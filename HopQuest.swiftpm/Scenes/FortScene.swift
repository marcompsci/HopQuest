import SpriteKit
import SwiftUI
import UIKit

// MARK: - Levels

/// A Fort Friends level, drawn as text so new levels don't need code changes.
/// Rows go top to bottom. `.` empty, `#` ground, `~` water, `S` start, `B` balloon,
/// `C` brick crate, `G` golden Brain crate, `F` the fort (finish).
struct FortLevel: Identifiable {
    let id: Int
    let title: String
    let blurb: String
    let startBricks: Int
    /// How fast the rain cloud drifts after you, in cells per second.
    let rainSpeed: CGFloat
    let rows: [String]

    static let all: [FortLevel] = [
        FortLevel(id: 301, title: "Sunny Cliffs", blurb: "Learn ramps and bridges", startBricks: 8, rainSpeed: 0.20, rows: [
            "..............................",
            "..............................",
            "..............................",
            ".......B..............B.......",
            "......###........B...###......",
            "S..C..###.....G......###...F..",
            "##########~~~~################",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ]),
        FortLevel(id: 302, title: "Rainbow River", blurb: "Long bridges and a sky balloon", startBricks: 12, rainSpeed: 0.24, rows: [
            "................................",
            "................B...............",
            "................................",
            "..........B..G..................",
            ".....###...............B........",
            "S.C..###..............###....F..",
            "########~~~~~~~~~~##############",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ]),
        FortLevel(id: 303, title: "Sky Fort", blurb: "Build a staircase to the top", startBricks: 14, rainSpeed: 0.27, rows: [
            "..............................",
            "...........................F..",
            "......................B...###.",
            "...........B..............###.",
            "..........###......B......###.",
            "S..C..G..####.....###.....###.",
            "################~~###~~~######",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ])
    ]

    static func level(_ id: Int) -> FortLevel { all.first { $0.id == id } ?? all[0] }
}

enum FortTool: String, CaseIterable, Identifiable {
    case ramp, block, bridge, recycle
    var id: String { rawValue }

    var cost: Int {
        switch self {
        case .ramp: return 2
        case .block, .bridge: return 1
        case .recycle: return 0
        }
    }

    var title: String {
        switch self {
        case .ramp: return "Ramp"
        case .block: return "Block"
        case .bridge: return "Bridge"
        case .recycle: return "Take back"
        }
    }

    var art: String? {
        switch self {
        case .ramp: return "piece_ramp"
        case .block: return "piece_block"
        case .bridge: return "piece_bridge"
        case .recycle: return nil
        }
    }

    /// The first time each piece is built, a short engineering idea is read aloud.
    var lesson: String {
        switch self {
        case .ramp: return "A ramp is an inclined plane. It's a simple machine that makes going up easier!"
        case .block: return "Blocks hold things up. Engineers call that support!"
        case .bridge: return "Bridges have to hold on to something at the end, just like real bridges!"
        case .recycle: return "Taking a piece back gives you your bricks back. Reduce, reuse, recycle!"
        }
    }
}

/// Live numbers for the SwiftUI HUD.
final class FortHUD: ObservableObject {
    @Published var bricks = 0
    @Published var balloons = 0
    @Published var totalBalloons = 0
    @Published var message: String?
    @Published var question: Question?
    @Published var rainNear = false
    @Published var finished = false
    @Published var brainRight = 0
}

// MARK: - Scene

/// Fort Friends: the build-and-explore mode (a gentle take on building games).
/// Walk left and right, build ramps, blocks, and bridges to reach balloons and the fort.
/// A sleepy rain cloud drifts along behind you instead of a storm. Getting caught only costs two bricks.
/// There's no combat and no way to lose.
final class FortScene: SKScene {

    enum Tile: Equatable {
        case empty, ground, water, block, ramp(CGFloat), bridge
        var solid: Bool {
            switch self {
            case .ground, .block, .ramp, .bridge: return true
            case .empty, .water: return false
            }
        }
        var built: Bool {
            switch self {
            case .block, .ramp, .bridge: return true
            default: return false
            }
        }
    }

    enum Item { case balloon, crate, gold, fort }

    struct Cell: Hashable { var x: Int; var y: Int }

    // Controls (set from SwiftUI)
    var moveInput: CGFloat = 0
    var tool: FortTool? { didSet { refreshGhosts() } }

