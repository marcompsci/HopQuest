import Foundation

// Music Maker (v4.2): rainbow keys, four instruments, and three music games. Notes are synthesized on the
// device (Synth.instrumentNote), so there are no sound files. Plain Swift, tested in Tests/Learn.

enum Instrument: String, CaseIterable, Codable, Identifiable {
    case piano, xylophone, flute, drums

    var id: String { rawValue }

    var title: String {
        switch self {
        case .piano: return "Piano"
        case .xylophone: return "Xylophone"
        case .flute: return "Flute"
        case .drums: return "Drums"
        }
    }

    var emoji: String {
        switch self {
        case .piano: return "🎹"
        case .xylophone: return "🎵"
        case .flute: return "🪈"
        case .drums: return "🥁"
        }
    }
}

/// The eight rainbow keys: C D E F G A B C (do re mi fa sol la ti do).
enum MusicKeys {
    static let names = ["C", "D", "E", "F", "G", "A", "B", "C"]
    static let solfege = ["do", "re", "mi", "fa", "sol", "la", "ti", "do"]
    /// MIDI note numbers (middle C = 60).
    static let midi = [60, 62, 64, 65, 67, 69, 71, 72]
    static let colors: [UInt32] = [0xFF5A5F, 0xFF9F1C, 0xFFD23F, 0x34C77B, 0x2EC4B6, 0x4D96FF, 0x9B6BDF, 0xFF8CC6]
    /// Drum pads, used instead of keys when the instrument is drums.
    static let drumNames = ["Boom", "Tap", "Tss", "Clap"]
    static let drumEmoji = ["🥁", "🪘", "🔔", "👏"]

    static var count: Int { names.count }

    static func hz(_ key: Int) -> Double {
        440 * pow(2, Double(midi[max(0, min(count - 1, key))] - 69) / 12)
    }
}

/// A public-domain tune to learn, as key numbers (0 = low C … 7 = high C).
struct Tune: Equatable, Identifiable {
    let id: String
    let title: String
    let keys: [Int]
}

enum MusicGame: String, CaseIterable, Codable, Identifiable {
    case echo, rhythm, learnTune

    var id: String { rawValue }

    var title: String {
        switch self {
        case .echo: return "Echo Me"
        case .rhythm: return "Drum Copy"
        case .learnTune: return "Learn a Song"
        }
    }

    var icon: String {
        switch self {
        case .echo: return "🦜"
        case .rhythm: return "🥁"
        case .learnTune: return "🎶"
        }
    }

    var intro: String {
        switch self {
        case .echo: return "Listen to the notes, then play them back in the same order."
        case .rhythm: return "Listen to the drums, then copy the beat."
        case .learnTune: return "Follow the glowing keys to play a whole song."
        }
    }
}

enum MusicBank {
    static let tunes: [Tune] = [
        // "Twinkle, Twinkle, Little Star" (traditional, public domain): first two lines
        Tune(id: "twinkle", title: "Twinkle, Twinkle", keys: [0, 0, 4, 4, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0]),
        // "Mary Had a Little Lamb" (traditional, public domain)
        Tune(id: "mary", title: "Mary Had a Little Lamb", keys: [2, 1, 0, 1, 2, 2, 2, 1, 1, 1, 2, 4, 4]),
        // "Hot Cross Buns" (traditional, public domain)
        Tune(id: "buns", title: "Hot Cross Buns", keys: [2, 1, 0, 2, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 1, 0]),
        // "Ode to Joy" (Beethoven, 1824, public domain): opening line
        Tune(id: "joy", title: "Ode to Joy", keys: [2, 2, 3, 4, 4, 3, 2, 1, 0, 0, 1, 2, 2, 1, 1]),
    ]

    /// Echo Me patterns get longer each round: 3, 3, 4, 4, 5 notes. Neighboring notes never repeat, so every tap is clear.
    static func echoPatterns<G: RandomNumberGenerator>(rounds: Int = 5, using rng: inout G) -> [[Int]] {
        (0..<rounds).map { i in
            let length = 3 + i / 2
            var out: [Int] = []
            while out.count < length {
                // stay in the first five keys for short patterns, so little hands can find them
                let top = length <= 3 ? 4 : MusicKeys.count - 1
                let k = Int.random(in: 0...top, using: &rng)
                if k != out.last { out.append(k) }
            }
            return out
        }
    }

