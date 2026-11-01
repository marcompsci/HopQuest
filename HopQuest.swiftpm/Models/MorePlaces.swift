import Foundation

// Five more learning places on the shared quiz engine (v6.8–v7.2): Rhyme Pond, Number Builder, Times Treehouse,
// Measure Meadow and Feelings Corner. Plain Swift, tested in Tests/Learn (every game, many seeds, answers checked).

// MARK: - Rhyme Pond (v6.8)

enum RhymeBank {
    /// Rhyming families. Every word in a family rhymes with the others and with no word in another family.
    static let families: [[(word: String, picture: String)]] = [
        [("cat", "🐱"), ("hat", "🎩"), ("bat", "🦇")],
        [("dog", "🐶"), ("frog", "🐸"), ("log", "🪵")],
        [("sun", "☀️"), ("bun", "🍞"), ("run", "🏃")],
        [("bee", "🐝"), ("tree", "🌳"), ("key", "🔑")],
        [("cake", "🎂"), ("snake", "🐍"), ("rake", "🧹")],
        [("ring", "💍"), ("king", "🤴"), ("swing", "🛝")],
        [("clock", "🕰️"), ("sock", "🧦"), ("rock", "🪨")],
        [("car", "🚗"), ("star", "⭐"), ("jar", "🫙")],
        [("fish", "🐟"), ("dish", "🍽️"), ("wish", "🌠")],
        [("goat", "🐐"), ("boat", "⛵"), ("coat", "🧥")],
        [("bear", "🐻"), ("chair", "🪑"), ("pear", "🍐")],
        [("mouse", "🐭"), ("house", "🏠"), ("blouse", "👚")],
        [("bug", "🐛"), ("rug", "🧶"), ("mug", "☕")],
        [("fox", "🦊"), ("box", "📦"), ("ox", "🐂")],
    ]

    /// How many beats (syllables) a word has, to clap along.
    static let beats: [(word: String, picture: String, beats: Int)] = [
        ("cat", "🐱", 1), ("sun", "☀️", 1), ("dog", "🐶", 1), ("fish", "🐟", 1), ("tree", "🌳", 1),
        ("apple", "🍎", 2), ("pizza", "🍕", 2), ("rabbit", "🐰", 2), ("tiger", "🐯", 2), ("monkey", "🐵", 2), ("rocket", "🚀", 2), ("pencil", "✏️", 2),
        ("banana", "🍌", 3), ("butterfly", "🦋", 3), ("elephant", "🐘", 3), ("dinosaur", "🦕", 3), ("kangaroo", "🦘", 3), ("strawberry", "🍓", 3),
        ("caterpillar", "🐛", 4), ("watermelon", "🍉", 4), ("alligator", "🐊", 4), ("helicopter", "🚁", 4),
    ]

