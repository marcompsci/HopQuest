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

    enum CodingKeys: String, CodingKey {
        case name, identity, theme, characterID, stars, completedChapters, breakReminderMinutes, narration, coopCharacterID, kartBest
        case stickers, packsOpened, lifetimeStars, bopBest, fortBest
        case codeBest, brainAnswered, brainFirstTry
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

    /// Counts a solved Brain Gate for the grown-ups' Learning Report.
    func recordAnswer(subject: String, firstTry: Bool) {
        guard var p = profile else { return }
        p.brainAnswered[subject, default: 0] += 1
        if firstTry { p.brainFirstTry[subject, default: 0] += 1 }
        profile = p
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
        if let profile, let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
