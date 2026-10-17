import CoreGraphics

enum ChapterKind {
    case hop, drive, robot, kart
}

struct Chapter: Identifiable, Equatable {
    let id: Int
    let title: String
    let kind: ChapterKind
    let icon: String
    /// Hop levels: number of rows to the castle, and how often a Brain Gate appears.
    let rows: Int
    let gateEvery: Int
    /// Drive levels: road length in points.
    let trackLength: CGFloat
    /// 0 = easiest, 1 = hardest.
    let difficulty: CGFloat
    /// Position on the world map, 0...1 of the screen.
    let mapX: CGFloat
    let mapY: CGFloat
    /// How a hop level looks (worlds from data, like Snowy Peaks). nil = the classic meadow look.
    var style: HopStyle? = nil
}

enum Chapters {
    static let all: [Chapter] = [
        Chapter(id: 1, title: "Meadow Street", kind: .hop, icon: "🐾", rows: 24, gateEvery: 8, trackLength: 0, difficulty: 0.0, mapX: 0.30, mapY: 0.765),
        Chapter(id: 2, title: "Driving School", kind: .drive, icon: "🚗", rows: 0, gateEvery: 0, trackLength: 4200, difficulty: 0.0, mapX: 0.70, mapY: 0.685),
        Chapter(id: 3, title: "Robot Lab", kind: .robot, icon: "🤖", rows: 0, gateEvery: 0, trackLength: 0, difficulty: 0.0, mapX: 0.30, mapY: 0.60),
        Chapter(id: 4, title: "Lily River", kind: .hop, icon: "🪷", rows: 32, gateEvery: 8, trackLength: 0, difficulty: 0.45, mapX: 0.70, mapY: 0.515),
        Chapter(id: 5, title: "City Rally", kind: .drive, icon: "🏁", rows: 0, gateEvery: 0, trackLength: 6000, difficulty: 0.5, mapX: 0.30, mapY: 0.43),
        Chapter(id: 6, title: "Castle Hill", kind: .hop, icon: "🏰", rows: 40, gateEvery: 10, trackLength: 0, difficulty: 0.85, mapX: 0.72, mapY: 0.35),
    ]

    /// Grown-up & Me levels. Not on the map path and never locked; they don't change story progress.
    static let teamHop = Chapter(id: 101, title: "Team Hop", kind: .hop, icon: "🤝", rows: 30, gateEvery: 10, trackLength: 0, difficulty: 0.3, mapX: 0, mapY: 0)
    static let teamDrive = Chapter(id: 102, title: "Team Drive", kind: .drive, icon: "🚙", rows: 0, gateEvery: 0, trackLength: 5000, difficulty: 0.3, mapX: 0, mapY: 0)
    static let team: [Chapter] = [teamHop, teamDrive]

    /// Bubble Kart cups. Always open; they earn stars but don't change story progress.
    static let kartCups: [Chapter] = [
        Chapter(id: 201, title: "Meadow Loop", kind: .kart, icon: "🌼", rows: 0, gateEvery: 0, trackLength: 7000, difficulty: 0.0, mapX: 0, mapY: 0),
        Chapter(id: 202, title: "Candy City", kind: .kart, icon: "🍭", rows: 0, gateEvery: 0, trackLength: 8000, difficulty: 0.4, mapX: 0, mapY: 0),
        Chapter(id: 203, title: "Castle Circuit", kind: .kart, icon: "🏰", rows: 0, gateEvery: 0, trackLength: 9000, difficulty: 0.8, mapX: 0, mapY: 0),
        // Bubble Kart 2 (v3.6): jump ramps, and slush or sand instead of mud
        Chapter(id: 204, title: "Snowy Slalom", kind: .kart, icon: "⛷️", rows: 0, gateEvery: 0, trackLength: 8500, difficulty: 0.55, mapX: 0, mapY: 0),
        Chapter(id: 205, title: "Beach Boardwalk", kind: .kart, icon: "🏖️", rows: 0, gateEvery: 0, trackLength: 9000, difficulty: 0.7, mapX: 0, mapY: 0),
    ]

    static func chapter(_ id: Int) -> Chapter {
        (all + team + kartCups + Worlds.chapters).first { $0.id == id } ?? all[0]
    }

    /// A chapter from a data world (Snowy Peaks and later).
    static func isWorldChapter(_ id: Int) -> Bool {
        Worlds.world(containing: id) != nil
    }

    static func isStory(_ id: Int) -> Bool {
        all.contains { $0.id == id }
    }

    static func isTeam(_ id: Int) -> Bool {
        team.contains { $0.id == id }
    }
}
