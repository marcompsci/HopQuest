import Foundation

/// Everything Hop Village remembers, stored inside PlayerProfile (on this device only).
/// Every field decodes with a default, so saves from before the village (and future versions) keep loading.
struct VillageSaveState: Codable, Equatable {
    static let currentVersion = 1

    var version: Int = VillageSaveState.currentVersion
    /// Last tile the buddy stood on (the doorstep when they went inside somewhere).
    var tileX: Int = 20
    var tileY: Int = 22
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

    init() {}

    var tile: GridPoint {
        get { GridPoint(tileX, tileY) }
        set { tileX = newValue.c; tileY = newValue.r }
    }

    enum CodingKeys: String, CodingKey {
        case version, tileX, tileY, facing, visited, talkedTo, solved, lightEffects, eveningLights, startInVillage
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? VillageSaveState.currentVersion
        tileX = (try? c.decodeIfPresent(Int.self, forKey: .tileX)) ?? 20
        tileY = (try? c.decodeIfPresent(Int.self, forKey: .tileY)) ?? 22
        facing = (try? c.decodeIfPresent(Facing.self, forKey: .facing)) ?? .south
        visited = (try? c.decodeIfPresent(Set<String>.self, forKey: .visited)) ?? []
        talkedTo = (try? c.decodeIfPresent(Set<String>.self, forKey: .talkedTo)) ?? []
        solved = (try? c.decodeIfPresent(Set<String>.self, forKey: .solved)) ?? []
        lightEffects = (try? c.decodeIfPresent(Bool.self, forKey: .lightEffects)) ?? false
        eveningLights = (try? c.decodeIfPresent(Bool.self, forKey: .eveningLights)) ?? true
        startInVillage = (try? c.decodeIfPresent(Bool.self, forKey: .startInVillage)) ?? false
    }

    /// A safe tile to start on: the saved one if it's still walkable, otherwise the Village Square.
    func safeSpawn(in map: VillageMap) -> GridPoint {
        map.isWalkable(tile) ? tile : map.spawn
    }
}
