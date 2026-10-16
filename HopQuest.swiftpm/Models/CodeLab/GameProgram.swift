import Foundation

/// Runs a Game Maker project. The child's Python sets up the game (background, hero, stars, speed, bubbles) and
/// handles events (on_tap, on_star, on_bump, on_score). The stage asks this object what to draw and calls the
/// events while the game plays.
final class GameProgram {
    struct Setup: Equatable {
        var background: String?
        var hero: String?
        var stars = 0
        var bubbles = 0
        /// 1 (slow) to 10 (zoom). 3 is the classic pace.
        var speed = 3
    }

    enum Effect: Equatable {
        case jump(Int)
        case say(String)
        /// Changes made while the game is playing (for example a level-up inside on_score).
        case background(String)
        case speed(Int)
    }

    static let worlds = ["meadow", "night", "ocean", "candy"]
    static let maxStars = 12
    static let maxBubbles = 5
    static let speeds = 1...10

    /// How many points a second things slide past at a given speed setting.
    static func pointsPerSecond(_ speed: Int) -> Double { 60 + Double(min(max(speed, 1), 10)) * 30 }

    let py = MiniPython()
    private(set) var setup = Setup()
    private var effects: [Effect] = []
    /// False while the setup code runs, true once the game is playing.
    private(set) var playing = false

    init(validHeroes: Set<String>) {
        py.host["set_background"] = { [weak self] args in
            guard case .str(let w)? = args.first, args.count == 1, Self.worlds.contains(w) else {
                throw PyError(line: 0, message: "set_background() takes one world: \(Self.worlds.map { "\"\($0)\"" }.joined(separator: ", ")).")
            }
            guard let self else { return .none }
            if self.playing, self.setup.background != w { self.effects.append(.background(w)) }
            self.setup.background = w
            return .none
        }
        py.host["set_speed"] = { [weak self] args in
            guard case .int(let n)? = args.first, args.count == 1 else {
                throw PyError(line: 0, message: "set_speed() needs a number from 1 to 10, like set_speed(5).")
            }
            guard Self.speeds.contains(n) else { throw PyError(line: 0, message: "set_speed() goes from 1 (slow) to 10 (zoom!). Try a number in between.") }
            guard let self else { return .none }
            if self.playing, self.setup.speed != n { self.effects.append(.speed(n)) }
            self.setup.speed = n
            return .none
        }
        py.host["add_player"] = { [weak self] args in
            guard case .str(let h)? = args.first, args.count == 1, validHeroes.contains(h) else {
                throw PyError(line: 0, message: "add_player() needs a buddy's name, like \"lavender\".")
            }
            self?.setup.hero = h
            return .none
        }
        py.host["add_star"] = { [weak self] args in
            guard args.isEmpty else { throw PyError(line: 0, message: "add_star() doesn't need anything inside the ( ).") }
            guard let self else { return .none }
            guard !self.playing else { throw PyError(line: 0, message: "Add stars at the start of your game, not inside an event.") }
            guard self.setup.stars < Self.maxStars else { throw PyError(line: 0, message: "That's a lot of stars! Try \(Self.maxStars) or fewer.") }
            self.setup.stars += 1
            return .none
        }
        py.host["add_bubble"] = { [weak self] args in
            guard args.isEmpty else { throw PyError(line: 0, message: "add_bubble() doesn't need anything inside the ( ).") }
            guard let self else { return .none }
            guard !self.playing else { throw PyError(line: 0, message: "Add bubbles at the start of your game, not inside an event.") }
            guard self.setup.bubbles < Self.maxBubbles else { throw PyError(line: 0, message: "Too many bubbles to dodge! Try \(Self.maxBubbles) or fewer.") }
            self.setup.bubbles += 1
            return .none
        }
        py.host["jump"] = { [weak self] args in
            guard case .int(let h)? = args.first, args.count == 1 else { throw PyError(line: 0, message: "jump() needs a number, like jump(100).") }
            self?.effects.append(.jump(min(max(h, 20), 300)))
            return .none
        }
        py.host["say"] = { [weak self] args in
            guard args.count == 1 else { throw PyError(line: 0, message: "say() needs one message.") }
            self?.effects.append(.say(String(args[0].description.prefix(60))))
            return .none
        }
    }

    /// Runs the setup code (everything not inside an event).
    func load(_ source: String) throws {
        playing = false
        try py.run(source)
        playing = true
    }

    var hasTapEvent: Bool { py.hasFunction("on_tap") }
    var hasStarEvent: Bool { py.hasFunction("on_star") }
    var hasBumpEvent: Bool { py.hasFunction("on_bump") }
    var hasScoreEvent: Bool { py.hasFunction("on_score") }

    func tap() throws { try py.call("on_tap") }

    /// A star was caught: on_star runs, then on_score if the score changed.
    func starCollected() throws {
        let before = score
        try py.call("on_star")
        if score != before { try scoreChanged() }
    }

    /// The hero bumped a bubble: on_bump runs, then on_score if the score changed.
    func bumped() throws {
        let before = score
        try py.call("on_bump")
        if score != before { try scoreChanged() }
    }

    private func scoreChanged() throws {
        if hasScoreEvent { try py.call("on_score") }
    }

    /// The game's score variable, if the program has one.
    var score: Int? {
        if case .int(let s)? = py.value(of: "score") { return s }
        return nil
    }

    /// Effects produced since the last call (the stage animates them).
    func drainEffects() -> [Effect] {
        defer { effects = [] }
        return effects
    }
}
