import Foundation

// A living Hop Village: the season follows the calendar, the weather changes each day (the same for everyone,
// worked out from the date, with no network), a different festival decorates the square each week, and your
// own house sits on the hill to decorate. Nothing here punishes being away: no streaks, nothing to miss.
// Every festival can be celebrated any time from the notice board, and its reward is given once, ever.

enum Season: String, CaseIterable, Codable {
    case spring, summer, autumn, winter

    /// Northern-hemisphere months (the device date decides).
    static func of(month: Int) -> Season {
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .autumn: return "🍂"
        case .winter: return "❄️"
        }
    }

    /// A one-line fact about the season.
    var fact: String {
        switch self {
        case .spring: return "In spring, days get longer and seeds wake up and sprout."
        case .summer: return "Summer has the longest days of the year. Remember a hat and water!"
        case .autumn: return "In autumn, leaves change color because trees stop making green chlorophyll."
        case .winter: return "In winter, some animals hibernate: a long, deep sleep until spring."
        }
    }

    /// The two festivals that take turns in this season.
    var festivals: [Festival] {
        switch self {
        case .spring: return [.kite, .science]
        case .summer: return [.splash, .music]
        case .autumn: return [.harvest, .lantern]
        case .winter: return [.snow, .lantern]
        }
    }
}

enum Weather: String, CaseIterable, Codable {
    case sunny, cloudy, rainy, windy, snowy

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .windy: return "🌬️"
        case .snowy: return "🌨️"
        }
    }

    /// Today's weather. The same date always gives the same weather, and snow only falls in winter.
    static func on(year: Int, month: Int, day: Int) -> Weather {
        var rng = VillageRandom(seed: UInt64(year * 10_000 + month * 100 + day))
        let roll = rng.unit()
        switch Season.of(month: month) {
        case .winter: return roll < 0.4 ? .snowy : roll < 0.7 ? .cloudy : .sunny
        case .spring: return roll < 0.4 ? .sunny : roll < 0.6 ? .rainy : roll < 0.8 ? .cloudy : .windy
        case .summer: return roll < 0.65 ? .sunny : roll < 0.8 ? .cloudy : roll < 0.9 ? .rainy : .windy
        case .autumn: return roll < 0.3 ? .sunny : roll < 0.55 ? .windy : roll < 0.8 ? .rainy : .cloudy
        }
    }

    /// What a villager might say about it (real science, kid-sized).
    var lines: [String] {
        switch self {
        case .sunny: return ["Sunny days are great for playing outside. A hat and sunscreen keep you safe from sunburn!",
                             "Sunlight helps plants make their food. That's called photosynthesis!"]
        case .cloudy: return ["Clouds are made of billions of tiny water drops floating in the air.",
                              "Fluffy clouds are called cumulus. They look like cotton balls!"]
        case .rainy: return ["Rain is part of the water cycle: water goes up as vapor, makes clouds, then falls back down.",
                             "After rain, look for a rainbow! Sunlight shining through raindrops splits into colors."]
        case .windy: return ["Wind is air on the move. You can't see it, but you can see it push the leaves!",
                             "Windy days are perfect for kites. Wind pushes up on the kite and keeps it flying."]
        case .snowy: return ["Every snowflake has six sides, and no two are exactly the same!",
                             "Water freezes into ice at 0 degrees Celsius. That's 32 degrees Fahrenheit."]
        }
    }
}

enum Festival: String, CaseIterable, Codable {
    case kite, science, splash, music, harvest, lantern, snow

    var title: String {
        switch self {
        case .kite: return "Kite Festival"
        case .science: return "Science Fair"
        case .splash: return "Splash Day"
        case .music: return "Music in the Square"
        case .harvest: return "Harvest Fair"
        case .lantern: return "Lantern Night"
        case .snow: return "Snow Day"
        }
    }

