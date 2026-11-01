import Foundation

// Around the World (v4.6): Pip Penguin's postcard trip to all seven continents. Kids find continents on a map,
// match animals and landmarks to where they are, and learn the five oceans. Each continent they get right sends
// a postcard home. Plain Swift, tested in Tests/Learn.

enum Continent: String, CaseIterable, Codable, Identifiable {
    case northAmerica, southAmerica, europe, africa, asia, australia, antarctica

    var id: String { rawValue }

    var name: String {
        switch self {
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .europe: return "Europe"
        case .africa: return "Africa"
        case .asia: return "Asia"
        case .australia: return "Australia"
        case .antarctica: return "Antarctica"
        }
    }

    /// One true, kid-sized fact, read on the postcard.
    var postcard: String {
        switch self {
        case .northAmerica: return "Hello from North America! The bald eagle builds nests as big as a bed."
        case .southAmerica: return "Hello from South America! The Amazon rainforest is home to millions of kinds of plants and animals."
        case .europe: return "Hello from Europe! It's a small continent with lots of countries close together."
        case .africa: return "Hello from Africa! The Sahara is the biggest hot desert in the world."
        case .asia: return "Hello from Asia! It's the biggest continent, and it has the tallest mountain, Mount Everest."
        case .australia: return "Hello from Australia! Kangaroos carry their babies in a pouch."
        case .antarctica: return "Hello from Antarctica! It's the coldest place on Earth, and almost all of it is covered in ice."
        }
    }

    var colorHex: UInt32 {
        switch self {
        case .northAmerica: return 0xF4A259
        case .southAmerica: return 0x5BB370
        case .europe: return 0x7C8CF2
        case .africa: return 0xE9C46A
        case .asia: return 0xE76F51
        case .australia: return 0xD08AE0
        case .antarctica: return 0xE8F1F8
        }
    }

    /// The outline on Pip's map, as (longitude, latitude) corners. Simplified, but in the right places.
    var outline: [(lon: Double, lat: Double)] {
        switch self {
        case .northAmerica:
            return [(-168, 66), (-140, 70), (-95, 72), (-75, 62), (-55, 52), (-66, 44), (-81, 25), (-97, 18), (-87, 13), (-80, 8),
                    (-105, 20), (-118, 33), (-125, 48), (-140, 60), (-165, 60)]
        case .southAmerica:
            return [(-80, 9), (-60, 10), (-35, -6), (-40, -22), (-57, -38), (-68, -55), (-75, -48), (-71, -18), (-78, -12), (-81, -5)]
        case .europe:
            return [(-10, 36), (-10, 44), (-5, 48), (-2, 58), (5, 62), (15, 70), (30, 70), (40, 66), (50, 60), (55, 50), (40, 45),
                    (28, 41), (20, 38), (12, 38), (3, 43)]
        case .africa:
            return [(-17, 21), (-6, 35), (10, 37), (32, 31), (43, 12), (51, 12), (40, -15), (32, -29), (20, -35), (12, -17), (9, 4),
                    (-8, 5), (-17, 14)]
        case .asia:
            return [(40, 45), (55, 50), (50, 60), (40, 66), (60, 72), (100, 78), (140, 72), (180, 68), (170, 60), (140, 50), (130, 42),
                    (122, 30), (110, 20), (105, 10), (100, 2), (95, 15), (80, 8), (72, 20), (60, 25), (48, 30), (35, 33), (28, 41)]
        case .australia:
            return [(114, -22), (130, -12), (142, -11), (154, -27), (150, -38), (135, -35), (115, -34)]
        case .antarctica:
            return [(-180, -66), (-60, -64), (0, -70), (90, -66), (180, -66), (180, -85), (-180, -85)]
        }
    }

    /// The outline in map units: x 0…1 across the world, y 0…0.5 from the top (the map is twice as wide as tall).
    var mapOutline: [(x: Double, y: Double)] { outline.map { WorldMap.point(lon: $0.lon, lat: $0.lat) } }
}

