/// Every cell of the grid holds exactly one material (spec §2.4).
public enum Material: UInt8, CaseIterable, Codable, Sendable {
    case empty = 0
    case wall
    case dirt
    case sand
    case water
    case lava
    case stone
    case steam
    case plant
    case fire
    case gate
    /// Swallows anything that flows into it (spec §2.4).
    case drain

    public enum Kind: Sendable { case none, solid, powder, liquid, gas, fire }

    public var kind: Kind {
        switch self {
        case .empty: return .none
        case .wall, .dirt, .stone, .plant, .gate, .drain: return .solid
        case .sand: return .powder
        case .water, .lava: return .liquid
        case .steam: return .gas
        case .fire: return .fire
        }
    }

    /// Heavier materials sink through lighter fluids (spec §2.4).
    public var density: Int {
        switch self {
        case .steam, .fire: return 0
        case .water: return 2
        case .sand, .lava: return 3
        default: return 100
        }
    }

    /// Fluids can be displaced by a denser mover.
    public var isFluid: Bool { kind == .liquid || kind == .gas }

    /// How many cells a liquid may slide sideways per tick.
    public var spread: Int {
        switch self {
        case .water: return 5
        case .lava: return 1
        default: return 0
        }
    }

    /// Stable lowercase name used in level JSON.
    public var name: String {
        switch self {
        case .empty: return "empty"
        case .wall: return "wall"
        case .dirt: return "dirt"
        case .sand: return "sand"
        case .water: return "water"
        case .lava: return "lava"
        case .stone: return "stone"
        case .steam: return "steam"
        case .plant: return "plant"
        case .fire: return "fire"
        case .gate: return "gate"
        case .drain: return "drain"
        }
    }

    public init?(name: String) {
        guard let m = Material.allCases.first(where: { $0.name == name }) else { return nil }
        self = m
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let m = Material(name: raw) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Unknown material '\(raw)'"))
        }
        self = m
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(name)
    }
}
