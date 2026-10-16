import Foundation

/// Every building in Hop Village. The raw value is its footprint letter in the ASCII map.
enum BuildingKind: Character, CaseIterable, Codable {
    case castle = "C"
    case museum = "M"
    case arena = "A"
    case workshop = "W"
    case academy = "D"
    case stadium = "K"
    case fortYard = "Y"
    case fountain = "Q"

    /// Stable id for saves (visited places).
    var id: String {
        switch self {
        case .castle: return "castle"
        case .museum: return "museum"
        case .arena: return "arena"
        case .workshop: return "workshop"
        case .academy: return "academy"
        case .stadium: return "stadium"
        case .fortYard: return "fortyard"
        case .fountain: return "fountain"
        }
    }

    var title: String {
        switch self {
        case .castle: return "My Castle"
        case .museum: return "Sticker Book Museum"
        case .arena: return "Pillow Bop Arena"
        case .workshop: return "Robot Workshop"
        case .academy: return "Driving Academy"
        case .stadium: return "Bubble Kart Stadium"
        case .fortYard: return "Fort Friends Yard"
        case .fountain: return "Wishing Fountain"
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
        case .stadium: return "village_stadium"
        case .fortYard: return "village_shed"
        case .fountain: return ""
        }
    }

    var hasDoor: Bool { self != .fountain }
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

/// A forest portal into one of the existing Hop levels.
struct VillagePortal: Equatable {
    let number: Int
    let tile: GridPoint

    /// Portals 1, 2, 3 lead to Meadow Street, Lily River and Castle Hill.
    var chapterID: Int {
        switch number {
        case 1: return 1
        case 2: return 4
        default: return 6
        }
    }
}

/// What the village asks the app to open. `RootView` turns these into routes, so rewards and
/// progress keep running through the same code as the world map.
enum VillageDestination: Equatable {
    case castle, stickers, bop, fortSelect, kartSelect
    case chapter(Int)          // a story chapter (hop levels, Robot Lab, driving)
}
