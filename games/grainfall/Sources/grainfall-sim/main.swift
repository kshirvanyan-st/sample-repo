import Foundation
import GrainfallCore

// grainfall-sim — headless tooling for level authors and CI (spec §8).
//   grainfall-sim validate [levelsDir]
//   grainfall-sim render <levelID> <tick> <out.png> [--solve] [--scale N] [--dir levelsDir]
//   grainfall-sim trace <levelID> [--solve] [--every N] [--dir levelsDir]

func usage() -> Never {
    FileHandle.standardError.write(Data("""
    usage:
      grainfall-sim validate [levelsDir]
      grainfall-sim render <levelID> <tick> <out.png> [--solve] [--scale N] [--dir levelsDir]
      grainfall-sim trace <levelID> [--solve] [--every N] [--dir levelsDir]
      grainfall-sim render-trap <levelID> <trapIndex> <tick> <out.png> [--scale N] [--dir levelsDir]
      grainfall-sim sheet <out.png> [--at 0.75] [--scale N] [--dir levelsDir]

    """.utf8))
    exit(2)
}

var args = Array(CommandLine.arguments.dropFirst())
func flag(_ name: String) -> Bool {
    if let i = args.firstIndex(of: name) { args.remove(at: i); return true }
    return false
}
func option(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    let v = args[i + 1]
    args.removeSubrange(i...(i + 1))
    return v
}

let solve = flag("--solve")
let glow = flag("--glow")
let scale = Int(option("--scale") ?? "3") ?? 3
let every = Int(option("--every") ?? "120") ?? 120
let dirOption = option("--dir")
let at = Double(option("--at") ?? "0.75") ?? 0.75

func catalog(_ dir: String?) throws -> LevelCatalog {
    if let dir { return try LevelCatalog.load(from: URL(fileURLWithPath: dir)) }
    return try LevelCatalog.bundled()
}

func describe(_ s: GameStatus) -> String {
    switch s {
    case .playing: return "playing"
    case .won: return "won"
    case let .failed(.contaminated(cup, by)): return "failed (cup \(cup) contaminated by \(by.name))"
    }
}

guard let command = args.first else { usage() }

