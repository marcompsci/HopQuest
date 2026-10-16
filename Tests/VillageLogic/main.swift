import Foundation

// Hop Village logic tests. Run with Tests/VillageLogic/run.sh

var failures = 0
var passes = 0
func check(_ ok: Bool, _ what: String, file: String = #file, line: Int = #line) {
    if ok { passes += 1 } else { failures += 1; print("FAIL [\(line)] \(what)") }
}
func test(_ name: String, _ body: () throws -> Void) {
    let before = failures
    do { try body() } catch { failures += 1; print("FAIL \(name): threw \(error)") }
    print(failures == before ? "  ok   \(name)" : "  FAIL \(name)")
}

let map = VillageMap.shared
let pf = VillagePathfinder(map: map)
let col = VillageCollision(map: map)

/// Every tile reachable from spawn (4-way flood fill).
func reachable(from s: GridPoint) -> Set<GridPoint> {
    var seen: Set<GridPoint> = [s]
    var queue = [s]
    while let p = queue.popLast() {
        for (dc, dr) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let q = p.offset(dc, dr)
            if map.isWalkable(q) && !seen.contains(q) { seen.insert(q); queue.append(q) }
        }
    }
    return seen
}
let fromSpawn = reachable(from: map.spawn)

print("Hop Village logic tests")

test("map is 40 x 48 and rectangular") {
    check(map.width == 40 && map.height == 48, "size \(map.width)x\(map.height)")
    check(VillageMapData.rows.allSatisfy { $0.count == 40 }, "all rows 40 wide")
}

test("map edges are closed (no walking off the world)") {
    for c in 0..<map.width { check(!map.isWalkable(c, 0) && !map.isWalkable(c, map.height - 1), "edge col \(c)") }
    for r in 0..<map.height { check(!map.isWalkable(0, r) && !map.isWalkable(map.width - 1, r), "edge row \(r)") }
}

test("all eight landmarks exist") {
    for k in BuildingKind.allCases { check(map.building(k) != nil, "building \(k)") }
    check(map.portals.map(\.number) == [1, 2, 3], "three portals")
    check(map.portals.map(\.chapterID) == [1, 4, 6], "portals lead to hop chapters 1, 4, 6")
}

test("spawn is walkable and every door, portal, and NPC home is reachable") {
    check(map.isWalkable(map.spawn), "spawn walkable")
    for b in map.buildings where b.kind.hasDoor {
        check(fromSpawn.contains(b.doorstep), "\(b.kind.title) doorstep \(b.doorstep) reachable")
    }
    for p in map.portals { check(fromSpawn.contains(p.tile), "portal \(p.number) reachable") }
    for n in VillageNPCDef.all {
        check(fromSpawn.contains(n.home), "\(n.id) home reachable")
        check(fromSpawn.contains(n.activitySpot), "\(n.id) activity spot reachable")
    }
}

test("doorsteps sit right below each building's footprint") {
    for b in map.buildings where b.kind.hasDoor {
        check(b.contains(b.doorstep.offset(0, -1)), "\(b.kind) door touches its building")
        check(!b.contains(b.doorstep), "\(b.kind) doorstep outside")
    }
}

test("A* finds paths that never touch a blocked tile and never cut corners") {
    var targets: [GridPoint] = map.buildings.filter { $0.kind.hasDoor }.map(\.doorstep) + map.portals.map(\.tile)
    targets += VillageNPCDef.all.map(\.home)
    for t in targets {
        guard let p = pf.path(from: map.spawn, to: t) else { check(false, "no path to \(t)"); continue }
        check(p.first == map.spawn && p.last == t, "endpoints \(t)")
        for (a, b) in zip(p, p.dropFirst()) {
            check(map.isWalkable(b), "walkable \(b)")
            check(max(abs(a.c - b.c), abs(a.r - b.r)) == 1, "adjacent steps")
            if a.c != b.c && a.r != b.r {
                check(map.isWalkable(GridPoint(b.c, a.r)) && map.isWalkable(GridPoint(a.c, b.r)), "no corner cutting at \(a)->\(b)")
            }
        }
    }
}