enum WorldMap {
    static func point(lon: Double, lat: Double) -> (x: Double, y: Double) { ((lon + 180) / 360, (90 - lat) / 360) }

    /// Which continent is under a map point (nil = ocean).
    static func continent(atX x: Double, y: Double) -> Continent? {
        Continent.allCases.first { contains($0.mapOutline, x: x, y: y) }
    }

    /// Ray casting: is the point inside the polygon?
    static func contains(_ poly: [(x: Double, y: Double)], x: Double, y: Double) -> Bool {
        var inside = false
        var j = poly.count - 1
        for i in poly.indices {
            let a = poly[i], b = poly[j]
            if (a.y > y) != (b.y > y), x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
            j = i
        }
        return inside
    }

    /// The middle of a continent, for its label.
    static func center(_ c: Continent) -> (x: Double, y: Double) {
        let pts = c.mapOutline
        return (pts.map(\.x).reduce(0, +) / Double(pts.count), pts.map(\.y).reduce(0, +) / Double(pts.count))
    }
}

struct WorldThing: Equatable {
    let name: String
    let emoji: String
    /// Every continent it's found on (wrong choices are never any of these).
    let places: [Continent]
    let fact: String
    var home: Continent { places[0] }
}

enum WorldGame: String, CaseIterable, Codable, Identifiable {
    case findIt, animals, landmarks, oceans

    var id: String { rawValue }

    var title: String {
        switch self {
        case .findIt: return "Find It!"
        case .animals: return "Animal Homes"
        case .landmarks: return "Famous Places"
        case .oceans: return "Five Oceans"
        }
    }

    var skill: String {
        switch self {
        case .findIt: return "finding the continents on a map"
        case .animals: return "where animals live"
        case .landmarks: return "famous places around the world"
        case .oceans: return "the five oceans"
        }
    }

    var intro: String {
        switch self {
        case .findIt: return "There are seven continents. Tap the one Pip names on the map!"
        case .animals: return "Animals live all over the world. Where does this one live?"
        case .landmarks: return "Let's visit famous places! Which continent is this one on?"
        case .oceans: return "Most of the Earth is covered by water. Let's learn the five oceans!"
        }
    }
}

struct WorldRound: Equatable {
    enum Kind: Equatable {
        /// Tap a continent on the map.
        case tapMap
        /// Pick one of the choices.
        case choose
    }
    let kind: Kind
    let show: String
    let say: String
    let choices: [String]
    let answer: String
    let cheer: String
    /// The continent this round is about (sends a postcard), if any.
    let continent: Continent?
}

enum WorldBank {
    static let animals: [WorldThing] = [
        WorldThing(name: "lion", emoji: "🦁", places: [.africa, .asia], fact: "Lions live in groups called prides."),
        WorldThing(name: "giraffe", emoji: "🦒", places: [.africa], fact: "A giraffe's tongue is about as long as your arm."),
        WorldThing(name: "zebra", emoji: "🦓", places: [.africa], fact: "No two zebras have the same stripes."),
        WorldThing(name: "hippo", emoji: "🦛", places: [.africa], fact: "Hippos spend most of the day cooling off in water."),
        WorldThing(name: "gorilla", emoji: "🦍", places: [.africa], fact: "Gorillas build a fresh leafy bed every night."),
        WorldThing(name: "giant panda", emoji: "🐼", places: [.asia], fact: "Pandas eat bamboo for about half the day."),
        WorldThing(name: "tiger", emoji: "🐅", places: [.asia], fact: "Tigers are the biggest cats in the world, and they like to swim."),
        WorldThing(name: "orangutan", emoji: "🦧", places: [.asia], fact: "Orangutans spend almost all their time up in the trees."),
        WorldThing(name: "kangaroo", emoji: "🦘", places: [.australia], fact: "Kangaroos can't walk backwards."),
        WorldThing(name: "koala", emoji: "🐨", places: [.australia], fact: "Koalas sleep up to 20 hours a day."),
        WorldThing(name: "bison", emoji: "🦬", places: [.northAmerica, .europe], fact: "Bison are the biggest land animals in North America."),
        WorldThing(name: "raccoon", emoji: "🦝", places: [.northAmerica, .europe, .asia], fact: "Raccoons have very clever front paws."),
        WorldThing(name: "bald eagle", emoji: "🦅", places: [.northAmerica], fact: "Bald eagles aren't bald: their heads have white feathers."),
        WorldThing(name: "sloth", emoji: "🦥", places: [.southAmerica, .northAmerica], fact: "Sloths move so slowly that tiny plants grow in their fur."),
        WorldThing(name: "llama", emoji: "🦙", places: [.southAmerica], fact: "Llamas live high up in the Andes mountains."),
        WorldThing(name: "jaguar", emoji: "🐆", places: [.southAmerica, .northAmerica], fact: "Jaguars are great swimmers."),
        WorldThing(name: "hedgehog", emoji: "🦔", places: [.europe, .asia, .africa], fact: "Hedgehogs roll into a prickly ball to stay safe."),
        WorldThing(name: "emperor penguin", emoji: "🐧", places: [.antarctica], fact: "Emperor penguin dads keep the egg warm on their feet."),
    ]

