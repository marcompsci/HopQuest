import Foundation

// The Science Lab (v4.1): five hands-on experiments with Professor Ocho. Guess first, then see what happens.
// Plain Swift, tested in Tests/Learn.

enum Experiment: String, CaseIterable, Codable, Identifiable {
    case sinkFloat, magnets, plantParts, weather, matter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sinkFloat: return "Sink or Float?"
        case .magnets: return "Magnet Test"
        case .plantParts: return "Plant Parts"
        case .weather: return "Weather Watch"
        case .matter: return "Solid, Liquid, Gas"
        }
    }

    var icon: String {
        switch self {
        case .sinkFloat: return "🛁"
        case .magnets: return "🧲"
        case .plantParts: return "🌱"
        case .weather: return "🌦️"
        case .matter: return "🧊"
        }
    }

    var skill: String {
        switch self {
        case .sinkFloat: return "predicting and testing (density)"
        case .magnets: return "magnetic materials"
        case .plantParts: return "parts of a plant"
        case .weather: return "weather and temperature"
        case .matter: return "states of matter"
        }
    }

    var intro: String {
        switch self {
        case .sinkFloat: return "Will it sink or float? Make your guess, then watch it splash!"
        case .magnets: return "Does the magnet pull it? Guess, then test it with the magnet."
        case .plantParts: return "Every part of a plant has a job. Which part does this one?"
        case .weather: return "Look at the weather. What should you do or wear?"
        case .matter: return "Is it a solid, a liquid, or a gas?"
        }
    }
}

struct ScienceRound: Equatable {
    /// The thing being tested (big emoji).
    let show: String
    /// Its name ("a rubber duck").
    let name: String
    let say: String
    let choices: [String]
    let answer: String
    /// Why, read after the answer.
    let explain: String
}

enum ScienceBank {
    struct Fact { let emoji: String; let name: String; let answer: String; let explain: String }

    static let sinkFloat: [Fact] = [
        Fact(emoji: "🪨", name: "a rock", answer: "Sink", explain: "Rocks are heavy for their size, so they sink."),
        Fact(emoji: "🪵", name: "a log", answer: "Float", explain: "Wood is lighter than water for its size, so logs float."),
        Fact(emoji: "🦆", name: "a rubber duck", answer: "Float", explain: "It's full of air, and air makes it float."),
        Fact(emoji: "🔑", name: "a metal key", answer: "Sink", explain: "Metal is heavy for its size, so a key sinks."),
        Fact(emoji: "🍎", name: "an apple", answer: "Float", explain: "Apples have lots of air inside, so they float."),
        Fact(emoji: "🪙", name: "a coin", answer: "Sink", explain: "Coins are small but made of heavy metal, so they sink."),
        Fact(emoji: "🧽", name: "a sponge", answer: "Float", explain: "A sponge is full of tiny air holes, so it floats."),
        Fact(emoji: "⚓", name: "an anchor", answer: "Sink", explain: "Anchors are made to sink, to hold a boat in place."),
        Fact(emoji: "🏐", name: "a beach ball", answer: "Float", explain: "A beach ball is full of air, so it bobs on top."),
        Fact(emoji: "🔩", name: "a bolt", answer: "Sink", explain: "A steel bolt is heavy for its size, so it sinks."),
        Fact(emoji: "🍃", name: "a leaf", answer: "Float", explain: "Leaves are very light and flat, so they float."),
        Fact(emoji: "🥚", name: "an egg", answer: "Sink", explain: "A fresh egg is a little heavier than water, so it sinks."),
    ]

    static let magnets: [Fact] = [
        Fact(emoji: "📎", name: "a paper clip", answer: "Yes", explain: "Paper clips are made of steel, and magnets pull steel."),
        Fact(emoji: "🔩", name: "a steel bolt", answer: "Yes", explain: "Steel has iron in it, so the magnet pulls it."),
        Fact(emoji: "🧷", name: "a safety pin", answer: "Yes", explain: "Safety pins are steel, so they jump to the magnet."),
        Fact(emoji: "⛓️", name: "a steel chain", answer: "Yes", explain: "A steel chain sticks to a magnet, link by link."),
        Fact(emoji: "🪵", name: "a wooden block", answer: "No", explain: "Wood has no iron in it, so magnets don't pull it."),
        Fact(emoji: "🧸", name: "a teddy bear", answer: "No", explain: "Cloth and stuffing aren't magnetic."),
        Fact(emoji: "🍌", name: "a banana", answer: "No", explain: "Food isn't magnetic. The magnet does nothing!"),
        Fact(emoji: "✏️", name: "a pencil", answer: "No", explain: "Pencils are wood and graphite, which magnets don't pull."),
        Fact(emoji: "🥛", name: "a glass", answer: "No", explain: "Glass isn't magnetic."),
        Fact(emoji: "🦆", name: "a rubber duck", answer: "No", explain: "Rubber and plastic aren't magnetic."),
    ]

    /// Plant parts: (question, right part, why).
    static let plantParts: [(String, String, String)] = [
        ("Which part drinks water from the soil?", "Roots", "Roots soak up water and hold the plant in the ground."),
        ("Which part carries water up the plant?", "Stem", "The stem is like a straw that carries water up to the leaves."),
        ("Which part makes food from sunlight?", "Leaves", "Leaves use sunlight, air and water to make food for the plant."),
        ("Which part do bees visit for nectar?", "Flower", "Flowers have sweet nectar, and bees carry pollen between them."),
        ("Which part can grow into a new plant?", "Seeds", "A seed has a tiny baby plant inside, waiting to grow."),
        ("Which part holds the plant up tall?", "Stem", "A strong stem holds the leaves and flowers up to the sun."),
        ("Which part is often green and flat?", "Leaves", "Most leaves are green and flat to catch lots of sunlight."),
        ("Which part grows under the ground?", "Roots", "Roots grow down into the soil, where it's dark and damp."),
    ]
    static let parts = ["Roots", "Stem", "Leaves", "Flower", "Seeds"]

