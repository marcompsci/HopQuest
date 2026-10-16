import Foundation

// Code Club's robot language, separated from the screens so it can be tested.
// Blocks: steps (forward, turn left, turn right), Repeat ×N, and in Robot Lab 2 the sensor blocks:
// "Repeat until ⭐" (the robot checks whether it has reached the star) and "If blocked … else …"
// (the robot looks one square ahead for a rock or a wall).

struct RobotCell: Hashable, Codable {
    var x: Int
    var y: Int
}

enum RobotCmd: String, CaseIterable, Codable {
    case forward, left, right
}

/// One block in a robot program. Containers (loops and ifs) hold other blocks.
struct RobotBlock: Identifiable, Equatable {
    enum Kind: Equatable {
        case step(RobotCmd)
        case repeatTimes(Int)
        /// Repeat until the robot is on the star (and has every gear, when the puzzle asks for them).
        case repeatUntilGoal
        /// "If the square ahead is blocked" runs `body`, otherwise `elseBody`.
        case ifBlocked
    }

    let id: UUID
    var kind: Kind
    /// A loop's steps, or what an if does when the way is blocked.
    var body: [RobotBlock] = []
    /// What an if does when the way is clear.
    var elseBody: [RobotBlock] = []

    init(_ kind: Kind, body: [RobotBlock] = [], elseBody: [RobotBlock] = [], id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.body = body
        self.elseBody = elseBody
    }

    static func step(_ c: RobotCmd) -> RobotBlock { RobotBlock(.step(c)) }

    var isContainer: Bool {
        if case .step = kind { return false }
        return true
    }

    var isIf: Bool { kind == .ifBlocked }

    var isLoop: Bool {
        switch kind {
        case .repeatTimes, .repeatUntilGoal: return true
        default: return false
        }
    }

    /// Every block counts as one piece, plus everything inside it.
    var pieces: Int { 1 + body.reduce(0) { $0 + $1.pieces } + elseBody.reduce(0) { $0 + $1.pieces } }
}

extension Array where Element == RobotBlock {
    var pieces: Int { reduce(0) { $0 + $1.pieces } }

    /// Finds a block anywhere in the program.
    func find(_ id: UUID) -> RobotBlock? {
        for b in self {
            if b.id == id { return b }
            if let f = b.body.find(id) ?? b.elseBody.find(id) { return f }
        }
        return nil
    }

    /// Changes a block anywhere in the program. Returns false if it wasn't found.
    @discardableResult
    mutating func update(_ id: UUID, _ change: (inout RobotBlock) -> Void) -> Bool {
        for i in indices {
            if self[i].id == id { change(&self[i]); return true }
            if self[i].body.update(id, change) { return true }
            if self[i].elseBody.update(id, change) { return true }
        }
        return false
    }

    /// Removes a block anywhere in the program.
    @discardableResult
    mutating func remove(_ id: UUID) -> Bool {
        if let i = firstIndex(where: { $0.id == id }) { remove(at: i); return true }
        for i in indices {
            if self[i].body.remove(id) || self[i].elseBody.remove(id) { return true }
        }
        return false
    }

    /// Drops loops and ifs that have nothing inside (they'd do nothing, or loop forever).
    func withoutEmptyContainers() -> [RobotBlock] {
        compactMap { b in
            var b = b
            b.body = b.body.withoutEmptyContainers()
            b.elseBody = b.elseBody.withoutEmptyContainers()
            switch b.kind {
            case .step: return b
            case .repeatTimes, .repeatUntilGoal: return b.body.isEmpty ? nil : b
            case .ifBlocked: return b.body.isEmpty && b.elseBody.isEmpty ? nil : b
            }
        }
    }
}

/// One puzzle board.
struct RobotWorld: Equatable {
    static let size = 6
    var start: RobotCell
    /// 0 up, 1 right, 2 down, 3 left
    var dir: Int
    var goal: RobotCell
    var rocks: Set<RobotCell> = []
    var gears: Set<RobotCell> = []

    static let moves = [(0, -1), (1, 0), (0, 1), (-1, 0)]

    static func ahead(of cell: RobotCell, facing dir: Int) -> RobotCell {
        RobotCell(x: cell.x + moves[dir].0, y: cell.y + moves[dir].1)
    }

    func inside(_ c: RobotCell) -> Bool { (0..<Self.size).contains(c.x) && (0..<Self.size).contains(c.y) }

