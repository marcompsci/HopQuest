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
    /// The app is in Spanish (v8.1). Optional so snapshots from before still load.
    var spanish: Bool? = nil

    static let placeholder = WidgetSnapshot(name: "Explorer", buddyName: "Pip Penguin", buddyEmoji: "🐧", buddyID: "pip", stars: 0, lifetimeStars: 0,
                                            lessonTitle: "Reading Nook", skill: "beginning letter sounds", skillState: "Up next",
                                            skillsLearned: 0, skillsTotal: 40, quickBest: 0)

    var progress: Double { skillsTotal > 0 ? min(1, Double(skillsLearned) / Double(skillsTotal)) : 0 }
}

// MARK: - Star Hop 3 (v6.6–v6.7)

/// One star on the board. On counting and spelling levels it carries a number or a letter.
struct HopStar: Codable, Equatable, Identifiable {
    var id: Int
    var cell: Int
    var label: String? = nil
    var golden = false
}

/// What a level asks for.
enum HopGoal: Equatable {
    /// Catch this many stars (golden ones count twice).
    case stars(Int)
    /// Catch numbered stars in order, from `from` by `step` up to (or down to) `to`.
    case count(from: Int, step: Int, to: Int)
    /// Catch the letters of a word in order (a new word each try).
    case spell
    /// Catch these in order (the alphabet, say).
    case inOrder([String])
    /// Answer sums (or take-aways): catch the star with the answer. `rounds` questions.
    case math(add: Bool, rounds: Int)
}

struct HopLevel: Equatable {
    let number: Int
    let title: String
    let tip: String
    let goal: HopGoal
    let clouds: Int
    /// Sky top and bottom, grass and soil colors.
    let skyTop: UInt32
    let skyBottom: UInt32
    let grass: UInt32
    let soil: UInt32
    var night = false
    /// Column of a spring pad on the ground: landing on it bounces the buddy to the top row.
    var spring: Int? = nil
    /// Bubble shields show up now and then; one bubble saves you from one cloud bump.
    var bubbles = false
}

/// Star Hop, the widget's tap-to-play game. Widgets can only be tapped (no holding, no double taps), so every tap is one move:
/// tap the left half to step left; tap the right half to jump up and to the right; tap the right half again while in the air
/// to double jump even higher, then glide down. The board wraps around at the edges.
///
/// Twelve levels, each its own little world: plain star levels, counting (up, down, by twos and tens), spelling, the
/// alphabet, adding and taking away. Puff clouds float along the sky rows from level 2; bumping one costs a heart
/// (the ground is always safe). Catching a wrong number or letter never costs anything: the star just pops somewhere else.
/// Spring pads bounce you up high; bubble shields save you from one bump. Each level is rated 1–3 stars:
/// one for finishing, one for no bumps, one for quick feet (at most `par` moves).
struct StarHop: Codable, Equatable {
    static let columns = 6
    static let rows = 3
    static let maxHearts = 3
    static let startCol = 1

