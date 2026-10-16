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

/// The animation frames for one buddy, sliced from its px_<id> sheet (see ArtSource/make_village.py).
final class BuddyAnimations {
    let frames: [String: [SKTexture]]
    private static var cache: [String: BuddyAnimations] = [:]

    private init(frames: [String: [SKTexture]]) { self.frames = frames }

    static func load(_ characterID: String) -> BuddyAnimations? {
        if let a = cache[characterID] { return a }
        guard let sheet = VillageArt.sheet("px_\(characterID)") else { return nil }
        let cell = VillageAtlas.buddyCell
        let sheetSize = CGSize(width: cell.width * 4, height: cell.height * CGFloat(VillageAtlas.buddyRows.count))
        var out: [String: [SKTexture]] = [:]
        for (row, entry) in VillageAtlas.buddyRows.enumerated() {
            out[entry.name] = (0..<entry.frames).map { col in
                VillageArt.slice(sheet, pixels: CGRect(x: CGFloat(col) * cell.width, y: CGFloat(row) * cell.height,
                                                       width: cell.width, height: cell.height), sheetSize: sheetSize)
            }
        }
        let a = BuddyAnimations(frames: out)
        cache[characterID] = a
        return a
    }
}

/// A buddy in the village: a pixel sprite with a shadow, a walk cycle on every side, hop arcs and
/// one-shot moves (celebrate, talk, interact). Its position is the point between its feet.
final class BuddySprite: SKNode {
    let character: GameCharacter
    private let art: SKSpriteNode
    private let shadowNode: SKSpriteNode
    private let anims: BuddyAnimations?
    private var looping = ""
    private var lastHop = 0
    private var oneShot = false
    /// Called each time a hop lands (for dust puffs and lily pad dips).
    var onLand: (() -> Void)?

    static let hopsPerTile = 1.6
    static let hopHeight: CGFloat = 7

    init(character: GameCharacter) {
        self.character = character
        anims = BuddyAnimations.load(character.id)
        let cell = VillageAtlas.buddyCell
        art = SKSpriteNode(texture: anims?.frames["idle"]?.first)
        art.size = CGSize(width: cell.width * VillageArt.scale, height: cell.height * VillageArt.scale)
        art.anchorPoint = CGPoint(x: 0.5, y: VillageAtlas.buddyFeet / cell.height)
        shadowNode = VillageArt.propNode("shadow")
        shadowNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        shadowNode.position = CGPoint(x: 0, y: 2)
        shadowNode.zPosition = -0.5
        super.init()
        addChild(shadowNode)
        if anims == nil {
            // art missing: fall back to the regular illustrated buddy so the game still works
            art.isHidden = true
            addChild(SpriteFactory.character(character, size: 60))
        }
        addChild(art)
        playLoop("idle", fps: 2.5)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func textures(_ name: String) -> [SKTexture] { anims?.frames[name] ?? [] }

    func playLoop(_ name: String, fps: Double) {
        guard looping != name, !oneShot else { return }
        looping = name
        art.removeAction(forKey: "anim")
        let tex = textures(name)
        guard tex.count > 1 else { if let t = tex.first { art.texture = t }; return }
        art.run(.repeatForever(.animate(with: tex, timePerFrame: 1 / fps)), withKey: "anim")
    }

    /// Plays a move once, then goes back to idle.
    func playOnce(_ name: String, fps: Double = 8, repeats: Int = 1) {
        let tex = textures(name)
        guard !tex.isEmpty else { return }
        oneShot = true
        looping = ""
        art.removeAction(forKey: "anim")
        art.position.y = 0
        art.run(.sequence([.repeat(.animate(with: tex, timePerFrame: 1 / fps), count: repeats),
                           .run { [weak self] in self?.oneShot = false; self?.playLoop("idle", fps: 2.5) }]),
                withKey: "anim")
    }

    /// Called every frame with the mover's state. Walking is frame-by-frame from the distance walked,
    /// so feet and hops always match the ground speed.
    func update(stride: Double, facing: Facing, moving: Bool) {
        art.xScale = facing == .west ? -1 : 1
        guard !oneShot else { return }
        if moving {
            looping = ""
            art.removeAction(forKey: "anim")
            let row: String
            switch facing {
            case .south: row = "walkS"
            case .north: row = "walkN"
            case .east, .west: row = "walkE"
            }
            let tex = textures(row)
            let phase = stride * Self.hopsPerTile
            if !tex.isEmpty { art.texture = tex[Int(phase * 2) % tex.count] }
            // a little hop on every step
            let frac = phase - floor(phase)
            art.position.y = CGFloat(sin(frac * .pi)) * Self.hopHeight
            shadowNode.setScale(1 - 0.18 * CGFloat(sin(frac * .pi)))
            let hop = Int(phase)
            if hop != lastHop { lastHop = hop; onLand?() }
        } else {
            art.position.y = 0
            shadowNode.setScale(1)
            if facing == .south {
                playLoop("idle", fps: 2.5)
            } else {
                // standing still facing away or sideways: the standing frame of that walk cycle
                looping = ""
                art.removeAction(forKey: "anim")
                let row = facing == .north ? "walkN" : "walkE"
                if let t = textures(row).dropFirst().first { art.texture = t }
            }
        }
    }

    /// Turns the sprite without changing its animation.
    func face(_ facing: Facing) { art.xScale = facing == .west ? -1 : 1 }

    /// Looping move used while talking or performing an activity.
    func setActivity(_ name: String?) {
        guard !oneShot else { return }
        if let name { playLoop(name, fps: name == "talk" ? 4 : 6) }
    }
}