    /// What the robot's sensor sees: a wall or a rock one square ahead.
    func blocked(from cell: RobotCell, facing dir: Int) -> Bool {
        let next = Self.ahead(of: cell, facing: dir)
        return !inside(next) || rocks.contains(next)
    }
}

/// Everything that happened when a program ran, step by step, for the screen to animate.
struct RobotTrace: Equatable {
    enum Event: Equatable {
        case moved(gear: Bool)
        case turned(RobotCmd)
        /// The sensor looked ahead.
        case sensed(blocked: Bool)
        /// The robot tried to move into a wall or rock.
        case bonked(rock: Bool)
    }

    struct Step: Equatable {
        let event: Event
        /// The block that ran, and the containers around it (outermost first).
        let path: [UUID]
        let robot: RobotCell
        let dir: Int
    }

    enum Outcome: Equatable {
        case reachedGoal
        /// On the star, but some gears are still out there.
        case missingGears
        /// The program ended before the star.
        case stoppedShort
        /// Sensor puzzles: the robot went over the star but didn't stop on it.
        case passedGoal
        case bonkedWall
        case bonkedRock
        /// The robot kept going without getting anywhere.
        case wentInCircles
    }

    var steps: [Step] = []
    var outcome: Outcome = .stoppedShort
    var gears: Set<RobotCell> = []
    var robot: RobotCell
    var dir: Int

    var solved: Bool { outcome == .reachedGoal }
}

enum RobotRunner {
    /// Enough for any real solution on a 6×6 board, small enough to catch endless loops quickly.
    static let stepLimit = 150

    private struct Stop: Error {}

    /// - Parameter stopAtGoal: true (the classic puzzles) ends the run as soon as the robot reaches the star.
    ///   Sensor puzzles pass false: the program has to finish on the star, so the robot must sense it.
    static func run(_ program: [RobotBlock], in world: RobotWorld, needsGears: Bool, stopAtGoal: Bool = true) -> RobotTrace {
        var t = RobotTrace(robot: world.start, dir: world.dir)
        var visitedGoal = false

        func done() -> Bool {
            t.robot == world.goal && (!needsGears || t.gears.count == world.gears.count)
        }

        func record(_ e: RobotTrace.Event, _ path: [UUID]) throws {
            t.steps.append(.init(event: e, path: path, robot: t.robot, dir: t.dir))
            if t.steps.count >= stepLimit {
                t.outcome = .wentInCircles
                throw Stop()
            }
        }

        func exec(_ blocks: [RobotBlock], _ outer: [UUID]) throws {
            for b in blocks {
                if stopAtGoal && done() { return }
                let path = outer + [b.id]
                switch b.kind {
                case .step(let cmd):
                    switch cmd {
                    case .forward:
                        let next = RobotWorld.ahead(of: t.robot, facing: t.dir)
                        if !world.inside(next) {
                            try record(.bonked(rock: false), path)
                            t.outcome = .bonkedWall
                            throw Stop()
                        }
                        if world.rocks.contains(next) {
                            try record(.bonked(rock: true), path)
                            t.outcome = .bonkedRock
                            throw Stop()
                        }
                        t.robot = next
                        if next == world.goal { visitedGoal = true }
                        let gear = world.gears.contains(next) && !t.gears.contains(next)
                        if gear { t.gears.insert(next) }
                        try record(.moved(gear: gear), path)
                    case .left:
                        t.dir = (t.dir + 3) % 4
                        try record(.turned(.left), path)
                    case .right:
                        t.dir = (t.dir + 1) % 4
                        try record(.turned(.right), path)
                    }
                case .repeatTimes(let n):
                    for _ in 0..<max(0, n) {
                        if stopAtGoal && done() { return }
                        try exec(b.body, path)
                    }
                case .repeatUntilGoal:
                    guard !b.body.isEmpty else { continue }
                    while !done() {
                        let before = t.steps.count
                        try exec(b.body, path)
                        // a loop that does nothing at all would spin forever
                        if t.steps.count == before { t.outcome = .wentInCircles; throw Stop() }
                    }
                case .ifBlocked:
                    let blocked = world.blocked(from: t.robot, facing: t.dir)
                    try record(.sensed(blocked: blocked), path)
                    try exec(blocked ? b.body : b.elseBody, path)
                }
            }
        }

        do {
            try exec(program, [])
            if done() {
                t.outcome = .reachedGoal
            } else if t.robot == world.goal {
                t.outcome = .missingGears
            } else {
                t.outcome = visitedGoal && !stopAtGoal ? .passedGoal : .stoppedShort
            }
        } catch {
            // outcome already set (bonk or circles); a classic run can still end exactly on the star
            if stopAtGoal && done() { t.outcome = .reachedGoal }
        }
        return t
    }