    /// Silly rhyming sentences to finish. The last word rhymes with a word in the sentence.
    static let finish: [(start: String, end: String, picture: String)] = [
        ("The cat has a funny", "hat", "🐱"), ("A bug sat on a", "rug", "🐞"), ("The frog jumped on a", "log", "🐸"),
        ("A bee lives in a", "tree", "🐝"), ("The fox hid in a", "box", "🦊"), ("A goat sailed a", "boat", "🐐"),
        ("A mouse built a", "house", "🐭"), ("The snake baked a", "cake", "🐍"), ("A bear sat on a", "chair", "🐻"),
        ("The king found a", "ring", "🤴"),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "rhyme", title: "Find the Rhyme", symbol: "music.note", intro: "Words that rhyme sound the same at the end. Which word rhymes?", skill: "hearing rhymes"),
        QuizGameInfo(id: "oddOne", title: "Odd One Out", symbol: "xmark.circle.fill", intro: "Two words rhyme. Which word does not rhyme?", skill: "telling rhymes apart"),
        QuizGameInfo(id: "beats", title: "Clap the Beats", symbol: "hands.clap.fill", intro: "Say the word and clap each beat. How many claps?", skill: "counting syllables"),
        QuizGameInfo(id: "finish", title: "Finish the Rhyme", symbol: "text.quote", intro: "Finish the silly sentence with a word that rhymes!", skill: "finishing a rhyme"),
    ]

    static let cheers = ["Rhyme time!", "Ribbit, right!", "That sounds right!", "You've got an ear for it!", "Super!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "rhyme":
            return Array(families.indices.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                let pair = families[f].shuffled(using: &rng)
                let target = pair[0], answer = pair[1]
                let wrong = families.indices.filter { $0 != f }.shuffled(using: &rng).prefix(2).map { families[$0].randomElement(using: &rng)!.word }
                return QuizRound(visual: .picture(target.picture), say: "Which word rhymes with \(target.word)?",
                                 choices: QuizShuffle.choices(answer.word, wrong, using: &rng), answer: answer.word,
                                 cheer: "\(target.word.capitalized) and \(answer.word) rhyme! \(cheer(i))")
            }
        case "oddOne":
            return Array(families.indices.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                let two = families[f].shuffled(using: &rng).prefix(2).map(\.word)
                let other = families.indices.filter { $0 != f }.randomElement(using: &rng)!
                let odd = families[other].randomElement(using: &rng)!.word
                return QuizRound(visual: .none, say: "Which word does not rhyme?", choices: ([odd] + two).shuffled(using: &rng), answer: odd,
                                 cheer: "\(two[0].capitalized) and \(two[1]) rhyme, but \(odd) doesn't. \(cheer(i))")
            }
        case "beats":
            // a mix of short and long words, never two the same
            return Array(beats.shuffled(using: &rng).prefix(count)).enumerated().map { i, w in
                QuizRound(visual: .picture(w.picture), say: "\(w.word.capitalized). Clap the beats. How many?",
                          choices: ["1", "2", "3", "4"], answer: "\(w.beats)",
                          cheer: "\(w.word.capitalized) has \(w.beats) \(w.beats == 1 ? "beat" : "beats"). \(cheer(i))")
            }
        default: // finish
            return Array(finish.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                let wrong = finish.filter { $0.end != f.end }.shuffled(using: &rng).prefix(2).map(\.end)
                return QuizRound(visual: .picture(f.picture), say: "\(f.start)…", choices: QuizShuffle.choices(f.end, wrong, using: &rng),
                                 answer: f.end, cheer: "\(f.start) \(f.end)! \(cheer(i))")
            }
        }
    }
}

// MARK: - Number Builder (v6.9)

