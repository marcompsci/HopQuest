import Foundation

// A shared engine for the newer learning places (v5.8+): Spelling Bee, Fraction Bakery and Shape Studio.
// Each place supplies games that build rounds; one screen plays them all. Plain Swift, tested in Tests/Learn.

/// 2D and 3D shapes, drawn by the app.
enum ShapeKind: String, CaseIterable, Codable {
    case circle, square, triangle, rectangle, pentagon, hexagon, oval, rhombus
    case cube, sphere, cylinder, cone, pyramid

    var name: String { rawValue }
    var isSolid: Bool { [.cube, .sphere, .cylinder, .cone, .pyramid].contains(self) }

    /// Straight sides (2D only; curves have none).
    var sides: Int {
        switch self {
        case .triangle: return 3
        case .square, .rectangle, .rhombus: return 4
        case .pentagon: return 5
        case .hexagon: return 6
        default: return 0
        }
    }

    static let flat: [ShapeKind] = [.circle, .square, .triangle, .rectangle, .pentagon, .hexagon, .oval, .rhombus]
    static let solids: [ShapeKind] = [.cube, .sphere, .cylinder, .cone, .pyramid]
}

/// What a round shows: words, a big picture, a fraction drawing, or a row of shapes.
enum QuizVisual: Equatable {
    case none
    case text(String)
    case picture(String)
    /// A pie (round) or a bar cut into `parts` equal pieces, `shaded` of them colored.
    case fraction(parts: Int, shaded: Int, round: Bool)
    case shapes([ShapeKind])
    /// A row of shapes ending in a "?" box.
    case pattern([ShapeKind])
}

struct QuizRound: Equatable {
    enum Kind: Equatable { case choose, spell }
    let kind: Kind
    let visual: QuizVisual
    let say: String
    /// Button labels (letter tiles for `.spell`).
    let choices: [String]
    /// Optional pictures for the buttons, one per choice (e.g. "which pie shows a half?").
    let choiceVisuals: [QuizVisual]
    let answer: String
    let cheer: String

    init(kind: Kind = .choose, visual: QuizVisual, say: String, choices: [String], choiceVisuals: [QuizVisual] = [], answer: String, cheer: String) {
        self.kind = kind; self.visual = visual; self.say = say; self.choices = choices
        self.choiceVisuals = choiceVisuals; self.answer = answer; self.cheer = cheer
    }
}

/// One game in a place.
struct QuizGameInfo: Equatable, Identifiable {
    let id: String
    let title: String
    let symbol: String
    let intro: String
    let skill: String
}

/// Best stars per game in a place (the same rules as every other place: stars only for beating your best).
struct PlaceSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
    }

    func best(_ id: String) -> Int { best[id] ?? 0 }

    mutating func record(_ id: String, stars: Int) -> Int {
        plays += 1
        let old = best(id)
        guard stars > old else { return 0 }
        best[id] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
}

enum QuizShuffle {
    /// The answer plus wrong choices, shuffled, with no repeats.
    static func choices<G: RandomNumberGenerator>(_ answer: String, _ wrong: [String], count: Int = 3, using rng: inout G) -> [String] {
        var out = [answer]
        for w in wrong.shuffled(using: &rng) where !out.contains(w) && out.count < count { out.append(w) }
        return out.shuffled(using: &rng)
    }
}

// MARK: - Spelling Bee

enum SpellingBank {
    /// Grade 1–2 words kids can hear and spell, with pictures where one fits.
    static let words: [(word: String, picture: String)] = [
        ("frog", "🐸"), ("duck", "🦆"), ("fish", "🐟"), ("ship", "🚢"), ("drum", "🥁"), ("tent", "⛺"), ("milk", "🥛"),
        ("crab", "🦀"), ("star", "⭐"), ("moon", "🌙"), ("tree", "🌳"), ("bird", "🐦"), ("cake", "🎂"), ("kite", "🪁"),
        ("bike", "🚲"), ("rose", "🌹"), ("snow", "❄️"), ("rain", "🌧️"), ("boat", "⛵"), ("sock", "🧦"), ("hand", "✋"),
        ("lamp", "🪔"), ("nest", "🪺"), ("clock", "🕰️"), ("train", "🚂"), ("plant", "🪴"), ("smile", "😊"), ("whale", "🐋"),
    ]