    /// Runs one program on every map of a puzzle. Solved only when it works on all of them.
    static func runAll(_ program: [RobotBlock], maps: [RobotWorld], needsGears: Bool, stopAtGoal: Bool = true) -> [RobotTrace] {
        maps.map { run(program, in: $0, needsGears: needsGears, stopAtGoal: stopAtGoal) }
    }
}

// MARK: - Simple machines

/// Gears: each gear that meshes with the next one turns the other way. A small gear driving a big gear
/// turns it slower (but stronger); a big gear driving a small one turns it faster.
struct GearTrain: Equatable {
    /// Teeth on each gear, from the one you crank to the one that does the work.
    var teeth: [Int]

    /// The first gear turns clockwise. Every mesh flips the direction.
    var lastTurnsClockwise: Bool { teeth.count % 2 == 1 }

    /// How many times the last gear turns for one turn of the crank. Middle gears don't change it.
    var turnsPerCrank: Double {
        guard let first = teeth.first, let last = teeth.last, last > 0 else { return 0 }
        return Double(first) / Double(last)
    }
}

/// A lever (a seesaw): a board on a fulcrum (the pivot), with a load at the left end and the push at the right end.
struct Lever: Equatable {
    static let length = 10
    /// Where the fulcrum sits, 1...9 squares from the left end.
    var fulcrum: Int
    var load: Int
    var effort: Int

    /// The push wins when effort × its distance beats load × its distance. Moving the fulcrum near the load helps.
    var lifts: Bool { effort * (Self.length - fulcrum) > load * fulcrum }
    var balanced: Bool { effort * (Self.length - fulcrum) == load * fulcrum }
}

/// Pulleys: each rope holding up the load shares the weight, so you pull with less force, but pull more rope.
struct Pulley: Equatable {
    /// Ropes holding up the load (1 for a single fixed pulley).
    var ropes: Int
    var load: Int

    /// Force needed, rounded up.
    var effort: Int { ropes <= 0 ? load : (load + ropes - 1) / ropes }
    /// Rope you pull to lift the load one step.
    var ropePulled: Int { max(1, ropes) }
}

/// A Machine Workshop puzzle.
struct MachinePuzzle: Identifiable, Equatable {
    enum Kind: Equatable {
        /// Pick the number of gears and the size of the last one.
        case gears(wantClockwise: Bool, wantFaster: Bool, crankTeeth: Int)
        /// Slide the fulcrum so the buddy can lift the load.
        case lever(load: Int, effort: Int)
        /// Choose how many ropes so the buddy can lift the load.
        case pulley(load: Int, strength: Int)
    }

    let id: Int
    let title: String
    let lesson: String
    let kind: Kind
    let funFact: String

    static let all: [MachinePuzzle] = [
        MachinePuzzle(id: 501, title: "Spin the Fan",
                      lesson: "Gears that touch turn opposite ways. Make the fan gear turn clockwise, the same way you crank.",
                      kind: .gears(wantClockwise: true, wantFaster: false, crankTeeth: 20),
                      funFact: "Bikes, clocks and mixers are full of gears."),
        MachinePuzzle(id: 502, title: "Super Fast Fan",
                      lesson: "A big gear turning a small gear makes the small one spin faster! Make the fan turn clockwise and fast.",
                      kind: .gears(wantClockwise: true, wantFaster: true, crankTeeth: 30),
                      funFact: "Bike gears let you pick fast or easy pedaling."),
        MachinePuzzle(id: 503, title: "Seesaw Lift",
                      lesson: "A lever is a seesaw. Move the fulcrum (the triangle) closer to the heavy box so your buddy can lift it.",
                      kind: .lever(load: 3, effort: 1),
                      funFact: "A playground seesaw, a bottle opener and scissors are all levers."),
        MachinePuzzle(id: 504, title: "Elephant Lift",
                      lesson: "This toy elephant weighs 4! Find a fulcrum spot where your buddy wins.",
                      kind: .lever(load: 4, effort: 1),
                      funFact: "Long ago, a thinker named Archimedes said a long enough lever could move the world!"),
        MachinePuzzle(id: 505, title: "Pulley Power",
                      lesson: "Each rope holding the box shares the weight. Your buddy can pull 2. The box weighs 6. How many ropes?",
                      kind: .pulley(load: 6, strength: 2),
                      funFact: "Cranes that build skyscrapers lift heavy beams with pulleys."),
        MachinePuzzle(id: 506, title: "Piano Movers",
                      lesson: "A heavy toy piano weighs 8, and your buddy can pull 2. Use as few ropes as you can, because more ropes means more pulling!",
                      kind: .pulley(load: 8, strength: 2),
                      funFact: "Engineers always balance a trade-off: less force means more rope to pull."),
    ]

