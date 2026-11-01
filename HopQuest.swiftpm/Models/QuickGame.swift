import Foundation

// Quick Game (v5.4): "Star Dash", a one-minute side-scroller. Hold the left half of the screen to run left, hold the
// right half to run right, tap the right half to jump, and tap again in the air to double jump.
// Plain Swift physics (no UIKit), tested in Tests/Learn. Units are points in a world 400 tall; y goes up from the ground.

struct QuickPlatform: Equatable {
    var x: Double
    var y: Double
    var width: Double
    /// Ground pieces are thick and reach the bottom; floating ones are thin ledges.
    var ground: Bool
}

struct QuickStar: Equatable {
    var x: Double
    var y: Double
    var taken = false
}

/// What the child is doing with their fingers this frame.
struct QuickInput: Equatable {
    var left = false
    var right = false
    /// A tap on the right half happened since the last frame.
    var jump = false
}

struct QuickGameState: Equatable {
    static let gravity = -1900.0
    static let jumpSpeed = 700.0
    static let doubleJumpSpeed = 620.0
    static let runSpeed = 230.0
    static let playerWidth = 34.0
    static let playerHeight = 44.0
    static let timeLimit = 60.0

    var platforms: [QuickPlatform]
    var stars: [QuickStar]
    let finishX: Double

    var x = 40.0
    var y = 0.0
    var vx = 0.0
    var vy = 0.0
    var onGround = true
    /// Jumps used since last touching the ground (2 = the double jump is spent).
    var jumpsUsed = 0
    var facingRight = true
    var time = 0.0
    var collected = 0
    var falls = 0
    var finished = false
    /// Where to come back after falling into a gap (the last ground stood on).
    var safeX = 40.0
    var safeY = 0.0
    /// Seconds left of the little balloon ride back after a fall.
    var floatBack = 0.0

    var over: Bool { finished || time >= Self.timeLimit }
    var timeLeft: Double { max(0, Self.timeLimit - time) }
    /// 10 per star, plus 50 for reaching the flag, plus a bonus for time left.
    var score: Int { collected * 10 + (finished ? 50 + Int(timeLeft) : 0) }

    /// A level from a seed: ground with gentle gaps, floating ledges, and stars to reach with jumps and double jumps.
    static func level(seed: UInt64) -> QuickGameState {
        var rng = QuickRandom(seed: seed)
        var platforms: [QuickPlatform] = []
        var stars: [QuickStar] = []
        var x = -200.0
        // a safe start
        platforms.append(QuickPlatform(x: x, y: 0, width: 600, ground: true))
        x += 600
        for i in 0..<14 {
            // a gap a single jump can always clear (max jump distance is about 2 × 700/1900 × 230 ≈ 170)
            let gap = 50 + rng.unit() * 60
            x += gap
            let width = 160 + rng.unit() * 220
            let height = i % 4 == 3 ? 40.0 : 0
            platforms.append(QuickPlatform(x: x, y: height, width: width, ground: true))
            // stars on the ground piece
            stars.append(QuickStar(x: x + width * 0.5, y: height + 30))
            // a ledge above with a star that needs a jump; every other one needs the double jump
            if i % 2 == 0 {
                let ledgeY = height + (i % 4 == 0 ? 110 : 190)
                let lx = x + width * 0.2
                platforms.append(QuickPlatform(x: lx, y: ledgeY, width: 90, ground: false))
                stars.append(QuickStar(x: lx + 45, y: ledgeY + 30))
            } else {
                // a star floating over the gap behind: jump through it
                stars.append(QuickStar(x: x - gap / 2, y: 90 + rng.unit() * 40))
            }
            x += width
        }
        platforms.append(QuickPlatform(x: x + 60, y: 0, width: 400, ground: true))
        return QuickGameState(platforms: platforms, stars: stars, finishX: x + 200)
    }

