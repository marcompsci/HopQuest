import SpriteKit
import SwiftUI
import UIKit

/// Live numbers the SwiftUI HUD shows on top of the driving scene.
final class DriveHUD: ObservableObject {
    @Published var mph = 0
    @Published var limit: Int?
    @Published var stars = 0
    @Published var coins = 0
    @Published var progress = 0.0
    @Published var message: String?
    /// -1 left, 0 off, 1 right. Set by the blinker buttons; cancels itself after a lane change.
    @Published var blinker = 0
    @Published var finished = false
}

/// Driving School: smooth, kid-friendly driving that teaches real rules —
/// traffic lights, stop signs, school zones, turn signals and following distance.
/// Steering is continuous (a wheel), with gentle lane-assist. Bumps are soft "boings"; there are no crashes.
final class DriveScene: SKScene {

    // MARK: Controls (set from SwiftUI)

    /// Pedals: 0...1 each.
    var gasPedal: CGFloat = 0
    var brakePedal: CGFloat = 0
    /// Steering wheel: -1 (full left) ... 1 (full right).
    var steerInput: CGFloat = 0

    let hud: DriveHUD

    private enum CheckKind { case light, stop, school }

    private final class Checkpoint {
        let kind: CheckKind
        let d: CGFloat
        let length: CGFloat
        var lamps: [SKShapeNode] = []
        var glows: [SKSpriteNode] = []
        var announced = false
        var resolved = false
        var stoppedHere = false
        var maxSpeed: CGFloat = 0
        var cycleStart: TimeInterval = 0
        var lightState = 0   // 0 red, 1 green, 2 yellow
        init(kind: CheckKind, d: CGFloat, length: CGFloat = 0) {
            self.kind = kind
            self.d = d
            self.length = length
        }
    }

    private final class Traffic {
        let node: SKNode
        let lane: Int
        let length: CGFloat
        var d: CGFloat
        let cruise: CGFloat
        var vel: CGFloat
        var waitUntil: TimeInterval = 0
        var stoppedAtSigns: Set<Int> = []
        init(node: SKNode, lane: Int, length: CGFloat, d: CGFloat, cruise: CGFloat) {
            self.node = node
            self.lane = lane
            self.length = length
            self.d = d
            self.cruise = cruise
            self.vel = cruise
        }
    }

    private let chapter: Chapter
    private let character: GameCharacter
    private let theme: CastleTheme
    private let lanes = 3

    private let world = SKNode()
    private var car: SKNode!
    private var carBody: SKNode!
    private var roadLeft: CGFloat = 0
    private var roadW: CGFloat = 300
    private var laneW: CGFloat = 80
    private var carW: CGFloat = 40
    private var carLen: CGFloat = 70
    private var screenY: CGFloat = 0        // where the player's car sits on screen (moves with speed)
    private var carX: CGFloat = 0
    private var latVel: CGFloat = 0
    private var yaw: CGFloat = 0
    private var throttle: CGFloat = 0       // smoothed pedal values
    private var braking: CGFloat = 0
    private var carSpeed: CGFloat = 0       // not `speed`: SKNode already has a `speed` property
    private var distance: CGFloat = 0
    private let maxSpeed: CGFloat = 440     // ≈ 55 mph on the speedometer
    private let mphScale: CGFloat = 8
    private var trackLength: CGFloat { chapter.trackLength }

    private var traffic: [Traffic] = []
    private var coins: [(node: SKNode, x: CGFloat, d: CGFloat)] = []
    private var checkpoints: [Checkpoint] = []
    private var bumpCooldown: TimeInterval = 0
    private var edgeCooldown: TimeInterval = 0
    private var finished = false
    private var lastTime: TimeInterval = 0
    private var now: TimeInterval = 0

    private var currentLane = 1
    private var signalPraised = false
    private var signalTipAt: TimeInterval = 0
    private var cancelBlinkerWhenSettled = false
    private var lastBlinker = 0
    private var nextSpeedLine: TimeInterval = 0
    private var nextPuff: TimeInterval = 0