    /// Gear sizes kids can pick from.
    static let gearSizes = [10, 20, 30]

    /// Does this setup solve the puzzle? (`choice` is the number of gears, the fulcrum spot, or the number of ropes;
    /// `size` is the last gear's teeth for gear puzzles.)
    func check(choice: Int, size: Int = 20) -> Bool {
        switch kind {
        case .gears(let cw, let faster, let crank):
            guard (2...4).contains(choice), Self.gearSizes.contains(size) else { return false }
            let train = GearTrain(teeth: [crank] + Array(repeating: 20, count: choice - 2) + [size])
            return train.lastTurnsClockwise == cw && (faster ? train.turnsPerCrank > 1 : true)
        case .lever(let load, let effort):
            guard (1...9).contains(choice) else { return false }
            return Lever(fulcrum: choice, load: load, effort: effort).lifts
        case .pulley(let load, let strength):
            guard (1...4).contains(choice) else { return false }
            return Pulley(ropes: choice, load: load).effort <= strength
        }
    }

    /// The best possible answer for a 3-star solve: fewest gears, a fulcrum not jammed against the box, fewest ropes.
    func isBest(choice: Int, size: Int = 20) -> Bool {
        guard check(choice: choice, size: size) else { return false }
        switch kind {
        case .gears: return choice == (1...4).first { n in (2...4).contains(n) && MachinePuzzle.gearSizes.contains { check(choice: n, size: $0) } }
        case .lever: return true
        case .pulley: return choice == (1...4).first { check(choice: $0) }
        }
    }
}

// MARK: - Code Club puzzles

/// A Code Club puzzle: program the robot to reach the star. Sensor puzzles have several maps,
/// and one program has to solve them all, so the robot must look around instead of counting steps.
struct CodeChallenge: Identifiable, Equatable {
    let id: Int
    let title: String
    /// The idea this puzzle teaches, read aloud when it opens.
    let lesson: String
    /// What the card says it teaches.
    let topic: String
    let maps: [RobotWorld]
    /// When true, the robot must pick up every gear before the star counts.
    let needsGears: Bool
    /// Bonus star for solving it with this many blocks or fewer.
    let blockLimit: Int
    /// Shows the sensor blocks: Repeat until ⭐ and If blocked.
    let sensors: Bool

    static let size = RobotWorld.size

    /// Sensor puzzles must finish on the star (no auto-stop), so the robot has to sense it.
    var stopAtGoal: Bool { !sensors }

    func runAll(_ program: [RobotBlock]) -> [RobotTrace] {
        RobotRunner.runAll(program, maps: maps, needsGears: needsGears, stopAtGoal: stopAtGoal)
    }

    private static func c(_ x: Int, _ y: Int) -> RobotCell { RobotCell(x: x, y: y) }

