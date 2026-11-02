import Foundation

// Three more learning places (v8.2–v8.4): Nature Trail, Calendar Corner and Compass Camp.
// Plain Swift on the shared quiz engine, tested in Tests/Learn.

/// Names for the map pictures, for VoiceOver and for questions.
enum GridWords {
    static let names: [String: String] = [
        "⛺": "tent", "🌲": "tree", "🏠": "house", "🐻": "bear", "🦊": "fox", "🏕️": "campfire", "🌊": "lake", "⛰️": "mountain",
        "🍎": "apple", "🌸": "flower", "🐢": "turtle", "🦉": "owl", "🐰": "bunny", "🦆": "duck", "🐿️": "squirrel", "🐸": "frog",
        "🚩": "flag", "🍄": "mushroom",
    ]
    static func name(_ emoji: String) -> String { names[emoji] ?? emoji }
}

// MARK: - Nature Trail (v8.2)

enum NatureBank {
    /// Animals and where they live. Each animal has one home that clearly fits.
    static let homes: [(animal: String, picture: String, home: String)] = [
        ("camel", "🐫", "desert"), ("scorpion", "🦂", "desert"), ("penguin", "🐧", "polar ice"), ("seal", "🦭", "polar ice"),
        ("monkey", "🐒", "rainforest"), ("parrot", "🦜", "rainforest"), ("clownfish", "🐠", "ocean"), ("shark", "🦈", "ocean"),
        ("deer", "🦌", "forest"), ("owl", "🦉", "forest"), ("cow", "🐄", "farm"), ("pig", "🐖", "farm"),
        ("frog", "🐸", "pond"), ("duck", "🦆", "pond"),
    ]
    static let habitats = ["desert", "polar ice", "rainforest", "ocean", "forest", "farm", "pond"]
    /// Other homes that would also be fair answers, kept out of the wrong choices.
    static let alsoFits: [String: Set<String>] = [
        "seal": ["ocean"], "penguin": ["ocean"], "duck": ["farm"], "frog": ["rainforest", "forest"],
        "parrot": ["forest"], "monkey": ["forest"], "owl": ["farm"], "deer": ["farm"],
    ]

    /// Life cycles, in order.
    static let cycles: [(name: String, stages: [(String, String)])] = [
        ("frog", [("egg", "🥚"), ("tadpole", "〰️"), ("froglet", "🐸"), ("frog", "🐸")]),
        ("butterfly", [("egg", "🥚"), ("caterpillar", "🐛"), ("chrysalis", "🫘"), ("butterfly", "🦋")]),
        ("chicken", [("egg", "🥚"), ("chick", "🐥"), ("hen", "🐔")]),
        ("plant", [("seed", "🌰"), ("sprout", "🌱"), ("plant", "🪴"), ("flower", "🌻")]),
    ]

    /// Things to notice, and the sense you use.
    static let senses: [(thing: String, picture: String, sense: String, part: String)] = [
        ("see a rainbow", "🌈", "sight", "eyes"), ("hear a bell ring", "🔔", "hearing", "ears"), ("smell a flower", "🌸", "smell", "nose"),
        ("taste a lemon", "🍋", "taste", "tongue"), ("feel a soft teddy bear", "🧸", "touch", "skin"), ("see the stars", "🌟", "sight", "eyes"),
        ("hear a drum", "🥁", "hearing", "ears"), ("smell cookies baking", "🍪", "smell", "nose"), ("feel a prickly cactus", "🌵", "touch", "skin"),
    ]
    static let senseNames = ["sight", "hearing", "smell", "taste", "touch"]
    static let partNames = ["eyes", "ears", "nose", "tongue", "skin"]