enum NumberBank {
    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "count", title: "Count the Blocks", symbol: "square.stack.3d.up.fill", intro: "Each tall rod is 10. Each little cube is 1. How many in all?", skill: "counting tens and ones"),
        QuizGameInfo(id: "tens", title: "Tens and Ones", symbol: "number", intro: "The first digit tells the tens. The last digit tells the ones.", skill: "place value (tens and ones)"),
        QuizGameInfo(id: "build", title: "Build the Number", symbol: "hammer.fill", intro: "Which blocks make the number?", skill: "matching numbers to blocks"),
        QuizGameInfo(id: "bigger", title: "Bigger Number", symbol: "arrow.up.circle.fill", intro: "Which number is bigger? Look at the tens first!", skill: "comparing two-digit numbers"),
    ]

    static let cheers = ["Ocho-mazing!", "You built it!", "That's right!", "Number whiz!", "Great counting!"]

    /// A two-digit number with ones that aren't 0, so tens and ones can't be mixed up.
    static func twoDigit<G: RandomNumberGenerator>(_ rng: inout G) -> (tens: Int, ones: Int) {
        (Int.random(in: 1...9, using: &rng), Int.random(in: 1...9, using: &rng))
    }

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        var used: Set<Int> = []
        func fresh() -> (tens: Int, ones: Int) {
            var n = twoDigit(&rng)
            while used.contains(n.tens * 10 + n.ones) { n = twoDigit(&rng) }
            used.insert(n.tens * 10 + n.ones)
            return n
        }
        switch id {
        case "count":
            return (0..<count).map { i in
                let n = fresh(), v = n.tens * 10 + n.ones
                let wrong = [n.ones * 10 + n.tens, v + 10, v - 1, v + 1, n.tens + n.ones].filter { $0 != v && $0 > 0 && $0 < 100 }.map(String.init)
                return QuizRound(visual: .blocks(tens: n.tens, ones: n.ones), say: "How many blocks?",
                                 choices: QuizShuffle.choices("\(v)", wrong, using: &rng), answer: "\(v)",
                                 cheer: "\(n.tens) tens and \(n.ones) ones make \(v). \(cheer(i))")
            }
        case "tens":
            return (0..<count).map { i in
                let n = fresh(), v = n.tens * 10 + n.ones
                let askTens = i % 2 == 0
                let answer = askTens ? n.tens : n.ones
                let wrong = [askTens ? n.ones : n.tens, answer * 10, answer + 1, max(0, answer - 1)].filter { $0 != answer }.map(String.init)
                return QuizRound(visual: .text("\(v)"), say: "How many \(askTens ? "tens" : "ones") are in \(v)?",
                                 choices: QuizShuffle.choices("\(answer)", wrong, using: &rng), answer: "\(answer)",
                                 cheer: "\(v) has \(n.tens) tens and \(n.ones) ones. \(cheer(i))")
            }
        case "build":
            return (0..<count).map { i in
                var n = fresh()
                while n.tens == n.ones { n = fresh() }
                let v = n.tens * 10 + n.ones
                // the right blocks, the digits swapped, and one ten off
                var options: [(Bool, QuizVisual)] = [(true, .blocks(tens: n.tens, ones: n.ones)), (false, .blocks(tens: n.ones, ones: n.tens))]
                let off = n.tens < 9 ? n.tens + 1 : n.tens - 1
                options.append((false, .blocks(tens: off, ones: n.ones)))
                options.shuffle(using: &rng)
                let labels = ["1", "2", "3"]
                return QuizRound(visual: .text("\(v)"), say: "Which blocks make \(v)?", choices: labels, choiceVisuals: options.map(\.1),
                                 answer: labels[options.firstIndex { $0.0 }!], cheer: "\(n.tens) tens and \(n.ones) ones. \(cheer(i))")
            }
        default: // bigger
            return (0..<count).map { i in
                let a = fresh()
                var b = fresh()
                // half the time the tens match, so the ones decide
                if i % 2 == 1 && a.ones != b.ones { b = (a.tens, b.ones) }
                let va = a.tens * 10 + a.ones, vb = b.tens * 10 + b.ones
                let big = max(va, vb)
                return QuizRound(visual: .none, say: "Which number is bigger?", choices: ["\(va)", "\(vb)"],
                                 choiceVisuals: [.blocks(tens: a.tens, ones: a.ones), .blocks(tens: b.tens, ones: b.ones)],
                                 answer: "\(big)", cheer: "\(big) is bigger than \(min(va, vb)). \(cheer(i))")
            }
        }
    }
}

// MARK: - Times Treehouse (v7.0)

