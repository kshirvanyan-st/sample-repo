import Foundation

/// Something the player does; applied between ticks (spec §2.9).
public enum PlayerAction: Equatable, Sendable {
    case dig(from: Point, to: Point)
    case openGate(at: Point)
    /// Uses one blast charge: breaks dirt, stone and plant in a radius (spec §2.9).
    case blast(at: Point)
}

/// One painting operation in a level file (spec §3).
public enum Shape: Equatable, Sendable {
    case rect(Matter, x: Int, y: Int, w: Int, h: Int)
    case circle(Matter, cx: Int, cy: Int, r: Int)
    case line(Matter, x0: Int, y0: Int, x1: Int, y1: Int, t: Int)
    /// U-shaped container: left, right and bottom walls of thickness `t`.
    case cup(Matter, x: Int, y: Int, w: Int, h: Int, t: Int)
    case gate(id: Int, x: Int, y: Int, w: Int, h: Int)
}

extension Shape: Decodable {
    private enum K: String, CodingKey { case op, m, x, y, w, h, cx, cy, r, x0, y0, x1, y1, t, id }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        let op = try c.decode(String.self, forKey: .op)
        func i(_ k: K) throws -> Int { try c.decode(Int.self, forKey: k) }
        func m() throws -> Matter { try c.decode(Matter.self, forKey: .m) }
        switch op {
        case "rect": self = .rect(try m(), x: try i(.x), y: try i(.y), w: try i(.w), h: try i(.h))
        case "circle": self = .circle(try m(), cx: try i(.cx), cy: try i(.cy), r: try i(.r))
        case "line":
            self = .line(try m(), x0: try i(.x0), y0: try i(.y0), x1: try i(.x1), y1: try i(.y1),
                         t: try c.decodeIfPresent(Int.self, forKey: .t) ?? 1)
        case "cup":
            self = .cup(try c.decodeIfPresent(Matter.self, forKey: .m) ?? .wall,
                        x: try i(.x), y: try i(.y), w: try i(.w), h: try i(.h),
                        t: try c.decodeIfPresent(Int.self, forKey: .t) ?? 2)
        case "gate": self = .gate(id: try i(.id), x: try i(.x), y: try i(.y), w: try i(.w), h: try i(.h))
        default:
            throw DecodingError.dataCorruptedError(forKey: .op, in: c, debugDescription: "Unknown shape op '\(op)'")
        }
    }
}

public struct SpoutDef: Decodable, Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var m: Matter
    public var rate: Int
    public var total: Int
    public var width: Int
    public var delay: Int

    enum CodingKeys: String, CodingKey { case x, y, m, rate, total, width, delay }

    public init(x: Int, y: Int, m: Matter, rate: Int, total: Int, width: Int = 6, delay: Int = 60) {
        self.x = x; self.y = y; self.m = m; self.rate = rate; self.total = total; self.width = width; self.delay = delay
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(x: try c.decode(Int.self, forKey: .x),
                  y: try c.decode(Int.self, forKey: .y),
                  m: try c.decode(Matter.self, forKey: .m),
                  rate: try c.decode(Int.self, forKey: .rate),
                  total: try c.decode(Int.self, forKey: .total),
                  width: try c.decodeIfPresent(Int.self, forKey: .width) ?? 6,
                  delay: try c.decodeIfPresent(Int.self, forKey: .delay) ?? 60)
    }
}

public struct CupDef: Decodable, Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var w: Int
    public var h: Int
    public var accepts: Matter
    public var required: Int
    public var forbids: [Matter]

    enum CodingKeys: String, CodingKey { case x, y, w, h, accepts, required, forbids }

    public init(x: Int, y: Int, w: Int, h: Int, accepts: Matter, required: Int, forbids: [Matter] = []) {
        self.x = x; self.y = y; self.w = w; self.h = h
        self.accepts = accepts; self.required = required; self.forbids = forbids
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(x: try c.decode(Int.self, forKey: .x), y: try c.decode(Int.self, forKey: .y),
                  w: try c.decode(Int.self, forKey: .w), h: try c.decode(Int.self, forKey: .h),
                  accepts: try c.decode(Matter.self, forKey: .accepts),
                  required: try c.decode(Int.self, forKey: .required),
                  forbids: try c.decodeIfPresent([Matter].self, forKey: .forbids) ?? [])
    }

    public func contains(_ x: Int, _ y: Int) -> Bool {
        x >= self.x && y >= self.y && x < self.x + w && y < self.y + h
    }
}

