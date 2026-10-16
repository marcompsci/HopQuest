import SwiftUI
import SpriteKit

/// The playable game a child builds in Game Maker. Their Python decides the world, the hero, how many stars,
/// what a tap does (on_tap) and what happens when a star is caught (on_star).
final class CodeGameScene: SKScene {
    let program: GameProgram
    var onScore: ((Int?) -> Void)?
    var onMessage: ((String) -> Void)?
    var onError: ((PyError) -> Void)?

    private var hero: BuddySprite?
    private var stars: [SKSpriteNode] = []
    private var bubbles: [SKNode] = []
    private var ground: SKSpriteNode?
    private var decorations: [SKShapeNode] = []
    private var world: String?
    private var pace: CGFloat = 150
    /// Bubbles can't bump again for a moment after a bump.
    private var bumpCooldown = 0.0
    private var groundY: CGFloat = 0
    private var heroY: CGFloat = 0
    private var velocity: CGFloat = 0
    private var airborne = false
    private var stride = 0.0
    private var lastTime: TimeInterval = 0
    private var built = false
    private var bubble: SKNode?
    private let gravity: CGFloat = 1500

    init(size: CGSize, program: GameProgram) {
        self.program = program
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func colors(_ world: String?) -> (sky: UInt32, ground: UInt32, accent: UInt32) {
        switch world {
        case "meadow": return (0x9FDCFF, 0x6CC24A, 0xFFE66D)
        case "night": return (0x1B2450, 0x2F4F3A, 0xFFF7B0)
        case "ocean": return (0x7FD3F7, 0xF2D59A, 0x2F8FD8)
        case "candy": return (0xFFD6EC, 0xFF9CCB, 0xB983FF)
        default: return (0xD7DCE6, 0xAEB7C7, 0x8791A6)
        }
    }

    override func didMove(to view: SKView) {
        guard !built else { return }
        built = true
        let setup = program.setup
        groundY = size.height * 0.22
        pace = CGFloat(GameProgram.pointsPerSecond(setup.speed))

        let g = SKSpriteNode(color: .clear, size: CGSize(width: size.width * 2, height: groundY))
        g.anchorPoint = CGPoint(x: 0.5, y: 0)
        g.position = CGPoint(x: size.width / 2, y: 0)
        addChild(g)
        ground = g

        // a few world decorations
        for i in 0..<6 {
            let deco = SKShapeNode(circleOfRadius: CGFloat(4 + (i % 3) * 3))
            deco.strokeColor = .clear
            deco.position = CGPoint(x: size.width * CGFloat(i) / 6 + 30, y: size.height * (0.62 + 0.05 * CGFloat(i % 3)))
            addChild(deco)
            decorations.append(deco)
        }
        paint(setup.background, animated: false)

        if setup.background == nil {
            label("Add set_background() to pick a world", y: size.height * 0.75)
        }

        if let id = setup.hero {
            let h = BuddySprite(character: Roster.character(id: id))
            heroY = groundY
            h.position = CGPoint(x: size.width * 0.24, y: heroY)
            h.zPosition = 10
            addChild(h)
            hero = h
        } else {
            label("Add add_player() to put your hero in the game", y: size.height * 0.5)
        }

        for i in 0..<setup.stars {
            guard let tex = SpriteFactory.artTexture("goal_star") else { break }
            let s = SKSpriteNode(texture: tex, size: CGSize(width: 40, height: 40))
            s.position = CGPoint(x: size.width + CGFloat(i) * size.width / CGFloat(max(1, setup.stars)) + 40, y: starHeight())
            s.zPosition = 5
            s.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.4), .scale(to: 1, duration: 0.4)])))
            addChild(s)
            stars.append(s)
        }
        for i in 0..<setup.bubbles {
            let b = Self.makeBubble()
            b.position = CGPoint(x: size.width * 1.3 + CGFloat(i) * size.width * 0.55, y: groundY + 26)
            b.zPosition = 6
            addChild(b)
            bubbles.append(b)
        }
        onScore?(program.score)
        applyEffects()   // say() in the setup code shows right away
    }

    /// Colors the sky, ground and decorations for a world.
    private func paint(_ newWorld: String?, animated: Bool) {
        world = newWorld
        let c = Self.colors(newWorld)
        let sky = UIColor(hex: c.sky)
        backgroundColor = sky
        if animated {
            ground?.run(.colorize(with: UIColor(hex: c.ground), colorBlendFactor: 1, duration: 0.6))
        } else {
            ground?.color = UIColor(hex: c.ground)
        }
        for d in decorations {
            d.fillColor = UIColor(hex: c.accent).withAlphaComponent(newWorld == "night" ? 0.9 : 0.55)
        }
    }

    /// A soft, shiny soap bubble to jump over.
    private static func makeBubble() -> SKNode {
        let root = SKNode()
        let ball = SKShapeNode(circleOfRadius: 22)
        ball.fillColor = UIColor(hex: 0xBFE8FF).withAlphaComponent(0.55)
        ball.strokeColor = UIColor(hex: 0x6FC3F0)
        ball.lineWidth = 3
        root.addChild(ball)
        let shine = SKShapeNode(circleOfRadius: 6)
        shine.fillColor = UIColor.white.withAlphaComponent(0.85)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -8, y: 8)
        root.addChild(shine)
        root.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 0.6), .moveBy(x: 0, y: -6, duration: 0.6)])))
        return root
    }

    private func starHeight() -> CGFloat {
        groundY + 40 + CGFloat.random(in: 0...max(40, size.height * 0.4))
    }

    private func label(_ text: String, y: CGFloat) {
        let l = SKLabelNode(text: text)
        l.fontName = "AvenirNext-Heavy"
        l.fontSize = 16
        l.fontColor = UIColor(hex: 0x2B1B3D)
        l.position = CGPoint(x: size.width / 2, y: y)
        l.zPosition = 20
        addChild(l)
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 1.0 / 60 : min(0.05, currentTime - lastTime)
        lastTime = currentTime
        guard let hero else { return }

        // hero physics
        if airborne {
            velocity -= gravity * CGFloat(dt)
            heroY += velocity * CGFloat(dt)
            if heroY <= groundY {
                heroY = groundY
                airborne = false
                velocity = 0
            }
        }
        hero.position.y = heroY
        stride += dt * 1.4
        hero.update(stride: stride, facing: .east, moving: !airborne)

        // stars slide past; catch them by jumping
        for s in stars {
            s.position.x -= pace * CGFloat(dt)
            if s.position.x < -30 {
                s.position = CGPoint(x: size.width + 40 + CGFloat.random(in: 0...120), y: starHeight())
            }
            let heroCenter = CGPoint(x: hero.position.x, y: hero.position.y + 45)
            if hypot(s.position.x - heroCenter.x, s.position.y - heroCenter.y) < 48 {
                catchStar(s)
            }
        }

        // bubbles float along the ground; jump over them
        bumpCooldown = max(0, bumpCooldown - dt)
        for b in bubbles {
            b.position.x -= pace * 0.8 * CGFloat(dt)
            if b.position.x < -40 {
                b.position.x = size.width + 60 + CGFloat.random(in: 0...size.width * 0.6)
            }
            let heroCenter = CGPoint(x: hero.position.x, y: hero.position.y + 30)
            if bumpCooldown == 0, hypot(b.position.x - heroCenter.x, b.position.y - heroCenter.y) < 42 {
                bump(b)
            }
        }
    }

    private func bump(_ b: SKNode) {
        bumpCooldown = 0.8
        let pop = SKShapeNode(circleOfRadius: 22)
        pop.strokeColor = UIColor(hex: 0x6FC3F0)
        pop.lineWidth = 3
        pop.position = b.position
        pop.zPosition = 30
        addChild(pop)
        pop.run(.sequence([.group([.scale(to: 1.8, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
        b.position.x = size.width + 80 + CGFloat.random(in: 0...size.width * 0.5)
        hero?.run(.sequence([.rotate(byAngle: 0.25, duration: 0.08), .rotate(byAngle: -0.5, duration: 0.12), .rotate(toAngle: 0, duration: 0.08)]))
        SoundFX.shared.play(.pop)
        guard program.hasBumpEvent else { return }
        do {
            try program.bumped()
        } catch let e as PyError {
            onError?(e)
        } catch {}
        applyEffects()
        onScore?(program.score)
    }

    private func catchStar(_ s: SKSpriteNode) {
        let burst = VillageArt.propNode("sparkle")
        burst.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        burst.position = s.position
        burst.zPosition = 30
        addChild(burst)
        burst.run(.sequence([.group([.scale(to: 2.2, duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        s.position = CGPoint(x: size.width + 40 + CGFloat.random(in: 0...160), y: starHeight())
        SoundFX.shared.play(.coin)
        do {
            try program.starCollected()
        } catch let e as PyError {
            onError?(e)
        } catch {}
        applyEffects()
        onScore?(program.score)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard hero != nil else { return }
        guard program.hasTapEvent else {
            onMessage?("Your hero needs an on_tap() event to jump. That's lesson 3!")
            return
        }
        do {
            try program.tap()
        } catch let e as PyError {
            onError?(e)
        } catch {}
        applyEffects()
    }

    private func applyEffects() {
        for effect in program.drainEffects() {
            switch effect {
            case .jump(let h):
                guard !airborne else { continue }
                airborne = true
                // speed needed to rise h points (scaled a bit so 80-160 feel good on a phone)
                velocity = sqrt(2 * gravity * CGFloat(h) * 1.4)
                SoundFX.shared.play(.hop)
            case .say(let text):
                showBubble(text)
                onMessage?(text)
            case .background(let w):
                guard w != world else { continue }
                paint(w, animated: true)
                SoundFX.shared.play(.chime)
            case .speed(let n):
                pace = CGFloat(GameProgram.pointsPerSecond(n))
            }
        }
    }

    private func showBubble(_ text: String) {
        bubble?.removeFromParent()
        guard let hero else { return }
        let root = SKNode()
        let l = SKLabelNode(text: text)
        l.fontName = "AvenirNext-Heavy"
        l.fontSize = 17
        l.fontColor = UIColor(hex: 0x2B1B3D)
        l.verticalAlignmentMode = .center
        let bg = SKShapeNode(rectOf: CGSize(width: l.frame.width + 28, height: 36), cornerRadius: 16)
        bg.fillColor = .white
        bg.strokeColor = UIColor(hex: 0x2B1B3D)
        bg.lineWidth = 3
        root.addChild(bg)
        root.addChild(l)
        root.position = CGPoint(x: min(max(hero.position.x + 40, l.frame.width / 2 + 20), size.width - l.frame.width / 2 - 20),
                                y: heroY + 140)
        root.zPosition = 40
        addChild(root)
        bubble = root
        root.run(.sequence([.wait(forDuration: 2.5), .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }
}

/// SwiftUI wrapper with a score display.
struct CodeGameStageView: View {
    let program: GameProgram
    var onMessage: (String) -> Void = { _ in }
    var onError: (PyError) -> Void = { _ in }

    @State private var scene: CodeGameScene?
    @State private var score: Int?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60)
                        .id(ObjectIdentifier(scene))
                } else {
                    Color(hex: 0xD7DCE6)
                }
                if let score {
                    Text("⭐ score: \(score)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(.white.opacity(0.9)))
                        .padding(10)
                }
                Text(program.hasTapEvent ? "Tap to jump!" : "")
                    .font(.kid(13, .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .onAppear { build(geo.size) }
            .onChange(of: geo.size) { _, s in build(s) }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityLabel("Your game. Tap to make your hero jump.")
    }

    private func build(_ size: CGSize) {
        guard scene == nil, size.width > 0 else { return }
        let s = CodeGameScene(size: size, program: program)
        s.onScore = { v in score = v }
        s.onMessage = onMessage
        s.onError = onError
        scene = s
    }
}
