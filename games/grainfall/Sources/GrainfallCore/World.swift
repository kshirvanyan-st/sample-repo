public enum FailReason: Equatable, Sendable {
    /// A forbidden material reached a cup (spec §2.7).
    case contaminated(cup: Int, by: Material)
}

public enum GameStatus: Equatable, Sendable {
    case playing
    case won
    case failed(FailReason)

    public var isTerminal: Bool { self != .playing }
}

public struct SpoutState: Sendable {
    public let def: SpoutDef
    public internal(set) var emitted: Int = 0
    public var remaining: Int { def.total - emitted }
    public var exhausted: Bool { emitted >= def.total }
}

public struct CupState: Sendable {
    public let def: CupDef
    /// Accepted cells currently inside the cup.
    public internal(set) var collected: Int = 0
    /// Highest `collected` seen so far; drives stuck detection.
    public internal(set) var best: Int = 0
    public var isFull: Bool { collected >= def.required }
    public var fraction: Double { min(1, Double(collected) / Double(def.required)) }
}

/// The complete, deterministic game state for one attempt at a level.
public struct World: Sendable {
    public static let stuckAfterTicks = 600
    public static let digRadius = 4
    public static let gateTapRadius = 6

    public let level: LevelDefinition
    public internal(set) var grid: Grid
    public internal(set) var spouts: [SpoutState]
    public internal(set) var cups: [CupState]
    public internal(set) var tick: Int = 0
    public internal(set) var status: GameStatus = .playing
    public internal(set) var dug: Int = 0
    public internal(set) var digBudget: Int
    public internal(set) var idleTicks: Int = 0
    public internal(set) var openedGates: Set<Int> = []
    var rng: RNG
    /// Per-cell tick of the last move; avoids processing a cell twice in one tick.
    var stamp: [UInt32]

    public init(level: LevelDefinition) {
        self.level = level
        grid = Grid()
        spouts = level.spouts.map { SpoutState(def: $0) }
        cups = level.cups.map { CupState(def: $0) }
        digBudget = level.digBudget
        rng = RNG(seed: level.seed)
        stamp = Array(repeating: 0, count: grid.width * grid.height)
        paint(level.shapes)
    }

    /// Every spout exhausted and no cup progress for a while (spec §2.8). Not terminal.
    public var isStuck: Bool {
        status == .playing && spouts.allSatisfy(\.exhausted) && idleTicks >= World.stuckAfterTicks
    }

    public var stars: Int { status == .won ? Scoring.stars(dug: dug, level: level) : 0 }

    // MARK: - Painting

    mutating func paint(_ shapes: [Shape]) {
        for s in shapes {
            switch s {
            case let .rect(m, x, y, w, h):
                fill(m) { px, py in px >= x && px < x + w && py >= y && py < y + h }
            case let .circle(m, cx, cy, r):
                fill(m) { px, py in (px - cx) * (px - cx) + (py - cy) * (py - cy) <= r * r }
            case let .line(m, x0, y0, x1, y1, t):
                var points: [Point] = []
                stroke(from: Point(x0, y0), to: Point(x1, y1)) { points.append($0) }
                for p in points { fillSquare(center: p, size: t, m: m) }
            case let .cup(m, x, y, w, h, t):
                fill(m) { px, py in
                    guard px >= x && px < x + w && py >= y && py < y + h else { return false }
                    return px < x + t || px >= x + w - t || py >= y + h - t
                }
            case let .gate(id, x, y, w, h):
                for py in y..<(y + h) {
                    for px in x..<(x + w) {
                        grid.set(px, py, .gate, shade: UInt8((px + py) / 2 % 2), gate: UInt8(id))
                    }
                }
            }
        }
    }

    private mutating func fill(_ m: Material, where test: (Int, Int) -> Bool) {
        for y in 0..<grid.height {
            for x in 0..<grid.width where test(x, y) {
                grid.set(x, y, m, shade: newShade(m))
            }
        }
    }

    /// Paints a `t`×`t` block centred on p (used for line thickness).
    private mutating func fillSquare(center p: Point, size t: Int, m: Material) {
        let lo = -(t - 1) / 2
        for dy in lo..<(lo + t) {
            for dx in lo..<(lo + t) {
                grid.set(p.x + dx, p.y + dy, m, shade: newShade(m))
            }
        }
    }

