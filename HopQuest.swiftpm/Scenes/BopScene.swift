import SpriteKit

/// Pillow Bop 2 (v3.6): four arenas that play a little differently. Picked on the how-to card.
enum BopArena: String, CaseIterable, Identifiable {
    case cloud, ice, bouncy, moon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cloud: return "Cloud Island"
        case .ice: return "Ice Rink"
        case .bouncy: return "Bouncy Castle"
        case .moon: return "Moon Base"
        }
    }

    var icon: String {
        switch self {
        case .cloud: return "☁️"
        case .ice: return "⛸️"
        case .bouncy: return "🏰"
        case .moon: return "🌙"
        }
    }

    var blurb: String {
        switch self {
        case .cloud: return "The classic floating island."
        case .ice: return "Slippery! Everyone slides after a bop."
        case .bouncy: return "Boing! Land and bounce back up."
        case .moon: return "Low gravity: big, floaty jumps."
        }
    }

    /// A science line read when the match starts.
    var fact: String? {
        switch self {
        case .cloud: return nil
        case .ice: return "Ice is slippery because there is very little friction, so it's hard to stop!"
        case .bouncy: return "Springy floors push back when you land on them. That's why you bounce!"
        case .moon: return "The Moon's gravity is only about one sixth of Earth's, so you can jump really high there."
        }
    }

    /// Gravity compared to Cloud Island.
    var gravity: CGFloat { self == .moon ? 0.45 : 1 }
    /// How quickly feet grip the ground (lower = slidier).
    var grip: CGFloat { self == .ice ? 2.2 : 14 }
    /// How much of the landing speed bounces back up (0 = none).
    var bounce: CGFloat { self == .bouncy ? 0.55 : 0 }
    var sky: UInt32 {
        switch self {
        case .cloud: return 0xBFE6FF
        case .ice: return 0xDDF3FF
        case .bouncy: return 0xFFD6EC
        case .moon: return 0x1E1B4B
        }
    }
    /// Tint for the island and clouds.
    var tint: UInt32? {
        switch self {
        case .cloud: return nil
        case .ice: return 0xBFE9FF
        case .bouncy: return 0xFF9FD0
        case .moon: return 0xB8B8C8
        }
    }
    var decorations: [String] {
        switch self {
        case .cloud: return []
        case .ice: return ["❄️", "⛄", "❄️"]
        case .bouncy: return ["🎈", "🎀", "🎈"]
        case .moon: return ["⭐", "🪐", "✨", "🚀"]
        }
    }
}
import SwiftUI
import UIKit

/// Live numbers for the SwiftUI HUD on top of the arena.
final class BopHUD: ObservableObject {
    struct Entry: Identifiable, Equatable {
        let id: String
        let character: GameCharacter
        var bops: Int
        /// 0...1, how giggly (and how far a bop pushes them).
        var giggles: Double
        var floating: Bool
        let isPlayer: Bool
        /// 0 (⭐) or 1 (💜) when two people play; nil for computer buddies.
        var seat: Int? = nil

        static func == (a: Entry, b: Entry) -> Bool {
            a.id == b.id && a.bops == b.bops && abs(a.giggles - b.giggles) < 0.01 && a.floating == b.floating
        }
    }

    @Published var entries: [Entry] = []
    @Published var timeLeft = 60
    @Published var countdown: String?
    @Published var message: String?
    @Published var question: Question?
    @Published var giant = false
    @Published var giant2 = false
    @Published var twoPlayer = false
    @Published var brainRight = 0
    @Published var finished = false
    /// Final ranking, best first.
    @Published var ranking: [Entry] = []
}

/// Pillow Bop Arena: a gentle party-brawler on a floating island.
/// Bop friends with a pillow to push them toward the edge. Nobody gets hurt and nobody is "knocked out":
/// if you fall off, a balloon floats you back after two seconds. Score = bops landed, not damage.
final class BopScene: SKScene {

    // Controls (set from SwiftUI)
    var moveInput: CGFloat = 0
    /// The second player's walk input (two players on one phone).
    var moveInput2: CGFloat = 0

    let hud: BopHUD
    let matchLength: TimeInterval = 60

