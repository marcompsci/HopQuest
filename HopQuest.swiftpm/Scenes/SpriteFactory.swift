import SpriteKit
import UIKit

/// Every sprite in the game is drawn from code, so there are no image assets to license.
/// Swap any of these for real art later without touching game logic.
enum SpriteFactory {

    static let carColors: [UIColor] = [0xFF6B6B, 0x4D96FF, 0xFFD93D, 0x6BCB77, 0xB983FF, 0xFF9F45].map { UIColor(hex: $0) }

    // MARK: Characters

    /// Cached SpriteKit textures for the illustrated characters.
    private static var textures: [String: SKTexture] = [:]

    static func texture(_ c: GameCharacter) -> SKTexture? {
        if let t = textures[c.id] { return t }
        guard let img = CharacterArt.image(c) else { return nil }
        let t = SKTexture(image: img)
        textures[c.id] = t
        return t
    }

    /// Full-body illustrated character, feet at about y = -0.42 * s, with a gentle idle bounce.
    static func character(_ c: GameCharacter, size s: CGFloat) -> SKNode {
        guard let tex = texture(c) else { return legacyCharacter(c, size: s) }
        let root = SKNode()
        let w = s * 1.15
        let h = w * 460 / 420
        let art = SKSpriteNode(texture: tex, size: CGSize(width: w, height: h))
        art.anchorPoint = CGPoint(x: 0.5, y: 0.07)       // pivot at the feet
        art.position = CGPoint(x: 0, y: -s * 0.42)
        art.name = "art"
        art.run(.repeatForever(.sequence([
            .group([.scaleX(to: 0.97, duration: 0.45), .scaleY(to: 1.04, duration: 0.45)]),
            .group([.scaleX(to: 1.0, duration: 0.45), .scaleY(to: 1.0, duration: 0.45)])
        ])))
        root.addChild(art)
        return root
    }

    /// Small character for sitting in a kart or car (seen from above).
    static func driver(_ c: GameCharacter, size s: CGFloat) -> SKNode {
        guard let tex = texture(c) else { return emoji(c.emoji, size: s * 0.75) }
        let w = s
        let sprite = SKSpriteNode(texture: tex, size: CGSize(width: w, height: w * 460 / 420))
        return sprite
    }

    /// Old shape-drawn character, used only if the art can't be loaded.
    private static func legacyCharacter(_ c: GameCharacter, size s: CGFloat) -> SKNode {
        let root = SKNode()

        let shadow = SKShapeNode(ellipseOf: CGSize(width: s * 0.75, height: s * 0.22))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -s * 0.44)
        root.addChild(shadow)

