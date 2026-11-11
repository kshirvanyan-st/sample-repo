/// RGBA8 colours, packed so the bytes in memory are R, G, B, A (matches MTLPixelFormat.rgba8Unorm
/// and PNG on little-endian hardware, which is every Apple device and our CI).
public struct RGBA: Equatable, Sendable {
    public var r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255

    public init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) { self.r = r; self.g = g; self.b = b; self.a = a }

    public init(hex: UInt32) {
        self.init(UInt8((hex >> 16) & 0xFF), UInt8((hex >> 8) & 0xFF), UInt8(hex & 0xFF))
    }

    public var packed: UInt32 { UInt32(r) | UInt32(g) << 8 | UInt32(b) << 16 | UInt32(a) << 24 }

    public func mix(_ o: RGBA, _ t: Double) -> RGBA {
        func l(_ a: UInt8, _ b: UInt8) -> UInt8 { UInt8(Double(a) + (Double(b) - Double(a)) * t) }
        return RGBA(l(r, o.r), l(g, o.g), l(b, o.b))
    }
}

/// Four shades per material. Materials differ in brightness as well as hue (PRD §6 accessibility).
public enum Palette {
    public static let background = RGBA(hex: 0x14_1626)

    public static func shades(_ m: Material) -> [RGBA] {
        switch m {
        case .empty: return Array(repeating: background, count: 4)
        case .wall: return [0x4A4E69, 0x454962, 0x50556F, 0x42465C].map(RGBA.init(hex:))
        case .dirt: return [0x7A4E2D, 0x6E4628, 0x845533, 0x734A2A].map(RGBA.init(hex:))
        case .sand: return [0xF2C46D, 0xE8B85E, 0xF7D184, 0xDDAF58].map(RGBA.init(hex:))
        case .water: return [0x3E8EDE, 0x3A86D4, 0x4797E6, 0x3480CC].map(RGBA.init(hex:))
        case .lava: return [0xFF5A1F, 0xF04A12, 0xFF7A2F, 0xE03E10].map(RGBA.init(hex:))
        case .stone: return [0x8A8F98, 0x7E838C, 0x969BA3, 0x747982].map(RGBA.init(hex:))
        case .steam: return [0xC9D6E3, 0xBFCCD9, 0xD3E0EC, 0xB5C2CF].map(RGBA.init(hex:))
        case .plant: return [0x4CAF50, 0x43A047, 0x5CBF60, 0x388E3C].map(RGBA.init(hex:))
        case .fire: return [0xFFE066, 0xFFB627, 0xFF8C1A, 0xF25C05].map(RGBA.init(hex:))
        case .gate: return [0xE9C46A, 0x2A2D3E, 0xE9C46A, 0x2A2D3E].map(RGBA.init(hex:))
        case .drain: return [0x07070C, 0x1B1830, 0x2B2550, 0x110F1E].map(RGBA.init(hex:))
        }
    }

    /// Precomputed table: `table[material.rawValue * 4 + shade]`.
    public static let table: [UInt32] = Material.allCases.flatMap { shades($0).map(\.packed) }

    /// Tint for the empty space inside a cup that accepts `m`.
    public static func cupTint(_ m: Material) -> UInt32 { background.mix(shades(m)[0], 0.18).packed }
    public static let spoutColor = RGBA(hex: 0xE0E1DD).packed
}

extension World {
    /// Writes the current frame as RGBA8 into `pixels` (count = width × height).
    public func render(into pixels: inout [UInt32]) {
        let w = grid.width, h = grid.height
        if pixels.count != w * h { pixels = Array(repeating: 0, count: w * h) }
        let table = Palette.table
        let lavaPhase = tick / 6
        pixels.withUnsafeMutableBufferPointer { out in
            grid.mat.withUnsafeBufferPointer { mat in
                grid.shade.withUnsafeBufferPointer { shade in
                    for i in 0..<(w * h) {
                        let m = mat[i]
                        var s = Int(shade[i])
                        switch m {
                        case .lava: s = (s + lavaPhase + i % w / 3) & 3
                        case .fire: s = 3 - min(3, Int(grid.life[i]) / 10)
                        case .gate: s = ((i % w + i / w) / 2) & 1
                        case .drain: s = ((i % w + i / w + tick / 5) / 2) & 3
                        default: break
                        }
                        out[i] = table[Int(m.rawValue) * 4 + s]
                    }
                }
            }
        }
        for cup in cups {
            let tint = Palette.cupTint(cup.def.accepts)
            for y in cup.def.y..<(cup.def.y + cup.def.h) {
                for x in cup.def.x..<(cup.def.x + cup.def.w) where grid.mat[y * w + x] == .empty {
                    pixels[y * w + x] = tint
                }
            }
        }
        for s in spouts where !s.exhausted {
            let y = max(0, s.def.y - 1)
            for x in (s.def.x - s.def.width / 2)..<(s.def.x - s.def.width / 2 + s.def.width) where grid.inBounds(x, y) {
                if grid.mat[y * w + x] == .empty { pixels[y * w + x] = Palette.spoutColor }
            }
        }
    }
}
