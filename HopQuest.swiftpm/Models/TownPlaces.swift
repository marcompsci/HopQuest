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
                                 cheer: "\(right.capitalized) for \(w.id) days! \(cheer(i))")
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
    static let ids: Set<String> = ["words", "tenframe", "sky", "helpers", "sounds", "numberline"]

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
