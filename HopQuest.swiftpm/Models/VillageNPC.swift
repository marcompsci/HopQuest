import Foundation

/// What a buddy can teach. Mapped to the Brain Gate subjects in the SwiftUI layer.
enum NPCLesson: String, Codable {
    case math, road, nature, science, words, coding, kindness
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
                      home: GridPoint(30, 23), wanderRadius: 3, activitySpot: GridPoint(35, 21), activity: "crossing-guard practice",
                      greeting: "Woof! I'm the crossing helper at the Driving Academy. Can you answer a road-safety question?",
                      chatter: ["At a crosswalk I stop, look left, look right, and look left again.",
                                "Grown-ups hold hands with little ones near busy roads. Teamwork!"],
                      lesson: .road,
                      askLine: "Paws ready? Here it comes!",
                      thanksLine: "Great job, safe walker! A star for you!",
                      seed: 23),
        VillageNPCDef(id: "acorn", characterID: "acorn", fallbackID: "rocky",
                      home: GridPoint(11, 21), wanderRadius: 2, activitySpot: GridPoint(12, 18), activity: "stacking blocks",
                      greeting: "Hi! I'm counting gears for the Robot Lab. Want to help me with a number puzzle?",
                      chatter: ["Robots need batteries, motors, and a brain to follow their code.",
                                "Engineers try, test, and try again. Mistakes help us learn!"],
                      lesson: .math,
                      askLine: "Okay, math helper, here's my puzzle!",
                      thanksLine: "Nutty-good counting! Here's a star!",
                      seed: 37),
        VillageNPCDef(id: "pip", characterID: "pip", fallbackID: "coral",
                      home: GridPoint(24, 43), wanderRadius: 4, activitySpot: GridPoint(28, 46), activity: "watching the pond",
                      greeting: "Hello! I love watching the frogs by the pond. Want a nature riddle?",
                      chatter: ["The lily pads float because they're full of tiny air pockets. Try hopping on them!",
                                "The cottage, the boathouse and the tower in this forest are your hop adventures!"],
                      lesson: .nature,
                      askLine: "Let's see what you know about nature!",
                      thanksLine: "Splash-tastic! A star for you!",
                      seed: 41),
        VillageNPCDef(id: "stella", characterID: "stella", fallbackID: "gigi",
                      home: GridPoint(10, 11), wanderRadius: 3, activitySpot: GridPoint(4, 10), activity: "reading",
                      greeting: "Hi there! I look after the Sticker Book Museum. Do you like word games?",
                      chatter: ["Every buddy you collect gets a spot in the Sticker Book. Can you find all 29?",
                                "Reading a little every day makes your brain extra strong!"],
                      lesson: .words,
                      askLine: "Here's a word puzzle!",
                      thanksLine: "Berry nice! You earned a star!",
                      seed: 53),
    ]

    static let newFriends: [VillageNPCDef] = [
        VillageNPCDef(id: "ocho", characterID: "ocho", fallbackID: "comet",
                      home: GridPoint(14, 27), wanderRadius: 2, activitySpot: GridPoint(16, 24), activity: "debugging",
                      greeting: "Hi! I'm Ocho, the Coding Lab teacher. Eight arms, eight keyboards! Want a coding riddle?",
                      chatter: ["In the Coding Lab you can build a web page, write Python, and make your own game!",
                                "A bug is a mistake in code. Finding bugs is like being a detective!"],
                      lesson: .coding, askLine: "Here's a coding riddle!", thanksLine: "You think like a programmer! Here's a star!", seed: 61),
        VillageNPCDef(id: "kip", characterID: "kip", fallbackID: "ellie",
                      home: GridPoint(30, 10), wanderRadius: 3, activitySpot: GridPoint(28, 11), activity: "hugging trees",
                      greeting: "G'day! I'm Kip. I love helping friends feel good. Want a kindness question?",
                      chatter: ["Koalas sleep up to 20 hours a day. I'm only awake to be kind!",
                                "When a friend is sad, sometimes just sitting with them helps a lot."],
                      lesson: .kindness, askLine: "Here's a kindness question!", thanksLine: "That's the kind answer! Here's a star!", seed: 67),
        VillageNPCDef(id: "fizz", characterID: "fizz", fallbackID: "coral",
                      home: GridPoint(17, 43), wanderRadius: 3, activitySpot: GridPoint(21, 43), activity: "catching bugs",
                      greeting: "Ribbit! I'm Fizz. Want a nature riddle from the pond?",
                      chatter: ["Frogs drink water through their skin! No cups needed.",
                                "Try hopping across the lily pads with the Hop button!"],
                      lesson: .nature, askLine: "Ribbit, riddle time!", thanksLine: "Ribbit-rific! Here's a star!", seed: 71),
        VillageNPCDef(id: "flora", characterID: "flora", fallbackID: "starspark",
                      home: GridPoint(13, 10), wanderRadius: 3, activitySpot: GridPoint(16, 9), activity: "smelling flowers",
                      greeting: "Hello, darling! I'm Flora. Do you like science questions?",
                      chatter: ["Flamingos are pink because of the tiny shrimp they eat!",
                                "Sunflowers turn to face the sun when they're young."],
                      lesson: .science, askLine: "Here's a science question!", thanksLine: "Brilliant! Here's a star!", seed: 73),
        VillageNPCDef(id: "polly", characterID: "polly", fallbackID: "zara",
                      home: GridPoint(27, 14), wanderRadius: 3, activitySpot: GridPoint(29, 15), activity: "counting bamboo",
                      greeting: "Hi! I'm Polly. I love numbers and shapes. Want a math puzzle?",
                      chatter: ["A square has 4 sides that are all the same length.",
                                "Pandas eat bamboo for about 12 hours a day. That's a lot of counting!"],
                      lesson: .math, askLine: "Math puzzle time!", thanksLine: "You're a math whiz! Here's a star!", seed: 79),
        VillageNPCDef(id: "buzzy", characterID: "buzzy", fallbackID: "sunny",
                      home: GridPoint(17, 11), wanderRadius: 3, activitySpot: GridPoint(20, 10), activity: "buzzing around",
                      greeting: "Bzz! I'm Buzzy, the village mail carrier. Want a word puzzle?",
                      chatter: ["Bees dance to tell their friends where the best flowers are!",
                                "Every letter needs an address so it gets to the right home."],
                      lesson: .words, askLine: "Bzz, word puzzle!", thanksLine: "Bee-autiful! Here's a star!", seed: 83),
    ]

    static func def(_ id: String) -> VillageNPCDef? { (all + newFriends).first { $0.id == id } }

    /// Everyone who lives in the village.
    static var everyone: [VillageNPCDef] { all + newFriends }

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

