import SpriteKit

/// One village buddy on screen: runs its NPCBrain on the fixed step and animates its sprite.
final class VillageNPCController {
    private(set) var brain: NPCBrain
    let sprite: BuddySprite
    let character: GameCharacter

    var id: String { brain.def.id }
    var position: VPoint { brain.position }

    init(def: VillageNPCDef, map: VillageMap, playerCharacterID: String) {
        brain = NPCBrain(def: def, map: map)
        character = Roster.character(id: def.characterID(avoiding: playerCharacterID))
        sprite = BuddySprite(character: character)
    }

    func step(dt: Double, player: VPoint, collision: VillageCollision, pathfinder: VillagePathfinder) -> NPCEvent? {
        brain.step(dt: dt, player: player, collision: collision, pathfinder: pathfinder)
    }

    /// Called once per rendered frame.
    func render(at point: CGPoint, z: CGFloat) {
        sprite.position = point
        sprite.zPosition = z
        switch brain.mode {
        case .talk:
            // don't call update() here: it would reset the loop to idle every frame
            sprite.face(brain.facing)
            sprite.setActivity("talk")
        case .activity where brain.isPerforming:
            sprite.face(.south)
            sprite.setActivity("celebrate")
        default:
            sprite.update(stride: brain.stride, facing: brain.facing, moving: brain.isMoving)
        }
    }

    func beginTalk(player: VPoint) { brain.beginTalk(player: player) }

    func endTalk(happy: Bool) {
        brain.endTalk()
        if happy { sprite.playOnce("celebrate", fps: 8, repeats: 2) }
    }

    /// Greeting wave.
    func wave() { sprite.playOnce("interact", fps: 5, repeats: 2) }
}
