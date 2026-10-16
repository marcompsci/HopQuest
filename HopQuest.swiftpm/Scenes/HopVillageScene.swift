import SpriteKit
import UIKit

/// Hop Village: a walkable pixel-art overworld. Logic runs on a fixed 60 Hz step in tile units
/// (VillagePlayerController, NPCBrain, VillageCollision); this scene only draws it and reads input.
final class HopVillageScene: SKScene {

    struct Setup {
        var character: GameCharacter
        var theme: CastleTheme
        var save: VillageSaveState
        /// Which forest portals are awake (story chapter unlocked or done).
        var awakePortals: Set<Int>
        var hour: Int
    }

    // MARK: Callbacks to SwiftUI
    /// What the big action button should offer right now.
    var onInteractionChange: ((VillageInteraction?) -> Void)?
    /// The child chose to do something: tapped a door/buddy and arrived, walked into a door, or stepped into a portal.
    var onActivate: ((VillageInteraction) -> Void)?
    var onRegionChange: ((String) -> Void)?
    /// A buddy walked over and said hi.
    var onGreet: ((String) -> Void)?

    // MARK: State
    let map = VillageMap.shared
    private let setup: Setup
    private var player: VillagePlayerController
    private let playerSprite: BuddySprite
    private var npcs: [VillageNPCController] = []
    private let cam = VillageCameraController()
    private var environment: VillageEnvironmentSystem?
    private let world = SKNode()
    private var cullables: [SKNode] = []
    private var lilies: [GridPoint: SKSpriteNode] = [:]
    private let marker = SKSpriteNode()
    private var built = false

    private var accumulator = 0.0
    private var lastTime: TimeInterval = 0
    private var frameCount = 0
    private static let step = 1.0 / 60

    private var interaction: VillageInteraction?
    private var pendingActivate: VillageInteraction?
    private var doorPush = 0.0
    private var portalLatch: Int?
    private var region = ""
    private var talkingTo: String?
    /// While a dialogue, quiz or picker is open, the buddy stands still.
    var frozen = false {
        didSet { if frozen { player.stop(); pendingActivate = nil } }
    }

    private var touchStart: (point: CGPoint, time: TimeInterval)?

    private let t = VillageArt.tilePt
    private var worldSize: CGSize { CGSize(width: CGFloat(map.width) * t, height: CGFloat(map.height) * t) }