    /// Grown-up animals and their babies.
    static let babies: [(animal: String, picture: String, baby: String)] = [
        ("dog", "🐕", "puppy"), ("cat", "🐈", "kitten"), ("cow", "🐄", "calf"), ("sheep", "🐑", "lamb"), ("horse", "🐎", "foal"),
        ("kangaroo", "🦘", "joey"), ("duck", "🦆", "duckling"), ("bear", "🐻", "cub"), ("deer", "🦌", "fawn"), ("pig", "🐖", "piglet"),
        ("chicken", "🐔", "chick"), ("goat", "🐐", "kid"),
    ]
    /// Other baby names that would also be fair answers, kept out of the wrong choices (baby ducks are called chicks too).
    static let babyAlsoFits: [String: Set<String>] = ["duck": ["chick"]]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "homes", title: "Where Animals Live", symbol: "house.fill", intro: "Every animal has a home that suits it. Where does this one live?", skill: "animal habitats"),
        QuizGameInfo(id: "cycles", title: "Life Cycles", symbol: "arrow.triangle.2.circlepath", intro: "Living things grow and change. What comes next?", skill: "life cycles"),
        QuizGameInfo(id: "senses", title: "Five Senses", symbol: "eye.fill", intro: "We have five senses: sight, hearing, smell, taste and touch. Which one is it?", skill: "the five senses"),
        QuizGameInfo(id: "babies", title: "Baby Animals", symbol: "heart.fill", intro: "Baby animals have their own names! What is this baby called?", skill: "baby animal names"),
    ]

    static let cheers = ["Nature explorer!", "Wild and right!", "That's right!", "You know nature!", "Great spotting!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "homes":
            return Array(homes.shuffled(using: &rng).prefix(count)).enumerated().map { i, a in
                QuizRound(visual: .picture(a.picture), say: "Where does the \(a.animal) live?",
                          choices: QuizShuffle.choices(a.home, habitats.filter { !(alsoFits[a.animal] ?? []).contains($0) }, using: &rng), answer: a.home,
                          cheer: "The \(a.animal) lives in the \(a.home). \(cheer(i))")
            }
        case "cycles":
            // every step of every cycle, then five of them
            var steps: [(cycle: String, shown: [(String, String)], next: String, others: [String])] = []
            for c in cycles {
                for k in 1..<c.stages.count {
                    let names = c.stages.map(\.0)
                    steps.append((c.name, Array(c.stages.prefix(k)), names[k], names.filter { $0 != names[k] && !names.prefix(k).contains($0) } + names.prefix(k).map { $0 }))
                }
            }
            return Array(steps.shuffled(using: &rng).prefix(count)).enumerated().map { i, s in
                let last = s.shown.last!.0
                let wrong = s.others.filter { $0 != s.next }
                return QuizRound(visual: .text(s.shown.map(\.1).joined(separator: " → ") + " → ?"),
                                 say: "A \(s.cycle) grows. After the \(last), what comes next?",
                                 choices: QuizShuffle.choices(s.next, wrong, using: &rng), answer: s.next,
                                 cheer: "After the \(last) comes the \(s.next). \(cheer(i))")
            }
        case "senses":
            return Array(senses.shuffled(using: &rng).prefix(count)).enumerated().map { i, s in
                let askPart = i % 2 == 1
                let answer = askPart ? s.part : s.sense
                return QuizRound(visual: .picture(s.picture),
                                 say: askPart ? "What do you use to \(s.thing)?" : "Which sense do you use to \(s.thing)?",
                                 choices: QuizShuffle.choices(answer, askPart ? partNames : senseNames, using: &rng), answer: answer,
                                 cheer: "You use your \(s.part) to \(s.thing): that's \(s.sense)! \(cheer(i))")
            }
        default: // babies
            return Array(babies.shuffled(using: &rng).prefix(count)).enumerated().map { i, b in
                QuizRound(visual: .picture(b.picture), say: "What is a baby \(b.animal) called?",
                          choices: QuizShuffle.choices(b.baby, babies.map(\.baby).filter { $0 != b.baby && !(babyAlsoFits[b.animal] ?? []).contains($0) }, using: &rng), answer: b.baby,
                          cheer: "A baby \(b.animal) is a \(b.baby). \(cheer(i))")
            }
        }
    }
}

// MARK: - Calendar Corner (v8.3)

