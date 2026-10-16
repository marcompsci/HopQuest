import Foundation

/// Something the child can do right where they're standing.
enum VillageInteraction: Equatable {
    case talk(npcID: String)
    case enter(BuildingKind)
    /// Another live player is close: challenge them to a Brain Duel.
    case challenge(peerKey: String)
}

enum InteractionFinder {
    static let talkRange = 1.5
    static let doorRange = 0.95
    static let peerRange = 1.6

    /// The closest thing in reach. Buddies and players win ties because they move and a chat is quick.
    static func find(player: VPoint,
                     npcs: [(id: String, position: VPoint)],
                     peers: [(key: String, position: VPoint)] = [],
                     map: VillageMap) -> VillageInteraction? {
        var best: (VillageInteraction, Double)?
        func consider(_ i: VillageInteraction, _ d: Double, _ range: Double) {
            guard d <= range else { return }
            if best == nil || d < best!.1 { best = (i, d) }
        }
        for npc in npcs {
            consider(.talk(npcID: npc.id), player.distance(to: npc.position) - 0.2, talkRange)
        }
        for peer in peers {
            consider(.challenge(peerKey: peer.key), player.distance(to: peer.position) - 0.2, peerRange)
        }
        for b in map.buildings where b.kind.hasDoor {
            consider(.enter(b.kind), player.distance(to: b.doorstep.center), doorRange)
        }
        return best?.0
    }
}
