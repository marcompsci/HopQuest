import SpriteKit
import UIKit

/// Crossy-road style level: hop row by row past friendly traffic and floating logs,
/// answer Brain Gates, reach the castle, and jump into the hot air balloon.
/// Nothing ever "dies": bumps spin you with dizzy stars and drop you back on the last safe row.
///
/// Supports 1 player, or 2 players on one device (Grown-up & Me):
/// the left half of the screen moves player 1, the right half moves player 2.
final class HopScene: SKScene {

    enum RowKind { case grass, road, river, gate, castle }

    final class Mover {
        let node: SKNode
        let width: CGFloat
        init(node: SKNode, width: CGFloat) {
            self.node = node
            self.width = width
        }
    }

    final class Row {
        let index: Int
        let kind: RowKind
        let node: SKNode
        var speed: CGFloat = 0
        var movers: [Mover] = []
        var gateBanner: SKNode?
        init(index: Int, kind: RowKind, node: SKNode) {
            self.index = index
            self.kind = kind
            self.node = node
        }
    }

    /// One hopping character.
    final class Hopper {
        let index: Int
        let node = SKNode()
        var rowIdx = 0
        var lastSafeRow = 0
        var furthest = 0
        var busy = false
        var atCastle = false
        init(index: Int) { self.index = index }
    }

    // Callbacks to SwiftUI
    var onGate: ((Int) -> Void)?
    var onTip: ((String) -> Void)?
    var onProgress: ((Double) -> Void)?
    var onFinish: (() -> Void)?

    private let chapter: Chapter
    private let characters: [GameCharacter]
    private let theme: CastleTheme
    private let columns = 9
    /// In team mode, nobody may get more than this many rows ahead of their buddy.
    private let maxGap = 5

    private var cell: CGFloat = 40
    private var loopLength: CGFloat = 0
    private var rows: [Row] = []
    private var hoppers: [Hopper] = []
    private var frozen = false
    private var finished = false
    private var lastTime: TimeInterval = 0
    private var lastTipTime: TimeInterval = 0
    private let cam = SKCameraNode()
    private var touchStarts: [UITouch: CGPoint] = [:]
    private var balloon: SKNode?
    /// Counted on the scene (not a captured local) so the SKAction completion closure needn't mutate a captured var.
    private var ridersSeated = 0

    private var isTeam: Bool { hoppers.count > 1 }

    private static let roadTips = [
        "Boing! Cars are quick — wait for a big gap, then hop!",
        "Look left, look right, then look left again!",
        "Oops! Watch the cars and hop when the lane is clear."
    ]
    private static let riverTips = [
        "Splish! Hop onto the logs to cross the river.",
        "Water can't hold you up — ride a log across!"
    ]

    /// Single player.
    convenience init(size: CGSize, chapter: Chapter, character: GameCharacter, theme: CastleTheme) {
        self.init(size: size, chapter: chapter, characters: [character], theme: theme)
    }

