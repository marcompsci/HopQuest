import Foundation

// Story cutscenes (v3.9): short picture-book scenes between chapters, read aloud with a voice for each character.
// Shown once when a chapter is finished for the first time (skippable), and replayable from the Story Book.
// Plain Swift, tested in Tests/Learn.

/// Who is talking: each has its own voice (pitch and speed of the built-in iOS voice).
enum StoryVoice: String, Codable, CaseIterable {
    case narrator, buddy, ollie, gemma, ocho, pip, coral

    /// Name shown on the speech bubble ("" for the narrator; the buddy uses the child's buddy name).
    var name: String {
        switch self {
        case .narrator: return ""
        case .buddy: return ""
        case .ollie: return "Ollie Owl"
        case .gemma: return "Gemma Giraffe"
        case .ocho: return "Ocho Octopus"
        case .pip: return "Pip Penguin"
        case .coral: return "Coral Turtle"
        }
    }

    var emoji: String {
        switch self {
        case .narrator: return "📖"
        case .buddy: return "⭐"
        case .ollie: return "🦉"
        case .gemma: return "🦒"
        case .ocho: return "🐙"
        case .pip: return "🐧"
        case .coral: return "🐢"
        }
    }

    /// Voice pitch (0.5...2) and speed compared to the normal narrator.
    var pitch: Float {
        switch self {
        case .narrator: return 1.1
        case .buddy: return 1.45
        case .ollie: return 0.8
        case .gemma: return 1.2
        case .ocho: return 1.0
        case .pip: return 1.6
        case .coral: return 0.9
        }
    }

    var rate: Float {
        switch self {
        case .narrator: return 0.88
        case .buddy: return 0.95
        case .ollie: return 0.8
        case .gemma: return 0.85
        case .ocho: return 0.95
        case .pip: return 1.0
        case .coral: return 0.75
        }
    }
}

/// Where a panel happens (the backdrop colors and ground).
enum StoryPlace: String, Codable, CaseIterable {
    case meadow, road, lab, river, city, castle, sky, snow, beach, jungle

    var skyHex: [UInt32] {
        switch self {
        case .meadow: return [0xBDE7FF, 0xE9F8FF]
        case .road: return [0xA8DBFF, 0xEAF6FF]
        case .lab: return [0x3A2E6E, 0x6C5BC4]
        case .river: return [0x9FE6EA, 0xE4FBFF]
        case .city: return [0xFFD2A8, 0xFFF0DC]
        case .castle: return [0xC9B8FF, 0xFFE3F3]
        case .sky: return [0x7FC8FF, 0xD6F0FF]
        case .snow: return [0xD6ECFF, 0xFFFFFF]
        case .beach: return [0x8FE3F0, 0xFFF4D6]
        case .jungle: return [0x9ED9A0, 0xE6F7D9]
        }
    }

    var groundHex: UInt32 {
        switch self {
        case .meadow, .castle: return 0x7BC950
        case .road, .city: return 0x8C93A6
        case .lab: return 0x9AA6B8
        case .river: return 0x4C9BE0
        case .sky: return 0xFFFFFF
        case .snow: return 0xF4FBFF
        case .beach: return 0xF2D59A
        case .jungle: return 0x2E7D32
        }
    }

    /// Little things in the background.
    var props: [String] {
        switch self {
        case .meadow: return ["🌼", "🌳", "🌷"]
        case .road: return ["🚦", "🚗", "🌳"]
        case .lab: return ["⚙️", "🔧", "💡"]
        case .river: return ["🪷", "🐸", "🌿"]
        case .city: return ["🏢", "🏁", "🚕"]
        case .castle: return ["🏰", "🚩", "🌈"]
        case .sky: return ["☁️", "🎈", "☁️"]
        case .snow: return ["🏔️", "❄️", "⛄"]
        case .beach: return ["🌴", "🗼", "🐚"]
        case .jungle: return ["🌿", "🛕", "🦜"]
        }
    }
}

/// Someone (or something) on stage.
struct StoryActor: Equatable {
    enum Entrance: String, Codable { case fromLeft, fromRight, pop, float }
    /// An emoji, or "buddy" for the child's own buddy.
    let who: String
    /// 0 = left edge, 1 = right edge.
    let x: Double
    var size: Double = 1
    var entrance: Entrance = .pop

