import Foundation

// Four more learning places on the shared quiz engine (v9.12–v9.15):
// Word Workshop (grammar and word building), Ten Frame Farm (ten frames, make ten, doubles),
// Sky Watch (moon, shadows, weather, sky facts) and Helper Town (community helpers and staying safe).
// Plain Swift, tested in Tests/Learn.

// MARK: - Word Workshop (v9.12)

enum WordBank {
    /// Compound words: two small words that make a new word, with a picture of the new word.
    static let compounds: [(a: String, b: String, picture: String)] = [
        ("sun", "flower", "🌻"), ("rain", "bow", "🌈"), ("star", "fish", "⭐"), ("snow", "man", "⛄"), ("cup", "cake", "🧁"),
        ("foot", "ball", "🏈"), ("pop", "corn", "🍿"), ("butter", "fly", "🦋"), ("tooth", "brush", "🪥"), ("back", "pack", "🎒"),
        ("gold", "fish", "🐠"), ("lady", "bug", "🐞"), ("pan", "cake", "🥞"), ("sea", "shell", "🐚"), ("rain", "coat", "🧥"),
        ("snow", "flake", "❄️"), ("bed", "room", "🛏️"), ("sun", "glasses", "🕶️"),
    ]
    static func word(_ c: (a: String, b: String, picture: String)) -> String { c.a + c.b }

    /// Everyday words that are not made of two smaller words.
    static let plainWords = ["apple", "tiger", "pencil", "yellow", "garden", "rabbit", "monkey", "pizza", "table", "river", "kitten", "carrot"]

    /// Words for ABC order: every one starts with a different letter.
    static let abcWords = ["apple", "bear", "cat", "duck", "egg", "fish", "goat", "hat", "igloo", "jam", "kite", "lion", "moon",
                           "nest", "owl", "pig", "queen", "rain", "sun", "tree", "umbrella", "van", "web", "yak", "zebra"]

    /// Doing words (verbs) and naming words (nouns), chosen so none of them is often the other kind.
    static let doing: [(word: String, picture: String)] = [
        ("jump", "🦘"), ("sing", "🎤"), ("swim", "🏊"), ("clap", "👏"), ("eat", "😋"), ("hop", "🐰"),
        ("read", "📖"), ("write", "✍️"), ("climb", "🧗"), ("dance", "💃"), ("throw", "🤾"), ("bake", "🧑‍🍳"),
    ]
    static let naming: [(word: String, picture: String)] = [
        ("apple", "🍎"), ("chair", "🪑"), ("tiger", "🐯"), ("pencil", "✏️"), ("sock", "🧦"), ("tree", "🌳"),
        ("kitten", "🐱"), ("table", "🍽️"), ("carrot", "🥕"), ("rocket", "🚀"), ("turtle", "🐢"), ("crayon", "🖍️"),
    ]

    /// Two words and their short word (contraction).
    static let contractions: [(long: String, short: String)] = [
        ("do not", "don't"), ("can not", "can't"), ("is not", "isn't"), ("I am", "I'm"), ("it is", "it's"), ("we are", "we're"),
        ("they are", "they're"), ("you are", "you're"), ("did not", "didn't"), ("let us", "let's"), ("I will", "I'll"), ("she is", "she's"),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "compound", title: "Word Glue", symbol: "link", intro: "Two little words can stick together and make a new word!", skill: "compound words"),
        QuizGameInfo(id: "abc", title: "ABC Order", symbol: "textformat.abc", intro: "Look at the first letter. Which word comes first in the alphabet?", skill: "putting words in ABC order"),
        QuizGameInfo(id: "kinds", title: "Naming or Doing?", symbol: "figure.run", intro: "Naming words name a thing. Doing words are things you can do!", skill: "naming words and doing words"),
        QuizGameInfo(id: "short", title: "Squish Words", symbol: "arrow.right.and.line.vertical.and.arrow.left", intro: "Squish two words together and add a little mark. Which short word is it?", skill: "contractions"),
    ]

    static let cheers = ["Word wizard!", "Hoo-ray!", "That's right!", "Wise choice!", "Wonderful words!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "compound":
            let picks = Array(compounds.shuffled(using: &rng).prefix(count))
            return picks.enumerated().map { i, c in
                let answer = word(c)
                if i % 3 == 2 {
                    // which word is made of two words?
                    let wrong = Array(plainWords.shuffled(using: &rng).prefix(2))
                    return QuizRound(visual: .picture(c.picture), say: "Which word is made of two little words?",
                                     choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                     cheer: "\(c.a.capitalized) and \(c.b) make \(answer)! \(cheer(i))")
                }
                let wrong = compounds.map(word).filter { $0 != answer }
                return QuizRound(visual: .text("\(c.a) + \(c.b)"), say: "\(c.a.capitalized) plus \(c.b). What new word do they make?",
                                 choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "\(c.a.capitalized) and \(c.b) make \(answer)! \(c.picture) \(cheer(i))")
            }
        case "abc":
            return (0..<count).map { i -> QuizRound in
                let three = Array(abcWords.shuffled(using: &rng).prefix(3))
                let sorted = three.sorted()
                let last = i % 3 == 2
                let answer = last ? sorted[2] : sorted[0]
                let letter = answer.prefix(1)
                return QuizRound(visual: .text(three.joined(separator: "  ")),
                                 say: last ? "Which word comes last in ABC order?" : "Which word comes first in ABC order?",
                                 choices: three, answer: answer,
                                 cheer: "\(answer.capitalized) starts with \(letter), which comes \(last ? "after" : "before") the others. \(cheer(i))")
            }
        case "kinds":
            return (0..<count).map { i -> QuizRound in
                let wantDoing = i % 2 == 0
                let right = wantDoing ? doing.randomElement(using: &rng)! : naming.randomElement(using: &rng)!
                let others = Array((wantDoing ? naming : doing).shuffled(using: &rng).prefix(2)).map(\.word)
                return QuizRound(visual: .none,
                                 say: wantDoing ? "Which one is a doing word?" : "Which one is a naming word?",
                                 choices: QuizShuffle.choices(right.word, others, using: &rng), answer: right.word,
                                 cheer: wantDoing ? "You can \(right.word)! It's a doing word. \(right.picture)" : "\(right.word.capitalized) names a thing. It's a naming word. \(right.picture)")
            }
        default: // short
            let picks = Array(contractions.shuffled(using: &rng).prefix(count))
            return picks.enumerated().map { i, c in
                let wrong = contractions.map(\.short).filter { $0 != c.short }
                return QuizRound(visual: .text(c.long), say: "Squish \(c.long) together. Which short word is it?",
                                 choices: QuizShuffle.choices(c.short, wrong, using: &rng), answer: c.short,
                                 cheer: "\(c.long.prefix(1).uppercased() + c.long.dropFirst()) is \(c.short). \(cheer(i))")
            }
        }
    }
}

// MARK: - Ten Frame Farm (v9.13)

enum FrameBank {
    /// Farm pictures that fill the frames.
    static let items: [String: (one: String, many: String)] = [
        "🐣": ("chick", "chicks"), "🥚": ("egg", "eggs"), "🍎": ("apple", "apples"), "🐞": ("ladybug", "ladybugs"),
    ]
    static let pictures = ["🐣", "🥚", "🍎", "🐞"]
    static func one(_ e: String) -> String { items[e]?.one ?? e }
    static func many(_ e: String) -> String { items[e]?.many ?? e }

    /// Frames for a number: full frames of ten, then the rest (0 to 20).
    static func frames(_ n: Int) -> [Int] {
        n <= 10 ? [n] : [10, n - 10]
    }

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "count", title: "Fill the Frame", symbol: "square.grid.4x3.fill", intro: "A ten frame has ten boxes. Count what's inside!", skill: "counting with ten frames"),
        QuizGameInfo(id: "make10", title: "Make Ten", symbol: "10.circle.fill", intro: "How many empty boxes? That's how many more make ten!", skill: "making ten"),
        QuizGameInfo(id: "doubles", title: "Doubles", symbol: "plus.square.on.square", intro: "Doubles are two of the same number. Add them up!", skill: "adding doubles"),
        QuizGameInfo(id: "moreless", title: "One More, One Less", symbol: "plusminus.circle.fill", intro: "One more is the next number. One less is the number before.", skill: "one more and one less"),
    ]

    static let cheers = ["Farm-tastic!", "Egg-cellent!", "That's right!", "You counted it!", "Cluck-cluck, hooray!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        let item = pictures.randomElement(using: &rng)!
        switch id {
        case "count":
            let ns = Array(Array(3...20).shuffled(using: &rng).prefix(count))
            return ns.enumerated().map { i, n in
                QuizRound(visual: .tenFrames(frames(n), item: item), say: "How many \(many(item)) are in the \(n > 10 ? "frames" : "frame")?",
                          choices: GraphBank.numberChoices(n, others: [n + 1, n - 1, n + 10], using: &rng), answer: "\(n)",
                          cheer: n > 10 ? "Ten and \(n - 10) more make \(n). \(cheer(i))" : "\(n) \(n == 1 ? one(item) : many(item)). \(cheer(i))")
            }
        case "make10":
            let ns = Array(Array(1...9).shuffled(using: &rng).prefix(count))
            return ns.enumerated().map { i, n in
                QuizRound(visual: .tenFrames([n], item: item), say: "How many more \(many(item)) to make 10?",
                          choices: GraphBank.numberChoices(10 - n, others: [n, 11 - n], using: &rng), answer: "\(10 - n)",
                          cheer: "\(n) and \(10 - n) make 10. \(cheer(i))")
            }
        case "doubles":
            let ns = Array(Array(1...9).shuffled(using: &rng).prefix(count))
            return ns.enumerated().map { i, n in
                QuizRound(visual: .tenFrames([n, n], item: item), say: "Double \(n)! What is \(n) plus \(n)?",
                          choices: GraphBank.numberChoices(n + n, others: [n + n + 2, n + n - 2], using: &rng), answer: "\(n + n)",
                          cheer: "\(n) plus \(n) is \(n + n). \(cheer(i))")
            }
        default: // moreless
            let ns = Array(Array(2...19).shuffled(using: &rng).prefix(count))
            return ns.enumerated().map { i, n in
                let more = i % 2 == 0
                let answer = more ? n + 1 : n - 1
                return QuizRound(visual: .tenFrames(frames(n), item: item),
                                 say: "There are \(n) \(many(item)). What is one \(more ? "more" : "less") than \(n)?",
                                 choices: GraphBank.numberChoices(answer, others: [n, more ? n + 2 : n - 2], using: &rng), answer: "\(answer)",
                                 cheer: "One \(more ? "more" : "less") than \(n) is \(answer). \(cheer(i))")
            }
        }
    }
}