    init(size: CGSize, setup: Setup) {
        self.setup = setup
        player = VillagePlayerController(map: VillageMap.shared, start: setup.save.safeSpawn(in: VillageMap.shared), facing: setup.save.facing)
        playerSprite = BuddySprite(character: setup.character)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(hex: 0x3F7F36)
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Public API

    /// Joystick from SwiftUI: dx right, dy down, length 0...1.
    func setJoystick(_ v: CGVector) {
        guard !frozen else { player.joystick = .zero; return }
        player.joystick = VPoint(Double(v.dx), Double(v.dy))
        if v.dx != 0 || v.dy != 0 { pendingActivate = nil }
    }

    var playerTile: GridPoint { player.tile }
    var playerFacing: Facing { player.facing }

    /// Where to stand when coming back out of a building (its doorstep), else the current tile.
    func returnTile(for interaction: VillageInteraction?) -> GridPoint {
        if case .enter(let kind)? = interaction, let b = map.building(kind) { return b.doorstep }
        if case .portal(let n)? = interaction, let p = map.portals.first(where: { $0.number == n }) {
            return map.nearestWalkable(to: p.tile.offset(0, -1)) ?? p.tile
        }
        return player.tile
    }

    func beginTalk(_ npcID: String) {
        guard let npc = npcs.first(where: { $0.id == npcID }) else { return }
        talkingTo = npcID
        frozen = true
        npc.beginTalk(player: player.position)
        // the player turns to face them
        player.face(Facing.from(npc.position - player.position, current: player.facing))
    }

    func endTalk(happy: Bool) {
        if let id = talkingTo, let npc = npcs.first(where: { $0.id == id }) { npc.endTalk(happy: happy) }
        if happy { playerSprite.playOnce("celebrate", fps: 8, repeats: 2) }
        talkingTo = nil
        frozen = false
    }

    /// The action button with nothing in reach: a happy hop on the spot.
    func hopInPlace() {
        guard !frozen else { return }
        playerSprite.playOnce("hop", fps: 9)
        environment?.dust(at: scenePoint(player.position), z: playerSprite.zPosition)
    }

    /// The buddy cheers (after a reward).
    func celebrate() { playerSprite.playOnce("celebrate", fps: 8, repeats: 2) }

    func npcCharacter(_ npcID: String) -> GameCharacter? { npcs.first { $0.id == npcID }?.character }

    // MARK: Build

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        guard !built else { return }
        built = true
        addChild(world)
        addChild(cam.node)
        camera = cam.node

        buildGround()
        buildProps()
        buildBuildings()

        let quality: VillageEnvironmentSystem.Quality = setup.save.lightEffects ? .light : .full
        environment = VillageEnvironmentSystem(world: world, camera: cam.node, map: map, worldSize: worldSize,
                                               quality: quality, eveningLights: setup.save.eveningLights, hour: setup.hour)
        if environment?.isEvening == true { lightLamps() }

        for def in VillageNPCDef.all {
            let npc = VillageNPCController(def: def, map: map, playerCharacterID: setup.character.id)
            world.addChild(npc.sprite)
            npcs.append(npc)
        }

        world.addChild(playerSprite)
        playerSprite.onLand = { [weak self] in self?.playerLanded() }

        marker.texture = VillageArt.prop("marker0")
        marker.size = CGSize(width: 9 * VillageArt.scale, height: 11 * VillageArt.scale)
        marker.anchorPoint = CGPoint(x: 0.5, y: 0)
        marker.zPosition = 990
        marker.isHidden = true
        marker.run(.repeatForever(.animate(with: VillageArt.frames("marker", count: 2), timePerFrame: 0.35)))
        world.addChild(marker)

        renderActors()
        cam.snap(to: scenePoint(player.position), view: size, world: worldSize)
        cull()
    }

    private var lamps: [SKSpriteNode] = []

    private func buildGround() {
        let tileSize = CGSize(width: t, height: t)
        var groups: [GroundTile: SKTileGroup] = [:]
        for r in 0..<map.height {
            for c in 0..<map.width {
                let g = map.ground(c, r)
                if groups[g] != nil { continue }
                let def: SKTileDefinition
                switch g {
                case .sheet(let col, let row):
                    guard let tex = VillageArt.tile(col: col, row: row) else { continue }
                    def = SKTileDefinition(texture: tex, size: tileSize)
                case .water(let mask):
                    let frames = VillageArt.waterFrames(mask: mask)
                    guard !frames.isEmpty else { continue }
                    def = SKTileDefinition(textures: frames, size: tileSize, timePerFrame: 0.3)
                }
                groups[g] = SKTileGroup(tileDefinition: def)
            }
        }
        let tileSet = SKTileSet(tileGroups: Array(groups.values))
        let tileMap = SKTileMapNode(tileSet: tileSet, columns: map.width, rows: map.height, tileSize: tileSize)
        tileMap.anchorPoint = .zero
        tileMap.position = .zero
        tileMap.zPosition = 0
        for r in 0..<map.height {
            for c in 0..<map.width {
                if let g = groups[map.ground(c, r)] {
                    tileMap.setTileGroup(g, forColumn: c, row: map.height - 1 - r)
                }
            }
        }
        world.addChild(tileMap)
    }