enum TimesBank {
    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "groups", title: "Equal Groups", symbol: "circle.grid.2x2.fill", intro: "Count the groups, then how many in each. How many in all?", skill: "adding equal groups"),
        QuizGameInfo(id: "skip", title: "Skip Counting", symbol: "forward.fill", intro: "Count by 2s, 5s and 10s. What comes next?", skill: "skip counting by 2s, 5s and 10s"),
        QuizGameInfo(id: "arrays", title: "Rows and Rows", symbol: "square.grid.3x3.fill", intro: "Things in neat rows! How many rows? How many in each row? How many in all?", skill: "arrays (rows and columns)"),
        QuizGameInfo(id: "match", title: "Groups Of", symbol: "rectangle.3.group.fill", intro: "Find the picture that matches the words.", skill: "reading \"groups of\""),
    ]

    static let items = ["🌰", "🍎", "⭐", "🐞", "🍪", "🌸"]
    static let cheers = ["Acorn-tastic!", "That's right!", "Times-terrific!", "Nutty good!", "You counted it!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        func wrongFor(_ g: Int, _ e: Int) -> [String] {
            [g + e, g * e + 1, g * e - 1, g * e + e, g * e - e].filter { $0 > 0 && $0 != g * e }.map(String.init)
        }
        switch id {
        case "groups", "arrays":
            let rows = id == "arrays"
            return (0..<count).map { i in
                let g = Int.random(in: 2...5, using: &rng), e = Int.random(in: 2...5, using: &rng)
                let item = items[(i + (rows ? 3 : 0)) % items.count]
                let say = rows ? "\(g) rows, \(e) in each row. How many in all?" : "\(g) groups of \(e). How many in all?"
                return QuizRound(visual: .groups(count: g, each: e, item: item, rows: rows), say: say,
                                 choices: QuizShuffle.choices("\(g * e)", wrongFor(g, e), using: &rng), answer: "\(g * e)",
                                 cheer: "\(g) \(rows ? "rows" : "groups") of \(e) is \(g * e). \(cheer(i))")
            }
        case "skip":
            let steps = [2, 5, 10, 2, 5, 10, 3]
            return (0..<count).map { i in
                let step = steps[(i + Int.random(in: 0..<3, using: &rng)) % steps.count]
                let start = step * Int.random(in: 1...4, using: &rng)
                let shown = (0..<3).map { start + $0 * step }
                let next = start + 3 * step
                let wrong = [next + 1, next - 1, next + step, shown[2] + 1].filter { $0 != next }.map(String.init)
                return QuizRound(visual: .text(shown.map(String.init).joined(separator: ", ") + ", ?"),
                                 say: "Count by \(step)s: \(shown.map(String.init).joined(separator: ", ")). What comes next?",
                                 choices: QuizShuffle.choices("\(next)", wrong, using: &rng), answer: "\(next)",
                                 cheer: "\(shown[2]) and \(step) more is \(next). \(cheer(i))")
            }
        default: // match
            return (0..<count).map { i in
                let g = Int.random(in: 2...4, using: &rng)
                var e = Int.random(in: 2...5, using: &rng)
                if e == g { e += 1 }
                let item = items[i % items.count]
                var options: [(Bool, QuizVisual)] = [
                    (true, .groups(count: g, each: e, item: item, rows: false)),
                    (false, .groups(count: e, each: g, item: item, rows: false)),
                    (false, .groups(count: g, each: e + 1, item: item, rows: false)),
                ]
                options.shuffle(using: &rng)
                let labels = ["1", "2", "3"]
                return QuizRound(visual: .text("\(g) groups of \(e)"), say: "Which picture shows \(g) groups of \(e)?",
                                 choices: labels, choiceVisuals: options.map(\.1), answer: labels[options.firstIndex { $0.0 }!],
                                 cheer: "\(g) groups, with \(e) in each group. \(cheer(i))")
            }
        }
    }
}

// MARK: - Measure Meadow (v7.1)

enum MeasureBank {
    static let colors = ["red", "blue", "green", "yellow", "purple"]

    /// Pairs where the first is clearly heavier.
    static let heavy: [(big: String, bigName: String, small: String, smallName: String)] = [
        ("🐘", "elephant", "🐭", "mouse"), ("🚗", "car", "🚲", "bike"), ("🍉", "watermelon", "🍇", "grape"),
        ("🪨", "rock", "🍃", "leaf"), ("📚", "stack of books", "✏️", "pencil"), ("🎃", "pumpkin", "🍓", "strawberry"),
        ("🐋", "whale", "🐟", "fish"), ("🚚", "truck", "🛹", "skateboard"), ("🛋️", "sofa", "🪶", "feather"),
    ]

