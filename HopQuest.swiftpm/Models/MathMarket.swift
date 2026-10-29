import Foundation

// The Math Market (v3.4): Benny Banana's shop in Hop Village. Kids count coins, pay, make change and compare prices.
// Plain Swift, tested in Tests/Learn. Money is in cents; US coins.

enum Coin: Int, CaseIterable, Codable, Comparable {
    case penny = 1, nickel = 5, dime = 10, quarter = 25

    static func < (a: Coin, b: Coin) -> Bool { a.rawValue < b.rawValue }

    var name: String {
        switch self {
        case .penny: return "penny"
        case .nickel: return "nickel"
        case .dime: return "dime"
        case .quarter: return "quarter"
        }
    }

    var label: String { "\(rawValue)¢" }

    /// Coins a learner at this level uses (1 = little, 2 = growing, 3 = big).
    static func forLevel(_ level: Int) -> [Coin] { level <= 1 ? [.penny, .nickel, .dime] : allCases }
}

struct ShopItem: Equatable {
    let name: String
    let emoji: String
}

enum MarketGame: String, CaseIterable, Codable, Identifiable {
    case countCoins, payExactly, makeChange, compare, addUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countCoins: return "Count the Coins"
        case .payExactly: return "Pay Exactly"
        case .makeChange: return "Make Change"
        case .compare: return "Better Buy"
        case .addUp: return "Shopping List"
        }
    }

    var icon: String {
        switch self {
        case .countCoins: return "🪙"
        case .payExactly: return "🛒"
        case .makeChange: return "💵"
        case .compare: return "⚖️"
        case .addUp: return "📝"
        }
    }

    var skill: String {
        switch self {
        case .countCoins: return "counting coins"
        case .payExactly: return "making an amount with coins"
        case .makeChange: return "subtracting to make change"
        case .compare: return "comparing numbers"
        case .addUp: return "adding prices"
        }
    }

    var intro: String {
        switch self {
        case .countCoins: return "Count the coins. How much money is it?"
        case .payExactly: return "Tap coins to pay the exact price, then press Pay."
        case .makeChange: return "You pay with more money than it costs. How much change do you get back?"
        case .compare: return "Look at the prices and pick the right one."
        case .addUp: return "Add up the shopping list. How much is it all together?"
        }
    }
}

struct MarketRound: Equatable {
    enum Kind: Equatable {
        case choose
        /// Tap coins until they add up to `target`.
        case pay(target: Int)
    }
    let kind: Kind
    /// Pictures and words at the top ("🍎 12¢").
    let show: String
    /// Coins pictured in the question (Count the Coins).
    let coins: [Coin]
    let say: String
    let choices: [String]
    /// The right choice (empty for `.pay`).
    let answer: String
    let cheer: String
}

enum MarketBank {
    static let items: [ShopItem] = [
        ShopItem(name: "apple", emoji: "🍎"), ShopItem(name: "banana", emoji: "🍌"), ShopItem(name: "juice box", emoji: "🧃"),
        ShopItem(name: "cookie", emoji: "🍪"), ShopItem(name: "balloon", emoji: "🎈"), ShopItem(name: "crayon", emoji: "🖍️"),
        ShopItem(name: "teddy bear", emoji: "🧸"), ShopItem(name: "kite", emoji: "🪁"), ShopItem(name: "carrot", emoji: "🥕"),
        ShopItem(name: "muffin", emoji: "🧁"), ShopItem(name: "ball", emoji: "⚽"), ShopItem(name: "book", emoji: "📘"),
    ]

    static let cheers = ["Nice counting!", "You got it!", "Smart shopping!", "That's right!", "Super math!"]

    /// The most money in a round for each level.
    static func maxCents(_ level: Int) -> Int { level <= 1 ? 20 : level == 2 ? 50 : 99 }

    static func cents(_ n: Int) -> String { "\(n)¢" }

    static func total(_ coins: [Coin]) -> Int { coins.map(\.rawValue).reduce(0, +) }

    /// Fewest coins that make `amount` (greedy works for US coins).
    static func fewestCoins(_ amount: Int, from kinds: [Coin] = Coin.allCases) -> [Coin] {
        var left = amount, out: [Coin] = []
        for c in kinds.sorted(by: >) { while left >= c.rawValue { out.append(c); left -= c.rawValue } }
        return out
    }

    /// Two wrong amounts near the right one, never below 1 or repeated.
    static func distractors<G: RandomNumberGenerator>(for answer: Int, max: Int, using rng: inout G) -> [Int] {
        var pool = Set([answer + 1, answer - 1, answer + 5, answer - 5, answer + 10, answer - 10, answer + 2])
        pool = pool.filter { $0 >= 1 && $0 <= max + 10 && $0 != answer }
        return Array(pool.sorted().shuffled(using: &rng).prefix(2))
    }

