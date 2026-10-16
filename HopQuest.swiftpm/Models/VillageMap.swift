import Foundation

// Hop Village logic is plain Foundation (no SwiftUI / SpriteKit) so it can be unit-tested on any machine.
//
// Coordinates:
//   GridPoint (c, r)  one tile. r = 0 is the NORTH edge, like the rows of the ASCII map.
//   VPoint (x, y)     a continuous position in tile units. (c + 0.5, r + 0.5) is a tile's center; y grows southward.
// The scene converts to SpriteKit points (y up) when it draws.

struct GridPoint: Hashable, Codable {
    var c: Int
    var r: Int
    init(_ c: Int, _ r: Int) { self.c = c; self.r = r }

    var center: VPoint { VPoint(Double(c) + 0.5, Double(r) + 0.5) }
    func offset(_ dc: Int, _ dr: Int) -> GridPoint { GridPoint(c + dc, r + dr) }
    func manhattan(_ o: GridPoint) -> Int { abs(c - o.c) + abs(r - o.r) }
}

enum GroundTile: Hashable {
    case sheet(col: Int, row: Int)
    case water(mask: Int)
}

struct VPoint: Equatable, Codable {
    var x: Double
    var y: Double
    init(_ x: Double, _ y: Double) { self.x = x; self.y = y }

    static let zero = VPoint(0, 0)
    var tile: GridPoint { GridPoint(Int(floor(x)), Int(floor(y))) }
    var length: Double { (x * x + y * y).squareRoot() }
    func distance(to o: VPoint) -> Double { (self - o).length }
    var normalized: VPoint { let l = length; return l > 1e-9 ? VPoint(x / l, y / l) : .zero }

    static func + (a: VPoint, b: VPoint) -> VPoint { VPoint(a.x + b.x, a.y + b.y) }
    static func - (a: VPoint, b: VPoint) -> VPoint { VPoint(a.x - b.x, a.y - b.y) }
    static func * (a: VPoint, k: Double) -> VPoint { VPoint(a.x * k, a.y * k) }
}

enum Facing: String, Codable, CaseIterable {
    case north, south, east, west

    /// Picks the facing for a movement direction (tile space, y = south).
    static func from(_ d: VPoint, current: Facing) -> Facing {
        if abs(d.x) < 1e-6 && abs(d.y) < 1e-6 { return current }
        if abs(d.x) > abs(d.y) * 1.15 { return d.x > 0 ? .east : .west }
        return d.y > 0 ? .south : .north
    }
}

/// The village grid built from the ASCII map. Legend (one character per tile):
///   .  grass        =  stone path     ~  water          o  lily pad (walk on it!)   #  wooden bridge
///   r  road         z  crosswalk      s  sand           *  flowers (walkable)       m  mushroom (walkable)
///   T  tree         t  bush           F  fence          B  bench    L  lamp         R  rock
///   c  parked car   n  traffic sign   k  crane          b  block pile
///   1 2 3  forest portals (Hop chapters 1, 4, 6)
///   Building footprints: C castle, M museum, A arena, W workshop, D academy, K kart stadium, Y fort shed, Q fountain
struct VillageMap {
    let width: Int
    let height: Int
    private let cells: [[Character]]
    private let walk: [Bool]
    let buildings: [VillageBuilding]
    let portals: [VillagePortal]
    let spawn = GridPoint(20, 22)

    static let walkableChars: Set<Character> = [".", "=", "o", "#", "r", "z", "s", "*", "m", "1", "2", "3"]

    static let shared = VillageMap(rows: VillageMapData.rows)

    init(rows: [String]) {
        cells = rows.map { Array($0) }
        height = cells.count
        width = cells.first?.count ?? 0
        var w = [Bool](repeating: false, count: width * height)
        for r in 0..<height {
            for c in 0..<width where c < cells[r].count {
                w[r * width + c] = VillageMap.walkableChars.contains(cells[r][c])
            }
        }
        walk = w

        // building footprints → bounding boxes
        var boxes: [Character: (Int, Int, Int, Int)] = [:]
        var portals: [VillagePortal] = []
        for r in 0..<height {
            for c in 0..<width where c < cells[r].count {
                let ch = cells[r][c]
                if BuildingKind(rawValue: ch) != nil {
                    if let b = boxes[ch] {
                        boxes[ch] = (min(b.0, c), min(b.1, r), max(b.2, c), max(b.3, r))
                    } else {
                        boxes[ch] = (c, r, c, r)
                    }
                }
                if let n = Int(String(ch)), (1...3).contains(n) {
                    portals.append(VillagePortal(number: n, tile: GridPoint(c, r)))
                }
            }
        }
        buildings = BuildingKind.allCases.compactMap { kind in
            guard let b = boxes[kind.rawValue] else { return nil }
            return VillageBuilding(kind: kind, minC: b.0, minR: b.1, maxC: b.2, maxR: b.3)
        }
        self.portals = portals.sorted { $0.number < $1.number }
    }