    static let landmarks: [WorldThing] = [
        WorldThing(name: "the Great Pyramids", emoji: "🔺", places: [.africa], fact: "The pyramids in Egypt are more than 4,000 years old."),
        WorldThing(name: "Mount Kilimanjaro", emoji: "🏔️", places: [.africa], fact: "Kilimanjaro has snow on top, even though it's near the equator."),
        WorldThing(name: "the Great Wall", emoji: "🧱", places: [.asia], fact: "The Great Wall of China winds over mountains for thousands of miles."),
        WorldThing(name: "Mount Everest", emoji: "⛰️", places: [.asia], fact: "Mount Everest is the tallest mountain on Earth."),
        WorldThing(name: "the Taj Mahal", emoji: "🕌", places: [.asia], fact: "The Taj Mahal in India is made of white marble."),
        WorldThing(name: "the Eiffel Tower", emoji: "🗼", places: [.europe], fact: "The Eiffel Tower in Paris gets a new coat of paint every few years."),
        WorldThing(name: "the Colosseum", emoji: "🏛️", places: [.europe], fact: "The Colosseum in Rome is almost 2,000 years old."),
        WorldThing(name: "the Statue of Liberty", emoji: "🗽", places: [.northAmerica], fact: "The Statue of Liberty was a gift from France."),
        WorldThing(name: "the Grand Canyon", emoji: "🏜️", places: [.northAmerica], fact: "A river carved the Grand Canyon over millions of years."),
        WorldThing(name: "the Amazon rainforest", emoji: "🌳", places: [.southAmerica], fact: "The Amazon is the biggest rainforest in the world."),
        WorldThing(name: "Machu Picchu", emoji: "🏞️", places: [.southAmerica], fact: "Machu Picchu is an old stone town high in the mountains of Peru."),
        WorldThing(name: "the Great Barrier Reef", emoji: "🐠", places: [.australia], fact: "The Great Barrier Reef is so big it can be seen from space."),
        WorldThing(name: "Uluru", emoji: "🪨", places: [.australia], fact: "Uluru is a giant red rock that glows at sunset."),
        WorldThing(name: "the South Pole", emoji: "🧭", places: [.antarctica], fact: "At the South Pole, every direction is north!"),
    ]