// MARK: - Pop-quiz buddy

enum CourierEvent: Equatable {
    /// Walked up to the player: time to ask a follow-up question.
    case arrived
}

/// A CPU buddy who walks up to the player after every two minutes of village play and asks a
/// follow-up question about a game they've played, for bonus stars. Deterministic for a seed.
struct QuizCourier {
    enum Phase: Equatable { case waiting, approaching, asking, leaving }

    static let interval = 120.0
    static let speed = 2.6
    static let characterID = "novawing"
    static let fallbackID = "starspark"

    private(set) var phase: Phase = .waiting
    private(set) var position = VPoint(0, 0)
    private(set) var facing: Facing = .south
    private(set) var isMoving = false
    private(set) var stride: Double = 0
    /// Seconds of active village play since the last visit.
    private(set) var clock: Double = 0
    private var path: [VPoint] = []
    private var phaseTime: Double = 0
    private var aimTimer: Double = 0
    private var rng: VillageRandom

    init(seed: UInt64 = 99) { rng = VillageRandom(seed: seed) }

    var isVisible: Bool { phase != .waiting }

    /// `active` is false while a dialogue, quiz or game screen is open, so the timer only counts real exploring.
    mutating func step(dt: Double, active: Bool, player: VPoint, collision: VillageCollision, pathfinder: VillagePathfinder) -> CourierEvent? {
        isMoving = false
        phaseTime += dt
        switch phase {
        case .waiting:
            guard active else { return nil }
            clock += dt
            if clock >= Self.interval { spawn(near: player, collision: collision, pathfinder: pathfinder) }
            return nil

        case .approaching:
            if position.distance(to: player) <= 1.4 {
                phase = .asking
                phaseTime = 0
                path = []
                facing = Facing.from(player - position, current: facing)
                return .arrived
            }
            // the player walked off: re-aim every couple of seconds; give up after 40 s
            if phaseTime > 40 { finish(collision: collision, pathfinder: pathfinder); return nil }
            aimTimer -= dt
            if path.isEmpty || aimTimer <= 0 {
                aim(at: player.tile, collision: collision, pathfinder: pathfinder)
                aimTimer = 1.5
            }
            walk(dt: dt, collision: collision)
            return nil

        case .asking:
            facing = Facing.from(player - position, current: facing)
            return nil

        case .leaving:
            walk(dt: dt, collision: collision)
            if path.isEmpty || phaseTime > 20 {
                phase = .waiting
                clock = 0
                phaseTime = 0
            }
            return nil
        }
    }

