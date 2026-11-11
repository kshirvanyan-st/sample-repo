/// SplitMix64 — tiny, fast and fully deterministic across platforms (spec §2.2, R-SIM-1).
public struct RNG: Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform integer in `0..<bound`.
    public mutating func int(_ bound: Int) -> Int {
        precondition(bound > 0)
        return Int(next() % UInt64(bound))
    }

    public mutating func bool() -> Bool { next() & 1 == 1 }

    /// True with probability `p` (0...1).
    public mutating func chance(_ p: Double) -> Bool {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0) < p
    }
}
