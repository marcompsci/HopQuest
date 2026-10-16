import Foundation

/// What a buddy can teach. Mapped to the Brain Gate subjects in the SwiftUI layer.
enum NPCLesson: String, Codable {
    case math, road, nature, science, words
}

/// A buddy who lives in Hop Village. All dialogue is written here: no AI chat, no network, no free text.
struct VillageNPCDef: Equatable {
    let id: String
    /// The buddy who plays this role, and who steps in if the child is playing as that buddy.
    let characterID: String
    let fallbackID: String
    let home: GridPoint
    let wanderRadius: Int
    let activitySpot: GridPoint
    /// What they're doing at their activity spot ("stargazing").
    let activity: String
    let greeting: String
    /// Said after the riddle is solved, and on later visits.
    let chatter: [String]
    let lesson: NPCLesson?
    let askLine: String
    let thanksLine: String
    /// Seed for their wandering, so they behave the same way every time.
    let seed: UInt64

    static let all: [VillageNPCDef] = [
        VillageNPCDef(id: "ollie", characterID: "ollie", fallbackID: "gemma",
                      home: GridPoint(13, 14), wanderRadius: 3, activitySpot: GridPoint(12, 10), activity: "stargazing",
                      greeting: "Hello, explorer! Want to solve a mystery about the stars?",
                      chatter: ["At night I look up from the castle garden. There are so many stars that nobody has ever counted them all!",
                                "Our Sun is a star too. It looks big because it's the closest one to us."],
                      lesson: .science,
                      askLine: "Here's my mystery. Ready?",
                      thanksLine: "Hoo-ray! You're a real star scientist. Here's a star for your collection!",
                      seed: 11),
        VillageNPCDef(id: "pixelpup", characterID: "pixelpup", fallbackID: "pip",
                      home: GridPoint(30, 23), wanderRadius: 3, activitySpot: GridPoint(33, 22), activity: "crossing-guard practice",
                      greeting: "Woof! I'm the crossing helper at the Driving Academy. Can you answer a road-safety question?",
                      chatter: ["At a crosswalk I stop, look left, look right, and look left again.",
                                "Grown-ups hold hands with little ones near busy roads. Teamwork!"],
                      lesson: .road,
                      askLine: "Paws ready? Here it comes!",
                      thanksLine: "Great job, safe walker! A star for you!",
                      seed: 23),
        VillageNPCDef(id: "acorn", characterID: "acorn", fallbackID: "rocky",
                      home: GridPoint(11, 22), wanderRadius: 3, activitySpot: GridPoint(11, 18), activity: "stacking blocks",
                      greeting: "Hi! I'm counting gears for the Robot Workshop. Want to help me with a number puzzle?",
                      chatter: ["Robots need batteries, motors, and a brain to follow their code.",
                                "Engineers try, test, and try again. Mistakes help us learn!"],
                      lesson: .math,
                      askLine: "Okay, math helper, here's my puzzle!",
                      thanksLine: "Nutty-good counting! Here's a star!",
                      seed: 37),
        VillageNPCDef(id: "pip", characterID: "pip", fallbackID: "coral",
                      home: GridPoint(23, 37), wanderRadius: 4, activitySpot: GridPoint(17, 37), activity: "watching the pond",
                      greeting: "Hello! I love watching the frogs by the pond. Want a nature riddle?",
                      chatter: ["The lily pads float because they're full of tiny air pockets. Try hopping on them!",
                                "The portals in this forest lead to your hop adventures. Some are still asleep."],
                      lesson: .nature,
                      askLine: "Let's see what you know about nature!",
                      thanksLine: "Splash-tastic! A star for you!",
                      seed: 41),
        VillageNPCDef(id: "stella", characterID: "stella", fallbackID: "gigi",
                      home: GridPoint(10, 11), wanderRadius: 3, activitySpot: GridPoint(4, 10), activity: "reading",
                      greeting: "Hi there! I look after the Sticker Book Museum. Do you like word games?",
                      chatter: ["Every buddy you collect gets a spot in the Sticker Book. Can you find all 23?",
                                "Reading a little every day makes your brain extra strong!"],
                      lesson: .words,
                      askLine: "Here's a word puzzle!",
                      thanksLine: "Berry nice! You earned a star!",
                      seed: 53),
    ]

    static func def(_ id: String) -> VillageNPCDef? { all.first { $0.id == id } }

    /// The buddy who actually appears (never the same buddy the child is playing).
    func characterID(avoiding player: String) -> String {
        player == characterID ? fallbackID : characterID
    }
}

enum NPCMode: String, Equatable {
    case idle, wander, approach, talk, activity, returnHome
}

enum NPCEvent: Equatable {
    /// The buddy walked over and said hi.
    case greet
}

/// A buddy's behavior as a small state machine:
/// Idle → Wander (near home) → Approach (greets a nearby player once) → Talk (when the child talks to them)
/// → Perform activity (on a schedule) → Return home. Deterministic for the same seed and inputs.
struct NPCBrain {
    let def: VillageNPCDef
    private(set) var mode: NPCMode = .idle
    private(set) var position: VPoint
    private(set) var facing: Facing = .south
    private(set) var path: [VPoint] = []
    private(set) var isMoving = false
    private(set) var stride: Double = 0
    /// True while doing their activity at the activity spot (plays the celebrate animation).
    private(set) var isPerforming = false
    private(set) var greeted = false

