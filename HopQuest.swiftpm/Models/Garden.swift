import Foundation

// Garden & pets (v3.5): a fenced garden beside your house with six beds, and a little pet that follows your buddy.
// Plants grow with real days and grow faster when watered. Nothing ever wilts or dies, and there's nothing to miss.

enum PlantKind: String, CaseIterable, Codable, Identifiable {
    case sunflower, carrot, tomato, strawberry, pumpkin, tulip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sunflower: return "Sunflower"
        case .carrot: return "Carrot"
        case .tomato: return "Tomato"
        case .strawberry: return "Strawberry"
        case .pumpkin: return "Pumpkin"
        case .tulip: return "Tulip"
        }
    }

    var emoji: String {
        switch self {
        case .sunflower: return "🌻"
        case .carrot: return "🥕"
        case .tomato: return "🍅"
        case .strawberry: return "🍓"
        case .pumpkin: return "🎃"
        case .tulip: return "🌷"
        }
    }

    /// A science fact read aloud as it grows.
    var fact: String {
        switch self {
        case .sunflower: return "Young sunflowers turn to follow the sun across the sky!"
        case .carrot: return "A carrot is a root. It grows down under the soil, and we eat the root."
        case .tomato: return "Tomatoes grow from yellow flowers. Each flower can become a tomato."
        case .strawberry: return "Strawberries wear their seeds on the outside, about two hundred on each berry!"
        case .pumpkin: return "Pumpkins grow on long vines that creep along the ground."
        case .tulip: return "Tulips grow from bulbs, a little like onions, that store food under the ground."
        }
    }
}

/// One planted bed.
struct GardenPlot: Codable, Equatable {
    var kind: PlantKind
    /// The day it was planted ("yyyy-MM-dd").
    var planted: String
    /// Days it was watered (once a day counts).
    var watered: [String] = []
}

enum PetKind: String, CaseIterable, Codable, Identifiable {
    case puppy, kitten, bunny, duckling

    var id: String { rawValue }

    var name: String {
        switch self {
        case .puppy: return "Biscuit"
        case .kitten: return "Whiskers"
        case .bunny: return "Clover"
        case .duckling: return "Puddles"
        }
    }

    var title: String {
        switch self {
        case .puppy: return "Puppy"
        case .kitten: return "Kitten"
        case .bunny: return "Bunny"
        case .duckling: return "Duckling"
        }
    }

    var emoji: String {
        switch self {
        case .puppy: return "🐶"
        case .kitten: return "🐱"
        case .bunny: return "🐰"
        case .duckling: return "🐥"
        }
    }

    /// What happens when you pat it.
    var pat: String {
        switch self {
        case .puppy: return "Biscuit wags and wags!"
        case .kitten: return "Whiskers purrs. Prrrr!"
        case .bunny: return "Clover does a happy hop!"
        case .duckling: return "Puddles says quack quack!"
        }
    }

    /// How to get it, in kid words (nil = from the start).
    var howToGet: String? {
        switch self {
        case .puppy, .kitten: return nil
        case .bunny: return "Grow and pick a carrot"
        case .duckling: return "Pick 3 plants from your garden"
        }
    }
}

struct GardenSave: Codable, Equatable {
    static let plotCount = 6
    /// The most growth a plant needs (seed → sprout → bud → ready).
    static let ripeStage = 3

    /// Bed number (0...5) → plant. Empty beds aren't stored.
    var plots: [Int: GardenPlot] = [:]
    /// How many of each plant have been picked.
    var harvested: [String: Int] = [:]
    var pet: PetKind?

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plots = ((try? c.decodeIfPresent([Int: GardenPlot].self, forKey: .plots)) ?? [:]).filter { (0..<Self.plotCount).contains($0.key) }
        harvested = (try? c.decodeIfPresent([String: Int].self, forKey: .harvested)) ?? [:]
        pet = try? c.decodeIfPresent(PetKind.self, forKey: .pet)
    }

    var totalHarvested: Int { harvested.values.reduce(0, +) }

    /// Growth: one step for each day since planting, plus one for each day it was watered. Never goes down.
    func stage(_ i: Int, today: String) -> Int? {
        guard let p = plots[i], let planted = Self.dayNumber(p.planted), let now = Self.dayNumber(today) else { return nil }
        let days = max(0, now - planted)
        let waters = Set(p.watered).compactMap(Self.dayNumber).filter { $0 >= planted && $0 <= now }.count
        return min(Self.ripeStage, days + waters)
    }

    func isRipe(_ i: Int, today: String) -> Bool { stage(i, today: today) == Self.ripeStage }

    func wateredToday(_ i: Int, today: String) -> Bool { plots[i]?.watered.contains(today) == true }

    /// Days left until it's ready if it isn't watered again (0 = ready now).
    func daysLeft(_ i: Int, today: String) -> Int? {
        guard let s = stage(i, today: today) else { return nil }
        return Self.ripeStage - s
    }

    @discardableResult
    mutating func plant(_ kind: PlantKind, in i: Int, today: String) -> Bool {
        guard (0..<Self.plotCount).contains(i), plots[i] == nil, Self.dayNumber(today) != nil else { return false }
        plots[i] = GardenPlot(kind: kind, planted: today)
        return true
    }

    /// Water once a day. False if it's ready, empty, or already watered today.
    @discardableResult
    mutating func water(_ i: Int, today: String) -> Bool {
        guard var p = plots[i], !isRipe(i, today: today), !p.watered.contains(today) else { return false }
        p.watered.append(today)
        plots[i] = p
        return true
    }

    /// Picks a ready plant. Returns what was picked and whether it's the first of its kind (that gives a star).
    mutating func harvest(_ i: Int, today: String) -> (kind: PlantKind, first: Bool)? {
        guard let p = plots[i], isRipe(i, today: today) else { return nil }
        plots[i] = nil
        let n = harvested[p.kind.rawValue] ?? 0
        harvested[p.kind.rawValue] = n + 1
        return (p.kind, n == 0)
    }

    func isUnlocked(_ pet: PetKind) -> Bool {
        switch pet {
        case .puppy, .kitten: return true
        case .bunny: return (harvested[PlantKind.carrot.rawValue] ?? 0) > 0
        case .duckling: return totalHarvested >= 3
        }
    }

    /// "2026-10-16" → days since 1970-01-01 (no time zones involved), or nil if it isn't a date.
    static func dayNumber(_ s: String) -> Int? {
        let parts = s.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        var y = parts[0]
        let m = parts[1], d = parts[2]
        y -= m <= 2 ? 1 : 0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }
}
