import Foundation

/// Something the child can do right where they're standing.
enum VillageInteraction: Equatable {
    case talk(npcID: String)
    case enter(BuildingKind)
    case portal(Int)
}

enum InteractionFinder {
    static let talkRange = 1.5
    static let doorRange = 0.95
    static let portalRange = 1.05

    /// The closest thing in reach. Buddies win ties because they move and a chat is quick.
    static func find(player: VPoint, npcs: [(id: String, position: VPoint)], map: VillageMap) -> VillageInteraction? {
        var best: (VillageInteraction, Double)?
        func consider(_ i: VillageInteraction, _ d: Double, _ range: Double) {
            guard d <= range else { return }
            if best == nil || d < best!.1 { best = (i, d) }
        }
        for npc in npcs {
            consider(.talk(npcID: npc.id), player.distance(to: npc.position) - 0.2, talkRange)
        }
        for b in map.buildings where b.kind.hasDoor {
            consider(.enter(b.kind), player.distance(to: b.doorstep.center), doorRange)
        }
        for p in map.portals {
            consider(.portal(p.number), player.distance(to: p.tile.center), portalRange)
        }
        return best?.0
    }
}
