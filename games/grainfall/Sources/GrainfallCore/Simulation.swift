/// Cellular-automaton rules (spec §2.3–§2.5).
extension World {
    static let neighbours4 = [(0, -1), (1, 0), (0, 1), (-1, 0)]

    mutating func initialLife(_ m: Matter) -> UInt8 {
        switch m {
        case .steam: return UInt8(60 + rng.int(61))
        case .fire: return UInt8(20 + rng.int(21))
        default: return 0
        }
    }

    mutating func updateCells() {
        let w = grid.width, h = grid.height
        let now = UInt32(truncatingIfNeeded: tick)
        let leftToRight = tick % 2 == 0
        for y in stride(from: h - 1, through: 0, by: -1) {
            for k in 0..<w {
                let x = leftToRight ? k : w - 1 - k
                let i = y * w + x
                let m = grid.mat[i]
                if m == .empty || m == .wall || m == .dirt || m == .stone || m == .gate { continue }
                if stamp[i] == now { continue }
                switch m {
                case .sand: _ = movePowder(x, y, i, m, now)
                case .water: _ = moveLiquid(x, y, i, m, now)
                case .lava: updateLava(x, y, i, now)
                case .steam: updateSteam(x, y, i, now)
                case .fire: updateFire(x, y, i, now)
                case .plant: updatePlant(x, y)
                default: break
                }
            }
        }
    }

    // MARK: Movement

    @inline(__always) func canEnter(_ x: Int, _ y: Int, mover: Matter) -> Bool {
        guard grid.inBounds(x, y) else { return false }
        let t = grid.mat[y * grid.width + x]
        return t == .empty || t == .drain || (t.isFluid && t.density < mover.density)
    }

    @inline(__always) mutating func move(_ i: Int, to x: Int, _ y: Int, _ now: UInt32) -> Int {
        let j = y * grid.width + x
        switch grid.mat[i] {
        case .sand: activity.sand += 1
        case .water: activity.water += 1
        case .lava: activity.lava += 1
        case .steam: activity.steam += 1
        default: break
        }
        if grid.mat[j] == .drain {
            grid.set(i % grid.width, i / grid.width, .empty)
            activity.drained += 1
            return i
        }
        grid.swapCells(i, j)
        stamp[j] = now
        return j
    }

    /// Tries ↓ then the two diagonals in random order (dy = +1 falls, -1 rises).
    mutating func fall(_ x: Int, _ y: Int, _ i: Int, _ m: Matter, _ now: UInt32, dy: Int) -> Int? {
        if canEnter(x, y + dy, mover: m) { return move(i, to: x, y + dy, now) }
        let first = rng.bool() ? -1 : 1
        for dx in [first, -first] where canEnter(x + dx, y + dy, mover: m) {
            return move(i, to: x + dx, y + dy, now)
        }
        return nil
    }

    mutating func movePowder(_ x: Int, _ y: Int, _ i: Int, _ m: Matter, _ now: UInt32) -> Int? {
        fall(x, y, i, m, now, dy: 1)
    }

    mutating func moveLiquid(_ x: Int, _ y: Int, _ i: Int, _ m: Matter, _ now: UInt32) -> Int? {
        if let j = fall(x, y, i, m, now, dy: 1) { return j }
        let first = rng.bool() ? -1 : 1
        for dir in [first, -first] {
            var target = 0
            for s in 1...max(1, m.spread) {
                let nx = x + dir * s
                guard grid.inBounds(nx, y) else { break }
                let t = grid.mat[y * grid.width + nx]
                if t == .drain { target = s; break }
                guard t == .empty else { break }
                target = s
            }
            if target > 0 { return move(i, to: x + dir * target, y, now) }
        }
        return nil
    }

    // MARK: Materials with reactions

    mutating func updateLava(_ x: Int, _ y: Int, _ i: Int, _ now: UInt32) {
        for (dx, dy) in World.neighbours4 {
            let nx = x + dx, ny = y + dy
            guard grid.inBounds(nx, ny) else { continue }
            let j = ny * grid.width + nx
            switch grid.mat[j] {
            case .water:
                activity.reactions += 1
                grid.set(x, y, .stone, shade: newShade(.stone))
                grid.set(nx, ny, .steam, shade: newShade(.steam), life: initialLife(.steam))
                stamp[j] = now
                return
            case .plant where rng.chance(0.5):
                grid.set(nx, ny, .fire, shade: newShade(.fire), life: initialLife(.fire))
                stamp[j] = now
            default: break
            }
        }
        // Lava is sluggish: it only moves on about half the ticks.
        if rng.bool() { _ = moveLiquid(x, y, i, .lava, now) }
    }

    mutating func updateSteam(_ x: Int, _ y: Int, _ i: Int, _ now: UInt32) {
        if grid.life[i] <= 1 { grid.set(x, y, .empty); return }
        grid.life[i] -= 1
        if fall(x, y, i, .steam, now, dy: -1) != nil { return }
        let dx = rng.bool() ? -1 : 1
        if canEnter(x + dx, y, mover: .steam) { _ = move(i, to: x + dx, y, now) }
    }

    mutating func updateFire(_ x: Int, _ y: Int, _ i: Int, _ now: UInt32) {
        if grid.life[i] <= 1 { grid.set(x, y, .empty); return }
        grid.life[i] -= 1
        activity.burning += 1
        for (dx, dy) in World.neighbours4 {
            let nx = x + dx, ny = y + dy
            guard grid.inBounds(nx, ny) else { continue }
            let j = ny * grid.width + nx
            switch grid.mat[j] {
            case .water:
                grid.set(x, y, .empty)
                grid.set(nx, ny, .steam, shade: newShade(.steam), life: initialLife(.steam))
                stamp[j] = now
                return
            case .plant where rng.chance(0.15):
                grid.set(nx, ny, .fire, shade: newShade(.fire), life: initialLife(.fire))
                stamp[j] = now
            default: break
            }
        }
    }

    mutating func updatePlant(_ x: Int, _ y: Int) {
        for (dx, dy) in World.neighbours4 where grid.at(x + dx, y + dy) == .water {
            if rng.chance(0.004) { grid.set(x + dx, y + dy, .plant, shade: newShade(.plant)) }
            return
        }
    }
}
