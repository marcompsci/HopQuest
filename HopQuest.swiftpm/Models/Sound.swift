import AVFoundation
import UIKit

/// Every sound in HopQuest is synthesized in code at launch — no audio files to license.
enum Sfx: CaseIterable {
    case tap, hop, coin, chime, boing, splash, whoosh, beep, go, oops, item, pop
    // pre-rendered in Assets.xcassets (see ArtSource/make_audio.py)
    case star, fanfare, tick, tock, correct

    var assetName: String? {
        switch self {
        case .star: return "sfx_star"
        case .fanfare: return "sfx_fanfare"
        case .tick: return "sfx_tick"
        case .tock: return "sfx_tock"
        case .correct: return "sfx_correct"
        default: return nil
        }
    }
}

/// Background songs (pre-rendered in Assets.xcassets as music_<name>).
enum MusicTrack: String {
    case adventure, race
}

final class SoundFX {
    static let shared = SoundFX()

    static let sfxKey = "hopquest.sfx"
    static let musicKey = "hopquest.music"

    var sfxOn: Bool { UserDefaults.standard.object(forKey: Self.sfxKey) as? Bool ?? true }
    var musicOn: Bool { UserDefaults.standard.object(forKey: Self.musicKey) as? Bool ?? true }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let musicPlayer = AVAudioPlayerNode()
    private let humPlayer = AVAudioPlayerNode()
    private let varispeed = AVAudioUnitVarispeed()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private var musicBuffer: AVAudioPCMBuffer?
    private var humBuffer: AVAudioPCMBuffer?
    private var started = false
    private var wantMusic = false
    private var humming = false
    private var track: MusicTrack = .adventure
    private var playingTrack: MusicTrack?
    private var trackBuffers: [MusicTrack: AVAudioPCMBuffer] = [:]
    private var ducked = false
    private let musicVolume: Float = 0.3

    private init() {}

