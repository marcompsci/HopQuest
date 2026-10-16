import SwiftUI

/// What the child picked during onboarding. Used ONLY to pre-select a castle style
/// and a "Picked for you" character row. Every castle and character stays open to every kid.
enum KidIdentity: String, Codable, CaseIterable, Identifiable {
    case girl, boy, noAnswer
    var id: String { rawValue }

    var label: String {
        switch self {
        case .girl: return "Girl"
        case .boy: return "Boy"
        case .noAnswer: return "I'd rather not say"
        }
    }

    var emoji: String {
        switch self {
        case .girl: return "👧"
        case .boy: return "👦"
        case .noAnswer: return "🌈"
        }
    }

    var suggestedTheme: CastleTheme {
        switch self {
        case .girl: return .sparkle
        case .boy: return .fortress
        case .noAnswer: return .rainbow
        }
    }
}

/// The castle style at every finish line, on the map, and on the balloon.
enum CastleTheme: String, Codable, CaseIterable, Identifiable {
    case sparkle, fortress, rainbow
    var id: String { rawValue }

    var title: String {
        switch self {
        case .sparkle: return "Sparkle Castle"
        case .fortress: return "Stone Fortress"
        case .rainbow: return "Rainbow Castle"
        }
    }

    var wallHex: UInt32 {
        switch self {
        case .sparkle: return 0xFFD6EC
        case .fortress: return 0xB8C4D6
        case .rainbow: return 0xFFF4C2
        }
    }

    var roofHex: UInt32 {
        switch self {
        case .sparkle: return 0xC77DFF
        case .fortress: return 0x3B5BA5
        case .rainbow: return 0x3CC9A0
        }
    }

    var accentHex: UInt32 {
        switch self {
        case .sparkle: return 0xFF7FC4
        case .fortress: return 0xF2B134
        case .rainbow: return 0xFF7A59
        }
    }

    var skyHex: [UInt32] {
        switch self {
        case .sparkle: return [0xFFE4F3, 0xE9D5FF]
        case .fortress: return [0xCDEBFF, 0x9CC9F5]
        case .rainbow: return [0xD8F7FF, 0xFFF0C9]
        }
    }

    var flag: String {
        switch self {
        case .sparkle: return "💖"
        case .fortress: return "🛡️"
        case .rainbow: return "🌈"
        }
    }

    var deco: String {
        switch self {
        case .sparkle: return "✨"
        case .fortress: return "⭐"
        case .rainbow: return "🌟"
        }
    }

    var wall: Color { Color(hex: wallHex) }
    var roof: Color { Color(hex: roofHex) }
    var accent: Color { Color(hex: accentHex) }
    var sky: [Color] { skyHex.map { Color(hex: $0) } }
}

/// One piece of furniture placed in My Castle. Position is 0...1 of the room.
struct DecorPlacement: Codable, Equatable, Identifiable {
    var id = UUID()
    var item: String
    var x: Double
    var y: Double
    var flipped = false
}

/// Who the Brain Gate questions are pitched at. Auto starts in the middle and adjusts.
enum LearnerTier: Int, Codable, CaseIterable, Identifiable {
    case auto = 0, little = 1, middle = 2, big = 3
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .auto: return "Automatic"
        case .little: return "Little learner (4–5)"
        case .middle: return "Growing learner (6–7)"
        case .big: return "Big learner (8–10)"
        }
    }
}

struct PlayerProfile: Codable, Equatable {
    var name: String
    var identity: KidIdentity
    var theme: CastleTheme
    var characterID: String
    var stars: Int = 0
    var completedChapters: Set<Int> = []
    /// 0 = off. Grown-ups change this behind the parent gate.
    var breakReminderMinutes: Int = 30
    /// Read questions, tips, and lessons out loud.
    var narration: Bool = true
    /// The grown-up's character in Grown-up & Me mode.
    var coopCharacterID: String? = nil
    /// Best finishing place per Bubble Kart cup (1 = first).
    var kartBest: [Int: Int] = [:]
    /// Sticker Book: buddies collected from sticker packs.
    var stickers: Set<String> = []
    var packsOpened: Int = 0
    /// Every star ever earned (resetting progress doesn't take sticker packs away).
    var lifetimeStars: Int = 0
    /// Best Pillow Bop score.
    var bopBest: Int = 0
    /// Most balloons found per Fort Friends level.
    var fortBest: [Int: Int] = [:]
    /// Best stars per Code Club puzzle.
    var codeBest: [Int: Int] = [:]
    /// Brain Gate questions answered, and answered on the first try, by subject.
    var brainAnswered: [String: Int] = [:]
    var brainFirstTry: [String: Int] = [:]
    /// The last few Brain Gates (true = right on the first try), used to adjust difficulty.
    var recentFirstTry: [Bool] = []
    var learnerTier: LearnerTier = .auto
    /// My Castle: furniture you own, where it's placed, and the wall color.
    var decorOwned: Set<String> = ["decor_rug", "decor_plant"]
    var decorPlaced: [DecorPlacement] = []
    var wallpaper: Int = 0
    /// Buddies invited to hang out in My Castle (besides your own).
    var castleGuests: [String] = []
    /// Daily play limit in minutes (0 = off), and today's play time.
    var dailyLimitMinutes: Int = 0
    var playDay: String = ""
    var playedSeconds: Int = 0
    /// Hop Village: where the buddy is standing, who they've met, and village settings.
    var village = VillageSaveState()