    let hud: FortHUD
    let level: FortLevel
    private let character: GameCharacter
    private let theme: CastleTheme

    private var cols = 0
    private var rows = 0
    private var tiles: [[Tile]] = []          // [x][y], y = 0 at the bottom
    private var tileNodes: [Cell: SKNode] = [:]
    private var items: [Cell: Item] = [:]
    private var itemNodes: [Cell: SKNode] = [:]
    private var crates = 0

    private let world = SKNode()
    private let ghostLayer = SKNode()
    private let rainLayer = SKNode()
    private let playerNode = SKNode()
    private let playerBody = SKNode()

    private var cellSize: CGFloat = 48
    private var baseY: CGFloat = 0
    private var player = Cell(x: 0, y: 2)
    private var lastSafe = Cell(x: 0, y: 2)
    private var facing: CGFloat = 1
    private var busy = true
    private var started = false
    private var ended = false

    private var rainX: CGFloat = -7
    private var rainFront = SKShapeNode()
    private var rainCloud = SKSpriteNode()
    private var lastDrop: TimeInterval = 0

    private var lastTime: TimeInterval = 0
    private var now: TimeInterval = 0
    private var camX: CGFloat = 0
    private var usedTools: Set<FortTool> = []
    private var tipsGiven: Set<String> = []
    private let questions: [Question]
    private var questionIndex = 0

    init(size: CGSize, level: FortLevel, character: GameCharacter, theme: CastleTheme, hud: FortHUD) {
        self.level = level
        self.character = character
        self.theme = theme
        self.hud = hud
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
        guard tiles.isEmpty else { return }
        backgroundColor = UIColor(hex: 0xBFE6FF)
        if let tex = SpriteFactory.artTexture("arena_bg") {
            let bg = SKSpriteNode(texture: tex)
            let scale = max(size.width / 400, size.height / 860)
            bg.size = CGSize(width: 400 * scale, height: 860 * scale)
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.zPosition = -50
            addChild(bg)
        }

        rows = level.rows.count
        cols = level.rows.map(\.count).max() ?? 0
        let bottomUI: CGFloat = 186
        let topUI: CGFloat = 150
        cellSize = floor(min(size.width / 7.2, (size.height - bottomUI - topUI) / CGFloat(rows)))
        baseY = bottomUI - cellSize * 0.7

        // water all the way down to the bottom of the screen
        let sea = SKSpriteNode(color: UIColor(hex: 0x5EC8F2), size: CGSize(width: size.width, height: baseY + cellSize * 0.2))
        sea.anchorPoint = .zero
        sea.zPosition = -40
        addChild(sea)

        addChild(world)
        world.addChild(ghostLayer)
        ghostLayer.zPosition = 30
        world.addChild(rainLayer)
        rainLayer.zPosition = 60

        parseLevel()
        buildRain()
        buildPlayer()
        hud.bricks = level.startBricks
        hud.totalBalloons = items.values.filter { if case .balloon = $0 { return true } else { return false } }.count
        camX = targetCamX()
        world.position.x = -camX
        dropIn()
    }

    private func parseLevel() {
        tiles = Array(repeating: Array(repeating: Tile.empty, count: rows), count: cols)
        for (rowIndex, line) in level.rows.enumerated() {
            let y = rows - 1 - rowIndex
            for (x, ch) in line.enumerated() {
                let cell = Cell(x: x, y: y)
                switch ch {
                case "#": tiles[x][y] = .ground
                case "~": tiles[x][y] = .water
                case "S": player = cell; lastSafe = cell
                case "B": items[cell] = .balloon
                case "C": items[cell] = .crate; crates += 1
                case "G": items[cell] = .gold
                case "F": items[cell] = .fort
                default: break
                }
            }
        }
        for x in 0..<cols {
            for y in 0..<rows {
                drawTile(Cell(x: x, y: y))
            }
        }
        for (cell, item) in items { drawItem(item, at: cell) }
    }

    private func center(_ c: Cell) -> CGPoint {
        CGPoint(x: (CGFloat(c.x) + 0.5) * cellSize, y: baseY + (CGFloat(c.y) + 0.5) * cellSize)
    }

    /// Where a buddy's feet go when standing in this cell.
    private func feet(_ c: Cell) -> CGPoint {
        CGPoint(x: (CGFloat(c.x) + 0.5) * cellSize, y: baseY + CGFloat(c.y) * cellSize)
    }

