import Foundation

/// Moves the player's buddy: joystick (continuous) or tap-to-move (A* waypoints).
/// Pure logic stepped at a fixed rate by HopVillageScene, so the same inputs always give the same walk.
struct VillagePlayerController {
    let collision: VillageCollision
    let pathfinder: VillagePathfinder

    private(set) var position: VPoint
    private(set) var facing: Facing = .south
    private(set) var waypoints: [VPoint] = []
    /// Distance walked; drives the hop/walk animation so it matches the feet.
    private(set) var stride: Double = 0
    private(set) var isMoving = false
    /// Joystick vector, length 0...1 (tile space, y = south).
    var joystick: VPoint = .zero

    /// Tiles per second at full joystick tilt.
    static let speed = 3.6

    init(map: VillageMap, start: GridPoint, facing: Facing = .south) {
        collision = VillageCollision(map: map)
        pathfinder = VillagePathfinder(map: map)
        let spawn = map.isWalkable(start) ? start : (map.nearestWalkable(to: start) ?? map.spawn)
        position = spawn.center
        self.facing = facing
    }

    var tile: GridPoint { position.tile }
    var hasPath: Bool { !waypoints.isEmpty }

    /// Walk to a tile (or the nearest reachable spot). Returns false if there's no way there.
    @discardableResult
    mutating func walk(to target: GridPoint) -> Bool {
        guard let goal = collision.map.nearestWalkable(to: target),
              let pts = pathfinder.waypoints(from: position, to: goal, collision: collision) else {
            waypoints = []
            return false
        }
        waypoints = pts
        return true
    }

    mutating func stop() {
        waypoints = []
        joystick = .zero
        isMoving = false
    }

    /// Put the buddy somewhere directly (spawning, coming back through a door).
    mutating func place(at p: GridPoint, facing f: Facing) {
        position = p.center
        facing = f
        waypoints = []
    }

    mutating func face(_ f: Facing) { facing = f }

    /// One fixed step. Returns the distance actually moved.
    @discardableResult
    mutating func step(dt: Double) -> Double {
        var velocity = VPoint.zero
        let stick = joystick.length
        if stick > 0.15 {
            // the joystick always wins over a tap path
            waypoints = []
            velocity = joystick.normalized * (Self.speed * min(1, stick))
        } else if let next = waypoints.first {
            let toNext = next - position
            let d = toNext.length
            let stepLen = Self.speed * dt
            if d <= stepLen {
                velocity = toNext * (1 / dt)
                waypoints.removeFirst()
            } else {
                velocity = toNext.normalized * Self.speed
            }
        }

        let before = position
        position = collision.move(position, by: velocity * dt)
        let moved = position.distance(to: before)
        // stuck against something while following a path: give up instead of jittering
        if moved < 1e-4 && stick <= 0.15 && !waypoints.isEmpty && velocity.length > 0 {
            waypoints = []
        }
        isMoving = moved > 1e-4
        if isMoving {
            facing = Facing.from(position - before, current: facing)
            stride += moved
        }
        return moved
    }
}

/// Camera follow math (pure). The scene feeds it world sizes in points.
enum VillageCameraMath {
    /// Keeps the view inside the world; centers the axis if the world is smaller than the view.
    static func clamp(_ target: (x: Double, y: Double), view: (w: Double, h: Double), world: (w: Double, h: Double)) -> (x: Double, y: Double) {
        func axis(_ v: Double, _ viewLen: Double, _ worldLen: Double) -> Double {
            if worldLen <= viewLen { return worldLen / 2 }
            return min(max(v, viewLen / 2), worldLen - viewLen / 2)
        }
        return (axis(target.x, view.w, world.w), axis(target.y, view.h, world.h))
    }

    /// Frame-rate independent smoothing toward the target.
    static func follow(_ current: Double, _ target: Double, dt: Double, sharpness: Double = 7) -> Double {
        current + (target - current) * (1 - exp(-sharpness * dt))
    }
}
