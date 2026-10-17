import Foundation

// Village missions: little quests from buddies. Each one teaches something real (gears, plants, shapes,
// frogs, kindness, coding) and gives a one-time star reward. There are no timers and no streaks.

enum MissionStep: Equatable {
    /// Pick up every item (walk over it).
    case collect(item: String, spots: [GridPoint], hint: String)
    /// Talk to a buddy (deliveries, cheering someone up).
    case talk(npcID: String, line: String, hint: String)
    /// Finish this many Coding Lab lessons in total.
    case codeLessons(Int, hint: String)

    var hint: String {
        switch self {
        case .collect(_, _, let h), .talk(_, _, let h), .codeLessons(_, let h): return h
        }
    }
}

struct MissionDef: Identifiable, Equatable {
    let id: String
    let giver: String           // NPC id
    let title: String
    let icon: String
    /// What the giver says when offering the mission.
    let intro: String
    /// The real-world lesson, shown and read aloud.
    let lesson: String
    let steps: [MissionStep]
    let thanks: String
    let reward: Int
}

/// Progress, saved inside PlayerProfile.
struct MissionSave: Codable, Equatable {
    /// Mission id → index of the current step. Equal to steps.count means "go back to the giver".
    var stage: [String: Int] = [:]
    /// Picked-up items ("gears.2").
    var collected: Set<String> = []
    var done: Set<String> = []

    init() {}

    enum CodingKeys: String, CodingKey { case stage, collected, done }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stage = (try? c.decodeIfPresent([String: Int].self, forKey: .stage)) ?? [:]
        collected = (try? c.decodeIfPresent(Set<String>.self, forKey: .collected)) ?? []
        done = (try? c.decodeIfPresent(Set<String>.self, forKey: .done)) ?? []
    }

    enum Status: Equatable {
        case new, active(step: Int), readyToTurnIn, done
    }

    func status(_ m: MissionDef) -> Status {
        if done.contains(m.id) { return .done }
        guard let s = stage[m.id] else { return .new }
        return s >= m.steps.count ? .readyToTurnIn : .active(step: s)
    }

    mutating func start(_ m: MissionDef) {
        guard status(m) == .new else { return }
        stage[m.id] = 0
    }

    /// How many of the current collect step's items are picked up.
    func collectedCount(_ m: MissionDef) -> (have: Int, need: Int)? {
        guard case .active(let s) = status(m), case .collect(_, let spots, _) = m.steps[s] else { return nil }
        let have = spots.indices.filter { collected.contains(Self.key(m, s, $0)) }.count
        return (have, spots.count)
    }

    static func key(_ m: MissionDef, _ step: Int, _ i: Int) -> String { "\(m.id).\(step).\(i)" }

    /// Items to show in the village right now (only for active collect steps).
    func pickups() -> [(key: String, item: String, tile: GridPoint)] {
        MissionCatalog.all.flatMap { m -> [(key: String, item: String, tile: GridPoint)] in
            guard case .active(let s) = status(m), case .collect(let item, let spots, _) = m.steps[s] else { return [] }
            return spots.enumerated().compactMap { i, p in
                let k = Self.key(m, s, i)
                return collected.contains(k) ? nil : (k, item, p)
            }
        }
    }

    /// Picks up an item. Moves the mission on when the last one is found. Returns the mission it belonged to.
    @discardableResult
    mutating func collect(_ key: String) -> MissionDef? {
        guard let m = MissionCatalog.all.first(where: { key.hasPrefix($0.id + ".") }),
              case .active(let s) = status(m), case .collect(_, let spots, _) = m.steps[s],
              key.hasPrefix("\(m.id).\(s).") else { return nil }
        collected.insert(key)
        if spots.indices.allSatisfy({ collected.contains(Self.key(m, s, $0)) }) { stage[m.id] = s + 1 }
        return m
    }

    /// Talking to a buddy may move a mission on. Returns the step's line if it did.
    mutating func talked(to npcID: String) -> (MissionDef, String)? {
        for m in MissionCatalog.all {
            guard case .active(let s) = status(m), case .talk(let who, let line, _) = m.steps[s], who == npcID else { continue }
            stage[m.id] = s + 1
            return (m, line)
        }
        return nil
    }

    /// Coding Lab progress moves code missions on.
    mutating func codeLessonsDone(_ n: Int) {
        for m in MissionCatalog.all {
            guard case .active(let s) = status(m), case .codeLessons(let need, _) = m.steps[s], n >= need else { continue }
            stage[m.id] = s + 1
        }
    }

    /// Turn in a finished mission to its giver. Returns true the first time.
    mutating func turnIn(_ m: MissionDef) -> Bool {
        guard status(m) == .readyToTurnIn else { return false }
        done.insert(m.id)
        stage[m.id] = nil
        return true
    }
}

enum MissionCatalog {
    static func mission(givenBy npc: String) -> MissionDef? { base.first { $0.giver == npc } }
    static func mission(_ id: String) -> MissionDef? { all.first { $0.id == id } }

    /// Every mission: the villagers' own, plus the festival missions.
    static let all: [MissionDef] = base + FestivalMissions.all

    /// The mission a villager offers right now. The festival host offers a festival already in progress first
    /// (so nothing is ever left half-done), otherwise the festival being celebrated.
    static func offer(from npc: String, save: MissionSave, festival: Festival) -> MissionDef? {
        guard npc == FestivalMissions.hostID else { return mission(givenBy: npc) }
        if let going = FestivalMissions.all.first(where: { m in
            switch save.status(m) {
            case .active, .readyToTurnIn: return true
            default: return false
            }
        }) { return going }
        return FestivalMissions.mission(for: festival)
    }

