import Combine
import GrainfallCore
import SwiftUI

/// HUD state published to SwiftUI at most ~10×/s (spec §5). Drawing never goes through SwiftUI.
struct HUDState: Equatable {
    struct Cup: Equatable, Identifiable {
        let id: Int
        let material: Material
        let collected: Int
        let required: Int
        var fraction: Double { min(1, Double(collected) / Double(required)) }
    }

    var cups: [Cup] = []
    var digRemaining: Double = 1
    var status: GameStatus = .playing
    var isStuck = false
    var stars = 0
    var dug = 0
}

/// Owns one attempt at a level: fixed-step clock, input → `PlayerAction`, haptics, HUD snapshot.
@MainActor
final class GameController: ObservableObject {
    static let dt = 1.0 / 60.0
    static let maxStepsPerFrame = 4

    @Published private(set) var hud = HUDState()
    @Published var isPaused = false

    private(set) var level: LevelDefinition
    private(set) var world: World
    /// Every action with the tick it was applied at — a replay of this attempt.
    private(set) var recorded: [TimedAction] = []

    /// Demo mode (title screen): replays the level's reference solution in a loop.
    let isDemo: Bool
    var haptics: Haptics?
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
        world.render(into: &pixels)
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
        world.render(into: &pixels)
        publishHUD()
    }

    // MARK: Input (spec §2.9)

    func touch(_ phase: GridMTKView.TouchPhase, at p: Point) {
        guard !isDemo, !isPaused, world.status == .playing else { return }
        switch phase {
        case .began:
            if world.gateID(near: p) != nil {
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
    /// returns the pixels to draw.
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
        if stepped || world.status != .playing { world.render(into: &pixels) }

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
            switch action {
            case .dig: dugNow += changed
            case .openGate: if changed > 0 { haptics?.gate() }
            }
        }
        pending.removeAll(keepingCapacity: true)
        if dugNow > 0 { haptics?.dig() }
        world.render(into: &pixels)
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
        switch world.status {
        case .won: haptics?.success()
        case .failed: haptics?.failure()
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
            status: world.status,
            isStuck: world.isStuck,
            stars: world.stars,
            dug: world.dug
        )
        if next != hud { hud = next }
    }
}
