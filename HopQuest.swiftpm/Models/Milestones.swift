import Foundation

// Grown-ups progress page and milestone notes (v5.1). Plain Swift, tested in Tests/Learn.
//
// Everything is worked out on this device from the save. A milestone note is only ever sent by a grown-up:
// after the parental gate, the app opens Messages (or the share sheet) with the note filled in, and the grown-up
// presses Send. Nothing is sent automatically, and nothing goes to a server.

/// One game inside a learning place, and the child's best stars in it (0–3).
struct SkillProgress: Equatable {
    let skill: String
    let best: Int

    enum Status: Equatable { case notStarted, practising, gotIt }

    var status: Status { best <= 0 ? .notStarted : best == 1 ? .practising : .gotIt }
}

/// A learning place (Reading Nook, Clock Tower…) as grown-ups see it.
struct LearningArea: Equatable, Identifiable {
    let id: String
    let title: String
    let skills: [SkillProgress]

    var stars: Int { skills.reduce(0) { $0 + min(3, max(0, $1.best)) } }
    var maxStars: Int { skills.count * 3 }
    var started: Bool { skills.contains { $0.best > 0 } }
    /// Every game at 2 stars or more.
    var finished: Bool { !skills.isEmpty && skills.allSatisfy { $0.status == .gotIt } }
    /// Games played but still at 1 star: the place to help.
    var needsPractice: [SkillProgress] { skills.filter { $0.status == .practising } }
    var learned: [SkillProgress] { skills.filter { $0.status == .gotIt } }
}

/// What the milestone checker looks at.
struct MilestoneInput: Equatable {
    var lifetimeStars: Int
    var areas: [LearningArea]
    var postcards: Int
    var lettersWritten: Int
    var storyFinished: Bool
}

struct Milestone: Equatable, Identifiable {
    let id: String
    /// Finishes the sentence "Sam just …".
    let what: String
}

enum Milestones {
    static let starSteps = [25, 50, 100, 250, 500]

    /// Every milestone reached so far, in a stable order.
    static func reached(_ input: MilestoneInput) -> [Milestone] {
        var out: [Milestone] = []
        for n in starSteps where input.lifetimeStars >= n {
            out.append(Milestone(id: "stars\(n)", what: "earned \(n) stars in HopQuest"))
        }
        for a in input.areas where a.finished {
            out.append(Milestone(id: "area-\(a.id)", what: "finished every game in the \(a.title)"))
        }
        if input.postcards >= 7 { out.append(Milestone(id: "postcards7", what: "collected postcards from all 7 continents")) }
        if input.lettersWritten >= 62 { out.append(Milestone(id: "letters62", what: "traced every capital letter, small letter and number")) }
        if input.storyFinished { out.append(Milestone(id: "story", what: "finished the whole HopQuest story, all the way to the Coral Castle")) }
        return out
    }

    /// Milestones reached but not yet shared.
    static func pending(_ input: MilestoneInput, shared: Set<String>) -> [Milestone] {
        reached(input).filter { !shared.contains($0.id) }
    }

    /// The note a grown-up can send. Uses the child's first name only, and lists skills in plain words.
    static func note(name: String, milestone: Milestone?, input: MilestoneInput) -> String {
        let who = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Your child" : name
        var lines: [String] = []
        if let m = milestone {
            lines.append("HopQuest news: \(who) just \(m.what)! ⭐")
        } else {
            lines.append("HopQuest update for \(who) ⭐")
        }
        let learned = input.areas.flatMap { a in a.learned.map(\.skill) }
        if !learned.isEmpty {
            lines.append("Skills practised: " + list(Array(learned.prefix(6))) + (learned.count > 6 ? ", and more" : "") + ".")
        }
        let practice = input.areas.flatMap { a in a.needsPractice.map(\.skill) }
        if let next = practice.first {
            lines.append("Working on next: \(next).")
        }
        lines.append("Stars earned so far: \(input.lifetimeStars).")
        return lines.joined(separator: "\n")
    }

    static func list(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        case 2: return "\(items[0]) and \(items[1])"
        default: return items.dropLast().joined(separator: ", ") + " and " + items.last!
        }
    }

    /// A phone number as typed: keeps digits and a leading +. Empty if it isn't a plausible number.
    static func cleanPhone(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let plus = trimmed.hasPrefix("+") ? "+" : ""
        let digits = trimmed.filter(\.isNumber)
        guard (7...15).contains(digits.count) else { return "" }
        return plus + digits
    }
}