    init(size: CGSize, chapter: Chapter, character: GameCharacter, theme: CastleTheme, hud: DriveHUD) {
        self.chapter = chapter
        self.character = character
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
        guard car == nil else { return }
        backgroundColor = UIColor(hex: 0x8FD86E)
        roadW = min(size.width * 0.8, 460)
        roadLeft = ((size.width - roadW) / 2).rounded()
        laneW = roadW / CGFloat(lanes)
        carW = laneW * 0.5
        carLen = carW * DriveArt.CarKind.car.design.height / DriveArt.CarKind.car.design.width
        screenY = size.height * 0.3

        world.zPosition = 0
        addChild(world)
        buildTrack()

        car = SpriteFactory.topCar(color: UIColor(hex: character.colorHex), width: carW, height: carLen)
        carBody = car.childNode(withName: "body")
        let driver = SpriteFactory.driver(character, size: carW * 0.82)
        driver.position = CGPoint(x: 0, y: -carLen * 0.02)
        driver.zPosition = 3
        car.addChild(driver)
        carX = laneX(1)
        car.position = CGPoint(x: carX, y: screenY)
        car.zPosition = 20
        addChild(car)

        say("Press the GAS pedal to drive and BRAKE to stop. Turn the wheel to steer!", seconds: 3.6)
        SoundFX.shared.startEngineHum()
    }

    override func willMove(from view: SKView) {
        SoundFX.shared.stopEngineHum()
    }

    private func laneX(_ lane: Int) -> CGFloat {
        roadLeft + laneW * (CGFloat(lane) + 0.5)
    }

    private func lane(at x: CGFloat) -> Int {
        max(0, min(lanes - 1, Int((x - roadLeft) / laneW)))
    }

    private func buildTrack() {
        let L = trackLength

        // painted road pieces (one shared texture)
        let segH: CGFloat = 600
        let roadTex = DriveArt.roadSegment(width: size.width, height: segH, roadLeft: roadLeft, roadWidth: roadW, lanes: lanes)
        var y: CGFloat = -size.height
        while y < L + size.height * 2 {
            let seg = SKSpriteNode(texture: roadTex, size: CGSize(width: size.width, height: segH))
            seg.anchorPoint = .zero
            seg.position = CGPoint(x: 0, y: y)
            seg.zPosition = -10
            world.addChild(seg)
            y += segH
        }

        // roadside trees, bushes and houses (hang over the grass edge)
        let leftX = roadLeft - 22
        let rightX = roadLeft + roadW + 22
        var sd: CGFloat = -size.height
        var flip = false
        while sd < L + size.height * 1.5 {
            for (side, x) in [(-1, leftX), (1, rightX)] {
                let roll = Int.random(in: 0..<10)
                let node: SKSpriteNode
                if roll < 5 {
                    let s = CGFloat.random(in: 62...84)
                    node = SKSpriteNode(texture: DriveArt.tree, size: CGSize(width: s, height: s))
                    node.position = CGPoint(x: x + CGFloat(side) * s * 0.28, y: sd + CGFloat.random(in: -20...20))
                } else if roll < 8 {
                    node = SKSpriteNode(texture: DriveArt.bush, size: CGSize(width: 40, height: 32))
                    node.position = CGPoint(x: x + CGFloat(side) * 4, y: sd)
                } else {
                    let roofs: [UInt32] = [0xE76F51, 0x6C7BD9, 0x34A0A4, 0xF4A261]
                    node = SKSpriteNode(texture: DriveArt.house(roof: UIColor(hex: roofs.randomElement()!)),
                                        size: CGSize(width: 76, height: 72))
                    node.position = CGPoint(x: x + CGFloat(side) * 30, y: sd)
                }
                node.zPosition = 25 + (flip ? 0.1 : 0)
                world.addChild(node)
            }
            flip.toggle()
            sd += CGFloat.random(in: 120...180)
        }

        // checkpoints
        var plan: [Checkpoint] = [
            Checkpoint(kind: .school, d: L * 0.16, length: 650),
            Checkpoint(kind: .light, d: L * 0.42),
            Checkpoint(kind: .stop, d: L * 0.66),
        ]
        if chapter.difficulty > 0.3 {
            plan.append(Checkpoint(kind: .light, d: L * 0.86))
        }
        checkpoints = plan
        for cp in checkpoints { drawCheckpoint(cp) }

        drawFinish(at: L)

        // coins
        var cd: CGFloat = 380
        while cd < L - 200 {
            if !nearCheckpoint(cd, before: 140, after: 80) {
                let x = laneX(Int.random(in: 0..<lanes))
                let coin = SKSpriteNode(texture: DriveArt.coin, size: CGSize(width: laneW * 0.32, height: laneW * 0.32))
                coin.position = CGPoint(x: x, y: cd)
                coin.zPosition = 3
                coin.run(.repeatForever(.sequence([.scaleX(to: 0.25, duration: 0.3), .scaleX(to: 1, duration: 0.3)])))
                world.addChild(coin)
                coins.append((node: coin, x: x, d: cd))
            }
            cd += CGFloat.random(in: 200...300)
        }

        // friendly traffic (a school bus near the school zone)
        let gap = 560 - chapter.difficulty * 200
        var td: CGFloat = 700
        while td < L - 400 {
            if !nearCheckpoint(td, before: 320, after: 160) {
                let laneI = Int.random(in: 0..<lanes)
                let kind: DriveArt.CarKind
                if abs(td - L * 0.12) < 400 { kind = .bus }
                else { kind = Int.random(in: 0..<5) == 0 ? .van : .car }
                let node = SpriteFactory.topCar(color: kind == .bus ? UIColor(hex: 0xFFC21A) : SpriteFactory.carColors.randomElement()!,
                                                width: kind == .bus ? carW * 1.08 : carW, height: carLen, kind: kind)
                node.position = CGPoint(x: laneX(laneI), y: td)
                node.zPosition = 10
                world.addChild(node)
                let len = (kind == .bus ? carW * 1.08 : carW) * kind.design.height / kind.design.width
                traffic.append(Traffic(node: node, lane: laneI, length: len, d: td, cruise: CGFloat.random(in: 150...200)))
            }
            td += gap * CGFloat.random(in: 0.8...1.2)
        }
    }