/// A scripted player action at a tick; used for reference solutions and replays.
public struct TimedAction: Equatable, Sendable {
    public var tick: Int
    public var action: PlayerAction
    public init(tick: Int, action: PlayerAction) { self.tick = tick; self.action = action }
}

/// Decodes `{"t": 0, "dig": [x0, y0, x1, y1, ...]}` (a polyline) or `{"t": 0, "gate": [x, y]}`.
struct SolutionStep: Decodable {
    let actions: [TimedAction]

    enum CodingKeys: String, CodingKey { case t, dig, gate, blast }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let t = try c.decode(Int.self, forKey: .t)
        if let pts = try c.decodeIfPresent([Int].self, forKey: .dig) {
            guard pts.count >= 4, pts.count % 2 == 0 else {
                throw DecodingError.dataCorruptedError(forKey: .dig, in: c, debugDescription: "dig needs ≥ 2 points")
            }
            var out: [TimedAction] = []
            for k in stride(from: 0, to: pts.count - 2, by: 2) {
                out.append(TimedAction(tick: t, action: .dig(from: Point(pts[k], pts[k + 1]),
                                                             to: Point(pts[k + 2], pts[k + 3]))))
            }
            actions = out
        } else if let p = try c.decodeIfPresent([Int].self, forKey: .gate), p.count == 2 {
            actions = [TimedAction(tick: t, action: .openGate(at: Point(p[0], p[1])))]
        } else if let p = try c.decodeIfPresent([Int].self, forKey: .blast), p.count == 2 {
            actions = [TimedAction(tick: t, action: .blast(at: Point(p[0], p[1])))]
        } else {
            throw DecodingError.dataCorruptedError(forKey: .t, in: c, debugDescription: "step needs dig, gate or blast")
        }
    }
}

public struct LevelDefinition: Decodable, Sendable {
    public var id: String
    public var name: String
    public var seed: UInt64
    public var digBudget: Int
    /// Blast charges available (0 = no blast tool in this level).
    public var blasts: Int
    public var par: [Int]
    public var hint: String?
    public var shapes: [Shape]
    public var spouts: [SpoutDef]
    public var cups: [CupDef]
    public var solution: [TimedAction]
    /// Plausible wrong approaches that must *not* win (design-intent checks, R-LVL-4).
    public var traps: [[TimedAction]]

    enum CodingKeys: String, CodingKey { case id, name, seed, digBudget, blasts, par, hint, shapes, spouts, cups, solution, traps }

    public init(id: String, name: String, seed: UInt64 = 1, digBudget: Int = 2000, blasts: Int = 0, par: [Int] = [500, 1000],
                hint: String? = nil, shapes: [Shape], spouts: [SpoutDef], cups: [CupDef], solution: [TimedAction] = [],
                traps: [[TimedAction]] = []) {
        self.id = id; self.name = name; self.seed = seed; self.digBudget = digBudget; self.blasts = blasts; self.par = par
        self.hint = hint; self.shapes = shapes; self.spouts = spouts; self.cups = cups; self.solution = solution
        self.traps = traps
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        seed = try c.decode(UInt64.self, forKey: .seed)
        digBudget = try c.decode(Int.self, forKey: .digBudget)
        blasts = try c.decodeIfPresent(Int.self, forKey: .blasts) ?? 0
        par = try c.decode([Int].self, forKey: .par)
        hint = try c.decodeIfPresent(String.self, forKey: .hint)
        shapes = try c.decode([Shape].self, forKey: .shapes)
        spouts = try c.decodeIfPresent([SpoutDef].self, forKey: .spouts) ?? []
        cups = try c.decode([CupDef].self, forKey: .cups)
        solution = (try c.decodeIfPresent([SolutionStep].self, forKey: .solution) ?? []).flatMap(\.actions)
        traps = (try c.decodeIfPresent([[SolutionStep]].self, forKey: .traps) ?? []).map { $0.flatMap(\.actions) }
    }

