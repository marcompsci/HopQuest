import Foundation

// The Writing Desk (v4.4): trace letters, numbers and short words with a finger, the way first graders learn to print.
// Plain Swift (no UIKit), so the letter shapes and the tracing checker are tested in Tests/Learn.
//
// Every letter lives in a 1-unit-tall box, like lined school paper:
//   y 0.0 = top line (capitals and tall letters), y 0.4 = dashed middle line, y 0.8 = baseline, y 1.0 = tails (g, j, p, q, y).
// x runs from 0 to the letter's width (at most 0.62). Strokes are listed in the order kids are taught to write them,
// and each stroke runs in the direction the pencil moves.

struct PenPoint: Equatable {
    var x: Double
    var y: Double
    init(_ x: Double, _ y: Double) { self.x = x; self.y = y }

    func distance(to p: PenPoint) -> Double { ((x - p.x) * (x - p.x) + (y - p.y) * (y - p.y)).squareRoot() }
}

/// One letter or number: its strokes, in writing order.
struct Glyph: Equatable {
    let character: String
    let strokes: [[PenPoint]]

    var width: Double { (strokes.flatMap { $0 }.map(\.x).max() ?? 0.5) }
    var minX: Double { (strokes.flatMap { $0 }.map(\.x).min() ?? 0) }
    var maxY: Double { (strokes.flatMap { $0 }.map(\.y).max() ?? 0.8) }
}

// MARK: - Drawing helpers

/// A straight line through the given points.
private func line(_ pts: (Double, Double)...) -> [PenPoint] {
    var out: [PenPoint] = []
    for (a, b) in zip(pts, pts.dropFirst()) {
        let len = PenPoint(a.0, a.1).distance(to: PenPoint(b.0, b.1))
        let n = max(2, Int((len / 0.03).rounded(.up)))
        for i in 0..<n {
            let t = Double(i) / Double(n)
            out.append(PenPoint(a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t))
        }
    }
    if let last = pts.last { out.append(PenPoint(last.0, last.1)) }
    return out
}

/// An arc of an oval. Angles are in degrees with y pointing down: 0 = right, 90 = bottom, -90 = top, 180 = left.
/// Going from a bigger angle to a smaller one draws counterclockwise on screen (like the letter c).
private func arc(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, from a: Double, to b: Double) -> [PenPoint] {
    let span = abs(b - a)
    let n = max(4, Int((span / 8).rounded(.up)))
    return (0...n).map { i in
        let t = (a + (b - a) * Double(i) / Double(n)) * .pi / 180
        return PenPoint(cx + rx * cos(t), cy + ry * sin(t))
    }
}

/// Joins pieces into one stroke (the pencil doesn't lift).
private func joined(_ parts: [PenPoint]...) -> [PenPoint] {
    var out: [PenPoint] = []
    for p in parts {
        if let last = out.last, let first = p.first, last.distance(to: first) < 0.001 {
            out += p.dropFirst()
        } else {
            out += p
        }
    }
    return out
}

/// A dot (i and j): a very short stroke, done with a tap.
private func dot(_ x: Double, _ y: Double) -> [PenPoint] { [PenPoint(x, y), PenPoint(x, y + 0.02)] }

// MARK: - The alphabet