    var icon: String {
        switch self {
        case .kite: return "🪁"
        case .science: return "🔬"
        case .splash: return "🐚"
        case .music: return "🎵"
        case .harvest: return "🎃"
        case .lantern: return "🏮"
        case .snow: return "⛄"
        }
    }

    /// The decoration this festival adds to your house, once you've celebrated it.
    var houseReward: HomeExtra {
        switch self {
        case .kite: return .kite
        case .science: return .telescope
        case .splash: return .shells
        case .music: return .chimes
        case .harvest: return .pumpkin
        case .lantern: return .lanterns
        case .snow: return .snowman
        }
    }

    var missionID: String { "fest_\(rawValue)" }

    /// The festival decorating the square this week. Two festivals per season take turns.
    static func ofWeek(_ weekOfYear: Int, season: Season) -> Festival {
        let options = season.festivals
        return options[abs(weekOfYear) % options.count]
    }
}

/// Today in Hop Village, worked out from a date.
struct VillageDay: Equatable {
    let season: Season
    let weather: Weather
    /// This week's festival (before the child picks another one on the notice board).
    let weekFestival: Festival

    init(season: Season, weather: Weather, weekFestival: Festival) {
        self.season = season
        self.weather = weather
        self.weekFestival = weekFestival
    }

    init(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        let c = calendar.dateComponents([.year, .month, .day, .weekOfYear], from: date)
        let season = Season.of(month: c.month ?? 1)
        self.season = season
        weather = Weather.on(year: c.year ?? 2026, month: c.month ?? 1, day: c.day ?? 1)
        weekFestival = Festival.ofWeek(c.weekOfYear ?? 1, season: season)
    }

    /// The festival being celebrated: the child's pick from the notice board, or this week's.
    func festival(picked: String?) -> Festival {
        picked.flatMap(Festival.init(rawValue:)) ?? weekFestival
    }
}

// MARK: - Your house

/// Decorations for the house. The first four are there from the start; the rest come from festivals.
enum HomeExtra: String, CaseIterable, Codable {
    case flowerBox, mailbox, flag, lamp
    case kite, telescope, shells, chimes, pumpkin, lanterns, snowman

    var title: String {
        switch self {
        case .flowerBox: return "Flower box"
        case .mailbox: return "Mailbox"
        case .flag: return "Flag"
        case .lamp: return "Lamp"
        case .kite: return "Kite"
        case .telescope: return "Telescope"
        case .shells: return "Shell chime"
        case .chimes: return "Wind chimes"
        case .pumpkin: return "Pumpkins"
        case .lanterns: return "Lanterns"
        case .snowman: return "Snowman"
        }
    }

    var icon: String {
        switch self {
        case .flowerBox: return "🌷"
        case .mailbox: return "📫"
        case .flag: return "🚩"
        case .lamp: return "💡"
        case .kite: return "🪁"
        case .telescope: return "🔭"
        case .shells: return "🐚"
        case .chimes: return "🎐"
        case .pumpkin: return "🎃"
        case .lanterns: return "🏮"
        case .snowman: return "⛄"
        }
    }

    var art: String { "home_extra_\(rawValue)" }

    /// The festival that gives it (nil = available from the start).
    var festival: Festival? { Festival.allCases.first { $0.houseReward == self } }
}

struct HomeStyle: Codable, Equatable {
    static let wallColors = ["Cream", "Pink", "Mint", "Sky"]
    static let roofColors = ["Red", "Blue", "Purple", "Green"]
    static let doorColors = ["Wood", "Red", "Yellow", "Blue"]

    var wall = 0
    var roof = 0
    var door = 0
    var extras: Set<HomeExtra> = [.flowerBox]

    init() {}

