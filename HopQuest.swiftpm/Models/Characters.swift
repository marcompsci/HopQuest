import SwiftUI

enum CharacterFamily: String, CaseIterable, Identifiable {
    case pets = "Retro Pets"
    case heroes = "Hero Squad"
    case garden = "Garden Gang"
    case zoo = "Zoo Crew"
    case wild = "Wild Pals"
    var id: String { rawValue }
}

enum Accessory: String {
    case none, cape, mask, crown, bow, helmet
}

/// All characters are ORIGINAL to HopQuest. Do not rename or restyle them to resemble
/// characters owned by other studios — that's what keeps the app shippable.
struct GameCharacter: Identifiable, Hashable {
    let id: String
    let name: String
    let family: CharacterFamily
    let emoji: String
    let colorHex: UInt32
    let accessory: Accessory
    let fact: String
    /// Which castle themes show this character in the "Picked for you" row.
    let featured: Set<CastleTheme>

    var color: Color { Color(hex: colorHex) }
    /// Lavender Lop is hand-drawn (a purple bunny) instead of an emoji badge.
    var isBunny: Bool { id == "lavender" }
}

enum Roster {
    static let all: [GameCharacter] = [
        // Retro Pets
        GameCharacter(id: "lavender", name: "Lavender Lop", family: .pets, emoji: "🐰", colorHex: 0x9B6BDF, accessory: .none,
                      fact: "A bunny's teeth never stop growing — crunchy hay keeps them just right!", featured: [.sparkle, .rainbow, .fortress]),
        GameCharacter(id: "pixelpup", name: "Pixel Pup", family: .pets, emoji: "🐶", colorHex: 0xFFC95E, accessory: .none,
                      fact: "Dogs can smell thousands of times better than people!", featured: [.fortress, .rainbow]),
        GameCharacter(id: "mochi", name: "Mochi Cat", family: .pets, emoji: "🐱", colorHex: 0xFFB3C7, accessory: .bow,
                      fact: "Cats can sleep 12 to 16 hours a day.", featured: [.sparkle]),
        GameCharacter(id: "ollie", name: "Ollie Owl", family: .pets, emoji: "🦉", colorHex: 0x8FD3C8, accessory: .none,
                      fact: "Owls can turn their heads almost all the way around.", featured: [.fortress]),
        GameCharacter(id: "coral", name: "Coral Turtle", family: .pets, emoji: "🐢", colorHex: 0x5EC8E5, accessory: .bow,
                      fact: "Sea turtles can swim thousands of miles across the ocean.", featured: [.sparkle, .rainbow]),
        GameCharacter(id: "sunny", name: "Sunny Chick", family: .pets, emoji: "🐥", colorHex: 0xFFE66D, accessory: .none,
                      fact: "Baby chicks peep to their mom while they're still inside the egg!", featured: [.rainbow]),

        // Hero Squad (original heroes)
        GameCharacter(id: "comet", name: "Captain Comet", family: .heroes, emoji: "🦊", colorHex: 0xFF8A5E, accessory: .cape,
                      fact: "Foxes may use Earth's magnetic field to help them pounce!", featured: [.fortress, .rainbow]),
        GameCharacter(id: "midnight", name: "Midnight Mask", family: .heroes, emoji: "🦝", colorHex: 0x6C7BD9, accessory: .mask,
                      fact: "Raccoons have super-sensitive front paws — almost like tiny hands.", featured: [.fortress]),
        GameCharacter(id: "starspark", name: "Star Spark", family: .heroes, emoji: "🦄", colorHex: 0xF7A8E0, accessory: .cape,
                      fact: "Unicorns are pretend, but real horses can sleep standing up!", featured: [.sparkle]),
        GameCharacter(id: "acorn", name: "Iron Acorn", family: .heroes, emoji: "🐿️", colorHex: 0xC9A27E, accessory: .helmet,
                      fact: "Squirrels bury nuts and can find lots of them again later.", featured: [.fortress]),
        GameCharacter(id: "novawing", name: "Nova Wing", family: .heroes, emoji: "🦋", colorHex: 0x7FD8FF, accessory: .cape,
                      fact: "Butterflies taste with their feet!", featured: [.sparkle, .rainbow]),

        // Garden Gang
        GameCharacter(id: "benny", name: "Benny Banana", family: .garden, emoji: "🍌", colorHex: 0xFFF1A6, accessory: .none,
                      fact: "Bananas are berries — but strawberries aren't!", featured: [.rainbow, .fortress]),
        GameCharacter(id: "stella", name: "Stella Strawberry", family: .garden, emoji: "🍓", colorHex: 0xFFD1DC, accessory: .bow,
                      fact: "Strawberries wear about 200 seeds on the outside.", featured: [.sparkle]),
        GameCharacter(id: "broccoli", name: "Sir Broccoli", family: .garden, emoji: "🥦", colorHex: 0xB7E4A1, accessory: .crown,
                      fact: "Broccoli is a bunch of tiny flower buds we eat before they bloom.", featured: [.fortress]),
        GameCharacter(id: "carlos", name: "Carlos Carrot", family: .garden, emoji: "🥕", colorHex: 0xFFC48C, accessory: .helmet,
                      fact: "Long ago, most carrots were purple or yellow, not orange!", featured: [.rainbow, .fortress]),
        GameCharacter(id: "gigi", name: "Gigi Grape", family: .garden, emoji: "🍇", colorHex: 0xD9C2F0, accessory: .crown,
                      fact: "Raisins are grapes that dried in the sun.", featured: [.sparkle]),
        GameCharacter(id: "avi", name: "Avi Avocado", family: .garden, emoji: "🥑", colorHex: 0xC9E7A7, accessory: .none,
                      fact: "Avocados ripen after they're picked, not on the tree.", featured: [.rainbow]),

        // Zoo Crew
        GameCharacter(id: "leo", name: "Leo Lion", family: .zoo, emoji: "🦁", colorHex: 0xF6C177, accessory: .crown,
                      fact: "A lion's roar can be heard up to 5 miles away.", featured: [.fortress]),
        GameCharacter(id: "zara", name: "Zara Zebra", family: .zoo, emoji: "🦓", colorHex: 0xE5E7EB, accessory: .bow,
                      fact: "Every zebra's stripes are different, like fingerprints.", featured: [.sparkle, .rainbow]),
        GameCharacter(id: "gemma", name: "Gemma Giraffe", family: .zoo, emoji: "🦒", colorHex: 0xFFE0A3, accessory: .none,
                      fact: "Giraffes often nap for just a few minutes at a time.", featured: [.sparkle]),
        GameCharacter(id: "pip", name: "Pip Penguin", family: .zoo, emoji: "🐧", colorHex: 0xBFE3FF, accessory: .none,
                      fact: "Penguins can't fly in the air, but they 'fly' underwater!", featured: [.rainbow, .fortress]),
        GameCharacter(id: "ellie", name: "Ellie Elephant", family: .zoo, emoji: "🐘", colorHex: 0xCBD5E1, accessory: .bow,
                      fact: "Elephants use their trunks to drink, smell, and give hugs.", featured: [.sparkle, .rainbow]),
        GameCharacter(id: "rocky", name: "Rocky Rhino", family: .zoo, emoji: "🦏", colorHex: 0xA7B4C2, accessory: .helmet,
                      fact: "A rhino's horn is made of keratin — the same stuff as your fingernails.", featured: [.fortress]),

        // Wild Pals (v2.3): the village's newest neighbors
        GameCharacter(id: "kip", name: "Kip Koala", family: .wild, emoji: "🐨", colorHex: 0x9AA7B6, accessory: .none,
                      fact: "Koalas sleep up to 20 hours a day and eat eucalyptus leaves.", featured: [.rainbow, .fortress]),
        GameCharacter(id: "fizz", name: "Fizz Frog", family: .wild, emoji: "🐸", colorHex: 0x5FC86A, accessory: .none,
                      fact: "Frogs start life as tadpoles that swim with tails!", featured: [.rainbow]),
        GameCharacter(id: "ocho", name: "Ocho Octopus", family: .wild, emoji: "🐙", colorHex: 0xC77DDB, accessory: .none,
                      fact: "An octopus has three hearts and eight arms.", featured: [.sparkle, .fortress]),
        GameCharacter(id: "flora", name: "Flora Flamingo", family: .wild, emoji: "🦩", colorHex: 0xFF96C2, accessory: .none,
                      fact: "Flamingos are pink because of the tiny shrimp they eat.", featured: [.sparkle]),
        GameCharacter(id: "polly", name: "Polly Panda", family: .wild, emoji: "🐼", colorHex: 0xF1F1F4, accessory: .none,
                      fact: "Pandas spend about 12 hours a day eating bamboo.", featured: [.fortress, .rainbow]),
        GameCharacter(id: "buzzy", name: "Buzzy Bee", family: .wild, emoji: "🐝", colorHex: 0xFFD24D, accessory: .none,
                      fact: "Bees do a waggle dance to tell friends where the flowers are.", featured: [.sparkle, .rainbow]),
    ]

    static func character(id: String) -> GameCharacter {
        all.first { $0.id == id } ?? all[0]
    }

    static func featured(for theme: CastleTheme) -> [GameCharacter] {
        all.filter { $0.featured.contains(theme) }
    }
}
