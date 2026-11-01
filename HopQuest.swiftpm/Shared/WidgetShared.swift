import Foundation

// Shared by the app and the home-screen widget (v5.6). Plain Swift, tested in Tests/Learn.
// The app writes a small snapshot of the child's progress into the shared App Group; the widget only reads it.
// The widget's own little game (Star Hop) keeps its state there too. Nothing leaves the device.

enum SharedStore {
    static let appGroup = "group.com.phoronomics.hopquest"
    static let snapshotKey = "hopquest.widget.snapshot"
    static let hopKey = "hopquest.widget.starhop"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func loadSnapshot(_ d: UserDefaults? = defaults) -> WidgetSnapshot {
        guard let data = d?.data(forKey: snapshotKey), let s = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return s
    }

    /// Saves the snapshot. Returns true when it changed (so the app only asks the widget to refresh when needed).
    @discardableResult
    static func save(_ s: WidgetSnapshot, _ d: UserDefaults? = defaults) -> Bool {
        let enc = JSONEncoder()
        enc.outputFormatting = .sortedKeys   // the same snapshot always gives the same bytes
        guard let d, let data = try? enc.encode(s) else { return false }
        if d.data(forKey: snapshotKey) == data { return false }
        d.set(data, forKey: snapshotKey)
        return true
    }

    static func loadHop(_ d: UserDefaults? = defaults) -> StarHop {
        guard let data = d?.data(forKey: hopKey), let h = try? JSONDecoder().decode(StarHop.self, from: data) else { return StarHop() }
        return h
    }

    static func save(_ h: StarHop, _ d: UserDefaults? = defaults) {
        guard let d, let data = try? JSONEncoder().encode(h) else { return }
        d.set(data, forKey: hopKey)
    }
}

/// What the widget shows: the buddy, stars, what to play next and the skill being practised.
struct WidgetSnapshot: Codable, Equatable {
    var name: String
    var buddyName: String
    var buddyEmoji: String
    var buddyID: String
    var stars: Int
    var lifetimeStars: Int
    /// "Clock Tower"
    var lessonTitle: String
    /// "telling time to the half hour"
    var skill: String
    /// "Practising" / "Up next" / "Got it"
    var skillState: String
    var skillsLearned: Int
    var skillsTotal: Int
    var quickBest: Int

    static let placeholder = WidgetSnapshot(name: "Explorer", buddyName: "Pip Penguin", buddyEmoji: "🐧", buddyID: "pip", stars: 0, lifetimeStars: 0,
                                            lessonTitle: "Reading Nook", skill: "beginning letter sounds", skillState: "Up next",
                                            skillsLearned: 0, skillsTotal: 40, quickBest: 0)

    var progress: Double { skillsTotal > 0 ? min(1, Double(skillsLearned) / Double(skillsTotal)) : 0 }
}

/// Star Hop, the widget's tap-to-play game. Widgets can only be tapped (no holding, no double taps), so every tap is one move:
/// tap the left half to step left; tap the right half to jump up and to the right; tap the right half again while in the air
/// to double jump even higher. Catch the stars before they drift away. The board wraps around at the edges.
struct StarHop: Codable, Equatable {
    static let columns = 6
    static let rows = 3
    static let goal = 10

    /// Buddy position: column 0…5, row 0 (ground) … 2 (top).
    var col = 1
    var row = 0
    /// Jumps since leaving the ground (2 = double jump used).
    var jumps = 0
    /// Where the stars are, as column + row × columns.
    var stars: [Int] = [4, 3 + 6 * 2]
    var collected = 0
    var moves = 0
    var best = 0
    /// Increases with every move, for repeatable star placement.
    var turn = 0
    /// A word for the last move ("Jump!", "Double jump!", "Got it!").
    var message = "Tap to play!"

    var won: Bool { collected >= Self.goal }

    func cell(_ c: Int, _ r: Int) -> Int { c + r * Self.columns }

    /// Tap on the left half: one step left (falling one row if in the air).
    mutating func left() {
        guard !won else { return }
        col = (col + Self.columns - 1) % Self.columns
        if row > 0 { row -= 1 }
        if row == 0 { jumps = 0 }
        message = row == 0 ? "Step!" : "Whee!"
        afterMove()
    }

    /// Tap on the right half: jump up and right; in the air, a second tap is a double jump; after that you glide down.
    mutating func right() {
        guard !won else { return }
        col = (col + 1) % Self.columns
        if row == 0 {
            row = 1; jumps = 1; message = "Jump!"
        } else if jumps == 1 {
            row = min(Self.rows - 1, row + 1); jumps = 2; message = "Double jump!"
        } else {
            row -= 1
            if row == 0 { jumps = 0 }
            message = "Glide!"
        }
        afterMove()
    }

    /// Start a fresh round (keeps the best).
    mutating func newGame() {
        let keep = best
        self = StarHop()
        best = keep
        message = "New game! Catch \(Self.goal) stars."
    }

    private mutating func afterMove() {
        moves += 1
        turn += 1
        let here = cell(col, row)
        if let i = stars.firstIndex(of: here) {
            stars.remove(at: i)
            collected += 1
            message = won ? "You caught \(Self.goal) stars!" : "Got it! ⭐"
            if won && (best == 0 || moves < best) { best = moves }
        }
        // stars drift down one row every third move, and wrap back to the top when they reach the ground
        if turn % 3 == 0 {
            stars = stars.map { s in
                let r = s / Self.columns, c = s % Self.columns
                return r == 0 ? cell(c, Self.rows - 1) : cell(c, r - 1)
            }
        }
        // keep two stars on the board, never on the buddy
        var seed = UInt64(truncatingIfNeeded: turn &* 2_654_435_761 &+ collected &* 97)
        while !won && stars.count < 2 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let pick = Int((seed >> 33) % UInt64(Self.columns * Self.rows))
            if pick != cell(col, row) && !stars.contains(pick) { stars.append(pick) }
        }
    }
}