enum CalendarBank {
    static let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    static let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    /// Seasons by what you see (not by month, which is different north and south of the equator).
    static let seasonClues: [(picture: String, clue: String, season: String)] = [
        ("⛄🧤", "Snowmen and mittens", "winter"), ("❄️🛷", "Snow and sleds", "winter"),
        ("🌷🐣", "Tulips and baby chicks", "spring"), ("🌧️🌱", "Rain showers and new sprouts", "spring"),
        ("🏖️🍦", "The beach and ice cream", "summer"), ("☀️🏊", "Hot sun and swimming", "summer"),
        ("🍂🍁", "Falling leaves", "fall"), ("🎃🍎", "Pumpkins and apple picking", "fall"),
    ]
    static let seasons = ["winter", "spring", "summer", "fall"]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "days", title: "Days of the Week", symbol: "calendar", intro: "Seven days make a week. What day comes next?", skill: "days of the week in order"),
        QuizGameInfo(id: "yesterday", title: "Yesterday and Tomorrow", symbol: "clock.arrow.circlepath", intro: "Yesterday is the day before today. Tomorrow is the day after.", skill: "yesterday, today and tomorrow"),
        QuizGameInfo(id: "months", title: "Months of the Year", symbol: "calendar.badge.clock", intro: "Twelve months make a year. Which month comes next?", skill: "months of the year in order"),
        QuizGameInfo(id: "seasons", title: "Four Seasons", symbol: "leaf.fill", intro: "Winter, spring, summer and fall. Which season is it?", skill: "the four seasons"),
    ]

    static let cheers = ["Right on time!", "Calendar star!", "That's right!", "Peep peep, perfect!", "You know your days!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "days":
            return Array((0..<7).shuffled(using: &rng).prefix(count)).enumerated().map { i, d in
                let before = i % 2 == 1
                let answer = days[(d + (before ? 6 : 1)) % 7]
                let wrong = [days[(d + (before ? 1 : 6)) % 7], days[(d + (before ? 5 : 2)) % 7], days[d]]
                return QuizRound(visual: .text(days[d]), say: "What day comes \(before ? "before" : "after") \(days[d])?",
                                 choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "\(before ? "\(answer) comes before \(days[d])" : "\(answer) comes after \(days[d])"). \(cheer(i))")
            }
        case "yesterday":
            return Array((0..<7).shuffled(using: &rng).prefix(count)).enumerated().map { i, d in
                let askTomorrow = i % 2 == 0
                let answer = days[(d + (askTomorrow ? 1 : 6)) % 7]
                let wrong = [days[(d + (askTomorrow ? 6 : 1)) % 7], days[d], days[(d + 3) % 7]]
                return QuizRound(visual: .text("Today is \(days[d])"), say: "Today is \(days[d]). What day \(askTomorrow ? "will tomorrow be" : "was yesterday")?",
                                 choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "\(askTomorrow ? "Tomorrow will be" : "Yesterday was") \(answer). \(cheer(i))")
            }
        case "months":
            return Array((0..<12).shuffled(using: &rng).prefix(count)).enumerated().map { i, m in
                let answer = months[(m + 1) % 12]
                let wrong = [months[(m + 11) % 12], months[(m + 2) % 12], months[m]]
                return QuizRound(visual: .text(months[m]), say: "What month comes after \(months[m])?",
                                 choices: QuizShuffle.choices(answer, wrong, using: &rng), answer: answer,
                                 cheer: "\(answer) comes after \(months[m]). \(cheer(i))")
            }
        default: // seasons
            return Array(seasonClues.shuffled(using: &rng).prefix(count)).enumerated().map { i, c in
                QuizRound(visual: .picture(c.picture), say: "\(c.clue). Which season is it?",
                          choices: QuizShuffle.choices(c.season, seasons, using: &rng), answer: c.season,
                          cheer: "\(c.clue) means \(c.season)! \(cheer(i))")
            }
        }
    }
}

// MARK: - Compass Camp (v8.4)

enum CompassBank {
    static let directions = ["north", "east", "south", "west"]
    static let mapThings = ["⛺", "🌲", "🏠", "🐻", "🦊", "🌊", "⛰️", "🍎", "🌸", "🐢", "🦉", "🐰", "🦆", "🐿️", "🐸", "🍄"]
    static let letters = Array("ABCDEFGH").map(String.init)