    /// Ocean questions: (question, answer, wrong choices, fact).
    static let oceans: [(q: String, answer: String, wrong: [String], fact: String)] = [
        ("Which is the biggest ocean?", "Pacific", ["Arctic", "Indian"], "The Pacific Ocean is bigger than all the land on Earth put together."),
        ("Which ocean is at the very top of the world, around the North Pole?", "Arctic", ["Pacific", "Indian"], "The Arctic Ocean is the smallest and coldest ocean."),
        ("Which ocean goes all the way around Antarctica?", "Southern", ["Atlantic", "Indian"], "The Southern Ocean is home to whales and penguins."),
        ("Which ocean is between Africa and Australia?", "Indian", ["Arctic", "Pacific"], "The Indian Ocean is the warmest ocean."),
        ("Which ocean is between the Americas and Europe and Africa?", "Atlantic", ["Pacific", "Southern"], "Ships have sailed across the Atlantic for hundreds of years."),
        ("Is ocean water salty or fresh?", "Salty", ["Fresh", "Sweet"], "Ocean water is salty. The water in rivers and lakes is usually fresh."),
        ("How many oceans are there?", "Five", ["Two", "Nine"], "Five oceans: Pacific, Atlantic, Indian, Southern and Arctic."),
        ("How much of the Earth is covered by water?", "Most of it", ["A little", "None"], "About seven out of every ten parts of Earth are water."),
    ]

    static let cheers = ["Great exploring!", "You found it!", "Super traveler!", "That's right!", "Postcard time!"]

    /// Two continents the thing is NOT on.
    static func wrongContinents<G: RandomNumberGenerator>(for t: WorldThing, using rng: inout G) -> [Continent] {
        Array(Continent.allCases.filter { !t.places.contains($0) }.shuffled(using: &rng).prefix(2))
    }

    static func rounds<G: RandomNumberGenerator>(for game: WorldGame, count: Int = 5, using rng: inout G) -> [WorldRound] {
        let cheer = { (i: Int) in cheers[i % cheers.count] }
        let offset = Int.random(in: 0..<cheers.count, using: &rng)
        switch game {
        case .findIt:
            return Array(Continent.allCases.shuffled(using: &rng).prefix(count)).enumerated().map { i, c in
                WorldRound(kind: .tapMap, show: c.name, say: "Find \(c.name) on the map.", choices: [], answer: c.rawValue,
                           cheer: "That's \(c.name)! \(cheer(i + offset))", continent: c)
            }
        case .animals, .landmarks:
            let pool = game == .animals ? animals : landmarks
            return Array(pool.shuffled(using: &rng).prefix(count)).map { t in
                let choices = ([t.home] + wrongContinents(for: t, using: &rng)).shuffled(using: &rng).map(\.name)
                let say = game == .animals ? "Where does the \(t.name) live?" : "Which continent is \(t.name) on?"
                return WorldRound(kind: .choose, show: t.emoji, say: say, choices: choices, answer: t.home.name,
                                  cheer: "\(t.home.name)! \(t.fact)", continent: t.home)
            }
        case .oceans:
            return Array(oceans.shuffled(using: &rng).prefix(count)).map { o in
                WorldRound(kind: .choose, show: "🌊", say: o.q, choices: ([o.answer] + o.wrong).shuffled(using: &rng),
                           answer: o.answer, cheer: "\(o.answer)! \(o.fact)", continent: nil)
            }
        }
    }

    static func rounds(for game: WorldGame, count: Int = 5) -> [WorldRound] {
        var g = SystemRandomNumberGenerator()
        return rounds(for: game, count: count, using: &g)
    }
}

/// Around the World progress: best stars per game, and postcards collected.
struct WorldTourSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0
    var postcards: Set<String> = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
        postcards = (try? c.decodeIfPresent(Set<String>.self, forKey: .postcards)) ?? []
    }

    func best(_ g: WorldGame) -> Int { best[g.rawValue] ?? 0 }

    mutating func record(_ g: WorldGame, stars: Int) -> Int {
        plays += 1
        let old = best(g)
        guard stars > old else { return 0 }
        best[g.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    /// Adds postcards; returns the ones that are new.
    mutating func collect(_ cs: [Continent]) -> [Continent] {
        let new = cs.filter { !postcards.contains($0.rawValue) }
        var seen: Set<Continent> = []
        let unique = new.filter { seen.insert($0).inserted }
        postcards.formUnion(unique.map(\.rawValue))
        return unique
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = WorldGame.allCases.count * 3
}
