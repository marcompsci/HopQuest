import SpriteKit
import UIKit

/// Pixel-art textures for Hop Village. Every sheet uses nearest-neighbor filtering and one shared scale
/// (1 art pixel = 3 points), so pixels stay crisp and the same size everywhere.
enum VillageArt {
    static let scale: CGFloat = 3
    static let tilePt: CGFloat = VillageAtlas.tileSize * scale     // 48 pt

    private static var sheets: [String: SKTexture] = [:]
    private static var slices: [String: SKTexture] = [:]

    /// A whole image from the asset catalog, crisp.
    static func sheet(_ name: String) -> SKTexture? {
        if let t = sheets[name] { return t }
        guard let img = ArtLibrary.image(name) else { return nil }
        let t = SKTexture(image: img)
        t.filteringMode = .nearest
        sheets[name] = t
        return t
    }

    /// A sub-rectangle of a sheet. `pixels` uses a top-left origin, like the art tools.
    static func slice(_ sheet: SKTexture, pixels r: CGRect, sheetSize: CGSize) -> SKTexture {
        let unit = CGRect(x: r.minX / sheetSize.width,
                          y: 1 - r.maxY / sheetSize.height,
                          width: r.width / sheetSize.width,
                          height: r.height / sheetSize.height)
        let t = SKTexture(rect: unit, in: sheet)
        t.filteringMode = .nearest
        return t
    }

    static func prop(_ name: String) -> SKTexture? {
        let key = "prop." + name
        if let t = slices[key] { return t }
        guard let rect = VillageAtlas.props[name], let sheet = sheet("village_props") else { return nil }
        let t = slice(sheet, pixels: rect, sheetSize: VillageAtlas.propsSheetSize)
        slices[key] = t
        return t
    }

    static func tile(col: Int, row: Int) -> SKTexture? {
        let key = "tile.\(col).\(row)"
        if let t = slices[key] { return t }
        guard let sheet = sheet("village_tiles") else { return nil }
        let s = VillageAtlas.tileSize
        let t = slice(sheet, pixels: CGRect(x: CGFloat(col) * s, y: CGFloat(row) * s, width: s, height: s),
                      sheetSize: VillageAtlas.tilesSheetSize)
        slices[key] = t
        return t
    }

    /// Water tile frames (four, for the ripple animation).
    static func waterFrames(mask: Int) -> [SKTexture] {
        (0..<4).compactMap { tile(col: mask, row: 2 + $0) }
    }

    /// A prop sprite standing with its bottom-center on (0, 0).
    static func propNode(_ name: String) -> SKSpriteNode {
        let tex = prop(name)
        let node = SKSpriteNode(texture: tex)
        if let tex { node.size = CGSize(width: tex.size().width * scale, height: tex.size().height * scale) }
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        return node
    }

    /// Frames for a looping prop animation ("fountain" → fountain0, fountain1, ...).
    static func frames(_ base: String, count: Int) -> [SKTexture] {
        (0..<count).compactMap { prop("\(base)\($0)") }
    }
}

/// Smooth, shaded ("3D") buddy textures: buddy3d_<id>, baked by ArtSource/make_buddies3d.py from the
/// original illustrations. Falls back to the plain illustration if one is missing.
enum BuddyTextures {
    private static var cache: [String: SKTexture] = [:]
    private static var shadowTex: SKTexture?

    static func texture(_ c: GameCharacter) -> SKTexture? {
        if let t = cache[c.id] { return t }
        let t: SKTexture?
        if let img = ArtLibrary.image("buddy3d_\(c.id)") {
            t = SKTexture(image: img)
        } else {
            t = SpriteFactory.texture(c)
        }
        t?.filteringMode = .linear
        cache[c.id] = t
        return t
    }

    /// A soft, round contact shadow.
    static var shadow: SKTexture {
        if let shadowTex { return shadowTex }
        let size = CGSize(width: 64, height: 24)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(white: 0, alpha: 0.32).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray
            guard let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            ctx.cgContext.scaleBy(x: 1, y: size.height / size.width)
            let c = CGPoint(x: size.width / 2, y: size.width / 2)
            ctx.cgContext.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
        }
        let t = SKTexture(image: img)
        shadowTex = t
        return t
    }
}

/// A buddy in the village: a smooth, shaded figure that bounces, sways and squashes as it walks, turns around
/// with a quick flip, hops in an arc, and breathes when standing still. Its position is the point between its feet.
///
/// Node layers: root (position) → shadow, rig (per-frame walk/hop motion) → actor (looping and one-shot moves)
/// → art (left/right turn).
final class BuddySprite: SKNode {
    let character: GameCharacter
    private let shadowNode: SKSpriteNode
    private let rig = SKNode()
    private let actor = SKNode()
    private let art: SKSpriteNode
    private var facingSign: CGFloat = 1
    private var loop = ""
    private var oneShot = false
    private var lastStep = 0
    private var wasHopping = false
    /// Called each time a step or hop lands (for dust puffs and lily pad dips).
    var onLand: (() -> Void)?

