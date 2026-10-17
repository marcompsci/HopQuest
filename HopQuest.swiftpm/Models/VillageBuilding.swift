import Foundation

/// Every building in Hop Village: one for each HopQuest game. The raw value is its footprint letter in the ASCII map.
enum BuildingKind: Character, CaseIterable, Codable {
    case castle = "C"
    case museum = "M"
    case arena = "A"
    case workshop = "W"
    case academy = "D"
    case garage = "X"
    case stadium = "K"
    case fortYard = "Y"
    case clubhouse = "U"
    case cottage = "G"
    case boathouse = "V"
    case tower = "H"
    case codingLab = "P"
    case home = "J"
    case fountain = "Q"
    case nook = "N"

    /// Stable id for saves (visited places).
    var id: String {
        switch self {
        case .castle: return "castle"
        case .museum: return "museum"
        case .arena: return "arena"
        case .workshop: return "workshop"
        case .academy: return "academy"
        case .garage: return "garage"
        case .stadium: return "stadium"
        case .fortYard: return "fortyard"
        case .clubhouse: return "clubhouse"
        case .cottage: return "cottage"
        case .boathouse: return "boathouse"
        case .tower: return "tower"
        case .codingLab: return "codinglab"
        case .home: return "home"
        case .fountain: return "fountain"
        case .nook: return "nook"
        }
    }

    /// The game inside, as kids know it from the menu.
    var title: String {
        switch self {
        case .castle: return "My Castle"
        case .museum: return "Sticker Book"
        case .arena: return "Pillow Bop"
        case .workshop: return "Robot Lab"
        case .academy: return "Driving School"
        case .garage: return "City Rally"
        case .stadium: return "Bubble Kart"
        case .fortYard: return "Fort Friends"
        case .clubhouse: return "Together Club"
        case .cottage: return "Meadow Street"
        case .boathouse: return "Lily River"
        case .tower: return "Castle Hill"
        case .codingLab: return "Coding Lab"
        case .home: return "My House"
        case .fountain: return "Wishing Fountain"
        case .nook: return "Reading Nook"
        }
    }

    /// Art name in the asset catalog (the castle adds the castle style).
    var art: String {
        switch self {
        case .castle: return "village_castle"
        case .museum: return "village_museum"
        case .arena: return "village_arena"
        case .workshop: return "village_workshop"
        case .academy: return "village_academy"
        case .garage: return "village_garage"
        case .stadium: return "village_stadium"
        case .fortYard: return "village_shed"
        case .clubhouse: return "village_clubhouse"
        case .cottage: return "village_cottage"
        case .boathouse: return "village_boathouse"
        case .tower: return "village_tower"
        case .codingLab: return "village_codinglab"
        case .home: return ""          // drawn from layers (see HomeStyle)
        case .fountain: return ""
        case .nook: return "village_nook"
        }
    }

    var hasDoor: Bool { self != .fountain }

    /// The story chapter this building opens (hop levels, driving, Robot Lab).
    var storyChapter: Int? {
        switch self {
        case .cottage: return 1
        case .academy: return 2
        case .workshop: return 3
        case .boathouse: return 4
        case .garage: return 5
        case .tower: return 6
        default: return nil
        }
    }

    /// The challenge this building counts toward (nil for the museum, clubhouse, castle and fountain).
    var challenge: VillageChallenge? { VillageChallenge.allCases.first { $0.building == self } }
}

struct VillageBuilding: Equatable {
    let kind: BuildingKind
    let minC: Int, minR: Int, maxC: Int, maxR: Int

    func contains(_ p: GridPoint) -> Bool {
        p.c >= minC && p.c <= maxC && p.r >= minR && p.r <= maxR
    }

    var widthTiles: Int { maxC - minC + 1 }
    var heightTiles: Int { maxR - minR + 1 }

    /// The tile just outside the front door (doors face south).
    var doorstep: GridPoint { GridPoint((minC + maxC + 1) / 2, maxR + 1) }

    /// Bottom-center of the footprint in tile units (where the art stands).
    var foot: VPoint { VPoint(Double(minC + maxC + 1) / 2, Double(maxR + 1)) }
}

/// What the village asks the app to open. `RootView` turns these into routes, so rewards and
/// progress keep running through the same code as the menu and the world map.
enum VillageDestination: Equatable {
    case castle, stickers, bop, fortSelect, kartSelect, together, codingLab, readingNook
    case chapter(Int)          // a story chapter (hop levels, Robot Lab, driving)
}