// MARK: - Sky Watch (v9.14)

enum SkyBank {
    /// Moon pictures and what kids call them.
    static let moons: [(picture: String, name: String)] = [
        ("🌕", "full moon"), ("🌑", "new moon"), ("🌓", "half moon"), ("🌗", "half moon"), ("🌒", "crescent moon"), ("🌘", "crescent moon"),
    ]
    static let moonNames = ["full moon", "new moon", "half moon", "crescent moon"]

    /// Questions with one right answer and two wrong ones that are plainly wrong.
    static let shadows: [(say: String, answer: String, wrong: [String])] = [
        ("What makes a shadow?", "something blocking the light", ["the wind blowing", "rain falling"]),
        ("At noon the sun is high in the sky. Is your shadow long or short?", "short", ["long", "it's purple"]),
        ("Early in the morning the sun is low. Is your shadow long or short?", "long", ["short", "it's purple"]),
        ("The sun is in front of you. Where is your shadow?", "behind you", ["in front of you", "on your head"]),
        ("You walk under a big tree on a sunny day. What do you stand in?", "the tree's shadow", ["a puddle", "a rainbow"]),
        ("Which one can make a shadow puppet on the wall?", "your hands and a flashlight", ["a whisper", "a smell"]),
    ]

    /// Things to wear or bring. For each weather: what fits, and things that plainly don't (no "sunglasses in the snow" arguments).
    static let gear: [String: String] = [
        "umbrella": "☂️", "rain boots": "🥾", "mittens": "🧤", "scarf": "🧣", "sun hat": "👒", "sunglasses": "🕶️", "swimsuit": "🩱", "sandals": "🩴",
    ]
    static let weathers: [(id: String, picture: String, say: String, fits: [String], never: [String])] = [
        ("rainy", "🌧️", "It's raining! What should you bring?", ["umbrella", "rain boots"], ["sunglasses", "sun hat", "sandals"]),
        ("snowy", "🌨️", "It's snowing and cold! What should you wear?", ["mittens", "scarf"], ["swimsuit", "sandals", "sun hat"]),
        ("sunny", "☀️", "It's hot and sunny! What should you wear?", ["sun hat", "sunglasses"], ["mittens", "scarf", "rain boots"]),
    ]
    static func label(_ name: String) -> String { "\(gear[name] ?? "") \(name)" }

    static let facts: [(say: String, answer: String, wrong: [String])] = [
        ("What is the sun?", "a star", ["a planet", "a cloud"]),
        ("What does the moon go around?", "the Earth", ["a cloud", "a rainbow"]),
        ("Where does rain come from?", "clouds", ["the moon", "the stars"]),
        ("What planet do we live on?", "Earth", ["the moon", "the sun"]),
        ("When can we see the stars best?", "at night", ["at lunchtime", "on a sunny afternoon"]),
        ("Where does the sun come up in the morning?", "in the east", ["in the west", "under the sea"]),
        ("What do plants get from the sun?", "light", ["snow", "socks"]),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "moon", title: "Moon Shapes", symbol: "moon.stars.fill", intro: "The moon looks different on different nights. Which moon is it?", skill: "shapes of the moon"),
        QuizGameInfo(id: "shadow", title: "Shadow Play", symbol: "sun.max.fill", intro: "When something blocks the light, it makes a shadow!", skill: "light and shadows"),
        QuizGameInfo(id: "weather", title: "Dress for the Weather", symbol: "cloud.sun.rain.fill", intro: "Look at the weather. What should you wear or bring?", skill: "dressing for the weather"),
        QuizGameInfo(id: "facts", title: "Sky Facts", symbol: "sparkles", intro: "The sun, the moon, the stars and the clouds. What do you know?", skill: "the sun, moon and sky"),
    ]

    static let cheers = ["Sky-high!", "Out of this world!", "That's right!", "Star-tastic!", "Shining bright!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "moon":
            return (0..<count).map { i -> QuizRound in
                let m = moons[(i + Int.random(in: 0..<moons.count, using: &rng)) % moons.count]
                let wrong = moonNames.filter { $0 != m.name }
                return QuizRound(visual: .picture(m.picture), say: "What do we call this moon?",
                                 choices: QuizShuffle.choices(m.name, wrong, using: &rng), answer: m.name,
                                 cheer: "It's a \(m.name)! \(cheer(i))")
            }
        case "shadow":
            return pick(shadows, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["🌳", "🔦", "☀️", "🧍"][i % 4]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "Yes: \(q.answer)! \(cheer(i))")
            }
        case "weather":
            return (0..<count).map { i -> QuizRound in
                let w = weathers[(i + Int.random(in: 0..<weathers.count, using: &rng)) % weathers.count]
                let right = w.fits.randomElement(using: &rng)!
                let answer = label(right)
                return QuizRound(visual: .picture(w.picture), say: w.say,
                                 choices: QuizShuffle.choices(answer, w.never.map(label), using: &rng), answer: answer,
                                 cheer: "\(right.prefix(1).uppercased() + right.dropFirst()) for \(w.id) days! \(cheer(i))")
            }
        default: // facts
            return pick(facts, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["☀️", "🌙", "⭐", "🌍", "☁️"][i % 5]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "\(q.answer.prefix(1).uppercased() + q.answer.dropFirst())! \(cheer(i))")
            }
        }
    }

    static func pick<T, G: RandomNumberGenerator>(_ bank: [T], _ count: Int, using rng: inout G) -> [T] {
        Array(bank.shuffled(using: &rng).prefix(count))
    }
}

// MARK: - Helper Town (v9.15)

enum HelperBank {
    /// Helpers, by name, with a picture.
    static let helpers: [String: String] = [
        "doctor": "🧑‍⚕️", "dentist": "🦷", "vet": "🐶", "firefighter": "🧑‍🚒", "mail carrier": "📬", "librarian": "📚",
        "farmer": "🧑‍🌾", "baker": "🧑‍🍳", "teacher": "🧑‍🏫", "bus driver": "🚌", "police officer": "👮",
    ]
    /// Helpers who do nearly the same job are never wrong answers for each other.
    static let alike: [Set<String>] = [["doctor", "dentist", "vet"], ["librarian", "teacher"], ["baker", "farmer"], ["police officer", "teacher", "librarian"]]
    static func wrongHelpers(for answer: String) -> [String] {
        let close = alike.filter { $0.contains(answer) }.reduce(Set([answer])) { $0.union($1) }
        return helpers.keys.filter { !close.contains($0) }.sorted()
    }

    /// A question, the picture shown with it (never the helper themselves), and the helper.
    static let jobs: [(say: String, picture: String, answer: String)] = [
        ("Who helps you feel better when you're sick?", "🤒", "doctor"), ("Who checks your teeth?", "😁", "dentist"),
        ("Who takes care of sick pets?", "🐕", "vet"), ("Who puts out fires?", "🔥", "firefighter"),
        ("Who brings letters to your home?", "✉️", "mail carrier"), ("Who helps you find a book at the library?", "🏛️", "librarian"),
        ("Who grows food on a farm?", "🌽", "farmer"), ("Who bakes bread and muffins?", "🍞", "baker"),
        ("Who drives the big yellow school bus?", "🏫", "bus driver"), ("Who helps keep people safe on the street?", "🏙️", "police officer"),
    ]

    static let tools: [(picture: String, thing: String, answer: String)] = [
        ("🚒", "a fire truck", "firefighter"), ("🩺", "a stethoscope", "doctor"), ("🪥", "a tooth mirror and brush", "dentist"),
        ("✉️", "a bag of letters", "mail carrier"), ("🚜", "a tractor", "farmer"), ("🥖", "an oven and dough", "baker"),
        ("📚", "a cart of library books", "librarian"), ("🚌", "a big steering wheel and bus stops", "bus driver"),
    ]

    static let safety: [(say: String, answer: String, wrong: [String])] = [
        ("You're riding your bike. What keeps you safe?", "wear a helmet", ["ride with no hands", "close your eyes"]),
        ("You want to cross the street. What do you do?", "stop, look both ways, and hold a grown-up's hand", ["run across fast", "cross without looking"]),
        ("You get in the car. What do you do first?", "buckle your seat belt", ["stand on the seat", "open the window wide"]),
        ("You want to go swimming. Who should be there?", "a grown-up watching", ["nobody", "just your teddy bear"]),
        ("The stove is hot. What should you do?", "stay back and let a grown-up cook", ["touch it to check", "put your toy on it"]),
        ("You can't find your grown-up in a store. What do you do?", "stay put and ask a store worker for help", ["leave the store", "hide under a shelf"]),
        ("It's a hot, sunny day at the park. What helps?", "sunscreen and water", ["a winter coat", "no water all day"]),
    ]