    /// Words kids often misspell, with the misspellings they really write.
    static let tricky: [(word: String, wrong: [String])] = [
        ("because", ["becuz", "becaus"]), ("said", ["sed", "siad"]), ("friend", ["frend", "freind"]), ("were", ["wer", "whre"]),
        ("they", ["thay", "tehy"]), ("there", ["thare", "ther"]), ("people", ["peple", "poeple"]), ("could", ["cud", "coud"]),
        ("again", ["agen", "agin"]), ("school", ["skool", "scool"]), ("would", ["wud", "woud"]), ("water", ["watr", "woter"]),
    ]

    /// Short-vowel words that become a new word with a magic e.
    static let magicE: [(short: String, long: String, picture: String)] = [
        ("cap", "cape", "🦸"), ("kit", "kite", "🪁"), ("tub", "tube", "🧪"), ("hop", "hope", "🙏"), ("pin", "pine", "🌲"),
        ("can", "cane", "🦯"), ("cub", "cube", "🧊"), ("rob", "robe", "🥋"), ("mad", "made", "🛠️"), ("not", "note", "🎵"),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "hearSpell", title: "Hear & Spell", symbol: "ear.fill", intro: "Listen to the word, then spell it with the letter tiles.", skill: "spelling words by sound"),
        QuizGameInfo(id: "missing", title: "Missing Letter", symbol: "questionmark.square.fill", intro: "One letter is missing. Which one fits?", skill: "hearing the middle sounds in words"),
        QuizGameInfo(id: "spot", title: "Spot the Spelling", symbol: "checkmark.seal.fill", intro: "Which one is spelled the right way?", skill: "spelling tricky words"),
        QuizGameInfo(id: "magicE", title: "Magic E", symbol: "wand.and.stars", intro: "Add a magic e and the vowel says its name! Pick the new word.", skill: "silent e (long vowels)"),
    ]

    static let cheers = ["Super speller!", "Buzz-tastic!", "You spelled it!", "That's right!", "Bee-autiful!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "hearSpell":
            return Array(words.shuffled(using: &rng).prefix(count)).enumerated().map { i, w in
                // the word's letters plus two extra, shuffled
                let extras = "aeioustrnl".map(String.init).filter { !w.word.contains($0) }.shuffled(using: &rng).prefix(2)
                return QuizRound(kind: .spell, visual: .picture(w.picture), say: "Spell \(w.word).",
                                 choices: (w.word.map(String.init) + extras).shuffled(using: &rng), answer: w.word,
                                 cheer: "\(w.word.uppercased().map(String.init).joined(separator: ", ")). \(cheer(i))")
            }
        case "missing":
            return Array(words.shuffled(using: &rng).prefix(count)).enumerated().map { i, w in
                let letters = Array(w.word)
                // hide a letter in the middle (never the first)
                let at = max(1, letters.count / 2)
                let hidden = String(letters[at])
                var shown = letters.map(String.init); shown[at] = "_"
                let pool = "aeiou".contains(hidden) ? ["a", "e", "i", "o", "u"] : ["b", "d", "l", "m", "n", "r", "s", "t", "c", "k", "p"]
                return QuizRound(visual: .text(shown.joined(separator: " ")), say: "Which letter is missing in \(w.word)?",
                                 choices: QuizShuffle.choices(hidden, pool, using: &rng), answer: hidden, cheer: "\(w.word)! \(cheer(i))")
            }
        case "spot":
            return Array(tricky.shuffled(using: &rng).prefix(count)).enumerated().map { i, t in
                QuizRound(visual: .none, say: "Which one spells \(t.word)?", choices: QuizShuffle.choices(t.word, t.wrong, using: &rng),
                          answer: t.word, cheer: "\(t.word.uppercased().map(String.init).joined(separator: ", ")). \(cheer(i))")
            }
        default: // magicE
            return Array(magicE.shuffled(using: &rng).prefix(count)).enumerated().map { i, m in
                let others = magicE.filter { $0.long != m.long }.map(\.long)
                return QuizRound(visual: .text("\(m.short) + e"), say: "\(m.short), plus a magic e, makes which word?",
                                 choices: QuizShuffle.choices(m.long, [m.short + "ee"] + others, using: &rng), answer: m.long,
                                 cheer: "\(m.short) becomes \(m.long)! \(m.picture) \(cheer(i))")
            }
        }
    }
}

// MARK: - Fraction Bakery