    final class Fighter {
        let node = SKNode()
        let body = SKNode()
        let pillow: SKSpriteNode
        let character: GameCharacter
        /// A person playing (not a computer buddy).
        let isPlayer: Bool
        var seat = 0
        var pos: CGPoint = .zero          // feet
        var vel: CGVector = .zero
        var facing: CGFloat = 1
        var onGround = false
        var airJumps = 1
        var bops = 0
        var giggles: CGFloat = 0          // 0...100
        var stunUntil: TimeInterval = 0
        var bopReadyAt: TimeInterval = 0
        var swingingUntil: TimeInterval = 0
        var safeUntil: TimeInterval = 0
        var floatingSince: TimeInterval?
        var inBalloon = false
        var lastHitBy: Fighter?
        var giantUntil: TimeInterval = 0
        // bot brain
        var thinkAt: TimeInterval = 0
        var wantDir: CGFloat = 0
        var target: Fighter?
        init(character: GameCharacter, isPlayer: Bool, pillow: SKSpriteNode) {
            self.character = character
            self.isPlayer = isPlayer
            self.pillow = pillow
        }
    }

    private struct Platform {
        let minX: CGFloat
        let maxX: CGFloat
        let y: CGFloat
        let solid: Bool       // the island is solid; clouds can be jumped up through
    }

    private let playerCharacter: GameCharacter
    /// The second player's buddy (two players on one phone), or nil.
    private let partnerCharacter: GameCharacter?
    private var twoPlayer: Bool { partnerCharacter != nil }
    private let theme: CastleTheme
    private var fighters: [Fighter] = []
    private var player: Fighter { fighters[0] }
    private var humans: [Fighter] { fighters.filter(\.isPlayer) }
    /// Who popped the Brain Bubble (they get the giant pillow).
    private var bubblePopper: Fighter?
    private var platforms: [Platform] = []
    /// The arena (set before the match starts).
    var arena: BopArena = .cloud { didSet { if arena != oldValue { applyArena() } } }
    private var arenaArt: [SKSpriteNode] = []
    private var backdrop: SKSpriteNode?
    private var arenaDecor = SKNode()
    private var bubble: SKNode?
    private var bubbleUntil: TimeInterval = 0
    private var bubbleTimes: [TimeInterval] = [14, 36]
    private let questions: [Question]
    private var questionIndex = 0

    private var groundY: CGFloat = 0
    private var islandHalf: CGFloat = 0
    private var unit: CGFloat = 1            // scales physics to screen size
    private let charSize: CGFloat = 54

    private var waiting = true
    private var started = false
    private var ended = false
    private var countdownBegan = false
    private var matchStart: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    private var now: TimeInterval = 0
    private var lastHudPush: TimeInterval = 0

