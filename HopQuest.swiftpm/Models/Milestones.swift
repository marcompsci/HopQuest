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
