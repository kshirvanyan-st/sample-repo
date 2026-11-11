public struct Point: Hashable, Codable, Sendable {
    public var x: Int
    public var y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

/// Structure-of-arrays cell storage (spec §2.1). y = 0 is the top row.
public struct Grid: Sendable {
    public static let width = 128
    public static let height = 240

    public let width: Int
    public let height: Int
    public var mat: [Matter]
    public var shade: [UInt8]
    public var life: [UInt8]
    public var stamp: [UInt8]
    public var gate: [UInt8]

    public init(width: Int = Grid.width, height: Int = Grid.height) {
        self.width = width
        self.height = height
        let n = width * height
        mat = Array(repeating: .empty, count: n)
        shade = Array(repeating: 0, count: n)
        life = Array(repeating: 0, count: n)
        stamp = Array(repeating: 0, count: n)
        gate = Array(repeating: 0, count: n)
    }

    @inline(__always) public func inBounds(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < width && y < height
    }

    @inline(__always) public func index(_ x: Int, _ y: Int) -> Int { y * width + x }

    /// Matter at (x, y); out of bounds reads as wall.
    @inline(__always) public func at(_ x: Int, _ y: Int) -> Matter {
        inBounds(x, y) ? mat[y * width + x] : .wall
    }

    public mutating func set(_ x: Int, _ y: Int, _ m: Matter, shade s: UInt8 = 0, life l: UInt8 = 0, gate g: UInt8 = 0) {
        guard inBounds(x, y) else { return }
        let i = y * width + x
        mat[i] = m
        shade[i] = s
        life[i] = l
        gate[i] = g
    }

    @inline(__always) mutating func swapCells(_ a: Int, _ b: Int) {
        mat.swapAt(a, b)
        shade.swapAt(a, b)
        life.swapAt(a, b)
        gate.swapAt(a, b)
    }

    public func count(_ m: Matter) -> Int { mat.reduce(0) { $0 + ($1 == m ? 1 : 0) } }

    /// FNV-1a hash over materials, used to assert determinism.
    public var hashValueForTesting: UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for m in mat {
            h ^= UInt64(m.rawValue)
            h = h &* 0x100_0000_01b3
        }
        return h
    }
}
