import Foundation

// v7.3–v7.6: Breathe with Buddy, Surprise Me and buddy hats. Plain Swift, tested in Tests/Learn.

// MARK: - Breathe with Buddy (v7.3)

/// A calm breathing break: breathe in while the balloon grows, hold, breathe out while it shrinks.
/// Slow and even (about 6 breaths a minute), the pace often taught to children for calming down.
struct BreathPlan: Equatable {
    enum Step: String, Equatable { case breatheIn = "Breathe in", hold = "Hold", breatheOut = "Breathe out", done = "All done" }

    var inSeconds: Double = 4
    var holdSeconds: Double = 2
    var outSeconds: Double = 5
    var breaths: Int = 5

    var breathLength: Double { inSeconds + holdSeconds + outSeconds }
    var total: Double { breathLength * Double(breaths) }

    /// Where the break is at `t` seconds: the step, how far through it (0…1), which breath (1-based),
    /// and how big the balloon is (0 = empty, 1 = full).
    func state(at t: Double) -> (step: Step, progress: Double, breath: Int, size: Double) {
        guard t < total else { return (.done, 1, breaths, 0) }
        let tt = max(0, t)
        let breath = Int(tt / breathLength)
        let within = tt - Double(breath) * breathLength
        if within < inSeconds {
            let p = within / inSeconds
            return (.breatheIn, p, breath + 1, ease(p))
        } else if within < inSeconds + holdSeconds {
            return (.hold, (within - inSeconds) / holdSeconds, breath + 1, 1)
        } else {
            let p = (within - inSeconds - holdSeconds) / outSeconds
            return (.breatheOut, p, breath + 1, 1 - ease(p))
        }
    }

    /// Smooth start and finish, so the balloon never jerks.
    private func ease(_ p: Double) -> Double { 0.5 - cos(min(1, max(0, p)) * .pi) / 2 }
}

// MARK: - Surprise Me (v7.4)

enum SurpriseMe {
    /// Picks a learning place with a game not finished yet (fewer than 2 stars), preferring places
    /// the child has played least. Never the place picked last time. Nil when everything is finished.
    /// `areas`: (place id, best stars per game).
    static func pick<G: RandomNumberGenerator>(areas: [(id: String, bests: [Int])], last: String?, using rng: inout G) -> String? {
        let open = areas.filter { $0.bests.contains { $0 < 2 } }
        guard !open.isEmpty else { return nil }
        let choices = open.count > 1 ? open.filter { $0.id != last } : open
        // weight places by how much is left to do, so newer places come up more often
        let weights = choices.map { a in a.bests.filter { $0 < 2 }.count + (a.bests.allSatisfy { $0 == 0 } ? 2 : 0) }
        var roll = Int.random(in: 0..<max(1, weights.reduce(0, +)), using: &rng)
        for (a, w) in zip(choices, weights) {
            if roll < w { return a.id }
            roll -= w
        }
        return choices.last?.id
    }
}

// MARK: - Buddy hats (v7.5)

/// Hats for your buddy, unlocked by earning badges. Wearing a hat changes nothing in the game: it's just for fun.
enum HatKind: String, CaseIterable, Codable, Identifiable {
    case none, party, cap, flower, beanie, crown, wizard, topHat, astronaut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "No hat"
        case .party: return "Party Hat"
        case .cap: return "Ball Cap"
        case .flower: return "Flower Crown"
        case .beanie: return "Cozy Beanie"
        case .crown: return "Golden Crown"
        case .wizard: return "Wizard Hat"
        case .topHat: return "Top Hat"
        case .astronaut: return "Space Helmet"
        }
    }

    /// Badges needed to unlock it.
    var badgesNeeded: Int {
        switch self {
        case .none, .party: return 0
        case .cap: return 2
        case .flower: return 4
        case .beanie: return 6
        case .crown: return 9
        case .wizard: return 12
        case .topHat: return 16
        case .astronaut: return 20
        }
    }

    func unlocked(badges: Int) -> Bool { badges >= badgesNeeded }

    /// The next hat to unlock, and how many more badges it needs.
    static func next(badges: Int) -> (hat: HatKind, more: Int)? {
        allCases.filter { !$0.unlocked(badges: badges) }.min { $0.badgesNeeded < $1.badgesNeeded }.map { ($0, $0.badgesNeeded - badges) }
    }
}

// MARK: - Play this week (v7.8)

/// Minutes played each day, kept on this device for the grown-ups' chart. Only the last 14 days are kept.
struct PlayHistory: Codable, Equatable {
    /// "yyyy-MM-dd" → seconds played that day.
    var days: [String: Int] = [:]

    static let keep = 14

    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    mutating func add(_ seconds: Int, on date: Date, calendar: Calendar = .current) {
        guard seconds > 0 else { return }
        days[Self.key(date, calendar: calendar), default: 0] += seconds
        // forget anything older than two weeks
        if let cutoff = calendar.date(byAdding: .day, value: -(Self.keep - 1), to: calendar.startOfDay(for: date)) {
            let oldest = Self.key(cutoff, calendar: calendar)
            days = days.filter { $0.key >= oldest }
        }
    }

    /// The last 7 days, oldest first, ending today: (date, minutes rounded to the nearest minute).
    func week(endingOn date: Date, calendar: Calendar = .current) -> [(day: Date, minutes: Int)] {
        let today = calendar.startOfDay(for: date)
        return (0..<7).reversed().compactMap { back in
            guard let d = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return (d, ((days[Self.key(d, calendar: calendar)] ?? 0) + 30) / 60)
        }
    }

    func weekTotal(endingOn date: Date, calendar: Calendar = .current) -> Int {
        week(endingOn: date, calendar: calendar).reduce(0) { $0 + $1.minutes }
    }
}
