import Foundation

/// Runs a Game Maker project. The child's Python sets up the game (background, hero, stars) and handles events
/// (on_tap, on_star). The stage asks this object what to draw and calls the events while the game plays.
final class GameProgram {
    struct Setup: Equatable {
        var background: String?
        var hero: String?
        var stars = 0
    }

    enum Effect: Equatable {
        case jump(Int)
        case say(String)
    }

    static let worlds = ["meadow", "night", "ocean", "candy"]
    static let maxStars = 12

    let py = MiniPython()
    private(set) var setup = Setup()
    private var effects: [Effect] = []

    init(validHeroes: Set<String>) {
        py.host["set_background"] = { [weak self] args in
            guard case .str(let w)? = args.first, args.count == 1, Self.worlds.contains(w) else {
                throw PyError(line: 0, message: "set_background() takes one world: \(Self.worlds.map { "\"\($0)\"" }.joined(separator: ", ")).")
            }
            self?.setup.background = w
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
            guard self.setup.stars < Self.maxStars else { throw PyError(line: 0, message: "That's a lot of stars! Try \(Self.maxStars) or fewer.") }
            self.setup.stars += 1
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
        try py.run(source)
    }

    var hasTapEvent: Bool { py.hasFunction("on_tap") }
    var hasStarEvent: Bool { py.hasFunction("on_star") }

    func tap() throws { try py.call("on_tap") }
    func starCollected() throws { try py.call("on_star") }

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
