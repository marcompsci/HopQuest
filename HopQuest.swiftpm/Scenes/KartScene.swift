import SpriteKit
import SwiftUI
import UIKit

enum KartItem: CaseIterable {
    case shield, carrot, jelly

    var emoji: String {
        switch self {
        case .shield: return "🫧"
        case .carrot: return "🥕"
        case .jelly: return "🍮"
        }
    }

    /// Illustrated icon in the asset catalog.
    var art: String {
        switch self {
        case .shield: return "item_shield"
        case .carrot: return "item_carrot"
        case .jelly: return "item_jelly"
        }
    }

    var title: String {
        switch self {
        case .shield: return "Bubble Shield"
        case .carrot: return "Carrot Boost"
        case .jelly: return "Jelly Pad"
        }
    }

    var tip: String {
        switch self {
        case .shield: return "Bubble Shield! It protects you from one bump."
        case .carrot: return "Carrot Boost! Tap ITEM for a burst of speed."
        case .jelly: return "Jelly Pad! Tap ITEM to drop it behind you. Racers who hit it go bouncy!"
        }
    }
}

/// Live numbers for the SwiftUI HUD on top of the race.
final class KartHUD: ObservableObject {
    @Published var place = 1
    @Published var lap = 1
    @Published var laps = 3
    @Published var item: KartItem?
    @Published var message: String?
    @Published var countdown: String?
    @Published var progress = 0.0
    @Published var mathRight = 0
    @Published var finished = false
    @Published var finalPlace = 0
    @Published var podium: [GameCharacter] = []
}

/// Bubble Kart: a kid-safe kart race. No attack items — only a shield, a boost, and jelly pads.
/// Bumps never crash anyone: racers float in a bubble for a moment, then keep going.
/// Math Gates: a question sign across the road, one answer per lane — drive through the right one for a boost.
final class KartScene: SKScene {

    // Controls (set from SwiftUI)
    var gas = false
    var brake = false
    var autoGas = true

    let hud: KartHUD

    final class Racer {
        let node = SKNode()
        let character: GameCharacter
        let isPlayer: Bool
        var lane: Int
        var d: CGFloat = 0
        var vel: CGFloat = 0
        var topSpeed: CGFloat
        var bubbleUntil: TimeInterval = 0
        var boostUntil: TimeInterval = 0
        var shielded = false
        var item: KartItem?
        var useItemAt: TimeInterval = 0
        var nextLaneChange: TimeInterval = 0
        var changingLane = false
        var finishOrder: Int?
        var bubble: SKNode?
        var shieldRing: SKNode?
        init(character: GameCharacter, isPlayer: Bool, lane: Int, topSpeed: CGFloat) {
            self.character = character
            self.isPlayer = isPlayer
            self.lane = lane
            self.topSpeed = topSpeed
        }
    }

    private struct Spot {
        let node: SKNode
        let lane: Int
        let d: CGFloat
    }

    private final class ItemBox {
        let node: SKNode
        let lane: Int
        let d: CGFloat
        var readyAt: TimeInterval = 0
        init(node: SKNode, lane: Int, d: CGFloat) {
            self.node = node
            self.lane = lane
            self.d = d
        }
    }

    private final class Jelly {
        let node: SKNode
        let lane: Int
        let d: CGFloat
        let owner: Racer
        let armedAt: TimeInterval
        init(node: SKNode, lane: Int, d: CGFloat, owner: Racer, armedAt: TimeInterval) {
            self.node = node
            self.lane = lane
            self.d = d
            self.owner = owner
            self.armedAt = armedAt
        }
    }

    private final class MathGate {
        let d: CGFloat
        let question: Question
        var announced = false
        var resolved = false
        init(d: CGFloat, question: Question) {
            self.d = d
            self.question = question
        }
    }

    private let chapter: Chapter
    private let playerCharacter: GameCharacter
    private let theme: CastleTheme
    private let lanes = 4
    private let laps = 3