    /// Sets up the audio session and engine. Safe to call many times.
    func start() {
        guard !started else { return }
        started = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for _ in 0..<8 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: format)
            players.append(p)
        }
        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        engine.attach(humPlayer)
        engine.attach(varispeed)
        engine.connect(humPlayer, to: varispeed, format: format)
        engine.connect(varispeed, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9

        for s in Sfx.allCases {
            if let name = s.assetName {
                buffers[s] = Self.loadAsset(name)
            } else {
                buffers[s] = Synth.make(s, format: format)
            }
        }
        humBuffer = Synth.engineHum(format: format)

        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.restart()
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.restart()
        }
        restart()

        // decode the songs off the main thread; fall back to the built-in tune if an asset is missing
        let fmt = format
        DispatchQueue.global(qos: .utility).async {
            var loaded: [MusicTrack: AVAudioPCMBuffer] = [:]
            for t in [MusicTrack.adventure, .race] {
                if let b = Self.loadAsset("music_\(t.rawValue)") { loaded[t] = b }
            }
            let fallback = loaded.isEmpty ? Synth.song(format: fmt) : nil
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.trackBuffers = loaded
                self.musicBuffer = fallback
                if self.wantMusic { self.startMusic() }
            }
        }
    }

    /// Reads a sound from the asset catalog into a buffer in the engine's format (44.1 kHz mono).
    private static func loadAsset(_ name: String) -> AVAudioPCMBuffer? {
        guard let data = NSDataAsset(name: name, bundle: .module)?.data ?? NSDataAsset(name: name)?.data else { return nil }
        let ext = name.hasPrefix("music_") ? "m4a" : "wav"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).\(ext)")
        do {
            try data.write(to: url, options: .atomic)
            let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
            guard file.processingFormat.sampleRate == 44_100, file.processingFormat.channelCount == 1,
                  let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return nil }
            try file.read(into: buf)
            return buf
        } catch {
            return nil
        }
    }

    private func currentSong() -> AVAudioPCMBuffer? {
        trackBuffers[track] ?? trackBuffers[.adventure] ?? musicBuffer
    }

    private func restart() {
        guard !engine.isRunning else { return }
        do { try engine.start() } catch { return }
        players.forEach { $0.play() }
        if wantMusic, let song = currentSong(), musicOn {
            musicPlayer.stop()
            musicPlayer.scheduleBuffer(song, at: nil, options: .loops)
            musicPlayer.play()
        }
    }

    // MARK: Effects

    func play(_ s: Sfx, volume: Float = 1) {
        guard sfxOn else { return }
        start()
        guard engine.isRunning, let buf = buffers[s], !players.isEmpty else { return }
        let p = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        p.volume = volume
        p.scheduleBuffer(buf, at: nil, options: .interrupts)
        if !p.isPlaying { p.play() }
    }

    // MARK: Music Maker

    private var noteBuffers: [String: AVAudioPCMBuffer] = [:]

    /// Plays one Music Maker note (key 0...7, or drum pad 0...3 for drums). Made on the device the first time.
    func playNote(_ instrument: Instrument, key: Int, volume: Float = 0.9) {
        guard sfxOn else { return }
        start()
        let id = "\(instrument.rawValue)\(key)"
        if noteBuffers[id] == nil { noteBuffers[id] = Synth.instrumentNote(instrument, key: key, format: format) }
        guard engine.isRunning, let buf = noteBuffers[id], !players.isEmpty else { return }
        let p = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        p.volume = volume
        p.scheduleBuffer(buf, at: nil, options: .interrupts)
        if !p.isPlaying { p.play() }
    }

    // MARK: Music

    func startMusic() {
        wantMusic = true
        start()
        guard musicOn, engine.isRunning, let song = currentSong() else { return }
        if musicPlayer.isPlaying && playingTrack == track { return }
        musicPlayer.stop()
        musicPlayer.volume = ducked ? musicVolume * 0.4 : musicVolume
        musicPlayer.scheduleBuffer(song, at: nil, options: .loops)
        musicPlayer.play()
        playingTrack = trackBuffers[track] != nil ? track : nil
    }

    /// Switches songs (adventure theme vs. racing theme).
    func playMusic(_ next: MusicTrack) {
        track = next
        startMusic()
    }

    func stopMusic() {
        wantMusic = false
        musicPlayer.stop()
        playingTrack = nil
    }

    /// Quieter music while the narrator is talking.
    func duckMusic(_ on: Bool) {
        ducked = on
        musicPlayer.volume = on ? musicVolume * 0.4 : musicVolume
    }

    /// Re-reads the grown-up toggles.
    func applySettings() {
        if musicOn && wantMusic {
            startMusic()
        } else {
            musicPlayer.stop()
            playingTrack = nil
        }
        if !sfxOn { stopEngineHum() }
    }

    // MARK: Engine hum (driving)

    func startEngineHum() {
        guard sfxOn else { return }
        start()
        guard engine.isRunning, let humBuffer, !humming else { return }
        humming = true
        humPlayer.volume = 0.18
        varispeed.rate = 0.7
        humPlayer.scheduleBuffer(humBuffer, at: nil, options: .loops)
        humPlayer.play()
    }

    /// 0 = idle, 1 = flat out.
    func setEngine(_ level: Float) {
        guard humming else { return }
        varispeed.rate = 0.7 + max(0, min(1, level)) * 1.5
        humPlayer.volume = 0.12 + max(0, min(1, level)) * 0.14
    }

    func stopEngineHum() {
        humming = false
        humPlayer.stop()
    }
}

// MARK: - Synthesizer

enum Synth {
    static let sr = 44_100.0