    static func cellName(_ cell: Int, cols: Int) -> String { "\(letters[cell % cols])\(cell / cols + 1)" }

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "leftRight", title: "Left or Right?", symbol: "arrow.left.arrow.right", intro: "Look along the row. What is just to the left, or just to the right?", skill: "left and right"),
        QuizGameInfo(id: "compass", title: "Compass Rose", symbol: "safari.fill", intro: "North is up, south is down, east is right, west is left. Never Eat Soggy Waffles!", skill: "north, south, east and west"),
        QuizGameInfo(id: "gridFind", title: "Map Spots", symbol: "map.fill", intro: "Find the letter along the top, then the number down the side. What is there?", skill: "reading a grid map"),
        QuizGameInfo(id: "follow", title: "Follow the Path", symbol: "figure.walk", intro: "Start at the flag and follow the steps. Where do you end up?", skill: "following directions"),
    ]

    static let cheers = ["Way to go!", "Great map reading!", "You found it!", "That's right!", "Super scout!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "leftRight":
            return (0..<count).map { i in
                let row = Array(mapThings.shuffled(using: &rng).prefix(4))
                let k = Int.random(in: 1...2, using: &rng)   // a middle one, so both neighbours exist
                let askLeft = i % 2 == 0
                let answer = askLeft ? row[k - 1] : row[k + 1]
                let wrong = row.filter { $0 != answer }
                return QuizRound(visual: .picture(row.joined(separator: " ")),
                                 say: "What is just to the \(askLeft ? "left" : "right") of the \(GridWords.name(row[k]))?",
                                 choices: QuizShuffle.choices(GridWords.name(answer), wrong.map(GridWords.name), using: &rng), answer: GridWords.name(answer),
                                 cheer: "The \(GridWords.name(answer)) is just to the \(askLeft ? "left" : "right"). \(cheer(i))")
            }
        case "compass":
            return (0..<count).map { i in
                let four = Array(mapThings.shuffled(using: &rng).prefix(4))
                let d = Int.random(in: 0..<4, using: &rng)
                let askWhich = i % 2 == 0
                if askWhich {
                    return QuizRound(visual: .compass(north: four[0], east: four[1], south: four[2], west: four[3]),
                                     say: "What is to the \(directions[d])?",
                                     choices: QuizShuffle.choices(GridWords.name(four[d]), four.map(GridWords.name), using: &rng), answer: GridWords.name(four[d]),
                                     cheer: "The \(GridWords.name(four[d])) is to the \(directions[d]). \(cheer(i))")
                }
                return QuizRound(visual: .compass(north: four[0], east: four[1], south: four[2], west: four[3]),
                                 say: "Which way is the \(GridWords.name(four[d]))?",
                                 choices: QuizShuffle.choices(directions[d], directions, using: &rng), answer: directions[d],
                                 cheer: "The \(GridWords.name(four[d])) is to the \(directions[d]). \(cheer(i))")
            }
        case "gridFind":
            return (0..<count).map { i in
                let cols = 4, rows = 4
                let cells = Array((0..<(cols * rows)).shuffled(using: &rng).prefix(5))
                let things = Array(mapThings.shuffled(using: &rng).prefix(5))
                var items: [Int: String] = [:]
                for (c, t) in zip(cells, things) { items[c] = t }
                let askWhat = i % 2 == 0
                let target = cells[0]
                if askWhat {
                    return QuizRound(visual: .gridMap(cols: cols, rows: rows, items: items, marker: nil),
                                     say: "What is at \(cellName(target, cols: cols))?",
                                     choices: QuizShuffle.choices(GridWords.name(items[target]!), things.map(GridWords.name), using: &rng),
                                     answer: GridWords.name(items[target]!), cheer: "The \(GridWords.name(items[target]!)) is at \(cellName(target, cols: cols)). \(cheer(i))")
                }
                let answer = cellName(target, cols: cols)
                let wrong = cells.dropFirst().map { cellName($0, cols: cols) }
                    + ["\(letters[target / cols % cols])\(target % cols + 1)"]   // letter and number swapped
                return QuizRound(visual: .gridMap(cols: cols, rows: rows, items: items, marker: nil),
                                 say: "Where is the \(GridWords.name(items[target]!))?",
                                 choices: QuizShuffle.choices(answer, wrong.filter { $0 != answer }, using: &rng), answer: answer,
                                 cheer: "The \(GridWords.name(items[target]!)) is at \(answer). \(cheer(i))")
            }
        default: // follow
            return (0..<count).map { i in
                let cols = 4, rows = 4
                // pick a start and a short walk that stays on the map
                var start = 0, steps: [(String, Int)] = [], end = 0
                repeat {
                    start = Int.random(in: 0..<(cols * rows), using: &rng)
                    var c = start % cols, r = start / cols
                    var onMap = true
                    steps = []
                    for _ in 0..<2 {
                        let dir = ["up", "down", "left", "right"][Int.random(in: 0..<4, using: &rng)]
                        let n = Int.random(in: 1...2, using: &rng)
                        steps.append((dir, n))
                        switch dir {
                        case "up": r -= n
                        case "down": r += n
                        case "left": c -= n
                        default: c += n
                        }
                        // every step of the walk stays on the map, not just the end
                        if !(c >= 0 && c < cols && r >= 0 && r < rows) { onMap = false }
                    }
                    end = onMap ? r * cols + c : -1
                } while end < 0 || end == start
                var items: [Int: String] = [:]
                let others = Array((0..<(cols * rows)).filter { $0 != start && $0 != end }.shuffled(using: &rng).prefix(3))
                let pics = Array(mapThings.shuffled(using: &rng).prefix(4))
                items[end] = pics[0]
                for (cell, p) in zip(others, pics.dropFirst()) { items[cell] = p }
                let path = steps.map { "\($0.1) \($0.0)" }.joined(separator: ", then ")
                return QuizRound(visual: .gridMap(cols: cols, rows: rows, items: items, marker: start),
                                 say: "Start at the flag. Go \(path). What do you find?",
                                 choices: QuizShuffle.choices(GridWords.name(pics[0]), pics.dropFirst().map(GridWords.name), using: &rng),
                                 answer: GridWords.name(pics[0]), cheer: "You walked to the \(GridWords.name(pics[0]))! \(cheer(i))")
            }
        }
    }
}