    /// Drum Copy patterns: pads 0...3, 3 to 5 hits.
    static func rhythmPatterns<G: RandomNumberGenerator>(rounds: Int = 5, using rng: inout G) -> [[Int]] {
        (0..<rounds).map { i in
            let length = 3 + i / 2
            return (0..<length).map { _ in Int.random(in: 0..<MusicKeys.drumNames.count, using: &rng) }
        }
    }

    static func echoPatterns(rounds: Int = 5) -> [[Int]] {
        var g = SystemRandomNumberGenerator()
        return echoPatterns(rounds: rounds, using: &g)
    }

    static func rhythmPatterns(rounds: Int = 5) -> [[Int]] {
        var g = SystemRandomNumberGenerator()
        return rhythmPatterns(rounds: rounds, using: &g)
    }
}

/// Checks a child's taps against a pattern as they go.
struct PatternCheck: Equatable {
    let pattern: [Int]
    private(set) var position = 0
    private(set) var mistakes = 0

    init(_ pattern: [Int]) { self.pattern = pattern }

    enum Result: Equatable { case good, wrong, done }

    var isDone: Bool { position >= pattern.count }
    /// The key to tap next (for "follow the glowing key").
    var next: Int? { isDone ? nil : pattern[position] }

    /// A wrong tap doesn't start over: the child just tries that note again.
    mutating func tap(_ key: Int) -> Result {
        guard !isDone else { return .done }
        if key == pattern[position] {
            position += 1
            return isDone ? .done : .good
        }
        mistakes += 1
        return .wrong
    }
}

/// The song builder: 8 steps, each one key (or a rest), saved so kids keep their song.
/// v9.4: each step can also have a drum (the beat row), and a song has a speed.
struct SongSteps: Codable, Equatable {
    static let length = 8
    /// Speeds to pick from: seconds per step (slow turtle, walking, quick rabbit).
    static let tempos: [Double] = [0.45, 0.33, 0.24]
    static let tempoNames = ["Slow", "Walk", "Quick"]
    static let tempoEmoji = ["🐢", "🚶", "🐇"]

    /// Key per step (nil = rest).
    var steps: [Int?] = Array(repeating: nil, count: length)
    /// Drum pad per step (nil = no drum), 0…3 like the drum pads: Boom, Tap, Tss, Clap.
    var beats: [Int?] = Array(repeating: nil, count: length)
    var instrument: Instrument = .xylophone
    /// Index into `tempos` (1 = walking speed, the speed songs had before v9.4).
    var tempo = 1

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let raw = (try? c.decodeIfPresent([Int?].self, forKey: .steps)) ?? []
        steps = (0..<Self.length).map { i in
            guard i < raw.count, let k = raw[i], (0..<MusicKeys.count).contains(k) else { return nil }
            return k
        }
        let rawBeats = (try? c.decodeIfPresent([Int?].self, forKey: .beats)) ?? []
        beats = (0..<Self.length).map { i in
            guard i < rawBeats.count, let d = rawBeats[i], (0..<MusicKeys.drumNames.count).contains(d) else { return nil }
            return d
        }
        instrument = (try? c.decodeIfPresent(Instrument.self, forKey: .instrument)) ?? .xylophone
        let t = (try? c.decodeIfPresent(Int.self, forKey: .tempo)) ?? 1
        tempo = (0..<Self.tempos.count).contains(t) ? t : 1
    }

    /// Tapping a cell sets that step's key, or clears it if it's already that key.
    mutating func toggle(step: Int, key: Int) {
        guard (0..<Self.length).contains(step), (0..<MusicKeys.count).contains(key) else { return }
        steps[step] = steps[step] == key ? nil : key
    }

    /// Tapping a beat box goes: no drum → Boom → Tap → Tss → Clap → no drum.
    mutating func cycleBeat(step: Int) {
        guard (0..<Self.length).contains(step) else { return }
        if let d = beats[step] {
            beats[step] = d + 1 < MusicKeys.drumNames.count ? d + 1 : nil
        } else {
            beats[step] = 0
        }
    }

    /// Seconds per step at this song's speed.
    var stepSeconds: Double { Self.tempos[max(0, min(Self.tempos.count - 1, tempo))] }

    var isEmpty: Bool { steps.allSatisfy { $0 == nil } && beats.allSatisfy { $0 == nil } }

    /// How many notes and drums the song has (for the shelf and VoiceOver).
    var noteCount: Int { steps.compactMap { $0 }.count }
    var beatCount: Int { beats.compactMap { $0 }.count }

    /// The song read out for VoiceOver: "C, E, rest, G…" with the drums after.
    var spoken: String {
        let notes = steps.map { $0.map { MusicKeys.names[$0] } ?? "rest" }.joined(separator: ", ")
        guard beatCount > 0 else { return "Notes: \(notes)." }
        let drums = beats.map { $0.map { MusicKeys.drumNames[$0] } ?? "quiet" }.joined(separator: ", ")
        return "Notes: \(notes). Drums: \(drums)."
    }
}