    /// Weather: (picture, question, right choice, two other choices, why).
    static let weather: [(String, String, String, [String], String)] = [
        ("❄️", "It's snowing outside. What should you wear?", "A warm coat", ["A swimsuit", "Flip-flops"], "Snow means it's very cold, so wear a warm coat."),
        ("🌧️", "It's raining. What should you take?", "An umbrella", ["Sunglasses", "A sled"], "An umbrella keeps the rain off you."),
        ("☀️", "It's a hot, sunny day. What helps?", "Sunscreen and water", ["Mittens", "A scarf"], "Sunscreen protects your skin, and water keeps you cool."),
        ("🌬️", "It's very windy. What's fun to do?", "Fly a kite", ["Build a snowman", "Swim"], "Wind lifts kites high into the sky."),
        ("⛈️", "There's thunder and lightning. Where should you be?", "Inside", ["At the pool", "Under a tall tree"], "Lightning can be dangerous, so go inside until the storm passes."),
        ("🌡️", "The thermometer says 95 degrees. Is it hot or cold?", "Hot", ["Cold", "Freezing"], "95 degrees Fahrenheit is a hot summer day."),
        ("🌡️", "The thermometer says 20 degrees. Is it hot or cold?", "Cold", ["Hot", "Warm"], "20 degrees Fahrenheit is below freezing, so it's cold."),
        ("🌈", "When do rainbows appear?", "Sun after rain", ["At midnight", "In a snowstorm"], "Sunlight shining through raindrops makes a rainbow."),
    ]

    static let matter: [Fact] = [
        Fact(emoji: "🧊", name: "an ice cube", answer: "Solid", explain: "Ice is frozen water. It keeps its shape, so it's a solid."),
        Fact(emoji: "🧃", name: "juice", answer: "Liquid", explain: "Juice pours and takes the shape of its cup, so it's a liquid."),
        Fact(emoji: "♨️", name: "steam", answer: "Gas", explain: "Steam is water that got so hot it became a gas."),
        Fact(emoji: "🪨", name: "a rock", answer: "Solid", explain: "A rock keeps its shape. It's a solid."),
        Fact(emoji: "🥛", name: "milk", answer: "Liquid", explain: "Milk flows and fills its glass, so it's a liquid."),
        Fact(emoji: "🎈", name: "the air in a balloon", answer: "Gas", explain: "Air is a gas. It spreads out to fill the balloon."),
        Fact(emoji: "🧱", name: "a brick", answer: "Solid", explain: "Bricks are hard and keep their shape: a solid."),
        Fact(emoji: "💧", name: "water", answer: "Liquid", explain: "Water flows and splashes. It's a liquid."),
        Fact(emoji: "🫧", name: "the air in bubbles", answer: "Gas", explain: "Bubbles are filled with air, which is a gas."),
        Fact(emoji: "🍯", name: "honey", answer: "Liquid", explain: "Honey flows slowly, but it still pours, so it's a liquid."),
    ]

    static let cheers = ["Great science!", "You figured it out!", "Super scientist!", "Excellent!", "That's right!"]

    static func rounds<G: RandomNumberGenerator>(for e: Experiment, count: Int = 5, using rng: inout G) -> [ScienceRound] {
        switch e {
        case .sinkFloat:
            return Array(sinkFloat.shuffled(using: &rng).prefix(count)).map { f in
                ScienceRound(show: f.emoji, name: f.name, say: "Will \(f.name) sink or float?", choices: ["Sink", "Float"],
                             answer: f.answer, explain: f.explain)
            }
        case .magnets:
            return Array(magnets.shuffled(using: &rng).prefix(count)).map { f in
                ScienceRound(show: f.emoji, name: f.name, say: "Will the magnet pull \(f.name)?", choices: ["Yes", "No"],
                             answer: f.answer, explain: f.explain)
            }
        case .plantParts:
            return Array(plantParts.shuffled(using: &rng).prefix(count)).map { q in
                let wrong = parts.filter { $0 != q.1 }.shuffled(using: &rng).prefix(2)
                return ScienceRound(show: "🌻", name: "", say: q.0, choices: ([q.1] + wrong).shuffled(using: &rng),
                                    answer: q.1, explain: q.2)
            }
        case .weather:
            return Array(weather.shuffled(using: &rng).prefix(count)).map { w in
                ScienceRound(show: w.0, name: "", say: w.1, choices: ([w.2] + w.3).shuffled(using: &rng), answer: w.2, explain: w.4)
            }
        case .matter:
            return Array(matter.shuffled(using: &rng).prefix(count)).map { f in
                ScienceRound(show: f.emoji, name: f.name, say: "Is \(f.name) a solid, a liquid, or a gas?",
                             choices: ["Solid", "Liquid", "Gas"], answer: f.answer, explain: f.explain)
            }
        }
    }

    static func rounds(for e: Experiment, count: Int = 5) -> [ScienceRound] {
        var g = SystemRandomNumberGenerator()
        return rounds(for: e, count: count, using: &g)
    }
}

/// Science Lab progress: best stars per experiment (stars only for beating your best).
struct ScienceSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
    }

    func best(_ e: Experiment) -> Int { best[e.rawValue] ?? 0 }

    mutating func record(_ e: Experiment, stars: Int) -> Int {
        plays += 1
        let old = best(e)
        guard stars > old else { return 0 }
        best[e.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = Experiment.allCases.count * 3
}