    static let signs: [(picture: String, say: String, answer: String, wrong: [String])] = [
        ("🛑", "What does this sign tell drivers and walkers?", "stop", ["go fast", "turn around"]),
        ("🚸", "What does this sign mean?", "children cross here", ["no children", "a playground slide"]),
        ("🔴", "The traffic light is red. What do you do?", "stop and wait", ["go", "dance"]),
        ("🚶", "The walk light turned on. What do you do?", "look both ways, then walk", ["run without looking", "sit down"]),
        ("⚠️", "What does this sign mean?", "be careful", ["free ice cream", "go to sleep"]),
        ("🚻", "What does this sign show?", "restrooms", ["a parking lot", "a fire"]),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "jobs", title: "Who Helps?", symbol: "person.2.fill", intro: "Lots of people help our town. Who does this job?", skill: "community helpers"),
        QuizGameInfo(id: "tools", title: "Helper Tools", symbol: "wrench.and.screwdriver.fill", intro: "Every helper has special tools. Who uses this one?", skill: "helpers and their tools"),
        QuizGameInfo(id: "safe", title: "Stay Safe", symbol: "shield.fill", intro: "Smart choices keep you safe. What's the safe thing to do?", skill: "safety choices"),
        QuizGameInfo(id: "signs", title: "Read the Signs", symbol: "signpost.right.fill", intro: "Signs and lights tell us what to do. What does this one mean?", skill: "safety signs and lights"),
    ]

    static let cheers = ["Super helper!", "Roar-some!", "That's right!", "Safe and smart!", "Town hero!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "jobs":
            return SkyBank.pick(jobs, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(q.picture), say: q.say,
                          choices: QuizShuffle.choices(q.answer, wrongHelpers(for: q.answer), using: &rng), answer: q.answer,
                          cheer: "The \(q.answer)! \(cheer(i))")
            }
        case "tools":
            return SkyBank.pick(tools, count, using: &rng).enumerated().map { i, t in
                QuizRound(visual: .picture(t.picture), say: "Who uses \(t.thing)?",
                          choices: QuizShuffle.choices(t.answer, wrongHelpers(for: t.answer), using: &rng), answer: t.answer,
                          cheer: "A \(t.answer) uses \(t.thing). \(cheer(i))")
            }
        case "safe":
            return SkyBank.pick(safety, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["🚲", "🚦", "🚗", "🏊", "🍳", "🛒", "🧴"][i % 7]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "Yes: \(q.answer). \(cheer(i))")
            }
        default: // signs
            return SkyBank.pick(signs, count, using: &rng).enumerated().map { i, s in
                QuizRound(visual: .picture(s.picture), say: s.say,
                          choices: QuizShuffle.choices(s.answer, s.wrong, using: &rng), answer: s.answer,
                          cheer: "It means \(s.answer). \(cheer(i))")
            }
        }
    }
}

// MARK: - Learn page helpers (v9.16–v9.17)

/// "Keep going": the one place to suggest at the top of the Learn page — a game still at 1 star first,
/// then a place that's started but not finished. Nothing before the first game, nothing once all are done.
enum KeepGoing {
    static func pick(_ areas: [LearningArea]) -> LearningArea? {
        AtHome.suggested(areas.filter { $0.id != "code" }, limit: 1).first
    }

    /// "2 of 4 games done" (done = 2 stars or more, the same as the grown-ups' progress page).
    static func detail(_ area: LearningArea) -> String {
        "\(area.learned.count) of \(area.skills.count) games done"
    }
}

/// Places that are new in this update get a "New!" ribbon on the menu until they're played once.
enum NewPlaces {
    static let ids: Set<String> = ["words", "tenframe", "sky", "helpers", "sounds", "numberline", "colors", "evenodd", "animals", "opposites", "sentences",
                                   "ocean", "dinos", "kindness", "vehicles"]

    static func showRibbon(_ id: String, plays: Int) -> Bool { ids.contains(id) && plays == 0 }
}

// MARK: - Sound Shop (v9.23)

enum SoundBank {
    static let digraphWords: [(word: String, picture: String, sound: String)] = [
        ("ship", "🚢", "sh"), ("shoe", "👟", "sh"), ("shell", "🐚", "sh"), ("sheep", "🐑", "sh"),
        ("chick", "🐥", "ch"), ("cheese", "🧀", "ch"), ("chair", "🪑", "ch"), ("cherry", "🍒", "ch"),
        ("thumb", "👍", "th"), ("three", "3️⃣", "th"), ("thread", "🧵", "th"),
    ]
    static let endWords: [(word: String, picture: String)] = [
        ("cat", "🐱"), ("dog", "🐶"), ("bus", "🚌"), ("sun", "☀️"), ("bed", "🛏️"), ("cup", "☕"),
        ("map", "🗺️"), ("web", "🕸️"), ("fox", "🦊"), ("bat", "🦇"), ("van", "🚐"), ("leaf", "🍃"),
    ]
    /// Three-letter words with a short vowel in the middle.
    static let cvcWords: [(word: String, picture: String)] = [
        ("cat", "🐱"), ("hat", "🎩"), ("map", "🗺️"), ("bed", "🛏️"), ("web", "🕸️"), ("hen", "🐔"),
        ("pig", "🐷"), ("six", "6️⃣"), ("dog", "🐶"), ("fox", "🦊"), ("pot", "🍲"), ("bus", "🚌"), ("sun", "☀️"), ("cup", "☕"),
    ]
    static let vowels = ["a", "e", "i", "o", "u"]
    static let blendWords: [(word: String, picture: String, blend: String)] = [
        ("frog", "🐸", "fr"), ("flag", "🚩", "fl"), ("star", "⭐", "st"), ("sled", "🛷", "sl"), ("crab", "🦀", "cr"),
        ("drum", "🥁", "dr"), ("tree", "🌳", "tr"), ("snail", "🐌", "sn"), ("plane", "✈️", "pl"), ("broom", "🧹", "br"),
        ("grapes", "🍇", "gr"), ("clock", "🕐", "cl"),
    ]
    static var blends: [String] { Array(Set(blendWords.map(\.blend))).sorted() }

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "digraph", title: "Sh, Ch or Th?", symbol: "speaker.wave.2.fill", intro: "Two letters can make one sound! Listen to the start of the word.", skill: "sh, ch and th sounds"),
        QuizGameInfo(id: "end", title: "Last Sound", symbol: "arrow.right.to.line", intro: "Say the word slowly. What sound do you hear at the very end?", skill: "ending sounds"),
        QuizGameInfo(id: "middle", title: "Middle Vowel", symbol: "a.circle.fill", intro: "A, e, i, o, u! Which vowel is hiding in the middle?", skill: "short vowel sounds"),
        QuizGameInfo(id: "blend", title: "Blend It", symbol: "wind", intro: "Some words start with two sounds blended together, like fr in frog.", skill: "consonant blends"),
    ]

    static let cheers = ["Sound-tastic!", "You heard it!", "That's right!", "Great listening!", "Super sounding!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "digraph":
            return SkyBank.pick(digraphWords, count, using: &rng).enumerated().map { i, w in
                QuizRound(visual: .picture(w.picture), say: "\(w.word.capitalized). Which sound does it start with?",
                          choices: QuizShuffle.choices(w.sound, ["sh", "ch", "th"].filter { $0 != w.sound }, using: &rng), answer: w.sound,
                          cheer: "\(w.word.capitalized) starts with \(w.sound)! \(cheer(i))")
            }
        case "end":
            return SkyBank.pick(endWords, count, using: &rng).enumerated().map { i, w in
                let last = String(w.word.last!)
                let wrong = ["t", "g", "s", "n", "d", "p", "b", "x", "m", "f"].filter { $0 != last }
                return QuizRound(visual: .picture(w.picture), say: "\(w.word.capitalized). Which letter does it end with?",
                                 choices: QuizShuffle.choices(last, wrong, using: &rng), answer: last,
                                 cheer: "\(w.word.capitalized) ends with \(last)! \(cheer(i))")
            }
        case "middle":
            return SkyBank.pick(cvcWords, count, using: &rng).enumerated().map { i, w in
                let letters = Array(w.word).map(String.init)
                let v = letters[1]
                return QuizRound(visual: .text("\(letters[0]) _ \(letters[2])  \(w.picture)"), say: "\(w.word.capitalized). Which vowel is in the middle?",
                                 choices: QuizShuffle.choices(v, vowels.filter { $0 != v }, using: &rng), answer: v,
                                 cheer: "\(letters[0]), \(v), \(letters[2]): \(w.word)! \(cheer(i))")
            }
        default: // blend
            return SkyBank.pick(blendWords, count, using: &rng).enumerated().map { i, w in
                QuizRound(visual: .picture(w.picture), say: "\(w.word.capitalized). Which two letters does it start with?",
                          choices: QuizShuffle.choices(w.blend, blends.filter { $0 != w.blend }, using: &rng), answer: w.blend,
                          cheer: "\(w.blend.uppercased()), \(w.word)! \(cheer(i))")
            }
        }
    }
}

// MARK: - Number Line Lane (v9.24)