    private func drawTile(_ c: Cell) {
        tileNodes[c]?.removeFromParent()
        tileNodes[c] = nil
        let t = tiles[c.x][c.y]
        let name: String
        var xScale: CGFloat = 1
        switch t {
        case .empty: return
        case .ground:
            let open = c.y + 1 < rows && !tiles[c.x][c.y + 1].solid
            name = open ? "fort_grass" : "fort_dirt"
        case .water: name = "fort_water"
        case .block: name = "piece_block"
        case .bridge: name = "piece_bridge"
        case .ramp(let dir):
            name = "piece_ramp"
            xScale = dir
        }
        let sprite: SKNode
        if let tex = SpriteFactory.artTexture(name) {
            let s = SKSpriteNode(texture: tex, size: CGSize(width: cellSize + 1, height: cellSize + 1))
            s.xScale = xScale
            sprite = s
        } else {
            sprite = SKSpriteNode(color: .brown, size: CGSize(width: cellSize, height: cellSize))
        }
        sprite.position = center(c)
        sprite.zPosition = t == .water ? 0 : (t.built ? 6 : 2)
        world.addChild(sprite)
        tileNodes[c] = sprite
        if t == .water {
            sprite.run(.repeatForever(.sequence([.moveBy(x: 0, y: 2, duration: 0.8), .moveBy(x: 0, y: -2, duration: 0.8)])))
        }
    }