    static let levels: [HopLevel] = [
        HopLevel(number: 1, title: "Sunny Meadow", tip: "Catch 8 stars!", goal: .stars(8), clouds: 0,
                 skyTop: 0xBFE3FF, skyBottom: 0xEEF8FF, grass: 0x59C46B, soil: 0xB57A45),
        HopLevel(number: 2, title: "Breezy Beach", tip: "Hop over the puff cloud!", goal: .stars(8), clouds: 1,
                 skyTop: 0x9FDCF5, skyBottom: 0xFFF3D6, grass: 0xF2D58A, soil: 0xD9A95B),
        HopLevel(number: 3, title: "Counting Hill", tip: "Catch the stars in order: 1, 2, 3…", goal: .count(from: 1, step: 1, to: 6), clouds: 1,
                 skyTop: 0xC9E7C2, skyBottom: 0xF4FBEF, grass: 0x3FA55B, soil: 0x8C6239),
        HopLevel(number: 4, title: "Snowy Peaks", tip: "Two clouds! Grab a bubble to stay safe.", goal: .stars(10), clouds: 2,
                 skyTop: 0xD6E4F5, skyBottom: 0xFFFFFF, grass: 0xF4F8FF, soil: 0xA9B8CC, bubbles: true),
        HopLevel(number: 5, title: "Spelling Sky", tip: "Catch the letters to spell the word!", goal: .spell, clouds: 1,
                 skyTop: 0xF9C9E0, skyBottom: 0xFFF0E5, grass: 0x8FD18B, soil: 0xB07A52),
        HopLevel(number: 6, title: "Starry Night", tip: "Count by twos: 2, 4, 6…", goal: .count(from: 2, step: 2, to: 12), clouds: 2,
                 skyTop: 0x1E2457, skyBottom: 0x4B3F8F, grass: 0x3E7D5A, soil: 0x5B4033, night: true, spring: 4),
        HopLevel(number: 7, title: "ABC Garden", tip: "Catch the letters in ABC order!", goal: .inOrder(["A", "B", "C", "D", "E", "F"]), clouds: 1,
                 skyTop: 0xFFE3A3, skyBottom: 0xFFF8E6, grass: 0x6CC36A, soil: 0x9C6B3F, spring: 3),
        HopLevel(number: 8, title: "Rocket Launch", tip: "Count down to blast off: 6, 5, 4…", goal: .count(from: 6, step: -1, to: 1), clouds: 1,
                 skyTop: 0x2B3A67, skyBottom: 0x7A8CC9, grass: 0x8A93A6, soil: 0x5C6273, night: true, spring: 0, bubbles: true),
        HopLevel(number: 9, title: "Adding Bay", tip: "Catch the answer to each sum!", goal: .math(add: true, rounds: 5), clouds: 1,
                 skyTop: 0x8FE0E8, skyBottom: 0xE9FBFF, grass: 0xF0D98C, soil: 0xCFA35E, bubbles: true),
        HopLevel(number: 10, title: "Tens Tower", tip: "Count by tens: 10, 20, 30…", goal: .count(from: 10, step: 10, to: 60), clouds: 2,
                 skyTop: 0xC7B8F5, skyBottom: 0xF3EEFF, grass: 0x7FBF7A, soil: 0x8B6A55, spring: 2, bubbles: true),
        HopLevel(number: 11, title: "Take-Away Tundra", tip: "Catch the answer to each take-away!", goal: .math(add: false, rounds: 5), clouds: 2,
                 skyTop: 0xBFDDF0, skyBottom: 0xFAFDFF, grass: 0xFFFFFF, soil: 0x9FB3C8, bubbles: true),
        HopLevel(number: 12, title: "Rainbow Castle", tip: "The last level! Catch 12 stars.", goal: .stars(12), clouds: 3,
                 skyTop: 0xFFB3C7, skyBottom: 0xC9F0FF, grass: 0x6FD08C, soil: 0xA77B5B, spring: 5, bubbles: true),
    ]

    /// Moves allowed for the "quick feet" star. In-order levels need a particular star, so they get more room.
    var par: Int { sequence.isEmpty ? goal * 3 + 2 : goal * 5 + 2 }

    /// Short words with no repeated letters, so every letter star is different.
    static let words = ["SUN", "CAT", "HOP", "DOG", "STAR", "FROG", "FISH", "KITE", "CAKE", "BIRD"]

    var level = 1
    /// Buddy position: column 0…5, row 0 (ground) … 2 (top).
    var col = StarHop.startCol
    var row = 0
    /// Jumps since leaving the ground (2 = double jump used).
    var jumps = 0
    var facingLeft = false
    var stars: [HopStar] = []
    /// Puff clouds, as cells. They only float in the sky rows.
    var clouds: [Int] = []
    /// Stars caught (star levels) or numbers/letters caught in order.
    var collected = 0
    /// The numbers or letters to catch in order ("1"…"6", or "C","A","T"). Empty on star levels.
    var sequence: [String] = []
    /// On adding and take-away levels, the question for each answer in `sequence` ("2 + 3").
    var prompts: [String] = []
    var hearts = StarHop.maxHearts
    var moves = 0
    /// Increases with every move, for repeatable star placement.
    var turn = 0
    var nextStarID = 0
    /// How many levels have been started, so the spelling word changes each time.
    var plays = 0
    /// Fewest moves for each level (0 = not finished yet), indexed by level − 1.
    var best: [Int] = Array(repeating: 0, count: StarHop.levels.count)
    /// The highest level finished.
    var levelsCleared = 0
    /// A word for the last move ("Jump!", "Double jump!", "Got it!").
    var message = "Tap to play!"
    /// The cell where a star was just caught (for the sparkle), and whether a cloud just bumped the buddy.
    var lastCatch: Int? = nil
    var bumped = false
    /// A bubble shield waiting on the board, whether the buddy has one on, and whether one just popped.
    var bubble: Int? = nil
    var shield = false
    var popped = false
    /// The spring just bounced the buddy up.
    var bounced = false
    /// Cloud bumps on this try (a bubble pop doesn't count).
    var bumps = 0
    /// Best rating for each level (0 = not finished), indexed by level − 1.
    var rating: [Int] = Array(repeating: 0, count: StarHop.levels.count)
    /// The rating just earned, shown on the "level done" card.
    var lastRating = 0