enum LineBank {
    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "where", title: "Find the Dot", symbol: "smallcircle.filled.circle", intro: "Count along the number line. What number is the dot on?", skill: "reading a number line"),
        QuizGameInfo(id: "forward", title: "Hop Forward", symbol: "arrow.right.circle.fill", intro: "Hopping forward on a number line is adding!", skill: "adding on a number line"),
        QuizGameInfo(id: "back", title: "Hop Back", symbol: "arrow.left.circle.fill", intro: "Hopping back on a number line is taking away!", skill: "taking away on a number line"),
        QuizGameInfo(id: "compare", title: "Bigger or Smaller?", symbol: "lessthan.circle.fill", intro: "The open mouth of > and < always faces the bigger number!", skill: "comparing with >, < and ="),
    ]

    static let cheers = ["Hop-tastic!", "Right on the line!", "That's right!", "Number ninja!", "Great hopping!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "where":
            return (0..<count).map { i -> QuizRound in
                let top = i < 2 ? 10 : 20
                let n = Int.random(in: 1..<top, using: &rng)
                return QuizRound(visual: .numberLine(to: top, dot: n, hopFrom: nil), say: "What number is the dot on?",
                                 choices: GraphBank.numberChoices(n, others: [n + 1, n - 1], using: &rng), answer: "\(n)",
                                 cheer: "The dot is on \(n). \(cheer(i))")
            }
        case "forward":
            return (0..<count).map { i -> QuizRound in
                let h = Int.random(in: 2...6, using: &rng)
                let s = Int.random(in: 0...(20 - h), using: &rng)
                return QuizRound(visual: .numberLine(to: 20, dot: s + h, hopFrom: s), say: "Start at \(s) and hop \(h) forward. Where do you land?",
                                 choices: GraphBank.numberChoices(s + h, others: [s + h + 1, s + h - 1, s - h], using: &rng), answer: "\(s + h)",
                                 cheer: "\(s) plus \(h) is \(s + h). \(cheer(i))")
            }
        case "back":
            return (0..<count).map { i -> QuizRound in
                let h = Int.random(in: 2...6, using: &rng)
                let s = Int.random(in: (h + 1)...20, using: &rng)
                return QuizRound(visual: .numberLine(to: 20, dot: s - h, hopFrom: s), say: "Start at \(s) and hop \(h) back. Where do you land?",
                                 choices: GraphBank.numberChoices(s - h, others: [s - h + 1, s - h - 1, s + h], using: &rng), answer: "\(s - h)",
                                 cheer: "\(s) take away \(h) is \(s - h). \(cheer(i))")
            }
        default: // compare
            return (0..<count).map { i -> QuizRound in
                let a = Int.random(in: 0...50, using: &rng)
                let b = i == 3 ? a : Int.random(in: 0...50, using: &rng)
                let answer = a > b ? ">" : a < b ? "<" : "="
                let words = a > b ? "is greater than" : a < b ? "is less than" : "is equal to"
                return QuizRound(visual: .text("\(a)  ◻  \(b)"), say: "Which sign goes in the box?",
                                 choices: QuizShuffle.choices(answer, [">", "<", "="].filter { $0 != answer }, using: &rng), answer: answer,
                                 cheer: "\(a) \(words) \(b). \(cheer(i))")
            }
        }
    }
}

// MARK: - Color Lab (v9.31)

enum ColorBank {
    static let swatch: [String: String] = [
        "red": "🔴", "orange": "🟠", "yellow": "🟡", "green": "🟢", "blue": "🔵", "purple": "🟣",
        "brown": "🟤", "black": "⚫", "white": "⚪", "pink": "🩷", "gray": "🩶",
    ]
    static func label(_ c: String) -> String { "\(swatch[c] ?? "") \(c)" }

    /// Paint mixing, kid style.
    static let mixes: [(a: String, b: String, makes: String)] = [
        ("red", "yellow", "orange"), ("blue", "yellow", "green"), ("red", "blue", "purple"),
        ("red", "white", "pink"), ("black", "white", "gray"), ("red", "green", "brown"),
    ]
    static let warm = ["red", "orange", "yellow"]
    static let cool = ["blue", "green", "purple"]
    static let rainbow = ["red", "orange", "yellow", "green", "blue", "purple"]

    static let lightDark: [(say: String, answer: String, wrong: [String])] = [
        ("You add white paint to blue. What happens?", "it gets lighter", ["it gets darker", "it turns orange"]),
        ("You add black paint to green. What happens?", "it gets darker", ["it gets lighter", "it turns pink"]),
        ("Which paint makes red into pink?", "white", ["black", "blue"]),
        ("Which paint makes a color darker?", "black", ["white", "yellow"]),
        ("Is the night sky light or dark?", "dark", ["light", "rainbow"]),
        ("Is a sunny yellow lemon light or dark?", "light", ["dark", "see-through"]),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "mix", title: "Mix It!", symbol: "paintpalette.fill", intro: "Mix two paints and you get a brand new color!", skill: "mixing colors"),
        QuizGameInfo(id: "warmcool", title: "Warm or Cool", symbol: "thermometer.sun.fill", intro: "Warm colors feel like fire and sun. Cool colors feel like water and grass.", skill: "warm and cool colors"),
        QuizGameInfo(id: "light", title: "Light and Dark", symbol: "circle.lefthalf.filled", intro: "White makes colors lighter. Black makes them darker!", skill: "lighter and darker colors"),
        QuizGameInfo(id: "rainbow", title: "Rainbow Order", symbol: "rainbow", intro: "Red, orange, yellow, green, blue, purple. What comes next?", skill: "the order of the rainbow"),
    ]

    static let cheers = ["Colorful!", "Paint-tastic!", "That's right!", "What an artist!", "Bright idea!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "mix":
            return SkyBank.pick(mixes, count, using: &rng).enumerated().map { i, m in
                let flip = Bool.random(using: &rng)
                let (a, b) = flip ? (m.b, m.a) : (m.a, m.b)
                let wrong = mixes.map(\.makes).filter { $0 != m.makes }.map(label)
                return QuizRound(visual: .text("\(swatch[a]!) + \(swatch[b]!)"), say: "Mix \(a) and \(b). What color do you get?",
                                 choices: QuizShuffle.choices(label(m.makes), wrong, using: &rng), answer: label(m.makes),
                                 cheer: "\(a.capitalized) and \(b) make \(m.makes)! \(cheer(i))")
            }
        case "warmcool":
            return (0..<count).map { i -> QuizRound in
                let wantWarm = i % 2 == 0
                let right = (wantWarm ? warm : cool).randomElement(using: &rng)!
                let wrong = Array((wantWarm ? cool : warm).shuffled(using: &rng).prefix(2))
                return QuizRound(visual: .picture(wantWarm ? "🔥" : "💧"), say: wantWarm ? "Which one is a warm color?" : "Which one is a cool color?",
                                 choices: QuizShuffle.choices(label(right), wrong.map(label), using: &rng), answer: label(right),
                                 cheer: "\(right.capitalized) is a \(wantWarm ? "warm" : "cool") color. \(cheer(i))")
            }
        case "light":
            return SkyBank.pick(lightDark, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["🎨", "🖌️", "🌙", "🍋", "🖍️"][i % 5]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "Yes: \(q.answer). \(cheer(i))")
            }
        default: // rainbow
            return (0..<count).map { i -> QuizRound in
                let k = Int.random(in: 0..<(rainbow.count - 1), using: &rng)
                let shown = rainbow.prefix(k + 1).map { swatch[$0]! }.joined(separator: " ") + " ❓"
                let answer = rainbow[k + 1]
                let wrong = rainbow.filter { $0 != answer }.map(label)
                return QuizRound(visual: .text(shown), say: "In a rainbow, which color comes after \(rainbow[k])?",
                                 choices: QuizShuffle.choices(label(answer), wrong, using: &rng), answer: label(answer),
                                 cheer: "\(answer.capitalized) comes after \(rainbow[k]). \(cheer(i))")
            }
        }
    }
}

// MARK: - Even Steven (v9.32)

enum EvenBank {
    static let items: [String: (one: String, many: String)] = ["🧦": ("sock", "socks"), "🍪": ("cookie", "cookies"), "👟": ("shoe", "shoes"), "🐟": ("fish", "fish")]
    static let pictures = ["🧦", "🍪", "👟", "🐟"]
    static func isEven(_ n: Int) -> Bool { n % 2 == 0 }

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "pairs", title: "Buddy Pairs", symbol: "person.2.circle.fill", intro: "Put things in pairs. If everyone has a buddy, the number is even!", skill: "even and odd with pairs"),
        QuizGameInfo(id: "which", title: "Spot the Even", symbol: "eye.fill", intro: "Even numbers end in 0, 2, 4, 6 or 8. Odd numbers end in 1, 3, 5, 7 or 9.", skill: "even and odd numbers"),
        QuizGameInfo(id: "twos", title: "Count by Twos", symbol: "2.circle.fill", intro: "Two, four, six, eight! Skip-count by twos.", skill: "counting by twos"),
        QuizGameInfo(id: "share", title: "Fair Share", symbol: "square.split.2x1.fill", intro: "Share fairly between two friends. How many does each one get?", skill: "halving even numbers"),
    ]

    static let cheers = ["Even-tastic!", "Purr-fect!", "That's right!", "Super sorting!", "Fair and square!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        let item = pictures.randomElement(using: &rng)!
        let many = items[item]!.many
        switch id {
        case "pairs":
            let ns = Array(Array(3...12).shuffled(using: &rng).prefix(count))
            return ns.enumerated().map { i, n in
                let answer = isEven(n) ? "even" : "odd"
                return QuizRound(visual: .pairs(n, item: item), say: "There are \(n) \(many). Does every one have a buddy? Is \(n) even or odd?",
                                 choices: ["even", "odd"], answer: answer,
                                 cheer: isEven(n) ? "Every one has a buddy, so \(n) is even. \(cheer(i))" : "One is left over, so \(n) is odd. \(cheer(i))")
            }
        case "which":
            return (0..<count).map { i -> QuizRound in
                let wantEven = i % 2 == 0
                var pool = Array(1...30).shuffled(using: &rng)
                let right = pool.first { isEven($0) == wantEven }!
                pool.removeAll { $0 == right }
                let wrong = Array(pool.filter { isEven($0) != wantEven }.prefix(2))
                return QuizRound(visual: .picture(wantEven ? "✌️" : "☝️"), say: wantEven ? "Which number is even?" : "Which number is odd?",
                                 choices: QuizShuffle.choices("\(right)", wrong.map { "\($0)" }, using: &rng), answer: "\(right)",
                                 cheer: "\(right) is \(wantEven ? "even" : "odd"). \(cheer(i))")
            }
        case "twos":
            return (0..<count).map { i -> QuizRound in
                let start = Int.random(in: 0...8, using: &rng) * 2
                let seq = (0..<3).map { start + $0 * 2 }
                let answer = start + 6
                return QuizRound(visual: .text(seq.map(String.init).joined(separator: ", ") + ", ?"), say: "Count by twos. What comes next?",
                                 choices: GraphBank.numberChoices(answer, others: [answer - 1, answer + 1, answer + 2], using: &rng), answer: "\(answer)",
                                 cheer: "\(seq.map(String.init).joined(separator: ", ")), \(answer)! \(cheer(i))")
            }
        default: // share
            let ns = Array(Array(1...9).shuffled(using: &rng).prefix(count)).map { $0 * 2 }
            return ns.enumerated().map { i, n in
                QuizRound(visual: .pairs(n, item: item), say: "Share \(n) \(many) fairly between 2 friends. How many does each friend get?",
                          choices: GraphBank.numberChoices(n / 2, others: [n, n / 2 + 1, n / 2 - 1], using: &rng), answer: "\(n / 2)",
                          cheer: "\(n) shared by 2 is \(n / 2) each. \(cheer(i))")
            }
        }
    }
}