    init(size: CGSize, character: GameCharacter, partner: GameCharacter? = nil, theme: CastleTheme, hud: BopHUD) {
        self.playerCharacter = character
        self.partnerCharacter = partner
        self.theme = theme
        self.hud = hud
        hud.twoPlayer = partner != nil
        self.questions = QuestionBank.deck(for: Chapters.teamHop)
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    override func didMove(to view: SKView) {
        guard fighters.isEmpty else { return }
        backgroundColor = UIColor(hex: 0xBFE6FF)
        unit = min(size.width / 390, 1.4)
        groundY = size.height * 0.40

        if let tex = SpriteFactory.artTexture("arena_bg") {
            let bg = SKSpriteNode(texture: tex)
            let scale = max(size.width / 400, size.height / 860)
            bg.size = CGSize(width: 400 * scale, height: 860 * scale)
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.zPosition = -20
            addChild(bg)
            backdrop = bg
        }

        // floating island
        let islandW = size.width * 0.92
        islandHalf = islandW * 0.45
        if let tex = SpriteFactory.artTexture("arena_island") {
            let island = SKSpriteNode(texture: tex, size: CGSize(width: islandW, height: islandW * 380 / 800))
            island.anchorPoint = CGPoint(x: 0.5, y: 1 - 50.0 / 380.0)
            island.position = CGPoint(x: size.width / 2, y: groundY)
            island.zPosition = -5
            addChild(island)
            arenaArt.append(island)
            island.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 3, duration: 1.6), .moveBy(x: 0, y: -3, duration: 1.6)
            ])))
        }
        platforms.append(Platform(minX: size.width / 2 - islandHalf, maxX: size.width / 2 + islandHalf, y: groundY, solid: true))

        // two cloud platforms and one high middle cloud
        let cloudSpots: [(CGFloat, CGFloat, CGFloat)] = [(0.24, 140, 120), (0.76, 140, 120), (0.5, 235, 110)]
        for (fx, dy, w) in cloudSpots {
            let cw = w * unit
            let x = size.width * fx
            let y = groundY + dy * unit
            if let tex = SpriteFactory.artTexture("cloud_platform") {
                let cloud = SKSpriteNode(texture: tex, size: CGSize(width: cw, height: cw * 138 / 360))
                cloud.anchorPoint = CGPoint(x: 0.5, y: 1 - 46.0 / 138.0)
                cloud.position = CGPoint(x: x, y: y)
                cloud.zPosition = -4
                addChild(cloud)
                arenaArt.append(cloud)
            }
            platforms.append(Platform(minX: x - cw * 0.42, maxX: x + cw * 0.42, y: y, solid: false))
        }

        arenaDecor.zPosition = -15
        addChild(arenaDecor)
        applyArena()

        buildFighters()
        pushHud(force: true)
    }

    /// Recolors the arena and adds its decorations.
    private func applyArena() {
        guard !platforms.isEmpty else { return }
        backgroundColor = UIColor(hex: arena.sky)
        backdrop?.color = UIColor(hex: arena.sky)
        backdrop?.colorBlendFactor = arena == .cloud ? 0 : (arena == .moon ? 0.85 : 0.45)
        for node in arenaArt {
            node.color = UIColor(hex: arena.tint ?? 0xFFFFFF)
            node.colorBlendFactor = arena.tint == nil ? 0 : 0.5
        }
        arenaDecor.removeAllChildren()
        for (i, e) in arena.decorations.enumerated() {
            let n = SpriteFactory.emoji(e, size: 34 * unit)
            let fx = CGFloat(i + 1) / CGFloat(arena.decorations.count + 1)
            n.position = CGPoint(x: size.width * fx, y: size.height * (i % 2 == 0 ? 0.82 : 0.74))
            n.alpha = 0.85
            n.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 1.2 + Double(i) * 0.2), .moveBy(x: 0, y: -6, duration: 1.2 + Double(i) * 0.2)])))
            arenaDecor.addChild(n)
        }
    }

    private func buildFighters() {
        let people = [playerCharacter] + (partnerCharacter.map { [$0] } ?? [])
        var others = Roster.all.filter { c in !people.contains { $0.id == c.id } }.shuffled()
        let botCount = 4 - people.count
        // one friend from each family when possible, so the arena looks varied
        var picks: [GameCharacter] = []
        for family in CharacterFamily.allCases.shuffled() where picks.count < botCount {
            if let c = others.first(where: { $0.family == family && $0.family != playerCharacter.family }) {
                picks.append(c)
                others.removeAll { $0.id == c.id }
            }
        }
        while picks.count < botCount, let c = others.popLast() { picks.append(c) }

        let all = people + picks
        let starts: [CGFloat] = [-0.55, 0.55, -0.15, 0.15]
        for (i, c) in all.enumerated() {
            let f = makeFighter(c, isPlayer: i < people.count)
            f.seat = i < people.count ? i : 0
            f.pos = CGPoint(x: size.width / 2 + islandHalf * starts[i], y: groundY)
            f.facing = starts[i] < 0 ? 1 : -1
            f.onGround = true
            fighters.append(f)
            addChild(f.node)
            place(f)
        }
        // a little arrow so kids can find themselves (⭐ and 💜 when two people play)
        for f in humans {
            let arrow = SKLabelNode(text: twoPlayer ? (f.seat == 0 ? "⭐" : "💜") : "▼")
            arrow.fontName = "AvenirNext-Heavy"
            arrow.fontSize = 20
            arrow.fontColor = UIColor(hex: theme.accentHex)
            arrow.position = CGPoint(x: 0, y: charSize * 1.25)
            arrow.name = "me"
            arrow.run(.repeatForever(.sequence([.moveBy(x: 0, y: 5, duration: 0.4), .moveBy(x: 0, y: -5, duration: 0.4)])))
            f.node.addChild(arrow)
        }
    }

    private func makeFighter(_ c: GameCharacter, isPlayer: Bool) -> Fighter {
        let pillowTex = SpriteFactory.artTexture("pillow")
        let pillow = SKSpriteNode(texture: pillowTex, size: CGSize(width: 46, height: 31))
        pillow.color = UIColor(hex: c.colorHex)
        pillow.colorBlendFactor = 0.35
        pillow.zPosition = 2
        let f = Fighter(character: c, isPlayer: isPlayer, pillow: pillow)
        f.node.zPosition = isPlayer ? 12 : 10

        let shadow = SKShapeNode(ellipseOf: CGSize(width: charSize * 0.8, height: 9))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.15)
        shadow.strokeColor = .clear
        shadow.name = "shadow"
        f.node.addChild(shadow)

        let art = SpriteFactory.character(c, size: charSize)
        art.position = CGPoint(x: 0, y: charSize * 0.42)
        art.zPosition = 1
        f.body.addChild(art)
        f.body.addChild(pillow)
        f.node.addChild(f.body)
        restPillow(f)
        return f
    }

    private func restPillow(_ f: Fighter) {
        f.pillow.removeAction(forKey: "swing")
        let big: CGFloat = now < f.giantUntil ? 1.7 : 1
        f.pillow.setScale(big)
        f.pillow.position = CGPoint(x: 22, y: charSize * 0.55)
        f.pillow.zRotation = 0.5
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : CGFloat(min(currentTime - lastTime, 1.0 / 20.0))
        lastTime = currentTime
        now += Double(dt)        // game clock: stands still while a Brain Gate is open

        if !countdownBegan && !waiting {
            countdownBegan = true
            runCountdown()
        }

        for f in fighters {
            if started && !ended {
                if f.isPlayer { steerPlayer(f) } else { think(f) }
            } else {
                f.wantDir = 0
            }
            physics(f, dt)
            place(f)
        }

        if started && !ended {
            let elapsed = now - matchStart
            updateBubble(elapsed)
            if elapsed >= matchLength { endMatch() }
        }
        pushHud(force: false)
    }

    /// Starts the countdown once the how-to card is closed.
    func begin() {
        waiting = false
    }

    private func runCountdown() {
        let steps = ["3", "2", "1", "BOP!"]
        var actions: [SKAction] = [.wait(forDuration: 0.8)]
        for (i, s) in steps.enumerated() {
            actions.append(.run { [weak self] in
                guard let self else { return }
                self.hud.countdown = s
                Narrator.shared.say(s == "BOP!" ? "Bop!" : s)
                if i == steps.count - 1 {
                    self.started = true
                    self.matchStart = self.now
                    Haptics.success(.go)
                } else {
                    Haptics.tap(.beep)
                }
            })
            actions.append(.wait(forDuration: 0.8))
        }
        actions.append(.run { [weak self] in self?.hud.countdown = nil })
        run(.sequence(actions))
    }

    // MARK: Movement

    private func steerPlayer(_ f: Fighter) {
        f.wantDir = f.seat == 1 ? moveInput2 : moveInput
    }

    /// "⭐ " or "💜 " in front of a message when two people are playing.
    private func who(_ f: Fighter) -> String {
        twoPlayer ? (f.seat == 0 ? "⭐ " : "💜 ") : ""
    }

    private func human(_ seat: Int) -> Fighter? { humans.first { $0.seat == seat } }

    private func physics(_ f: Fighter, _ dt: CGFloat) {
        guard dt > 0 else { return }
        if let since = f.floatingSince {
            if !f.inBalloon && now - since > 2.0 { respawn(f) }
            return
        }
        let gravity: CGFloat = -1900 * unit * arena.gravity
        let runSpeed: CGFloat = 240 * unit
        let stunned = now < f.stunUntil

        if !stunned {
            let target = f.wantDir * runSpeed
            let accel: CGFloat = f.onGround ? arena.grip : 6
            f.vel.dx += (target - f.vel.dx) * min(1, accel * dt)
            if f.wantDir != 0 && now > f.swingingUntil { f.facing = f.wantDir > 0 ? 1 : -1 }
        } else {
            // gentle air drag while being pushed
            f.vel.dx *= (1 - min(1, 1.2 * dt))
        }
        f.vel.dy += gravity * dt

        let oldY = f.pos.y
        f.pos.x += f.vel.dx * dt
        f.pos.y += f.vel.dy * dt

        // landing
        f.onGround = false
        if f.vel.dy <= 0 {
            for p in platforms where f.pos.x >= p.minX && f.pos.x <= p.maxX {
                if oldY >= p.y - 2 && f.pos.y <= p.y {
                    f.pos.y = p.y
                    if arena.bounce > 0 && f.vel.dy < -520 * unit {
                        // Bouncy Castle: spring back up (it doesn't count as landing yet)
                        f.vel.dy = -f.vel.dy * arena.bounce
                        landPuff(f)
                        break
                    }
                    f.vel.dy = 0
                    if !f.onGround && oldY > p.y + 30 { landPuff(f) }
                    f.onGround = true
                    f.airJumps = 1
                    break
                }
            }
        }
        if f.onGround && stunned { f.vel.dx *= (1 - min(1, (arena == .ice ? 1.2 : 6) * dt)) }

        // fell off the world → float back
        if f.pos.y < -80 || f.pos.x < -120 || f.pos.x > size.width + 120 {
            fellOff(f)
        }
    }

    private func place(_ f: Fighter) {
        f.node.position = f.pos
        f.body.xScale = f.facing
        if let shadow = f.node.childNode(withName: "shadow") {
            // shadow sits on the platform below
            let below = platforms.filter { f.pos.x >= $0.minX && f.pos.x <= $0.maxX && $0.y <= f.pos.y + 1 }.map(\.y).max()
            if let y = below, f.floatingSince == nil {
                shadow.isHidden = false
                shadow.position = CGPoint(x: 0, y: y - f.pos.y)
                let h = f.pos.y - y
                shadow.setScale(max(0.4, 1 - h / 300))
            } else {
                shadow.isHidden = true
            }
        }
    }

    func jump(seat: Int = 0) {
        guard started, !ended, let f = human(seat) else { return }
        jump(f)
    }

    private func jump(_ f: Fighter) {
        guard f.floatingSince == nil, now >= f.stunUntil - 0.15 else { return }
        if f.onGround {
            f.vel.dy = 760 * unit
            f.onGround = false
            if f.isPlayer { SoundFX.shared.play(.hop) }
        } else if f.airJumps > 0 {
            f.airJumps -= 1
            f.vel.dy = 680 * unit
            puff(at: f.pos, in: self)
            if f.isPlayer { SoundFX.shared.play(.hop) }
        } else {
            return
        }
        squash(f)
    }

    private func squash(_ f: Fighter) {
        f.body.removeAction(forKey: "squash")
        f.body.yScale = 1
        f.body.run(.sequence([.scaleY(to: 1.12, duration: 0.08), .scaleY(to: 1, duration: 0.15)]), withKey: "squash")
    }

    // MARK: Bops

    func bop(seat: Int = 0) {
        guard started, !ended, let f = human(seat) else { return }
        bop(f)
    }

    private func bop(_ f: Fighter) {
        guard f.floatingSince == nil, now >= f.bopReadyAt, now >= f.stunUntil else { return }
        f.bopReadyAt = now + 0.42
        f.swingingUntil = now + 0.25
        let giant = now < f.giantUntil
        let big: CGFloat = giant ? 1.7 : 1

        // swing the pillow over the head and down in front
        f.pillow.removeAction(forKey: "swing")
        let up = SKAction.group([.rotate(toAngle: 1.9, duration: 0.07), .move(to: CGPoint(x: 6, y: charSize * 1.0), duration: 0.07)])
        let down = SKAction.group([.rotate(toAngle: -0.6, duration: 0.09), .move(to: CGPoint(x: 34 * big, y: charSize * 0.45), duration: 0.09)])
        down.timingMode = .easeIn
        let back = SKAction.group([.rotate(toAngle: 0.5, duration: 0.16), .move(to: CGPoint(x: 22, y: charSize * 0.55), duration: 0.16)])
        f.pillow.setScale(big)
        f.pillow.run(.sequence([up, down, .run { [weak self] in self?.resolveBop(f) }, back]), withKey: "swing")
        if f.isPlayer { SoundFX.shared.play(.whoosh, volume: 0.6) }
    }

    private func resolveBop(_ f: Fighter) {
        guard started, !ended, f.floatingSince == nil else { return }
        let giant = now < f.giantUntil
        let reach: CGFloat = (giant ? 96 : 64) * unit
        var hitAny = false
        var hitPlayer = false
        for t in fighters where t !== f && t.floatingSince == nil && now >= t.safeUntil {
            let dx = (t.pos.x - f.pos.x) * f.facing
            let dy = t.pos.y - f.pos.y
            guard dx > -12, dx < reach, abs(dy) < 56 * unit else { continue }
            hitAny = true
            if t.isPlayer { hitPlayer = true }
            f.bops += 1
            t.lastHitBy = f
            t.giggles = min(100, t.giggles + (giant ? 18 : 11))
            let power = (giant ? 1.5 : 1.0) * (1 + t.giggles / 55)
            t.vel.dx = f.facing * 230 * unit * power
            t.vel.dy = (330 + t.giggles * 2.6) * unit * (giant ? 1.2 : 1)
            t.onGround = false
            t.stunUntil = now + 0.3 + Double(t.giggles) / 300
            t.facing = -f.facing
            restPillow(t)
            hitFX(on: t, by: f)
        }
        if hitAny {
            if f.isPlayer {
                Haptics.bump(.boing)
            } else if hitPlayer {
                Haptics.bump(.pop)
            } else {
                SoundFX.shared.play(.pop, volume: 0.5)
            }
        }
    }

    private func hitFX(on t: Fighter, by f: Fighter) {
        let word = SpriteFactory.popWord(["BOP!", "BOOP!", "FLUFF!", "WHUMP!"].randomElement()!, size: 26)
        word.position = CGPoint(x: t.pos.x, y: t.pos.y + charSize * 1.1)
        word.zPosition = 80
        addChild(word)
        // feathers
        for _ in 0..<7 {
            let feather = SKShapeNode(ellipseOf: CGSize(width: 9, height: 4))
            feather.fillColor = .white
            feather.strokeColor = UIColor(hex: 0x2B1B3D).withAlphaComponent(0.5)
            feather.lineWidth = 1
            feather.position = CGPoint(x: t.pos.x, y: t.pos.y + charSize * 0.6)
            feather.zPosition = 70
            feather.zRotation = .random(in: 0...(.pi))
            addChild(feather)
            let drift = SKAction.moveBy(x: .random(in: -50...50), y: .random(in: -10...50), duration: 0.9)
            drift.timingMode = .easeOut
            feather.run(.sequence([
                .group([drift, .rotate(byAngle: .random(in: -3...3), duration: 0.9), .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.4)])]),
                .removeFromParent()
            ]))
        }
        // wobble + dizzy stars on big giggles
        t.body.run(.sequence([.rotate(toAngle: -0.25 * f.facing, duration: 0.06), .rotate(toAngle: 0, duration: 0.25)]))
        if t.giggles >= 60 {
            let stars = SpriteFactory.dizzyStars(radius: 18)
            stars.position = CGPoint(x: 0, y: charSize * 1.05)
            stars.zPosition = 5
            t.node.addChild(stars)
            stars.run(.sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.2), .removeFromParent()]))
        }
    }

    // MARK: Falling & balloons

    private func fellOff(_ f: Fighter) {
        guard f.floatingSince == nil else { return }
        f.floatingSince = now
        f.node.isHidden = true
        f.vel = .zero
        if let by = f.lastHitBy, by !== f, started, !ended {
            by.bops += 2   // a boop-out bonus for whoever sent them flying
            let label = SpriteFactory.popWord("+2", size: 24, color: UIColor(hex: 0xFFD93D))
            label.position = CGPoint(x: by.pos.x, y: by.pos.y + charSize * 1.4)
            label.zPosition = 80
            addChild(label)
        }
        f.lastHitBy = nil
        let x = min(max(f.pos.x, 30), size.width - 30)
        let splash = SpriteFactory.popWord("WHEEE!", size: 22)
        splash.position = CGPoint(x: x, y: 40)
        splash.zPosition = 80
        addChild(splash)
        if f.isPlayer {
            Haptics.bump(.whoosh)
            say(who(f) + "Wheee! A balloon will float you back!")
        }
    }

    private func respawn(_ f: Fighter) {
        f.inBalloon = true
        f.giggles = 0
        f.vel = .zero
        f.stunUntil = 0
        f.giantUntil = min(f.giantUntil, now)
        restPillow(f)

        // spot on the island away from the others
        let spots: [CGFloat] = [-0.5, 0.5, 0, -0.25, 0.25]
        let x = spots.map { size.width / 2 + islandHalf * $0 }
            .max { a, b in nearest(a) < nearest(b) } ?? size.width / 2
        let landing = CGPoint(x: x, y: groundY)

        // a balloon drifts down with the buddy in the basket, then drops them off
        let s: CGFloat = 26
        let balloon = SpriteFactory.balloon(theme: theme, scale: s)
        balloon.position = CGPoint(x: x, y: size.height + 80)
        balloon.zPosition = 30
        addChild(balloon)
        let rider = SpriteFactory.character(f.character, size: 30)
        rider.position = CGPoint(x: 0, y: SpriteFactory.basketSeat(scale: s).y)
        rider.zPosition = 2
        balloon.addChild(rider)

        let drop = landing.y + charSize * 1.2
        let down = SKAction.move(to: CGPoint(x: x, y: drop), duration: 0.9)
        down.timingMode = .easeOut
        f.node.isHidden = true
        balloon.run(.sequence([
            down,
            .run { [weak self, weak f] in
                guard let self, let f else { return }
                rider.removeFromParent()
                f.inBalloon = false
                f.floatingSince = nil
                f.pos = CGPoint(x: x, y: drop - 20)
                f.vel = CGVector(dx: 0, dy: 120)
                f.safeUntil = self.now + 1.4
                f.node.isHidden = false
                f.node.run(.repeat(.sequence([.fadeAlpha(to: 0.4, duration: 0.12), .fadeAlpha(to: 1, duration: 0.12)]), count: 6))
                if f.isPlayer { Haptics.success(.pop) }
            },
            .group([.moveBy(x: 0, y: size.height, duration: 1.4), .fadeOut(withDuration: 1.4)]),
            .removeFromParent()
        ]))
    }

    private func nearest(_ x: CGFloat) -> CGFloat {
        fighters.filter { $0.floatingSince == nil }.map { abs($0.pos.x - x) }.min() ?? 999
    }

    // MARK: Friendly bots

    private func think(_ f: Fighter) {
        guard f.floatingSince == nil else { return }
        let center = size.width / 2
        let left = center - islandHalf
        let right = center + islandHalf

        // recover first: off the island's sides or below it → head home and double-jump
        let overIsland = f.pos.x > left + 6 && f.pos.x < right - 6
        if !overIsland || f.pos.y < groundY - 4 {
            f.wantDir = f.pos.x < center ? 1 : -1
            if !f.onGround && f.vel.dy < 0 && f.pos.y < groundY + 40 { jump(f) }
            return
        }

        if now >= f.thinkAt {
            f.thinkAt = now + .random(in: 0.25...0.6)
            // pick someone nearby (the player a little more often, but never ganging up)
            let others = fighters.filter { $0 !== f && $0.floatingSince == nil }
            let chasingPlayer = fighters.filter { !$0.isPlayer && $0 !== f && $0.target?.isPlayer == true }.count
            f.target = others.min { a, b in
                score(a, for: f, chasingPlayer: chasingPlayer) < score(b, for: f, chasingPlayer: chasingPlayer)
            }
            if Int.random(in: 0..<10) == 0 { f.target = nil }   // sometimes just wander
        }

        var dir: CGFloat = 0
        if let t = f.target {
            let dx = t.pos.x - f.pos.x
            let dy = t.pos.y - f.pos.y
            if abs(dx) > 40 * unit { dir = dx > 0 ? 1 : -1 }
            else { f.facing = dx >= 0 ? 1 : -1 }
            if dy > 70 * unit && f.onGround && abs(dx) < 140 * unit && Int.random(in: 0..<40) == 0 { jump(f) }
            if abs(dx) < 60 * unit && abs(dy) < 44 * unit && now >= f.bopReadyAt && Int.random(in: 0..<14) == 0 {
                f.facing = dx >= 0 ? 1 : -1
                bop(f)
            }
        } else if f.onGround && Int.random(in: 0..<90) == 0 {
            jump(f)
        }

        // don't walk off the edge on purpose
        if f.onGround && f.pos.y <= groundY + 1 {
            if (dir < 0 && f.pos.x < left + 30) || (dir > 0 && f.pos.x > right - 30) { dir = 0 }
        }
        f.wantDir = dir
    }

    private func score(_ t: Fighter, for f: Fighter, chasingPlayer: Int) -> CGFloat {
        var d = hypot(t.pos.x - f.pos.x, (t.pos.y - f.pos.y) * 1.5)
        if t.isPlayer { d *= chasingPlayer >= 1 ? 1.6 : 0.8 }
        if now < t.safeUntil { d += 400 }
        return d
    }

    // MARK: Brain Bubble

    private func updateBubble(_ elapsed: TimeInterval) {
        if bubble == nil, let next = bubbleTimes.first, elapsed >= next {
            bubbleTimes.removeFirst()
            spawnBubble()
        }
        guard let b = bubble else { return }
        if now > bubbleUntil {
            b.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
            bubble = nil
            return
        }
        // only people can pop it (bots float right past)
        guard let p = humans.first(where: { h in
            h.floatingSince == nil && hypot(h.pos.x - b.position.x, h.pos.y + charSize * 0.5 - b.position.y) < 48 * unit
        }) else { return }
        do {
            bubblePopper = p
            if twoPlayer { say(who(p) + "popped the Brain Bubble! Answer together!") }
            bubble = nil
            SpriteFactory.sparkleBurst(in: self, at: b.position, size: 50)
            b.removeFromParent()
            askQuestion()
        }
    }

    private func spawnBubble() {
        let node = SKNode()
        if let tex = SpriteFactory.artTexture("brain_bubble") {
            let sprite = SKSpriteNode(texture: tex, size: CGSize(width: 58 * unit, height: 58 * unit))
            node.addChild(sprite)
        }
        // somewhere reachable: over a cloud or the middle of the island
        // the island and the two low clouds (the high cloud sits too close to the scoreboard)
        let spots = platforms.prefix(3).map { CGPoint(x: ($0.minX + $0.maxX) / 2, y: $0.y + 64 * unit) }
        node.position = spots.randomElement() ?? CGPoint(x: size.width / 2, y: groundY + 80)
        node.zPosition = 40
        node.setScale(0.1)
        node.run(.scale(to: 1, duration: 0.3))
        node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 10, duration: 0.7), .moveBy(x: 0, y: -10, duration: 0.7)])))
        addChild(node)
        bubble = node
        bubbleUntil = now + 14
        SoundFX.shared.play(.item)
        say("A Brain Bubble! Pop it and answer the question to get a GIANT pillow!")
    }

    private func askQuestion() {
        guard !questions.isEmpty else { return }
        let q = questions[questionIndex % questions.count]
        questionIndex += 1
        isPaused = true
        hud.question = q
    }

    /// Called by SwiftUI when the Brain Gate card is done.
    func answered(firstTry: Bool) {
        hud.question = nil
        if firstTry { hud.brainRight += 1 }
        isPaused = false
        lastTime = 0
        let p = bubblePopper ?? player
        bubblePopper = nil
        p.giantUntil = now + (firstTry ? 10 : 7)
        restPillow(p)
        SpriteFactory.sparkleBurst(in: self, at: CGPoint(x: p.pos.x, y: p.pos.y + charSize * 0.6), size: 60)
        Haptics.success(.star)
        say(who(p) + (firstTry ? "Super brain! GIANT pillow time!" : "You got it! GIANT pillow time!"))
        let shrink = SKAction.sequence([.wait(forDuration: firstTry ? 10 : 7), .run { [weak self] in
            self?.restPillow(p)
        }])
        run(shrink, withKey: "giant")
    }

    // MARK: Ending

    private func endMatch() {
        ended = true
        moveInput = 0
        moveInput2 = 0
        for f in fighters { f.wantDir = 0 }
        let ranking = fighters
            .sorted { a, b in a.bops != b.bops ? a.bops > b.bops : a.isPlayer }
            .map(entry)
        SpriteFactory.confetti(in: self, at: CGPoint(x: size.width / 2, y: groundY + 120), spread: size.width * 0.5)
        Haptics.success(.fanfare)
        hud.message = nil
        run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in
            self?.hud.ranking = ranking
            self?.hud.finished = true
        }]))
    }

    // MARK: HUD

    private func entry(_ f: Fighter) -> BopHUD.Entry {
        BopHUD.Entry(id: f.character.id, character: f.character, bops: f.bops,
                     giggles: Double(f.giggles / 100), floating: f.floatingSince != nil, isPlayer: f.isPlayer,
                     seat: f.isPlayer && twoPlayer ? f.seat : nil)
    }

    private func pushHud(force: Bool) {
        guard force || now - lastHudPush > 0.15 else { return }
        lastHudPush = now
        let list = fighters.map(entry)
        if list != hud.entries { hud.entries = list }
        let left = started ? max(0, Int(ceil(matchLength - (now - matchStart)))) : Int(matchLength)
        if left != hud.timeLeft {
            hud.timeLeft = left
            if left == 10 { say("Ten seconds left!") }
            if left <= 3 && left > 0 { SoundFX.shared.play(.tick) }
        }
        let giant = now < player.giantUntil
        if giant != hud.giant { hud.giant = giant }
        let giant2 = human(1).map { now < $0.giantUntil } ?? false
        if giant2 != hud.giant2 { hud.giant2 = giant2 }
    }

    private func say(_ text: String) {
        hud.message = text
        Narrator.shared.say(text)
        removeAction(forKey: "msg")
        run(.sequence([.wait(forDuration: 2.6), .run { [weak self] in
            if self?.hud.message == text { self?.hud.message = nil }
        }]), withKey: "msg")
    }

    // MARK: Little effects

    private func landPuff(_ f: Fighter) {
        puff(at: f.pos, in: self)
        squash(f)
    }

    private func puff(at p: CGPoint, in parent: SKNode) {
        for i in 0..<4 {
            let dot = SKShapeNode(circleOfRadius: 5)
            dot.fillColor = UIColor.white.withAlphaComponent(0.9)
            dot.strokeColor = .clear
            dot.position = p
            dot.zPosition = 20
            parent.addChild(dot)
            let dx: CGFloat = (CGFloat(i) - 1.5) * 12
            dot.run(.sequence([.group([.moveBy(x: dx, y: 6, duration: 0.3), .scale(to: 1.8, duration: 0.3), .fadeOut(withDuration: 0.3)]),
                               .removeFromParent()]))
        }
    }
}