    /// The question is answered (or skipped): wave goodbye and walk away.
    mutating func finish(collision: VillageCollision, pathfinder: VillagePathfinder) {
        phase = .leaving
        phaseTime = 0
        let away = ringTile(around: position.tile, radius: 9, collision: collision)
        if let away, let pts = pathfinder.waypoints(from: position, to: away, collision: collision) {
            path = pts
        } else {
            path = []
        }
    }

    /// Skip the wait (used by tests and the "ask me now" debug path).
    mutating func forceSoon() { clock = Self.interval }

    private mutating func spawn(near player: VPoint, collision: VillageCollision, pathfinder: VillagePathfinder) {
        for radius in [7, 6, 8, 5, 9, 4] {
            guard let start = ringTile(around: player.tile, radius: radius, collision: collision) else { continue }
            if let pts = pathfinder.waypoints(from: start.center, to: player.tile, collision: collision), !pts.isEmpty {
                position = start.center
                path = pts
                phase = .approaching
                phaseTime = 0
                return
            }
        }
        clock = Self.interval - 10      // nowhere to come from right now; try again soon
    }

    private mutating func aim(at tile: GridPoint, collision: VillageCollision, pathfinder: VillagePathfinder) {
        if let pts = pathfinder.waypoints(from: position, to: tile, collision: collision), !pts.isEmpty { path = pts }
    }

    private mutating func ringTile(around p: GridPoint, radius: Int, collision: VillageCollision) -> GridPoint? {
        var options: [GridPoint] = []
        for dr in -radius...radius {
            for dc in -radius...radius where max(abs(dc), abs(dr)) == radius {
                let q = p.offset(dc, dr)
                if collision.map.isWalkable(q) { options.append(q) }
            }
        }
        guard !options.isEmpty else { return nil }
        return options[rng.int(0...(options.count - 1))]
    }

    private mutating func walk(dt: Double, collision: VillageCollision) {
        guard let next = path.first else { return }
        let toNext = next - position
        let stepLen = Self.speed * dt
        let move = toNext.length <= stepLen ? toNext : toNext.normalized * stepLen
        if toNext.length <= stepLen { path.removeFirst() }
        let before = position
        position = collision.move(position, by: move)
        let moved = position.distance(to: before)
        if moved > 1e-4 {
            isMoving = true
            stride += moved
            facing = Facing.from(move, current: facing)
        } else {
            path = []
        }
    }
}