// MARK: - Animal Club (v9.33)

enum AnimalBank {
    static let animals: [(name: String, picture: String, group: String, covering: String, legs: Int, eats: String)] = [
        ("dog", "🐶", "mammal", "fur", 4, "plants and animals"), ("cow", "🐄", "mammal", "fur", 4, "plants"),
        ("lion", "🦁", "mammal", "fur", 4, "animals"), ("rabbit", "🐰", "mammal", "fur", 4, "plants"),
        ("bear", "🐻", "mammal", "fur", 4, "plants and animals"), ("whale", "🐋", "mammal", "smooth skin", 0, "animals"),
        ("eagle", "🦅", "bird", "feathers", 2, "animals"), ("penguin", "🐧", "bird", "feathers", 2, "animals"),
        ("parrot", "🦜", "bird", "feathers", 2, "plants"), ("shark", "🦈", "fish", "scales", 0, "animals"),
        ("goldfish", "🐠", "fish", "scales", 0, "plants and animals"), ("snake", "🐍", "reptile", "scales", 0, "animals"),
        ("turtle", "🐢", "reptile", "scales", 4, "plants and animals"), ("lizard", "🦎", "reptile", "scales", 4, "animals"),
        ("frog", "🐸", "amphibian", "smooth skin", 4, "animals"), ("ant", "🐜", "insect", "a hard shell", 6, "plants and animals"),
        ("bee", "🐝", "insect", "a hard shell", 6, "plants"), ("ladybug", "🐞", "insect", "a hard shell", 6, "animals"),
    ]
    /// "a dog", "an ant".
    static func a(_ word: String) -> String { (["a", "e", "i", "o", "u"].contains(word.prefix(1)) ? "an " : "a ") + word }
    /// "A dog" at the start of a sentence.
    static func A(_ word: String) -> String { let s = a(word); return s.prefix(1).uppercased() + s.dropFirst() }
    static let groups = ["mammal", "bird", "fish", "reptile", "amphibian", "insect"]
    static let coverings = ["fur", "feathers", "scales", "smooth skin", "a hard shell"]
    static let diets = ["plants", "animals", "plants and animals"]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "group", title: "Animal Groups", symbol: "pawprint.fill", intro: "Mammals, birds, fish, reptiles, amphibians and insects. Which group?", skill: "animal groups"),
        QuizGameInfo(id: "cover", title: "Fur, Feathers or Scales?", symbol: "leaf.fill", intro: "Animals are covered in different things. What covers this one?", skill: "what covers animals"),
        QuizGameInfo(id: "legs", title: "Count the Legs", symbol: "figure.walk", intro: "Two, four, six or none at all! How many legs?", skill: "animal legs"),
        QuizGameInfo(id: "eat", title: "What's for Dinner?", symbol: "fork.knife", intro: "Some animals eat plants, some eat other animals, and some eat both!", skill: "what animals eat"),
    ]

    static let cheers = ["Wild!", "Hop-hop hooray!", "That's right!", "Animal expert!", "Paws-itively right!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        // a turtle's shell is made of scales and bone, so it sits out the covering game
        let picks = SkyBank.pick(id == "cover" ? animals.filter { $0.name != "turtle" } : animals, count, using: &rng)
        return picks.enumerated().map { i, a in
            switch id {
            case "group":
                return QuizRound(visual: .picture(a.picture), say: "What kind of animal is \(Self.a(a.name))?",
                                 choices: QuizShuffle.choices(a.group, groups.filter { $0 != a.group }, using: &rng), answer: a.group,
                                 cheer: "\(Self.A(a.name)) is \(Self.a(a.group))! \(cheer(i))")
            case "cover":
                return QuizRound(visual: .picture(a.picture), say: "What covers \(Self.a(a.name))'s body?",
                                 choices: QuizShuffle.choices(a.covering, coverings.filter { $0 != a.covering }, using: &rng), answer: a.covering,
                                 cheer: "\(Self.A(a.name)) has \(a.covering). \(cheer(i))")
            case "legs":
                return QuizRound(visual: .picture(a.picture), say: "How many legs does \(Self.a(a.name)) have?",
                                 choices: QuizShuffle.choices("\(a.legs)", ["0", "2", "4", "6", "8"].filter { $0 != "\(a.legs)" }, using: &rng), answer: "\(a.legs)",
                                 cheer: a.legs == 0 ? "No legs at all! \(cheer(i))" : "\(a.legs) legs! \(cheer(i))")
            default: // eat
                return QuizRound(visual: .picture(a.picture), say: "What does \(Self.a(a.name)) eat?",
                                 choices: diets, answer: a.eats,
                                 cheer: "\(Self.A(a.name)) eats \(a.eats). \(cheer(i))")
            }
        }
    }
}

// MARK: - Opposite Island (v9.34)

enum OppositeBank {
    static let pairs: [(String, String)] = [
        ("hot", "cold"), ("big", "small"), ("up", "down"), ("fast", "slow"), ("happy", "sad"), ("day", "night"),
        ("open", "closed"), ("full", "empty"), ("wet", "dry"), ("loud", "quiet"), ("in", "out"), ("push", "pull"),
    ]
    static func opposite(_ w: String) -> String? {
        pairs.first { $0.0 == w }?.1 ?? pairs.first { $0.1 == w }?.0
    }

    static let families: [String: [String]] = [
        "fruit": ["🍎 apple", "🍌 banana", "🍇 grapes", "🍓 strawberry"],
        "animal": ["🐶 dog", "🐱 cat", "🐮 cow", "🐷 pig"],
        "vehicle": ["🚗 car", "🚌 bus", "🚲 bike", "✈️ plane"],
        "clothes": ["👕 shirt", "🧦 socks", "🧢 cap", "👖 jeans"],
    ]
    static func family(of thing: String) -> String? { families.first { $0.value.contains(thing) }?.key }
    static let kindOf = ["fruit": "a fruit", "animal": "an animal", "vehicle": "a vehicle", "clothes": "clothing"]

    /// Smallest to biggest.
    static let sizes = ["🐜 ant", "🐭 mouse", "🐱 cat", "🐕 dog", "🐴 horse", "🐘 elephant", "🐋 whale"]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "opposite", title: "Opposites", symbol: "arrow.left.arrow.right", intro: "Hot and cold, up and down! What's the opposite?", skill: "opposite words"),
        QuizGameInfo(id: "odd", title: "Which Doesn't Belong?", symbol: "questionmark.square.dashed", intro: "Three things go together. Which one doesn't belong?", skill: "finding what doesn't belong"),
        QuizGameInfo(id: "together", title: "What Goes Together?", symbol: "square.on.square", intro: "Find the one that belongs with the others!", skill: "sorting into groups"),
        QuizGameInfo(id: "size", title: "Biggest and Smallest", symbol: "arrow.up.and.down.square.fill", intro: "Picture them side by side. Which is biggest? Which is smallest?", skill: "comparing sizes"),
    ]

    static let cheers = ["Island-tastic!", "Holy guacamole!", "That's right!", "Smart thinking!", "You got it!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "opposite":
            return SkyBank.pick(pairs, count, using: &rng).enumerated().map { i, p in
                let (w, answer) = Bool.random(using: &rng) ? p : (p.1, p.0)
                let wrong = pairs.flatMap { [$0.0, $0.1] }.filter { $0 != answer && $0 != w }
                return QuizRound(visual: .text(w.uppercased()), say: "What's the opposite of \(w)?",
                                 choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "\(w.capitalized) and \(answer) are opposites. \(cheer(i))")
            }
        case "odd", "together":
            let keys = families.keys.sorted()
            return (0..<count).map { i -> QuizRound in
                let main = keys[(i + Int.random(in: 0..<keys.count, using: &rng)) % keys.count]
                let other = keys.filter { $0 != main }.randomElement(using: &rng)!
                let mains = families[main]!.shuffled(using: &rng)
                let outsider = families[other]!.randomElement(using: &rng)!
                if id == "odd" {
                    return QuizRound(visual: .none, say: "Which one doesn't belong?",
                                     choices: QuizShuffle.choices(outsider, Array(mains.prefix(2)), using: &rng), answer: outsider,
                                     cheer: "The \(outsider.split(separator: " ").last!) isn't \(kindOf[main] ?? main). \(cheer(i))")
                }
                let others = keys.filter { $0 != main }.shuffled(using: &rng).prefix(2).map { families[$0]!.randomElement(using: &rng)! }
                return QuizRound(visual: .text(mains.prefix(2).map { String($0.split(separator: " ").first!) }.joined(separator: "  ")),
                                 say: "Which one goes with these?",
                                 choices: QuizShuffle.choices(mains[2], others, using: &rng), answer: mains[2],
                                 cheer: "They're all \(main == "clothes" ? "clothes" : main + "s")! \(cheer(i))")
            }
        default: // size
            return (0..<count).map { i -> QuizRound in
                let three = Array(sizes.shuffled(using: &rng).prefix(3))
                let order = three.sorted { sizes.firstIndex(of: $0)! < sizes.firstIndex(of: $1)! }
                let biggest = i % 2 == 0
                let answer = biggest ? order[2] : order[0]
                return QuizRound(visual: .none, say: biggest ? "Which one is the biggest?" : "Which one is the smallest?",
                                 choices: three, answer: answer,
                                 cheer: "The \(answer.split(separator: " ").last!) is the \(biggest ? "biggest" : "smallest"). \(cheer(i))")
            }
        }
    }
}