// MARK: - Healthy Hut (v9.1)

/// Sir Broccoli's place: what body parts do, food groups, healthy habits, and everyday and sometimes foods.
/// No food is ever called "bad": sometimes foods are treats for once in a while.
enum HealthyBank {
    /// Body parts and their jobs. Each job fits one part only.
    static let parts: [(part: String, picture: String, job: String)] = [
        ("brain", "🧠", "think and remember"), ("heart", "🫀", "pump blood all around the body"),
        ("lungs", "🫁", "breathe air in and out"), ("bones", "🦴", "hold the body up like a frame"),
        ("muscles", "💪", "pull on the bones to move the body"), ("teeth", "🦷", "bite and chew food"),
    ]

    /// Foods with one clear food group (no tomatoes, beans, corn or potatoes, which people sort different ways).
    static let foods: [(food: String, picture: String, group: String)] = [
        ("apple", "🍎", "fruit"), ("banana", "🍌", "fruit"), ("strawberry", "🍓", "fruit"), ("pear", "🍐", "fruit"), ("watermelon", "🍉", "fruit"),
        ("carrot", "🥕", "vegetable"), ("broccoli", "🥦", "vegetable"), ("lettuce", "🥬", "vegetable"), ("onion", "🧅", "vegetable"), ("pepper", "🫑", "vegetable"),
        ("bread", "🍞", "grain"), ("rice", "🍚", "grain"), ("bagel", "🥯", "grain"), ("spaghetti", "🍝", "grain"),
        ("egg", "🥚", "protein"), ("fish", "🐟", "protein"), ("chicken", "🍗", "protein"), ("peanuts", "🥜", "protein"),
        ("milk", "🥛", "dairy"), ("cheese", "🧀", "dairy"),
    ]
    static let groups = ["fruit", "vegetable", "grain", "protein", "dairy"]