    enum CodingKeys: String, CodingKey { case wall, roof, door, extras }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wall = Self.clamp((try? c.decodeIfPresent(Int.self, forKey: .wall)) ?? 0, Self.wallColors.count)
        roof = Self.clamp((try? c.decodeIfPresent(Int.self, forKey: .roof)) ?? 0, Self.roofColors.count)
        door = Self.clamp((try? c.decodeIfPresent(Int.self, forKey: .door)) ?? 0, Self.doorColors.count)
        // unknown decorations from a future version are skipped instead of failing the whole save
        let raw = (try? c.decodeIfPresent([String].self, forKey: .extras)) ?? [HomeExtra.flowerBox.rawValue]
        extras = Set(raw.compactMap(HomeExtra.init(rawValue:)))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(wall, forKey: .wall)
        try c.encode(roof, forKey: .roof)
        try c.encode(door, forKey: .door)
        try c.encode(extras.map(\.rawValue).sorted(), forKey: .extras)
    }

    private static func clamp(_ v: Int, _ n: Int) -> Int { min(max(v, 0), n - 1) }

    /// Art layers, back to front.
    var layers: [String] {
        ["home_wall_\(wall)", "home_roof_\(roof)", "home_door_\(door)"]
            + HomeExtra.allCases.filter { extras.contains($0) }.map(\.art)
    }

    /// Decorations the child may use: the starters plus those from festivals they've celebrated.
    static func unlocked(missionsDone: Set<String>) -> [HomeExtra] {
        HomeExtra.allCases.filter { e in e.festival.map { missionsDone.contains($0.missionID) } ?? true }
    }
}

// MARK: - Festival missions

enum FestivalMissions {
    /// The villager who hosts every festival in the square.
    static let hostID = "gemma"