    /// One or two players. Player 1 = left side of the screen, player 2 = right side.
    init(size: CGSize, chapter: Chapter, characters: [GameCharacter], theme: CastleTheme) {
        self.chapter = chapter
        self.characters = Array(characters.prefix(2))
        self.theme = theme
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        guard rows.isEmpty else { return }
        backgroundColor = UIColor(hex: snowy ? 0xEAF6FF : 0x8FD86E)
        cell = size.width / CGFloat(columns)
        loopLength = size.width + cell * 4
        buildRows()

        let startCols = characters.count > 1 ? [columns / 2 - 1, columns / 2 + 1] : [columns / 2]
        for (i, character) in characters.enumerated() {
            let h = Hopper(index: i)
            let shadow = SKShapeNode(ellipseOf: CGSize(width: cell * 0.62, height: cell * 0.2))
            shadow.fillColor = UIColor(white: 0, alpha: 0.22)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -cell * 0.36)
            shadow.name = "shadow"
            shadow.zPosition = -1
            h.node.addChild(shadow)
            let body = SpriteFactory.character(character, size: cell * 0.86)
            body.name = "body"
            h.node.addChild(body)
            if characters.count > 1 {
                let tag = SpriteFactory.emoji(i == 0 ? "⭐" : "💜", size: cell * 0.22, at: CGPoint(x: 0, y: cell * 0.5))
                h.node.addChild(tag)
            }
            h.node.position = point(col: startCols[i], row: 0)
            h.node.zPosition = 50 + CGFloat(i)
            addChild(h.node)
            hoppers.append(h)
        }

        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)
        camera = cam

        if isTeam {
            let divider = SKSpriteNode(color: UIColor.white.withAlphaComponent(0.35), size: CGSize(width: 3, height: size.height))
            divider.position = .zero
            divider.zPosition = 40
            cam.addChild(divider)
        }
    }

    // MARK: Level building

    /// Worlds from data (Snowy Peaks) restyle the classic level.
    private var style: HopStyle? { chapter.style }
    private var snowy: Bool { style?.isSnow == true }

    private func buildRows() {
        let finish = chapter.rows
        var previous: RowKind = .grass
        var kinds: [RowKind] = []
        for i in 0...(finish + 6) {
            let kind: RowKind
            if i < 2 {
                kind = .grass
            } else if i == finish {
                kind = .castle
            } else if i > finish || i == finish - 1 {
                kind = .grass
            } else if chapter.gateEvery > 0 && i % chapter.gateEvery == 0 {
                kind = .gate
            } else {
                let roll = Double.random(in: 0...1)
                let riverChance = style?.riverChance ?? (0.1 + Double(chapter.difficulty) * 0.22)
                if roll < riverChance {
                    kind = .river
                } else if roll < riverChance + 0.5 {
                    kind = .road
                } else {
                    kind = previous == .grass ? .road : .grass
                }
            }
            previous = kind
            kinds.append(kind)
        }
        for (i, kind) in kinds.enumerated() {
            let below = i > 0 ? kinds[i - 1] : .grass
            let above = i + 1 < kinds.count ? kinds[i + 1] : .grass
            rows.append(makeRow(i, kind: kind, decorate: i < finish, below: below, above: above))
        }
    }

    private func rowColor(_ kind: RowKind, _ i: Int) -> UIColor {
        switch kind {
        case .grass: return UIColor(hex: i % 2 == 0 ? 0x9BE07A : 0x8FD86E)
        case .road: return UIColor(hex: 0x5B6170)
        case .river: return UIColor(hex: 0x5EC8F2)
        case .gate: return UIColor(hex: 0xFFE38A)
        case .castle: return UIColor(hex: 0xB9F09B)
        }
    }

    private func makeRow(_ i: Int, kind: RowKind, decorate: Bool, below: RowKind, above: RowKind) -> Row {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: CGFloat(i) * cell)
        node.zPosition = 1
        addChild(node)
        let row = Row(index: i, kind: kind, node: node)

        let stripeW = size.width + cell * 6
        let stripeSize = CGSize(width: stripeW, height: cell + 1)
        let stripe: SKSpriteNode
        switch kind {
        case .grass, .castle:
            stripe = SKSpriteNode(texture: HopArt.grass(width: stripeW, cell: cell, light: i % 2 == 0), size: stripeSize)
        case .road:
            stripe = SKSpriteNode(texture: HopArt.road(width: stripeW, cell: cell,
                                                       top: above == .road ? .dash : .curb,
                                                       bottom: below == .road ? .dash : .curb), size: stripeSize)
        case .river:
            let frames = [HopArt.water(width: stripeW, cell: cell, frame: 0), HopArt.water(width: stripeW, cell: cell, frame: 1)]
            stripe = SKSpriteNode(texture: frames[0], size: stripeSize)
            stripe.run(.repeatForever(.animate(with: frames, timePerFrame: 0.45)))
        case .gate:
            stripe = SKSpriteNode(texture: HopArt.path(width: stripeW, cell: cell), size: stripeSize)
        }
        stripe.anchorPoint = .zero
        stripe.position = CGPoint(x: -cell * 3, y: 0)
        if snowy {
            // snow on the ground, icy water
            switch kind {
            case .grass, .castle, .gate:
                stripe.color = .white
                stripe.colorBlendFactor = kind == .gate ? 0.3 : 0.62
            case .river:
                stripe.color = UIColor(hex: 0xD8F1FF)
                stripe.colorBlendFactor = 0.35
            case .road:
                stripe.color = UIColor(hex: 0xDDE6F2)
                stripe.colorBlendFactor = 0.18
            }
        }
        node.addChild(stripe)

        let mid = cell / 2
        switch kind {
        case .grass:
            if decorate {
                for _ in 0..<Int.random(in: 0...2) {
                    let x = (CGFloat(Int.random(in: 0..<columns)) + 0.5) * cell
                    let f = SpriteFactory.emoji((style?.decorations.randomElement()) ?? ["🌼", "🌷", "🌸"].randomElement()!, size: cell * 0.3,
                                                at: CGPoint(x: x + CGFloat.random(in: -8...8), y: mid - cell * 0.18))
                    f.alpha = 0.95
                    node.addChild(f)
                }
            } else {
                for _ in 0..<Int.random(in: 1...3) {
                    let tree = SKSpriteNode(texture: DriveArt.tree, size: CGSize(width: cell * 1.1, height: cell * 1.1))
                    tree.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: mid)
                    tree.zPosition = 5
                    if snowy { tree.color = .white; tree.colorBlendFactor = 0.35 }
                    node.addChild(tree)
                }
            }
            if Int.random(in: 0..<3) == 0 {
                // bushes just off the play area edges
                let bush = SKSpriteNode(texture: DriveArt.bush, size: CGSize(width: cell * 0.9, height: cell * 0.72))
                bush.position = CGPoint(x: Bool.random() ? -cell * 0.1 : size.width + cell * 0.1, y: mid)
                bush.zPosition = 5
                node.addChild(bush)
            }

        case .road:
            let dir: CGFloat = Bool.random() ? 1 : -1
            row.speed = dir * CGFloat.random(in: 55...90) * (1 + chapter.difficulty)
            let count = Int.random(in: 2...3)
            let spacing = loopLength / CGFloat(count)
            let offset = CGFloat.random(in: 0..<spacing)
            for k in 0..<count {
                let roll = Int.random(in: 0..<8)
                let kind: HopArt.SideKind = roll == 0 ? .bus : (roll == 1 ? .truck : .car)
                let w = cell * (kind == .car ? CGFloat.random(in: 1.35...1.6) : 2.2)
                let h = cell * (kind == .car ? 0.74 : 0.82)
                let styled = style?.vehicleColors?.randomElement().flatMap { UInt32($0, radix: 16) }.map { UIColor(hex: $0) }
                let color = styled ?? (kind == .bus ? UIColor(hex: 0xFFC21A) : SpriteFactory.carColors.randomElement()!)
                let tex = HopArt.sideVehicle(kind, color: color, size: CGSize(width: w, height: h))
                let car = SKSpriteNode(texture: tex, size: CGSize(width: w + 8, height: h + 8))
                car.xScale = dir > 0 ? 1 : -1
                car.position = CGPoint(x: -cell * 2 + offset + CGFloat(k) * spacing, y: mid + cell * 0.04)
                car.zPosition = 10
                node.addChild(car)
                row.movers.append(Mover(node: car, width: w))
            }

        case .river:
            row.speed = (Bool.random() ? 1 : -1) * CGFloat.random(in: 40...65) * (1 + chapter.difficulty * 0.6)
            let count = 3
            let spacing = loopLength / CGFloat(count)
            let offset = CGFloat.random(in: 0..<spacing)
            let lilies = (chapter.id == 4 || style?.floaters == "lily") && Bool.random()
            let ice = style?.floaters == "ice"
            for k in 0..<count {
                if ice {
                    // a flat ice floe (works just like a log)
                    let w = cell * CGFloat.random(in: 2.3...3.0) * (1 - chapter.difficulty * 0.2)
                    let floe = SKShapeNode(rectOf: CGSize(width: w, height: cell * 0.62), cornerRadius: cell * 0.22)
                    floe.fillColor = UIColor(hex: 0xF4FBFF)
                    floe.strokeColor = UIColor(hex: 0x9FD2F2)
                    floe.lineWidth = 3
                    let shine = SKShapeNode(rectOf: CGSize(width: w * 0.4, height: cell * 0.08), cornerRadius: cell * 0.04)
                    shine.fillColor = .white
                    shine.strokeColor = .clear
                    shine.position = CGPoint(x: -w * 0.15, y: cell * 0.14)
                    floe.addChild(shine)
                    floe.position = CGPoint(x: -cell * 2 + offset + CGFloat(k) * spacing, y: mid)
                    floe.zPosition = 5
                    floe.run(.repeatForever(.sequence([.moveBy(x: 0, y: 2, duration: 0.8), .moveBy(x: 0, y: -2, duration: 0.8)])))
                    node.addChild(floe)
                    row.movers.append(Mover(node: floe, width: w))
                } else if lilies {
                    // a little raft of 2-3 lily pads
                    let pads = Int.random(in: 2...3)
                    let raft = SKNode()
                    for j in 0..<pads {
                        let pad = SKSpriteNode(texture: HopArt.lilyPad, size: CGSize(width: cell * 0.95, height: cell * 0.83))
                        pad.position = CGPoint(x: (CGFloat(j) - CGFloat(pads - 1) / 2) * cell, y: 0)
                        pad.zRotation = CGFloat.random(in: -0.4...0.4)
                        raft.addChild(pad)
                    }
                    raft.position = CGPoint(x: -cell * 2 + offset + CGFloat(k) * spacing, y: mid)
                    raft.zPosition = 5
                    raft.run(.repeatForever(.sequence([.moveBy(x: 0, y: 2, duration: 0.7), .moveBy(x: 0, y: -2, duration: 0.7)])))
                    node.addChild(raft)
                    row.movers.append(Mover(node: raft, width: CGFloat(pads) * cell))
                } else {
                    let w = cell * CGFloat.random(in: 2.3...3.0) * (1 - chapter.difficulty * 0.2)
                    let log = SKSpriteNode(texture: HopArt.log(length: w, height: cell * 0.7),
                                           size: CGSize(width: w + 8, height: cell * 0.7 + 10))
                    log.position = CGPoint(x: -cell * 2 + offset + CGFloat(k) * spacing, y: mid)
                    log.zPosition = 5
                    log.run(.repeatForever(.sequence([.rotate(toAngle: 0.015, duration: 0.9), .rotate(toAngle: -0.015, duration: 0.9)])))
                    node.addChild(log)
                    row.movers.append(Mover(node: log, width: w))
                }
            }

        case .gate:
            let banner = SpriteFactory.gateBanner(width: size.width, cell: cell)
            banner.position = CGPoint(x: size.width / 2, y: mid)
            banner.zPosition = 30
            node.addChild(banner)
            row.gateBanner = banner

        case .castle:
            let castle = SpriteFactory.castle(theme: theme, width: min(size.width * 0.55, 260))
            castle.position = CGPoint(x: size.width * 0.4, y: cell * 0.8)
            castle.zPosition = 20
            node.addChild(castle)

            let b = SpriteFactory.balloon(theme: theme, scale: cell)
            b.position = CGPoint(x: size.width * 0.84, y: mid)
            b.zPosition = 25
            b.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 0.8),
                                             .moveBy(x: 0, y: -6, duration: 0.8)])), withKey: "bob")
            node.addChild(b)
            balloon = b
        }
        return row
    }

    // MARK: Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchStarts[t] = t.location(in: view)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            guard let start = touchStarts.removeValue(forKey: t) else { continue }
            let end = t.location(in: view)
            let width = view?.bounds.width ?? size.width
            let player = isTeam && start.x >= width / 2 ? 1 : 0
            let dx = end.x - start.x
            let dy = end.y - start.y          // UIKit: +y is down
            if hypot(dx, dy) < 24 {
                hop(player: player, dc: 0, dr: 1)
            } else if abs(dx) > abs(dy) {
                hop(player: player, dc: dx > 0 ? 1 : -1, dr: 0)
            } else {
                hop(player: player, dc: 0, dr: dy < 0 ? 1 : -1)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchStarts.removeValue(forKey: t) }
    }

    /// Single-player shortcut used by the on-screen arrow pad.
    func hop(dc: Int, dr: Int) {
        hop(player: 0, dc: dc, dr: dr)
    }

    func hop(player: Int, dc: Int, dr: Int) {
        guard player < hoppers.count, !frozen, !finished else { return }
        let h = hoppers[player]
        guard !h.busy, !h.atCastle else { return }
        let newCol = column(for: h.node.position.x) + dc
        let newRow = h.rowIdx + dr
        guard newCol >= 0, newCol < columns, newRow >= 0, newRow <= chapter.rows else {
            wiggle(h)
            return
        }
        if isTeam, dr > 0, let slowest = hoppers.map({ $0.rowIdx }).min(), newRow > slowest + maxGap {
            wiggle(h)
            tip("Wait for your buddy! Teams stick together. 🤝")
            return
        }
        h.busy = true
        Haptics.tap(.hop)
        let duration = 0.16
        let move = SKAction.move(to: point(col: newCol, row: newRow), duration: duration)
        move.timingMode = .easeInEaseOut
        h.node.run(move) { [weak self] in
            self?.landed(h, row: newRow)
            self?.dust(at: h)
        }
        // the character leaps up and comes back down while the shadow stays on the ground
        if let body = h.node.childNode(withName: "body") {
            body.removeAction(forKey: "jump")
            let up = SKAction.moveTo(y: cell * 0.32, duration: duration / 2)
            up.timingMode = .easeOut
            let down = SKAction.moveTo(y: 0, duration: duration / 2)
            down.timingMode = .easeIn
            let stretch = SKAction.sequence([.group([.scaleX(to: 0.88, duration: duration / 2), .scaleY(to: 1.14, duration: duration / 2)]),
                                             .group([.scaleX(to: 1.0, duration: duration / 2), .scaleY(to: 1.0, duration: duration / 2)])])
            let landSquash = SKAction.sequence([.group([.scaleX(to: 1.14, duration: 0.05), .scaleY(to: 0.86, duration: 0.05)]),
                                                .group([.scaleX(to: 1.0, duration: 0.08), .scaleY(to: 1.0, duration: 0.08)])])
            body.run(.sequence([.group([.sequence([up, down]), stretch]), landSquash]), withKey: "jump")
        }
        if let shadow = h.node.childNode(withName: "shadow") {
            shadow.run(.sequence([.scale(to: 0.6, duration: duration / 2), .scale(to: 1.0, duration: duration / 2)]))
        }
    }

    /// Little puffs at the feet when landing on solid ground.
    private func dust(at h: Hopper) {
        guard h.rowIdx < rows.count, rows[h.rowIdx].kind != .river else { return }
        for side: CGFloat in [-1, 1] {
            let puff = SKShapeNode(circleOfRadius: cell * 0.07)
            puff.fillColor = UIColor(white: 1, alpha: 0.75)
            puff.strokeColor = .clear
            puff.position = CGPoint(x: h.node.position.x + side * cell * 0.18, y: h.node.position.y - cell * 0.34)
            puff.zPosition = 49
            addChild(puff)
            puff.run(.sequence([.group([.moveBy(x: side * cell * 0.22, y: cell * 0.05, duration: 0.3),
                                        .scale(to: 1.8, duration: 0.3), .fadeOut(withDuration: 0.3)]),
                                .removeFromParent()]))
        }
    }

    private func wiggle(_ h: Hopper) {
        h.node.run(.sequence([.moveBy(x: 5, y: 0, duration: 0.05),
                              .moveBy(x: -10, y: 0, duration: 0.08),
                              .moveBy(x: 5, y: 0, duration: 0.05)]))
    }

    private func landed(_ h: Hopper, row newRow: Int) {
        h.rowIdx = newRow
        h.busy = false
        if newRow > h.furthest {
            h.furthest = newRow
            // Team progress = the slower buddy.
            let team = hoppers.map { $0.furthest }.min() ?? newRow
            onProgress?(Double(team) / Double(max(chapter.rows, 1)))
        }
        let row = rows[newRow]
        switch row.kind {
        case .grass:
            h.lastSafeRow = newRow
        case .gate:
            h.lastSafeRow = newRow
            if row.gateBanner != nil {
                frozen = true
                onGate?(newRow)
            }
        case .river:
            if logUnder(row, h) == nil { splash(h) }
        case .road:
            checkCars(row, h)
        case .castle:
            h.lastSafeRow = newRow
            h.atCastle = true
            h.busy = true
            if hoppers.allSatisfy({ $0.atCastle }) {
                finish()
            } else {
                Haptics.success()
                SpriteFactory.sparkleBurst(in: self, at: h.node.position, size: cell)
                tip("You made it! Cheer for your buddy to reach the castle! 📣", force: true)
            }
        }
    }

    /// Called by SwiftUI after the Brain Gate question is answered.
    func clearGate(row: Int) {
        defer {
            frozen = false
            lastTime = 0
        }
        guard row < rows.count, let banner = rows[row].gateBanner else { return }
        rows[row].gateBanner = nil
        SoundFX.shared.play(.pop)
        banner.run(.sequence([.group([.scale(to: 1.3, duration: 0.2), .fadeOut(withDuration: 0.25)]),
                              .removeFromParent()]))
        SpriteFactory.sparkleBurst(in: self, at: CGPoint(x: size.width / 2, y: (CGFloat(row) + 0.5) * cell), size: cell * 1.4)
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : CGFloat(min(currentTime - lastTime, 1.0 / 20.0))
        lastTime = currentTime

        if !frozen {
            let half = cell * 2
            for row in rows where !row.movers.isEmpty {
                for m in row.movers {
                    m.node.position.x += row.speed * dt
                    if m.node.position.x > size.width + half {
                        m.node.position.x -= loopLength
                    } else if m.node.position.x < -half {
                        m.node.position.x += loopLength
                    }
                }
            }

            if !finished {
                for h in hoppers where !h.busy {
                    let row = rows[h.rowIdx]
                    if row.kind == .river {
                        if logUnder(row, h) != nil {
                            h.node.position.x += row.speed * dt
                            if h.node.position.x < cell * 0.2 || h.node.position.x > size.width - cell * 0.2 {
                                splash(h)
                            }
                        } else {
                            splash(h)
                        }
                    } else if row.kind == .road {
                        checkCars(row, h)
                    }
                }
            }
        }
        followCamera()
    }

    private func followCamera() {
        let onBoard = hoppers.filter { $0.node.parent === self }
        guard let lowest = onBoard.map({ $0.node.position.y }).min() else { return }
        let target = max(size.height / 2, lowest + size.height * 0.2)
        let maxY = CGFloat(rows.count) * cell - size.height / 2
        let y = min(target, max(maxY, size.height / 2))
        cam.position.y += (y - cam.position.y) * 0.12
    }

    // MARK: Hazards (kid-friendly)

    private func logUnder(_ row: Row, _ h: Hopper) -> Mover? {
        row.movers.first { abs($0.node.position.x - h.node.position.x) < $0.width / 2 - cell * 0.08 }
    }

    private func checkCars(_ row: Row, _ h: Hopper) {
        let hit = row.movers.contains { abs($0.node.position.x - h.node.position.x) < $0.width / 2 + cell * 0.2 }
        if hit { bonk(h) }
    }

    private func bonk(_ h: Hopper) {
        guard !h.busy else { return }
        h.busy = true
        Haptics.bump()
        tip(Self.roadTips.randomElement()!, force: true)

        let stars = SpriteFactory.dizzyStars(radius: cell * 0.45)
        stars.position = CGPoint(x: 0, y: cell * 0.5)
        h.node.addChild(stars)

        let pop = SpriteFactory.popWord("BOING!", size: cell * 0.45)
        pop.position = CGPoint(x: h.node.position.x, y: h.node.position.y + cell * 0.8)
        pop.zPosition = 80
        addChild(pop)

        let back = SKAction.move(to: point(col: column(for: h.node.position.x), row: h.lastSafeRow), duration: 0.35)
        back.timingMode = .easeInEaseOut
        h.node.run(.sequence([
            .group([.rotate(byAngle: .pi * 2, duration: 0.45),
                    .sequence([.scale(to: 1.25, duration: 0.15), .scale(to: 1.0, duration: 0.3)])]),
            .wait(forDuration: 0.25),
            back
        ])) {
            stars.removeFromParent()
            h.node.zRotation = 0
            h.rowIdx = h.lastSafeRow
            h.busy = false
        }
    }

    private func splash(_ h: Hopper) {
        guard !h.busy else { return }
        h.busy = true
        Haptics.bump(.splash)
        tip(style?.floaters == "ice" ? "Splash! Hop onto the ice floes to cross the cold water." : Self.riverTips.randomElement()!, force: true)

        let pop = SpriteFactory.popWord("SPLISH!", size: cell * 0.45, color: UIColor(hex: 0xD6F1FF))
        pop.position = CGPoint(x: h.node.position.x, y: h.node.position.y + cell * 0.6)
        pop.zPosition = 80
        addChild(pop)
        for i in 0..<5 {
            let bubble = SpriteFactory.emoji("🫧", size: cell * 0.3,
                                             at: CGPoint(x: h.node.position.x + CGFloat(i - 2) * cell * 0.15, y: h.node.position.y))
            bubble.zPosition = 60
            addChild(bubble)
            bubble.run(.sequence([.group([.moveBy(x: 0, y: cell * 0.8, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                                  .removeFromParent()]))
        }

        let safe = point(col: column(for: h.node.position.x), row: h.lastSafeRow)
        h.node.run(.sequence([
            .group([.scale(to: 0.3, duration: 0.25), .fadeAlpha(to: 0.2, duration: 0.25)]),
            .move(to: safe, duration: 0.01),
            .wait(forDuration: 0.3),
            .group([.scale(to: 1.0, duration: 0.25), .fadeAlpha(to: 1.0, duration: 0.25)])
        ])) {
            h.rowIdx = h.lastSafeRow
            h.busy = false
        }
    }

    /// Sends a tip to SwiftUI, at most once every 2 seconds unless `force` is set.
    private func tip(_ text: String, force: Bool = false) {
        guard force || lastTime - lastTipTime > 2 else { return }
        lastTipTime = lastTime
        onTip?(text)
    }

    // MARK: Finish line

    private func finish() {
        guard !finished, let balloon else { return }
        finished = true
        Haptics.success(.fanfare)
        for h in hoppers {
            SpriteFactory.confetti(in: self, at: h.node.position, spread: cell * 3)
        }
        balloon.removeAction(forKey: "bob")

        let seat = SpriteFactory.basketSeat(scale: cell)
        let offsets: [CGFloat] = hoppers.count > 1 ? [-cell * 0.22, cell * 0.22] : [0]
        ridersSeated = 0
        for (i, h) in hoppers.enumerated() {
            let target = balloon.convert(CGPoint(x: seat.x + offsets[i], y: seat.y), to: self)
            let jump = SKAction.move(to: target, duration: 0.45)
            jump.timingMode = .easeInEaseOut
            let riderScale: CGFloat = hoppers.count > 1 ? 0.8 : 1.0
            let arc = SKAction.sequence([.scale(to: 1.35, duration: 0.22), .scale(to: riderScale, duration: 0.23)])
            h.node.run(.sequence([.wait(forDuration: 0.5 + Double(i) * 0.25), .group([jump, arc])])) { [weak self] in
                guard let self, let balloon = self.balloon else { return }
                h.node.move(toParent: balloon)
                h.node.zPosition = 2 + CGFloat(i) * 0.1   // between envelope (1) and basket (3)
                self.ridersSeated += 1
                if self.ridersSeated == self.hoppers.count {
                    self.liftOff(balloon)
                }
            }
        }
    }

    private func liftOff(_ balloon: SKNode) {
        SoundFX.shared.play(.whoosh)
        let rise = SKAction.moveBy(x: size.width * 0.08, y: size.height * 1.3, duration: 2.4)
        rise.timingMode = .easeIn
        balloon.run(.group([rise, .scale(to: 0.6, duration: 2.4)]))
        run(.wait(forDuration: 1.6)) { [weak self] in
            self?.onFinish?()
        }
    }

    // MARK: Grid helpers

    private func point(col: Int, row: Int) -> CGPoint {
        CGPoint(x: (CGFloat(col) + 0.5) * cell, y: (CGFloat(row) + 0.5) * cell)
    }

    private func column(for x: CGFloat) -> Int {
        max(0, min(columns - 1, Int((x / cell - 0.5).rounded())))
    }
}