    /// What we measure, and the tool for it.
    static let tools: [(picture: String, ask: String, tool: String)] = [
        ("🐍", "how long the snake is", "ruler"), ("🍉", "how heavy the melon is", "scale"), ("☕", "how hot the cocoa is", "thermometer"),
        ("🏃", "how long the race takes", "clock"), ("💧", "how much water is in the jug", "measuring cup"), ("🗼", "how tall the tower is", "ruler"),
        ("🍎", "how heavy the apples are", "scale"), ("🛁", "how warm the bath is", "thermometer"), ("🍪", "how much milk goes in the cookies", "measuring cup"),
    ]
    static let toolNames = ["ruler", "scale", "thermometer", "clock", "measuring cup"]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "longer", title: "Longest Ribbon", symbol: "ruler.fill", intro: "Line them up! Which ribbon is the longest? Which is the shortest?", skill: "comparing lengths"),
        QuizGameInfo(id: "units", title: "Measure with Blocks", symbol: "square.split.1x2.fill", intro: "Count the blocks under the ribbon. How many blocks long is it?", skill: "measuring with units"),
        QuizGameInfo(id: "heavy", title: "Heavy or Light", symbol: "scalemass.fill", intro: "Which one is heavier? Which one is lighter?", skill: "comparing weight"),
        QuizGameInfo(id: "tools", title: "Measuring Tools", symbol: "thermometer.medium", intro: "Which tool measures it?", skill: "picking measuring tools"),
    ]

    static let cheers = ["Ellie-gant!", "Measured right!", "That's right!", "Great looking!", "Trunk-tastic!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "longer":
            return (0..<count).map { i in
                let picks = Array(colors.shuffled(using: &rng).prefix(3))
                let lengths = Array((2...9).shuffled(using: &rng).prefix(3))
                let longest = i % 2 == 0
                let target = longest ? lengths.max()! : lengths.min()!
                let answer = picks[lengths.firstIndex(of: target)!]
                return QuizRound(visual: .none, say: "Which ribbon is the \(longest ? "longest" : "shortest")?", choices: picks,
                                 choiceVisuals: zip(lengths, picks).map { .bar(length: $0, color: $1, units: false) },
                                 answer: answer, cheer: "The \(answer) ribbon is the \(longest ? "longest" : "shortest"). \(cheer(i))")
            }
        case "units":
            return Array((2...9).shuffled(using: &rng).prefix(count)).enumerated().map { i, n in
                let color = colors[i % colors.count]
                let wrong = [n + 1, n - 1, n + 2].filter { $0 > 0 }.map(String.init)
                return QuizRound(visual: .bar(length: n, color: color, units: true), say: "How many blocks long is the \(color) ribbon?",
                                 choices: QuizShuffle.choices("\(n)", wrong, using: &rng), answer: "\(n)",
                                 cheer: "It's \(n) blocks long. \(cheer(i))")
            }
        case "heavy":
            return Array(heavy.shuffled(using: &rng).prefix(count)).enumerated().map { i, p in
                let askHeavy = i % 2 == 0
                let pair = [(p.big, p.bigName), (p.small, p.smallName)].shuffled(using: &rng)
                let answer = askHeavy ? p.bigName : p.smallName
                return QuizRound(visual: .picture(pair.map(\.0).joined(separator: "   ")),
                                 say: "Which is \(askHeavy ? "heavier" : "lighter"): the \(pair[0].1) or the \(pair[1].1)?",
                                 choices: pair.map(\.1), answer: answer,
                                 cheer: "The \(answer) is \(askHeavy ? "heavier" : "lighter"). \(cheer(i))")
            }
        default: // tools
            return Array(tools.shuffled(using: &rng).prefix(count)).enumerated().map { i, t in
                QuizRound(visual: .picture(t.picture), say: "What do we use to measure \(t.ask)?",
                          choices: QuizShuffle.choices(t.tool, toolNames, using: &rng), answer: t.tool,
                          cheer: "A \(t.tool) measures \(t.ask). \(cheer(i))")
            }
        }
    }
}

// MARK: - Feelings Corner (v7.2)

enum FeelingsBank {
    static let faces: [(face: String, feeling: String)] = [
        ("😄", "happy"), ("😢", "sad"), ("😠", "angry"), ("😨", "scared"), ("😲", "surprised"), ("😴", "sleepy"), ("😟", "worried"), ("🤩", "excited"),
    ]
    static var feelings: [String] { faces.map(\.feeling) }

    /// Little stories. `fits` is every feeling that makes sense, so a fair-but-different answer is never marked wrong.
    static let stories: [(text: String, picture: String, answer: String, fits: Set<String>)] = [
        ("Mia's ice cream fell on the ground.", "🍦", "sad", ["sad", "angry", "surprised"]),
        ("Leo is getting a puppy today!", "🐶", "excited", ["excited", "happy", "surprised"]),
        ("A loud thunderstorm wakes Sam up at night.", "⛈️", "scared", ["scared", "surprised", "worried", "sleepy"]),
        ("Ava stayed up very late and it's morning now.", "🌅", "sleepy", ["sleepy"]),
        ("Someone knocked down Kai's block tower on purpose.", "🧱", "angry", ["angry", "sad", "surprised"]),
        ("Zoe's friends jump out and shout \"Happy birthday!\"", "🎉", "surprised", ["surprised", "happy", "excited"]),
        ("It's Noah's first day at a new school.", "🏫", "worried", ["worried", "scared", "excited"]),
        ("Lily finished her puzzle all by herself.", "🧩", "happy", ["happy", "excited"]),
    ]