    static let all: [CodeChallenge] = [
        CodeChallenge(id: 401, title: "Loop Launch",
                      lesson: "Meet the Repeat block! It runs the steps inside it again and again. Coders call that a loop. Can you reach the star with just two blocks?",
                      topic: "Loops",
                      maps: [RobotWorld(start: c(0, 5), dir: 0, goal: c(0, 0))],
                      needsGears: false, blockLimit: 2, sensors: false),
        CodeChallenge(id: 402, title: "Corner Turn",
                      lesson: "Use a loop to go up, turn, then another loop to go across. Grab the gears on the way for a bonus star!",
                      topic: "Loops + turns",
                      maps: [RobotWorld(start: c(0, 5), dir: 0, goal: c(4, 1),
                                        rocks: [c(2, 3), c(3, 4)], gears: [c(0, 2), c(3, 1)])],
                      needsGears: false, blockLimit: 5, sensors: false),
        CodeChallenge(id: 403, title: "Staircase",
                      lesson: "See a pattern? Forward, turn left, forward, turn right... and again! Put the whole pattern inside one Repeat block.",
                      topic: "Patterns",
                      maps: [RobotWorld(start: c(0, 5), dir: 1, goal: c(3, 2),
                                        rocks: [c(2, 5), c(0, 3), c(3, 4)], gears: [c(1, 4), c(3, 3)])],
                      needsGears: false, blockLimit: 5, sensors: false),
        CodeChallenge(id: 404, title: "Rock Garden",
                      lesson: "Rocks are in the way! Plan a path around them. Engineers call planning steps an algorithm.",
                      topic: "Planning",
                      maps: [RobotWorld(start: c(0, 2), dir: 1, goal: c(5, 2),
                                        rocks: [c(2, 2), c(3, 2), c(2, 1), c(3, 1)], gears: [c(1, 3), c(4, 3)])],
                      needsGears: false, blockLimit: 10, sensors: false),
        CodeChallenge(id: 405, title: "Square Dance",
                      lesson: "Collect all three gears and come back to the star. Hint: a square has four sides that are all the same!",
                      topic: "Shapes + loops",
                      maps: [RobotWorld(start: c(1, 4), dir: 0, goal: c(1, 4),
                                        rocks: [c(2, 2), c(3, 3)], gears: [c(1, 1), c(4, 1), c(4, 4)])],
                      needsGears: true, blockLimit: 5, sensors: false),

        // Robot Lab 2: sensors
        CodeChallenge(id: 406, title: "Until the Star",
                      lesson: "Your robot has sensors now! The robot must stop right ON the star, and every map is a different distance. Use Repeat until ⭐: the robot keeps going until its sensor says it's there. One program must solve all 3 maps.",
                      topic: "Sensors + loops",
                      maps: [RobotWorld(start: c(1, 5), dir: 0, goal: c(1, 2)),
                             RobotWorld(start: c(3, 5), dir: 0, goal: c(3, 0)),
                             RobotWorld(start: c(5, 5), dir: 0, goal: c(5, 4))],
                      needsGears: false, blockLimit: 2, sensors: true),
        CodeChallenge(id: 407, title: "Corner Sensor",
                      lesson: "Meet If blocked! The robot looks one square ahead. If a wall is there, do one thing. Else, do another. Put an If inside Repeat until ⭐ to turn at every corner.",
                      topic: "If / else",
                      maps: [RobotWorld(start: c(0, 5), dir: 0, goal: c(4, 0)),
                             RobotWorld(start: c(2, 4), dir: 0, goal: c(5, 0)),
                             RobotWorld(start: c(0, 2), dir: 0, goal: c(3, 0))],
                      needsGears: false, blockLimit: 4, sensors: true),
        CodeChallenge(id: 408, title: "Rock Dodger",
                      lesson: "Rocks pop up in different places on every map. When the robot is blocked, which way should it turn? Watch the maps and decide!",
                      topic: "Sensors + decisions",
                      maps: [RobotWorld(start: c(5, 5), dir: 0, goal: c(2, 3), rocks: [c(5, 2), c(1, 0)]),
                             RobotWorld(start: c(4, 5), dir: 0, goal: c(1, 2), rocks: [c(4, 1), c(2, 4)]),
                             RobotWorld(start: c(5, 4), dir: 0, goal: c(2, 0), rocks: [c(3, 3)])],
                      needsGears: false, blockLimit: 4, sensors: true),
        CodeChallenge(id: 409, title: "Smart Maze",
                      lesson: "A whole maze! Can one tiny program find its way through? Grab every gear for a bonus star. Real robot vacuums use sensor rules a lot like yours.",
                      topic: "Algorithms",
                      maps: [RobotWorld(start: c(0, 5), dir: 0, goal: c(3, 3),
                                        rocks: [c(5, 4), c(2, 2), c(1, 4), c(3, 5)], gears: [c(0, 2), c(3, 0), c(5, 2)])],
                      needsGears: false, blockLimit: 4, sensors: true),
    ]
}