    private var timer: Double = 1.5
    private var clock: Double = 0
    private var nextActivityAt: Double
    private var greetCooldown: Double = 0
    private var rng: VillageRandom

    static let speed = 2.0
    static let greetDistance = 3.0

    init(def: VillageNPCDef, map: VillageMap) {
        self.def = def
        let start = map.isWalkable(def.home) ? def.home : (map.nearestWalkable(to: def.home) ?? map.spawn)
        position = start.center
        rng = VillageRandom(seed: def.seed)
        nextActivityAt = 20 + Double(def.seed % 17)
    }

    var tile: GridPoint { position.tile }

    mutating func beginTalk(player: VPoint) {
        mode = .talk
        path = []
        isMoving = false
        isPerforming = false
        greeted = true
        facing = Facing.from(player - position, current: facing)
    }

    mutating func endTalk() {
        guard mode == .talk else { return }
        mode = .idle
        timer = 2.5
        greetCooldown = 30
    }

    /// One fixed step. Returns an event when something worth showing happens.
    mutating func step(dt: Double, player: VPoint, collision: VillageCollision, pathfinder: VillagePathfinder) -> NPCEvent? {
        clock += dt
        greetCooldown = max(0, greetCooldown - dt)
        let toPlayer = position.distance(to: player)
        if toPlayer > 8 && greetCooldown == 0 { greeted = false }
        isMoving = false

        switch mode {
        case .talk:
            facing = Facing.from(player - position, current: facing)
            return nil

        case .idle:
            timer -= dt
            if !greeted && greetCooldown == 0 && toPlayer < Self.greetDistance && toPlayer > 1.3 {
                if go(toward: player.tile, collision: collision, pathfinder: pathfinder) { mode = .approach }
                else { greeted = true }
                return nil
            }
            if clock >= nextActivityAt {
                if go(toward: def.activitySpot, collision: collision, pathfinder: pathfinder) {
                    mode = .activity
                    isPerforming = false
                } else {
                    nextActivityAt = clock + 40
                }
                return nil
            }
            if timer <= 0 { pickWander(collision: collision, pathfinder: pathfinder) }
            return nil

        case .activity:
            if isPerforming {
                timer -= dt
                if timer <= 0 {
                    isPerforming = false
                    nextActivityAt = clock + 35 + Double(rng.int(0...15))
                    if go(toward: def.home, collision: collision, pathfinder: pathfinder) { mode = .returnHome }
                    else { mode = .idle; timer = 2 }
                }
                return nil
            }
            if follow(dt: dt, player: player, collision: collision) {
                isPerforming = true
                facing = .south
                timer = 6
            }
            return nil

        case .approach:
            if toPlayer <= 1.4 {
                path = []
                greeted = true
                greetCooldown = 30
                facing = Facing.from(player - position, current: facing)
                mode = .idle
                timer = 3
                return .greet
            }
            if follow(dt: dt, player: player, collision: collision) {
                // got where the player was; they moved on, so let it go
                greeted = true
                mode = .idle
                timer = 2
            }
            return nil

        case .wander:
            if position.distance(to: def.home.center) > Double(def.wanderRadius) + 1.5 {
                if go(toward: def.home, collision: collision, pathfinder: pathfinder) { mode = .returnHome }
                return nil
            }
            if follow(dt: dt, player: player, collision: collision) {
                mode = .idle
                timer = 1.5 + rng.unit() * 3
            }
            return nil

        case .returnHome:
            if follow(dt: dt, player: player, collision: collision) {
                mode = .idle
                timer = 1 + rng.unit() * 2
            }
            return nil
        }
    }

    // MARK: Helpers

    private mutating func pickWander(collision: VillageCollision, pathfinder: VillagePathfinder) {
        let map = collision.map
        for _ in 0..<8 {
            let target = def.home.offset(rng.int(-def.wanderRadius...def.wanderRadius), rng.int(-def.wanderRadius...def.wanderRadius))
            guard map.isWalkable(target), target != tile else { continue }
            if go(toward: target, collision: collision, pathfinder: pathfinder) {
                mode = .wander
                return
            }
        }
        timer = 2
    }

    private mutating func go(toward target: GridPoint, collision: VillageCollision, pathfinder: VillagePathfinder) -> Bool {
        guard let goal = collision.map.nearestWalkable(to: target, maxRadius: 2),
              let pts = pathfinder.waypoints(from: position, to: goal, collision: collision), !pts.isEmpty else { return false }
        path = pts
        return true
    }

    /// Walks along the path. Returns true when the path is finished.
    private mutating func follow(dt: Double, player: VPoint, collision: VillageCollision) -> Bool {
        guard let next = path.first else { return true }
        // politely wait if the player is right in the way
        if position.distance(to: player) < 0.85 && (next - position).length > 0.2 {
            facing = Facing.from(player - position, current: facing)
            return false
        }
        let toNext = next - position
        let stepLen = Self.speed * dt
        let move: VPoint
        if toNext.length <= stepLen {
            move = toNext
            path.removeFirst()
        } else {
            move = toNext.normalized * stepLen
        }
        let before = position
        position = collision.move(position, by: move)
        let moved = position.distance(to: before)
        if moved > 1e-4 {
            isMoving = true
            stride += moved
            facing = Facing.from(move, current: facing)
        } else if !path.isEmpty {
            path = []      // blocked: stop rather than jitter
        }
        return path.isEmpty
    }
}