    /// Little moments with one healthy choice; the other two are clearly not it (and a bit silly).
    static let habits: [(picture: String, question: String, right: String, wrong: [String], why: String)] = [
        ("🧼", "Before you eat, what should you do?", "Wash your hands", ["Take off your socks", "Spin around three times"], "Clean hands keep germs out of your food."),
        ("🪥", "What keeps your teeth healthy?", "Brush them twice a day", ["Brush them once a year", "Eat candy in bed"], "Brushing morning and night keeps teeth strong."),
        ("🤧", "You need to sneeze. What should you do?", "Sneeze into your elbow", ["Sneeze on a friend", "Sneeze on the food"], "Your elbow catches the germs."),
        ("💧", "You're thirsty after running around. What's the best drink?", "Water", ["Soda pop", "Maple syrup"], "Water is the best drink for a busy body."),
        ("😴", "It's bedtime. What helps your body grow and rest?", "A good night's sleep", ["Staying up all night", "Jumping on the bed all night"], "Your body grows and rests while you sleep."),
        ("⏱️", "How long should you scrub your hands with soap?", "About 20 seconds", ["One second", "One whole hour"], "Twenty seconds of scrubbing washes germs away."),
        ("☀️", "It's a very sunny day. What protects your skin?", "Sunscreen and a hat", ["A bowl of soup", "Nothing at all"], "Sunscreen and a hat stop sunburn."),
        ("🏃", "What makes your heart and muscles strong?", "Running and playing", ["Sitting all day", "Staying in bed all day"], "Moving your body makes it strong."),
    ]

    /// Everyday foods help you grow; sometimes foods are treats for once in a while.
    static let treats: [(food: String, picture: String, everyday: Bool)] = [
        ("apples", "🍎", true), ("bananas", "🍌", true), ("carrots", "🥕", true), ("broccoli", "🥦", true), ("strawberries", "🍓", true),
        ("milk", "🥛", true), ("eggs", "🥚", true), ("grapes", "🍇", true),
        ("cake", "🎂", false), ("candy", "🍬", false), ("lollipops", "🍭", false), ("donuts", "🍩", false), ("cookies", "🍪", false),
        ("ice cream", "🍦", false), ("french fries", "🍟", false), ("cupcakes", "🧁", false),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "body", title: "Body Jobs", symbol: "figure.stand", intro: "Every part of your body has a job. Which part does it?", skill: "body parts and what they do"),
        QuizGameInfo(id: "foods", title: "Food Groups", symbol: "carrot.fill", intro: "Fruits, vegetables, grains, protein and dairy. Which group is it in?", skill: "the food groups"),
        QuizGameInfo(id: "habits", title: "Healthy Habits", symbol: "hands.sparkles.fill", intro: "Healthy habits keep you strong. What's the healthy choice?", skill: "healthy habits"),
        QuizGameInfo(id: "everyday", title: "Everyday or Sometimes?", symbol: "fork.knife", intro: "Everyday foods help you grow. Sometimes foods are treats. Which is it?", skill: "everyday and sometimes foods"),
    ]

    static let cheers = ["Healthy and smart!", "Strong thinking!", "That's right!", "You're a health hero!", "Crunchy good!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "body":
            return Array(parts.shuffled(using: &rng).prefix(count)).enumerated().map { i, p in
                let done = "To \(p.job) is the job of your \(p.part). \(cheer(i))"
                if i % 2 == 0 {
                    return QuizRound(visual: .none, say: "Which part of your body has this job: \(p.job)?",
                                     choices: QuizShuffle.choices(p.part, parts.map(\.part), using: &rng), answer: p.part, cheer: done)
                }
                return QuizRound(visual: .picture(p.picture), say: "What is the job of your \(p.part)?",
                                 choices: QuizShuffle.choices(p.job, parts.map(\.job), using: &rng), answer: p.job, cheer: done)
            }
        case "foods":
            return Array(foods.shuffled(using: &rng).prefix(count)).enumerated().map { i, f in
                QuizRound(visual: .picture(f.picture), say: "Which food group is \(f.food) in?",
                          choices: QuizShuffle.choices(f.group, groups, using: &rng), answer: f.group,
                          cheer: "\(f.food.prefix(1).uppercased() + f.food.dropFirst()) is in the \(f.group) group. \(cheer(i))")
            }
        case "habits":
            return Array(habits.shuffled(using: &rng).prefix(count)).enumerated().map { i, h in
                QuizRound(visual: .picture(h.picture), say: h.question,
                          choices: QuizShuffle.choices(h.right, h.wrong, using: &rng), answer: h.right,
                          cheer: "\(h.why) \(cheer(i))")
            }
        default: // everyday
            return Array(treats.shuffled(using: &rng).prefix(count)).enumerated().map { i, t in
                let answer = t.everyday ? "everyday" : "sometimes"
                let name = t.food.prefix(1).uppercased() + t.food.dropFirst()
                return QuizRound(visual: .picture(t.picture), say: "Is \(t.food) an everyday food or a sometimes food?",
                                 choices: ["everyday", "sometimes"], answer: answer,
                                 cheer: t.everyday ? "\(name): an everyday food that helps you grow! \(cheer(i))"
                                                   : "\(name): a sometimes food, a yummy treat for once in a while! \(cheer(i))")
            }
        }
    }
}

