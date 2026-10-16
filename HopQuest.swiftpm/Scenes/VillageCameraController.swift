import SpriteKit

/// Follows the player smoothly and never shows past the map's edge.
final class VillageCameraController {
    let node = SKCameraNode()
    /// A little look-ahead in the walking direction so kids see where they're going.
    var lead = CGVector.zero

    private func clamped(_ target: CGPoint, view: CGSize, world: CGSize) -> CGPoint {
        let c = VillageCameraMath.clamp((x: Double(target.x), y: Double(target.y)),
                                        view: (w: Double(view.width), h: Double(view.height)),
                                        world: (w: Double(world.width), h: Double(world.height)))
        return CGPoint(x: c.x, y: c.y)
    }

    func snap(to target: CGPoint, view: CGSize, world: CGSize) {
        node.position = clamped(target, view: view, world: world)
    }

    func update(target: CGPoint, view: CGSize, world: CGSize, dt: Double) {
        let goal = clamped(CGPoint(x: target.x + lead.dx, y: target.y + lead.dy), view: view, world: world)
        node.position = CGPoint(x: VillageCameraMath.follow(Double(node.position.x), Double(goal.x), dt: dt),
                                y: VillageCameraMath.follow(Double(node.position.y), Double(goal.y), dt: dt))
    }

    /// The part of the world currently on screen (plus a margin), for culling.
    func visibleRect(view: CGSize, margin: CGFloat) -> CGRect {
        CGRect(x: node.position.x - view.width / 2 - margin, y: node.position.y - view.height / 2 - margin,
               width: view.width + margin * 2, height: view.height + margin * 2)
    }
}