/// A song kept on the song shelf (v9.4). Songs are numbered, never named, so there's nothing to type.
struct ShelfSong: Codable, Equatable, Identifiable {
    var id: String
    var number: Int
    var song: SongSteps
    /// One of the rainbow key colors, so songs are easy to tell apart.
    var color: Int { (number - 1) % MusicKeys.colors.count }
    var title: String { "Song \(number)" }
}

/// Music Maker progress: best stars per game (best only), the song you're building, and the song shelf.
struct MusicSave: Codable, Equatable {
    static let shelfSize = 6

    var best: [String: Int] = [:]
    /// Songs from "Learn a Song" played all the way through.
    var tunesLearned: Set<String> = []
    var song = SongSteps()
    /// Saved songs, newest first (v9.4), at most six.
    var shelf: [ShelfSong] = []
    /// Which shelf song the builder has open, so keeping it again updates it instead of making a copy.
    var openSongID: String?
    /// How many songs have ever been kept, for numbering.
    var songsMade = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        tunesLearned = (try? c.decodeIfPresent(Set<String>.self, forKey: .tunesLearned)) ?? []
        song = (try? c.decodeIfPresent(SongSteps.self, forKey: .song)) ?? SongSteps()
        shelf = Array(((try? c.decodeIfPresent([ShelfSong].self, forKey: .shelf)) ?? []).prefix(Self.shelfSize))
        openSongID = try? c.decodeIfPresent(String.self, forKey: .openSongID)
        songsMade = max((try? c.decodeIfPresent(Int.self, forKey: .songsMade)) ?? 0, shelf.map(\.number).max() ?? 0)
        if let id = openSongID, !shelf.contains(where: { $0.id == id }) { openSongID = nil }
    }

    enum KeepResult: Equatable { case kept(Int), updated(Int), empty, full }

    /// Puts the builder's song on the shelf. A song opened from the shelf is updated in place.
    @discardableResult
    mutating func keepSong() -> KeepResult {
        guard !song.isEmpty else { return .empty }
        if let id = openSongID, let i = shelf.firstIndex(where: { $0.id == id }) {
            shelf[i].song = song
            return .updated(shelf[i].number)
        }
        guard shelf.count < Self.shelfSize else { return .full }
        songsMade += 1
        let id = "song-\(songsMade)-\(Int.random(in: 1000...9999))"
        shelf.insert(ShelfSong(id: id, number: songsMade, song: song), at: 0)
        openSongID = id
        return .kept(songsMade)
    }

    /// Opens a shelf song in the builder.
    mutating func openSong(_ id: String) {
        guard let s = shelf.first(where: { $0.id == id }) else { return }
        song = s.song
        openSongID = id
    }

    /// A fresh, empty song (the shelf keeps the old one).
    mutating func newSong() {
        song = SongSteps()
        openSongID = nil
    }

    mutating func deleteSong(_ id: String) {
        shelf.removeAll { $0.id == id }
        if openSongID == id { openSongID = nil }
    }

    func best(_ g: MusicGame) -> Int { best[g.rawValue] ?? 0 }

    mutating func record(_ g: MusicGame, stars: Int) -> Int {
        let old = best(g)
        guard stars > old else { return 0 }
        best[g.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = MusicGame.allCases.count * 3
}