    /// On-screen height in points (about 1.9 tiles).
    static let height: CGFloat = 92
    static let stepsPerTile = 1.6
    static let hopArc: CGFloat = 38

    init(character: GameCharacter) {
        self.character = character
        let tex = BuddyTextures.texture(character)
        art = SKSpriteNode(texture: tex)
        let aspect = tex.map { $0.size().width / max(1, $0.size().height) } ?? 0.9
        art.size = CGSize(width: Self.height * aspect, height: Self.height)
        art.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        shadowNode = SKSpriteNode(texture: BuddyTextures.shadow)
        shadowNode.size = CGSize(width: max(46, Self.height * aspect * 0.78), height: 18)
        shadowNode.position = CGPoint(x: 0, y: 3)
        shadowNode.zPosition = -0.5
        super.init()
        addChild(shadowNode)
        addChild(rig)
        rig.addChild(actor)
        if tex == nil {
            actor.addChild(SpriteFactory.character(character, size: 60))
        } else {
            actor.addChild(art)
        }
        startLoop("idle")
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Per-frame motion

    /// Called every frame with the mover's state. `hop` is 0...1 through a hop (0 = on the ground).
    func update(stride: Double, facing: Facing, moving: Bool, hop: Double = 0) {
        face(facing)
        if hop > 0 {
            wasHopping = true
            stopLoop()
            let h = CGFloat(sin(hop * .pi))
            rig.position.y = h * Self.hopArc
            // stretch on the way up, squash just before landing
            let stretch = CGFloat(hop < 0.5 ? 0.10 * (1 - hop * 2) : -0.08 * (hop - 0.5) * 2)
            rig.yScale = 1 + stretch
            rig.xScale = 1 - stretch * 0.6
            rig.zRotation = -facingSign * 0.12 * h
            shadowNode.setScale(1 - 0.45 * h)
            shadowNode.alpha = 1 - 0.5 * h
            return
        }
        if wasHopping {
            wasHopping = false
            land()
        }
        if moving {
            stopLoop()
            let phase = stride * Self.stepsPerTile
            let f = phase - floor(phase)
            let lift = CGFloat(sin(f * .pi))
            let contact = 1 - lift
            rig.position.y = lift * 7
            // sway side to side each step, lean a little into the walk
            let lean: CGFloat = (facing == .east || facing == .west) ? -facingSign * 0.06 : 0
            rig.zRotation = CGFloat(sin(phase * .pi)) * 0.07 + lean
            rig.yScale = 1 - 0.07 * contact * contact
            rig.xScale = 1 + 0.05 * contact * contact
            shadowNode.setScale(1 - 0.15 * lift)
            shadowNode.alpha = 1
            let step = Int(phase)
            if step != lastStep { lastStep = step; onLand?() }
        } else {
            rig.position.y = 0
            rig.zRotation *= 0.6
            rig.xScale = 1
            rig.yScale = 1
            shadowNode.setScale(1)
            shadowNode.alpha = 1
            startLoop("idle")
        }
    }

    /// Turns to face left/right with a quick flip; facing away dims the buddy a touch (we see their back).
    func face(_ facing: Facing) {
        let sign: CGFloat
        switch facing {
        case .west: sign = -1
        case .east: sign = 1
        default: sign = facingSign
        }
        if sign != facingSign {
            facingSign = sign
            art.run(SKAction.scaleX(to: sign, duration: 0.14), withKey: "turn")
        }
        art.color = .black
        art.colorBlendFactor = facing == .north ? 0.14 : 0
    }

    // MARK: Moves

    /// Looping move while talking or doing an activity ("talk" or "celebrate").
    func setActivity(_ name: String?) {
        guard let name else { return }
        rig.position.y = 0
        rig.zRotation = 0
        startLoop(name)
    }

    /// Plays a move once ("hop", "celebrate", "interact"), then goes back to idle.
    func playOnce(_ name: String, fps: Double = 8, repeats: Int = 1) {
        let move: SKAction
        switch name {
        case "hop":
            move = jump(height: 30, duration: 0.42)
        case "celebrate":
            let spin = SKAction.sequence([.scaleX(to: -facingSign, duration: 0.12), .scaleX(to: facingSign, duration: 0.12)])
            art.run(.repeat(spin, count: max(1, repeats)), withKey: "turn")
            move = .repeat(jump(height: 26, duration: 0.4), count: max(1, repeats))
            sparkle()
        default: // "interact": a friendly wave (wiggle)
            let wiggle = SKAction.sequence([.rotate(toAngle: 0.12, duration: 0.12), .rotate(toAngle: -0.12, duration: 0.18),
                                            .rotate(toAngle: 0, duration: 0.12)])
            move = .repeat(wiggle, count: max(1, repeats))
        }
        oneShot = true
        loop = ""
        actor.removeAction(forKey: "loop")
        actor.run(.sequence([move, .run { [weak self] in
            self?.oneShot = false
            self?.startLoop("idle")
        }]), withKey: "once")
    }

    private func jump(height: CGFloat, duration: Double) -> SKAction {
        let crouch = SKAction.group([.scaleX(to: 1.08, duration: 0.06), .scaleY(to: 0.9, duration: 0.06)])
        let up = SKAction.group([.moveTo(y: height, duration: duration * 0.45), .scaleX(to: 0.95, duration: duration * 0.2),
                                 .scaleY(to: 1.07, duration: duration * 0.2)])
        up.timingMode = .easeOut
        let down = SKAction.group([.moveTo(y: 0, duration: duration * 0.4), .scaleX(to: 1, duration: duration * 0.4),
                                   .scaleY(to: 1, duration: duration * 0.4)])
        down.timingMode = .easeIn
        let land = SKAction.sequence([.group([.scaleX(to: 1.1, duration: 0.05), .scaleY(to: 0.9, duration: 0.05)]),
                                      .group([.scaleX(to: 1, duration: 0.1), .scaleY(to: 1, duration: 0.1)])])
        return .sequence([crouch, up, down, .run { [weak self] in self?.onLand?() }, land])
    }

    private func land() {
        onLand?()
        rig.position.y = 0
        rig.zRotation = 0
        rig.xScale = 1
        rig.yScale = 1
        actor.run(.sequence([.group([.scaleX(to: 1.12, duration: 0.05), .scaleY(to: 0.86, duration: 0.05)]),
                             .group([.scaleX(to: 1, duration: 0.14), .scaleY(to: 1, duration: 0.14)])]), withKey: "land")
        shadowNode.setScale(1)
        shadowNode.alpha = 1
    }

    private func sparkle() {
        for i in 0..<5 {
            let s = VillageArt.propNode("sparkle")
            s.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            let a = Double(i) / 5 * 2 * .pi
            s.position = CGPoint(x: 0, y: Self.height * 0.55)
            s.setScale(0.6)
            s.zPosition = 2
            addChild(s)
            s.run(.sequence([.group([.moveBy(x: CGFloat(cos(a)) * 46, y: CGFloat(sin(a)) * 46 + 20, duration: 0.5),
                                     .scale(to: 1.1, duration: 0.5), .fadeOut(withDuration: 0.6)]),
                             .removeFromParent()]))
        }
    }

    // MARK: Loops

    private func startLoop(_ name: String) {
        guard !oneShot, loop != name else { return }
        loop = name
        actor.removeAction(forKey: "loop")
        actor.position = .zero
        actor.zRotation = 0
        actor.setScale(1)
        let action: SKAction
        switch name {
        case "talk":
            let nod = SKAction.sequence([.group([.rotate(toAngle: 0.05, duration: 0.18), .scaleY(to: 0.97, duration: 0.18)]),
                                         .group([.rotate(toAngle: -0.04, duration: 0.2), .scaleY(to: 1.0, duration: 0.2)])])
            action = .repeatForever(nod)
        case "celebrate":
            action = .repeatForever(.sequence([jump(height: 22, duration: 0.38), .wait(forDuration: 0.15)]))
        default: // idle: gentle breathing with a tiny sway
            let inhale = SKAction.group([.scaleY(to: 1.035, duration: 0.95), .scaleX(to: 0.985, duration: 0.95),
                                         .rotate(toAngle: 0.015, duration: 0.95)])
            inhale.timingMode = .easeInEaseOut
            let exhale = SKAction.group([.scaleY(to: 1.0, duration: 0.95), .scaleX(to: 1.0, duration: 0.95),
                                         .rotate(toAngle: -0.015, duration: 0.95)])
            exhale.timingMode = .easeInEaseOut
            action = .repeatForever(.sequence([inhale, exhale]))
        }
        actor.run(action, withKey: "loop")
    }

    private func stopLoop() {
        guard !loop.isEmpty, !oneShot else { return }
        loop = ""
        actor.removeAction(forKey: "loop")
        actor.position = .zero
        actor.zRotation = 0
        actor.setScale(1)
    }
}