enum FractionBank {
    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "name", title: "Name the Slice", symbol: "chart.pie.fill", intro: "How much of the pie is colored? Pick the fraction.", skill: "naming fractions"),
        QuizGameInfo(id: "findHalf", title: "Find the Fraction", symbol: "magnifyingglass", intro: "Find the picture that shows the fraction.", skill: "matching fractions to pictures"),
        QuizGameInfo(id: "share", title: "Share the Treats", symbol: "person.2.fill", intro: "Share the treats fairly. How many does each friend get?", skill: "sharing equally (division)"),
        QuizGameInfo(id: "bigger", title: "Bigger Slice", symbol: "arrow.up.right.circle.fill", intro: "Which slice is bigger? Fewer pieces means bigger pieces!", skill: "comparing unit fractions"),
    ]

    /// Kid-friendly fraction names.
    static func words(_ shaded: Int, _ parts: Int) -> String {
        let names = [2: "half", 3: "third", 4: "quarter", 5: "fifth", 6: "sixth", 8: "eighth"]
        let n = names[parts] ?? "part"
        if shaded == 1 { return "one \(n)" }
        let counts = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight"]
        let plural = n == "half" ? "halves" : n + "s"
        return "\(counts[min(shaded, 8)]) \(plural)"
    }

    static let cheers = ["Delicious!", "Yum, that's right!", "Fresh from the oven!", "Sweet!", "Perfect slice!"]
    static let treats = ["🍪", "🧁", "🍩", "🍓", "🥨"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        let pool: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (1, 4), (3, 4), (1, 6), (5, 6), (1, 8), (3, 8)]
        switch id {
        case "name":
            return Array(pool.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                let answer = "\(f.0)/\(f.1)"
                let wrong = ["\(f.1 - f.0)/\(f.1)", "\(f.0)/\(f.1 + 1)", "\(min(f.0 + 1, f.1))/\(f.1)", "1/\(f.1 == 2 ? 3 : 2)"].filter { $0 != answer }
                return QuizRound(visual: .fraction(parts: f.1, shaded: f.0, round: Bool.random(using: &rng)),
                                 say: "How much is colored?", choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "\(words(f.0, f.1).prefix(1).uppercased() + words(f.0, f.1).dropFirst())! \(cheer(i))")
            }
        case "findHalf":
            return Array(pool.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                // three drawings: the right one, the "other part", and one cut a different way
                var options: [(String, QuizVisual)] = [("A", .fraction(parts: f.1, shaded: f.0, round: true))]
                let other = f.1 - f.0 != f.0 ? f.1 - f.0 : (f.0 + 1 <= f.1 ? f.0 + 1 : f.0 - 1)
                options.append(("B", .fraction(parts: f.1, shaded: other, round: true)))
                let cParts = f.1 == 4 ? 3 : 4
                options.append(("C", .fraction(parts: cParts, shaded: min(f.0, cParts - 1), round: true)))
                options.shuffle(using: &rng)
                let labels = ["1", "2", "3"]
                let answer = labels[options.firstIndex { $0.0 == "A" }!]
                return QuizRound(visual: .text("\(f.0)/\(f.1)"), say: "Find \(words(f.0, f.1)).", choices: labels,
                                 choiceVisuals: options.map(\.1), answer: answer, cheer: "That's \(words(f.0, f.1))! \(cheer(i))")
            }
        case "share":
            let sets = [(4, 2), (6, 2), (6, 3), (8, 2), (8, 4), (9, 3), (10, 2), (12, 3), (12, 4)]
            return Array(sets.shuffled(using: &rng).prefix(count)).enumerated().map { i, s in
                let each = s.0 / s.1
                let treat = treats[i % treats.count]
                return QuizRound(visual: .picture(String(repeating: treat, count: s.0)),
                                 say: "\(s.0) treats, shared fairly by \(s.1) friends. How many does each friend get?",
                                 choices: QuizShuffle.choices("\(each)", ["\(each + 1)", "\(max(1, each - 1))", "\(s.0)", "\(s.1)"], using: &rng),
                                 answer: "\(each)", cheer: "\(s.0) shared by \(s.1) is \(each) each. \(cheer(i))")
            }
        default: // bigger
            let parts = [2, 3, 4, 6, 8]
            return (0..<count).map { i in
                var a = parts.randomElement(using: &rng)!, b = parts.randomElement(using: &rng)!
                while a == b { b = parts.randomElement(using: &rng)! }
                if Bool.random(using: &rng) { swap(&a, &b) }
                let big = min(a, b)
                return QuizRound(visual: .none, say: "Which slice is bigger: one \(words(1, a).dropFirst(4)) or one \(words(1, b).dropFirst(4))?",
                                 choices: ["1/\(a)", "1/\(b)"], choiceVisuals: [.fraction(parts: a, shaded: 1, round: true), .fraction(parts: b, shaded: 1, round: true)],
                                 answer: "1/\(big)", cheer: "1/\(big) is bigger: cutting into fewer pieces makes bigger slices! \(cheer(i))")
            }
        }
    }
}

