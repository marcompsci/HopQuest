import SpriteKit

/// Little bits of life: butterflies, falling leaves, cloud shadows, fireflies and a soft evening tint,
/// plus footstep dust. Everything is pooled and capped; "light" mode uses far fewer of each.
final class VillageEnvironmentSystem {
    enum Quality { case full, light }

    let quality: Quality
    let isEvening: Bool
    private let world: SKNode
    private let camera: SKCameraNode
    private let worldSize: CGSize
    private var rng = VillageRandom(seed: 2024)

    private struct Flyer { let node: SKSpriteNode; var center: CGPoint; var phase: Double; let speed: Double; let radius: CGFloat }
    private var butterflies: [Flyer] = []
    private var fireflies: [Flyer] = []
    private var clouds: [SKSpriteNode] = []
    private var leaves: [SKSpriteNode] = []
    private var leafTimer = 0.0
    private var dustPool: [SKSpriteNode] = []
    private var dustNext = 0
    private var tint: SKSpriteNode?

    /// Points per tile.
    private let t = VillageArt.tilePt

    init(world: SKNode, camera: SKCameraNode, map: VillageMap, worldSize: CGSize, quality: Quality, eveningLights: Bool, hour: Int) {
        self.world = world
        self.camera = camera
        self.worldSize = worldSize
        self.quality = quality
        isEvening = eveningLights && (hour >= 19 || hour < 6)
        let full = quality == .full

        // butterflies over flower patches (daytime)
        if !isEvening {
            let flowerTiles = (0..<map.height).flatMap { r in (0..<map.width).compactMap { c in map.char(c, r) == "*" ? GridPoint(c, r) : nil } }
            let colors = ["pink", "gold", "blue"]
            let count = full ? 8 : 3
            for i in 0..<count where !flowerTiles.isEmpty {
                let home = flowerTiles[(i * 37 + 11) % flowerTiles.count]
                let frames = VillageArt.frames("fly_\(colors[i % 3])", count: 2)
                let node = SKSpriteNode(texture: frames.first)
                node.size = CGSize(width: 8 * VillageArt.scale, height: 7 * VillageArt.scale)
                node.zPosition = 950
                if frames.count == 2 { node.run(.repeatForever(.animate(with: frames, timePerFrame: 0.12 + Double(i % 3) * 0.02))) }
                world.addChild(node)
                butterflies.append(Flyer(node: node, center: CGPoint(x: (CGFloat(home.c) + 0.5) * t, y: (CGFloat(map.height - home.r) - 0.5) * t + 30),
                                         phase: Double(i) * 1.3, speed: 0.6 + Double(i % 4) * 0.12, radius: 40 + CGFloat(i % 3) * 18))
            }
        }

        // drifting cloud shadows (daytime)
        if !isEvening {
            for i in 0..<(full ? 3 : 1) {
                let cloud = VillageArt.propNode("cloud")
                cloud.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                cloud.setScale(2.2)
                cloud.position = CGPoint(x: CGFloat(i) * worldSize.width / 3, y: CGFloat(i * 2 + 1) * worldSize.height / 6)
                cloud.zPosition = 940
                world.addChild(cloud)
                clouds.append(cloud)
            }
        }

        // fireflies and a soft night tint (evening)
        if isEvening {
            for i in 0..<(full ? 16 : 6) {
                let node = VillageArt.propNode("firefly")
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                node.blendMode = .add
                node.zPosition = 960
                node.run(.repeatForever(.sequence([.fadeAlpha(to: 0.15, duration: 0.6 + Double(i % 5) * 0.2),
                                                   .fadeAlpha(to: 1, duration: 0.5 + Double(i % 3) * 0.2)])))
                world.addChild(node)
                let cx = CGFloat(4 + (i * 7) % 32) * t
                let cy = worldSize.height - CGFloat(36 + (i * 5) % 10) * t + (i % 2 == 0 ? 0 : 20 * t)
                fireflies.append(Flyer(node: node, center: CGPoint(x: cx, y: cy), phase: Double(i), speed: 0.35, radius: 70))
            }
            let tint = SKSpriteNode(color: UIColor(hex: 0x1B2450), size: CGSize(width: 4000, height: 4000))
            tint.alpha = 0.26
            tint.zPosition = 930
            camera.addChild(tint)
            self.tint = tint
        }

        // dust puffs for footsteps
        for _ in 0..<(full ? 8 : 4) {
            let d = VillageArt.propNode("dust0")
            d.anchorPoint = CGPoint(x: 0.5, y: 0)
            d.isHidden = true
            world.addChild(d)
            dustPool.append(d)
        }
    }