    static func rounds<G: RandomNumberGenerator>(for game: MarketGame, level: Int, count: Int = 5, using rng: inout G) -> [MarketRound] {
        let top = maxCents(level)
        let kinds = Coin.forLevel(level)
        return (0..<count).map { _ in
            let item = items.randomElement(using: &rng)!
            let cheer = cheers.randomElement(using: &rng)!
            switch game {
            case .countCoins:
                let n = Int.random(in: 2...(level <= 1 ? 4 : 6), using: &rng)
                var coins: [Coin] = []
                while coins.count < n {
                    let c = kinds.randomElement(using: &rng)!
                    if total(coins) + c.rawValue <= top { coins.append(c) } else if total(coins) + 1 <= top { coins.append(.penny) } else { break }
                }
                coins.sort(by: >)
                let sum = total(coins)
                let choices = ([sum] + distractors(for: sum, max: top, using: &rng)).shuffled(using: &rng).map(cents)
                return MarketRound(kind: .choose, show: "", coins: coins, say: "How much money is this? Count the coins.",
                                   choices: choices, answer: cents(sum), cheer: "That's \(sum) cents! \(cheer)")
            case .payExactly:
                let price = Int.random(in: (level <= 1 ? 3 : 8)...top, using: &rng)
                return MarketRound(kind: .pay(target: price), show: "\(item.emoji) \(cents(price))", coins: [],
                                   say: "The \(item.name) costs \(price) cents. Tap coins to pay exactly \(price) cents.",
                                   choices: kinds.map(\.label), answer: "", cheer: "Exactly \(price) cents! \(cheer)")
            case .makeChange:
                let paid = level <= 1 ? 20 : level == 2 ? 50 : 100
                let price = Int.random(in: max(1, paid / 4)...(paid - 1), using: &rng)
                let change = paid - price
                let choices = ([change] + distractors(for: change, max: paid, using: &rng)).shuffled(using: &rng).map(cents)
                return MarketRound(kind: .choose, show: "\(item.emoji) \(cents(price))\nYou pay \(cents(paid))", coins: [],
                                   say: "The \(item.name) costs \(price) cents. You pay with \(paid) cents. How much change do you get?",
                                   choices: choices, answer: cents(change),
                                   cheer: "\(paid) take away \(price) is \(change). \(cheer)")
            case .compare:
                let other = items.filter { $0 != item }.randomElement(using: &rng)!
                let a = Int.random(in: 2...top, using: &rng)
                var b = Int.random(in: 2...top, using: &rng)
                while b == a { b = Int.random(in: 2...top, using: &rng) }
                let cheaper = Bool.random(using: &rng)
                let pick = cheaper ? (a < b ? item : other) : (a > b ? item : other)
                let pickPrice = pick == item ? a : b
                return MarketRound(kind: .choose, show: "\(item.emoji) \(cents(a))   \(other.emoji) \(cents(b))", coins: [],
                                   say: "Which one costs \(cheaper ? "less" : "more"): the \(item.name) or the \(other.name)?",
                                   choices: ["\(item.emoji) \(cents(a))", "\(other.emoji) \(cents(b))"],
                                   answer: "\(pick.emoji) \(cents(pickPrice))",
                                   cheer: "\(pickPrice) cents is \(cheaper ? "less" : "more")! \(cheer)")
            case .addUp:
                let other = items.filter { $0 != item }.randomElement(using: &rng)!
                let a = Int.random(in: 1...(top / 2), using: &rng)
                let b = Int.random(in: 1...(top - a), using: &rng)
                let sum = a + b
                let choices = ([sum] + distractors(for: sum, max: top, using: &rng)).shuffled(using: &rng).map(cents)
                return MarketRound(kind: .choose, show: "\(item.emoji) \(cents(a))  +  \(other.emoji) \(cents(b))", coins: [],
                                   say: "A \(item.name) for \(a) cents and a \(other.name) for \(b) cents. How much together?",
                                   choices: choices, answer: cents(sum), cheer: "\(a) plus \(b) is \(sum). \(cheer)")
            }
        }
    }

    static func rounds(for game: MarketGame, level: Int, count: Int = 5) -> [MarketRound] {
        var g = SystemRandomNumberGenerator()
        return rounds(for: game, level: level, count: count, using: &g)
    }
}

/// Math Market progress: best stars per game, like the Reading Nook.
struct MarketSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
    }

    func best(_ g: MarketGame) -> Int { best[g.rawValue] ?? 0 }

    mutating func record(_ g: MarketGame, stars: Int) -> Int {
        plays += 1
        let old = best(g)
        guard stars > old else { return 0 }
        best[g.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = MarketGame.allCases.count * 3
}
