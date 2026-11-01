import Foundation

// Story Maker (v6.1): kids build a three-page picture story by picking a place, a buddy, what happens and a thing,
// then the story is read back to them. Choices only, no typing, so it stays kid-safe. Plain Swift, tested in Tests/Learn.

/// One thing that can happen on a page. `{thing}` is filled in with the page's thing.
struct StoryAction: Equatable {
    let id: String
    let text: String
    let symbol: String
}

struct StoryThing: Equatable {
    let id: String
    let name: String
    let emoji: String
}

/// One page of a made-up story.
struct MadePage: Codable, Equatable {
    var place: StoryPlace
    var heroID: String
    var heroName: String
    var heroEmoji: String
    var action: String
    var thing: String
}

struct MadeStory: Codable, Equatable, Identifiable {
    var id: String
    var pages: [MadePage]
    var made: Date

    var title: String { StoryMakerBank.title(for: pages) }
}

enum StoryMakerBank {
    static let pageCount = 3
    static let maxSaved = 6

    static let places: [StoryPlace] = [.meadow, .beach, .snow, .jungle, .sky, .ocean, .castle, .city, .river]

    static func placeName(_ p: StoryPlace) -> String {
        switch p {
        case .meadow: return "the meadow"
        case .road: return "the road"
        case .lab: return "the robot lab"
        case .river: return "the river"
        case .city: return "the city"
        case .castle: return "the castle"
        case .sky: return "the clouds"
        case .snow: return "the snowy mountains"
        case .beach: return "the beach"
        case .jungle: return "the jungle"
        case .ocean: return "the bottom of the sea"
        }
    }

    static let actions: [StoryAction] = [
        StoryAction(id: "found", text: "found {thing}", symbol: "magnifyingglass"),
        StoryAction(id: "shared", text: "shared {thing} with a friend", symbol: "hands.sparkles.fill"),
        StoryAction(id: "built", text: "built {thing} out of blocks", symbol: "hammer.fill"),
        StoryAction(id: "lost", text: "lost {thing}, then found it again", symbol: "questionmark.circle.fill"),
        StoryAction(id: "danced", text: "danced with {thing}", symbol: "music.note"),
        StoryAction(id: "painted", text: "painted a picture of {thing}", symbol: "paintbrush.fill"),
        StoryAction(id: "flew", text: "flew up high holding {thing}", symbol: "cloud.fill"),
        StoryAction(id: "gave", text: "gave {thing} to someone who needed it", symbol: "gift.fill"),
    ]

    static let things: [StoryThing] = [
        StoryThing(id: "map", name: "a treasure map", emoji: "🗺️"), StoryThing(id: "kite", name: "a kite", emoji: "🪁"),
        StoryThing(id: "balloon", name: "a red balloon", emoji: "🎈"), StoryThing(id: "shell", name: "a shiny shell", emoji: "🐚"),
        StoryThing(id: "cake", name: "a birthday cake", emoji: "🎂"), StoryThing(id: "star", name: "a falling star", emoji: "🌟"),
        StoryThing(id: "robot", name: "a tiny robot", emoji: "🤖"), StoryThing(id: "book", name: "a magic book", emoji: "📘"),
        StoryThing(id: "egg", name: "a mystery egg", emoji: "🥚"), StoryThing(id: "crown", name: "a golden crown", emoji: "👑"),
    ]

    /// How each page starts, so the story flows: first, then, finally.
    static let openers = ["One day,", "Then", "At last,"]

    static func sentence(_ page: MadePage, index: Int) -> String {
        let thing = things.first { $0.id == page.thing }?.name ?? "something"
        let act = (actions.first { $0.id == page.action }?.text ?? "found {thing}").replacingOccurrences(of: "{thing}", with: thing)
        let opener = openers[min(index, openers.count - 1)]
        let first = page.heroName.split(separator: " ").first.map(String.init) ?? page.heroName
        if index == 0 {
            return "\(opener) \(page.heroName) went to \(placeName(page.place)) and \(act)."
        }
        return "\(opener) at \(placeName(page.place)), \(first) \(act)."
    }

    static func title(for pages: [MadePage]) -> String {
        guard let first = pages.first else { return "My Story" }
        let name = first.heroName.split(separator: " ").first.map(String.init) ?? first.heroName
        let thing = things.first { $0.id == (pages.last ?? first).thing }?.name ?? "something"
        let bare = thing.split(separator: " ").dropFirst().joined(separator: " ")
        return "\(name) and the \(bare.isEmpty ? thing : bare.capitalized)"
    }

    /// Every page has all its picks (the place and hero carry over from the page before).
    static func isComplete(_ pages: [MadePage]) -> Bool {
        pages.count == pageCount && pages.allSatisfy { !$0.action.isEmpty && !$0.thing.isEmpty && !$0.heroID.isEmpty }
    }
}

/// Saved stories (newest first, at most six) and the stars given for the first three.
struct StoryMakerSave: Codable, Equatable {
    var stories: [MadeStory] = []
    var made: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stories = (try? c.decodeIfPresent([MadeStory].self, forKey: .stories)) ?? []
        made = (try? c.decodeIfPresent(Int.self, forKey: .made)) ?? 0
    }

    /// Saves a story. Returns the stars given (1 for each of the first three stories, then none).
    mutating func save(_ s: MadeStory) -> Int {
        guard StoryMakerBank.isComplete(s.pages) else { return 0 }
        stories.removeAll { $0.id == s.id }
        stories.insert(s, at: 0)
        if stories.count > StoryMakerBank.maxSaved { stories = Array(stories.prefix(StoryMakerBank.maxSaved)) }
        made += 1
        return made <= 3 ? 1 : 0
    }

    mutating func delete(_ id: String) { stories.removeAll { $0.id == id } }
}