        if c.accessory == .cape {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -s * 0.25, y: s * 0.05))
            path.addLine(to: CGPoint(x: s * 0.25, y: s * 0.05))
            path.addLine(to: CGPoint(x: s * 0.5, y: -s * 0.46))
            path.addQuadCurve(to: CGPoint(x: -s * 0.5, y: -s * 0.46), control: CGPoint(x: 0, y: -s * 0.36))
            path.closeSubpath()
            let cape = SKShapeNode(path: path)
            cape.fillColor = UIColor(hex: 0xE63946)
            cape.strokeColor = .clear
            root.addChild(cape)
        }

        if c.isBunny {
            root.addChild(bunny(size: s))
        } else {
            let badge = SKShapeNode(circleOfRadius: s * 0.42)
            badge.fillColor = UIColor(hex: c.colorHex)
            badge.strokeColor = .white
            badge.lineWidth = max(2, s * 0.05)
            root.addChild(badge)
            root.addChild(emoji(c.emoji, size: s * 0.52, at: CGPoint(x: 0, y: -s * 0.01)))
        }

        switch c.accessory {
        case .mask:
            let mask = SKShapeNode(rectOf: CGSize(width: s * 0.62, height: s * 0.13), cornerRadius: s * 0.06)
            mask.fillColor = UIColor.black.withAlphaComponent(0.82)
            mask.strokeColor = .clear
            mask.position = CGPoint(x: 0, y: s * 0.06)
            for side: CGFloat in [-1, 1] {
                let eye = SKShapeNode(circleOfRadius: s * 0.03)
                eye.fillColor = .white
                eye.strokeColor = .clear
                eye.position = CGPoint(x: side * s * 0.11, y: 0)
                mask.addChild(eye)
            }
            root.addChild(mask)
        case .crown:
            root.addChild(emoji("👑", size: s * 0.3, at: CGPoint(x: 0, y: s * 0.44)))
        case .bow:
            root.addChild(emoji("🎀", size: s * 0.26, at: CGPoint(x: s * 0.28, y: s * 0.32)))
        case .helmet:
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: s * 0.3, startAngle: 0, endAngle: .pi, clockwise: false)
            path.closeSubpath()
            let helmet = SKShapeNode(path: path)
            helmet.fillColor = UIColor(hex: 0xF4D35E)
            helmet.strokeColor = .white
            helmet.lineWidth = 2
            helmet.position = CGPoint(x: 0, y: s * 0.24)
            root.addChild(helmet)
        case .cape, .none:
            break
        }
        return root
    }

    static func bunny(size s: CGFloat) -> SKNode {
        let n = SKNode()
        let body = UIColor(hex: 0x9B6BDF)
        let light = UIColor(hex: 0xD9C2FF)
        let pink = UIColor(hex: 0xFF9ECF)

        for side: CGFloat in [-1, 1] {
            let ear = SKShapeNode(ellipseOf: CGSize(width: s * 0.2, height: s * 0.48))
            ear.fillColor = body
            ear.strokeColor = .white
            ear.lineWidth = max(1.5, s * 0.03)
            ear.position = CGPoint(x: side * s * 0.15, y: s * 0.38)
            ear.zRotation = -side * 0.2
            let inner = SKShapeNode(ellipseOf: CGSize(width: s * 0.09, height: s * 0.32))
            inner.fillColor = light
            inner.strokeColor = .clear
            ear.addChild(inner)
            n.addChild(ear)
        }

        let head = SKShapeNode(circleOfRadius: s * 0.37)
        head.fillColor = body
        head.strokeColor = .white
        head.lineWidth = max(2, s * 0.04)
        head.position = CGPoint(x: 0, y: -s * 0.04)
        n.addChild(head)

        for side: CGFloat in [-1, 1] {
            let eye = SKShapeNode(circleOfRadius: s * 0.055)
            eye.fillColor = UIColor(hex: 0x2B1B3D)
            eye.strokeColor = .clear
            eye.position = CGPoint(x: side * s * 0.13, y: 0)
            let shine = SKShapeNode(circleOfRadius: s * 0.018)
            shine.fillColor = .white
            shine.strokeColor = .clear
            shine.position = CGPoint(x: s * 0.018, y: s * 0.018)
            eye.addChild(shine)
            n.addChild(eye)

            let cheek = SKShapeNode(circleOfRadius: s * 0.05)
            cheek.fillColor = pink.withAlphaComponent(0.55)
            cheek.strokeColor = .clear
            cheek.position = CGPoint(x: side * s * 0.21, y: -s * 0.11)
            n.addChild(cheek)
        }

        let nose = SKShapeNode(ellipseOf: CGSize(width: s * 0.1, height: s * 0.07))
        nose.fillColor = pink
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: -s * 0.09)
        n.addChild(nose)
        return n
    }

    static func emoji(_ text: String, size: CGFloat, at point: CGPoint = .zero) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontSize = size
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = point
        return label
    }

    // MARK: Vehicles & river

    /// Side-view car for the hop levels. Drawn facing right, mirrored when driving left.
    static func car(color: UIColor, width w: CGFloat, height h: CGFloat, facingRight: Bool) -> SKNode {
        let root = SKNode()

        let cabin = SKShapeNode(rectOf: CGSize(width: w * 0.55, height: h * 0.45), cornerRadius: h * 0.16)
        cabin.fillColor = color.withAlphaComponent(0.85)
        cabin.strokeColor = .clear
        cabin.position = CGPoint(x: -w * 0.05, y: h * 0.22)
        root.addChild(cabin)

        let window = SKShapeNode(rectOf: CGSize(width: w * 0.42, height: h * 0.27), cornerRadius: h * 0.1)
        window.fillColor = UIColor(hex: 0xD6F1FF)
        window.strokeColor = .clear
        window.position = CGPoint(x: -w * 0.05, y: h * 0.22)
        root.addChild(window)

        // friendly eyes on the windshield
        for dx: CGFloat in [0.04, 0.14] {
            let eye = SKShapeNode(circleOfRadius: h * 0.05)
            eye.fillColor = UIColor(hex: 0x2B1B3D)
            eye.strokeColor = .clear
            eye.position = CGPoint(x: w * dx, y: h * 0.24)
            root.addChild(eye)
        }

        let body = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.5), cornerRadius: h * 0.2)
        body.fillColor = color
        body.strokeColor = UIColor.black.withAlphaComponent(0.15)
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: -h * 0.08)
        root.addChild(body)

        let light = SKShapeNode(circleOfRadius: h * 0.08)
        light.fillColor = UIColor(hex: 0xFFF3A0)
        light.strokeColor = .clear
        light.position = CGPoint(x: w * 0.44, y: -h * 0.05)
        root.addChild(light)

        for dx: CGFloat in [-0.3, 0.3] {
            let wheel = SKShapeNode(circleOfRadius: h * 0.17)
            wheel.fillColor = UIColor(hex: 0x2E2E3A)
            wheel.strokeColor = UIColor(hex: 0x9AA0AE)
            wheel.lineWidth = 2
            wheel.position = CGPoint(x: w * dx, y: -h * 0.33)
            root.addChild(wheel)
        }

        if !facingRight { root.xScale = -1 }
        return root
    }

    /// Top-down car for the driving levels. Front points up (+y).
    /// Top-down vehicle (front points up). Children: "brake" lights, "blinkL"/"blinkR" turn signals.
    static func topCar(color: UIColor, width w: CGFloat, height h: CGFloat, kind: DriveArt.CarKind = .car) -> SKNode {
        let root = SKNode()
        let size = DriveArt.vehicleSize(kind, bodyWidth: w)
        let body = SKSpriteNode(texture: DriveArt.vehicle(kind, color: color), size: size)
        body.name = "body"
        root.addChild(body)
        let bodyH = w * kind.design.height / kind.design.width

        let brake = SKNode()
        brake.name = "brake"
        brake.alpha = 0
        for side: CGFloat in [-1, 1] {
            let g = SKSpriteNode(texture: DriveArt.glow(UIColor(hex: 0xFF2D2D)), size: CGSize(width: w * 0.42, height: w * 0.42))
            g.position = CGPoint(x: side * w * 0.3, y: -bodyH * 0.47)
            g.blendMode = .add
            brake.addChild(g)
        }
        brake.zPosition = 2
        root.addChild(brake)

        for (name, side) in [("blinkL", CGFloat(-1)), ("blinkR", CGFloat(1))] {
            let blink = SKNode()
            blink.name = name
            blink.alpha = 0
            for y in [bodyH * 0.45, -bodyH * 0.45] {
                let g = SKSpriteNode(texture: DriveArt.glow(UIColor(hex: 0xFFA41B)), size: CGSize(width: w * 0.45, height: w * 0.45))
                g.position = CGPoint(x: side * w * 0.46, y: y)
                g.blendMode = .add
                blink.addChild(g)
            }
            blink.zPosition = 2
            root.addChild(blink)
        }
        return root
    }

    static func log(width w: CGFloat, height h: CGFloat) -> SKNode {
        let root = SKNode()
        let wood = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: h * 0.45)
        wood.fillColor = UIColor(hex: 0xA0673B)
        wood.strokeColor = UIColor(hex: 0x6E4325)
        wood.lineWidth = 2
        root.addChild(wood)
        for dx: CGFloat in [-0.25, 0.1, 0.32] {
            let grain = SKShapeNode(rectOf: CGSize(width: w * 0.16, height: 2), cornerRadius: 1)
            grain.fillColor = UIColor(hex: 0x6E4325, alpha: 0.6)
            grain.strokeColor = .clear
            grain.position = CGPoint(x: w * dx, y: h * (dx > 0 ? 0.15 : -0.12))
            root.addChild(grain)
        }
        let end = SKShapeNode(ellipseOf: CGSize(width: h * 0.45, height: h * 0.85))
        end.fillColor = UIColor(hex: 0xD9A066)
        end.strokeColor = UIColor(hex: 0x6E4325)
        end.position = CGPoint(x: w / 2 - h * 0.22, y: 0)
        root.addChild(end)
        return root
    }

    // MARK: Gates, castle, balloon

    static func gateBanner(width: CGFloat, cell: CGFloat) -> SKNode {
        let root = SKNode()
        for side: CGFloat in [-1, 1] {
            let post = SKShapeNode(rectOf: CGSize(width: cell * 0.18, height: cell * 0.95), cornerRadius: 3)
            post.fillColor = UIColor(hex: 0xFFFFFF)
            post.strokeColor = UIColor(hex: 0xFF7FC4)
            post.lineWidth = 2
            post.position = CGPoint(x: side * width * 0.46, y: cell * 0.05)
            root.addChild(post)
        }
        let ribbon = SKShapeNode(rectOf: CGSize(width: width * 0.9, height: cell * 0.42), cornerRadius: cell * 0.2)
        ribbon.fillColor = UIColor(hex: 0x7C4DFF)
        ribbon.strokeColor = .white
        ribbon.lineWidth = 3
        ribbon.position = CGPoint(x: 0, y: cell * 0.36)
        root.addChild(ribbon)
        let label = SKLabelNode(text: "❓ BRAIN GATE ❓")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = cell * 0.26
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: cell * 0.36)
        root.addChild(label)
        label.run(.repeatForever(.sequence([.scale(to: 1.06, duration: 0.5), .scale(to: 1.0, duration: 0.5)])))
        return root
    }

    private static var artTextures: [String: SKTexture] = [:]

    static func artTexture(_ name: String) -> SKTexture? {
        if let t = artTextures[name] { return t }
        guard let img = ArtLibrary.image(name) else { return nil }
        let t = SKTexture(image: img)
        artTextures[name] = t
        return t
    }

    /// Illustrated castle with its bottom-center at (0, 0).
    static func castle(theme: CastleTheme, width w: CGFloat) -> SKNode {
        let root = SKNode()
        guard let tex = artTexture("castle_\(theme.rawValue)") else { return root }
        let sprite = SKSpriteNode(texture: tex, size: CGSize(width: w * 1.15, height: w * 1.2))
        sprite.anchorPoint = CGPoint(x: 0.5, y: 50.0 / 480.0)
        root.addChild(sprite)
        return root
    }

    /// Illustrated balloon with the basket centered at (0, 0). Back at z = 1 and basket front at z = 3,
    /// so a rider at z = 2 sits inside the basket.
    static func balloon(theme: CastleTheme, scale s: CGFloat) -> SKNode {
        let root = SKNode()
        let size = CGSize(width: s * 2.2, height: s * 3.8)
        let anchor = CGPoint(x: 0.5, y: 1 - 340.0 / 380.0)
        if let back = artTexture("balloon_\(theme.rawValue)") {
            let sprite = SKSpriteNode(texture: back, size: size)
            sprite.anchorPoint = anchor
            sprite.zPosition = 1
            root.addChild(sprite)
        }
        if let front = artTexture("balloon_front") {
            let sprite = SKSpriteNode(texture: front, size: size)
            sprite.anchorPoint = anchor
            sprite.zPosition = 3
            root.addChild(sprite)
        }
        return root
    }

    /// Where a rider should land, in the balloon's local coordinates.
    static func basketSeat(scale s: CGFloat) -> CGPoint {
        CGPoint(x: 0, y: s * 0.42)
    }

    // MARK: Effects

    static func dizzyStars(radius r: CGFloat) -> SKNode {
        let ring = SKNode()
        for i in 0..<3 {
            let a = CGFloat(i) * (.pi * 2 / 3)
            ring.addChild(emoji("⭐", size: r * 0.5, at: CGPoint(x: cos(a) * r, y: sin(a) * r * 0.4)))
        }
        ring.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 0.6)))
        return ring
    }

    static func popWord(_ text: String, size: CGFloat, color: UIColor = .white) -> SKNode {
        let root = SKNode()
        let back = SKLabelNode(text: text)
        back.fontName = "AvenirNext-Heavy"
        back.fontSize = size
        back.fontColor = UIColor(hex: 0x7C4DFF)
        back.position = CGPoint(x: 2, y: -3)
        root.addChild(back)
        let front = SKLabelNode(text: text)
        front.fontName = "AvenirNext-Heavy"
        front.fontSize = size
        front.fontColor = color
        root.addChild(front)
        root.setScale(0.4)
        root.run(.sequence([
            .scale(to: 1.15, duration: 0.15),
            .scale(to: 1.0, duration: 0.1),
            .group([.moveBy(x: 0, y: size * 1.4, duration: 0.7), .fadeOut(withDuration: 0.7)]),
            .removeFromParent()
        ]))
        return root
    }

    /// Same look as popWord, but stays put (used for the FINISH banner).
    static func popWordStatic(_ text: String, size: CGFloat) -> SKNode {
        let root = SKNode()
        let back = SKLabelNode(text: text)
        back.fontName = "AvenirNext-Heavy"
        back.fontSize = size
        back.fontColor = UIColor(hex: 0x7C4DFF)
        back.position = CGPoint(x: 2, y: -3)
        root.addChild(back)
        let front = SKLabelNode(text: text)
        front.fontName = "AvenirNext-Heavy"
        front.fontSize = size
        front.fontColor = .white
        root.addChild(front)
        return root
    }

    static func confetti(in parent: SKNode, at point: CGPoint, spread: CGFloat) {
        let colors: [UIColor] = [0xFF7FC4, 0x7C4DFF, 0xFFD93D, 0x34C77B, 0x4D96FF].map { UIColor(hex: $0) }
        for _ in 0..<36 {
            let bit = SKSpriteNode(color: colors.randomElement()!, size: CGSize(width: 7, height: 11))
            bit.position = point
            bit.zPosition = 90
            parent.addChild(bit)
            let dx = CGFloat.random(in: -spread...spread)
            let dy = CGFloat.random(in: spread * 0.3...spread * 1.2)
            let up = SKAction.moveBy(x: dx, y: dy, duration: 0.45)
            up.timingMode = .easeOut
            let down = SKAction.moveBy(x: dx * 0.3, y: -spread * 1.6, duration: 1.1)
            down.timingMode = .easeIn
            bit.run(.sequence([
                .group([.sequence([up, down]),
                        .rotate(byAngle: .pi * CGFloat.random(in: 2...6), duration: 1.55),
                        .sequence([.wait(forDuration: 1.0), .fadeOut(withDuration: 0.55)])]),
                .removeFromParent()
            ]))
        }
    }

    static func sparkleBurst(in parent: SKNode, at point: CGPoint, size: CGFloat) {
        for i in 0..<8 {
            let a = CGFloat(i) / 8 * .pi * 2
            let s = emoji("✨", size: size * 0.35, at: point)
            s.zPosition = 90
            parent.addChild(s)
            s.run(.sequence([
                .group([.moveBy(x: cos(a) * size, y: sin(a) * size, duration: 0.4), .fadeOut(withDuration: 0.45)]),
                .removeFromParent()
            ]))
        }
    }
}