    private func drawItem(_ item: Item, at c: Cell) {
        let node: SKNode
        switch item {
        case .balloon:
            let s = SKSpriteNode(texture: SpriteFactory.artTexture("party_balloon"), size: CGSize(width: cellSize * 0.85, height: cellSize * 0.85))
            node = s
            node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 5, duration: 0.7), .moveBy(x: 0, y: -5, duration: 0.7)])))
            node.position = center(c)
        case .crate, .gold:
            let s = SKSpriteNode(texture: SpriteFactory.artTexture(item == .gold ? "crate_gold" : "crate"),
                                 size: CGSize(width: cellSize * 0.8, height: cellSize * 0.8))
            node = s
            node.position = CGPoint(x: center(c).x, y: feet(c).y + cellSize * 0.4)
            if item == .gold {
                node.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 0.5), .scale(to: 1, duration: 0.5)])))
            }
        case .fort:
            let w = cellSize * 2.1
            let s = SKSpriteNode(texture: SpriteFactory.artTexture("fort_goal"), size: CGSize(width: w, height: w * 1.3))
            s.anchorPoint = CGPoint(x: 0.5, y: 6.0 / 260.0)
            node = s
            node.position = feet(c)
        }
        node.zPosition = item == .fort ? 4 : 20
        world.addChild(node)
        itemNodes[c] = node
    }

    private func buildPlayer() {
        let art = SpriteFactory.character(character, size: cellSize * 0.95)
        art.position = CGPoint(x: 0, y: cellSize * 0.95 * 0.42)
        playerBody.addChild(art)
        playerNode.addChild(playerBody)
        playerNode.zPosition = 40
        playerNode.position = feet(player)
        world.addChild(playerNode)
    }

    private func buildRain() {
        let h = CGFloat(rows) * cellSize + 400
        rainFront = SKShapeNode(rect: CGRect(x: -3000, y: baseY - 200, width: 3000, height: h))
        rainFront.fillColor = UIColor(hex: 0x5B6B8C).withAlphaComponent(0.28)
        rainFront.strokeColor = .clear
        rainLayer.addChild(rainFront)
        if let tex = SpriteFactory.artTexture("rain_cloud") {
            rainCloud = SKSpriteNode(texture: tex, size: CGSize(width: cellSize * 3.2, height: cellSize * 3.2 * 152 / 360))
            rainCloud.zPosition = 2
            rainLayer.addChild(rainCloud)
        }
        placeRain()
    }

    private func placeRain() {
        let x = rainX * cellSize
        rainFront.position.x = x
        rainCloud.position = CGPoint(x: x - cellSize * 0.8, y: baseY + CGFloat(rows) * cellSize - cellSize * 0.2)
    }

    /// Fortnite-style start: your buddy rides a balloon down and hops out.
    private func dropIn() {
        playerNode.isHidden = true
        let s = cellSize * 0.7
        let balloon = SpriteFactory.balloon(theme: theme, scale: s)
        let landing = feet(player)
        balloon.position = CGPoint(x: landing.x, y: size.height + s * 3)
        balloon.zPosition = 50
        world.addChild(balloon)
        let rider = SpriteFactory.character(character, size: s * 0.9)
        rider.position = SpriteFactory.basketSeat(scale: s)
        rider.zPosition = 2
        balloon.addChild(rider)
        let down = SKAction.move(to: CGPoint(x: landing.x, y: landing.y + cellSize * 0.9), duration: 1.3)
        down.timingMode = .easeOut
        balloon.run(.sequence([
            down,
            .run { [weak self] in
                guard let self else { return }
                rider.removeFromParent()
                self.playerNode.isHidden = false
                self.playerNode.position = CGPoint(x: landing.x, y: landing.y + self.cellSize * 0.5)
                self.playerNode.run(.move(to: landing, duration: 0.18))
                Haptics.tap(.hop)
            },
            .wait(forDuration: 0.25),
            .run { [weak self] in
                guard let self else { return }
                self.busy = false
                self.started = true
                self.say("Tap a piece below, then tap a glowing square to build it!")
                self.refreshGhosts()
            },
            .group([.moveBy(x: 0, y: size.height, duration: 1.6), .fadeOut(withDuration: 1.6)]),
            .removeFromParent()
        ]))
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, 1.0 / 20.0)
        lastTime = currentTime
        now += dt

        if started && !ended && !busy && moveInput != 0 {
            step(moveInput > 0 ? 1 : -1)
        }

        // rain cloud drifts along behind (waits a little at the start)
        if started && !ended && now > 10 {
            rainX += level.rainSpeed * CGFloat(dt)
            if rainX > CGFloat(player.x) + 0.3 && !busy { caughtByRain() }
            let near = CGFloat(player.x) - rainX < 4
            if near != hud.rainNear { hud.rainNear = near }
        }
        placeRain()
        dropRain()

        camX += (targetCamX() - camX) * min(1, CGFloat(dt) * 6)
        world.position.x = -camX
    }

    private func targetCamX() -> CGFloat {
        let worldW = CGFloat(cols) * cellSize
        if worldW <= size.width { return -(size.width - worldW) / 2 }
        let want = playerNode.position.x - size.width * 0.4
        return min(max(want, 0), worldW - size.width)
    }

    private func dropRain() {
        guard now - lastDrop > 0.05 else { return }
        lastDrop = now
        let front = rainX * cellSize
        let left = max(camX, front - size.width)
        guard front > camX else { return }
        let drop = SKShapeNode(rectOf: CGSize(width: 2.5, height: 14), cornerRadius: 1.2)
        drop.fillColor = UIColor(hex: 0x9FD8FF)
        drop.strokeColor = .clear
        drop.position = CGPoint(x: .random(in: left...max(left + 1, front - 6)), y: baseY + CGFloat(rows) * cellSize - cellSize * 0.5)
        drop.zPosition = 1
        rainLayer.addChild(drop)
        drop.run(.sequence([.moveBy(x: -6, y: -CGFloat(rows) * cellSize, duration: 0.7), .removeFromParent()]))
    }

    // MARK: Walking

    private func tile(_ x: Int, _ y: Int) -> Tile {
        guard x >= 0, x < cols else { return .ground }   // edges of the world are walls
        guard y >= 0 else { return .water }
        guard y < rows else { return .empty }
        return tiles[x][y]
    }

    private func step(_ d: Int) {
        let dir = CGFloat(d)
        if facing != dir {
            facing = dir
            playerBody.xScale = dir
            refreshGhosts()
        }
        let nx = player.x + d
        let ahead = tile(nx, player.y)

        if case .ramp(let rampDir) = ahead, rampDir == dir, !tile(nx, player.y + 1).solid, nx >= 0, nx < cols {
            moveTo(Cell(x: nx, y: player.y + 1), climb: true)
            return
        }
        if nx < 0 || nx >= cols || ahead.solid {
            bump()
            return
        }
        // about to step over water with nothing to stand on?
        if !tile(nx, player.y - 1).solid && lowestLanding(nx, player.y) == nil {
            tip("water", "Water ahead! Build a bridge to get across.")
        }
        moveTo(Cell(x: nx, y: player.y), climb: false)
    }

    /// The cell you'd land in if you fell from (x, y), or nil if you'd fall in the water.
    private func lowestLanding(_ x: Int, _ y: Int) -> Cell? {
        var yy = y
        while yy > 0 {
            let below = tile(x, yy - 1)
            if below.solid { return Cell(x: x, y: yy) }
            if below == .water { return nil }
            yy -= 1
        }
        return nil
    }

    private func moveTo(_ c: Cell, climb: Bool) {
        busy = true
        let dur = climb ? 0.24 : 0.17
        let hop = SKAction.sequence([.moveBy(x: 0, y: cellSize * 0.18, duration: dur / 2), .moveBy(x: 0, y: -cellSize * 0.18, duration: dur / 2)])
        playerBody.run(hop)
        let move = SKAction.move(to: feet(c), duration: dur)
        player = c
        collect(at: c)
        playerNode.run(move) { [weak self] in
            self?.afterMove()
        }
        if climb { SoundFX.shared.play(.hop, volume: 0.6) }
    }

    private func afterMove() {
        guard !ended else { return }
        // fall if nothing is underneath
        if !tile(player.x, player.y - 1).solid {
            if let landing = lowestLanding(player.x, player.y) {
                let fallCells = player.y - landing.y
                // collect anything we fall past
                for y in stride(from: player.y - 1, through: landing.y, by: -1) { collect(at: Cell(x: player.x, y: y)) }
                player = landing
                let fall = SKAction.move(to: feet(landing), duration: 0.09 * Double(fallCells) + 0.05)
                fall.timingMode = .easeIn
                playerNode.run(fall) { [weak self] in
                    guard let self else { return }
                    self.land()
                }
            } else {
                splash()
            }
            return
        }
        land()
    }

    private func land() {
        lastSafe = player
        busy = false
        refreshGhosts()
        if items[player] == .fort { reachFort() }
    }

    private func bump() {
        busy = true
        let d = facing
        playerBody.run(.sequence([.moveBy(x: d * 6, y: 0, duration: 0.06), .moveBy(x: -d * 6, y: 0, duration: 0.1)])) { [weak self] in
            self?.busy = false
        }
        let ahead = tile(player.x + Int(d), player.y)
        if ahead.solid {
            tip("wall", "Too tall to walk up! Build a ramp to climb.")
        }
    }

    private func splash() {
        busy = true
        Haptics.bump(.splash)
        let word = SpriteFactory.popWord("SPLISH!", size: 24)
        word.position = CGPoint(x: playerNode.position.x, y: baseY + cellSize * 2)
        word.zPosition = 80
        world.addChild(word)
        let fall = SKAction.move(to: CGPoint(x: playerNode.position.x, y: baseY + cellSize * 0.4), duration: 0.35)
        fall.timingMode = .easeIn
        say("Splish! Build a bridge so you can walk over the water.")
        playerNode.run(.sequence([fall, .fadeOut(withDuration: 0.2), .wait(forDuration: 0.5), .run { [weak self] in
            guard let self else { return }
            self.player = self.lastSafe
            self.playerNode.position = self.feet(self.lastSafe)
            self.playerNode.alpha = 1
            self.playerNode.run(.repeat(.sequence([.fadeAlpha(to: 0.4, duration: 0.1), .fadeAlpha(to: 1, duration: 0.1)]), count: 3))
            self.busy = false
            self.refreshGhosts()
        }]))
    }

    private func caughtByRain() {
        let lost = min(2, hud.bricks)
        hud.bricks -= lost
        rainX = CGFloat(player.x) - 6
        Haptics.bump(.splash)
        let word = SpriteFactory.popWord(lost > 0 ? "-\(lost) bricks" : "Drip drop!", size: 20, color: UIColor(hex: 0x9FD8FF))
        word.position = CGPoint(x: playerNode.position.x, y: playerNode.position.y + cellSize * 1.2)
        word.zPosition = 80
        world.addChild(word)
        say("The sleepy rain cloud caught up! It floats back a bit. Keep building forward!")
    }

    // MARK: Items

    private func collect(at c: Cell) {
        guard let item = items[c] else { return }
        switch item {
        case .fort:
            return
        case .balloon:
            items[c] = nil
            hud.balloons += 1
            if let n = itemNodes.removeValue(forKey: c) {
                SpriteFactory.sparkleBurst(in: world, at: n.position, size: cellSize)
                n.run(.sequence([.group([.moveBy(x: 0, y: cellSize * 2, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
            }
            Haptics.success(.star)
            let left = hud.totalBalloons - hud.balloons
            say(left == 0 ? "You found every balloon! Now head to the fort!" : "Balloon! \(left) more to find.")
        case .crate:
            items[c] = nil
            crates -= 1
            hud.bricks += 4
            if let n = itemNodes.removeValue(forKey: c) {
                n.run(.sequence([.group([.scale(to: 1.4, duration: 0.15), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
            }
            popAt(c, "+4 bricks")
            Haptics.success(.coin)
        case .gold:
            items[c] = nil
            if let n = itemNodes.removeValue(forKey: c) {
                SpriteFactory.sparkleBurst(in: world, at: n.position, size: cellSize)
                n.removeFromParent()
            }
            askQuestion()
        }
    }

    private func popAt(_ c: Cell, _ text: String) {
        let word = SpriteFactory.popWord(text, size: 20, color: UIColor(hex: 0xFFD93D))
        word.position = CGPoint(x: center(c).x, y: center(c).y + cellSize * 0.5)
        word.zPosition = 80
        world.addChild(word)
    }

    private func askQuestion() {
        guard !questions.isEmpty else { return }
        hud.question = questions[questionIndex % questions.count]
        questionIndex += 1
        isPaused = true
    }

    /// Called by SwiftUI when the Brain Gate card is done.
    func answered(firstTry: Bool) {
        hud.question = nil
        isPaused = false
        lastTime = 0
        let gift = firstTry ? 8 : 5
        if firstTry { hud.brainRight += 1 }
        hud.bricks += gift
        popAt(player, "+\(gift) bricks")
        Haptics.success(.coin)
        say(firstTry ? "Super brain! +\(gift) bricks!" : "You got it! +\(gift) bricks!")
    }

    private func reachFort() {
        guard !ended else { return }
        ended = true
        busy = true
        SpriteFactory.confetti(in: world, at: CGPoint(x: playerNode.position.x, y: playerNode.position.y + cellSize * 2), spread: cellSize * 3)
        Haptics.success(.fanfare)
        hud.rainNear = false
        rainLayer.run(.fadeOut(withDuration: 0.6))
        playerBody.run(.repeat(.sequence([.moveBy(x: 0, y: cellSize * 0.4, duration: 0.15), .moveBy(x: 0, y: -cellSize * 0.4, duration: 0.15)]), count: 3))
        run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in self?.hud.finished = true }]))
    }

    // MARK: Building

    /// Cells near you where the selected piece can go (or, for Take back, pieces you can pick up).
    private func canPlace(_ t: FortTool, at c: Cell) -> Bool {
        guard c.x >= 0, c.x < cols, c.y >= 1, c.y < rows else { return false }
        guard abs(c.x - player.x) <= 3, abs(c.y - player.y) <= 3 else { return false }
        let here = tile(c.x, c.y)
        if t == .recycle {
            // don't pull the floor out from under your buddy
            return here.built && !(c.x == player.x && c.y == player.y - 1)
        }
        guard here == .empty || here == .water else { return false }
        guard items[c] == nil, c != player else { return false }
        return tile(c.x, c.y - 1).solid || tile(c.x - 1, c.y).solid && c.x - 1 >= 0 || tile(c.x + 1, c.y).solid && c.x + 1 < cols
    }

    private func refreshGhosts() {
        ghostLayer.removeAllChildren()
        guard let tool, started, !ended else { return }
        for x in (player.x - 3)...(player.x + 3) {
            for y in max(1, player.y - 3)...min(rows - 1, player.y + 3) {
                let c = Cell(x: x, y: y)
                guard canPlace(tool, at: c) else { continue }
                let r = SKShapeNode(rectOf: CGSize(width: cellSize * 0.86, height: cellSize * 0.86), cornerRadius: cellSize * 0.18)
                r.position = center(c)
                if tool == .recycle {
                    r.fillColor = UIColor(hex: 0xFF5A5F).withAlphaComponent(0.18)
                    r.strokeColor = UIColor(hex: 0xFF5A5F)
                } else {
                    r.fillColor = UIColor.white.withAlphaComponent(0.25)
                    r.strokeColor = UIColor(hex: 0x34C77B)
                    if tool == .ramp, let tex = SpriteFactory.artTexture("piece_ramp") {
                        let preview = SKSpriteNode(texture: tex, size: CGSize(width: cellSize * 0.6, height: cellSize * 0.6))
                        preview.alpha = 0.35
                        preview.xScale = facing
                        r.addChild(preview)
                    }
                }
                r.lineWidth = 3
                r.glowWidth = 1
                r.run(.repeatForever(.sequence([.fadeAlpha(to: 0.55, duration: 0.5), .fadeAlpha(to: 1, duration: 0.5)])))
                ghostLayer.addChild(r)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard started, !ended, !busy, let touch = touches.first else { return }
        let p = touch.location(in: world)
        let c = Cell(x: Int(floor(p.x / cellSize)), y: Int(floor((p.y - baseY) / cellSize)))
        guard let tool else {
            if tile(c.x, c.y).built { say("Pick Take back to pick a piece up again.") }
            else { say("Pick a piece below first, then tap a glowing square.") }
            return
        }
        guard canPlace(tool, at: c) else {
            Haptics.bump(.oops)
            if abs(c.x - player.x) > 3 || abs(c.y - player.y) > 3 {
                say("That's too far away. Build close to your buddy!")
            } else if tool != .recycle {
                say("Pieces need something to hold on to: the ground or another piece.")
            }
            return
        }
        if tool == .recycle {
            remove(at: c)
        } else {
            place(tool, at: c)
        }
    }

    private func place(_ t: FortTool, at c: Cell) {
        guard hud.bricks >= t.cost else {
            if crates > 0 {
                say("You need \(t.cost) bricks. Find a crate for more!")
                Haptics.bump(.oops)
            } else {
                hud.bricks += 6
                say("Here come 6 helper bricks! Keep building!")
                Haptics.success(.coin)
                popAt(player, "+6 bricks")
            }
            return
        }
        hud.bricks -= t.cost
        switch t {
        case .ramp: tiles[c.x][c.y] = .ramp(facing)
        case .block: tiles[c.x][c.y] = .block
        case .bridge: tiles[c.x][c.y] = .bridge
        case .recycle: return
        }
        drawTile(c)
        // ground below loses its grass when covered
        if c.y > 0, tiles[c.x][c.y - 1] == .ground { drawTile(Cell(x: c.x, y: c.y - 1)) }
        if let node = tileNodes[c] {
            node.setScale(0.2)
            node.run(.sequence([.scale(to: 1.12, duration: 0.12), .scale(to: 1, duration: 0.08)]))
        }
        SoundFX.shared.play(.pop)
        Haptics.tap(nil)
        if !usedTools.contains(t) {
            usedTools.insert(t)
            say(t.lesson)
        }
        refreshGhosts()
    }

    private func remove(at c: Cell) {
        let t = tiles[c.x][c.y]
        let refund: Int
        switch t {
        case .ramp: refund = FortTool.ramp.cost
        case .block: refund = FortTool.block.cost
        case .bridge: refund = FortTool.bridge.cost
        default: return
        }
        tiles[c.x][c.y] = c.y == 1 && level.rows[rows - 1 - c.y].dropFirst(c.x).first == "~" ? .water : .empty
        if let node = tileNodes.removeValue(forKey: c) {
            node.run(.sequence([.group([.scale(to: 0.1, duration: 0.15), .fadeOut(withDuration: 0.15)]), .removeFromParent()]))
        }
        drawTile(c)
        if c.y > 0, tiles[c.x][c.y - 1] == .ground { drawTile(Cell(x: c.x, y: c.y - 1)) }
        hud.bricks += refund
        popAt(c, "+\(refund)")
        SoundFX.shared.play(.coin, volume: 0.6)
        if !usedTools.contains(.recycle) {
            usedTools.insert(.recycle)
            say(FortTool.recycle.lesson)
        }
        refreshGhosts()
    }

    // MARK: Messages

    private func tip(_ key: String, _ text: String) {
        guard !tipsGiven.contains(key) else { return }
        tipsGiven.insert(key)
        say(text)
    }

    private func say(_ text: String) {
        hud.message = text
        Narrator.shared.say(text)
        removeAction(forKey: "msg")
        run(.sequence([.wait(forDuration: 3.2), .run { [weak self] in
            if self?.hud.message == text { self?.hud.message = nil }
        }]), withKey: "msg")
    }
}