    private static func buffer(_ format: AVAudioFormat, seconds: Double, _ fill: (UnsafeMutablePointer<Float>, Int) -> Void) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(seconds * sr)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buf.floatChannelData?[0] else { return nil }
        buf.frameLength = frames
        for i in 0..<Int(frames) { data[i] = 0 }
        fill(data, Int(frames))
        return buf
    }

    enum Wave { case sine, triangle, square, saw }

    private static func osc(_ wave: Wave, _ phase: Double) -> Double {
        switch wave {
        case .sine: return sin(phase)
        case .triangle: return asin(sin(phase)) * 2 / .pi
        case .square: return sin(phase) >= 0 ? 0.6 : -0.6
        case .saw:
            let x = phase / (2 * .pi)
            return (x - floor(x)) * 2 - 1
        }
    }

    /// Adds a note into `data` starting at `start` seconds. `freq` may change over the note (for sweeps).
    private static func note(_ data: UnsafeMutablePointer<Float>, frames: Int, start: Double, dur: Double,
                             wave: Wave, vol: Double, attack: Double = 0.005, release: Double? = nil,
                             freq: (Double) -> Double) {
        let s0 = Int(start * sr)
        let n = Int(dur * sr)
        let rel = release ?? dur * 0.8
        var phase = 0.0
        for k in 0..<n {
            let i = s0 + k
            guard i >= 0 && i < frames else { continue }
            let t = Double(k) / sr
            phase += 2 * .pi * freq(t) / sr
            let a = min(1, t / attack)
            let r = t > dur - rel ? max(0, (dur - t) / rel) : 1
            data[i] += Float(osc(wave, phase) * vol * a * r * r)
        }
    }

    private static func noise(_ data: UnsafeMutablePointer<Float>, frames: Int, start: Double, dur: Double, vol: Double,
                              cutoff: (Double) -> Double, env: (Double) -> Double) {
        var rng = SeededRandom(seed: 7)
        var low = 0.0
        let s0 = Int(start * sr)
        for k in 0..<Int(dur * sr) {
            let i = s0 + k
            guard i < frames else { break }
            let t = Double(k) / sr
            let white = Double(rng.next(-1, 1))
            let alpha = min(1, 2 * .pi * cutoff(t) / sr)
            low += alpha * (white - low)
            data[i] += Float(low * vol * env(t))
        }
    }

    /// Music Maker notes: piano (bright, fading), xylophone (short, woody), flute (soft and breathy), drums (pads).
    static func instrumentNote(_ instrument: Instrument, key: Int, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let f = MusicKeys.hz(key)
        switch instrument {
        case .piano:
            return buffer(format, seconds: 1.0) { d, n in
                note(d, frames: n, start: 0, dur: 1.0, wave: .triangle, vol: 0.32, attack: 0.004, release: 0.95) { _ in f }
                note(d, frames: n, start: 0, dur: 0.6, wave: .sine, vol: 0.12, attack: 0.004, release: 0.55) { _ in f * 2 }
            }
        case .xylophone:
            return buffer(format, seconds: 0.45) { d, n in
                note(d, frames: n, start: 0, dur: 0.42, wave: .sine, vol: 0.4, attack: 0.002, release: 0.4) { _ in f * 2 }
                note(d, frames: n, start: 0, dur: 0.12, wave: .sine, vol: 0.12, attack: 0.002, release: 0.1) { _ in f * 8 }
            }
        case .flute:
            return buffer(format, seconds: 0.8) { d, n in
                note(d, frames: n, start: 0, dur: 0.78, wave: .sine, vol: 0.34, attack: 0.08, release: 0.3) { t in f * 2 * (1 + 0.004 * sin(t * 30)) }
                noise(d, frames: n, start: 0, dur: 0.2, vol: 0.05, cutoff: { _ in 3000 }, env: { t in max(0, 1 - t * 5) })
            }
        case .drums:
            switch key % 4 {
            case 0:   // boom: kick drum
                return buffer(format, seconds: 0.4) { d, n in
                    note(d, frames: n, start: 0, dur: 0.38, wave: .sine, vol: 0.7, attack: 0.001, release: 0.36) { t in 140 * exp(-t * 9) + 45 }
                }
            case 1:   // tap: tom
                return buffer(format, seconds: 0.3) { d, n in
                    note(d, frames: n, start: 0, dur: 0.28, wave: .sine, vol: 0.5, attack: 0.001, release: 0.26) { t in 260 * exp(-t * 4) + 120 }
                }
            case 2:   // tss: hi-hat
                return buffer(format, seconds: 0.18) { d, n in
                    noise(d, frames: n, start: 0, dur: 0.17, vol: 0.35, cutoff: { _ in 9000 }, env: { t in max(0, 1 - t * 6) })
                }
            default:  // clap
                return buffer(format, seconds: 0.25) { d, n in
                    for k in 0..<3 {
                        noise(d, frames: n, start: Double(k) * 0.012, dur: 0.2, vol: 0.3, cutoff: { _ in 2500 }, env: { t in max(0, 1 - t * 7) })
                    }
                }
            }
        }
    }

    static func make(_ s: Sfx, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        switch s {
        case .star, .fanfare, .tick, .tock, .correct:
            return nil   // loaded from the asset catalog instead
        case .tap:
            return buffer(format, seconds: 0.06) { d, n in
                note(d, frames: n, start: 0, dur: 0.05, wave: .sine, vol: 0.35, release: 0.045) { _ in 1100 }
            }
        case .hop:
            return buffer(format, seconds: 0.13) { d, n in
                note(d, frames: n, start: 0, dur: 0.12, wave: .triangle, vol: 0.45, release: 0.08) { t in 320 + 4000 * t }
            }
        case .coin:
            return buffer(format, seconds: 0.32) { d, n in
                note(d, frames: n, start: 0, dur: 0.07, wave: .square, vol: 0.18, release: 0.01) { _ in 1318.5 }
                note(d, frames: n, start: 0.07, dur: 0.24, wave: .square, vol: 0.18, release: 0.2) { _ in 1975.5 }
            }
        case .chime:
            return buffer(format, seconds: 0.7) { d, n in
                for (i, f) in [523.25, 659.25, 783.99, 1046.5].enumerated() {
                    note(d, frames: n, start: Double(i) * 0.08, dur: i == 3 ? 0.45 : 0.2, wave: .triangle, vol: 0.32) { _ in f }
                }
            }
        case .boing:
            return buffer(format, seconds: 0.36) { d, n in
                note(d, frames: n, start: 0, dur: 0.34, wave: .sine, vol: 0.55, release: 0.25) { t in
                    max(90, 440 * (1 - 1.9 * t)) + 35 * sin(2 * .pi * 18 * t)
                }
            }
        case .splash:
            return buffer(format, seconds: 0.5) { d, n in
                noise(d, frames: n, start: 0, dur: 0.45, vol: 0.9, cutoff: { t in 2400 - 3600 * t }, env: { t in min(1, t / 0.01) * exp(-t * 7) })
                for (i, f) in [620.0, 880, 740].enumerated() {
                    note(d, frames: n, start: 0.12 + Double(i) * 0.07, dur: 0.05, wave: .sine, vol: 0.18) { t in f + 3000 * t }
                }
            }
        case .whoosh:
            return buffer(format, seconds: 0.9) { d, n in
                noise(d, frames: n, start: 0, dur: 0.85, vol: 0.7, cutoff: { t in 300 + 3200 * t }, env: { t in sin(.pi * t / 0.85) })
            }
        case .beep:
            return buffer(format, seconds: 0.16) { d, n in
                note(d, frames: n, start: 0, dur: 0.15, wave: .square, vol: 0.16, release: 0.05) { _ in 660 }
            }
        case .go:
            return buffer(format, seconds: 0.4) { d, n in
                note(d, frames: n, start: 0, dur: 0.38, wave: .square, vol: 0.18, release: 0.15) { _ in 990 }
            }
        case .oops:
            return buffer(format, seconds: 0.36) { d, n in
                note(d, frames: n, start: 0, dur: 0.12, wave: .triangle, vol: 0.32) { _ in 392 }
                note(d, frames: n, start: 0.13, dur: 0.22, wave: .triangle, vol: 0.32) { _ in 329.6 }
            }
        case .item:
            return buffer(format, seconds: 0.4) { d, n in
                for (i, f) in [880.0, 1174.7, 1568, 2093].enumerated() {
                    note(d, frames: n, start: Double(i) * 0.05, dur: 0.18, wave: .sine, vol: 0.28) { _ in f }
                }
            }
        case .pop:
            return buffer(format, seconds: 0.1) { d, n in
                note(d, frames: n, start: 0, dur: 0.09, wave: .sine, vol: 0.45, release: 0.07) { t in 720 - 5200 * t }
            }
        }
    }

    /// A 0.5 s seamless engine loop (all frequencies fit whole cycles in 0.5 s).
    static func engineHum(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        buffer(format, seconds: 0.5) { d, n in
            for i in 0..<n {
                let t = Double(i) / sr
                let wobble = 1 + 0.15 * sin(2 * .pi * 4 * t)
                let v = (osc(.saw, 2 * .pi * 70 * t) * 0.35 + sin(2 * .pi * 140 * t) * 0.25 + sin(2 * .pi * 210 * t) * 0.1) * wobble
                d[i] = Float(v * 0.6)
            }
        }
    }

    /// A short, cheerful looping tune: C – G – Am – F, twice, with bass and soft hi-hats.
    static func song(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let bpm = 112.0
        let beat = 60 / bpm
        let bars = 8
        let total = Double(bars * 4) * beat
        func hz(_ midi: Int) -> Double { 440 * pow(2, Double(midi - 69) / 12) }
        // chord roots (MIDI) and chord tones per bar
        let chords: [[Int]] = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60],
                               [60, 64, 67], [55, 59, 62], [53, 57, 60], [55, 59, 62]]
        // melody pattern per bar: index into chord tone (+12 for octave), -1 = rest; eighth notes
        let patterns: [[Int]] = [[0, 1, 2, 1, 3, -1, 2, 1], [2, -1, 1, 0, 1, 2, -1, 3],
                                 [0, 2, 1, 2, 3, 2, 1, -1], [1, 0, -1, 1, 2, 3, 2, 1],
                                 [3, 2, 1, 2, 0, -1, 1, 2], [2, 3, -1, 2, 1, 0, 1, -1],
                                 [0, 1, 2, 3, 2, 1, 0, -1], [2, -1, 2, 1, 0, -1, -1, -1]]
        return buffer(format, seconds: total) { d, n in
            for bar in 0..<bars {
                let barStart = Double(bar * 4) * beat
                let chord = chords[bar]
                // bass: root on each beat, octave down
                for b in 0..<4 {
                    let midi = chord[0] - 24 + (b == 2 ? 7 : 0)
                    note(d, frames: n, start: barStart + Double(b) * beat, dur: beat * 0.9, wave: .triangle, vol: 0.32, attack: 0.01) { _ in hz(midi) }
                }
                // melody
                for (k, idx) in patterns[bar].enumerated() where idx >= 0 {
                    let tone = idx == 3 ? chord[0] + 12 : chord[idx]
                    let midi = tone + 12
                    note(d, frames: n, start: barStart + Double(k) * beat / 2, dur: beat / 2 * 0.95,
                         wave: .square, vol: 0.09, attack: 0.004, release: beat / 2 * 0.6) { _ in hz(midi) }
                }
                // soft hats on the off-beats
                for b in 0..<4 {
                    noise(d, frames: n, start: barStart + Double(b) * beat + beat / 2, dur: 0.04, vol: 0.12,
                          cutoff: { _ in 9000 }, env: { t in exp(-t * 80) })
                }
            }
            // keep it from clipping
            var peak: Float = 0
            for i in 0..<n { peak = max(peak, abs(d[i])) }
            if peak > 0.9 {
                let g = 0.9 / peak
                for i in 0..<n { d[i] *= g }
            }
        }
    }
}