    /// What could help with a big feeling, and choices that wouldn't help.
    static let helps: [(feeling: String, good: String, notGood: [String])] = [
        ("angry", "Take three slow, deep breaths", ["Throw your toys", "Yell at a friend"]),
        ("sad", "Talk to a grown-up you trust", ["Keep it all inside", "Kick the wall"]),
        ("scared", "Hold a grown-up's hand", ["Run away and hide alone", "Pretend nothing is wrong"]),
        ("worried", "Say what's worrying you", ["Keep it a secret", "Stop eating your lunch"]),
        ("excited", "Take a breath, then share the news", ["Shout in the library", "Push to the front"]),
        ("frustrated", "Take a break, then try again", ["Rip up your work", "Give up forever"]),
    ]

    /// Kind things to say, and things that aren't kind.
    static let kind: [(story: String, kind: String, notKind: [String])] = [
        ("Your friend is sad because their kite broke.", "\"Do you want to play with me?\"", ["\"That's silly.\"", "\"Go away.\""]),
        ("A new kid is sitting alone at lunch.", "\"Do you want to sit with us?\"", ["\"That seat is taken.\"", "\"You can't play.\""]),
        ("Your brother fell off his bike.", "\"Are you okay? I'll help.\"", ["\"Ha ha!\"", "\"That's your fault.\""]),
        ("Your friend made a mistake in the game.", "\"That's okay! Try again.\"", ["\"You're bad at this.\"", "\"I'm not playing anymore.\""]),
        ("Your classmate drew a picture.", "\"I like the colors you used!\"", ["\"Mine is better.\"", "\"That's ugly.\""]),
        ("Your friend is scared of the dark.", "\"I can stay with you.\"", ["\"Scaredy-cat!\"", "\"That's babyish.\""]),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "faces", title: "Name the Feeling", symbol: "face.smiling.inverse", intro: "Look at the face. What feeling is it?", skill: "naming feelings"),
        QuizGameInfo(id: "stories", title: "How Would You Feel?", symbol: "book.closed.fill", intro: "Listen to the little story. How might they feel?", skill: "understanding how others feel"),
        QuizGameInfo(id: "helps", title: "What Could Help?", symbol: "heart.circle.fill", intro: "Big feelings are okay! What could help?", skill: "calming big feelings"),
        QuizGameInfo(id: "kind", title: "Kind Words", symbol: "bubble.left.and.bubble.right.fill", intro: "What is a kind thing to say?", skill: "being a kind friend"),
    ]

    static let cheers = ["That's kind and wise!", "You understand feelings!", "That's right!", "Big heart!", "Koala-ty answer!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "faces":
            return Array(faces.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                QuizRound(visual: .picture(f.face), say: "How does this face feel?",
                          choices: QuizShuffle.choices(f.feeling, feelings, using: &rng), answer: f.feeling,
                          cheer: "That face looks \(f.feeling). \(cheer(i))")
            }
        case "stories":
            return Array(stories.shuffled(using: &rng).prefix(count)).enumerated().map { i, s in
                QuizRound(visual: .picture(s.picture), say: "\(s.text) How might they feel?",
                          choices: QuizShuffle.choices(s.answer, feelings.filter { !s.fits.contains($0) }, using: &rng), answer: s.answer,
                          cheer: "They might feel \(s.answer). It's okay to feel that way. \(cheer(i))")
            }
        case "helps":
            return Array(helps.shuffled(using: &rng).prefix(count)).enumerated().map { i, h in
                QuizRound(visual: .text("Feeling \(h.feeling)"), say: "You feel \(h.feeling). What could help?",
                          choices: QuizShuffle.choices(h.good, h.notGood, using: &rng), answer: h.good,
                          cheer: "\(h.good). That helps! \(cheer(i))")
            }
        default: // kind
            return Array(kind.shuffled(using: &rng).prefix(count)).enumerated().map { i, k in
                QuizRound(visual: .none, say: "\(k.story) What is a kind thing to say?",
                          choices: QuizShuffle.choices(k.kind, k.notKind, using: &rng), answer: k.kind,
                          cheer: "That's a kind thing to say. \(cheer(i))")
            }
        }
    }
}
