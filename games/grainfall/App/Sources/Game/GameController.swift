import Combine
import GrainfallCore
import SwiftUI
import UIKit

/// HUD state published to SwiftUI at most ~10×/s (spec §5). Drawing never goes through SwiftUI.
struct HUDState: Equatable {
    struct Cup: Equatable, Identifiable {
        let id: Int
        let material: Matter
        let collected: Int
        let required: Int
        var fraction: Double { min(1, Double(collected) / Double(required)) }
    }

    var cups: [Cup] = []
    var digRemaining: Double = 1
    var blastsLeft = 0
    var status: GameStatus = .playing
    var isStuck = false
    var stars = 0
    var dug = 0
    var seconds = 0.0
}

/// A reference-solution stroke for the hint overlay, in grid cells.
struct GhostStroke: Identifiable {
    enum Kind { case dig, gate, blast }
    let id: Int
    let kind: Kind
    let points: [Point]
}

/// Owns one attempt at a level: fixed-step clock, input → `PlayerAction`, effects, HUD snapshot.
@MainActor
final class GameController: ObservableObject {
    static let dt = 1.0 / 60.0
    static let maxStepsPerFrame = 4

    @Published private(set) var hud = HUDState()
    @Published var isPaused = false {
        didSet { if isPaused { audio?.quiet() } }
    }
    /// Next tap uses a blast charge instead of digging.
    @Published var blastArmed = false
    /// Increments on blasts; views use it to drive a screen shake.
    @Published private(set) var shakeCount = 0
    /// Set when the player first touches the board (dismisses the tutorial hand).
    @Published private(set) var hasTouched = false
    @Published private(set) var attempts = 1

    private(set) var level: LevelDefinition
    private(set) var world: World
    /// Every action with the tick it was applied at — a replay of this attempt.
    private(set) var recorded: [TimedAction] = []
    let ghost: [GhostStroke]

    /// Demo mode (title screen): replays the level's reference solution in a loop.
    let isDemo: Bool
    var haptics: Haptics?
    var audio: AudioEngine?
    var onFinished: ((GameStatus, Int) -> Void)?

    private var pending: [PlayerAction] = []
    private var lastTime: Double?
    private var accumulator = 0.0
    private var lastHUD = 0.0
    private var pixels: [UInt32] = []
    private var strokeLast: Point?
    private var reported = false
    private var demoCursor = 0
    private var demoRestartAt: Double?

    init(level: LevelDefinition, demo: Bool = false) {
        self.level = level
        self.world = World(level: level)
        self.isDemo = demo
        self.ghost = GameController.ghostStrokes(for: level)
        world.render(into: &pixels, emissive: true)
        publishHUD()
    }

    func restart() {
        world = World(level: level)
        recorded = []
        pending = []
        strokeLast = nil
        accumulator = 0
        lastTime = nil
        reported = false
        demoCursor = 0
        demoRestartAt = nil
        isPaused = false
        blastArmed = false
        if !isDemo { attempts += 1 }
        audio?.quiet()
        world.render(into: &pixels, emissive: true)
        publishHUD()
    }

    // MARK: Input (spec §2.9)

    func touch(_ phase: GridMTKView.TouchPhase, at p: Point) {
        guard !isDemo, !isPaused, world.status == .playing else { return }
        hasTouched = true
        switch phase {
        case .began:
            if blastArmed, world.blastsLeft > 0 {
                pending.append(.blast(at: p))
                blastArmed = false
                strokeLast = nil
            } else if world.gateID(near: p) != nil {
                pending.append(.openGate(at: p))
                strokeLast = nil
            } else {
                pending.append(.dig(from: p, to: p))
                strokeLast = p
            }
        case .moved:
            guard let last = strokeLast, last != p else { return }
            pending.append(.dig(from: last, to: p))
            strokeLast = p
        case .ended:
            strokeLast = nil
        }
    }

    // MARK: Frame clock

