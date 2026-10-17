import Foundation

// The Reading Nook (v3.3): five short reading games for early readers, hosted in a little library in Hop Village.
// Everything here is plain Swift so the word lists and round builders are tested (Tests/Reading).

/// A short word kids can sound out, with a picture.
struct PictureWord: Equatable {
    let word: String
    let emoji: String
    /// The rhyming family ("at" for cat, hat, bat).
    var family: String { String(word.dropFirst()) }
    var firstLetter: String { String(word.prefix(1)) }
}

enum ReadingGame: String, CaseIterable, Codable, Identifiable {
    case firstSound, buildWord, sightWords, rhymes, sentences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSound: return "First Sounds"
        case .buildWord: return "Build a Word"
        case .sightWords: return "Word Pop"
        case .rhymes: return "Rhyme Time"
        case .sentences: return "Read & Match"
        }
    }

    var icon: String {
        switch self {
        case .firstSound: return "🔤"
        case .buildWord: return "🧩"
        case .sightWords: return "🫧"
        case .rhymes: return "🎵"
        case .sentences: return "📖"
        }
    }

    /// What kids practice, in grown-up words (Learning Report).
    var skill: String {
        switch self {
        case .firstSound: return "beginning letter sounds"
        case .buildWord: return "spelling short words"
        case .sightWords: return "sight words"
        case .rhymes: return "rhyming word families"
        case .sentences: return "reading a sentence"
        }
    }

    /// What to do, read aloud at the start.
    var intro: String {
        switch self {
        case .firstSound: return "Look at the picture and say the word. Which letter does it start with?"
        case .buildWord: return "Spell the word! Tap the letters in order."
        case .sightWords: return "Listen to the word, then pop the bubble that says it."
        case .rhymes: return "Which word rhymes? Rhyming words sound the same at the end, like cat and hat."
        case .sentences: return "Read the sentence, then pick the picture that matches it."
        }
    }
}

/// One question in a reading game.
struct ReadingRound: Equatable {
    enum Kind: Equatable {
        /// Tap the right choice.
        case choose
        /// Tap letters in order to spell `answer`.
        case spell
    }
    let kind: Kind
    /// Big text or picture shown at the top.
    let show: String
    /// What the narrator says (and the speaker button repeats).
    let say: String
    /// Choices (or letter tiles for `.spell`), already shuffled.
    let choices: [String]
    let answer: String
    /// Said after a right answer.
    let cheer: String
}

enum ReadingBank {
    /// Short words with pictures (consonant-vowel-consonant, so they can be sounded out).
    static let words: [PictureWord] = [
        PictureWord(word: "cat", emoji: "🐱"), PictureWord(word: "hat", emoji: "🎩"), PictureWord(word: "bat", emoji: "🦇"),
        PictureWord(word: "rat", emoji: "🐀"), PictureWord(word: "fan", emoji: "🪭"), PictureWord(word: "pan", emoji: "🍳"),
        PictureWord(word: "van", emoji: "🚐"), PictureWord(word: "can", emoji: "🥫"), PictureWord(word: "map", emoji: "🗺️"),
        PictureWord(word: "dog", emoji: "🐶"), PictureWord(word: "log", emoji: "🪵"), PictureWord(word: "fox", emoji: "🦊"),
        PictureWord(word: "box", emoji: "📦"), PictureWord(word: "pig", emoji: "🐷"), PictureWord(word: "bed", emoji: "🛏️"),
        PictureWord(word: "hen", emoji: "🐔"), PictureWord(word: "ten", emoji: "🔟"), PictureWord(word: "pen", emoji: "🖊️"),
        PictureWord(word: "net", emoji: "🥅"), PictureWord(word: "web", emoji: "🕸️"), PictureWord(word: "sun", emoji: "☀️"),
        PictureWord(word: "bus", emoji: "🚌"), PictureWord(word: "bug", emoji: "🐛"), PictureWord(word: "mug", emoji: "☕"),
        PictureWord(word: "nut", emoji: "🥜"), PictureWord(word: "cup", emoji: "🍵"),
    ]

    /// Common sight words (from the early Dolch lists).
    static let sightWords: [String] = [
        "the", "and", "a", "to", "is", "you", "it", "in", "said", "for", "up", "look", "we", "can", "see",
        "my", "me", "go", "here", "play", "like", "are", "he", "she", "was", "they", "have", "come", "what", "this",
    ]

    /// Word families with at least two picture words.
    static var rhymeFamilies: [String: [PictureWord]] {
        Dictionary(grouping: words, by: \.family).filter { $0.value.count >= 2 }
    }

    /// Animals and places for "Read & Match" sentences.
    static let sentenceAnimals: [PictureWord] = words.filter { ["cat", "dog", "pig", "hen", "fox", "bug", "bat"].contains($0.word) }
    static let sentencePlaces: [PictureWord] = words.filter { ["bed", "box", "log", "bus", "van"].contains($0.word) }

    static let alphabet = Array("abcdefghijklmnopqrstuvwxyz").map(String.init)

