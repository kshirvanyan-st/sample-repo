import AVFoundation
import GrainfallCore
import os

/// Fully procedural audio (PRD §6): granular pour beds that follow the simulation's activity,
/// one-shot effects, and a soft generative pentatonic soundtrack. No audio assets, no licensing.
///
/// Threading: the main thread writes targets/one-shots into `Synth` under an unfair lock; the
/// real-time render callback only ever *tries* the lock, so it never blocks.
@MainActor
final class AudioEngine {
    enum Effect: Sendable { case dig, gate, blast, cupFilled, win, fail, tap }

    var soundEnabled = true {
        didSet { let on = soundEnabled; synth.update { $0.sfxOn = on } }
    }
    var musicEnabled = true {
        didSet { let on = musicEnabled; synth.update { $0.musicOn = on } }
    }

    private let engine = AVAudioEngine()
    private let synth = Synth()
    private var started = false
    private var lastDig = 0.0

    func start() {
        guard !started else { return }
        let session = AVAudioSession.sharedInstance()
        // Ambient: respects the silent switch and mixes with the player's own music.
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
        let node = AudioEngine.makeSourceNode(format: format, synth: synth)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
        do {
            try engine.start()
            started = true
        } catch {
            started = false
        }
    }

    /// Built outside the main actor so the render block isn't main-actor isolated: it runs on the
    /// real-time audio thread.
    nonisolated private static func makeSourceNode(format: AVAudioFormat, synth: Synth) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let out = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            synth.render(into: out, frames: Int(frameCount))
            return noErr
        }
    }

    /// Pour-bed intensities from the last tick's movement counts.
    func update(activity a: Activity) {
        guard started else { return }
        func level(_ n: Int, _ full: Double) -> Float { Float(min(1, Double(n) / full)) }
        synth.update {
            $0.target.sand = level(a.sand, 120)
            $0.target.water = level(a.water, 200)
            $0.target.lava = level(a.lava, 60)
            $0.target.fire = level(a.burning, 40)
            $0.target.sizzle = level(a.reactions, 4)
        }
    }

    /// Silences pour beds (pause, results screen, leaving a level).
    func quiet() { synth.update { $0.target = .init() } }

    func play(_ effect: Effect) {
        guard started, soundEnabled else { return }
        if effect == .dig {
            let now = CACurrentMediaTime()
            guard now - lastDig > 0.07 else { return }
            lastDig = now
        }
        synth.update { $0.pending.append(effect) }
    }
}

// MARK: - Real-time synth

private struct Beds: Sendable {
    var sand: Float = 0, water: Float = 0, lava: Float = 0, fire: Float = 0, sizzle: Float = 0
}

private struct Shared: Sendable {
    var target = Beds()
    var pending: [AudioEngine.Effect] = []
    var sfxOn = true
    var musicOn = true
}

private final class Synth: @unchecked Sendable {
    static let sampleRate = 44_100.0
    private let lock = OSAllocatedUnfairLock(initialState: Shared())

    // Render-thread-only state (never touched elsewhere).
    private var beds = Beds()
    private var target = Beds()
    private var sfxOn = true
    private var musicOn = true
    private var rng: UInt32 = 0x1234_5678
    private var lpWater: Float = 0, lpWater2: Float = 0, brown: Float = 0, hpPrev: Float = 0, lpSand: Float = 0
    private var bubblePhase: Float = 0, bubbleFreq: Float = 0, bubbleAmp: Float = 0
    private var voices: [Voice] = []
    private var music = Music()

    func update(_ body: (inout Shared) -> Void) {
        lock.withLockUnchecked { body(&$0) }
    }

    @inline(__always) private func noise() -> Float {
        rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5
        return Float(rng) / Float(UInt32.max) * 2 - 1
    }

    func render(into out: UnsafeMutablePointer<Float>, frames: Int) {
        // Pull new targets/effects without ever blocking the audio thread.
        let fresh = lock.withLockIfAvailableUnchecked { (s: inout Shared) -> Shared in
            let copy = s
            s.pending.removeAll(keepingCapacity: true)
            return copy
        }
        if let fresh {
            target = fresh.target
            sfxOn = fresh.sfxOn
            musicOn = fresh.musicOn
            for e in fresh.pending where voices.count < 24 { voices.append(Voice(effect: e)) }
        }

        let sr = Float(Synth.sampleRate)
        let smooth: Float = 0.0008
        for i in 0..<frames {
            beds.sand += (target.sand - beds.sand) * smooth
            beds.water += (target.water - beds.water) * smooth
            beds.lava += (target.lava - beds.lava) * smooth
            beds.fire += (target.fire - beds.fire) * smooth
            beds.sizzle += (target.sizzle - beds.sizzle) * smooth * 4

            var s: Float = 0
            if sfxOn {
                // Sand: bright, grainy hiss (high-passed noise gated by random grains).
                let n = noise()
                let hp = n - hpPrev; hpPrev = n
                lpSand += (hp - lpSand) * 0.35
                let grain: Float = noise() > 0.2 ? 1 : 0.25
                s += lpSand * grain * beds.sand * 0.22

                // Water: low-passed noise plus random bubble chirps.
                lpWater += (noise() - lpWater) * 0.05
                lpWater2 += (lpWater - lpWater2) * 0.05
                s += lpWater2 * beds.water * 0.9
                if bubbleAmp < 0.001, beds.water > 0.05, noise() > 0.9995 - beds.water * 0.002 {
                    bubbleFreq = 300 + (noise() + 1) * 400
                    bubbleAmp = 0.12 * beds.water
                }
                if bubbleAmp > 0.0005 {
                    bubblePhase += bubbleFreq / sr * 2 * .pi
                    bubbleFreq *= 1.00012 // rising chirp
                    s += sin(bubblePhase) * bubbleAmp
                    bubbleAmp *= 0.9993
                }

                // Lava: brown-noise rumble.
                brown = (brown + noise() * 0.02) * 0.998
                s += brown * beds.lava * 1.4

                // Fire / sizzle: sparse crackles.
                if noise() > 1 - 0.002 * (beds.fire + beds.sizzle) { s += noise() * 0.35 }

                // One-shot effects.
                var v = 0
                while v < voices.count {
                    s += voices[v].next(sr: sr, noise: noise())
                    if voices[v].done { voices.swapAt(v, voices.count - 1); voices.removeLast() } else { v += 1 }
                }
            } else if !voices.isEmpty {
                voices.removeAll()
            }

            if musicOn { s += music.next(sr: sr, noise: noise()) }
            out[i] = max(-1, min(1, s))
        }
    }
}