    static let all: [MissionDef] = [
        MissionDef(id: Festival.kite.missionID, giver: hostID, title: "Kite Festival", icon: "🪁",
                   intro: "Welcome to the Kite Festival! The wind blew five kite tails all over the village. Can you find them?",
                   lesson: "Kites fly because moving air (wind) pushes up on them. The tail keeps the kite steady, like a rudder on a boat.",
                   steps: [.collect(item: "kite", spots: [GridPoint(8, 10), GridPoint(25, 11), GridPoint(38, 13), GridPoint(10, 29), GridPoint(30, 37)],
                                    hint: "Find 5 kite tails")],
                   thanks: "Every tail is back! Look at those kites fly. A kite for your house!", reward: 2),
        MissionDef(id: Festival.science.missionID, giver: hostID, title: "Science Fair", icon: "🔬",
                   intro: "It's the Science Fair! Three friends have experiments to show you: Iron Acorn, Stella and Pip. Go see them all!",
                   lesson: "Scientists ask a question, make a guess, test it, and look at what happens. That's the scientific method!",
                   steps: [
                    .talk(npcID: "acorn", line: "My experiment: magnets pull on iron, but not on wood or plastic. Try it at home with a fridge magnet!", hint: "See Iron Acorn's magnets"),
                    .talk(npcID: "stella", line: "My experiment: the Moon doesn't make light. It shines because sunlight bounces off it!", hint: "See Stella's Moon model"),
                    .talk(npcID: "pip", line: "My experiment: penguins huddle together to stay warm. Sharing warmth works!", hint: "See Pip's penguin huddle"),
                   ],
                   thanks: "You saw every experiment, scientist! Here's a telescope for your house.", reward: 2),
        MissionDef(id: Festival.splash.missionID, giver: hostID, title: "Splash Day", icon: "🐚",
                   intro: "Splash Day at the pond! Four pretty shells washed up on the shore. Can you collect them?",
                   lesson: "Shells are the hard homes of sea animals like snails and clams. When they move out, the empty shells wash up on the shore.",
                   steps: [.collect(item: "shell", spots: [GridPoint(17, 45), GridPoint(17, 50), GridPoint(11, 50), GridPoint(30, 43)],
                                    hint: "Collect 4 shells by the pond")],
                   thanks: "What a shiny collection! Here's a shell chime for your house.", reward: 2),
        MissionDef(id: Festival.music.missionID, giver: hostID, title: "Music in the Square", icon: "🎵",
                   intro: "Tonight is Music in the Square! Can you ask Buzzy, Fizz and Polly to join the band?",
                   lesson: "Sound is a wiggle in the air called a vibration. Fast wiggles make high notes, slow wiggles make low notes.",
                   steps: [
                    .talk(npcID: "buzzy", line: "Bzzz! My wings beat so fast they hum. I'll play the high notes!", hint: "Invite Buzzy"),
                    .talk(npcID: "fizz", line: "Ribbit! Frogs puff up a throat pouch to croak loud. I'll do the bass!", hint: "Invite Fizz"),
                    .talk(npcID: "polly", line: "I'll keep the beat! Clap, clap, tap. Music has patterns, just like math!", hint: "Invite Polly"),
                   ],
                   thanks: "The band is ready! Here are wind chimes for your house.", reward: 2),
        MissionDef(id: Festival.harvest.missionID, giver: hostID, title: "Harvest Fair", icon: "🎃",
                   intro: "It's the Harvest Fair! Four pumpkins rolled away from the patch. Can you bring them back?",
                   lesson: "A pumpkin grows from one small seed. It needs sun, water and lots of time. Inside every pumpkin are seeds for next year!",
                   steps: [.collect(item: "pumpkin", spots: [GridPoint(3, 12), GridPoint(40, 15), GridPoint(24, 30), GridPoint(19, 38)],
                                    hint: "Find 4 pumpkins")],
                   thanks: "The pumpkin patch is full again! Here's a pumpkin for your house.", reward: 2),
        MissionDef(id: Festival.lantern.missionID, giver: hostID, title: "Lantern Night", icon: "🏮",
                   intro: "Lantern Night! Can you light the five lanterns around the Village Square?",
                   lesson: "A lantern glows because a light inside shines through thin paper. The paper spreads the light so it looks soft.",
                   steps: [.collect(item: "lantern", spots: [GridPoint(17, 15), GridPoint(26, 15), GridPoint(16, 24), GridPoint(27, 24), GridPoint(21, 27)],
                                    hint: "Light 5 lanterns in the square")],
                   thanks: "The square is glowing! Here are lanterns for your house.", reward: 2),
        MissionDef(id: Festival.snow.missionID, giver: hostID, title: "Snow Day", icon: "⛄",
                   intro: "Snow Day! Let's build a snowman. Can you find three big snowballs?",
                   lesson: "Snow is frozen water. It melts when it gets warmer than 0 degrees Celsius, which is 32 degrees Fahrenheit.",
                   steps: [
                    .collect(item: "snowball", spots: [GridPoint(14, 15), GridPoint(29, 17), GridPoint(18, 27)], hint: "Find 3 snowballs"),
                    .talk(npcID: hostID, line: "Big one on the bottom, medium in the middle, small on top. Our snowman is finished!", hint: "Bring the snowballs to Gemma"),
                   ],
                   thanks: "What a great snowman! Here's one for your house.", reward: 2),
    ]

    static func mission(for f: Festival) -> MissionDef? { all.first { $0.id == f.missionID } }
}

// MARK: - Villager stories