/// What grown-ups chose about milestone notes. Kept on this device only.
struct MilestoneSettings: Codable, Equatable {
    /// Off until a grown-up turns it on.
    var enabled = false
    /// The grown-up's phone number, used only to fill in the "To:" line in Messages.
    var phone = ""
    /// Milestones already shared (or skipped).
    var shared: Set<String> = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = (try? c.decodeIfPresent(Bool.self, forKey: .enabled)) ?? false
        phone = Milestones.cleanPhone((try? c.decodeIfPresent(String.self, forKey: .phone)) ?? "")
        shared = (try? c.decodeIfPresent(Set<String>.self, forKey: .shared)) ?? []
    }
}

// MARK: - Try at home (v9.7)

/// For grown-ups: what a learning place teaches, in one plain line, and a few short things to try together
/// away from the screen. Written by hand, no shopping needed (things most homes have), and never homework.
struct AtHomeIdeas: Equatable {
    /// "What they're learning": one sentence a grown-up can read at a glance.
    let learning: String
    /// Two or three activities, each one sentence, that take a few minutes.
    let ideas: [String]
}

enum AtHome {
    /// Every learning place on the progress page, by `LearningArea.id`.
    static let byPlace: [String: AtHomeIdeas] = [
        "reading": AtHomeIdeas(learning: "Hearing the first sound in a word, building short words, sight words, rhymes and reading a short sentence.",
                               ideas: ["Play I Spy with sounds: \"I spy something that starts with /b/.\"",
                                       "Point out a sight word (the, and, is) on a cereal box or a sign and let them find it next time.",
                                       "Take turns reading one line each from a favorite picture book."]),
        "writing": AtHomeIdeas(learning: "Printing capital and lowercase letters, numbers 0 to 9 and short words, starting each stroke in the right place.",
                               ideas: ["Write letters with a finger in sand, flour on a tray, or on a steamy window.",
                                       "Let them write the shopping list, even if it's just the first letter of each thing.",
                                       "Make a name card for each person at dinner."]),
        "market": AtHomeIdeas(learning: "Counting coins, paying an exact amount, making change, comparing numbers and adding prices.",
                              ideas: ["Set up a pretend shop with toys, price tags under 20¢ and real coins.",
                                      "Let them count out the coins for something small at a real shop.",
                                      "Ask \"Which costs more?\" with two things on a menu or flyer."]),
        "clock": AtHomeIdeas(learning: "Telling time to the hour, half hour and quarter hour, setting a clock, and \"one hour later\".",
                             ideas: ["Ask what time it is on a clock with hands at meals and bedtime.",
                                     "Say \"We leave in one hour. What time will that be?\"",
                                     "Make a paper-plate clock with a split pin for the hands."]),
        "science": AtHomeIdeas(learning: "Guessing, then testing: sinking and floating, magnets, plant parts, weather, and solids, liquids and gases.",
                               ideas: ["Fill the sink and guess first: does a spoon, a cork or an apple float?",
                                       "Walk round the kitchen with a fridge magnet. What does it stick to?",
                                       "Freeze water in a cup, then watch it melt. Where did the ice go?"]),
        "world": AtHomeIdeas(learning: "The seven continents and five oceans, where animals live, and famous places around the world.",
                             ideas: ["Find where a fruit or a toy was made on its label, then find that country on a map.",
                                     "Pick an animal at bedtime and talk about where in the world it lives.",
                                     "Look at a globe or a world map and trace the oceans with a finger."]),
        "music": AtHomeIdeas(learning: "Listening and remembering short tunes, copying a rhythm, and playing a simple song.",
                             ideas: ["Clap a short rhythm and have them clap it back, then swap.",
                                     "Make a drum from a pot and a wooden spoon and play loud, then soft.",
                                     "Sing a song you both know and stop: can they sing the next note?"]),
        "spelling": AtHomeIdeas(learning: "Spelling words by sound, the middle sound, tricky words, and the silent e that makes a vowel say its name.",
                                ideas: ["Spell a word out loud together using magnetic or paper letters.",
                                        "Try magic e with paper letters: cap becomes cape, kit becomes kite.",
                                        "Hunt for a tricky word in a book and spell it together."]),
        "fractions": AtHomeIdeas(learning: "Halves, thirds and quarters: naming a part, finding it in a picture, sharing fairly and comparing slices.",
                                 ideas: ["Cut a sandwich or a pizza into halves and quarters and name each piece.",
                                         "Share 12 crackers between 3 plates fairly. How many on each?",
                                         "Ask \"Would you rather have half or a quarter of this pancake?\""]),
        "shapes": AtHomeIdeas(learning: "Naming flat and solid shapes, counting sides and corners, and spotting shape patterns.",
                              ideas: ["Go on a shape hunt: a round plate, a rectangle door, a cylinder can.",
                                      "Build a pattern with spoons and forks and ask what comes next.",
                                      "Count the corners on a book, a napkin and a slice of toast."]),
        "rhyme": AtHomeIdeas(learning: "Hearing rhymes, telling rhymes apart, clapping the beats (syllables) in a word, and finishing a rhyme.",
                             ideas: ["Make up silly rhymes in the car: \"cat, hat, bat… splat!\"",
                                     "Clap the beats in each family member's name.",
                                     "Read a rhyming book and pause before the rhyming word."]),
        "numbers": AtHomeIdeas(learning: "Place value: tens and ones, building numbers to 99 with blocks, and comparing two-digit numbers.",
                               ideas: ["Bundle straws or pencils in tens with a rubber band, then count tens and ones.",
                                       "Read house or bus numbers together: how many tens?",
                                       "Roll two dice to make a number. Who made the bigger one?"]),
        "times": AtHomeIdeas(learning: "Equal groups, skip counting by 2s, 3s, 5s and 10s, rows (arrays) and \"groups of\".",
                             ideas: ["Count socks by 2s as you sort the laundry.",
                                     "Put snacks in equal groups: 3 bowls with 4 grapes each. How many in all?",
                                     "Spot rows in an egg box or a muffin tray and count them."]),
        "measure": AtHomeIdeas(learning: "Longer and shorter, measuring with blocks, heavier and lighter, and which tool measures what.",
                               ideas: ["Measure the table in hand spans, then in spoons. Why are the numbers different?",
                                       "Hold two things, one in each hand, and guess which is heavier.",
                                       "Use a measuring cup or kitchen scale while cooking together."]),
        "feelings": AtHomeIdeas(learning: "Naming feelings, how someone in a story might feel, what helps with a big feeling, and kind words.",
                                ideas: ["Talk about how a character in a book feels and why.",
                                        "Share one feeling each at dinner: \"Today I felt… when…\"",
                                        "Practise a calm-down idea together, like five slow breaths."]),
        "nature": AtHomeIdeas(learning: "Where animals live, life cycles (frog, butterfly, chicken, plant), the five senses and baby animal names.",
                              ideas: ["On a walk, name one thing you see, hear, smell and touch.",
                                      "Plant a bean in a wet paper towel and watch it sprout.",
                                      "Name the babies of animals in a picture book: kitten, puppy, calf."]),
        "calendar": AtHomeIdeas(learning: "Days of the week, yesterday and tomorrow, months of the year, and the four seasons.",
                                ideas: ["Each morning, ask \"What day is it? What was yesterday?\"",
                                        "Find each family birthday on a calendar and say the month.",
                                        "Look out of the window: what clues tell you the season?"]),
        "compass": AtHomeIdeas(learning: "Left and right, north, south, east and west, finding a spot on a grid map, and following steps on a map.",
                               ideas: ["Give directions to a hidden toy: \"Three steps forward, then turn left.\"",
                                       "Draw a map of their room together and mark the bed and the door.",
                                       "Play Simon Says with left and right hands."]),
        "healthy": AtHomeIdeas(learning: "What the brain, heart, lungs, bones, muscles and teeth do, the food groups, and healthy habits.",
                               ideas: ["Sort the groceries into fruit, vegetables, grains, protein and dairy as you put them away.",
                                       "Sing a short song while washing hands so the scrubbing lasts about 20 seconds.",
                                       "Jump ten times, then put a hand on your chest: can you feel your heart beating faster?"]),
        "code": AtHomeIdeas(learning: "Coding: putting steps in order, loops (repeat) and finding mistakes (debugging) to guide a robot to a star.",
                            ideas: ["Be the robot: they give step-by-step directions to get you to the kitchen.",
                                    "Write the steps for brushing teeth on cards, mix them up, and put them back in order.",
                                    "Find a pattern that repeats in a song or a dance: that's a loop!"]),
    ]

    /// A short, friendly fallback for any place without its own ideas yet.
    static let general = AtHomeIdeas(learning: "Games that practise a skill a little at a time, with hints and no penalty for wrong answers.",
                                     ideas: ["Ask them to show you their favorite game in this place and explain it.",
                                             "Play one round together and take turns answering."])

    static func ideas(for placeID: String) -> AtHomeIdeas { byPlace[placeID] ?? general }

    /// The places to suggest first: ones being practised (games at 1 star), then ones started but not finished,
    /// at most `limit`, in page order. Places not started are left out: there's nothing to build on yet.
    static func suggested(_ areas: [LearningArea], limit: Int = 3) -> [LearningArea] {
        let practising = areas.filter { !$0.needsPractice.isEmpty }
        let started = areas.filter { $0.started && !$0.finished && $0.needsPractice.isEmpty }
        return Array((practising + started).prefix(max(0, limit)))
    }
}