    public var par3: Int { par.first ?? 0 }
    public var par2: Int { par.count > 1 ? par[1] : par3 }
}

public enum LevelError: Error, CustomStringConvertible, Equatable {
    case invalid(String, String)

    public var description: String {
        switch self { case let .invalid(id, why): return "Level \(id): \(why)" }
    }
}

public enum LevelLoader {
    public static func decode(_ data: Data) throws -> LevelDefinition {
        let level = try JSONDecoder().decode(LevelDefinition.self, from: data)
        try validate(level)
        return level
    }

    /// Structural checks from spec §3.
    public static func validate(_ l: LevelDefinition, width: Int = Grid.width, height: Int = Grid.height) throws {
        func fail(_ why: String) throws -> Never { throw LevelError.invalid(l.id, why) }
        func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < width && y < height }

        if l.par.count != 2 { try fail("par must be [par3, par2]") }
        if l.par3 > l.par2 { try fail("par3 must be ≤ par2") }
        if l.digBudget < 0 { try fail("digBudget must be ≥ 0") }
        if l.blasts < 0 || l.blasts > 9 { try fail("blasts must be 0...9") }
        if l.cups.isEmpty { try fail("needs at least one cup") }

        // Matter available to a cup: spout output plus cells painted into the level
        // (stone is made from lava, so lava counts toward it).
        lazy var painted = World(level: l).grid
        func available(_ m: Matter) -> Int {
            let spouted = l.spouts.filter { $0.m == m || (m == .stone && $0.m == .lava) }.reduce(0) { $0 + $1.total }
            return spouted + painted.count(m) + (m == .stone ? painted.count(.lava) : 0)
        }

        var gateIDs = Set<Int>()
        for s in l.shapes {
            switch s {
            case let .rect(_, x, y, w, h), let .cup(_, x, y, w, h, _):
                if w <= 0 || h <= 0 || !inside(x, y) || !inside(x + w - 1, y + h - 1) { try fail("shape out of bounds: \(s)") }
            case let .gate(id, x, y, w, h):
                if id <= 0 || id > 255 { try fail("gate id must be 1...255") }
                if !gateIDs.insert(id).inserted { try fail("duplicate gate id \(id)") }
                if w <= 0 || h <= 0 || !inside(x, y) || !inside(x + w - 1, y + h - 1) { try fail("gate out of bounds") }
            case let .circle(_, cx, cy, r):
                if r <= 0 || !inside(cx, cy) { try fail("circle centre out of bounds") }
            case let .line(_, x0, y0, x1, y1, t):
                if t <= 0 || !inside(x0, y0) || !inside(x1, y1) { try fail("line out of bounds") }
            }
        }
        for sp in l.spouts {
            if !inside(sp.x, sp.y) { try fail("spout out of bounds") }
            if sp.rate <= 0 || sp.total <= 0 || sp.width <= 0 || sp.delay < 0 { try fail("spout needs positive rate/total/width") }
            if sp.m.kind == .solid || sp.m == .empty { try fail("spout material must flow") }
        }
        for cup in l.cups {
            if cup.w <= 0 || cup.h <= 0 || !inside(cup.x, cup.y) || !inside(cup.x + cup.w - 1, cup.y + cup.h - 1) {
                try fail("cup out of bounds")
            }
            if cup.required <= 0 { try fail("cup.required must be > 0") }
            if cup.required > cup.w * cup.h { try fail("cup can't hold \(cup.required) cells") }
            if cup.required > available(cup.accepts) {
                try fail("cup needs \(cup.required) \(cup.accepts.name), level provides \(available(cup.accepts))")
            }
            if cup.forbids.contains(cup.accepts) { try fail("cup forbids its own material") }
            for y in cup.y..<(cup.y + cup.h) {
                for x in cup.x..<(cup.x + cup.w) where painted.at(x, y) == cup.accepts {
                    try fail("cup starts with \(cup.accepts.name) already inside")
                }
            }
        }
    }
}