test("A* returns nil for blocked or unreachable goals") {
    check(pf.path(from: map.spawn, to: GridPoint(0, 0)) == nil, "tree border")
    check(pf.path(from: map.spawn, to: map.building(.castle)!.doorstep.offset(0, -2)) == nil, "inside castle")
    // a walkable tile walled in on every side
    let rows = ["#####", "#...#", "#####", "#.#.#", "#####"].map { $0.replacingOccurrences(of: "#", with: "T") }
    let tiny = VillageMap(rows: rows)
    check(VillagePathfinder(map: tiny).path(from: GridPoint(1, 3), to: GridPoint(3, 3)) == nil, "island tile unreachable")
    check(VillagePathfinder(map: tiny).path(from: GridPoint(1, 1), to: GridPoint(3, 1))?.count == 3, "simple corridor")
}

test("A* is deterministic") {
    let a = pf.path(from: map.spawn, to: map.portals[2].tile)
    let b = pf.path(from: map.spawn, to: map.portals[2].tile)
    check(a == b, "same path twice")
}

test("collision: pushing into walls for 10 seconds never overlaps a blocked tile") {
    let dirs = [VPoint(1, 0), VPoint(-1, 0), VPoint(0, 1), VPoint(0, -1), VPoint(0.7, 0.7), VPoint(-0.7, 0.4)]
    var player = VillagePlayerController(map: map, start: map.spawn)
    for d in dirs {
        player.joystick = d
        for _ in 0..<600 {
            player.step(dt: 1.0 / 60)
            check(col.fits(player.position), "inside wall at \(player.position)")
        }
    }
    // the castle stops you: walk north from its doorstep
    var p2 = VillagePlayerController(map: map, start: map.building(.castle)!.doorstep)
    p2.joystick = VPoint(0, -1)
    for _ in 0..<120 { p2.step(dt: 1.0 / 60) }
    check(p2.position.y >= Double(map.building(.castle)!.maxR + 1) + col.radius - 1e-6, "can't walk into the castle")
}

test("collision slides along walls") {
    // standing below the castle, pushing up-and-right still moves right
    var p = VillagePlayerController(map: map, start: map.building(.castle)!.doorstep)
    let x0 = p.position.x
    p.joystick = VPoint(0.7, -0.7)
    for _ in 0..<30 { p.step(dt: 1.0 / 60) }
    check(p.position.x > x0 + 0.5, "slid sideways along the wall")
}

test("tap-to-move reaches every door and portal") {
    var targets = map.buildings.filter { $0.kind.hasDoor }.map(\.doorstep)
    targets += map.portals.map(\.tile)
    for t in targets {
        var p = VillagePlayerController(map: map, start: map.spawn)
        check(p.walk(to: t), "path to \(t)")
        var frames = 0
        while p.hasPath && frames < 60 * 60 { p.step(dt: 1.0 / 60); frames += 1 }
        check(p.position.distance(to: t.center) < 0.3, "arrived at \(t) (at \(p.position.tile))")
        check(InteractionFinder.find(player: p.position, npcs: [], map: map) != nil, "something to do at \(t)")
    }
}

test("tapping a building or a tree walks to the nearest open tile") {
    var p = VillagePlayerController(map: map, start: map.spawn)
    let castle = map.building(.castle)!
    check(p.walk(to: GridPoint(castle.minC + 3, castle.maxR)), "tap castle wall")
    while p.hasPath { p.step(dt: 1.0 / 60) }
    check(map.isWalkable(p.tile), "ended on a walkable tile")
    check(p.tile.r == castle.maxR + 1, "stopped just in front of the castle")
}

