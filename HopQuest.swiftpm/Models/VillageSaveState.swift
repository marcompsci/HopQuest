import Foundation

/// Who a child may play with live in Hop Village. Grown-ups choose this behind the parent gate.
enum VillagePlayMode: String, Codable, CaseIterable {
    case off, nearby, friends

    var label: String {
        switch self {
        case .off: return "Off"
        case .nearby: return "Nearby only"
        case .friends: return "Game Center friends"
        }
    }
}

/// Everything Hop Village remembers, stored inside PlayerProfile (on this device only).
/// Every field decodes with a default, so saves from before the village (and future versions) keep loading.
struct VillageSaveState: Codable, Equatable {
    /// 2 = the bigger map with a building for every game.
    static let currentVersion = 2

    var version: Int = VillageSaveState.currentVersion
    /// Last tile the buddy stood on (the doorstep when they went inside somewhere).
    var tileX: Int = 22
    var tileY: Int = 23
    var facing: Facing = .south
    /// Places the child has visited and buddies they've talked to (for little "first visit" moments).
    var visited: Set<String> = []
    var talkedTo: Set<String> = []
    /// Buddies whose riddle was solved. The first solve gives one star, once ever (no daily resets).
    var solved: Set<String> = []
    /// Grown-ups' setting: lighter effects for older phones.
    var lightEffects: Bool = false
    /// Evening lighting and fireflies follow the clock.
    var eveningLights: Bool = true
    /// Open the app in the village instead of the world map.
    var startInVillage: Bool = false
    /// The castle-opening celebration has played.
    var castleCelebrated: Bool = false
    /// Bonus stars from the pop-quiz buddy and Brain Duels, capped per day (no streaks, nothing carries over).
    var bonusDay: String = ""
    var bonusToday: Int = 0
    var duelDay: String = ""
    var duelStarsToday: Int = 0
    /// Rotates the pop-quiz questions.
    var popTurn: Int = 0
    var playMode: VillagePlayMode = .off
    /// The festival the child picked on the notice board (nil = this week's festival).
    var festivalPick: String?
    /// The child's house on the hill.
    var home = HomeStyle()
    /// Grown-ups' setting: seasons and weather follow the calendar (off = always a sunny spring day).
    var seasons: Bool = true

    static let bonusPerDay = 5
    static let duelStarsPerDay = 6

    init() {}

    var tile: GridPoint {
        get { GridPoint(tileX, tileY) }
        set { tileX = newValue.c; tileY = newValue.r }
    }

    enum CodingKeys: String, CodingKey {
        case version, tileX, tileY, facing, visited, talkedTo, solved, lightEffects, eveningLights, startInVillage
        case castleCelebrated, bonusDay, bonusToday, duelDay, duelStarsToday, popTurn, playMode
        case festivalPick, home, seasons
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? VillageSaveState.currentVersion
        tileX = (try? c.decodeIfPresent(Int.self, forKey: .tileX)) ?? 22
        tileY = (try? c.decodeIfPresent(Int.self, forKey: .tileY)) ?? 23
        facing = (try? c.decodeIfPresent(Facing.self, forKey: .facing)) ?? .south
        visited = (try? c.decodeIfPresent(Set<String>.self, forKey: .visited)) ?? []
        talkedTo = (try? c.decodeIfPresent(Set<String>.self, forKey: .talkedTo)) ?? []
        solved = (try? c.decodeIfPresent(Set<String>.self, forKey: .solved)) ?? []
        lightEffects = (try? c.decodeIfPresent(Bool.self, forKey: .lightEffects)) ?? false
        eveningLights = (try? c.decodeIfPresent(Bool.self, forKey: .eveningLights)) ?? true
        startInVillage = (try? c.decodeIfPresent(Bool.self, forKey: .startInVillage)) ?? false
        castleCelebrated = (try? c.decodeIfPresent(Bool.self, forKey: .castleCelebrated)) ?? false
        bonusDay = (try? c.decodeIfPresent(String.self, forKey: .bonusDay)) ?? ""
        bonusToday = (try? c.decodeIfPresent(Int.self, forKey: .bonusToday)) ?? 0
        duelDay = (try? c.decodeIfPresent(String.self, forKey: .duelDay)) ?? ""
        duelStarsToday = (try? c.decodeIfPresent(Int.self, forKey: .duelStarsToday)) ?? 0
        popTurn = (try? c.decodeIfPresent(Int.self, forKey: .popTurn)) ?? 0
        playMode = (try? c.decodeIfPresent(VillagePlayMode.self, forKey: .playMode)) ?? .off
        festivalPick = try? c.decodeIfPresent(String.self, forKey: .festivalPick)
        home = (try? c.decodeIfPresent(HomeStyle.self, forKey: .home)) ?? HomeStyle()
        seasons = (try? c.decodeIfPresent(Bool.self, forKey: .seasons)) ?? true
        // Saves from the first, smaller village: the old spot means something else on the new map.
        if version < 2 {
            tileX = 22
            tileY = 23
            facing = .south
            version = VillageSaveState.currentVersion
        }
    }

    /// Grants up to `wanted` capped stars for `day`. Returns how many were actually given.
    mutating func grantBonus(_ wanted: Int, day: String) -> Int {
        if bonusDay != day { bonusDay = day; bonusToday = 0 }
        let n = max(0, min(wanted, Self.bonusPerDay - bonusToday))
        bonusToday += n
        return n
    }

    mutating func grantDuelStars(_ wanted: Int, day: String) -> Int {
        if duelDay != day { duelDay = day; duelStarsToday = 0 }
        let n = max(0, min(wanted, Self.duelStarsPerDay - duelStarsToday))
        duelStarsToday += n
        return n
    }

    /// A safe tile to start on: the saved one if it's still walkable, otherwise the Village Square.
    func safeSpawn(in map: VillageMap) -> GridPoint {
        map.isWalkable(tile) ? tile : map.spawn
    }
}
