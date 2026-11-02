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
        ("taste a lemon", "🍋", "taste", "tongue"), ("feel a soft blanket", "🧸", "touch", "skin"), ("see the stars", "🌟", "sight", "eyes"),
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
                          choices: QuizShuffle.choices(a.home, habitats, using: &rng), answer: a.home,
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
                          choices: QuizShuffle.choices(b.baby, babies.map(\.baby).filter { $0 != b.baby }, using: &rng), answer: b.baby,
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
        ("🌷🐣", "Tulips and baby chicks", "spring"), ("🌧️🌱", "Spring rain and new sprouts", "spring"),
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
