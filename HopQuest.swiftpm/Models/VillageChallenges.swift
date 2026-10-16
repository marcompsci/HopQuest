import Foundation

/// The nine Hop Village challenges. Finish them all and the castle gate opens.
/// "Done" is read from the progress each game already saves; nothing is stored twice.
enum VillageChallenge: String, CaseIterable, Codable {
    case meadow, driving, robot, lily, rally, castleHill, fort, bop, kart

    var building: BuildingKind {
        switch self {
        case .meadow: return .cottage
        case .driving: return .academy
        case .robot: return .workshop
        case .lily: return .boathouse
        case .rally: return .garage
        case .castleHill: return .tower
        case .fort: return .fortYard
        case .bop: return .arena
        case .kart: return .stadium
        }
    }

    var title: String { building.title }

    var icon: String {
        switch self {
        case .meadow: return "🐾"
        case .driving: return "🚗"
        case .robot: return "🤖"
        case .lily: return "🪷"
        case .rally: return "🏁"
        case .castleHill: return "🏰"
        case .fort: return "🧱"
        case .bop: return "🪶"
        case .kart: return "🏎️"
        }
    }

    /// What to do, in kid words.
    var goal: String {
        switch self {
        case .meadow, .lily, .castleHill: return "Hop all the way to the castle"
        case .driving, .rally: return "Finish the drive safely"
        case .robot: return "Build your robot"
        case .fort: return "Reach the fort in any level"
        case .bop: return "Play a whole Pillow Bop match"
        case .kart: return "Finish any Bubble Kart cup"
        }
    }

    /// The story chapter behind this challenge, if it's one.
    var chapter: Int? { building.storyChapter }

    func isDone(_ p: ChallengeProgress) -> Bool {
        switch self {
        case .fort: return p.fortDone
        case .bop: return p.bopDone
        case .kart: return p.kartDone
        default: return chapter.map { p.completedChapters.contains($0) } ?? false
        }
    }
}

/// A snapshot of the progress the challenges read.
struct ChallengeProgress: Equatable {
    var completedChapters: Set<Int> = []
    var fortDone = false
    var bopDone = false
    var kartDone = false

    var done: [VillageChallenge] { VillageChallenge.allCases.filter { $0.isDone(self) } }
    var doneCount: Int { done.count }
    static var total: Int { VillageChallenge.allCases.count }
    var allDone: Bool { doneCount == Self.total }
}