/// Extra things villagers say, depending on the season and the weather.
enum VillageStories {
    private static let seasonal: [String: [Season: String]] = [
        "ollie": [.spring: "In spring the stars of Leo the Lion shine at night. Can you spot a lion in the sky?",
                  .summer: "Summer nights are short, so I stargaze extra late. Hoo!",
                  .autumn: "In autumn, many birds fly south to warmer places. That trip is called migration.",
                  .winter: "Winter nights are long, perfect for stargazing. Orion the Hunter is easy to find!"],
        "pixelpup": [.spring: "Spring rain makes roads slippery. Cars need more space to stop!",
                     .summer: "In summer, lots of kids ride bikes. Helmets on, every time!",
                     .autumn: "When it gets dark early, wear something bright so cars can see you.",
                     .winter: "Icy sidewalks are slippery. Take small steps like a penguin!"],
        "acorn": [.spring: "Spring is building season! My robot is planting seeds in straight rows.",
                  .summer: "Robots get hot in the sun too. Engineers add fans to keep them cool.",
                  .autumn: "Acorns fall in autumn. Squirrels bury them, and some grow into new oak trees!",
                  .winter: "Batteries don't like the cold. That's why phones run out faster in winter!"],
        "pip": [.spring: "Tadpoles are hatching in the pond! Soon they'll grow legs.",
                .summer: "Penguins live where it's cold, so summer is my splashing time!",
                .autumn: "The pond gets chilly in autumn. Frogs get ready to sleep in the mud.",
                .winter: "Emperor penguins keep their eggs warm on their feet all winter long!"],
        "stella": [.spring: "Spring is a great time to read outside under a tree.",
                   .summer: "My summer reading list is SO long. Want to start a book club?",
                   .autumn: "Autumn starts with A. So do apple, acorn and adventure!",
                   .winter: "Hot cocoa and a good book: my favorite winter day."],
        "ocho": [.spring: "New season, new code! Try making a spring-colored web page in the Coding Lab.",
                 .summer: "Real coders take breaks too. Go play outside, then come back and code!",
                 .autumn: "Leaves fall in a loop: grow, change, fall, repeat. Nature loves loops!",
                 .winter: "Snowflakes follow a pattern with six sides. Patterns are what coders love!"],
        "kip": [.spring: "Spring is a good time to say hi to a new friend.",
                .summer: "Sharing your water on a hot day is a kind thing to do.",
                .autumn: "Helping rake leaves for a neighbor is extra kind. And fun to jump in!",
                .winter: "When it's cold outside, a warm smile helps a lot."],
        "fizz": [.spring: "Ribbit! Spring is when frogs sing the loudest, looking for friends.",
                 .summer: "Summer bugs are tasty. Well, for frogs!",
                 .autumn: "Frogs eat extra in autumn to get ready for their long winter sleep.",
                 .winter: "Some frogs can freeze in winter and wake up in spring. Amazing!"],
        "flora": [.spring: "My favorite season! Bees and butterflies carry pollen so flowers can make seeds.",
                  .summer: "Flowers drink a lot in summer. Morning is the best time to water them.",
                  .autumn: "Many flowers make seeds in autumn, ready for next spring.",
                  .winter: "Bulbs sleep under the snow and pop up in spring."],
        "polly": [.spring: "Spring has 3 months: March, April and May. Can you count the days?",
                  .summer: "Summer days are long! In June, the Sun can be up for about 15 hours.",
                  .autumn: "A year has 4 seasons and 12 months. That's 3 months each!",
                  .winter: "Look at a snowflake: it has 6 points. 6 is my favorite number!"],
        "buzzy": [.spring: "Spring is our busiest time. Flowers, flowers, flowers!",
                  .summer: "Bees fan their wings to keep the hive cool in summer.",
                  .autumn: "In autumn, bees store honey so they have food all winter.",
                  .winter: "Bees huddle in a ball in winter and wiggle to stay warm!"],
        FestivalMissions.hostID: [.spring: "Spring festivals bring everyone together. Fly a kite with us!",
                                  .summer: "Summer evenings are made for music in the square!",
                                  .autumn: "Harvest time! We celebrate the food that grew all year.",
                                  .winter: "Even on cold days, a festival warms up the whole village."],
    ]

    /// Something to say about the season or the weather. `turn` rotates between them.
    static func line(npc: String, day: VillageDay, turn: Int) -> String {
        let weatherLines = day.weather.lines
        // every other turn is a weather line, and those take turns too (so each one gets heard)
        let options = [seasonal[npc]?[day.season], weatherLines[(abs(turn) / 2) % weatherLines.count]].compactMap { $0 }
        return options[abs(turn) % options.count]
    }

    /// Ids with seasonal lines (for tests).
    static var npcIDs: [String] { Array(seasonal.keys) }
}