    static func buddy(_ x: Double = 0.3, _ entrance: Entrance = .fromLeft) -> StoryActor {
        StoryActor(who: "buddy", x: x, size: 1.2, entrance: entrance)
    }
}

struct StoryLine: Equatable {
    let voice: StoryVoice
    let text: String
}

struct StoryPanel: Equatable {
    let place: StoryPlace
    let actors: [StoryActor]
    let lines: [StoryLine]
}

struct Cutscene: Equatable, Identifiable {
    let id: String
    let title: String
    let panels: [StoryPanel]
}

enum StoryBook {
    private typealias A = StoryActor
    private typealias L = StoryLine

    /// Every cutscene, in story order.
    static let all: [Cutscene] = [
        Cutscene(id: "intro", title: "The Big Invitation", panels: [
            StoryPanel(place: .meadow, actors: [.buddy(0.3), A(who: "🦉", x: 0.72, entrance: .fromRight)], lines: [
                L(voice: .narrator, text: "One sunny morning, a letter came floating down on a tiny balloon."),
                L(voice: .ollie, text: "Hoo hoo! It's an invitation to the Balloon Festival at the castle on the hill!"),
            ]),
            StoryPanel(place: .meadow, actors: [.buddy(0.35, .pop), A(who: "🏰", x: 0.78, size: 1.4, entrance: .float)], lines: [
                L(voice: .buddy, text: "The castle is so far away! How do I get there?"),
                L(voice: .ollie, text: "One step at a time. Look both ways, learn as you go, and you'll get there!"),
            ]),
        ]),
        Cutscene(id: "after1", title: "Across Meadow Street", panels: [
            StoryPanel(place: .meadow, actors: [.buddy(0.4, .pop), A(who: "🎈", x: 0.7, entrance: .float)], lines: [
                L(voice: .narrator, text: "You made it across Meadow Street, looking left and right every time."),
                L(voice: .buddy, text: "That was fun! But the road ahead is long. Too long to hop!"),
            ]),
            StoryPanel(place: .road, actors: [.buddy(0.3), A(who: "🚗", x: 0.7, entrance: .fromRight)], lines: [
                L(voice: .ollie, text: "Then let's learn to drive! Driving School is just down the road."),
            ]),
        ]),
        Cutscene(id: "after2", title: "A Careful Driver", panels: [
            StoryPanel(place: .road, actors: [A(who: "🚗", x: 0.35, size: 1.2, entrance: .fromLeft), A(who: "🚦", x: 0.75)], lines: [
                L(voice: .narrator, text: "Red means stop, green means go. You drove like a pro!"),
                L(voice: .buddy, text: "Beep beep! But how will I carry all my festival gifts?"),
            ]),
            StoryPanel(place: .lab, actors: [.buddy(0.3), A(who: "🤖", x: 0.7, entrance: .pop)], lines: [
                L(voice: .ollie, text: "Build a robot helper! The Robot Lab has all the parts you need."),
            ]),
        ]),
        Cutscene(id: "after3", title: "Robot Friend", panels: [
            StoryPanel(place: .lab, actors: [.buddy(0.3, .pop), A(who: "🤖", x: 0.68, size: 1.3, entrance: .pop)], lines: [
                L(voice: .narrator, text: "Beep boop! Your robot blinked its lights and waved hello."),
                L(voice: .ocho, text: "Great building! Robots follow the code you give them, one step at a time."),
            ]),
            StoryPanel(place: .river, actors: [.buddy(0.3), A(who: "🐸", x: 0.72, entrance: .fromRight)], lines: [
                L(voice: .buddy, text: "Uh oh. Lily River is in the way!"),
                L(voice: .narrator, text: "Lily pads and logs float across. Hop carefully!"),
            ]),
        ]),
        Cutscene(id: "after4", title: "Over Lily River", panels: [
            StoryPanel(place: .river, actors: [.buddy(0.4, .pop), A(who: "🐸", x: 0.15), A(who: "🪷", x: 0.8)], lines: [
                L(voice: .narrator, text: "Splish, splash, safe on the other side!"),
                L(voice: .coral, text: "Slow and steady, young one. The city is next, and the castle isn't far after that."),
            ]),
        ]),
        Cutscene(id: "after5", title: "City Lights", panels: [
            StoryPanel(place: .city, actors: [A(who: "🚗", x: 0.3, size: 1.2, entrance: .fromLeft), A(who: "🏁", x: 0.75, entrance: .pop)], lines: [
                L(voice: .narrator, text: "Through busy streets and past the finish flag. What a rally!"),
                L(voice: .buddy, text: "Look! I can see the castle from here!"),
            ]),
            StoryPanel(place: .castle, actors: [.buddy(0.3), A(who: "🏰", x: 0.72, size: 1.5, entrance: .float)], lines: [
                L(voice: .ollie, text: "Castle Hill is the trickiest climb of all. You're ready!"),
            ]),
        ]),
        Cutscene(id: "after6", title: "The Balloon Festival", panels: [
            StoryPanel(place: .castle, actors: [.buddy(0.35, .pop), A(who: "🎉", x: 0.7, entrance: .pop), A(who: "🎈", x: 0.85, entrance: .float)], lines: [
                L(voice: .narrator, text: "You reached the castle on the hill, just as the Balloon Festival began!"),
                L(voice: .gemma, text: "Welcome, welcome! Everyone, give a big cheer for our newest explorer!"),
            ]),
            StoryPanel(place: .sky, actors: [.buddy(0.45, .float), A(who: "🎈", x: 0.2, entrance: .float), A(who: "☁️", x: 0.8)], lines: [
                L(voice: .narrator, text: "Up, up, up went the balloons. And far away, past the clouds, something sparkled with snow."),
                L(voice: .buddy, text: "A new adventure? Let's go!"),
            ]),
        ]),
        Cutscene(id: "after9", title: "Top of the Peaks", panels: [
            StoryPanel(place: .snow, actors: [.buddy(0.35, .pop), A(who: "🐧", x: 0.72, entrance: .fromRight)], lines: [
                L(voice: .pip, text: "You climbed all the way to Peak Castle! Brrr, but well done!"),
                L(voice: .buddy, text: "It's so cold up here. I wish I could feel some sunshine."),
            ]),
            StoryPanel(place: .beach, actors: [.buddy(0.3, .float), A(who: "🌴", x: 0.75)], lines: [
                L(voice: .narrator, text: "So off you floated, toward the warm and sunny shore."),
            ]),
        ]),
        Cutscene(id: "after12", title: "The Lighthouse", panels: [
            StoryPanel(place: .beach, actors: [.buddy(0.35, .pop), A(who: "🗼", x: 0.75, size: 1.4, entrance: .float)], lines: [
                L(voice: .narrator, text: "At the end of the beach stood the lighthouse, shining bright."),
                L(voice: .coral, text: "Its light helps every ship find its way home. Just like you found yours!"),
            ]),
            StoryPanel(place: .jungle, actors: [.buddy(0.3, .float), A(who: "🦜", x: 0.75, entrance: .fromRight)], lines: [
                L(voice: .narrator, text: "From the top of the lighthouse, you spotted a green jungle far across the bay."),
                L(voice: .buddy, text: "I hear parrots! One more adventure before home?"),
            ]),
        ]),
        Cutscene(id: "after15", title: "The Temple Top", panels: [
            StoryPanel(place: .jungle, actors: [.buddy(0.35, .pop), A(who: "🛕", x: 0.75, size: 1.4, entrance: .float), A(who: "🐒", x: 0.12, entrance: .fromLeft)], lines: [
                L(voice: .narrator, text: "At the very top of the jungle, the old temple glowed in the sunset."),
                L(voice: .ollie, text: "Hoo hoo! You crossed meadows, snow, beaches and jungles. What an explorer!"),
            ]),
            StoryPanel(place: .meadow, actors: [.buddy(0.4, .fromLeft), A(who: "🏡", x: 0.75, entrance: .pop)], lines: [
                L(voice: .narrator, text: "And then it was time to head home to Hop Village, full of stories to tell."),
                L(voice: .buddy, text: "Thank you for playing with me! See you in the village!"),
            ]),
        ]),
    ]

    static func cutscene(_ id: String) -> Cutscene? { all.first { $0.id == id } }

    /// The scene shown after finishing this chapter for the first time.
    static func after(chapter id: Int) -> Cutscene? { cutscene("after\(id)") }

    /// The scene before the very first level.
    static var intro: Cutscene { cutscene("intro")! }
}
