import Foundation

/// Your pet walks behind your buddy by following the buddy's own footsteps, so it only ever steps where the buddy
/// already stood (never through walls or water). If the buddy jumps far away (a hop, or coming back from a game),
/// the pet pops out right beside them. Plain Swift, tested in Tests/VillageLogic.
struct PetFollower {
    /// How far behind the buddy the pet likes to walk (tiles).
    static let followDistance = 1.1
    /// Farther than this, the pet just appears beside the buddy.
    static let snapDistance = 5.0
    static let maxSpeed = 5.2

    private(set) var position: VPoint
    private(set) var facing: Facing = .south
    private(set) var isMoving = false
    /// The buddy's recent footsteps, oldest first.
    private(set) var trail: [VPoint] = []

    init(near player: VPoint) {
        position = player
        trail = [player]
    }

    mutating func step(dt: Double, player: VPoint) {
        if trail.last.map({ $0.distance(to: player) >= 0.06 }) ?? true { trail.append(player) }
        if trail.count > 160 { trail.removeFirst(trail.count - 160) }

        if position.distance(to: player) > Self.snapDistance {
            // too far: pop out right where the buddy is (the only spot we know is safe), then trail behind again
            position = player
            trail = [player]
            isMoving = false
            return
        }

        // walk along the trail until we're followDistance behind the buddy
        var budget = Self.maxSpeed * dt
        var moved = false
        while budget > 0, let next = trail.first {
            guard position.distance(to: player) > Self.followDistance else { break }
            let d = next - position
            let len = d.length
            if len <= budget {
                position = next
                budget -= len
                trail.removeFirst()
                if len > 1e-6 { facing = Facing.from(d, current: facing); moved = true }
                if trail.isEmpty { trail = [player] }
            } else {
                position = position + d * (budget / len)
                facing = Facing.from(d, current: facing)
                moved = true
                budget = 0
            }
        }
        isMoving = moved
    }
}