enum Alphabet {
    static let capitals: [Glyph] = [
        Glyph(character: "A", strokes: [line((0.3, 0), (0.05, 0.8)), line((0.3, 0), (0.55, 0.8)), line((0.14, 0.52), (0.46, 0.52))]),
        Glyph(character: "B", strokes: [line((0.1, 0), (0.1, 0.8)),
                                        joined(line((0.1, 0), (0.32, 0)), arc(0.32, 0.2, 0.18, 0.2, from: -90, to: 90), line((0.32, 0.4), (0.1, 0.4))),
                                        joined(line((0.1, 0.4), (0.34, 0.4)), arc(0.34, 0.6, 0.2, 0.2, from: -90, to: 90), line((0.34, 0.8), (0.1, 0.8)))]),
        Glyph(character: "C", strokes: [arc(0.33, 0.4, 0.28, 0.4, from: -45, to: -315)]),
        Glyph(character: "D", strokes: [line((0.1, 0), (0.1, 0.8)),
                                        joined(line((0.1, 0), (0.24, 0)), arc(0.24, 0.4, 0.3, 0.4, from: -90, to: 90), line((0.24, 0.8), (0.1, 0.8)))]),
        Glyph(character: "E", strokes: [line((0.1, 0), (0.1, 0.8)), line((0.1, 0), (0.5, 0)), line((0.1, 0.4), (0.42, 0.4)), line((0.1, 0.8), (0.5, 0.8))]),
        Glyph(character: "F", strokes: [line((0.1, 0), (0.1, 0.8)), line((0.1, 0), (0.5, 0)), line((0.1, 0.4), (0.42, 0.4))]),
        Glyph(character: "G", strokes: [joined(arc(0.33, 0.4, 0.28, 0.4, from: -45, to: -360), line((0.61, 0.4), (0.38, 0.4)))]),
        Glyph(character: "H", strokes: [line((0.1, 0), (0.1, 0.8)), line((0.5, 0), (0.5, 0.8)), line((0.1, 0.4), (0.5, 0.4))]),
        Glyph(character: "I", strokes: [line((0.3, 0), (0.3, 0.8)), line((0.1, 0), (0.5, 0)), line((0.1, 0.8), (0.5, 0.8))]),
        Glyph(character: "J", strokes: [joined(line((0.45, 0), (0.45, 0.6)), arc(0.28, 0.6, 0.17, 0.2, from: 0, to: 170))]),
        Glyph(character: "K", strokes: [line((0.1, 0), (0.1, 0.8)), line((0.5, 0), (0.1, 0.45)), line((0.24, 0.3), (0.52, 0.8))]),
        Glyph(character: "L", strokes: [line((0.1, 0), (0.1, 0.8), (0.5, 0.8))]),
        Glyph(character: "M", strokes: [line((0.06, 0), (0.06, 0.8)), line((0.06, 0), (0.31, 0.55), (0.56, 0), (0.56, 0.8))]),
        Glyph(character: "N", strokes: [line((0.1, 0), (0.1, 0.8)), line((0.1, 0), (0.5, 0.8), (0.5, 0))]),
        Glyph(character: "O", strokes: [arc(0.33, 0.4, 0.28, 0.4, from: -90, to: -450)]),
        Glyph(character: "P", strokes: [line((0.1, 0), (0.1, 0.8)),
                                        joined(line((0.1, 0), (0.3, 0)), arc(0.3, 0.2, 0.2, 0.2, from: -90, to: 90), line((0.3, 0.4), (0.1, 0.4)))]),
        Glyph(character: "Q", strokes: [arc(0.33, 0.4, 0.28, 0.4, from: -90, to: -450), line((0.36, 0.56), (0.62, 0.86))]),
        Glyph(character: "R", strokes: [line((0.1, 0), (0.1, 0.8)),
                                        joined(line((0.1, 0), (0.3, 0)), arc(0.3, 0.2, 0.2, 0.2, from: -90, to: 90), line((0.3, 0.4), (0.1, 0.4))),
                                        line((0.26, 0.4), (0.52, 0.8))]),
        Glyph(character: "S", strokes: [joined(arc(0.31, 0.2, 0.22, 0.2, from: -20, to: -270), arc(0.31, 0.6, 0.22, 0.2, from: -90, to: 160))]),
        Glyph(character: "T", strokes: [line((0.05, 0), (0.55, 0)), line((0.3, 0), (0.3, 0.8))]),
        Glyph(character: "U", strokes: [joined(line((0.1, 0), (0.1, 0.55)), arc(0.3, 0.55, 0.2, 0.25, from: 180, to: 0), line((0.5, 0.55), (0.5, 0)))]),
        Glyph(character: "V", strokes: [line((0.05, 0), (0.3, 0.8), (0.55, 0))]),
        Glyph(character: "W", strokes: [line((0.02, 0), (0.16, 0.8), (0.31, 0.25), (0.46, 0.8), (0.6, 0))]),
        Glyph(character: "X", strokes: [line((0.06, 0), (0.54, 0.8)), line((0.54, 0), (0.06, 0.8))]),
        Glyph(character: "Y", strokes: [line((0.05, 0), (0.3, 0.4)), line((0.55, 0), (0.3, 0.4)), line((0.3, 0.4), (0.3, 0.8))]),
        Glyph(character: "Z", strokes: [line((0.06, 0), (0.54, 0), (0.06, 0.8), (0.54, 0.8))]),
    ]