    private let world = SKNode()
    private var roadLeft: CGFloat = 0
    private var laneW: CGFloat = 70
    private var carLen: CGFloat = 60
    private var playerY: CGFloat = 0
    private var trackLength: CGFloat { chapter.trackLength }

    private var racers: [Racer] = []
    private var player: Racer!
    private var boxes: [ItemBox] = []
    private var puddles: [Spot] = []
    private var pads: [Spot] = []
    private var jellies: [Jelly] = []
    private var gates: [MathGate] = []

    private var started = false
    private var raceStart: TimeInterval = 0
    private var countdownBegan = false
    private var finishCount = 0
    private var playerDone = false
    private var lastTime: TimeInterval = 0
    private var now: TimeInterval = 0
    private var lastBumpTip: TimeInterval = 0

    init(size: CGSize, chapter: Chapter, character: GameCharacter, theme: CastleTheme, hud: KartHUD) {
        self.chapter = chapter
        self.playerCharacter = character
        self.theme = theme
        self.hud = hud
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    override func didMove(to view: SKView) {
        guard racers.isEmpty else { return }
        backgroundColor = groundColor
        let roadW = min(size.width * 0.84, 480)
        roadLeft = (size.width - roadW) / 2
        laneW = roadW / CGFloat(lanes)
        carLen = laneW * 0.95
        playerY = size.height * 0.28
        hud.laps = laps

        let road = SKSpriteNode(color: UIColor(hex: 0x4E5566), size: CGSize(width: roadW, height: size.height))
        road.position = CGPoint(x: size.width / 2, y: size.height / 2)
        road.zPosition = -10
        addChild(road)
        for x in [roadLeft, roadLeft + roadW] {
            let curb = SKSpriteNode(color: UIColor(hex: theme.accentHex), size: CGSize(width: 8, height: size.height))
            curb.position = CGPoint(x: x, y: size.height / 2)
            curb.zPosition = -9
            addChild(curb)
        }

        addChild(world)
        buildTrack()
        buildRacers()
        world.position.y = playerY
        SoundFX.shared.startEngineHum()
    }

    override func willMove(from view: SKView) {
        SoundFX.shared.stopEngineHum()
    }

    private var groundColor: UIColor {
        switch chapter.id {
        case 202: return UIColor(hex: 0xFFD1E8)
        case 203: return UIColor(hex: 0xB8C4D6)
        default: return UIColor(hex: 0x8FD86E)
        }
    }

    private var scenery: [String] {
        switch chapter.id {
        case 202: return ["🍭", "🧁", "🍬", "🍩", "🎂"]
        case 203: return ["🏰", "🌲", "🚩", "🛡️", "🌳"]
        default: return ["🌼", "🌳", "🌷", "🐄", "🌻"]
        }
    }

    private func laneX(_ lane: Int) -> CGFloat {
        roadLeft + laneW * (CGFloat(lane) + 0.5)
    }

    private func buildTrack() {
        let L = trackLength

        // lane dashes
        var d: CGFloat = -size.height
        while d < L + size.height * 1.5 {
            for k in 1..<lanes {
                let dash = SKSpriteNode(color: UIColor.white.withAlphaComponent(0.7), size: CGSize(width: 4, height: 40))
                dash.position = CGPoint(x: roadLeft + laneW * CGFloat(k), y: d)
                world.addChild(dash)
            }
            d += 90
        }

        // scenery
        if roadLeft > 16 {
            var sd: CGFloat = -size.height
            var left = true
            while sd < L + size.height {
                let item = SpriteFactory.emoji(scenery.randomElement()!, size: min(roadLeft * 0.8, 38))
                item.position = CGPoint(x: left ? roadLeft / 2 : size.width - roadLeft / 2, y: sd)
                world.addChild(item)
                left.toggle()
                sd += CGFloat.random(in: 90...150)
            }
        }

        // start line, lap lines, finish line
        checkered(at: 0)
        checkered(at: L)
        for i in 1..<laps {
            let y = L * CGFloat(i) / CGFloat(laps)
            let line = SKSpriteNode(color: .white, size: CGSize(width: laneW * CGFloat(lanes), height: 6))
            line.position = CGPoint(x: size.width / 2, y: y)
            line.zPosition = 1
            world.addChild(line)
            let label = SpriteFactory.popWordStatic(i == laps - 1 ? "FINAL LAP" : "LAP \(i + 1)", size: laneW * 0.32)
            label.position = CGPoint(x: size.width / 2, y: y + 16)
            label.zPosition = 2
            world.addChild(label)
        }
        let finishBalloon = SpriteFactory.balloon(theme: theme, scale: laneW * 0.4)
        finishBalloon.position = CGPoint(x: roadLeft + laneW * CGFloat(lanes) - laneW * 0.4, y: L + laneW * 1.4)
        finishBalloon.zPosition = 6
        world.addChild(finishBalloon)

        // math gates: 2 per lap after the first stretch
        let gateCount = laps * 2
        for i in 0..<gateCount {
            let gd = L * (CGFloat(i) + 0.7) / CGFloat(gateCount)
            let q = QuestionBank.math(level: chapter.difficulty)
            let gate = MathGate(d: gd, question: q)
            gates.append(gate)
            drawGate(gate)
        }

        // item boxes, puddles, speed pads (kept away from gates)
        var bd: CGFloat = 500
        while bd < L - 300 {
            if !nearGate(bd, 220) {
                let lane = Int.random(in: 0..<lanes)
                // a row of boxes: every lane except one
                for k in 0..<lanes where k != lane {
                    let box = makeItemBox()
                    box.position = CGPoint(x: laneX(k), y: bd)
                    box.zPosition = 4
                    world.addChild(box)
                    boxes.append(ItemBox(node: box, lane: k, d: bd))
                }
            }
            bd += CGFloat.random(in: 900...1200)
        }

        var hd: CGFloat = 800
        let gap = 520 - chapter.difficulty * 180
        while hd < L - 300 {
            if !nearGate(hd, 200) && !boxes.contains(where: { abs($0.d - hd) < 140 }) {
                let lane = Int.random(in: 0..<lanes)
                if Double.random(in: 0...1) < 0.6 {
                    let mud = makePuddle()
                    mud.position = CGPoint(x: laneX(lane), y: hd)
                    mud.zPosition = 2
                    world.addChild(mud)
                    puddles.append(Spot(node: mud, lane: lane, d: hd))
                } else {
                    let pad = makeSpeedPad()
                    pad.position = CGPoint(x: laneX(lane), y: hd)
                    pad.zPosition = 2
                    world.addChild(pad)
                    pads.append(Spot(node: pad, lane: lane, d: hd))
                }
            }
            hd += gap * CGFloat.random(in: 0.7...1.3)
        }
    }

    private func nearGate(_ d: CGFloat, _ margin: CGFloat) -> Bool {
        gates.contains { abs($0.d - d) < margin }
    }

    private func checkered(at y: CGFloat) {
        let tile = laneW / 5
        let count = Int((laneW * CGFloat(lanes)) / tile)
        for i in 0..<count {
            for j in 0..<2 {
                let sq = SKSpriteNode(color: (i + j) % 2 == 0 ? .white : UIColor(hex: 0x2B1B3D),
                                      size: CGSize(width: tile, height: tile))
                sq.position = CGPoint(x: roadLeft + tile * (CGFloat(i) + 0.5), y: y + tile * CGFloat(j))
                sq.zPosition = 1
                world.addChild(sq)
            }
        }
    }

    private func drawGate(_ gate: MathGate) {
        // arch
        let arch = SKShapeNode(rectOf: CGSize(width: laneW * CGFloat(lanes) + 16, height: laneW * 0.42), cornerRadius: laneW * 0.2)
        arch.fillColor = UIColor(hex: 0x7C4DFF)
        arch.strokeColor = .white
        arch.lineWidth = 3
        arch.position = CGPoint(x: size.width / 2, y: gate.d + laneW * 0.75)
        arch.zPosition = 8
        world.addChild(arch)
        let prompt = SKLabelNode(text: "🧠 " + gate.question.prompt)
        prompt.fontName = "AvenirNext-Heavy"
        prompt.fontSize = laneW * 0.24
        prompt.fontColor = .white
        prompt.verticalAlignmentMode = .center
        arch.addChild(prompt)

        // one answer per lane
        for (i, choice) in gate.question.choices.prefix(lanes).enumerated() {
            let bubble = SKShapeNode(circleOfRadius: laneW * 0.28)
            bubble.fillColor = UIColor(hex: 0xFFF4C2)
            bubble.strokeColor = UIColor(hex: 0x7C4DFF)
            bubble.lineWidth = 3
            bubble.position = CGPoint(x: laneX(i), y: gate.d)
            bubble.zPosition = 7
            let label = SKLabelNode(text: choice)
            label.fontName = "AvenirNext-Heavy"
            label.fontSize = laneW * 0.28
            label.fontColor = UIColor(hex: 0x2B1B3D)
            label.verticalAlignmentMode = .center
            bubble.addChild(label)
            world.addChild(bubble)
        }
    }

    private func makeItemBox() -> SKNode {
        let s = laneW * 0.46
        if let tex = SpriteFactory.artTexture("item_box") {
            let box = SKSpriteNode(texture: tex, size: CGSize(width: s, height: s))
            box.run(.repeatForever(.sequence([.group([.rotate(byAngle: 0.18, duration: 0.5), .moveBy(x: 0, y: 4, duration: 0.5)]),
                                              .group([.rotate(byAngle: -0.18, duration: 0.5), .moveBy(x: 0, y: -4, duration: 0.5)])])))
            return box
        }
        let box = SKShapeNode(rectOf: CGSize(width: s, height: s), cornerRadius: s * 0.2)
        box.fillColor = UIColor(hex: 0xFFD93D, alpha: 0.9)
        box.strokeColor = .white
        box.lineWidth = 3
        let q = SKLabelNode(text: "?")
        q.fontName = "AvenirNext-Heavy"
        q.fontSize = s * 0.7
        q.fontColor = UIColor(hex: 0x7C4DFF)
        q.verticalAlignmentMode = .center
        box.addChild(q)
        box.run(.repeatForever(.sequence([.rotate(byAngle: 0.25, duration: 0.5), .rotate(byAngle: -0.25, duration: 0.5)])))
        return box
    }

    private func makePuddle() -> SKNode {
        let mud = SKShapeNode(ellipseOf: CGSize(width: laneW * 0.75, height: laneW * 0.45))
        mud.fillColor = UIColor(hex: 0x8A5A35, alpha: 0.85)
        mud.strokeColor = UIColor(hex: 0x6E4325)
        mud.lineWidth = 2
        let shine = SKShapeNode(ellipseOf: CGSize(width: laneW * 0.2, height: laneW * 0.08))
        shine.fillColor = UIColor.white.withAlphaComponent(0.35)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -laneW * 0.12, y: laneW * 0.07)
        mud.addChild(shine)
        return mud
    }