    enum CodingKeys: String, CodingKey {
        case name, identity, theme, characterID, stars, completedChapters, breakReminderMinutes, narration, coopCharacterID, kartBest
        case stickers, packsOpened, lifetimeStars, bopBest, fortBest
        case codeBest, brainAnswered, brainFirstTry
        case recentFirstTry, learnerTier, decorOwned, decorPlaced, wallpaper, castleGuests
        case dailyLimitMinutes, playDay, playedSeconds
        case village
    }
}

extension PlayerProfile {
    /// Tolerates saves from older versions that are missing newer fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        identity = try c.decode(KidIdentity.self, forKey: .identity)
        theme = try c.decode(CastleTheme.self, forKey: .theme)
        characterID = try c.decode(String.self, forKey: .characterID)
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        completedChapters = try c.decodeIfPresent(Set<Int>.self, forKey: .completedChapters) ?? []
        breakReminderMinutes = try c.decodeIfPresent(Int.self, forKey: .breakReminderMinutes) ?? 30
        narration = try c.decodeIfPresent(Bool.self, forKey: .narration) ?? true
        coopCharacterID = try c.decodeIfPresent(String.self, forKey: .coopCharacterID)
        kartBest = try c.decodeIfPresent([Int: Int].self, forKey: .kartBest) ?? [:]
        stickers = try c.decodeIfPresent(Set<String>.self, forKey: .stickers) ?? []
        packsOpened = try c.decodeIfPresent(Int.self, forKey: .packsOpened) ?? 0
        lifetimeStars = try c.decodeIfPresent(Int.self, forKey: .lifetimeStars) ?? stars
        bopBest = try c.decodeIfPresent(Int.self, forKey: .bopBest) ?? 0
        fortBest = try c.decodeIfPresent([Int: Int].self, forKey: .fortBest) ?? [:]
        codeBest = try c.decodeIfPresent([Int: Int].self, forKey: .codeBest) ?? [:]
        brainAnswered = try c.decodeIfPresent([String: Int].self, forKey: .brainAnswered) ?? [:]
        brainFirstTry = try c.decodeIfPresent([String: Int].self, forKey: .brainFirstTry) ?? [:]
        recentFirstTry = try c.decodeIfPresent([Bool].self, forKey: .recentFirstTry) ?? []
        learnerTier = try c.decodeIfPresent(LearnerTier.self, forKey: .learnerTier) ?? .auto
        decorOwned = try c.decodeIfPresent(Set<String>.self, forKey: .decorOwned) ?? ["decor_rug", "decor_plant"]
        decorPlaced = try c.decodeIfPresent([DecorPlacement].self, forKey: .decorPlaced) ?? []
        wallpaper = try c.decodeIfPresent(Int.self, forKey: .wallpaper) ?? 0
        castleGuests = try c.decodeIfPresent([String].self, forKey: .castleGuests) ?? []
        dailyLimitMinutes = try c.decodeIfPresent(Int.self, forKey: .dailyLimitMinutes) ?? 0
        playDay = try c.decodeIfPresent(String.self, forKey: .playDay) ?? ""
        playedSeconds = try c.decodeIfPresent(Int.self, forKey: .playedSeconds) ?? 0
        // Saves from before Hop Village have no village block; a damaged one never blocks the rest of the save.
        village = (try? c.decodeIfPresent(VillageSaveState.self, forKey: .village)) ?? VillageSaveState()
    }
}

enum ChapterState { case locked, open, done }

/// Everything is saved on this device only (UserDefaults). No accounts, no network, no analytics.
/// Only touched from the UI / SpriteKit main thread.
final class GameStore: ObservableObject {
    @Published var profile: PlayerProfile? {
        didSet { persist() }
    }