test("joystick overrides a tap path") {
    var p = VillagePlayerController(map: map, start: map.spawn)
    p.walk(to: map.portals[0].tile)
    p.joystick = VPoint(1, 0)
    p.step(dt: 1.0 / 60)
    check(!p.hasPath, "path cleared by joystick")
    check(p.facing == .east, "facing east")
}

test("player movement is deterministic") {
    func run() -> VPoint {
        var p = VillagePlayerController(map: map, start: map.spawn)
        p.walk(to: map.building(.stadium)!.doorstep)
        for i in 0..<400 { if i == 200 { p.joystick = VPoint(-0.3, 0.9) }; p.step(dt: 1.0 / 60) }
        return p.position
    }
    check(run() == run(), "same inputs, same result")
}

test("NPC brains stay near home, return home, and are deterministic") {
    for def in VillageNPCDef.all {
        func simulate() -> [VPoint] {
            var b = NPCBrain(def: def, map: map)
            var trace: [VPoint] = []
            let far = VPoint(2.5, 46.5)           // player far away in the forest corner
            for i in 0..<(60 * 120) {
                _ = b.step(dt: 1.0 / 60, player: far, collision: col, pathfinder: pf)
                check(col.fits(b.position), "\(def.id) never inside a wall")
                if i % 60 == 0 { trace.append(b.position) }
                let limit = max(Double(def.wanderRadius) + 3, def.home.center.distance(to: def.activitySpot.center) + 3)
                check(b.position.distance(to: def.home.center) <= limit, "\(def.id) stays near home/activity")
            }
            return trace
        }
        let a = simulate(), b = simulate()
        check(a == b, "\(def.id) deterministic")
        check(Set(a.map { $0.tile }).count > 2, "\(def.id) actually wanders")
    }
}

test("NPC approaches and greets a nearby player once, then can talk") {
    let def = VillageNPCDef.def("ollie")!
    var b = NPCBrain(def: def, map: map)
    let player = def.home.offset(2, 0).center
    var greets = 0
    var greetDistance = 99.0
    for _ in 0..<(60 * 20) {
        if b.step(dt: 1.0 / 60, player: player, collision: col, pathfinder: pf) == .greet {
            greets += 1
            greetDistance = b.position.distance(to: player)
        }
    }
    check(greets == 1, "greeted exactly once (\(greets))")
    check(greetDistance <= 1.45, "walked over to the player before saying hi (\(greetDistance))")
    b.beginTalk(player: player)
    check(b.mode == .talk, "talk state")
    let pos = b.position
    for _ in 0..<120 { _ = b.step(dt: 1.0 / 60, player: player, collision: col, pathfinder: pf) }
    check(b.position == pos, "doesn't wander off mid-chat")
    b.endTalk()
    check(b.mode == .idle, "back to idle")
}

test("NPC performs its activity on schedule and comes home") {
    let def = VillageNPCDef.def("pip")!
    var b = NPCBrain(def: def, map: map)
    var performed = false, returned = false
    for _ in 0..<(60 * 90) {
        _ = b.step(dt: 1.0 / 60, player: VPoint(2.5, 2.5), collision: col, pathfinder: pf)
        if b.isPerforming { performed = true; check(b.position.distance(to: def.activitySpot.center) < 1.6, "performs at its spot") }
        if performed && b.mode == .returnHome { returned = true }
    }
    check(performed, "did its activity")
    check(returned, "headed home afterwards")
}

test("NPC never uses the player's own buddy") {
    let d = VillageNPCDef.def("ollie")!
    check(d.characterID(avoiding: "ollie") == "gemma", "fallback")
    check(d.characterID(avoiding: "lavender") == "ollie", "normal")
}