    private func makeSpeedPad() -> SKNode {
        let pad = SKNode()
        let colors: [UInt32] = [0xFF7FC4, 0xFFD93D, 0x34C77B]
        for (i, c) in colors.enumerated() {
            let p = CGMutablePath()
            let w = laneW * 0.32, h = laneW * 0.16
            let y = CGFloat(i) * h * 0.9 - h
            p.move(to: CGPoint(x: -w, y: y))
            p.addLine(to: CGPoint(x: 0, y: y + h))
            p.addLine(to: CGPoint(x: w, y: y))
            let chevron = SKShapeNode(path: p)
            chevron.strokeColor = UIColor(hex: c)
            chevron.lineWidth = 6
            chevron.lineCap = .round
            pad.addChild(chevron)
        }
        pad.run(.repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 0.3), .fadeAlpha(to: 1, duration: 0.3)])))
        return pad
    }

    private func buildRacers() {
        let others = Roster.all.filter { $0.id != playerCharacter.id }.shuffled().prefix(3)
        let base: CGFloat = 330
        // player starts in lane 1, slightly behind, so there's someone to chase
        player = Racer(character: playerCharacter, isPlayer: true, lane: 1, topSpeed: base)
        player.d = -carLen * 1.3
        var all: [Racer] = []
        let aiLanes = [0, 2, 3]
        for (i, c) in others.enumerated() {
            let skill = 0.86 + chapter.difficulty * 0.12 + CGFloat(i) * 0.03
            let r = Racer(character: c, isPlayer: false, lane: aiLanes[i], topSpeed: base * skill)
            r.d = CGFloat(i % 2) * -carLen * 1.3
            all.append(r)
        }
        all.append(player)
        racers = all
        for r in racers {
            let body = SpriteFactory.topCar(color: UIColor(hex: r.character.colorHex), width: laneW * 0.5, height: carLen * 0.8)
            r.node.addChild(body)
            let driver = SpriteFactory.driver(r.character, size: laneW * 0.46)
            driver.position = CGPoint(x: 0, y: -carLen * 0.06)
            r.node.addChild(driver)
            if r.isPlayer {
                let marker = SpriteFactory.emoji("⭐", size: laneW * 0.2, at: CGPoint(x: 0, y: carLen * 0.55))
                marker.run(.repeatForever(.sequence([.moveBy(x: 0, y: 4, duration: 0.4), .moveBy(x: 0, y: -4, duration: 0.4)])))
                r.node.addChild(marker)
            }
            r.node.position = CGPoint(x: laneX(r.lane), y: r.d)
            r.node.zPosition = r.isPlayer ? 20 : 15
            world.addChild(r.node)
        }
    }

    // MARK: Controls

    func steer(_ dir: Int) {
        guard started, !playerDone else { return }
        changeLane(player, dir)
    }

    func useItem() {
        guard started, !playerDone, let item = player.item else { return }
        use(item, by: player)
        player.item = nil
        hud.item = nil
    }

    private func changeLane(_ r: Racer, _ dir: Int) {
        guard !r.changingLane else { return }
        let target = r.lane + dir
        guard (0..<lanes).contains(target) else { return }
        r.changingLane = true
        r.lane = target
        if r.isPlayer { Haptics.tap() }
        let slide = SKAction.moveTo(x: laneX(target), duration: 0.2)
        slide.timingMode = .easeInEaseOut
        let tilt = SKAction.sequence([.rotate(toAngle: -CGFloat(dir) * 0.15, duration: 0.1),
                                      .rotate(toAngle: 0, duration: 0.1)])
        r.node.run(.group([slide, tilt])) {
            r.changingLane = false
        }
    }

    private func use(_ item: KartItem, by r: Racer) {
        switch item {
        case .shield:
            r.shielded = true
            r.shieldRing?.removeFromParent()
            let ring = SKShapeNode(circleOfRadius: carLen * 0.6)
            ring.fillColor = UIColor(hex: 0x7FD8FF, alpha: 0.18)
            ring.strokeColor = UIColor(hex: 0x7FD8FF)
            ring.lineWidth = 3
            ring.zPosition = 5
            ring.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 0.4), .scale(to: 1.0, duration: 0.4)])))
            r.node.addChild(ring)
            r.shieldRing = ring
            if r.isPlayer { say("Bubble Shield on! You're protected from one bump.") }
        case .carrot:
            r.boostUntil = now + 1.8
            let trail: SKNode = SpriteFactory.artTexture("item_carrot").map {
                SKSpriteNode(texture: $0, size: CGSize(width: laneW * 0.3, height: laneW * 0.3))
            } ?? SpriteFactory.emoji("🥕", size: laneW * 0.25)
            trail.position = CGPoint(x: 0, y: -carLen * 0.6)
            trail.zPosition = -1
            r.node.addChild(trail)
            trail.run(.sequence([.repeat(.sequence([.scale(to: 1.3, duration: 0.15), .scale(to: 0.9, duration: 0.15)]), count: 6),
                                 .removeFromParent()]))
            if r.isPlayer {
                Haptics.success(.whoosh)
                say("Carrot Boost! Zoom!")
            }
        case .jelly:
            let node: SKNode = SpriteFactory.artTexture("item_jelly").map {
                SKSpriteNode(texture: $0, size: CGSize(width: laneW * 0.46, height: laneW * 0.46))
            } ?? SpriteFactory.emoji("🍮", size: laneW * 0.4)
            let d = r.d - carLen * 0.9
            node.position = CGPoint(x: laneX(r.lane), y: d)
            node.zPosition = 3
            node.setScale(0.2)
            node.run(.scale(to: 1, duration: 0.2))
            world.addChild(node)
            jellies.append(Jelly(node: node, lane: r.lane, d: d, owner: r, armedAt: now + 0.6))
            if r.isPlayer { say("Jelly Pad dropped! Wobble wobble!") }
        }
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : CGFloat(min(currentTime - lastTime, 1.0 / 20.0))
        lastTime = currentTime
        now = currentTime

        if !countdownBegan {
            countdownBegan = true
            runCountdown()
        }

        if started {
            for r in racers {
                drive(r, dt)
            }
            resolveBumps()
            checkGates()
            updateStandings()
        }

        for r in racers {
            r.node.position.y = r.d
        }
        SoundFX.shared.setEngine(Float(player.vel / max(player.topSpeed * 1.5, 1)))
        world.position.y = playerY - player.d
    }

    private func runCountdown() {
        let steps = ["3", "2", "1", "GO!"]
        var actions: [SKAction] = [.wait(forDuration: 0.6)]
        for (i, s) in steps.enumerated() {
            actions.append(.run { [weak self] in
                guard let self else { return }
                self.hud.countdown = s
                Narrator.shared.say(s == "GO!" ? "Go!" : s)
                if i == steps.count - 1 {
                    self.started = true
                    self.raceStart = self.now
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

    private func drive(_ r: Racer, _ dt: CGFloat) {
        let inBubble = now < r.bubbleUntil
        let boosting = now < r.boostUntil
        var top = r.topSpeed
        if !r.isPlayer && r.finishOrder == nil {
            // friendly rubber-banding keeps races close for little kids
            let gap = r.d - player.d
            if gap > 450 { top *= 0.86 } else if gap < -350 { top *= 1.14 }
        }
        if boosting { top *= 1.5 }
        if inBubble { top *= 0.25 }

        if r.isPlayer {
            if playerDone {
                r.vel = max(0, r.vel - 250 * dt)
            } else if brake {
                r.vel = max(0, r.vel - 520 * dt)
            } else if gas || autoGas {
                r.vel = r.vel < top ? min(top, r.vel + 210 * dt) : max(top, r.vel - 300 * dt)
            } else {
                r.vel = max(0, r.vel - 90 * dt)
            }
        } else {
            r.vel = r.vel < top ? min(top, r.vel + 190 * dt) : max(top, r.vel - 300 * dt)
            if r.finishOrder == nil { thinkAI(r) }
        }
        r.d += r.vel * dt

        // track pieces
        if !inBubble {
            if puddles.contains(where: { $0.lane == r.lane && abs($0.d - r.d) < carLen * 0.45 }) {
                pop(r, reason: r.isPlayer ? "Squish! Mud makes you bounce in a bubble. Steer around the brown puddles!" : nil)
            }
            if let j = jellies.firstIndex(where: { $0.lane == r.lane && abs($0.d - r.d) < carLen * 0.45 && ($0.owner !== r || now > $0.armedAt + 1.5) && now > $0.armedAt }) {
                let jelly = jellies.remove(at: j)
                jelly.node.run(.sequence([.group([.scale(to: 1.8, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
                pop(r, reason: r.isPlayer ? "Wobble! You bounced on a Jelly Pad!" : nil)
            }
        }
        if pads.contains(where: { $0.lane == r.lane && abs($0.d - r.d) < carLen * 0.45 }) && now > r.boostUntil - 0.5 {
            r.boostUntil = now + 1.0
            if r.isPlayer {
                Haptics.tap(.whoosh)
                say("Rainbow pad! Speed up!", seconds: 1.4)
            }
        }
        for box in boxes where box.lane == r.lane && now >= box.readyAt && abs(box.d - r.d) < carLen * 0.5 {
            box.readyAt = now + 2.5
            box.node.run(.sequence([.group([.scale(to: 0, duration: 0.15), .fadeOut(withDuration: 0.15)]),
                                    .wait(forDuration: 2.3),
                                    .group([.scale(to: 1, duration: 0.2), .fadeIn(withDuration: 0.2)])]))
            if r.item == nil {
                let item = KartItem.allCases.randomElement()!
                r.item = item
                if r.isPlayer {
                    hud.item = item
                    Haptics.success(.item)
                    say(item.tip)
                } else {
                    r.useItemAt = now + Double.random(in: 1.0...4.0)
                }
            }
        }

        // finish line
        if r.finishOrder == nil && r.d >= trackLength {
            finishCount += 1
            r.finishOrder = finishCount
            if r.isPlayer { playerFinished() }
        }
    }

    private func thinkAI(_ r: Racer) {
        if let item = r.item, now >= r.useItemAt {
            use(item, by: r)
            r.item = nil
        }
        guard !r.changingLane, now >= r.nextLaneChange else { return }
        let lookAhead = carLen * 3
        func blocked(_ lane: Int) -> Bool {
            if puddles.contains(where: { $0.lane == lane && $0.d > r.d && $0.d - r.d < lookAhead }) { return true }
            if jellies.contains(where: { $0.lane == lane && $0.d > r.d && $0.d - r.d < lookAhead && $0.owner !== r }) { return true }
            if racers.contains(where: { $0 !== r && $0.lane == lane && $0.d > r.d && $0.d - r.d < carLen * 1.6 }) { return true }
            return false
        }
        // math gates: AI usually (not always) picks the right lane — fair and beatable
        if let gate = gates.first(where: { !$0.resolved && $0.d > r.d && $0.d - r.d < lookAhead * 1.5 }) {
            let target = Double.random(in: 0...1) < 0.65 ? gate.question.answer : Int.random(in: 0..<lanes)
            if target != r.lane {
                changeLane(r, target > r.lane ? 1 : -1)
                r.nextLaneChange = now + 0.35
                return
            }
        }
        if blocked(r.lane) {
            let options = [r.lane - 1, r.lane + 1].filter { (0..<lanes).contains($0) && !blocked($0) }
            if let pick = options.randomElement() {
                changeLane(r, pick > r.lane ? 1 : -1)
            }
            r.nextLaneChange = now + 0.6
        } else {
            r.nextLaneChange = now + Double.random(in: 0.4...0.9)
        }
    }

    /// The kid-friendly "crash": float in a bubble for a moment, then keep racing.
    private func pop(_ r: Racer, reason: String?) {
        if r.shielded {
            r.shielded = false
            r.shieldRing?.run(.sequence([.group([.scale(to: 1.6, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
            r.shieldRing = nil
            if r.isPlayer { say("Your Bubble Shield saved you!") }
            return
        }
        r.bubbleUntil = now + 1.1
        r.vel *= 0.4
        if r.isPlayer {
            Haptics.bump()
            if let reason { say(reason) }
        }
        r.bubble?.removeFromParent()
        let bubble = SKShapeNode(circleOfRadius: carLen * 0.62)
        bubble.fillColor = UIColor(hex: 0xBDEBFF, alpha: 0.35)
        bubble.strokeColor = .white
        bubble.lineWidth = 2
        bubble.zPosition = 6
        let shine = SKShapeNode(ellipseOf: CGSize(width: carLen * 0.25, height: carLen * 0.12))
        shine.fillColor = UIColor.white.withAlphaComponent(0.7)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -carLen * 0.25, y: carLen * 0.3)
        bubble.addChild(shine)
        r.node.addChild(bubble)
        r.bubble = bubble
        r.node.run(.sequence([.scale(to: 1.2, duration: 0.3), .wait(forDuration: 0.5), .scale(to: 1.0, duration: 0.3)]))
        bubble.run(.sequence([.wait(forDuration: 1.0),
                              .group([.scale(to: 1.4, duration: 0.12), .fadeOut(withDuration: 0.12)]),
                              .removeFromParent()]))
    }

    /// Cars in the same lane softly nudge instead of crashing.
    private func resolveBumps() {
        for a in racers {
            for b in racers where a !== b && a.lane == b.lane && !a.changingLane && !b.changingLane {
                let gap = b.d - a.d
                if gap > 0 && gap < carLen * 0.85 {
                    a.d = b.d - carLen * 0.85
                    a.vel = min(a.vel, b.vel * 0.9)
                    if a.isPlayer && now - lastBumpTip > 4 {
                        lastBumpTip = now
                        Haptics.bump()
                        say("Boop! Change lanes to pass. ⬅️ ➡️", seconds: 1.8)
                    }
                }
            }
        }
    }

    private func checkGates() {
        for gate in gates where !gate.resolved {
            let ahead = gate.d - player.d
            if !gate.announced && ahead < 900 {
                gate.announced = true
                let q = gate.question
                hud.message = "Math Gate! " + q.prompt + " Drive through the right answer!"
                Narrator.shared.say("Math Gate! \(q.prompt) Drive through the right answer!")
            }
            if ahead <= 0 {
                gate.resolved = true
                let q = gate.question
                let correct = q.choices.indices.contains(q.answer) ? q.choices[q.answer] : ""
                if player.lane == q.answer {
                    hud.mathRight += 1
                    player.boostUntil = now + 2.0
                    Haptics.success(.correct)
                    SpriteFactory.sparkleBurst(in: world, at: CGPoint(x: laneX(player.lane), y: player.d), size: laneW)
                    say("Yes! The answer is \(correct)! Super boost!")
                } else {
                    say("The answer was \(correct). You'll get the next one!")
                }
            }
        }
    }

    private func updateStandings() {
        let ordered = racers.sorted { lhs, rhs in
            switch (lhs.finishOrder, rhs.finishOrder) {
            case let (l?, r?): return l < r
            case (.some, .none): return true
            case (.none, .some): return false
            default: return lhs.d > rhs.d
            }
        }
        let place = (ordered.firstIndex { $0 === player } ?? 0) + 1
        if place != hud.place && !playerDone { hud.place = place }

        let lap = min(laps, Int(max(0, player.d) / (trackLength / CGFloat(laps))) + 1)
        if lap != hud.lap && !playerDone {
            hud.lap = lap
            say(lap == laps ? "Final lap! You can do it!" : "Lap \(lap)!", seconds: 1.8)
        }
        let p = Double(min(max(player.d, 0) / trackLength, 1))
        if abs(p - hud.progress) > 0.005 { hud.progress = p }
    }

    private func playerFinished() {
        playerDone = true
        let place = player.finishOrder ?? 4
        hud.finalPlace = place
        Haptics.success(.fanfare)
        SpriteFactory.confetti(in: self, at: CGPoint(x: size.width / 2, y: playerY), spread: laneW * 2.5)
        let words = ["1st place! Amazing!", "2nd place! Great racing!", "3rd place! Nice job!", "You finished! Awesome effort!"]
        say(words[min(place, 4) - 1], seconds: 2.5)
        // finish the others quickly so the podium is ready
        run(.wait(forDuration: 2.2)) { [weak self] in
            guard let self else { return }
            let rest = self.racers.filter { $0.finishOrder == nil }.sorted { $0.d > $1.d }
            for r in rest {
                self.finishCount += 1
                r.finishOrder = self.finishCount
            }
            self.hud.podium = self.racers
                .sorted { ($0.finishOrder ?? 9) < ($1.finishOrder ?? 9) }
                .map { $0.character }
            self.hud.finished = true
        }
    }

    // MARK: Messages

    private func say(_ text: String, seconds: TimeInterval = 2.6) {
        hud.message = text
        Narrator.shared.say(text)
        removeAction(forKey: "msg")
        run(.sequence([.wait(forDuration: seconds), .run { [weak self] in self?.hud.message = nil }]), withKey: "msg")
    }
}