    static let lowercase: [Glyph] = [
        Glyph(character: "a", strokes: [arc(0.28, 0.6, 0.2, 0.2, from: -20, to: -380), line((0.48, 0.4), (0.48, 0.8))]),
        Glyph(character: "b", strokes: [line((0.1, 0), (0.1, 0.8)), arc(0.3, 0.6, 0.2, 0.2, from: 180, to: 540)]),
        Glyph(character: "c", strokes: [arc(0.3, 0.6, 0.2, 0.2, from: -45, to: -315)]),
        Glyph(character: "d", strokes: [arc(0.3, 0.6, 0.2, 0.2, from: -10, to: -370), line((0.5, 0), (0.5, 0.8))]),
        Glyph(character: "e", strokes: [joined(line((0.1, 0.6), (0.5, 0.6)), arc(0.3, 0.6, 0.2, 0.2, from: 0, to: -315))]),
        Glyph(character: "f", strokes: [joined(arc(0.42, 0.12, 0.13, 0.12, from: -20, to: -180), line((0.29, 0.12), (0.29, 0.8))),
                                        line((0.12, 0.4), (0.46, 0.4))]),
        Glyph(character: "g", strokes: [arc(0.3, 0.6, 0.2, 0.2, from: -10, to: -370),
                                        joined(line((0.5, 0.4), (0.5, 0.92)), arc(0.32, 0.92, 0.18, 0.08, from: 0, to: 165))]),
        Glyph(character: "h", strokes: [line((0.1, 0), (0.1, 0.8)),
                                        joined(arc(0.3, 0.58, 0.2, 0.18, from: 180, to: 360), line((0.5, 0.58), (0.5, 0.8)))]),
        Glyph(character: "i", strokes: [line((0.3, 0.4), (0.3, 0.8)), dot(0.3, 0.22)]),
        Glyph(character: "j", strokes: [joined(line((0.36, 0.4), (0.36, 0.92)), arc(0.21, 0.92, 0.15, 0.08, from: 0, to: 165)), dot(0.36, 0.22)]),
        Glyph(character: "k", strokes: [line((0.1, 0), (0.1, 0.8)), line((0.46, 0.4), (0.1, 0.62)), line((0.22, 0.55), (0.48, 0.8))]),
        Glyph(character: "l", strokes: [line((0.25, 0), (0.25, 0.8))]),
        Glyph(character: "m", strokes: [line((0.05, 0.4), (0.05, 0.8)),
                                        joined(arc(0.17, 0.56, 0.12, 0.14, from: 180, to: 360), line((0.29, 0.56), (0.29, 0.8))),
                                        joined(arc(0.41, 0.56, 0.12, 0.14, from: 180, to: 360), line((0.53, 0.56), (0.53, 0.8)))]),
        Glyph(character: "n", strokes: [line((0.1, 0.4), (0.1, 0.8)),
                                        joined(arc(0.3, 0.58, 0.2, 0.18, from: 180, to: 360), line((0.5, 0.58), (0.5, 0.8)))]),
        Glyph(character: "o", strokes: [arc(0.3, 0.6, 0.2, 0.2, from: -90, to: -450)]),
        Glyph(character: "p", strokes: [line((0.1, 0.4), (0.1, 1.0)), arc(0.3, 0.6, 0.2, 0.2, from: 180, to: 540)]),
        Glyph(character: "q", strokes: [arc(0.3, 0.6, 0.2, 0.2, from: -10, to: -370), line((0.5, 0.4), (0.5, 1.0))]),
        Glyph(character: "r", strokes: [line((0.12, 0.4), (0.12, 0.8)), arc(0.3, 0.58, 0.18, 0.16, from: 180, to: 300)]),
        Glyph(character: "s", strokes: [joined(arc(0.28, 0.5, 0.16, 0.1, from: -20, to: -270), arc(0.28, 0.7, 0.16, 0.1, from: -90, to: 160))]),
        Glyph(character: "t", strokes: [joined(line((0.28, 0.1), (0.28, 0.72)), arc(0.38, 0.72, 0.1, 0.08, from: 180, to: 40)),
                                        line((0.12, 0.4), (0.45, 0.4))]),
        Glyph(character: "u", strokes: [joined(line((0.1, 0.4), (0.1, 0.6)), arc(0.3, 0.6, 0.2, 0.2, from: 180, to: 0), line((0.5, 0.6), (0.5, 0.4))),
                                        line((0.5, 0.4), (0.5, 0.8))]),
        Glyph(character: "v", strokes: [line((0.08, 0.4), (0.3, 0.8), (0.52, 0.4))]),
        Glyph(character: "w", strokes: [line((0.02, 0.4), (0.15, 0.8), (0.29, 0.5), (0.43, 0.8), (0.56, 0.4))]),
        Glyph(character: "x", strokes: [line((0.08, 0.4), (0.5, 0.8)), line((0.5, 0.4), (0.08, 0.8))]),
        Glyph(character: "y", strokes: [line((0.08, 0.4), (0.3, 0.74)), line((0.52, 0.4), (0.16, 1.0))]),
        Glyph(character: "z", strokes: [line((0.08, 0.4), (0.5, 0.4), (0.08, 0.8), (0.5, 0.8))]),
    ]