do {
    switch command {
    case "validate":
        let cat = try catalog(args.count > 1 ? args[1] : dirOption)
        var failures = 0
        print("level  name                      untouched        solution            dug  par3 par2 ★  traps held")
        for id in cat.orderedLevelIDs {
            let level = cat.levels[id]!
            let idle = Replay.run(level, actions: [], stopWhenStuck: true)
            let sol = Replay.solve(level)
            let trapsWon = level.traps.filter { Replay.run(level, actions: $0, stopWhenStuck: true).status == .won }.count
            let ok = idle.status != .won && sol.status == .won && sol.stars == 3 && trapsWon == 0
            if !ok { failures += 1 }
            let name = level.name.padding(toLength: 24, withPad: " ", startingAt: 0)
            let idleS = (idle.status == .won ? "WON@\(idle.ticks)" : describe(idle.status)).padding(toLength: 16, withPad: " ", startingAt: 0)
            let solS = "\(describe(sol.status))@\(sol.ticks)".padding(toLength: 18, withPad: " ", startingAt: 0)
            print("\(ok ? "✓" : "✗") \(id.padding(toLength: 4, withPad: " ", startingAt: 0)) \(name)  \(idleS) \(solS) \(String(format: "%5d %5d %4d", sol.dug, level.par3, level.par2)) \(sol.stars)  traps \(level.traps.count - trapsWon)/\(level.traps.count)")
        }
        print(failures == 0 ? "\nAll \(cat.orderedLevelIDs.count) levels pass." : "\n\(failures) level(s) FAILED.")
        exit(failures == 0 ? 0 : 1)

    case "render":
        guard args.count >= 4, let tick = Int(args[2]) else { usage() }
        let cat = try catalog(dirOption)
        guard let level = cat.levels[args[1]] else { throw LevelError.invalid(args[1], "not in catalog") }
        let result = Replay.run(level, actions: solve ? level.solution : [], maxTicks: tick)
        var pixels: [UInt32] = []
        result.world.render(into: &pixels, emissive: glow)
        if glow {
            let (big, w, h) = Bloom.apply(pixels, width: result.world.grid.width, height: result.world.grid.height, scale: scale)
            try PNG.write(pixels: big, width: w, height: h, scale: 1, to: URL(fileURLWithPath: args[3]))
        } else {
            try PNG.write(pixels: pixels, width: result.world.grid.width, height: result.world.grid.height,
                          scale: scale, to: URL(fileURLWithPath: args[3]))
        }
        print("\(args[1]) @\(result.ticks): \(describe(result.status)), dug \(result.dug), cups \(result.world.cups.map { "\($0.collected)/\($0.def.required)" })")

    case "render-trap":
        // render-trap <levelID> <trapIndex> <tick> <out.png>
        guard args.count >= 5, let ti = Int(args[2]), let tick = Int(args[3]) else { usage() }
        let cat = try catalog(dirOption)
        guard let level = cat.levels[args[1]], ti < level.traps.count else { throw LevelError.invalid(args[1], "no such trap") }
        let result = Replay.run(level, actions: level.traps[ti], maxTicks: tick)
        var pixels: [UInt32] = []
        result.world.render(into: &pixels)
        try PNG.write(pixels: pixels, width: result.world.grid.width, height: result.world.grid.height,
                      scale: scale, to: URL(fileURLWithPath: args[4]))
        print("\(args[1]) trap \(ti) @\(result.ticks): \(describe(result.status))")

    case "sheet":
        // sheet <out.png> [--at fraction] — every level mid-solution, 6 per row (store art / visual QA).
        guard args.count >= 2 else { usage() }
        let cat = try catalog(dirOption)
        let ids = cat.orderedLevelIDs
        let cols = 6, gap = 4
        let w = Grid.width, h = Grid.height
        let rows = (ids.count + cols - 1) / cols
        let SW = cols * w + (cols + 1) * gap, SH = rows * h + (rows + 1) * gap
        var sheet = [UInt32](repeating: RGBA(hex: 0x0B0C14).packed, count: SW * SH)
        for (n, id) in ids.enumerated() {
            let level = cat.levels[id]!
            let total = Replay.solve(level).ticks
            let r = Replay.run(level, actions: level.solution, maxTicks: max(1, Int(Double(total) * at)))
            var px: [UInt32] = []
            r.world.render(into: &px)
            let ox = gap + (n % cols) * (w + gap), oy = gap + (n / cols) * (h + gap)
            for y in 0..<h { for x in 0..<w { sheet[(oy + y) * SW + ox + x] = px[y * w + x] } }
        }
        try PNG.write(pixels: sheet, width: SW, height: SH, scale: scale, to: URL(fileURLWithPath: args[1]))
        print("wrote \(args[1])")

    case "video":
        // video <levelID> [--every 2] [--scale 6] [--hold 90] — raw RGBA frames of the reference
        // solution (with bloom) on stdout, for `ffmpeg -f rawvideo -pix_fmt rgba -s WxH -i -`.
        guard args.count >= 2 else { usage() }
        let cat = try catalog(dirOption)
        guard let level = cat.levels[args[1]] else { throw LevelError.invalid(args[1], "not in catalog") }
        let stride = max(1, Int(option("--stride") ?? "2") ?? 2)
        var world = World(level: level)
        let actions = level.solution.sorted { $0.tick < $1.tick }
        var next = 0, hold = Int(option("--hold") ?? "90") ?? 90
        var px: [UInt32] = []
        let out = FileHandle.standardOutput
        while world.tick < 3600, hold > 0 {
            while next < actions.count, actions[next].tick <= world.tick {
                world.apply(actions[next].action)
                next += 1
            }
            world.step()
            if world.status != .playing { hold -= 1 }
            if world.tick % stride == 0 {
                world.render(into: &px, emissive: true)
                let (big, _, _) = Bloom.apply(px, width: world.grid.width, height: world.grid.height, scale: scale)
                big.withUnsafeBytes { out.write(Data($0)) }
            }
        }

    case "trace":
        guard args.count >= 2 else { usage() }
        let cat = try catalog(dirOption)
        guard let level = cat.levels[args[1]] else { throw LevelError.invalid(args[1], "not in catalog") }
        var world = World(level: level)
        let actions = (solve ? level.solution : []).sorted { $0.tick < $1.tick }
        var next = 0
        while world.tick < 3600, world.status == .playing {
            while next < actions.count, actions[next].tick <= world.tick {
                let n = world.apply(actions[next].action)
                print("  t=\(world.tick) \(actions[next].action) → \(n) cells")
                next += 1
            }
            world.step()
            if world.tick % every == 0 {
                let cups = world.cups.map { "\($0.collected)/\($0.def.required)" }.joined(separator: " ")
                let spouts = world.spouts.map { "\($0.remaining)" }.joined(separator: " ")
                print("t=\(world.tick) cups[\(cups)] spouts[\(spouts)] stuck=\(world.isStuck)")
            }
        }
        print("end t=\(world.tick) \(describe(world.status)) dug=\(world.dug) stars=\(world.stars)")

    default: usage()
    }
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}