test("interaction finder picks the nearest thing") {
    let castle = map.building(.castle)!
    check(InteractionFinder.find(player: castle.doorstep.center, npcs: [], map: map) == .enter(.castle), "door")
    let nearDoor = castle.doorstep.center + VPoint(-0.8, 0)
    check(InteractionFinder.find(player: nearDoor, npcs: [("x", nearDoor + VPoint(-0.5, 0))], map: map) == .talk(npcID: "x"), "a buddy right beside you beats a door farther away")
    check(InteractionFinder.find(player: map.spawn.center, npcs: [], map: map) == nil, "nothing in the square")
    check(InteractionFinder.find(player: map.portals[1].tile.center, npcs: [], map: map) == .portal(2), "portal")
    check(InteractionFinder.find(player: map.spawn.center, npcs: [("a", map.spawn.center + VPoint(1.2, 0)), ("b", map.spawn.center + VPoint(0.7, 0))], map: map) == .talk(npcID: "b"), "closest buddy")
}

test("save state: decodes from empty JSON, old versions, and round-trips") {
    let empty = try JSONDecoder().decode(VillageSaveState.self, from: Data("{}".utf8))
    check(empty == VillageSaveState(), "empty → defaults")
    check(empty.safeSpawn(in: map) == map.spawn, "default spawn is the square")

    let v1 = #"{"version":1,"tileX":7,"tileY":9,"facing":"north","solved":["ollie"],"futureField":42}"#
    let s = try JSONDecoder().decode(VillageSaveState.self, from: Data(v1.utf8))
    check(s.tile == GridPoint(7, 9) && s.facing == .north && s.solved == ["ollie"], "v1 fields kept, unknown ignored")

    let bad = #"{"tileX":"oops","facing":"upward"}"#
    let b = try JSONDecoder().decode(VillageSaveState.self, from: Data(bad.utf8))
    check(b.tile == GridPoint(20, 22) && b.facing == .south, "bad values fall back safely")

    var full = VillageSaveState()
    full.tile = GridPoint(33, 20); full.visited = ["castle"]; full.talkedTo = ["pip"]; full.lightEffects = true; full.startInVillage = true
    let back = try JSONDecoder().decode(VillageSaveState.self, from: JSONEncoder().encode(full))
    check(back == full, "round trip")

    var blocked = VillageSaveState(); blocked.tile = GridPoint(0, 0)
    check(blocked.safeSpawn(in: map) == map.spawn, "unwalkable saved tile → spawn")
}

test("save state nests inside an older profile JSON without breaking it") {
    struct MiniProfile: Codable { var name: String; var village: VillageSaveState? }
    let old = #"{"name":"Ava"}"#
    let p = try JSONDecoder().decode(MiniProfile.self, from: Data(old.utf8))
    check(p.name == "Ava" && p.village == nil, "old save has no village block")
    check((p.village ?? VillageSaveState()).safeSpawn(in: map) == map.spawn, "defaults to spawn")
}

test("camera clamps to the world and follows smoothly") {
    let c = VillageCameraMath.clamp((x: 0, y: 0), view: (w: 400, h: 800), world: (w: 1920, h: 2304))
    check(c.x == 200 && c.y == 400, "clamped corner")
    let mid = VillageCameraMath.clamp((x: 900, y: 1000), view: (w: 400, h: 800), world: (w: 1920, h: 2304))
    check(mid.x == 900 && mid.y == 1000, "inside unchanged")
    var x = 0.0
    for _ in 0..<120 { x = VillageCameraMath.follow(x, 100, dt: 1.0 / 60) }
    check(abs(x - 100) < 0.5, "settles on target")
}

test("A* performance: 200 cross-map paths") {
    let start = Date()
    for i in 0..<200 {
        let a = map.portals[i % 3].tile
        let b = map.buildings[i % 7].doorstep
        _ = pf.path(from: a, to: b)
    }
    let ms = Date().timeIntervalSince(start) * 1000
    print(String(format: "       (%.1f ms total, %.2f ms per path)", ms, ms / 200))
    check(ms / 200 < 5, "under 5 ms per path")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