    static let digits: [Glyph] = [
        Glyph(character: "0", strokes: [arc(0.3, 0.4, 0.24, 0.4, from: -90, to: -450)]),
        Glyph(character: "1", strokes: [line((0.16, 0.14), (0.32, 0), (0.32, 0.8))]),
        Glyph(character: "2", strokes: [joined(arc(0.3, 0.22, 0.22, 0.22, from: -160, to: 30), line((0.49, 0.33), (0.08, 0.8), (0.55, 0.8)))]),
        Glyph(character: "3", strokes: [joined(arc(0.28, 0.2, 0.2, 0.2, from: -150, to: 90), arc(0.28, 0.6, 0.22, 0.2, from: -90, to: 150))]),
        Glyph(character: "4", strokes: [line((0.42, 0), (0.05, 0.55), (0.56, 0.55)), line((0.42, 0), (0.42, 0.8))]),
        Glyph(character: "5", strokes: [joined(line((0.12, 0), (0.12, 0.38)), arc(0.3, 0.58, 0.24, 0.22, from: -124, to: 150)),
                                        line((0.12, 0), (0.5, 0))]),
        Glyph(character: "6", strokes: [joined(line((0.46, 0), (0.12, 0.5)), arc(0.32, 0.58, 0.21, 0.21, from: 202, to: -158))]),
        Glyph(character: "7", strokes: [line((0.05, 0), (0.55, 0), (0.22, 0.8))]),
        Glyph(character: "8", strokes: [joined(arc(0.3, 0.2, 0.19, 0.2, from: -30, to: -270), arc(0.3, 0.6, 0.22, 0.2, from: -90, to: 270),
                                               arc(0.3, 0.2, 0.19, 0.2, from: 90, to: -30))]),
        Glyph(character: "9", strokes: [joined(arc(0.3, 0.22, 0.2, 0.22, from: 0, to: -360), line((0.5, 0.22), (0.5, 0.8)))]),
    ]

    static func glyph(_ c: String) -> Glyph? { (capitals + lowercase + digits).first { $0.character == c } }
}

// MARK: - Checking a traced stroke

enum TraceVerdict: Equatable {
    case good
    /// The finger started far from the green dot.
    case wrongStart
    /// Too much of the line was drawn off the letter.
    case offPath
    /// Lifted before reaching the end.
    case notFinished

    /// What the helper says, kindly.
    var hint: String {
        switch self {
        case .good: return "Nice!"
        case .wrongStart: return "Start at the green dot."
        case .offPath: return "Stay close to the dotted line."
        case .notFinished: return "Keep going all the way to the end."
        }
    }
}

enum TraceChecker {
    /// How far (in letter units; a letter is 1 tall) a finger may wander and still be on the line.
    static let tolerance = 0.11
    /// How close the first touch must be to the start dot.
    static let startTolerance = 0.16

    static func distance(from p: PenPoint, to path: [PenPoint]) -> Double {
        guard path.count > 1 else { return path.first.map(p.distance(to:)) ?? .infinity }
        var best = Double.infinity
        for (a, b) in zip(path, path.dropFirst()) {
            let dx = b.x - a.x, dy = b.y - a.y
            let len2 = dx * dx + dy * dy
            let t = len2 == 0 ? 0 : max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2))
            best = min(best, p.distance(to: PenPoint(a.x + dx * t, a.y + dy * t)))
        }
        return best
    }

    static func length(_ path: [PenPoint]) -> Double { zip(path, path.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) } }

    /// Checks one finger stroke against the stroke it should trace.
    static func check(drawn: [PenPoint], against target: [PenPoint]) -> TraceVerdict {
        guard let first = drawn.first, let start = target.first else { return .notFinished }
        // a dot: any touch near it counts
        if length(target) < tolerance {
            return drawn.contains { distance(from: $0, to: target) <= startTolerance } ? .good : .wrongStart
        }
        if first.distance(to: start) > startTolerance { return .wrongStart }
        let off = drawn.filter { distance(from: $0, to: target) > tolerance }.count
        if Double(off) > Double(drawn.count) * 0.25 { return .offPath }
        // how much of the target the finger passed near
        let covered = target.filter { t in drawn.contains { $0.distance(to: t) <= tolerance } }.count
        if Double(covered) < Double(target.count) * 0.8 { return .notFinished }
        // and it has to reach the end
        if !drawn.contains(where: { $0.distance(to: target.last!) <= startTolerance }) { return .notFinished }
        return .good
    }
}