/// CPU port of Shaders.metal's grid_fragment (bloom + vignette) so store art matches the device.
enum Bloom {
    static func apply(_ px: [UInt32], width w: Int, height h: Int, scale: Int) -> ([UInt32], Int, Int) {
        func ch(_ p: UInt32, _ s: UInt32) -> Double { Double((p >> s) & 0xFF) / 255 }
        // Premultiplied emissive colour per cell.
        var em = [SIMD3<Double>](repeating: .zero, count: w * h)
        for i in 0..<(w * h) {
            let a = ch(px[i], 24)
            em[i] = SIMD3(ch(px[i], 0), ch(px[i], 8), ch(px[i], 16)) * a
        }
        func sample(_ x: Double, _ y: Double) -> SIMD3<Double> { // bilinear, in cell units
            let fx = min(max(x - 0.5, 0), Double(w - 1)), fy = min(max(y - 0.5, 0), Double(h - 1))
            let x0 = Int(fx), y0 = Int(fy), x1 = min(x0 + 1, w - 1), y1 = min(y0 + 1, h - 1)
            let tx = fx - Double(x0), ty = fy - Double(y0)
            let a = em[y0 * w + x0] * (1 - tx) + em[y0 * w + x1] * tx
            let b = em[y1 * w + x0] * (1 - tx) + em[y1 * w + x1] * tx
            return a * (1 - ty) + b * ty
        }
        let W = w * scale, H = h * scale
        var out = [UInt32](repeating: 0, count: W * H)
        let dirs = (0..<12).map { k -> (Double, Double) in
            let a = 2 * Double.pi * Double(k) / 12
            return (cos(a), sin(a))
        }
        for Y in 0..<H {
            for X in 0..<W {
                let cx = (Double(X) + 0.5) / Double(scale), cy = (Double(Y) + 0.5) / Double(scale)
                let p = px[(Y / scale) * w + X / scale]
                var c = SIMD3(ch(p, 0), ch(p, 8), ch(p, 16))
                var g = SIMD3<Double>.zero
                for (dx, dy) in dirs {
                    g += sample(cx + dx * 1.8, cy + dy * 1.8) * 0.6 + sample(cx + dx * 4.0, cy + dy * 4.0) * 0.4
                }
                c += g / 12 * 0.55
                let u = Double(X) / Double(W) - 0.5, v = Double(Y) / Double(H) - 0.5
                c *= 1 - (u * u + v * v) * 0.45
                let r = UInt32(min(1, c.x) * 255), gg = UInt32(min(1, c.y) * 255), b = UInt32(min(1, c.z) * 255)
                out[Y * W + X] = r | gg << 8 | b << 16 | 0xFF00_0000
            }
        }
        return (out, W, H)
    }
}

/// Minimal dependency-free PNG encoder (stored/uncompressed deflate), for previews and store art.
enum PNG {
    static func write(pixels: [UInt32], width: Int, height: Int, scale: Int, to url: URL) throws {
        let W = width * scale, H = height * scale
        var raw = [UInt8]()
        raw.reserveCapacity((W * 4 + 1) * H)
        for y in 0..<H {
            raw.append(0)
            for x in 0..<W {
                let p = pixels[(y / scale) * width + x / scale]
                raw.append(UInt8(p & 0xFF)); raw.append(UInt8(p >> 8 & 0xFF))
                raw.append(UInt8(p >> 16 & 0xFF)); raw.append(UInt8(p >> 24 & 0xFF))
            }
        }
        var z: [UInt8] = [0x78, 0x01]
        var i = 0
        while i < raw.count {
            let n = min(65535, raw.count - i)
            z.append(i + n == raw.count ? 1 : 0)
            z += [UInt8(n & 0xFF), UInt8(n >> 8), UInt8(~n & 0xFF), UInt8((~n >> 8) & 0xFF)]
            z += raw[i..<(i + n)]
            i += n
        }
        var a: UInt32 = 1, b: UInt32 = 0
        for byte in raw { a = (a + UInt32(byte)) % 65521; b = (b + a) % 65521 }
        z += be(b << 16 | a)

        var png: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        png += chunk("IHDR", be(UInt32(W)) + be(UInt32(H)) + [8, 6, 0, 0, 0])
        png += chunk("IDAT", z)
        png += chunk("IEND", [])
        try Data(png).write(to: url)
    }

    static func be(_ v: UInt32) -> [UInt8] { [UInt8(v >> 24), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)] }

    static func chunk(_ type: String, _ data: [UInt8]) -> [UInt8] {
        let t = Array(type.utf8)
        return be(UInt32(data.count)) + t + data + be(crc(t + data))
    }

    static let crcTable: [UInt32] = (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = c & 1 != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    static func crc(_ bytes: [UInt8]) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in bytes { c = crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }
}
