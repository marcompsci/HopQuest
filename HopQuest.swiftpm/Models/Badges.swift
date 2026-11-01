import Foundation

// The Badges wall (v6.3): badges for real learning and exploring, worked out from the save.
// No streaks, no daily rewards, nothing that can be lost: once earned, a badge stays. Plain Swift, tested in Tests/Learn.

struct BadgeInput: Equatable {
    var lifetimeStars = 0
    /// Learning areas finished (every game at 2+ stars), by area id ("reading", "clock"…).
    var finishedAreas: Set<String> = []
    var postcards = 0
    var lettersWritten = 0
    var storiesMade = 0
    var chaptersDone: Set<Int> = []
    var biggestIsland = 0
    var dashFinished = false
    var codePuzzles = 0
    var stickers = 0
    /// Star Hop levels finished on the home-screen widget.
    var hopLevels = 0
}

struct Badge: Equatable, Identifiable {
    let id: String
    let title: String
    /// How to earn it, in kid words.
    let how: String
    let symbol: String
    let colorHex: UInt32
    let earned: (BadgeInput) -> Bool

    static func == (a: Badge, b: Badge) -> Bool { a.id == b.id }
}

enum Badges {
    static let areaBadges: [(String, String, String, UInt32)] = [
        ("reading", "Bookworm", "book.fill", 0xC2364A), ("writing", "Neat Writer", "pencil.line", 0x2F6FD1),
        ("market", "Money Smart", "centsign.circle.fill", 0xD06A00), ("clock", "Time Keeper", "clock.fill", 0x2E7D4F),
        ("science", "Scientist", "flask.fill", 0x1F7A8C), ("world", "Map Reader", "map.fill", 0x5B4BC4),
        ("music", "Musician", "music.note", 0xB0459C), ("spelling", "Spelling Champ", "textformat.abc", 0xB7791F),
        ("fractions", "Fair Sharer", "chart.pie.fill", 0xC2185B), ("shapes", "Shape Spotter", "square.on.circle", 0x00796B),
        ("code", "Coder", "chevron.left.forwardslash.chevron.right", 0x3A2E6E),
    ]

    static let all: [Badge] = {
        var out: [Badge] = [
            Badge(id: "firstHop", title: "First Hop", how: "Finish your first adventure.", symbol: "figure.walk", colorHex: 0x34C77B) { !$0.chaptersDone.isEmpty },
            Badge(id: "explorer", title: "World Explorer", how: "Finish all six story worlds, down to the Coral Castle.", symbol: "globe.americas.fill", colorHex: 0x1E88A8) { $0.chaptersDone.contains(21) },
            Badge(id: "stars50", title: "Star Catcher", how: "Earn 50 stars.", symbol: "star.fill", colorHex: 0xE0A800) { $0.lifetimeStars >= 50 },
            Badge(id: "stars150", title: "Star Gazer", how: "Earn 150 stars.", symbol: "star.circle.fill", colorHex: 0xE0A800) { $0.lifetimeStars >= 150 },
            Badge(id: "stars300", title: "Superstar", how: "Earn 300 stars.", symbol: "sparkles", colorHex: 0xE0A800) { $0.lifetimeStars >= 300 },
            Badge(id: "postcards", title: "Globetrotter", how: "Collect postcards from all 7 continents.", symbol: "envelope.open.fill", colorHex: 0x5B4BC4) { $0.postcards >= 7 },
            Badge(id: "letters", title: "Alphabet Ace", how: "Trace every letter and number at the Writing Desk.", symbol: "a.circle.fill", colorHex: 0x2F6FD1) { $0.lettersWritten >= 62 },
            Badge(id: "storyteller", title: "Storyteller", how: "Make 3 stories in Story Maker.", symbol: "book.pages.fill", colorHex: 0x6A4C93) { $0.storiesMade >= 3 },
            Badge(id: "builder", title: "Master Builder", how: "Build 40 pieces on one of your islands.", symbol: "hammer.fill", colorHex: 0xFF9F45) { $0.biggestIsland >= 40 },
            Badge(id: "dash", title: "Quick Feet", how: "Reach the flag in Star Dash.", symbol: "hare.fill", colorHex: 0x4D7CFF) { $0.dashFinished },
            Badge(id: "puzzler", title: "Robot Whisperer", how: "Solve 10 Code Club puzzles.", symbol: "cpu.fill", colorHex: 0x7C4DFF) { $0.codePuzzles >= 10 },
            Badge(id: "collector", title: "Sticker Collector", how: "Collect 20 buddy stickers.", symbol: "heart.circle.fill", colorHex: 0xFF5A8A) { $0.stickers >= 20 },
            Badge(id: "hopper", title: "Star Hopper", how: "Finish all 12 Star Hop levels on the HopQuest widget.", symbol: "star.square.on.square.fill", colorHex: 0x4B3F8F) { $0.hopLevels >= StarHop.levels.count },
        ]
        for (id, title, symbol, color) in areaBadges {
            out.append(Badge(id: "area-\(id)", title: title, how: "Get 2 stars or more in every game in the \(areaName(id)).",
                             symbol: symbol, colorHex: color) { $0.finishedAreas.contains(id) })
        }
        return out
    }()

    static func areaName(_ id: String) -> String {
        switch id {
        case "reading": return "Reading Nook"
        case "writing": return "Writing Desk"
        case "market": return "Math Market"
        case "clock": return "Clock Tower"
        case "science": return "Science Lab"
        case "world": return "Around the World trip"
        case "music": return "Music Maker"
        case "spelling": return "Spelling Bee"
        case "fractions": return "Fraction Bakery"
        case "shapes": return "Shape Studio"
        default: return "Code Club"
        }
    }

    static func earned(_ input: BadgeInput) -> [Badge] { all.filter { $0.earned(input) } }
}