    func inBounds(_ p: GridPoint) -> Bool { p.c >= 0 && p.r >= 0 && p.c < width && p.r < height }

    func char(_ p: GridPoint) -> Character? {
        guard inBounds(p) else { return nil }
        return cells[p.r][p.c]
    }

    func char(_ c: Int, _ r: Int) -> Character? { char(GridPoint(c, r)) }

    func isWalkable(_ p: GridPoint) -> Bool {
        inBounds(p) && walk[p.r * width + p.c]
    }

    func isWalkable(_ c: Int, _ r: Int) -> Bool { isWalkable(GridPoint(c, r)) }

    func building(_ kind: BuildingKind) -> VillageBuilding? { buildings.first { $0.kind == kind } }

    /// The building whose footprint contains this tile.
    func building(at p: GridPoint) -> VillageBuilding? {
        buildings.first { $0.contains(p) }
    }

    func portal(at p: GridPoint) -> VillagePortal? { portals.first { $0.tile == p } }

    /// Closest walkable tile to `p` (breadth-first). Used when a child taps a tree, a wall, or water.
    func nearestWalkable(to p: GridPoint, maxRadius: Int = 6) -> GridPoint? {
        if isWalkable(p) { return p }
        for radius in 1...maxRadius {
            var best: GridPoint?
            var bestD = Int.max
            for dr in -radius...radius {
                for dc in -radius...radius where max(abs(dc), abs(dr)) == radius {
                    let q = p.offset(dc, dr)
                    let d = dc * dc + dr * dr
                    if isWalkable(q) && d < bestD { best = q; bestD = d }
                }
            }
            if let best { return best }
        }
        return nil
    }

    // MARK: Drawing helpers (pure, so the README preview and tests use the same rules)

    /// Deterministic per-tile variety.
    static func hash(_ c: Int, _ r: Int) -> Int { ((c &* 73856093) ^ (r &* 19349663)) & 0xffff }

    private static let pathLike: Set<Character> = ["=", "Q", "z", "#"]
    private static let waterLike: Set<Character> = ["~", "o", "#"]

    /// Bit mask of neighbors that are NOT in `like` (1 north, 2 east, 4 south, 8 west). Off-map counts as same.
    func edgeMask(_ c: Int, _ r: Int, like: Set<Character>) -> Int {
        var m = 0
        for (bit, dc, dr) in [(1, 0, -1), (2, 1, 0), (4, 0, 1), (8, -1, 0)] {
            if let n = char(c + dc, r + dr), !like.contains(n) { m |= bit }
        }
        return m
    }

    /// Which ground tile to draw (column and row in the 16 px tile sheet; water is animated).
    func ground(_ c: Int, _ r: Int) -> GroundTile {
        guard let k = char(c, r) else { return .sheet(col: 0, row: 0) }
        switch k {
        case "=", "Q":
            return .sheet(col: edgeMask(c, r, like: Self.pathLike), row: 1)
        case "~", "o":
            return .water(mask: edgeMask(c, r, like: Self.waterLike))
        case "#":
            return .sheet(col: 9, row: 0)
        case "r", "c":
            return .sheet(col: 6, row: 0)
        case "z":
            return .sheet(col: 7, row: 0)
        case "s":
            return .sheet(col: Self.hash(c, r) % 5 == 0 ? 5 : 4, row: 0)
        case "b", "k", "Y":
            let sandy = [(1, 0), (-1, 0), (0, 1), (0, -1)].contains { char(c + $0.0, r + $0.1) == "s" }
            if sandy { return .sheet(col: 4, row: 0) }
        default:
            break
        }
        switch Self.hash(c, r) % 9 {
        case 5: return .sheet(col: 1, row: 0)
        case 6: return .sheet(col: 2, row: 0)
        case 7: return .sheet(col: 3, row: 0)
        default: return .sheet(col: 0, row: 0)
        }
    }

    /// Friendly region names, shown in a banner as the child walks around.
    func regionName(at p: GridPoint) -> String {
        if p.r >= 35 { return "Adventure Forest" }
        if p.c <= 12 && p.r <= 11 { return "Sticker Book Museum" }
        if p.c >= 27 && p.r <= 11 { return "Pillow Bop Arena" }
        if p.r <= 11 { return "My Castle" }
        if p.c <= 11 && p.r <= 23 { return "Robot Workshop" }
        if p.c >= 26 && p.r <= 23 { return "Driving Academy" }
        if p.c <= 14 && p.r >= 26 { return "Construction Yard" }
        if p.c >= 26 && p.r >= 26 { return "Bubble Kart Stadium" }
        return "Village Square"
    }
}