// MARK: - Games

enum WritingGame: String, CaseIterable, Codable, Identifiable {
    case capitals, lowercase, numbers, words

    var id: String { rawValue }

    var title: String {
        switch self {
        case .capitals: return "Big Letters"
        case .lowercase: return "Small Letters"
        case .numbers: return "Numbers"
        case .words: return "Write a Word"
        }
    }

    var skill: String {
        switch self {
        case .capitals: return "printing capital letters"
        case .lowercase: return "printing lowercase letters"
        case .numbers: return "writing numbers 0 to 9"
        case .words: return "writing short words"
        }
    }

    var intro: String {
        switch self {
        case .capitals: return "Trace the big letter. Start at the green dot and follow the arrow."
        case .lowercase: return "Trace the small letter. Start at the green dot and follow the arrow."
        case .numbers: return "Trace the number. Start at the green dot and follow the arrow."
        case .words: return "Write a whole word, one letter at a time!"
        }
    }
}

/// One thing to write: a letter, a number, or a word (several letters).
struct WritingRound: Equatable {
    let glyphs: [Glyph]
    /// Read aloud ("The letter B, like ball.").
    let say: String
    /// The picture for a word ("🐱"), or "".
    let picture: String
    var text: String { glyphs.map(\.character).joined() }
}

enum WritingBank {
    /// A word for each capital, so the letter is said with a picture word.
    static let letterWords: [String: String] = [
        "a": "apple", "b": "ball", "c": "cat", "d": "dog", "e": "egg", "f": "fish", "g": "goat", "h": "hat", "i": "igloo",
        "j": "jam", "k": "kite", "l": "lion", "m": "moon", "n": "nest", "o": "octopus", "p": "pig", "q": "queen", "r": "rain",
        "s": "sun", "t": "tree", "u": "umbrella", "v": "van", "w": "web", "x": "fox", "y": "yo-yo", "z": "zebra",
    ]

    static let numberWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

    static let cheers = ["Beautiful writing!", "Neat!", "You wrote it!", "Wonderful!", "Super tracing!"]

    static func rounds<G: RandomNumberGenerator>(for game: WritingGame, count: Int = 5, using rng: inout G) -> [WritingRound] {
        switch game {
        case .capitals:
            return Array(Alphabet.capitals.shuffled(using: &rng).prefix(count)).map { g in
                let w = letterWords[g.character.lowercased()] ?? ""
                return WritingRound(glyphs: [g], say: "Big \(g.character), like \(w).", picture: "")
            }
        case .lowercase:
            return Array(Alphabet.lowercase.shuffled(using: &rng).prefix(count)).map { g in
                let w = letterWords[g.character] ?? ""
                return WritingRound(glyphs: [g], say: "Small \(g.character.uppercased()), like \(w).", picture: "")
            }
        case .numbers:
            return Array(Alphabet.digits.shuffled(using: &rng).prefix(count)).map { g in
                WritingRound(glyphs: [g], say: "The number \(numberWords[Int(g.character) ?? 0]).", picture: "")
            }
        case .words:
            // three short picture words from the Reading Nook, so reading and writing practise the same words
            return Array(ReadingBank.words.shuffled(using: &rng).prefix(min(count, 3))).map { w in
                WritingRound(glyphs: w.word.compactMap { Alphabet.glyph(String($0)) },
                             say: "Write the word \(w.word). \(w.word.map { String($0).uppercased() }.joined(separator: ", ")).",
                             picture: w.emoji)
            }
        }
    }

    static func rounds(for game: WritingGame, count: Int = 5) -> [WritingRound] {
        var g = SystemRandomNumberGenerator()
        return rounds(for: game, count: count, using: &g)
    }
}

/// Writing Desk progress: best stars per game, and the letters a child has written.
struct WritingSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0
    /// Every letter and number traced at least once (for the Grown-ups page).
    var written: Set<String> = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
        written = (try? c.decodeIfPresent(Set<String>.self, forKey: .written)) ?? []
    }

    func best(_ g: WritingGame) -> Int { best[g.rawValue] ?? 0 }

    mutating func record(_ g: WritingGame, stars: Int) -> Int {
        plays += 1
        let old = best(g)
        guard stars > old else { return 0 }
        best[g.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = WritingGame.allCases.count * 3
}