// MARK: - Shape Studio

enum ShapeBank {
    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "name", title: "Name That Shape", symbol: "square.on.circle", intro: "What is this shape called?", skill: "naming flat shapes"),
        QuizGameInfo(id: "sides", title: "Count the Sides", symbol: "triangle", intro: "Count the straight sides. Corners help!", skill: "counting sides and corners"),
        QuizGameInfo(id: "solids", title: "3D Shapes", symbol: "cube.fill", intro: "Some shapes are solid, like a ball or a box. Which shape is it?", skill: "naming 3D shapes"),
        QuizGameInfo(id: "pattern", title: "What Comes Next?", symbol: "circle.grid.3x3.fill", intro: "Look at the pattern. What shape comes next?", skill: "shape patterns"),
    ]

    /// Real things and the solid shape they are.
    static let objects: [(String, ShapeKind, String)] = [
        ("🎲", .cube, "a dice"), ("🧊", .cube, "an ice cube"), ("⚽", .sphere, "a ball"), ("🌍", .sphere, "the Earth"),
        ("🥫", .cylinder, "a can"), ("🕯️", .cylinder, "a candle"), ("🍦", .cone, "an ice cream cone"), ("🎉", .cone, "a party popper"),
        ("🔺", .pyramid, "a pyramid shape"),
    ]

    static let cheers = ["Shape star!", "You got it!", "Super spotting!", "That's right!", "Nice!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "name":
            return Array(ShapeKind.flat.shuffled(using: &rng).prefix(count)).enumerated().map { i, s in
                QuizRound(visual: .shapes([s]), say: "What shape is this?",
                          choices: QuizShuffle.choices(s.name, ShapeKind.flat.map(\.name), using: &rng), answer: s.name,
                          cheer: "A \(s.name)! \(cheer(i))")
            }
        case "sides":
            let withSides = ShapeKind.flat.filter { $0.sides > 0 }
            return (0..<count).map { i in
                let s = withSides[(i + Int.random(in: 0..<withSides.count, using: &rng)) % withSides.count]
                return QuizRound(visual: .shapes([s]), say: "How many sides does this \(s.name) have?",
                                 choices: QuizShuffle.choices("\(s.sides)", ["3", "4", "5", "6", "8"], using: &rng), answer: "\(s.sides)",
                                 cheer: "A \(s.name) has \(s.sides) sides and \(s.sides) corners. \(cheer(i))")
            }
        case "solids":
            return Array(objects.shuffled(using: &rng).prefix(count)).enumerated().map { i, o in
                QuizRound(visual: .picture(o.0), say: "What shape is \(o.2)?",
                          choices: QuizShuffle.choices(o.1.name, ShapeKind.solids.map(\.name), using: &rng), answer: o.1.name,
                          cheer: "\(o.2.prefix(1).uppercased() + o.2.dropFirst()) is a \(o.1.name)! \(cheer(i))")
            }
        default: // pattern
            return (0..<count).map { i in
                var picks = Array(ShapeKind.flat.shuffled(using: &rng).prefix(3))
                // AB, ABC or AAB patterns
                let unit: [ShapeKind]
                switch i % 3 {
                case 0: unit = [picks[0], picks[1]]
                case 1: unit = [picks[0], picks[1], picks[2]]
                default: unit = [picks[0], picks[0], picks[1]]
                }
                let shown = (0..<(unit.count * 2)).map { unit[$0 % unit.count] }
                let next = unit[shown.count % unit.count]
                picks = picks.filter { $0 != next } + ShapeKind.flat.filter { !picks.contains($0) }
                return QuizRound(visual: .pattern(shown), say: "What comes next in the pattern?",
                                 choices: QuizShuffle.choices(next.name, picks.map(\.name), using: &rng), answer: next.name,
                                 cheer: "\(next.name.prefix(1).uppercased() + next.name.dropFirst()) comes next! \(cheer(i))")
            }
        }
    }
}