    init() { startLevel(1) }

    enum CodingKeys: String, CodingKey {
        case level, col, row, jumps, facingLeft, stars, clouds, collected, sequence, prompts, hearts, moves, turn, nextStarID, plays, best, levelsCleared, message, lastCatch, bumped, bubble, shield, popped, bounced, bumps, rating, lastRating
    }

    /// Older saves (from before a field existed) keep everything they have; new fields start at their defaults.
    init(from decoder: Decoder) throws {
        startLevel(1)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try? c.decodeIfPresent(Int.self, forKey: .level) { level = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .col) { col = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .row) { row = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .jumps) { jumps = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .facingLeft) { facingLeft = v }
        if let v = try? c.decodeIfPresent([HopStar].self, forKey: .stars) { stars = v }
        if let v = try? c.decodeIfPresent([Int].self, forKey: .clouds) { clouds = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .collected) { collected = v }
        if let v = try? c.decodeIfPresent([String].self, forKey: .sequence) { sequence = v }
        if let v = try? c.decodeIfPresent([String].self, forKey: .prompts) { prompts = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .hearts) { hearts = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .moves) { moves = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .turn) { turn = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .nextStarID) { nextStarID = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .plays) { plays = v }
        if let v = try? c.decodeIfPresent([Int].self, forKey: .best) { best = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .levelsCleared) { levelsCleared = v }
        if let v = try? c.decodeIfPresent(String.self, forKey: .message) { message = v }
        lastCatch = (try? c.decodeIfPresent(Int.self, forKey: .lastCatch)) ?? nil
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .bumped) { bumped = v }
        bubble = (try? c.decodeIfPresent(Int.self, forKey: .bubble)) ?? nil
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .shield) { shield = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .popped) { popped = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .bounced) { bounced = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .bumps) { bumps = v }
        if let v = try? c.decodeIfPresent([Int].self, forKey: .rating) { rating = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .lastRating) { lastRating = v }
        // the level list grew: pad the per-level lists, then rebuild a level that was saved under older rules
        if best.count < Self.levels.count { best += Array(repeating: 0, count: Self.levels.count - best.count) }
        if rating.count < Self.levels.count { rating += Array(repeating: 0, count: Self.levels.count - rating.count) }
        if (try? c.decodeIfPresent([Int].self, forKey: .rating)) == nil {
            let keepBest = best, keepCleared = levelsCleared, keepPlays = plays, keepLevel = level, keepTurn = turn, keepID = nextStarID
            startLevel(keepLevel)
            best = keepBest; levelsCleared = keepCleared; plays = keepPlays; turn = keepTurn; nextStarID = max(nextStarID, keepID)
            // levels finished before ratings existed count as one star each
            for i in 0..<min(keepCleared, rating.count) { rating[i] = max(rating[i], 1) }
        }
    }

    // MARK: Reading the state

    var info: HopLevel { Self.levels[max(0, min(Self.levels.count - 1, level - 1))] }
    var isFinalLevel: Bool { level == Self.levels.count }

    var goal: Int {
        if case .stars(let n) = info.goal { return n }
        return sequence.count
    }

    var levelDone: Bool { collected >= goal }
    var outOfHearts: Bool { hearts <= 0 && !levelDone }
    var playing: Bool { !levelDone && !outOfHearts }
    /// Every level finished.
    var champion: Bool { levelDone && isFinalLevel }

    /// The number or letter to catch next, on counting and spelling levels.
    var needed: String? { sequence.indices.contains(collected) ? sequence[collected] : nil }
    /// The spelling word, on the spelling level.
    var word: String? { info.goal == .spell ? sequence.joined() : nil }
    /// The question on adding and take-away levels.
    var prompt: String? { prompts.indices.contains(collected) ? prompts[collected] : nil }
    /// All the rating stars earned across levels (what the app turns into real stars).
    var totalRating: Int { rating.reduce(0, +) }
    /// A level can be picked once the one before it is finished.
    func canPick(_ n: Int) -> Bool { n >= 1 && n <= min(Self.levels.count, levelsCleared + 1) }

    func cell(_ c: Int, _ r: Int) -> Int { c + r * Self.columns }
    var buddyCell: Int { cell(col, row) }

    // MARK: Moves

    /// Tap on the left half: one step left (falling one row if in the air).
    mutating func left() {
        guard playing else { return }
        facingLeft = true
        col = (col + Self.columns - 1) % Self.columns
        if row > 0 { row -= 1 }
        if row == 0 { jumps = 0 }
        message = row == 0 ? "Step!" : "Whee!"
        afterMove()
    }

    /// Tap on the right half: jump up and right; in the air, a second tap is a double jump; after that you glide down.
    mutating func right() {
        guard playing else { return }
        facingLeft = false
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

    /// Start (or restart) a level. Keeps the bests and how far the player has got.
    mutating func startLevel(_ n: Int) {
        level = max(1, min(Self.levels.count, n))
        col = Self.startCol; row = 0; jumps = 0; facingLeft = false
        collected = 0; hearts = Self.maxHearts; moves = 0; bumps = 0
        lastCatch = nil; bumped = false; popped = false; bounced = false
        bubble = nil; shield = false; lastRating = 0
        stars = []
        prompts = []
        plays += 1
        switch info.goal {
        case .stars:
            sequence = []
        case .count(let from, let step, let to):
            sequence = stride(from: from, through: to, by: step).map(String.init)
        case .spell:
            sequence = Self.words[(plays - 1) % Self.words.count].map(String.init)
        case .inOrder(let list):
            sequence = list
        case .math(let add, let rounds):
            // a fresh, repeatable set of questions each try; answers 1…10, no answer twice in a row
            var seed = UInt64(truncatingIfNeeded: plays &* 40_503 &+ level &* 977)
            func roll(_ n: Int) -> Int {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Int((seed >> 33) % UInt64(n))
            }
            sequence = []
            while sequence.count < rounds {
                let a: Int, b: Int, answer: Int
                if add { a = 1 + roll(5); b = 1 + roll(5); answer = a + b }
                else { a = 3 + roll(8); b = 1 + roll(a - 1); answer = a - b }
                if sequence.last == String(answer) { continue }
                sequence.append(String(answer))
                prompts.append(add ? "\(a) + \(b)" : "\(a) − \(b)")
            }
        }
        // clouds start in the sky away from the buddy, one per sky row, then doubled up
        clouds = (0..<info.clouds).map { k in cell((Self.startCol + 3 + 2 * k) % Self.columns, 2 - (k % 2)) }
        message = info.tip
        refill()
    }

    /// Picks a level from the level list (only ones already reached).
    mutating func pick(_ n: Int) {
        guard canPick(n) else { return }
        startLevel(n)
    }

    /// After a level is finished: on to the next one (or back to the first after the last).
    mutating func nextLevel() {
        guard levelDone else { return }
        startLevel(isFinalLevel ? 1 : level + 1)
    }

    /// The wrong answers that can show up next to the right one.
    private var decoyPool: [String] {
        if case .math = info.goal { return (1...10).map(String.init) }
        return sequence
    }

    /// Try the same level again (after running out of hearts, or any time).
    mutating func retry() { startLevel(level) }

    /// Back to level 1 (keeps the bests and the levels reached).
    mutating func newGame() {
        startLevel(1)
        message = "New game! " + info.tip
    }

    // MARK: Rules

    private mutating func afterMove() {
        moves += 1
        turn += 1
        lastCatch = nil
        bumped = false
        popped = false
        bounced = false

        // 0. a spring pad bounces the buddy up to the top row
        if row == 0, let sp = info.spring, col == sp {
            row = Self.rows - 1; jumps = 2; bounced = true
            message = "Boing!"
        }

        // a bubble shield
        if bubble == buddyCell {
            bubble = nil; shield = true
            message = "Bubble shield! 🫧"
        }

        // 1. catch whatever star the buddy landed on
        if let i = stars.firstIndex(where: { $0.cell == buddyCell }) {
            let star = stars[i]
            if let label = star.label {
                if label == needed {
                    let asked = prompt
                    stars.remove(at: i)
                    collected += 1
                    lastCatch = star.cell
                    if let q = asked {
                        message = "\(q) = \(label)! ✓"
                    } else {
                        message = levelDone ? "" : "\(label)! Now find \(needed ?? "")."
                    }
                } else {
                    // a wrong number or letter just pops somewhere else, no harm done
                    stars.remove(at: i)
                    if let q = prompt {
                        message = "Not \(label). \(q) = ?"
                    } else {
                        message = "That's \(label). Find \(needed ?? "") first!"
                    }
                }
            } else {
                stars.remove(at: i)
                collected = min(goal, collected + (star.golden ? 2 : 1))
                lastCatch = star.cell
                message = star.golden ? "Golden star! +2" : "Got it! ⭐"
            }
        }

        if levelDone {
            let i = level - 1
            if best.count < Self.levels.count { best += Array(repeating: 0, count: Self.levels.count - best.count) }
            if best[i] == 0 || moves < best[i] { best[i] = moves }
            if rating.count < Self.levels.count { rating += Array(repeating: 0, count: Self.levels.count - rating.count) }
            lastRating = 1 + (bumps == 0 ? 1 : 0) + (moves <= par ? 1 : 0)
            rating[i] = max(rating[i], lastRating)
            levelsCleared = max(levelsCleared, level)
            bubble = nil
            message = isFinalLevel ? "You finished every level!" : "Level \(level) done!"
            stars = []
            return
        }

        // 2. puff clouds: bumping one costs a heart and drops the buddy to the safe ground
        if clouds.contains(buddyCell) {
            bump()
        } else {
            if turn % 2 == 0 { driftClouds() }
            if clouds.contains(buddyCell) { bump() }
        }
        if outOfHearts { message = "Out of hearts!"; return }

        // 3. stars drift down one row every third move, and wrap back to the top when they reach the ground
        if turn % 3 == 0 {
            for i in stars.indices {
                let r = stars[i].cell / Self.columns, c = stars[i].cell % Self.columns
                stars[i].cell = r == 0 ? cell(c, Self.rows - 1) : cell(c, r - 1)
            }
        }
        refill()
    }

    private mutating func bump() {
        if shield {
            // the bubble takes the bump instead
            shield = false; popped = true
            message = "Pop! Your bubble saved you."
            return
        }
        hearts -= 1
        bumps += 1
        bumped = true
        row = 0; jumps = 0
        message = hearts > 0 ? "Bonk! A puff cloud. 💨" : "Out of hearts!"
    }

    /// Even clouds float left, odd clouds float right, each staying in its own sky row.
    private mutating func driftClouds() {
        for k in clouds.indices {
            let r = clouds[k] / Self.columns, c = clouds[k] % Self.columns
            let dc = k % 2 == 0 ? Self.columns - 1 : 1
            clouds[k] = cell((c + dc) % Self.columns, r)
        }
    }

    /// Keeps two stars on the board, never on the buddy or a cloud.
    /// On counting and spelling levels one of them is always the one needed next, the other a different one.
    private mutating func refill() {
        guard !levelDone else { return }
        var seed = UInt64(truncatingIfNeeded: turn &* 2_654_435_761 &+ collected &* 97 &+ level &* 7919 &+ nextStarID &* 31)
        func roll(_ n: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(n))
        }
        let size = Self.columns * Self.rows
        // never on the buddy, a cloud, another star, the bubble, or the spring pad (it would bounce you away)
        let springCell = info.spring.map { cell($0, 0) }
        func isFree(_ c: Int) -> Bool {
            c != buddyCell && !clouds.contains(c) && !stars.contains(where: { $0.cell == c }) && c != bubble && c != springCell
        }
        func freeCell() -> Int {
            for _ in 0..<64 {
                let pick = roll(size)
                    if isFree(pick) { return pick }
            }
            // fall back to the first free cell
            return (0..<size).first { isFree($0) } ?? 0
        }

        if let want = needed {
            if !stars.contains(where: { $0.label == want }) {
                stars.append(HopStar(id: nextStarID, cell: freeCell(), label: want)); nextStarID += 1
            }
            while stars.count < 2 {
                let others = decoyPool.filter { $0 != want && !stars.map(\.label).contains($0) }
                guard !others.isEmpty else { break }
                stars.append(HopStar(id: nextStarID, cell: freeCell(), label: others[roll(others.count)])); nextStarID += 1
            }
        } else {
            while stars.count < 2 {
                // from level 2 every fourth star is golden
                let golden = level >= 2 && nextStarID % 4 == 3
                stars.append(HopStar(id: nextStarID, cell: freeCell(), golden: golden)); nextStarID += 1
            }
        }
        // now and then a bubble shield floats in (one at a time, and not while wearing one)
        if info.bubbles && bubble == nil && !shield && turn % 7 == 6 {
            bubble = freeCell()
        }
    }
}