    /// The highest platform top under the player's feet at `x`, at or below `y` (nil = over a gap).
    func floor(at x: Double, below y: Double) -> Double? {
        let half = Self.playerWidth / 2
        var best: Double?
        for p in platforms where x + half > p.x && x - half < p.x + p.width && p.y <= y + 0.5 {
            if best == nil || p.y > best! { best = p.y }
        }
        return best
    }

    /// Moves the world on by `dt` seconds.
    mutating func step(_ dt: Double, _ input: QuickInput) {
        guard !over else { return }
        let dt = min(dt, 1.0 / 30)
        time += dt

        if floatBack > 0 {
            // floating back in a balloon after a fall: no controls for a moment
            floatBack -= dt
            if floatBack <= 0 { x = safeX; y = safeY; vx = 0; vy = 0; onGround = true; jumpsUsed = 0 }
            return
        }

        // run
        let dir = (input.right ? 1.0 : 0) - (input.left ? 1.0 : 0)
        vx = dir * Self.runSpeed
        if dir != 0 { facingRight = dir > 0 }

        // jump, or double jump in the air
        if input.jump {
            if onGround {
                vy = Self.jumpSpeed; onGround = false; jumpsUsed = 1
            } else if jumpsUsed < 2 {
                vy = Self.doubleJumpSpeed; jumpsUsed = 2
            }
        }

        // move sideways, never off the left edge of the level
        x = max(-150, x + vx * dt)
        if x >= finishX { finished = true }

        // fall, landing on the highest platform under the feet
        let previousY = y
        vy += Self.gravity * dt
        y += vy * dt
        if vy <= 0, let top = floor(at: x, below: previousY), y <= top {
            y = top; vy = 0; onGround = true; jumpsUsed = 0
            safeX = x; safeY = top
        } else if floor(at: x, below: y + 1) == nil || y > (floor(at: x, below: y + 1) ?? y) + 0.5 {
            onGround = false
            // walked off an edge: the first jump in the air still counts as a jump
            if jumpsUsed == 0 && vy < 0 { jumpsUsed = 1 }
        }

        // fell into a gap
        if y < -160 {
            falls += 1
            floatBack = 0.9
            y = -160
        }

        // stars
        for i in stars.indices where !stars[i].taken {
            if abs(stars[i].x - x) < 28 && abs(stars[i].y - (y + Self.playerHeight / 2)) < 34 {
                stars[i].taken = true
                collected += 1
            }
        }
    }
}

/// Small repeatable random numbers, so a level from a seed is always the same.
struct QuickRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

/// Telling a tap from a hold on the right half: a touch shorter than this is a jump.
enum QuickTouch {
    static let tapTime = 0.22
}

/// Star Dash progress: best score, best stars earned (0–3, given once), and the last game for the widget.
struct QuickSave: Codable, Equatable {
    var best = 0
    var bestStars = 0
    var plays = 0
    var last = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent(Int.self, forKey: .best)) ?? 0
        bestStars = (try? c.decodeIfPresent(Int.self, forKey: .bestStars)) ?? 0
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
        last = (try? c.decodeIfPresent(Int.self, forKey: .last)) ?? 0
    }

    /// Stars for a game: 1 for reaching the flag, 1 for 10 stars, 1 for 18 stars.
    static func stars(collected: Int, finished: Bool) -> Int {
        (finished ? 1 : 0) + (collected >= 10 ? 1 : 0) + (collected >= 18 ? 1 : 0)
    }

    /// Records a game. Returns the new collection stars (only for beating your best) and whether it's a new best score.
    mutating func record(score: Int, collected: Int, finished: Bool) -> (earned: Int, newBest: Bool) {
        plays += 1
        last = score
        let newBest = score > best
        if newBest { best = score }
        let s = Self.stars(collected: collected, finished: finished)
        guard s > bestStars else { return (0, newBest) }
        let earned = s - bestStars
        bestStars = s
        return (earned, newBest)
    }
}
