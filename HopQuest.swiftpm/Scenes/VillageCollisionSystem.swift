import Foundation

/// Box-vs-grid collision on the logical tile grid (independent of the artwork).
/// The mover is a small square of half-size `radius`, resolved one axis at a time so it slides along walls.
struct VillageCollision {
    let map: VillageMap
    var radius: Double = 0.28
    private let eps = 1e-4

    func blocked(_ c: Int, _ r: Int) -> Bool { !map.isWalkable(c, r) }

    /// True if a mover centered at `p` overlaps no blocked tile.
    func fits(_ p: VPoint) -> Bool {
        let c0 = Int(floor(p.x - radius + eps)), c1 = Int(floor(p.x + radius - eps))
        let r0 = Int(floor(p.y - radius + eps)), r1 = Int(floor(p.y + radius - eps))
        for r in r0...r1 {
            for c in c0...c1 where blocked(c, r) { return false }
        }
        return true
    }

    /// Moves from `p` by `d`, stopping at walls. Deterministic for the same inputs.
    func move(_ p: VPoint, by d: VPoint) -> VPoint {
        // sub-step so a fast frame can never tunnel through a one-tile wall
        let steps = max(1, Int(ceil(max(abs(d.x), abs(d.y)) / (radius * 0.9))))
        var pos = p
        let sx = d.x / Double(steps), sy = d.y / Double(steps)
        for _ in 0..<steps {
            pos = moveAxisX(pos, sx)
            pos = moveAxisY(pos, sy)
        }
        return pos
    }

    private func moveAxisX(_ p: VPoint, _ dx: Double) -> VPoint {
        guard dx != 0 else { return p }
        var x = p.x + dx
        let r0 = Int(floor(p.y - radius + eps)), r1 = Int(floor(p.y + radius - eps))
        if dx > 0 {
            let col = Int(floor(x + radius - eps))
            for r in r0...r1 where blocked(col, r) { x = Double(col) - radius; break }
        } else {
            let col = Int(floor(x - radius))
            for r in r0...r1 where blocked(col, r) { x = Double(col + 1) + radius; break }
        }
        return VPoint(x, p.y)
    }

    private func moveAxisY(_ p: VPoint, _ dy: Double) -> VPoint {
        guard dy != 0 else { return p }
        var y = p.y + dy
        let c0 = Int(floor(p.x - radius + eps)), c1 = Int(floor(p.x + radius - eps))
        if dy > 0 {
            let row = Int(floor(y + radius - eps))
            for c in c0...c1 where blocked(c, row) { y = Double(row) - radius; break }
        } else {
            let row = Int(floor(y - radius))
            for c in c0...c1 where blocked(c, row) { y = Double(row + 1) + radius; break }
        }
        return VPoint(p.x, y)
    }

    /// Can a mover slide in a straight line from a to b? (used to smooth A* paths)
    func clearLine(_ a: VPoint, _ b: VPoint) -> Bool {
        let d = b - a
        let n = max(1, Int(ceil(d.length / 0.2)))
        for i in 0...n {
            let t = Double(i) / Double(n)
            if !fits(a + d * t) { return false }
        }
        return true
    }
}

/// A* on the tile grid: 8 directions, no cutting corners past blocked tiles.
struct VillagePathfinder {
    let map: VillageMap
    var maxExpanded = 6000

    func path(from start: GridPoint, to goal: GridPoint) -> [GridPoint]? {
        guard map.isWalkable(start), map.isWalkable(goal) else { return nil }
        if start == goal { return [start] }
        let w = map.width
        func idx(_ p: GridPoint) -> Int { p.r * w + p.c }
        func h(_ p: GridPoint) -> Double {
            let dx = Double(abs(p.c - goal.c)), dy = Double(abs(p.r - goal.r))
            return max(dx, dy) + (2.0.squareRoot() - 1) * min(dx, dy)
        }

        var g = [Double](repeating: .infinity, count: w * map.height)
        var came = [Int](repeating: -1, count: w * map.height)
        var closed = [Bool](repeating: false, count: w * map.height)
        var open = MinHeap()
        g[idx(start)] = 0
        open.push(h(start), idx(start), tie: 0)
        var expanded = 0
        var order = 0

        let dirs: [(Int, Int, Double)] = [(1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1),
                                          (1, 1, 2.0.squareRoot()), (1, -1, 2.0.squareRoot()),
                                          (-1, 1, 2.0.squareRoot()), (-1, -1, 2.0.squareRoot())]
        while let (_, cur) = open.pop() {
            if closed[cur] { continue }
            closed[cur] = true
            let p = GridPoint(cur % w, cur / w)
            if p == goal { break }
            expanded += 1
            if expanded > maxExpanded { return nil }
            for (dc, dr, cost) in dirs {
                let q = p.offset(dc, dr)
                guard map.isWalkable(q) else { continue }
                if dc != 0 && dr != 0 {
                    // no squeezing diagonally between two blocked tiles or past a corner
                    if !map.isWalkable(p.offset(dc, 0)) || !map.isWalkable(p.offset(0, dr)) { continue }
                }
                let qi = idx(q)
                if closed[qi] { continue }
                let ng = g[cur] + cost
                if ng < g[qi] {
                    g[qi] = ng
                    came[qi] = cur
                    order += 1
                    open.push(ng + h(q), qi, tie: order)
                }
            }
        }
        guard g[idx(goal)].isFinite else { return nil }
        var out: [GridPoint] = []
        var i = idx(goal)
        while i != -1 {
            out.append(GridPoint(i % w, i / w))
            i = came[i]
        }
        return out.reversed()
    }

    /// Path as waypoints (tile centers), with straight runs merged by line-of-sight.
    func waypoints(from start: VPoint, to goal: GridPoint, collision: VillageCollision) -> [VPoint]? {
        guard let tiles = path(from: start.tile, to: goal) else { return nil }
        let pts = tiles.map { $0.center }
        var out: [VPoint] = []
        var anchor = start
        var i = 0
        while i < pts.count {
            // jump to the farthest point we can see from the anchor
            var j = pts.count - 1
            while j > i && !collision.clearLine(anchor, pts[j]) { j -= 1 }
            out.append(pts[j])
            anchor = pts[j]
            i = j + 1
        }
        return out
    }
}

/// Small binary heap of (priority, value). Ties break by insertion order, so results are deterministic.
struct MinHeap {
    private var items: [(Double, Int, Int)] = []

    mutating func push(_ priority: Double, _ value: Int, tie: Int) {
        items.append((priority, tie, value))
        var i = items.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            if less(items[i], items[parent]) { items.swapAt(i, parent); i = parent } else { break }
        }
    }

    mutating func pop() -> (Double, Int)? {
        guard let first = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < items.count && less(items[l], items[m]) { m = l }
                if r < items.count && less(items[r], items[m]) { m = r }
                if m == i { break }
                items.swapAt(i, m); i = m
            }
        }
        return (first.0, first.2)
    }

    private func less(_ a: (Double, Int, Int), _ b: (Double, Int, Int)) -> Bool {
        a.0 < b.0 || (a.0 == b.0 && a.1 < b.1)
    }
}

/// Deterministic random numbers (SplitMix64) so NPCs behave the same for the same seed.
struct VillageRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    mutating func int(_ range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }
}