    /// Called by the renderer every display frame. Advances the fixed-step simulation and
    /// returns the pixels to draw (alpha = glow strength).
    func frame(now: Double) -> [UInt32] {
        defer { lastTime = now }
        guard let last = lastTime else { return pixels }
        if isPaused { return pixels }

        if isDemo { driveDemo(now: now) }

        accumulator = min(accumulator + (now - last), GameController.dt * Double(GameController.maxStepsPerFrame))
        var stepped = false
        while accumulator >= GameController.dt {
            accumulator -= GameController.dt
            applyPending()
            world.step()
            stepped = true
        }
        if !pending.isEmpty { applyPending() } // keep digging responsive even between ticks
        if stepped || world.status != .playing { world.render(into: &pixels, emissive: true) }
        if stepped, !isDemo { audio?.update(activity: world.activity) }
        handleEvents()

        if now - lastHUD > 0.1 || world.status != hud.status {
            lastHUD = now
            publishHUD()
        }
        if world.status.isTerminal, !reported {
            reported = true
            finish()
        }
        return pixels
    }

    private func applyPending() {
        guard !pending.isEmpty else { return }
        var dugNow = 0
        for action in pending {
            let changed = world.apply(action)
            recorded.append(TimedAction(tick: world.tick, action: action))
            if case .dig = action { dugNow += changed }
        }
        pending.removeAll(keepingCapacity: true)
        if dugNow > 0, !isDemo {
            haptics?.dig()
            audio?.play(.dig)
        }
        world.render(into: &pixels, emissive: true)
    }

    private func handleEvents() {
        let events = world.takeEvents()
        guard !isDemo else { return }
        for e in events {
            switch e {
            case .gateOpened:
                haptics?.gate()
                audio?.play(.gate)
            case .blast:
                haptics?.blast()
                audio?.play(.blast)
                shakeCount += 1
            case .cupFilled:
                haptics?.gate()
                audio?.play(.cupFilled)
            }
        }
    }

    private func driveDemo(now: Double) {
        if let at = demoRestartAt {
            if now >= at { restart() }
            return
        }
        let sol = level.solution
        while demoCursor < sol.count, sol[demoCursor].tick <= world.tick {
            pending.append(sol[demoCursor].action)
            demoCursor += 1
        }
        if world.status.isTerminal || world.tick > 3600 { demoRestartAt = now + 2.5 }
    }

    private func finish() {
        guard !isDemo else { return }
        audio?.quiet()
        switch world.status {
        case .won:
            haptics?.success()
            audio?.play(.win)
        case .failed:
            haptics?.failure()
            audio?.play(.fail)
        case .playing: break
        }
        onFinished?(world.status, world.stars)
    }

    private func publishHUD() {
        let next = HUDState(
            cups: world.cups.enumerated().map { i, c in
                HUDState.Cup(id: i, material: c.def.accepts, collected: min(c.collected, c.def.required),
                             required: c.def.required)
            },
            digRemaining: level.digBudget == 0 ? 0 : Double(world.digBudget) / Double(level.digBudget),
            blastsLeft: world.blastsLeft,
            status: world.status,
            isStuck: world.isStuck,
            stars: world.stars,
            dug: world.dug,
            seconds: Double(world.tick) * GameController.dt
        )
        if next != hud { hud = next }
    }

    // MARK: Hints & sharing

    /// Groups the reference solution into drawable strokes: consecutive digs at the same tick
    /// whose segments join form one polyline.
    static func ghostStrokes(for level: LevelDefinition) -> [GhostStroke] {
        var out: [GhostStroke] = []
        var current: [Point] = []
        var currentTick = -1
        func flush() {
            if current.count > 1 { out.append(GhostStroke(id: out.count, kind: .dig, points: current)) }
            current = []
        }
        for step in level.solution {
            switch step.action {
            case let .dig(from, to):
                if step.tick != currentTick || current.last != from { flush(); current = [from] }
                current.append(to)
                currentTick = step.tick
            case let .openGate(p):
                flush()
                out.append(GhostStroke(id: out.count, kind: .gate, points: [p]))
            case let .blast(p):
                flush()
                out.append(GhostStroke(id: out.count, kind: .blast, points: [p]))
            }
        }
        flush()
        return out
    }

    /// The current board as a crisp, upscaled image for the share sheet.
    func snapshot(scale: Int = 6) -> UIImage? {
        var px: [UInt32] = []
        world.render(into: &px)
        let w = Grid.width, h = Grid.height
        var big = [UInt32](repeating: 0, count: w * scale * h * scale)
        for y in 0..<(h * scale) {
            for x in 0..<(w * scale) { big[y * w * scale + x] = px[(y / scale) * w + x / scale] }
        }
        let data = big.withUnsafeBytes { Data($0) }
        guard let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(width: w * scale, height: h * scale, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: w * scale * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false,
                                  intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: image)
    }
}