    /// Missions to list in the mission log: every villager mission, plus festivals that are started, done,
    /// or being celebrated now.
    static func visible(save: MissionSave, festival: Festival) -> [MissionDef] {
        base + FestivalMissions.all.filter { m in m.id == festival.missionID || save.status(m) != .new }
    }

    /// The villagers' own missions.
    static let base: [MissionDef] = [
        MissionDef(id: "gears", giver: "acorn", title: "Lost Gears", icon: "⚙️",
                   intro: "Oh no! Five gears fell out of my robot and rolled all over the village. Can you find them?",
                   lesson: "Gears are wheels with teeth. When one gear turns, its teeth push the next gear around. Clocks, bikes and robots all use gears!",
                   steps: [.collect(item: "gear", spots: [GridPoint(4, 11), GridPoint(30, 11), GridPoint(39, 21), GridPoint(17, 30), GridPoint(9, 40)],
                                    hint: "Find 5 gears around the village")],
                   thanks: "All five gears! My robot can roll again. You're a great engineer!", reward: 2),
        MissionDef(id: "flowers", giver: "flora", title: "Thirsty Flowers", icon: "💧",
                   intro: "The flower patches are thirsty! Can you give water to 4 of them?",
                   lesson: "Plants need water, sunlight and air to grow. Their roots drink water from the soil, and their leaves use sunlight to make food.",
                   steps: [.collect(item: "drop", spots: [GridPoint(3, 9), GridPoint(15, 9), GridPoint(24, 11), GridPoint(30, 14)],
                                    hint: "Water 4 flower patches")],
                   thanks: "Look at them bloom! Thank you for helping them grow.", reward: 2),
        MissionDef(id: "mail", giver: "buzzy", title: "Special Delivery", icon: "✉️",
                   intro: "Bzzz! I have a letter for Pip at the pond. Can you deliver it? Then Pip might send one back to Stella!",
                   lesson: "Letters have an address so they reach the right home. Bees are nature's helpers too: they carry pollen from flower to flower!",
                   steps: [
                    .talk(npcID: "pip", line: "A letter for me? It says 'Come play!' Please take my reply to Stella at the museum.", hint: "Take the letter to Pip at the pond"),
                    .talk(npcID: "stella", line: "A letter from Pip! How sweet. Tell Buzzy thank you!", hint: "Take Pip's reply to Stella"),
                   ],
                   thanks: "Bzz-tastic! Both letters delivered. You're the fastest mail carrier in Hop Village!", reward: 2),
        MissionDef(id: "shapes", giver: "polly", title: "Shape Hunt", icon: "🔺",
                   intro: "I hid three shape signs around the village: a circle, a triangle and a square. Can you find them all?",
                   lesson: "A triangle has 3 sides. A square has 4 equal sides. A circle has no corners at all! Look around: shapes are everywhere.",
                   steps: [.collect(item: "shape", spots: [GridPoint(29, 26), GridPoint(3, 26), GridPoint(38, 40)],
                                    hint: "Find the circle, triangle and square")],
                   thanks: "You found every shape! You have super shape-spotting eyes.", reward: 2),
        MissionDef(id: "lilies", giver: "fizz", title: "Lily Pad Hop", icon: "🐸",
                   intro: "Ribbit! Can you hop across all the lily pads in the pond? Use the Hop button to jump the gaps!",
                   lesson: "Frogs start life as eggs, hatch into tadpoles that swim with tails, then grow legs and become frogs. That change is called metamorphosis!",
                   steps: [.collect(item: "lily", spots: [GridPoint(20, 49), GridPoint(22, 49), GridPoint(24, 49), GridPoint(26, 49), GridPoint(28, 49)],
                                    hint: "Hop onto 5 lily pads")],
                   thanks: "Ribbit-tastic hopping! You'd make a great frog.", reward: 2),
        MissionDef(id: "kindness", giver: "kip", title: "Kindness Day", icon: "💛",
                   intro: "Today is Kindness Day! Can you visit Ollie, Pixel Pup and Iron Acorn and cheer them up?",
                   lesson: "Kind words make people feel brave and happy. Saying 'Good job!' or 'Want to play?' can change someone's whole day.",
                   steps: [
                    .talk(npcID: "ollie", line: "You came to cheer me up? That's so kind. Hoo-ray for friends!", hint: "Cheer up Ollie"),
                    .talk(npcID: "pixelpup", line: "Woof! You made my tail wag. Thank you!", hint: "Cheer up Pixel Pup"),
                    .talk(npcID: "acorn", line: "That made my day! Kindness is the best gear of all.", hint: "Cheer up Iron Acorn"),
                   ],
                   thanks: "You spread so much kindness today. The whole village is smiling!", reward: 2),
        MissionDef(id: "code", giver: "ocho", title: "Code Quest", icon: "💻",
                   intro: "Coders build big things one small step at a time. Can you finish 3 lessons in the Coding Lab?",
                   lesson: "Coders break big problems into small steps, test them, and fix bugs. That's called computational thinking, and you're doing it!",
                   steps: [.codeLessons(3, hint: "Finish 3 Coding Lab lessons")],
                   thanks: "Three lessons! With eight arms I still couldn't type that fast. You're a real coder!", reward: 3),
    ]
}