    func update(dt: Double, visible: CGRect) {
        for i in butterflies.indices {
            butterflies[i].phase += dt * butterflies[i].speed
            let p = butterflies[i].phase
            let b = butterflies[i]
            let x = b.center.x + CGFloat(sin(p * 1.3)) * b.radius
            let y = b.center.y + CGFloat(sin(p * 2.1)) * b.radius * 0.5 + CGFloat(sin(p * 7)) * 3
            b.node.position = CGPoint(x: x, y: y)
            b.node.xScale = cos(p * 1.3) >= 0 ? 1 : -1
            b.node.isHidden = !visible.contains(b.node.position)
        }
        for i in fireflies.indices {
            fireflies[i].phase += dt * fireflies[i].speed
            let f = fireflies[i]
            f.node.position = CGPoint(x: f.center.x + CGFloat(sin(f.phase * 1.7)) * f.radius,
                                      y: f.center.y + CGFloat(cos(f.phase * 1.1)) * f.radius * 0.6)
            f.node.isHidden = !visible.contains(f.node.position)
        }
        for cloud in clouds {
            cloud.position.x += CGFloat(dt) * 14
            if cloud.position.x > worldSize.width + 200 { cloud.position.x = -200 }
        }
        updateLeaves(dt: dt, visible: visible)
    }

    private func updateLeaves(dt: Double, visible: CGRect) {
        guard !isEvening else { return }
        leafTimer -= dt
        let maxLeaves = quality == .full ? 10 : 3
        if leafTimer <= 0 {
            leafTimer = quality == .full ? 0.7 : 2.2
            let leaf: SKSpriteNode
            if leaves.count < maxLeaves {
                leaf = VillageArt.propNode("leaf\(leaves.count % 2)")
                leaf.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                leaf.zPosition = 945
                world.addChild(leaf)
                leaves.append(leaf)
            } else if let free = leaves.first(where: { !$0.hasActions() }) {
                leaf = free
            } else {
                return
            }
            leaf.removeAllActions()
            leaf.alpha = 1
            leaf.isHidden = false
            leaf.position = CGPoint(x: visible.minX + CGFloat(rng.unit()) * visible.width,
                                    y: visible.maxY - CGFloat(rng.unit()) * visible.height * 0.3)
            let fall = visible.height * 0.6
            let sway = SKAction.sequence([.moveBy(x: 26, y: 0, duration: 0.9), .moveBy(x: -26, y: 0, duration: 0.9)])
            sway.timingMode = .easeInEaseOut
            leaf.run(.sequence([
                .group([.moveBy(x: 0, y: -fall, duration: 5),
                        .repeat(sway, count: 3),
                        .rotate(byAngle: .pi * 2, duration: 5),
                        .sequence([.wait(forDuration: 4), .fadeOut(withDuration: 1)])]),
                .hide()
            ]))
        }
    }

    /// A puff of dust where a hop lands.
    func dust(at p: CGPoint, z: CGFloat) {
        guard !dustPool.isEmpty else { return }
        let d = dustPool[dustNext % dustPool.count]
        dustNext += 1
        d.removeAllActions()
        d.position = p
        d.zPosition = z - 1
        d.isHidden = false
        d.alpha = 1
        let frames = VillageArt.frames("dust", count: 3)
        d.run(.sequence([.animate(with: frames, timePerFrame: 0.08), .hide()]))
    }

    /// A sparkle where the child tapped (shows where the buddy is heading).
    func tapMarker(at p: CGPoint) {
        let s = VillageArt.propNode("sparkle")
        s.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        s.position = p
        s.zPosition = 5
        s.setScale(0.5)
        world.addChild(s)
        s.run(.sequence([.group([.scale(to: 1.3, duration: 0.35), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
    }
}