// MARK: - Sentence Station (v9.35)

enum SentenceBank {
    static let sentences = ["The dog runs fast.", "My cat is sleepy.", "We play at the park.", "I like red apples.", "The sun is hot.",
                            "Birds can fly.", "She has a blue hat.", "It is time for lunch."]
    static let endings: [(text: String, mark: String)] = [
        ("Where is my hat", "?"), ("Can we go outside", "?"), ("What is your name", "?"), ("Do you like cake", "?"),
        ("I like pizza", "."), ("The sky is blue", "."), ("My dog is brown", "."), ("We read a book", "."),
        ("Watch out", "!"), ("Yay, we won", "!"), ("Wow, look at that rainbow", "!"), ("Hooray, it snowed", "!"),
    ]
    static let plurals: [(one: String, many: String, wrong: [String])] = [
        ("cat", "cats", ["cates", "caties"]), ("box", "boxes", ["boxs", "boxies"]), ("bus", "buses", ["buss", "busies"]),
        ("dog", "dogs", ["doges", "dogies"]), ("fox", "foxes", ["foxs", "foxen"]), ("mouse", "mice", ["mouses", "mousies"]),
        ("foot", "feet", ["foots", "footies"]), ("child", "children", ["childs", "childies"]), ("dish", "dishes", ["dishs", "dishies"]),
        ("bird", "birds", ["birdes", "birdies"]),
    ]
    static let questionWords: [(blank: String, answer: String)] = [
        ("___ is your name?", "What"), ("___ do you live?", "Where"), ("___ will you go to bed?", "When"),
        ("___ is your best friend?", "Who"), ("___ are you smiling?", "Why"), ("___ color is the sky?", "What"),
        ("___ is the park?", "Where"), ("___ is your teacher?", "Who"),
    ]
    static let qWords = ["Who", "What", "Where", "When", "Why"]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "capital", title: "Big Letter First", symbol: "textformat.size.larger", intro: "Every sentence starts with a capital letter!", skill: "capital letters"),
        QuizGameInfo(id: "end", title: "End Marks", symbol: "questionmark", intro: "A period tells, a question mark asks, and an exclamation mark shouts!", skill: "periods, question marks and exclamation marks"),
        QuizGameInfo(id: "plural", title: "One or More", symbol: "square.stack.fill", intro: "One cat, two cats! Some words change in surprising ways.", skill: "plurals"),
        QuizGameInfo(id: "qword", title: "Question Words", symbol: "bubble.left.fill", intro: "Who, what, where, when and why. Which one fits?", skill: "question words"),
    ]

    static let cheers = ["Full steam ahead!", "Crunch-tastic!", "That's right!", "Sentence superstar!", "All aboard!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "capital":
            return SkyBank.pick(sentences, count, using: &rng).enumerated().map { i, s in
                let lower = s.prefix(1).lowercased() + s.dropFirst()
                let words = s.split(separator: " ").map(String.init)
                let middle = ([words[0].lowercased()] + words.dropFirst().enumerated().map { k, w in k == 0 ? w.capitalized : w }).joined(separator: " ")
                return QuizRound(visual: .picture("🚂"), say: "Which sentence starts the right way?",
                                 choices: QuizShuffle.choices(s, [lower, middle], using: &rng), answer: s,
                                 cheer: "It starts with a capital \(s.prefix(1)). \(cheer(i))")
            }
        case "end":
            return SkyBank.pick(endings, count, using: &rng).enumerated().map { i, e in
                QuizRound(visual: .text(e.text + " ◻"), say: "Which mark goes at the end?",
                          choices: [".", "?", "!"], answer: e.mark,
                          cheer: (e.mark == "?" ? "It asks something, so it gets a question mark." : e.mark == "!" ? "It's exciting, so it gets an exclamation mark!" : "It tells something, so it gets a period.") + " \(cheer(i))")
            }
        case "plural":
            return SkyBank.pick(plurals, count, using: &rng).enumerated().map { i, p in
                QuizRound(visual: .text("1 \(p.one) → 2 ?"), say: "One \(p.one), two what?",
                          choices: QuizShuffle.choices(p.many, p.wrong, using: &rng), answer: p.many,
                          cheer: "One \(p.one), two \(p.many)! \(cheer(i))")
            }
        default: // qword
            return SkyBank.pick(questionWords, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .text(q.blank), say: "Which question word fits?",
                          choices: QuizShuffle.choices(q.answer, qWords.filter { $0 != q.answer }, using: &rng), answer: q.answer,
                          cheer: q.blank.replacingOccurrences(of: "___", with: q.answer) + " \(cheer(i))")
            }
        }
    }
}

// MARK: - Learn page subjects (v9.36, v9.38)

/// Filter chips on the Learn page: every place belongs to one subject.
enum LearnSubject: String, CaseIterable, Identifiable {
    case all, words, math, science, world, art
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .words: return "Words"
        case .math: return "Math"
        case .science: return "Science"
        case .world: return "World & Me"
        case .art: return "Art & Music"
        }
    }

    var symbol: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .words: return "textformat.abc"
        case .math: return "number"
        case .science: return "leaf.fill"
        case .world: return "globe.americas.fill"
        case .art: return "paintpalette.fill"
        }
    }

    static let places: [LearnSubject: [String]] = [
        .words: ["reading", "writing", "spelling", "rhyme", "words", "sounds", "sentences", "opposites"],
        .math: ["market", "clock", "fractions", "shapes", "numbers", "times", "measure", "calendar", "graphs", "tenframe", "numberline", "evenodd"],
        .science: ["science", "nature", "sky", "planet", "animals", "healthy", "ocean", "dinos"],
        .world: ["world", "feelings", "compass", "helpers", "kindness", "vehicles"],
        .art: ["music", "colors"],
    ]

    /// The subject a place belongs to (nil for places that aren't on the Learn grid, like Code Club).
    static func of(_ placeID: String) -> LearnSubject? {
        places.first { $0.value.contains(placeID) }?.key
    }

    func includes(_ placeID: String) -> Bool { self == .all || LearnSubject.of(placeID) == self }

    /// "3 of 12 done" for a chip: places finished (every game at 2 stars or more) out of the subject's places on the menu.
    static func done(_ subject: LearnSubject, areas: [LearningArea]) -> (done: Int, total: Int) {
        let mine = areas.filter { subject.includes($0.id) && $0.id != "code" }
        return (mine.filter(\.finished).count, mine.count)
    }
}

// MARK: - Mystery Mix (v9.37)

/// Five questions from quiz places the child has already played, one place at a time. Always there, never daily.
enum MysteryMix {
    static let id = "mystery"
    static let minSources = 2
    static let quizPlaceIDs = ["spelling", "fractions", "shapes", "rhyme", "numbers", "times", "measure", "feelings", "nature", "calendar",
                               "compass", "healthy", "planet", "graphs", "words", "tenframe", "sky", "helpers", "sounds", "numberline",
                               "colors", "evenodd", "animals", "opposites", "sentences", "ocean", "dinos", "kindness", "vehicles"]

    /// Places played at least once and still on the menu, optionally only one subject's (v9.49).
    static func sources(plays: [String: Int], shown: (String) -> Bool, subject: LearnSubject = .all) -> [String] {
        quizPlaceIDs.filter { (plays[$0] ?? 0) > 0 && shown($0) && subject.includes($0) }
    }

    /// The route id for a subject's Mystery Mix: "mystery" or "mystery:math".
    static func routeID(_ subject: LearnSubject) -> String { subject == .all ? id : "\(id):\(subject.rawValue)" }
    static func subject(fromRoute route: String) -> LearnSubject? {
        guard route == id || route.hasPrefix(id + ":") else { return nil }
        return LearnSubject(rawValue: String(route.dropFirst(id.count + 1))) ?? .all
    }

    /// Which place and game each question comes from: places take turns, so five places give five different ones.
    static func plan<G: RandomNumberGenerator>(sources: [String], games: (String) -> [String], count: Int = 5, using rng: inout G) -> [(place: String, game: String)] {
        guard !sources.isEmpty else { return [] }
        let order = sources.shuffled(using: &rng)
        return (0..<count).compactMap { k in
            let place = order[k % order.count]
            guard let game = games(place).randomElement(using: &rng) else { return nil }
            return (place, game)
        }
    }
}

// MARK: - Shared: count one kind of thing in a jumble (Ocean Cove, Dino Dig)

enum JumbleCount {
    /// A jumble of 2–3 kinds of things, with a different number of each; ask how many of one kind.
    static func round<G: RandomNumberGenerator>(kinds: [String], say: (String) -> String, cheer: String, using rng: inout G) -> QuizRound {
        let picked = Array(kinds.shuffled(using: &rng).prefix(Int.random(in: 2...3, using: &rng)))
        let counts = Array(Array(1...7).shuffled(using: &rng).prefix(picked.count))
        var items: [String] = []
        for (k, c) in zip(picked, counts) { items += Array(repeating: k, count: c) }
        items.shuffle(using: &rng)
        let ask = picked[0], n = counts[0]
        return QuizRound(visual: .jumble(items), say: say(GraphBank.many(ask)),
                         choices: GraphBank.numberChoices(n, others: counts.filter { $0 != n } + [n + 1], using: &rng), answer: "\(n)",
                         cheer: "\(n) \(n == 1 ? GraphBank.one(ask) : GraphBank.many(ask))! \(cheer)")
    }
}