    mutating func newShade(_ m: Material) -> UInt8 {
        m == .empty ? 0 : UInt8(rng.int(4))
    }

    /// Calls `body` for each integer point on the segment (inclusive), one cell apart.
    func stroke(from a: Point, to b: Point, _ body: (Point) -> Void) {
        let dx = b.x - a.x, dy = b.y - a.y
        let steps = max(abs(dx), abs(dy))
        if steps == 0 { body(a); return }
        for s in 0...steps {
            let t = Double(s) / Double(steps)
            body(Point(a.x + Int((Double(dx) * t).rounded()), a.y + Int((Double(dy) * t).rounded())))
        }
    }

    // MARK: - Player actions (spec §2.9)

    /// Applies an action between ticks. Returns the number of cells changed (dug cells, or gate cells removed).
    @discardableResult
    public mutating func apply(_ action: PlayerAction) -> Int {
        guard status == .playing else { return 0 }
        switch action {
        case let .dig(from, to):
            var cleared = 0
            let r = World.digRadius
            var points: [Point] = []
            stroke(from: from, to: to) { points.append($0) }
            for p in points {
                for dy in -r...r {
                    for dx in -r...r where dx * dx + dy * dy <= r * r {
                        let x = p.x + dx, y = p.y + dy
                        guard digBudget > 0, grid.at(x, y) == .dirt else { continue }
                        grid.set(x, y, .empty)
                        digBudget -= 1
                        dug += 1
                        cleared += 1
                    }
                }
            }
            if cleared > 0 { idleTicks = 0 }
            return cleared
        case let .openGate(at):
            guard let id = gateID(near: at) else { return 0 }
            var removed = 0
            for i in 0..<grid.mat.count where grid.mat[i] == .gate && grid.gate[i] == UInt8(id) {
                grid.mat[i] = .empty
                grid.gate[i] = 0
                removed += 1
            }
            openedGates.insert(id)
            idleTicks = 0
            return removed
        }
    }

    /// The id of the gate nearest to `p` within `gateTapRadius`, if any.
    public func gateID(near p: Point) -> Int? {
        let r = World.gateTapRadius
        var best: (d: Int, id: Int)?
        for dy in -r...r {
            for dx in -r...r {
                let x = p.x + dx, y = p.y + dy
                guard grid.inBounds(x, y) else { continue }
                let i = grid.index(x, y)
                guard grid.mat[i] == .gate else { continue }
                let d = dx * dx + dy * dy
                if d <= r * r, best == nil || d < best!.d { best = (d, Int(grid.gate[i])) }
            }
        }
        return best?.id
    }

    // MARK: - Tick (spec §2.3)

    public mutating func step() {
        guard status == .playing else { return }
        tick += 1
        idleTicks += 1
        emitSpouts()
        updateCells()
        updateCups()
    }

    public mutating func step(_ n: Int) {
        for _ in 0..<n where status == .playing { step() }
    }

    mutating func emitSpouts() {
        for s in spouts.indices where !spouts[s].exhausted && tick > spouts[s].def.delay {
            let d = spouts[s].def
            let half = d.width / 2
            for _ in 0..<d.rate where !spouts[s].exhausted {
                let x = d.x - half + rng.int(max(1, d.width))
                guard grid.inBounds(x, d.y), grid.at(x, d.y) == .empty else { continue }
                grid.set(x, d.y, d.m, shade: newShade(d.m), life: initialLife(d.m))
                stamp[grid.index(x, d.y)] = UInt32(truncatingIfNeeded: tick)
                spouts[s].emitted += 1
                idleTicks = 0
            }
        }
    }

    mutating func updateCups() {
        var allFull = true
        for c in cups.indices {
            let d = cups[c].def
            var count = 0
            for y in d.y..<(d.y + d.h) {
                for x in d.x..<(d.x + d.w) {
                    let m = grid.mat[grid.index(x, y)]
                    if m == d.accepts {
                        count += 1
                    } else if m != .empty, d.forbids.contains(m) {
                        status = .failed(.contaminated(cup: c, by: m))
                        return
                    }
                }
            }
            cups[c].collected = count
            if count > cups[c].best {
                cups[c].best = count
                idleTicks = 0
            }
            if count < d.required { allFull = false }
        }
        if allFull { status = .won }
    }

}