    static let cheers = ["Great reading!", "You got it!", "Super!", "Yes, that's right!", "Wonderful!"]

    /// A fresh set of rounds for one play.
    static func rounds<G: RandomNumberGenerator>(for game: ReadingGame, count: Int = 5, using rng: inout G) -> [ReadingRound] {
        switch game {
        case .firstSound:
            return Array(words.shuffled(using: &rng).prefix(count)).map { w in
                let others = alphabet.filter { $0 != w.firstLetter && !"aeiou".contains($0) }.shuffled(using: &rng).prefix(2)
                return ReadingRound(kind: .choose, show: w.emoji,
                                    say: "\(w.word). Which letter does \(w.word) start with?",
                                    choices: ([w.firstLetter] + others).shuffled(using: &rng), answer: w.firstLetter,
                                    cheer: "\(w.word) starts with \(w.firstLetter.uppercased())! \(cheers.randomElement(using: &rng)!)")
            }
        case .buildWord:
            return Array(words.shuffled(using: &rng).prefix(count)).map { w in
                let extra = alphabet.filter { !w.word.contains($0) }.randomElement(using: &rng)!
                let tiles = (w.word.map(String.init) + [extra]).shuffled(using: &rng)
                return ReadingRound(kind: .spell, show: w.emoji, say: "Spell \(w.word).", choices: tiles, answer: w.word,
                                    cheer: "\(w.word.map(String.init).joined(separator: ", ")). \(w.word)! \(cheers.randomElement(using: &rng)!)")
            }
        case .sightWords:
            return Array(sightWords.shuffled(using: &rng).prefix(count)).map { word in
                let others = sightWords.filter { $0 != word }.shuffled(using: &rng).prefix(3)
                return ReadingRound(kind: .choose, show: "🫧", say: "Find the word: \(word).",
                                    choices: ([word] + others).shuffled(using: &rng), answer: word,
                                    cheer: "That says \(word)! \(cheers.randomElement(using: &rng)!)")
            }
        case .rhymes:
            let families = rhymeFamilies
            let keys = families.keys.sorted()
            return (0..<count).map { _ in
                let key = keys.randomElement(using: &rng)!
                let pair = families[key]!.shuffled(using: &rng)
                let target = pair[0], rhyme = pair[1]
                let wrong = words.filter { $0.family != key }.shuffled(using: &rng).prefix(2)
                return ReadingRound(kind: .choose, show: "\(target.emoji) \(target.word)",
                                    say: "Which word rhymes with \(target.word)?",
                                    choices: ([rhyme.word] + wrong.map(\.word)).shuffled(using: &rng), answer: rhyme.word,
                                    cheer: "\(target.word) and \(rhyme.word) both end in \(key)! \(cheers.randomElement(using: &rng)!)")
            }
        case .sentences:
            return (0..<count).map { _ in
                let animal = sentenceAnimals.randomElement(using: &rng)!
                let place = sentencePlaces.randomElement(using: &rng)!
                let otherAnimal = sentenceAnimals.filter { $0 != animal }.randomElement(using: &rng)!
                let otherPlace = sentencePlaces.filter { $0 != place }.randomElement(using: &rng)!
                let right = picture(animal, place)
                let choices = [right, picture(otherAnimal, place), picture(animal, otherPlace)].shuffled(using: &rng)
                let text = "The \(animal.word) is on the \(place.word)."
                return ReadingRound(kind: .choose, show: text, say: "Read it: \(text) Which picture matches?",
                                    choices: choices, answer: right,
                                    cheer: "Yes! \(text) \(cheers.randomElement(using: &rng)!)")
            }
        }
    }

    static func rounds(for game: ReadingGame, count: Int = 5) -> [ReadingRound] {
        var g = SystemRandomNumberGenerator()
        return rounds(for: game, count: count, using: &g)
    }

    /// "🐱 on 🛏️" as one picture choice.
    static func picture(_ animal: PictureWord, _ place: PictureWord) -> String { "\(animal.emoji) on \(place.emoji)" }

    /// The next letter a speller needs, or nil when the word is done.
    static func nextLetter(of word: String, typed: String) -> String? {
        guard typed.count < word.count, word.hasPrefix(typed) else { return nil }
        return String(word[word.index(word.startIndex, offsetBy: typed.count)])
    }
}

/// Stars for one play: by how many rounds were right on the first try.
enum LearnScore {
    static func stars(firstTry: Int, of total: Int) -> Int {
        guard total > 0 else { return 0 }
        if firstTry == total { return 3 }
        if firstTry * 2 >= total { return 2 }
        return 1
    }
}

/// Reading Nook progress. Stars only come from beating your best, so each game gives at most 3 stars ever.
struct ReadingSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
    }

    func best(_ g: ReadingGame) -> Int { best[g.rawValue] ?? 0 }

    /// Records a finished play and returns the new stars to give (0 unless it beats the best).
    mutating func record(_ g: ReadingGame, stars: Int) -> Int {
        plays += 1
        let old = best(g)
        guard stars > old else { return 0 }
        best[g.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = ReadingGame.allCases.count * 3
}