// MARK: - Ocean Cove (v9.45)

enum OceanBank {
    static let sea: [(name: String, picture: String)] = [
        ("whale", "🐋"), ("octopus", "🐙"), ("shark", "🦈"), ("jellyfish", "🪼"), ("dolphin", "🐬"), ("squid", "🦑"), ("lobster", "🦞"), ("shrimp", "🦐"),
    ]
    static let land: [(name: String, picture: String)] = [
        ("lion", "🦁"), ("cow", "🐄"), ("horse", "🐴"), ("giraffe", "🦒"), ("camel", "🐫"), ("squirrel", "🐿️"), ("fox", "🦊"), ("elephant", "🐘"),
    ]
    static let facts: [(say: String, answer: String, wrong: [String])] = [
        ("How many arms does an octopus have?", "8", ["4", "10"]),
        ("Whales breathe through a hole on top of their head. What do they breathe?", "air", ["water", "sand"]),
        ("Is ocean water salty or sweet?", "salty", ["sweet", "spicy"]),
        ("Fish breathe underwater with special body parts. What are they called?", "gills", ["wings", "elbows"]),
        ("What do sea turtles lay in the sand on the beach?", "eggs", ["shells", "pearls"]),
        ("What is the biggest animal that has ever lived?", "the blue whale", ["the shark", "the octopus"]),
        ("What do we call a big group of fish swimming together?", "a school", ["a herd", "a flock"]),
    ]
    static let words: [(picture: String, word: String)] = [
        ("🌊", "wave"), ("🐚", "shell"), ("🏝️", "island"), ("⛵", "sailboat"), ("🪸", "coral"), ("⚓", "anchor"), ("🏖️", "beach"),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "who", title: "Who Lives Here?", symbol: "water.waves", intro: "Some animals live in the ocean, and some live on land. Who's who?", skill: "ocean and land animals"),
        QuizGameInfo(id: "facts", title: "Ocean Facts", symbol: "fish.fill", intro: "Dive in! How much do you know about the ocean?", skill: "facts about the ocean"),
        QuizGameInfo(id: "count", title: "Tide Pool Count", symbol: "circle.grid.3x3.fill", intro: "Peek into the tide pool and count carefully!", skill: "counting in a group"),
        QuizGameInfo(id: "words", title: "Beach Words", symbol: "beach.umbrella.fill", intro: "Waves, shells and sailboats! What's this called?", skill: "ocean words"),
    ]

    static let cheers = ["Fin-tastic!", "Splash-tastic!", "That's right!", "Ocean explorer!", "Shell yeah!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "who":
            return (0..<count).map { i -> QuizRound in
                let wantSea = i % 2 == 0
                let right = (wantSea ? sea : land).randomElement(using: &rng)!
                let wrong = Array((wantSea ? land : sea).shuffled(using: &rng).prefix(2)).map { "\($0.picture) \($0.name)" }
                let answer = "\(right.picture) \(right.name)"
                return QuizRound(visual: .picture(wantSea ? "🌊" : "🌳"), say: wantSea ? "Who lives in the ocean?" : "Who lives on land?",
                                 choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "The \(right.name) lives \(wantSea ? "in the ocean" : "on land")! \(cheer(i))")
            }
        case "facts":
            return SkyBank.pick(facts, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["🐙", "🐋", "🌊", "🐠", "🐢", "🐟", "🐡"][i % 7]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "Yes: \(q.answer)! \(cheer(i))")
            }
        case "count":
            return (0..<count).map { i in
                JumbleCount.round(kinds: ["🐚", "🦀", "🐠", "🪨"], say: { "How many \($0) are in the tide pool?" }, cheer: cheer(i), using: &rng)
            }
        default: // words
            return SkyBank.pick(words, count, using: &rng).enumerated().map { i, w in
                QuizRound(visual: .picture(w.picture), say: "What is this called?",
                          choices: QuizShuffle.choices(w.word, words.map(\.word).filter { $0 != w.word }, using: &rng), answer: w.word,
                          cheer: "It's \(AnimalBank.a(w.word))! \(cheer(i))")
            }
        }
    }
}

// MARK: - Dino Dig (v9.46)

enum DinoBank {
    static let diets: [(name: String, eats: String)] = [
        ("T. rex", "meat"), ("Triceratops", "plants"), ("Stegosaurus", "plants"), ("Brachiosaurus", "plants"), ("Velociraptor", "meat"),
        ("Spinosaurus", "meat"), ("Ankylosaurus", "plants"), ("Diplodocus", "plants"), ("Allosaurus", "meat"),
    ]
    static let facts: [(say: String, answer: String, wrong: [String])] = [
        ("What do we call bones and footprints that turned to stone?", "fossils", ["pebbles", "crayons"]),
        ("Did people live at the same time as dinosaurs?", "no, dinosaurs lived long before people", ["yes, they were friends", "yes, as pets"]),
        ("Which animals today are related to dinosaurs?", "birds", ["cats", "fish"]),
        ("Did baby dinosaurs hatch from eggs?", "yes", ["no", "only on Tuesdays"]),
        ("What does extinct mean?", "all gone, none left", ["sleeping", "hiding"]),
        ("Which dinosaur had three horns on its face?", "Triceratops", ["T. rex", "Brachiosaurus"]),
        ("Which dinosaur had big plates along its back?", "Stegosaurus", ["Velociraptor", "T. rex"]),
        ("Which dinosaur had a very, very long neck?", "Brachiosaurus", ["Velociraptor", "Triceratops"]),
    ]
    /// Smallest to biggest, with big gaps between them.
    static let sizes = ["Compsognathus (as big as a chicken)", "Velociraptor (as big as a turkey)", "T. rex (as long as a bus)", "Brachiosaurus (as tall as a building)"]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "eat", title: "Plant or Meat Eater?", symbol: "leaf.fill", intro: "Some dinosaurs munched plants. Others hunted for meat!", skill: "what dinosaurs ate"),
        QuizGameInfo(id: "facts", title: "Dino Facts", symbol: "fossil.shell.fill", intro: "Dig up some dinosaur facts!", skill: "dinosaur facts"),
        QuizGameInfo(id: "size", title: "Dino Sizes", symbol: "ruler.fill", intro: "Some dinosaurs were tiny. Some were taller than a house!", skill: "comparing dinosaur sizes"),
        QuizGameInfo(id: "dig", title: "Dig and Count", symbol: "hammer.fill", intro: "Brush away the dirt and count what you find!", skill: "counting in a group"),
    ]

    static let cheers = ["Dino-mite!", "Roar-some!", "That's right!", "Fossil finder!", "Jurassic genius!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "eat":
            return SkyBank.pick(diets, count, using: &rng).enumerated().map { i, d in
                QuizRound(visual: .picture(d.eats == "meat" ? "🦖" : "🦕"), say: "What did \(d.name) eat?",
                          choices: ["plants", "meat"], answer: d.eats,
                          cheer: "\(d.name) ate \(d.eats). \(cheer(i))")
            }
        case "facts":
            return SkyBank.pick(facts, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["🦴", "🦕", "🦖", "🥚", "🌋"][i % 5]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "Yes: \(q.answer)! \(cheer(i))")
            }
        case "size":
            return (0..<count).map { i -> QuizRound in
                let three = Array(sizes.shuffled(using: &rng).prefix(3))
                let order = three.sorted { sizes.firstIndex(of: $0)! < sizes.firstIndex(of: $1)! }
                let biggest = i % 2 == 0
                let answer = biggest ? order[2] : order[0]
                return QuizRound(visual: .picture("📏"), say: biggest ? "Which dinosaur was the biggest?" : "Which dinosaur was the smallest?",
                                 choices: three, answer: answer,
                                 cheer: "\(answer.components(separatedBy: " (")[0]) was the \(biggest ? "biggest" : "smallest") of these. \(cheer(i))")
            }
        default: // dig
            return (0..<count).map { i in
                JumbleCount.round(kinds: ["🦴", "🥚", "🪨", "🐚"], say: { "How many \($0) did you dig up?" }, cheer: cheer(i), using: &rng)
            }
        }
    }
}

// MARK: - Kindness Club (v9.47)