// MARK: - Earth Helpers (v9.2)

/// Coral Turtle's place: sorting into recycling, compost and trash, small choices that help the planet,
/// what things are made of, and what uses electricity.
enum PlanetBank {
    /// Things with one clear bin. (Rules differ from town to town, so only the clearest things are used.)
    static let bins: [(thing: String, picture: String, bin: String)] = [
        ("newspaper", "📰", "recycling"), ("cardboard box", "📦", "recycling"), ("empty can", "🥫", "recycling"), ("glass jar", "🫙", "recycling"),
        ("banana peel", "🍌", "compost"), ("apple core", "🍎", "compost"), ("eggshell", "🥚", "compost"), ("fallen leaf", "🍂", "compost"),
        ("used bandage", "🩹", "trash"), ("candy wrapper", "🍬", "trash"), ("popped balloon", "🎈", "trash"),
    ]
    static let binNames = ["recycling", "compost", "trash"]

    /// Small choices: one helps the planet, the other two clearly don't.
    static let moments: [(picture: String, question: String, right: String, wrong: [String], why: String)] = [
        ("🪥", "You're brushing your teeth. Which choice saves water?", "Turn off the tap while you brush", ["Let the water run the whole time", "Fill the sink to the top first"], "Turning off the tap saves lots of water."),
        ("💡", "You're leaving your room. Which choice saves energy?", "Turn off the light", ["Leave every light on", "Turn on the TV too"], "Lights off saves energy."),
        ("🛒", "You're going to the store. Which choice makes less trash?", "Bring a cloth bag from home", ["Get a new plastic bag for each thing", "Ask for extra bags"], "A bag you use again and again makes less trash."),
        ("🧺", "Your picnic in the park is done. What do you do with the wrappers?", "Put them in a bin", ["Leave them on the grass", "Hide them under a bush"], "Litter in a bin keeps parks clean for animals and people."),
        ("🧸", "Some of your toys still work, but you're too big for them. What could you do?", "Give them to someone who can use them", ["Throw them in the trash", "Bury them in the yard"], "Giving toys away means they get played with again."),
        ("🥤", "What's the best way to bring a drink to school?", "A bottle you can refill", ["A new plastic bottle every day", "Two new juice boxes every day"], "A bottle you refill makes less trash."),
        ("📄", "You drew on one side of a piece of paper. What could you do?", "Draw on the other side too", ["Throw it away right now", "Rip it into tiny bits for fun"], "Using both sides saves paper, and paper comes from trees."),
    ]