private struct Voice {
    let effect: AudioEngine.Effect
    var t: Float = 0
    var phase: Float = 0
    var lp: Float = 0
    var done = false

    init(effect: AudioEngine.Effect) { self.effect = effect }

    private var length: Float {
        switch effect {
        case .dig: return 0.07
        case .tap: return 0.03
        case .gate: return 0.28
        case .blast: return 0.9
        case .cupFilled: return 0.7
        case .win: return 1.4
        case .fail: return 0.7
        }
    }

    mutating func next(sr: Float, noise: Float) -> Float {
        let dt = 1 / sr
        defer {
            t += dt
            if t >= length { done = true }
        }
        let env = max(0, 1 - t / length)
        switch effect {
        case .dig:
            lp += (noise - lp) * 0.2
            return lp * env * env * 0.5
        case .tap:
            return noise * env * 0.15
        case .gate:
            let f: Float = 140 * (1 - 0.5 * t / length)
            phase += f * dt * 2 * .pi
            let click: Float = t < 0.01 ? noise * 0.4 : 0
            return (sin(phase) * 0.45 + click) * env * env
        case .blast:
            lp += (noise - lp) * (0.3 * env + 0.02)
            phase += 48 * dt * 2 * .pi
            return (lp * 0.9 + sin(phase) * 0.5) * env * env
        case .cupFilled:
            phase += 880 * dt * 2 * .pi
            return (sin(phase) + 0.5 * sin(phase * 1.5)) * 0.12 * env * env
        case .win:
            // C major arpeggio, one note every 120 ms.
            let notes: [Float] = [523.25, 659.25, 783.99, 1046.5]
            let idx = min(notes.count - 1, Int(t / 0.12))
            let local = t - Float(idx) * 0.12
            phase += notes[idx] * dt * 2 * .pi
            let e = exp(-local * 6)
            return (sin(phase) + 0.3 * sin(phase * 2)) * 0.13 * e * env
        case .fail:
            let f: Float = 330 * (1 - 0.45 * t / length)
            phase += f * dt * 2 * .pi
            return (sin(phase) > 0 ? 1 : -1) * 0.05 * env
        }
    }
}

/// Generative ambient soundtrack: slow pentatonic pad chords plus occasional soft plucks.
private struct Music {
    // A minor pentatonic across two octaves.
    private let scale: [Float] = [220, 261.63, 293.66, 329.63, 392, 440, 523.25, 587.33, 659.25, 783.99]
    private let chords: [[Int]] = [[0, 2, 5], [1, 3, 6], [2, 4, 7], [0, 3, 5]]
    private var t: Float = 0
    private var chord = 0
    private var padPhase: [Float] = [0, 0, 0]
    private var pluckFreq: Float = 0
    private var pluckPhase: Float = 0
    private var pluckAmp: Float = 0
    private var nextPluck: Float = 2

    mutating func next(sr: Float, noise: Float) -> Float {
        let dt = 1 / sr
        t += dt
        let barLength: Float = 6
        if t >= barLength {
            t -= barLength
            chord = (chord + 1) % chords.count
        }
        // Pad: fade in/out across each bar so chord changes are seamless.
        let fade = min(1, min(t, barLength - t) / 1.5)
        var s: Float = 0
        for v in 0..<3 {
            let f = scale[chords[chord][v]] / 2
            padPhase[v] += f * dt * 2 * .pi
            if padPhase[v] > 2 * .pi { padPhase[v] -= 2 * .pi }
            s += sin(padPhase[v]) * 0.018 * fade
        }
        // Plucks.
        nextPluck -= dt
        if nextPluck <= 0 {
            let idx = Int((noise + 1) * 0.5 * Float(scale.count - 1))
            pluckFreq = scale[max(0, min(scale.count - 1, idx))]
            pluckAmp = 0.035
            nextPluck = 0.8 + (noise + 1) * 0.9
        }
        if pluckAmp > 0.0001 {
            pluckPhase += pluckFreq * dt * 2 * .pi
            if pluckPhase > 2 * .pi { pluckPhase -= 2 * .pi }
            s += (sin(pluckPhase) + 0.25 * sin(pluckPhase * 3)) * pluckAmp
            pluckAmp *= 0.99985
        }
        return s
    }
}