    private let key = "hopquest.profile.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = saved
        }
        Narrator.shared.enabled = profile?.narration ?? true
        QuestionBank.tier = effectiveTier
    }

    var theme: CastleTheme { profile?.theme ?? .rainbow }

    var character: GameCharacter {
        Roster.character(id: profile?.characterID ?? Roster.all[0].id)
    }

    /// The grown-up's buddy in Grown-up & Me. Defaults to someone different from the kid's.
    var coopCharacter: GameCharacter {
        if let id = profile?.coopCharacterID { return Roster.character(id: id) }
        let fallback = character.id == "pixelpup" ? "pip" : "pixelpup"
        return Roster.character(id: fallback)
    }

    func recordKart(cup: Int, place: Int) {
        guard var p = profile else { return }
        if let best = p.kartBest[cup], best <= place { return }
        p.kartBest[cup] = place
        profile = p
    }

    func addStars(_ n: Int) {
        guard n > 0, var p = profile else { return }
        p.stars += n
        p.lifetimeStars += n
        profile = p
    }

    func recordCode(challenge: Int, stars: Int) {
        guard var p = profile, stars > (p.codeBest[challenge] ?? 0) else { return }
        p.codeBest[challenge] = stars
        profile = p
    }

    /// Counts a solved Brain Gate for the grown-ups' Learning Report, and feeds difficulty tuning.
    func recordAnswer(subject: String, firstTry: Bool) {
        guard var p = profile else { return }
        p.brainAnswered[subject, default: 0] += 1
        if firstTry { p.brainFirstTry[subject, default: 0] += 1 }
        p.recentFirstTry.append(firstTry)
        if p.recentFirstTry.count > 12 { p.recentFirstTry.removeFirst(p.recentFirstTry.count - 12) }
        profile = p
    }

    // MARK: Learning level

    /// The level questions are actually pitched at right now (1 little, 2 middle, 3 big).
    var effectiveTier: Int {
        guard let p = profile else { return 2 }
        let base = p.learnerTier == .auto ? 2 : p.learnerTier.rawValue
        let recent = p.recentFirstTry
        guard recent.count >= 8 else { return base }
        let rate = Double(recent.filter { $0 }.count) / Double(recent.count)
        if rate >= 0.85 { return min(3, base + 1) }
        if rate <= 0.45 { return max(1, base - 1) }
        return base
    }

    /// For the Learning Report: is the game nudging questions up or down?
    var tierNote: String {
        let names = [1: "Little (4–5)", 2: "Growing (6–7)", 3: "Big (8–10)"]
        let base = (profile?.learnerTier ?? .auto) == .auto ? 2 : (profile?.learnerTier.rawValue ?? 2)
        let now = effectiveTier
        let name = names[now] ?? ""
        if now > base { return "\(name), stepped up because they're acing it" }
        if now < base { return "\(name), eased down to build confidence" }
        return name
    }

    // MARK: My Castle

    static let decorPrices: [String: Int] = [
        "decor_rug": 0, "decor_plant": 0, "decor_lamp": 3, "decor_painting": 3, "decor_balloons": 3,
        "decor_beanbag": 4, "decor_toybox": 4, "decor_banner": 4, "decor_bookshelf": 5, "decor_cake": 5,
        "decor_bed": 6, "decor_aquarium": 7, "decor_telescope": 7, "decor_rocket": 8, "decor_piano": 9,
        "decor_trophy": 10
    ]

    /// Spend stars on a decoration. Returns false if there aren't enough.
    func buyDecor(_ item: String) -> Bool {
        guard var p = profile, !p.decorOwned.contains(item) else { return false }
        let price = Self.decorPrices[item] ?? 5
        guard p.stars >= price else { return false }
        p.stars -= price
        p.decorOwned.insert(item)
        profile = p
        return true
    }

    // MARK: Daily play limit

    private static let dayFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Adds play time for today (resets at midnight). Returns true when today's limit is used up.
    @discardableResult
    func addPlayTime(_ seconds: Int) -> Bool {
        guard var p = profile else { return false }
        let today = Self.dayFormat.string(from: Date())
        if p.playDay != today {
            p.playDay = today
            p.playedSeconds = 0
        }
        p.playedSeconds += seconds
        profile = p
        return timeIsUp
    }

    var timeIsUp: Bool {
        guard let p = profile, p.dailyLimitMinutes > 0 else { return false }
        return p.playDay == Self.dayFormat.string(from: Date()) && p.playedSeconds >= p.dailyLimitMinutes * 60
    }

    /// A grown-up grants a little more time today.
    func grantExtraTime(minutes: Int) {
        guard var p = profile else { return }
        p.playedSeconds = max(0, p.playedSeconds - minutes * 60)
        profile = p
    }

    // MARK: Hop Village

    /// Changes the village save block (only writes when something actually changed).
    func updateVillage(_ change: (inout VillageSaveState) -> Void) {
        guard var p = profile else { return }
        var v = p.village
        change(&v)
        guard v != p.village else { return }
        p.village = v
        profile = p
    }

    /// A village buddy's riddle was solved. Returns true (and gives one star) only the first time ever.
    @discardableResult
    func solveVillageRiddle(_ npcID: String) -> Bool {
        guard var p = profile, !p.village.solved.contains(npcID) else { return false }
        p.village.solved.insert(npcID)
        p.stars += 1
        p.lifetimeStars += 1
        profile = p
        return true
    }

    /// The nine village challenges, read from what each game already saves.
    var challengeProgress: ChallengeProgress {
        guard let p = profile else { return ChallengeProgress() }
        return ChallengeProgress(completedChapters: p.completedChapters,
                                 fortDone: !p.fortBest.isEmpty,
                                 bopDone: p.bopBest > 0,
                                 kartDone: !p.kartBest.isEmpty)
    }

    /// My Castle opens once every challenge is done.
    var castleOpen: Bool { challengeProgress.allDone }

    /// Bonus stars from the pop-quiz buddy (capped per day). Returns how many were given.
    @discardableResult
    func grantVillageBonus(_ n: Int) -> Int {
        guard var p = profile else { return 0 }
        let given = p.village.grantBonus(n, day: Self.dayFormat.string(from: Date()))
        p.stars += given
        p.lifetimeStars += given
        profile = p
        return given
    }

    /// Stars from a Brain Duel (capped per day). Returns how many were given.
    @discardableResult
    func grantDuelStars(_ n: Int) -> Int {
        guard var p = profile else { return 0 }
        let given = p.village.grantDuelStars(n, day: Self.dayFormat.string(from: Date()))
        p.stars += given
        p.lifetimeStars += given
        profile = p
        return given
    }

    /// Can this story chapter be played now (open or already done)?
    func isPlayable(_ chapterID: Int) -> Bool {
        state(of: Chapters.chapter(chapterID)) != .locked
    }

    func recordFort(level: Int, balloons: Int) {
        guard var p = profile, balloons > (p.fortBest[level] ?? -1) else { return }
        p.fortBest[level] = balloons
        profile = p
    }

    func recordBop(_ bops: Int) {
        guard var p = profile, bops > p.bopBest else { return }
        p.bopBest = bops
        profile = p
    }

    // MARK: Sticker Book

    /// Stars needed for each sticker pack.
    static let starsPerPack = 6

    /// Your own buddy is always in the book.
    var ownedStickers: Set<String> {
        var s = profile?.stickers ?? []
        if let id = profile?.characterID { s.insert(id) }
        return s
    }

    var packsAvailable: Int {
        guard let p = profile else { return 0 }
        let locked = Roster.all.count - ownedStickers.count
        return max(0, min(p.lifetimeStars / Self.starsPerPack - p.packsOpened, locked))
    }

    /// Stars still needed for the next pack.
    var starsToNextPack: Int {
        let earned = profile?.lifetimeStars ?? 0
        return Self.starsPerPack - earned % Self.starsPerPack
    }

    /// Opens one pack and returns the new buddy sticker.
    func openPack() -> GameCharacter? {
        guard packsAvailable > 0, var p = profile else { return nil }
        let owned = ownedStickers
        guard let pick = Roster.all.filter({ !owned.contains($0.id) }).randomElement() else { return nil }
        p.stickers.insert(pick.id)
        p.packsOpened += 1
        profile = p
        return pick
    }

    var nextChapterID: Int {
        let done = profile?.completedChapters ?? []
        return Chapters.all.first { !done.contains($0.id) }?.id ?? Chapters.all.last!.id
    }

    func state(of chapter: Chapter) -> ChapterState {
        if profile?.completedChapters.contains(chapter.id) == true { return .done }
        return chapter.id == nextChapterID ? .open : .locked
    }

    func complete(chapter: Int, stars earned: Int) {
        guard var p = profile else { return }
        p.completedChapters.insert(chapter)
        p.stars += earned
        p.lifetimeStars += earned
        profile = p
    }

    func resetProgress() {
        guard var p = profile else { return }
        p.completedChapters = []
        p.stars = 0
        profile = p
    }

    func startOver() {
        profile = nil
    }

    private func persist() {
        Narrator.shared.enabled = profile?.narration ?? true
        QuestionBank.tier = effectiveTier
        if let profile, let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