    /// What things are made of. Each thing is clearly one material.
    static let made: [(thing: String, picture: String, material: String)] = [
        ("newspaper", "📰", "paper"), ("cardboard box", "📦", "paper"), ("envelope", "✉️", "paper"),
        ("can", "🥫", "metal"), ("key", "🔑", "metal"), ("bell", "🔔", "metal"), ("coin", "🪙", "metal"),
        ("jar", "🫙", "glass"), ("window", "🪟", "glass"), ("mirror", "🪞", "glass"),
        ("log", "🪵", "wood"), ("violin", "🎻", "wood"),
        ("toothbrush", "🪥", "plastic"), ("lotion bottle", "🧴", "plastic"),
    ]
    static let materials = ["paper", "metal", "glass", "wood", "plastic"]

    /// Things that use electricity, and things that don't.
    static let electric: [(thing: String, picture: String)] = [
        ("light bulb", "💡"), ("TV", "📺"), ("laptop", "💻"), ("flashlight", "🔦"), ("phone", "📱"),
    ]
    static let unplugged: [(thing: String, picture: String)] = [
        ("book", "📖"), ("ball", "⚽"), ("bike", "🚲"), ("kite", "🪁"), ("teddy bear", "🧸"), ("crayon", "🖍️"), ("drum", "🥁"),
    ]

    static let games: [QuizGameInfo] = [
        QuizGameInfo(id: "bins", title: "Which Bin?", symbol: "arrow.3.trianglepath", intro: "Paper, cans and jars go in recycling. Food scraps go in compost. The rest goes in the trash.", skill: "sorting recycling, compost and trash"),
        QuizGameInfo(id: "choices", title: "Planet Choices", symbol: "leaf.fill", intro: "Small choices help our planet. Which one helps?", skill: "saving water, energy and trash"),
        QuizGameInfo(id: "made", title: "What's It Made Of?", symbol: "cube.transparent", intro: "Things are made of paper, metal, glass, wood or plastic. Which one is it?", skill: "materials"),
        QuizGameInfo(id: "power", title: "Power Off", symbol: "bolt.fill", intro: "Some things need electricity. Turn them off when you're done to save energy!", skill: "what uses electricity"),
    ]

    static let cheers = ["Earth helper!", "Shell-ebrate!", "That's right!", "The planet says thanks!", "Green and clean!"]

    static func rounds<G: RandomNumberGenerator>(for id: String, count: Int = 5, using rng: inout G) -> [QuizRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        switch id {
        case "bins":
            return Array(bins.shuffled(using: &rng).prefix(count)).enumerated().map { i, b in
                QuizRound(visual: .picture(b.picture), say: "Which bin does the \(b.thing) go in?",
                          choices: binNames.shuffled(using: &rng), answer: b.bin,
                          cheer: "The \(b.thing) goes in the \(b.bin). \(cheer(i))")
            }
        case "choices":
            return Array(moments.shuffled(using: &rng).prefix(count)).enumerated().map { i, c in
                QuizRound(visual: .picture(c.picture), say: c.question,
                          choices: QuizShuffle.choices(c.right, c.wrong, using: &rng), answer: c.right,
                          cheer: "\(c.why) \(cheer(i))")
            }
        case "made":
            return Array(made.shuffled(using: &rng).prefix(count)).enumerated().map { i, m in
                QuizRound(visual: .picture(m.picture), say: "What is the \(m.thing) made of?",
                          choices: QuizShuffle.choices(m.material, materials, using: &rng), answer: m.material,
                          cheer: "The \(m.thing) is made of \(m.material). \(cheer(i))")
            }
        default: // power
            let plugged = electric.shuffled(using: &rng)
            return (0..<count).map { i in
                let on = plugged[i % plugged.count]
                let off = Array(unplugged.shuffled(using: &rng).prefix(2))
                let three = ([on] + off).shuffled(using: &rng)
                let names = three.map(\.thing)
                return QuizRound(visual: .picture(three.map(\.picture).joined(separator: " ")),
                                 say: "Which one uses electricity: the \(names[0]), the \(names[1]) or the \(names[2])?",
                                 choices: names, answer: on.thing,
                                 cheer: "The \(on.thing) uses electricity. Turn it off when you're done! \(cheer(i))")
            }
        }
    }
}