    /// Adds a prop with its bottom-center on a tile's bottom edge (`lift` in art pixels moves it up).
    @discardableResult
    private func addProp(_ name: String, c: Int, r: Int, lift: CGFloat = 0, flat: Bool = false) -> SKSpriteNode {
        let node = VillageArt.propNode(name)
        node.position = CGPoint(x: (CGFloat(c) + 0.5) * t, y: CGFloat(map.height - 1 - r) * t + lift * VillageArt.scale)
        node.zPosition = flat ? 2 : depth(node.position.y)
        world.addChild(node)
        cullables.append(node)
        return node
    }

    private func buildProps() {
        for r in 0..<map.height {
            for c in 0..<map.width {
                guard let k = map.char(c, r) else { continue }
                let h = VillageMap.hash(c, r)
                switch k {
                case "T": addProp(h % 5 == 0 && r < 35 ? "tree1" : "tree0", c: c, r: r, lift: -2)
                case "t": addProp("bush", c: c, r: r, lift: 1)
                case "*": addProp("flowers\(h % 4)", c: c, r: r, flat: true)
                case "m": addProp("mushroom", c: c, r: r, lift: 3)
                case "B": addProp("bench", c: c, r: r, lift: 1)
                case "L": lamps.append(addProp("lamp0", c: c, r: r, lift: 2))
                case "F":
                    let vertical = map.char(c, r - 1) == "F" || map.char(c, r + 1) == "F"
                    addProp(vertical ? "fence_v" : "fence_h", c: c, r: r)
                case "R": addProp("rock", c: c, r: r, lift: 2)
                case "b": addProp("blocks", c: c, r: r, lift: 1)
                case "k": addProp("crane", c: c, r: r)
                case "c": addProp("car\(h % 2)", c: c, r: r, lift: 1)
                case "n": addProp("sign", c: c, r: r, lift: 1)
                case "o":
                    let lily = addProp("lily0", c: c, r: r, lift: 2, flat: true)
                    lily.run(.repeatForever(.animate(with: VillageArt.frames("lily", count: 2), timePerFrame: 0.9)))
                    lilies[GridPoint(c, r)] = lily
                case "1", "2", "3":
                    let n = Int(String(k)) ?? 1
                    let awake = setup.awakePortals.contains(n)
                    let portal = addProp(awake ? "portal0" : "portal_sleep", c: c, r: r)
                    if awake {
                        portal.run(.repeatForever(.animate(with: VillageArt.frames("portal", count: 4), timePerFrame: 0.14)))
                        let glow = VillageArt.propNode("firefly")
                        glow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                        glow.setScale(9)
                        glow.alpha = 0.55
                        glow.blendMode = .add
                        glow.position = CGPoint(x: 0, y: 22 * VillageArt.scale)
                        glow.zPosition = -0.2
                        glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 0.9), .fadeAlpha(to: 0.6, duration: 0.9)])))
                        portal.addChild(glow)
                    }
                default: break
                }
            }
        }
    }

    private func buildBuildings() {
        for b in map.buildings {
            let foot = scenePoint(b.foot)
            if b.kind == .fountain {
                let fountain = VillageArt.propNode("fountain0")
                fountain.position = foot
                fountain.zPosition = depth(foot.y)
                fountain.run(.repeatForever(.animate(with: VillageArt.frames("fountain", count: 3), timePerFrame: 0.18)))
                world.addChild(fountain)
                cullables.append(fountain)
                continue
            }
            let name = b.kind == .castle ? "village_castle_\(setup.theme.rawValue)" : b.kind.art
            guard let tex = VillageArt.sheet(name) else { continue }
            let node = SKSpriteNode(texture: tex)
            node.size = CGSize(width: tex.size().width * VillageArt.scale, height: tex.size().height * VillageArt.scale)
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.position = foot
            node.zPosition = depth(foot.y)
            node.name = b.kind.id
            world.addChild(node)
            cullables.append(node)
        }
    }

    private func lightLamps() {
        guard let lit = VillageArt.prop("lamp1") else { return }
        for lamp in lamps {
            lamp.texture = lit
            let glow = VillageArt.propNode("firefly")
            glow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            glow.setScale(7)
            glow.alpha = 0.5
            glow.blendMode = .add
            glow.position = CGPoint(x: 0, y: 27 * VillageArt.scale)
            glow.zPosition = 935 - lamp.zPosition
            lamp.addChild(glow)
        }
    }

    // MARK: Coordinates

    /// Tile space (y south) → scene points (y up).
    func scenePoint(_ v: VPoint) -> CGPoint {
        CGPoint(x: CGFloat(v.x) * t, y: (CGFloat(map.height) - CGFloat(v.y)) * t)
    }

    func tilePoint(_ p: CGPoint) -> VPoint {
        VPoint(Double(p.x / t), Double(map.height) - Double(p.y / t))
    }

    /// Lower on screen draws in front.
    private func depth(_ y: CGFloat) -> CGFloat { 100 + (worldSize.height - y) / 10 }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        guard built else { return }
        let dt = lastTime == 0 ? Self.step : min(0.1, currentTime - lastTime)
        lastTime = currentTime
        accumulator += dt
        var steps = 0
        while accumulator >= Self.step && steps < 6 {
            fixedStep(Self.step)
            accumulator -= Self.step
            steps += 1
        }
        if steps == 6 { accumulator = 0 }

        renderActors()
        let lead = player.isMoving ? CGVector(dx: player.joystick.x * 30, dy: -player.joystick.y * 30) : .zero
        cam.lead = lead
        cam.update(target: scenePoint(player.position), view: size, world: worldSize, dt: dt)
        frameCount += 1
        if frameCount % 10 == 0 { cull() }
        environment?.update(dt: dt, visible: cam.visibleRect(view: size, margin: 60))
    }

    private func fixedStep(_ dt: Double) {
        if !frozen { player.step(dt: dt) }

        for npc in npcs {
            if npc.step(dt: dt, player: player.position, collision: player.collision, pathfinder: player.pathfinder) == .greet {
                npc.wave()
                onGreet?(npc.id)
            }
        }

        // What can the child do here?
        let found = frozen ? nil : InteractionFinder.find(player: player.position,
                                                          npcs: npcs.filter { $0.id != talkingTo }.map { (id: $0.id, position: $0.position) },
                                                          map: map)
        if found != interaction {
            interaction = found
            onInteractionChange?(found)
        }

        guard !frozen else { return }

        // Arrived after tapping a door, buddy or portal: do it.
        if let pending = pendingActivate, !player.hasPath {
            pendingActivate = nil
            if pending == interaction { activate(pending) }
        }

        // Walking into a door with the joystick opens it.
        if case .enter(let kind)? = interaction, let b = map.building(kind),
           player.joystick.y < -0.5, player.position.distance(to: b.doorstep.center) < 0.7 {
            doorPush += dt
            if doorPush > 0.3 { doorPush = 0; activate(.enter(kind)) }
        } else {
            doorPush = 0
        }

        // Stepping onto a portal hops you in (once, until you step away).
        if let p = map.portals.first(where: { player.position.distance(to: $0.tile.center) < 0.45 }) {
            if portalLatch != p.number && player.joystick.length > 0.15 {
                portalLatch = p.number
                activate(.portal(p.number))
            }
        } else if let latch = portalLatch, let p = map.portals.first(where: { $0.number == latch }),
                  player.position.distance(to: p.tile.center) > 1.2 {
            portalLatch = nil
        }

        let name = map.regionName(at: player.tile)
        if name != region {
            region = name
            onRegionChange?(name)
        }
    }

    private func activate(_ i: VillageInteraction) {
        player.stop()
        onActivate?(i)
    }

    private func renderActors() {
        let pp = scenePoint(player.position)
        playerSprite.position = pp
        playerSprite.zPosition = depth(pp.y)
        playerSprite.update(stride: player.stride, facing: player.facing, moving: player.isMoving)

        for npc in npcs {
            let p = scenePoint(npc.position)
            npc.render(at: p, z: depth(p.y))
        }

        // bobbing arrow over whatever the button will do
        switch interaction {
        case .talk(let id)?:
            if let npc = npcs.first(where: { $0.id == id }) {
                marker.isHidden = false
                marker.position = CGPoint(x: scenePoint(npc.position).x, y: scenePoint(npc.position).y + 100)
            }
        case .enter(let kind)?:
            if let b = map.building(kind) {
                marker.isHidden = false
                let door = scenePoint(b.doorstep.center)
                marker.position = CGPoint(x: door.x, y: door.y + t * 1.6)
            }
        case .portal(let n)?:
            if let p = map.portals.first(where: { $0.number == n }) {
                marker.isHidden = false
                let pt = scenePoint(p.tile.center)
                marker.position = CGPoint(x: pt.x, y: pt.y + 130)
            }
        case nil:
            marker.isHidden = true
        }
    }

    private func playerLanded() {
        let tile = player.tile
        if let lily = lilies[tile] {
            lily.removeAction(forKey: "dip")
            lily.run(.sequence([.moveBy(x: 0, y: -4, duration: 0.08), .moveBy(x: 0, y: 4, duration: 0.25)]), withKey: "dip")
        } else if map.char(tile) != "#" {
            environment?.dust(at: scenePoint(player.position), z: playerSprite.zPosition)
        }
    }

    private func cull() {
        let rect = cam.visibleRect(view: size, margin: 220)
        for node in cullables {
            node.isHidden = !rect.intersects(node.frame)
        }
        for npc in npcs {
            npc.sprite.isHidden = !rect.contains(npc.sprite.position)
        }
    }

    // MARK: Touch (tap to move)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStart = (touch.location(in: self), touch.timestamp)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = touchStart, !frozen else { return }
        touchStart = nil
        let p = touch.location(in: self)
        guard hypot(p.x - start.point.x, p.y - start.point.y) < 14, touch.timestamp - start.time < 0.6 else { return }
        handleTap(at: p)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = nil
    }

    private func handleTap(at p: CGPoint) {
        let v = tilePoint(p)
        let tile = v.tile

        // a buddy? (their body sits above their feet)
        if let npc = npcs.first(where: { abs($0.position.x - v.x) < 0.7 && v.y < $0.position.y + 0.3 && v.y > $0.position.y - 1.9 }) {
            if player.walk(to: npc.position.tile) {
                pendingActivate = .talk(npcID: npc.id)
                environment?.tapMarker(at: scenePoint(npc.position))
            }
            return
        }
        // a building? (anywhere on its picture)
        if let b = map.buildings.first(where: { $0.kind.hasDoor && buildingHit($0, v) }) {
            if player.walk(to: b.doorstep) {
                pendingActivate = .enter(b.kind)
                environment?.tapMarker(at: scenePoint(b.doorstep.center))
            }
            return
        }
        if let portal = map.portal(at: tile) {
            if player.walk(to: portal.tile) {
                pendingActivate = .portal(portal.number)
                portalLatch = portal.number
                environment?.tapMarker(at: scenePoint(portal.tile.center))
            }
            return
        }
        pendingActivate = nil
        if player.walk(to: tile) {
            Haptics.tap(nil)
            environment?.tapMarker(at: scenePoint((map.nearestWalkable(to: tile) ?? tile).center))
        }
    }

    /// The picture is taller than the footprint (roofs, towers), so taps on the roof count too.
    private func buildingHit(_ b: VillageBuilding, _ v: VPoint) -> Bool {
        let roof = Double(b.heightTiles) * 0.9
        return v.x >= Double(b.minC) && v.x <= Double(b.maxC + 1) && v.y <= Double(b.maxR + 1) && v.y >= Double(b.minR) - roof
    }
}