enum KindBank {
    static let manners: [(say: String, answer: String, wrong: [String])] = [
        ("Grandma gives you a present. What can you say?", "Thank you!", ["Is that all?", "Give me more!"]),
        ("You bump into someone by accident. What can you say?", "I'm sorry!", ["Move!", "Watch it!"]),
        ("You want a turn on the swing. What can you say?", "May I have a turn, please?", ["Get off!", "It's mine now!"]),
        ("Someone says thank you to you. What can you say?", "You're welcome!", ["Whatever.", "Go away!"]),
        ("You need to get past someone. What can you say?", "Excuse me, please.", ["Out of my way!", "Move it!"]),
        ("You meet a new kid at the park. What can you say?", "Hi! Do you want to play?", ["Go away.", "You can't play."]),
    ]
    static let kind = ["share your crayons", "help a friend who fell", "let someone go first", "invite a new kid to play", "say something nice", "hold the door"]
    static let unkind = ["grab a toy", "laugh when someone falls", "push to be first", "leave someone out", "say something mean", "cut in line"]
    static let helping: [(say: String, answer: String, wrong: [String])] = [
        ("Your friend dropped all their books. How can you help?", "help pick them up", ["walk away", "laugh"]),
        ("Someone is sitting alone at lunch. What can you do?", "ask them to sit with you", ["point at them", "ignore them"]),
        ("Your little brother can't reach a cup. How can you help?", "get it for him or ask a grown-up", ["tell him to stop", "take his cup"]),
        ("Your friend looks sad. What can you do?", "ask if they're okay", ["tell them to cheer up now", "leave them alone forever"]),
        ("Toys are all over the floor after playtime. How can you help?", "help clean up", ["hide under the bed", "throw more toys"]),
    ]
    static let sport: [(say: String, answer: String, wrong: [String])] = [
        ("You lost a game. What can you say?", "Good game!", ["That's not fair!", "I quit!"]),
        ("You won a game! What can you say?", "Good game! Want to play again?", ["I'm the best, you're the worst!", "Ha ha!"]),
        ("It's someone else's turn. What do you do?", "wait patiently", ["take their turn", "stomp your feet"]),
        ("Your teammate makes a mistake. What can you say?", "It's okay, let's try again!", ["You ruined it!", "You're bad at this!"]),
        ("A friend does something great. What can you say?", "Wow, nice job!", ["So what.", "I could do better."]),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "words", title: "Magic Words", symbol: "sparkles", intro: "Please, thank you, sorry and excuse me are magic words. Which one fits?", skill: "polite words"),
        QuizGameInfo(id: "kind", title: "Kind or Not?", symbol: "heart.fill", intro: "Kind choices make everyone feel good. Which one is kind?", skill: "kind choices"),
        QuizGameInfo(id: "help", title: "Helping Hands", symbol: "hand.raised.fill", intro: "Little helpers make a big difference. How can you help?", skill: "helping others"),
        QuizGameInfo(id: "sport", title: "Good Sport", symbol: "figure.2.arms.open", intro: "Win or lose, a good sport is kind. What's the good-sport thing to do?", skill: "being a good sport"),
    ]

    static let cheers = ["Kindness hero!", "Heart of gold!", "That's right!", "So kind!", "What a good friend!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "kind":
            return (0..<count).map { i -> QuizRound in
                let right = kind.randomElement(using: &rng)!
                let wrong = Array(unkind.shuffled(using: &rng).prefix(2))
                return QuizRound(visual: .picture("💛"), say: "Which one is kind?",
                                 choices: QuizShuffle.choices(right, wrong, using: &rng), answer: right,
                                 cheer: "Yes! It's kind to \(right). \(cheer(i))")
            }
        default:
            let bank = id == "words" ? manners : id == "help" ? helping : sport
            return SkyBank.pick(bank, count, using: &rng).enumerated().map { i, q in
                QuizRound(visual: .picture(["🎁", "🤝", "🛝", "😊", "🙋"][i % 5]), say: q.say,
                          choices: QuizShuffle.choices(q.answer, q.wrong, using: &rng), answer: q.answer,
                          cheer: "\(sentence(q.answer)) \(cheer(i))")
            }
        }
    }

    /// "help clean up" → "Help clean up."; "Thank you!" stays as it is.
    static func sentence(_ s: String) -> String {
        let t = s.prefix(1).uppercased() + s.dropFirst()
        return ".!?".contains(t.last ?? ".") ? t : t + "."
    }
}

// MARK: - On the Move (v9.48)

enum MoveBank {
    static let ways: [(name: String, picture: String, goes: String)] = [
        ("car", "🚗", "land"), ("train", "🚆", "land"), ("bike", "🚲", "land"), ("tractor", "🚜", "land"),
        ("sailboat", "⛵", "water"), ("ship", "🚢", "water"), ("canoe", "🛶", "water"), ("speedboat", "🚤", "water"),
        ("plane", "✈️", "air"), ("helicopter", "🚁", "air"), ("parachute", "🪂", "air"),
    ]
    static let wheels: [(name: String, picture: String, count: Int)] = [
        ("bike", "🚲", 2), ("scooter", "🛴", 2), ("motorcycle", "🏍️", 2), ("auto rickshaw", "🛺", 3),
        ("car", "🚗", 4), ("skateboard", "🛹", 4), ("shopping cart", "🛒", 4),
    ]
    static let jobs: [(say: String, picture: String, answer: String)] = [
        ("Which one takes sick people to the hospital?", "🏥", "🚑 ambulance"), ("Which one helps put out fires?", "🔥", "🚒 fire truck"),
        ("Which one takes kids to school?", "🏫", "🚌 school bus"), ("Which one plows the farm fields?", "🌾", "🚜 tractor"),
        ("Which one flies people far away on a trip?", "🧳", "✈️ plane"), ("Which one runs on tracks?", "🛤️", "🚆 train"),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "where", title: "Land, Water or Air?", symbol: "map.fill", intro: "Some things go on roads, some float on water, and some fly!", skill: "how things travel"),
        QuizGameInfo(id: "wheels", title: "Count the Wheels", symbol: "circle.circle.fill", intro: "Two wheels, three wheels or four? Count them!", skill: "counting wheels"),
        QuizGameInfo(id: "jobs", title: "Busy Vehicles", symbol: "box.truck.fill", intro: "Every vehicle has a job. Which one does this job?", skill: "what vehicles do"),
        QuizGameInfo(id: "count", title: "Traffic Count", symbol: "car.2.fill", intro: "Look at all the traffic! Count carefully.", skill: "counting in a group"),
    ]

    static let cheers = ["Zoom zoom!", "Beep beep, hooray!", "That's right!", "Full speed ahead!", "Wheel-y good!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "where":
            return SkyBank.pick(ways, count, using: &rng).enumerated().map { i, w in
                QuizRound(visual: .picture(w.picture), say: "Where does \(AnimalBank.a(w.name)) go: on land, on water, or in the air?",
                          choices: ["land", "water", "air"], answer: w.goes,
                          cheer: "\(AnimalBank.A(w.name)) goes \(w.goes == "land" ? "on land" : w.goes == "water" ? "on water" : "in the air")! \(cheer(i))")
            }
        case "wheels":
            return SkyBank.pick(wheels, count, using: &rng).enumerated().map { i, w in
                QuizRound(visual: .picture(w.picture), say: "How many wheels does \(AnimalBank.a(w.name)) have?",
                          choices: ["2", "3", "4"], answer: "\(w.count)",
                          cheer: "\(w.count) wheels! \(cheer(i))")
            }
        case "jobs":
            return SkyBank.pick(jobs, count, using: &rng).enumerated().map { i, j in
                QuizRound(visual: .picture(j.picture), say: j.say,
                          choices: QuizShuffle.choices(j.answer, jobs.map(\.answer).filter { $0 != j.answer }, using: &rng), answer: j.answer,
                          cheer: "The \(j.answer.split(separator: " ").dropFirst().joined(separator: " "))! \(cheer(i))")
            }
        default: // count
            return (0..<count).map { i in
                JumbleCount.round(kinds: ["🚗", "🚌", "🚲", "🚕"], say: { "How many \($0) can you count?" }, cheer: cheer(i), using: &rng)
            }
        }
    }
}

// MARK: - Place progress helpers (v9.50–v9.56)

enum PlaceProgress {
    /// A place is complete when every game has 2 stars or more (the same rule as badges and the grown-ups' page).
    static func isComplete(_ bests: [Int]) -> Bool { !bests.isEmpty && bests.allSatisfy { $0 >= 2 } }

    /// The game to suggest after `current` (v9.51): the next one in order that isn't at 3 stars yet; nil when all are.
    static func next(after current: String, games: [String], best: (String) -> Int) -> String? {
        guard let i = games.firstIndex(of: current) else { return nil }
        let order = Array(games[(i + 1)...] + games[..<i])
        return order.first { best($0) < 3 }
    }

    /// The game to try next on a place page (v9.56): one at 1 star first, then the first not played.
    static func tryNext(games: [String], best: (String) -> Int) -> String? {
        games.first { best($0) == 1 } ?? games.first { best($0) == 0 }
    }

    /// The skill to name on the Keep going card (v9.52): a game at 1 star first, then the first not played.
    static func skillToPractise(_ area: LearningArea) -> String? {
        (area.skills.first { $0.best == 1 } ?? area.skills.first { $0.best == 0 })?.skill
    }

    /// All-Rounder (v9.50): at least one finished place in every subject.
    static func allRounder(_ finished: Set<String>) -> Bool {
        LearnSubject.allCases.filter { $0 != .all }.allSatisfy { sub in finished.contains { LearnSubject.of($0) == sub } }
    }
}

// MARK: - Tricky Mix, voice speed, badge groups (v9.58–v9.62)

/// Tricky Mix (v9.58): practise the games still at 1 star, from every place. Spaced practice for the shaky ones.
enum TrickyMix {
    static let id = "tricky"

    /// Every (place, game) still at 1 star, among the quiz places on the menu, in menu order.
    static func picks(places: [String], shown: (String) -> Bool, games: (String) -> [String], best: (String, String) -> Int) -> [(place: String, game: String)] {
        places.filter(shown).flatMap { place in games(place).filter { best(place, $0) == 1 }.map { (place, $0) } }
    }

    /// Up to `count` rounds, the tricky games taking turns, no question twice.
    static func rounds(picks: [(place: String, game: String)], count: Int = 5, make: (String, String) -> [QuizRound], label: (String) -> String) -> [QuizRound] {
        guard !picks.isEmpty else { return [] }
        var out: [QuizRound] = []
        var tries = 0
        var k = 0
        while out.count < count && tries < count * 4 {
            let p = picks[k % picks.count]
            k += 1; tries += 1
            if let r = make(p.place, p.game).first(where: { r in !out.contains { $0.say == r.say && $0.visual == r.visual } }) {
                out.append(r.tagged(label(p.place)))
            }
        }
        return out
    }
}

/// A slower voice for young listeners (v9.61), set by grown-ups.
enum VoiceSpeed {
    static let key = "hq.slowVoice"
    static let slowFactor: Float = 0.8
    static func rate(_ base: Float, slow: Bool) -> Float { slow ? base * slowFactor : base }
}

/// The badges wall in two groups (v9.62): one badge per place, then everything else.
enum BadgeGroups {
    static func split(_ all: [Badge]) -> (places: [Badge], other: [Badge]) {
        (all.filter { $0.id.hasPrefix("area-") }, all.filter { !$0.id.hasPrefix("area-") })
    }
}