    private func nearCheckpoint(_ d: CGFloat, before: CGFloat, after: CGFloat) -> Bool {
        checkpoints.contains { cp in
            d > cp.d - before && d < cp.d + cp.length + after
        }
    }

    private func roadText(_ text: String, at d: CGFloat, size: CGFloat, color: UIColor = .white) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = size
        label.fontColor = color.withAlphaComponent(0.88)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: roadLeft + roadW / 2, y: d)
        label.zPosition = 1
        label.yScale = 1.35            // painted road words are stretched long
        world.addChild(label)
    }

    private func stopLine(at d: CGFloat) {
        let line = SKSpriteNode(color: .white, size: CGSize(width: roadW - 16, height: 10))
        line.position = CGPoint(x: roadLeft + roadW / 2, y: d)
        line.zPosition = 1
        world.addChild(line)
    }

    private func drawCheckpoint(_ cp: Checkpoint) {
        let signX = roadLeft + roadW + 14
        switch cp.kind {
        case .light:
            stopLine(at: cp.d)
            // overhead signal: pole on the right, arm over the road
            let pole = SKSpriteNode(color: UIColor(hex: 0x3B3F4A), size: CGSize(width: 8, height: 8))
            pole.position = CGPoint(x: signX, y: cp.d + 30)
            pole.zPosition = 40
            world.addChild(pole)
            let arm = SKSpriteNode(color: UIColor(hex: 0x3B3F4A), size: CGSize(width: signX - (roadLeft + roadW * 0.45), height: 6))
            arm.anchorPoint = CGPoint(x: 1, y: 0.5)
            arm.position = CGPoint(x: signX, y: cp.d + 30)
            arm.zPosition = 40
            world.addChild(arm)
            let housing = SKShapeNode(rectOf: CGSize(width: laneW * 0.32, height: laneW * 0.82), cornerRadius: 8)
            housing.fillColor = UIColor(hex: 0x23232B)
            housing.strokeColor = UIColor(hex: 0xFFD93D)
            housing.lineWidth = 2
            housing.position = CGPoint(x: roadLeft + roadW * 0.55, y: cp.d + 30)
            housing.zPosition = 41
            world.addChild(housing)
            let colors = [UIColor(hex: 0xFF3B3B), UIColor(hex: 0xFFD21F), UIColor(hex: 0x2EE06B)]
            for (i, y) in [laneW * 0.25, 0, -laneW * 0.25].enumerated() {
                let lamp = SKShapeNode(circleOfRadius: laneW * 0.1)
                lamp.position = CGPoint(x: 0, y: y)
                lamp.strokeColor = .clear
                lamp.fillColor = colors[i].withAlphaComponent(0.22)
                housing.addChild(lamp)
                cp.lamps.append(lamp)
                let glow = SKSpriteNode(texture: DriveArt.glow(colors[i]), size: CGSize(width: laneW * 0.62, height: laneW * 0.62))
                glow.position = CGPoint(x: 0, y: y)
                glow.blendMode = .add
                glow.alpha = 0
                housing.addChild(glow)
                cp.glows.append(glow)
            }
            setLight(cp, state: 0)

        case .stop:
            stopLine(at: cp.d)
            roadText("STOP", at: cp.d - laneW * 0.75, size: laneW * 0.5)
            let post = SKSpriteNode(color: UIColor(hex: 0x9AA0AE), size: CGSize(width: 4, height: 30))
            post.position = CGPoint(x: signX, y: cp.d + 6)
            post.zPosition = 40
            world.addChild(post)
            let s = min(laneW * 0.5, 46)
            let path = CGMutablePath()
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4 + .pi / 8
                let p = CGPoint(x: cos(a) * s * 0.6, y: sin(a) * s * 0.6)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            let oct = SKShapeNode(path: path)
            oct.fillColor = UIColor(hex: 0xD62828)
            oct.strokeColor = .white
            oct.lineWidth = 3
            oct.position = CGPoint(x: min(signX, size.width - s * 0.62), y: cp.d + 30)
            oct.zPosition = 41
            world.addChild(oct)
            let text = SKLabelNode(text: "STOP")
            text.fontName = "AvenirNext-Heavy"
            text.fontSize = s * 0.34
            text.fontColor = .white
            text.verticalAlignmentMode = .center
            oct.addChild(text)

        case .school:
            let zone = SKSpriteNode(color: UIColor(hex: 0xFFD93D, alpha: 0.16), size: CGSize(width: roadW - 16, height: cp.length))
            zone.anchorPoint = CGPoint(x: 0.5, y: 0)
            zone.position = CGPoint(x: roadLeft + roadW / 2, y: cp.d)
            zone.zPosition = 0.5
            world.addChild(zone)
            roadText("SCHOOL", at: cp.d + 60, size: laneW * 0.42, color: UIColor(hex: 0xFFE066))
            roadText("20", at: cp.d + 150, size: laneW * 0.5, color: UIColor(hex: 0xFFE066))
            // zebra crosswalk
            let mid = cp.d + cp.length / 2
            var x = roadLeft + 14
            while x < roadLeft + roadW - 20 {
                let bar = SKSpriteNode(color: UIColor(white: 1, alpha: 0.92), size: CGSize(width: laneW * 0.18, height: 54))
                bar.anchorPoint = CGPoint(x: 0, y: 0.5)
                bar.position = CGPoint(x: x, y: mid)
                bar.zPosition = 1
                world.addChild(bar)
                x += laneW * 0.33
            }
            // kids waiting safely on the sidewalk
            let friends = Roster.all.filter { $0.id != character.id }.shuffled().prefix(2)
            for (i, f) in friends.enumerated() {
                let kid = SpriteFactory.driver(f, size: 30)
                kid.position = CGPoint(x: i == 0 ? roadLeft - 18 : roadLeft + roadW + 18, y: mid + 8)
                kid.zPosition = 42
                kid.run(.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: 0.4), .moveBy(x: 0, y: -3, duration: 0.4)])))
                world.addChild(kid)
            }
            // school sign
            let s = min(laneW * 0.5, 46)
            let board = SKShapeNode(path: diamond(s * 1.15))
            board.fillColor = UIColor(hex: 0xFFE14D)
            board.strokeColor = UIColor(hex: 0x2B1B3D)
            board.lineWidth = 3
            board.position = CGPoint(x: min(signX, size.width - s * 0.6), y: cp.d - 10)
            board.zPosition = 41
            world.addChild(board)
            board.addChild(SpriteFactory.emoji("🚸", size: s * 0.55))
            let limit = SKShapeNode(rectOf: CGSize(width: s * 0.8, height: s), cornerRadius: 4)
            limit.fillColor = .white
            limit.strokeColor = UIColor(hex: 0x2B1B3D)
            limit.lineWidth = 2
            limit.position = CGPoint(x: board.position.x, y: cp.d - 10 - s * 1.15)
            limit.zPosition = 41
            world.addChild(limit)
            let num = SKLabelNode(text: "20")
            num.fontName = "AvenirNext-Heavy"
            num.fontSize = s * 0.42
            num.fontColor = UIColor(hex: 0x2B1B3D)
            num.verticalAlignmentMode = .center
            limit.addChild(num)
        }
    }

    private func diamond(_ s: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: s / 2))
        p.addLine(to: CGPoint(x: s / 2, y: 0))
        p.addLine(to: CGPoint(x: 0, y: -s / 2))
        p.addLine(to: CGPoint(x: -s / 2, y: 0))
        p.closeSubpath()
        return p
    }

    private func drawFinish(at L: CGFloat) {
        let tile = (roadW - 16) / 12
        for i in 0..<12 {
            for j in 0..<2 {
                let sq = SKSpriteNode(color: (i + j) % 2 == 0 ? .white : UIColor(hex: 0x2B1B3D),
                                      size: CGSize(width: tile, height: tile))
                sq.position = CGPoint(x: roadLeft + 8 + tile * (CGFloat(i) + 0.5), y: L + tile * CGFloat(j))
                sq.zPosition = 1
                world.addChild(sq)
            }
        }
        // arch
        for x in [roadLeft - 4, roadLeft + roadW + 4] {
            let post = SKShapeNode(rectOf: CGSize(width: 12, height: 12), cornerRadius: 3)
            post.fillColor = UIColor(hex: theme.roofHex)
            post.strokeColor = .white
            post.position = CGPoint(x: x, y: L + laneW * 0.9)
            post.zPosition = 44
            world.addChild(post)
        }
        let banner = SKShapeNode(rectOf: CGSize(width: roadW + 8, height: laneW * 0.42), cornerRadius: laneW * 0.12)
        banner.fillColor = UIColor(hex: theme.roofHex)
        banner.strokeColor = .white
        banner.lineWidth = 3
        banner.position = CGPoint(x: roadLeft + roadW / 2, y: L + laneW * 0.9)
        banner.zPosition = 45
        world.addChild(banner)
        let text = SKLabelNode(text: "🏁 FINISH 🏁")
        text.fontName = "AvenirNext-Heavy"
        text.fontSize = laneW * 0.24
        text.fontColor = .white
        text.verticalAlignmentMode = .center
        banner.addChild(text)
        let balloon = SpriteFactory.balloon(theme: theme, scale: laneW * 0.42)
        balloon.position = CGPoint(x: roadLeft + roadW * 0.8, y: L + laneW * 1.9)
        balloon.zPosition = 46
        balloon.run(.repeatForever(.sequence([.moveBy(x: 0, y: 8, duration: 0.9), .moveBy(x: 0, y: -8, duration: 0.9)])))
        world.addChild(balloon)
    }

    private func setLight(_ cp: Checkpoint, state: Int) {
        cp.lightState = state
        let lit = [0: 0, 2: 1, 1: 2][state] ?? 0
        let base = [UIColor(hex: 0xFF3B3B), UIColor(hex: 0xFFD21F), UIColor(hex: 0x2EE06B)]
        for (i, lamp) in cp.lamps.enumerated() {
            lamp.fillColor = base[i].withAlphaComponent(i == lit ? 1 : 0.22)
        }
        for (i, g) in cp.glows.enumerated() {
            g.alpha = i == lit ? 0.9 : 0
        }
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : CGFloat(min(currentTime - lastTime, 1.0 / 20.0))
        lastTime = currentTime
        now = currentTime
        guard dt > 0 else { return }

        updateSpeed(dt)
        SoundFX.shared.setEngine(Float(carSpeed / maxSpeed * 0.8 + throttle * 0.2))
        updateSteering(dt)
        updateBlinker()

        distance += carSpeed * dt

        // look-ahead camera: the faster you go, the lower the car sits, so you see more road
        let targetY = size.height * (0.3 - 0.08 * carSpeed / maxSpeed)
        screenY += (targetY - screenY) * min(1, dt * 2.5)
        world.position.y = screenY - distance
        car.position = CGPoint(x: carX, y: screenY)
        car.zRotation = yaw

        updateTraffic(dt)
        updateCheckpoints()
        collectCoins()
        checkBumps()
        effects()

        let mph = Int((carSpeed / mphScale).rounded())
        if mph != hud.mph { hud.mph = mph }
        let p = Double(min(distance / trackLength, 1))
        if abs(p - hud.progress) > 0.003 { hud.progress = p }

        if !finished && distance >= trackLength {
            finished = true
            hud.stars += 1
            hud.blinker = 0
            Haptics.success(.fanfare)
            say("You made it! Great driving! 🏁", seconds: 2)
            SpriteFactory.confetti(in: self, at: car.position, spread: laneW * 2)
            run(.wait(forDuration: 1.8)) { [weak self] in
                self?.hud.finished = true
            }
        }
    }

    private func updateSpeed(_ dt: CGFloat) {
        // pedals ease in and out like a real car instead of switching instantly
        let g = finished ? 0 : gasPedal
        let b = finished ? 0.6 : brakePedal
        throttle += (g - throttle) * min(1, dt * 6)
        braking += (b - braking) * min(1, dt * 10)

        // engine pulls hard at low speed and softer near top speed
        let headroom = 1 - (carSpeed / maxSpeed)
        let accel = 260 * throttle * max(0.15, headroom)
        let brakeForce = 560 * braking
        let rolling: CGFloat = 40 + carSpeed * 0.12
        carSpeed += (accel - brakeForce * (carSpeed > 0 ? 1 : 0) - (throttle < 0.05 ? rolling : 0)) * dt
        carSpeed = max(0, min(maxSpeed, carSpeed))

        // brake lights
        car.childNode(withName: "brake")?.alpha = braking > 0.1 ? min(1, braking * 1.4) : 0
    }

    private func updateSteering(_ dt: CGFloat) {
        let grip = min(1, carSpeed / 90)                 // you can't slide sideways while stopped
        var target = steerInput * 280 * grip
        if abs(steerInput) < 0.08 {
            // lane assist: drift gently to the middle of the nearest lane
            let center = laneX(lane(at: carX))
            target = max(-120, min(120, (center - carX) * 3.2)) * grip
        }
        latVel += (target - latVel) * min(1, dt * 7)
        carX += latVel * dt

        // stay on the road: soft curb bump
        let minX = roadLeft + carW * 0.5 + 8
        let maxX = roadLeft + roadW - carW * 0.5 - 8
        if carX < minX || carX > maxX {
            carX = max(minX, min(maxX, carX))
            latVel = 0
            if now > edgeCooldown && carSpeed > 40 {
                edgeCooldown = now + 1.2
                Haptics.bump()
                carSpeed *= 0.85
                say("Rumble! Stay inside the white lines. 🛣️", seconds: 1.8)
            }
        }

        // the car turns its nose in the direction it's moving
        let targetYaw = carSpeed > 5 ? -atan2(latVel, max(carSpeed, 60)) * 0.9 : 0
        yaw += (targetYaw - yaw) * min(1, dt * 8)
    }

    private func updateBlinker() {
        // show the blinker on the car
        if hud.blinker != lastBlinker {
            lastBlinker = hud.blinker
            for name in ["blinkL", "blinkR"] {
                guard let node = car.childNode(withName: name) else { continue }
                node.removeAllActions()
                node.alpha = 0
                if (name == "blinkL" && hud.blinker < 0) || (name == "blinkR" && hud.blinker > 0) {
                    node.run(.repeatForever(.sequence([.fadeAlpha(to: 1, duration: 0.05), .wait(forDuration: 0.3),
                                                       .fadeAlpha(to: 0, duration: 0.05), .wait(forDuration: 0.3)])))
                }
            }
            removeAction(forKey: "blinkerSound")
            if hud.blinker != 0 {
                run(.repeatForever(.sequence([
                    .run { SoundFX.shared.play(.tick, volume: 0.8) }, .wait(forDuration: 0.35),
                    .run { SoundFX.shared.play(.tock, volume: 0.8) }, .wait(forDuration: 0.35)
                ])), withKey: "blinkerSound")
            }
        }

        // detect lane changes and teach signalling
        let laneNow = lane(at: carX)
        if laneNow != currentLane {
            let dir = laneNow > currentLane ? 1 : -1
            currentLane = laneNow
            if hud.blinker == dir {
                if !signalPraised {
                    signalPraised = true
                    award("Great signal! Other drivers knew where you were going. ⭐")
                }
                cancelBlinkerWhenSettled = true
            } else if now > signalTipAt {
                signalTipAt = now + 8
                say("Tip: tap the blinker before you change lanes! 💡")
            }
        }
        // blinker turns itself off once you're settled in the new lane (like a real car)
        if cancelBlinkerWhenSettled && abs(carX - laneX(currentLane)) < 10 && abs(steerInput) < 0.1 {
            cancelBlinkerWhenSettled = false
            hud.blinker = 0
        }
    }

    private func updateTraffic(_ dt: CGFloat) {
        let ordered = traffic.sorted { $0.d > $1.d }
        let playerLane = lane(at: carX)
        for t in ordered {
            var go = now >= t.waitUntil

            for (idx, cp) in checkpoints.enumerated() where cp.kind != .school {
                let toLine = cp.d - (t.d + t.length / 2)
                guard toLine > -5 && toLine < 60 else { continue }
                if cp.kind == .light && cp.lightState != 1 { go = false }
                if cp.kind == .stop && !t.stoppedAtSigns.contains(idx) {
                    t.stoppedAtSigns.insert(idx)
                    t.waitUntil = now + 1.4
                    go = false
                }
            }
            if let leader = ordered.last(where: { $0 !== t && $0.lane == t.lane && $0.d > t.d }),
               leader.d - t.d < (leader.length + t.length) * 0.5 + carLen * 0.5 {
                go = false
            }
            // polite traffic: don't drive into the player from behind
            if playerLane == t.lane && distance > t.d && distance - t.d < carLen * 1.6 {
                go = false
            }
            let target = go ? t.cruise : 0
            t.vel += (target - t.vel) * min(1, dt * (go ? 1.5 : 4))
            t.d += t.vel * dt
            t.node.position.y = t.d
            t.node.childNode(withName: "brake")?.alpha = t.vel < t.cruise * 0.6 ? 1 : 0
        }
    }

    private func updateCheckpoints() {
        for cp in checkpoints {
            let toLine = cp.d - distance - carLen / 2
            switch cp.kind {
            case .light:
                if !cp.announced && toLine < 900 {
                    cp.announced = true
                    cp.cycleStart = now
                    say("Traffic light ahead! 🔴 Red = stop · 🟡 Yellow = slow · 🟢 Green = go")
                }
                if cp.announced {
                    let t = (now - cp.cycleStart).truncatingRemainder(dividingBy: 9.5)
                    let state = t < 4 ? 0 : (t < 8 ? 1 : 2)
                    if state != cp.lightState { setLight(cp, state: state) }
                }
                if !cp.resolved {
                    if toLine < 200 && toLine > -10 && carSpeed < 20 && cp.lightState == 0 { cp.stoppedHere = true }
                    if toLine <= 0 {
                        cp.resolved = true
                        if cp.lightState == 0 {
                            say("Whoa! Red means STOP. Wait for green next time. 🔴")
                        } else {
                            award(cp.stoppedHere ? "Great stop! You waited for green. ⭐" : "Green means go! Nice driving. ⭐")
                        }
                    }
                }

            case .stop:
                if !cp.announced && toLine < 700 {
                    cp.announced = true
                    say("STOP sign ahead! 🛑 Come to a full stop at the white line.")
                }
                if !cp.resolved {
                    if toLine < 220 && toLine > -10 && carSpeed < 12 { cp.stoppedHere = true }
                    if toLine <= 0 {
                        cp.resolved = true
                        if cp.stoppedHere {
                            award("Perfect full stop! ⭐")
                        } else {
                            say("Stop signs mean stop all the way — even when nobody's coming. 🛑")
                        }
                    }
                }

            case .school:
                if !cp.announced && toLine < 600 {
                    cp.announced = true
                    say("School zone ahead 🚸 Slow down to 20 mph — kids might be crossing!")
                }
                let inZone = distance >= cp.d && distance <= cp.d + cp.length
                if inZone {
                    if hud.limit != 20 { hud.limit = 20 }
                    cp.maxSpeed = max(cp.maxSpeed, carSpeed)
                } else if !cp.resolved && distance > cp.d + cp.length {
                    cp.resolved = true
                    hud.limit = nil
                    if cp.maxSpeed <= 25 * mphScale {
                        award("You kept everyone safe in the school zone! ⭐")
                    } else {
                        say("School zones mean slow and careful. Kids might be crossing! 🚸")
                    }
                }
            }
        }
    }

    private func collectCoins() {
        coins.removeAll { coin in
            if abs(coin.x - carX) < carW * 0.8 && abs(coin.d - distance) < carLen * 0.55 {
                hud.coins += 1
                Haptics.tap(.coin)
                coin.node.removeAllActions()
                coin.node.run(.sequence([.group([.scale(to: 1.8, duration: 0.15), .fadeOut(withDuration: 0.15)]), .removeFromParent()]))
                return true
            }
            return false
        }
    }

    private func checkBumps() {
        guard now > bumpCooldown, !finished else { return }
        for t in traffic {
            let tx = laneX(t.lane)
            let dx = carX - tx
            let gap = t.d - distance                    // + means the other car is ahead
            let reachY = (t.length + carLen) * 0.5 * 0.92
            let reachX = carW * 0.92
            guard abs(gap) < reachY && abs(dx) < reachX else { continue }
            bumpCooldown = now + 0.9
            Haptics.bump()
            if gap > 0 && abs(dx) < carW * 0.6 {
                // rear bump: bounce back softly
                carSpeed = min(carSpeed, t.vel) * 0.3
                distance = t.d - reachY - 6
                say("Boing! Leave a safe gap behind other cars. 🚗 ··· 🚙")
            } else {
                // side bump: nudge back into your lane
                latVel = 0
                carX = tx + (dx >= 0 ? reachX + 2 : -reachX - 2)
                say("Boop! Check your mirrors before changing lanes. 👀")
            }
            let pop = SpriteFactory.popWord("BOING!", size: laneW * 0.3)
            pop.position = CGPoint(x: car.position.x, y: car.position.y + carLen * 0.6)
            pop.zPosition = 80
            addChild(pop)
            let stars = SpriteFactory.dizzyStars(radius: laneW * 0.25)
            stars.position = CGPoint(x: 0, y: carLen * 0.3)
            stars.zPosition = 5
            car.addChild(stars)
            stars.run(.sequence([.wait(forDuration: 0.9), .removeFromParent()]))
            return
        }
    }

    // MARK: Effects

    private func effects() {
        // speed lines at high speed
        if carSpeed > maxSpeed * 0.6 && now > nextSpeedLine {
            nextSpeedLine = now + 0.05
            let line = SKSpriteNode(color: UIColor(white: 1, alpha: 0.5), size: CGSize(width: 2, height: CGFloat.random(in: 40...90)))
            line.position = CGPoint(x: CGFloat.random(in: roadLeft...(roadLeft + roadW)), y: size.height + 50)
            line.zPosition = 60
            addChild(line)
            line.run(.sequence([.moveBy(x: 0, y: -size.height - 150, duration: 0.35), .removeFromParent()]))
        }
        // exhaust puffs when pulling away
        if throttle > 0.4 && carSpeed < maxSpeed * 0.4 && now > nextPuff {
            nextPuff = now + 0.12
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...7))
            puff.fillColor = UIColor(white: 0.95, alpha: 0.7)
            puff.strokeColor = .clear
            puff.position = CGPoint(x: car.position.x + carW * 0.25, y: car.position.y - carLen * 0.52)
            puff.zPosition = 19
            addChild(puff)
            puff.run(.sequence([.group([.moveBy(x: CGFloat.random(in: -8...8), y: -30, duration: 0.6),
                                        .scale(to: 2.2, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                                .removeFromParent()]))
        }
    }

    // MARK: Messages

    private func award(_ text: String) {
        hud.stars += 1
        Haptics.success(.star)
        SpriteFactory.sparkleBurst(in: self, at: car.position, size: laneW)
        say(text)
    }

    private func say(_ text: String, seconds: TimeInterval = 2.8) {
        hud.message = text
        removeAction(forKey: "msg")
        run(.sequence([.wait(forDuration: seconds), .run { [weak self] in self?.hud.message = nil }]), withKey: "msg")
    }
}
