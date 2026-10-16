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

test("map is 44 x 54 and rectangular") {
    check(map.width == 44 && map.height == 54, "size \(map.width)x\(map.height)")
    check(VillageMapData.rows.allSatisfy { $0.count == 44 }, "all rows 44 wide")
}

test("map edges are closed (no walking off the world)") {
    for c in 0..<map.width { check(!map.isWalkable(c, 0) && !map.isWalkable(c, map.height - 1), "edge col \(c)") }
    for r in 0..<map.height { check(!map.isWalkable(0, r) && !map.isWalkable(map.width - 1, r), "edge row \(r)") }
}

test("every game has a building") {
    for k in BuildingKind.allCases { check(map.building(k) != nil, "building \(k)") }
    let chapters = map.buildings.compactMap(\.kind.storyChapter).sorted()
    check(chapters == [1, 2, 3, 4, 5, 6], "a building for each story chapter: \(chapters)")
    check(Set(VillageChallenge.allCases.map(\.building)).count == 10, "ten challenge buildings")
    for c in VillageChallenge.allCases { check(map.building(c.building) != nil, "\(c) building on the map") }
}

test("spawn is walkable and every door and NPC home is reachable") {
    check(map.isWalkable(map.spawn), "spawn walkable")
    for b in map.buildings where b.kind.hasDoor {
        check(fromSpawn.contains(b.doorstep), "\(b.kind.title) doorstep \(b.doorstep) reachable")
    }
    for n in VillageNPCDef.everyone {
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
    var targets: [GridPoint] = map.buildings.filter { $0.kind.hasDoor }.map(\.doorstep)
    targets += VillageNPCDef.everyone.map(\.home)
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
    let a = pf.path(from: map.spawn, to: map.building(.tower)!.doorstep)
    let b = pf.path(from: map.spawn, to: map.building(.tower)!.doorstep)
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

test("tap-to-move reaches every door") {
    let targets = map.buildings.filter { $0.kind.hasDoor }.map(\.doorstep)
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

test("Hop button: hops forward about 2 tiles, never into walls, joystick waits") {
    var p = VillagePlayerController(map: map, start: map.spawn, facing: .south)
    let start = p.position
    check(p.hopForward(), "hop starts")
    check(!p.hopForward(), "no double hop mid-air")
    p.joystick = VPoint(1, 0)
    var frames = 0
    var peak = 0.0
    while p.isHopping && frames < 120 { p.step(dt: 1.0 / 60); peak = max(peak, p.hopHeight); frames += 1
        check(col.fits(p.position), "never inside a wall mid-hop") }
    check(abs(p.position.y - start.y - VillagePlayerController.hopDistance) < 1e-6 && p.position.x == start.x, "landed 2 tiles south (\(p.position))")
    check(p.justLanded, "landing reported")
    check(abs(frames - Int(VillagePlayerController.hopDuration * 60)) <= 1, "takes the hop duration (\(frames) frames)")
    check(peak > 0.95, "rises to full height")
    p.step(dt: 1.0 / 60)
    check(p.position.x > start.x, "joystick works again after landing")

    // hop toward the castle wall: stops at the wall
    let castle = map.building(.castle)!
    var q = VillagePlayerController(map: map, start: castle.doorstep, facing: .north)
    q.hopForward()
    for _ in 0..<60 { q.step(dt: 1.0 / 60) }
    check(col.fits(q.position) && q.position.y >= Double(castle.maxR + 1) + col.radius - 1e-6, "can't hop into the castle")
    // hop toward water: lands on the shore
    var w = VillagePlayerController(map: map, start: GridPoint(17, 46), facing: .east)
    w.hopForward()
    for _ in 0..<60 { w.step(dt: 1.0 / 60) }
    check(col.fits(w.position) && map.isWalkable(w.tile), "stops at the water's edge")
}

test("joystick overrides a tap path") {
    var p = VillagePlayerController(map: map, start: map.spawn)
    p.walk(to: map.building(.cottage)!.doorstep)
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
    for def in VillageNPCDef.everyone {
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
    check(InteractionFinder.find(player: map.building(.boathouse)!.doorstep.center, npcs: [], map: map) == .enter(.boathouse), "hop building")
    let spot = map.spawn.center
    check(InteractionFinder.find(player: spot, npcs: [], peers: [("p1", spot + VPoint(1.0, 0))], map: map) == .challenge(peerKey: "p1"), "live player in reach")
    check(InteractionFinder.find(player: spot, npcs: [], peers: [("p1", spot + VPoint(3, 0))], map: map) == nil, "live player too far")
    check(InteractionFinder.find(player: map.spawn.center, npcs: [("a", map.spawn.center + VPoint(1.2, 0)), ("b", map.spawn.center + VPoint(0.7, 0))], map: map) == .talk(npcID: "b"), "closest buddy")
}

test("save state: decodes from empty JSON, old versions, and round-trips") {
    let empty = try JSONDecoder().decode(VillageSaveState.self, from: Data("{}".utf8))
    check(empty == VillageSaveState(), "empty → defaults")
    check(empty.safeSpawn(in: map) == map.spawn, "default spawn is the square")

    let v1 = #"{"version":1,"tileX":7,"tileY":9,"facing":"north","solved":["ollie"],"futureField":42}"#
    let s = try JSONDecoder().decode(VillageSaveState.self, from: Data(v1.utf8))
    check(s.tile == map.spawn && s.solved == ["ollie"] && s.version == 2, "v1 save: progress kept, old-map spot moved to the square")
    let v2 = #"{"version":2,"tileX":7,"tileY":9,"facing":"north","playMode":"friends","futureField":42}"#
    let s2 = try JSONDecoder().decode(VillageSaveState.self, from: Data(v2.utf8))
    check(s2.tile == GridPoint(7, 9) && s2.facing == .north && s2.playMode == .friends, "v2 fields kept, unknown ignored")

    let bad = #"{"tileX":"oops","facing":"upward"}"#
    let b = try JSONDecoder().decode(VillageSaveState.self, from: Data(bad.utf8))
    check(b.tile == GridPoint(22, 23) && b.facing == .south, "bad values fall back safely")

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
        let a = map.buildings[(i + 5) % map.buildings.count].doorstep
        let b = map.buildings[i % map.buildings.count].doorstep
        _ = pf.path(from: a, to: b)
    }
    let ms = Date().timeIntervalSince(start) * 1000
    print(String(format: "       (%.1f ms total, %.2f ms per path)", ms, ms / 200))
    check(ms / 200 < 5, "under 5 ms per path")
}

test("challenges: nine of them, read from existing progress") {
    var p = ChallengeProgress()
    check(p.doneCount == 0 && !p.allDone, "nothing done")
    p.completedChapters = [1, 2, 3]
    check(p.done == [.meadow, .driving, .robot], "story chapters count")
    p.completedChapters = [1, 2, 3, 4, 5, 6]
    p.fortDone = true; p.bopDone = true
    check(p.doneCount == 8 && !p.allDone, "8 of 10")
    p.kartDone = true
    check(!p.allDone, "coding still to do")
    p.codingDone = true
    check(p.allDone && ChallengeProgress.total == 10, "all done opens the castle")
    for c in VillageChallenge.allCases { check(c.building.challenge == c, "\(c) maps back from its building") }
    check(BuildingKind.castle.challenge == nil && BuildingKind.clubhouse.challenge == nil, "castle and clubhouse aren't challenges")
}

test("pop-quiz buddy walks up after 2 minutes of play, then leaves") {
    var courier = QuizCourier(seed: 5)
    let player = map.spawn.center
    var arrivedAt: Double?
    var t = 0.0
    // frozen time (a dialogue open) doesn't count
    for _ in 0..<(60 * 200) { _ = courier.step(dt: 1.0 / 60, active: false, player: player, collision: col, pathfinder: pf) }
    check(courier.phase == .waiting, "paused while not exploring")
    while t < 200 {
        if courier.step(dt: 1.0 / 60, active: true, player: player, collision: col, pathfinder: pf) == .arrived { arrivedAt = t; break }
        if courier.isVisible { check(col.fits(courier.position), "courier never in a wall") }
        t += 1.0 / 60
    }
    check(arrivedAt != nil && arrivedAt! >= QuizCourier.interval, "arrived after 2 min (\(arrivedAt ?? -1))")
    check(courier.position.distance(to: player) <= 1.45, "right next to the player")
    courier.finish(collision: col, pathfinder: pf)
    for _ in 0..<(60 * 25) { _ = courier.step(dt: 1.0 / 60, active: true, player: player, collision: col, pathfinder: pf) }
    check(courier.phase == .waiting && courier.clock < 30, "left and the timer restarted")
}

test("pop-quiz buddy finds players anywhere on the map") {
    for b in map.buildings where b.kind.hasDoor {
        var courier = QuizCourier(seed: 9)
        courier.forceSoon()
        var arrived = false
        for _ in 0..<(60 * 45) {
            if courier.step(dt: 1.0 / 60, active: true, player: b.doorstep.center, collision: col, pathfinder: pf) == .arrived { arrived = true; break }
        }
        check(arrived, "reached a player at \(b.kind.title)")
    }
}

test("follow-up questions: every item is well formed") {
    for c in VillageChallenge.allCases {
        let items = FollowUpBank.items(for: c)
        check(items.count >= 2, "\(c) has follow-ups")
        for q in items + FollowUpBank.general {
            check((2...4).contains(q.choices.count) && !q.prompt.isEmpty && !q.explain.isEmpty, "well formed: \(q.prompt)")
            check(["Math", "Road Safety", "Nature", "Science", "Words", "Coding", "Kindness"].contains(q.subject), "known subject \(q.subject)")
        }
    }
    check(FollowUpBank.pick(done: [], turn: 3) == FollowUpBank.general[0], "general when nothing is done")
    check(FollowUpBank.items(for: .driving).contains(FollowUpBank.pick(done: [.driving], turn: 7)), "about a finished game")
}

test("bonus and duel stars are capped per day (no streaks)") {
    var v = VillageSaveState()
    check(v.grantBonus(1, day: "2026-10-16") == 1, "first bonus")
    for _ in 0..<10 { _ = v.grantBonus(1, day: "2026-10-16") }
    check(v.bonusToday == VillageSaveState.bonusPerDay, "capped at \(VillageSaveState.bonusPerDay)")
    check(v.grantBonus(1, day: "2026-10-16") == 0, "no more today")
    check(v.grantBonus(1, day: "2026-10-17") == 1, "fresh tomorrow")
    check(v.grantDuelStars(2, day: "d") == 2 && v.grantDuelStars(9, day: "d") == 4, "duel cap 6")
}

func sampleSetup() -> DuelSetup {
    DuelSetup(duelID: "d1", players: ["a", "b"], questions: (0..<5).map {
        DuelQuestion(subject: "Math", prompt: "Q\($0)", choices: ["1", "2", "3"], answer: $0 % 3)
    })
}

test("brain duel: scoring, speed bonus, winner and stars") {
    var duel = BrainDuel(setup: sampleSetup())
    for i in 0..<5 {
        duel.record(DuelAnswer(duelID: "d1", player: "a", index: i, choice: i % 3, ms: 1500))      // all right, quick
        duel.record(DuelAnswer(duelID: "d1", player: "b", index: i, choice: i < 3 ? i % 3 : -1, ms: 8000))
    }
    check(duel.isFinished, "finished")
    check(duel.score("a") == 5 * (10 + 4), "a: 5 right with speed bonus (\(duel.score("a")))")
    check(duel.score("b") == 3 * 10 && duel.correctCount("b") == 3, "b: 3 right, slow")
    check(duel.winners == ["a"] && duel.stars(for: "a") == 2 && duel.stars(for: "b") == 1, "winner 2 stars, good try 1")
    check(!duel.record(DuelAnswer(duelID: "d1", player: "a", index: 0, choice: 1, ms: 1)), "no changing answers")
    check(!duel.record(DuelAnswer(duelID: "d1", player: "z", index: 0, choice: 1, ms: 1)), "strangers ignored")
    check(!duel.record(DuelAnswer(duelID: "other", player: "a", index: 1, choice: 1, ms: 1)), "other duels ignored")
}

test("brain duel: tie gives both a star; unfinished gives none") {
    var duel = BrainDuel(setup: sampleSetup())
    for i in 0..<5 {
        duel.record(DuelAnswer(duelID: "d1", player: "a", index: i, choice: i % 3, ms: 9000))
        if i < 4 { duel.record(DuelAnswer(duelID: "d1", player: "b", index: i, choice: i % 3, ms: 9000)) }
    }
    check(!duel.isFinished && duel.stars(for: "a") == 0, "not finished yet")
    duel.record(DuelAnswer(duelID: "d1", player: "b", index: 4, choice: 4 % 3, ms: 99_999))   // clamped to 20 s
    check(duel.isFinished && duel.winners.count == 2 && duel.stars(for: "a") == 1 && duel.stars(for: "b") == 1, "tie")
    var bad = BrainDuel(setup: sampleSetup())
    bad.record(DuelAnswer(duelID: "d1", player: "a", index: 0, choice: 42, ms: 100))
    check(bad.correctCount("a") == 0, "nonsense choice counts as no answer")
}

test("network messages: round trip, and junk from other phones is rejected or cleaned") {
    let chars: Set<String> = ["ollie", "lavender"]
    let size = (w: 44, h: 54)
    let hello = VillageNetMessage.hello(PeerHello(key: "k1", nick: "Ava", characterID: "ollie", version: 1))
    check(VillageNetMessage.decode(hello.encoded()!, validCharacters: chars, mapSize: size) == hello, "hello round trip")
    let rude = VillageNetMessage.hello(PeerHello(key: "k1", nick: "<script>Ava!!🙂 the great and powerful", characterID: "ollie", version: 1))
    if case .hello(let h)? = VillageNetMessage.decode(rude.encoded()!, validCharacters: chars, mapSize: size) {
        check(h.nick == "scriptAva th", "nick cleaned to 12 safe characters (\(h.nick))")
    } else { check(false, "nick should be cleaned, not dropped") }
    let fake = VillageNetMessage.hello(PeerHello(key: "k1", nick: "x", characterID: "mickey", version: 1))
    check(VillageNetMessage.decode(fake.encoded()!, validCharacters: chars, mapSize: size) == nil, "unknown buddy rejected")
    let far = VillageNetMessage.move(PeerMove(key: "k1", x: 9999, y: -5, facing: .east, moving: true))
    if case .move(let m)? = VillageNetMessage.decode(far.encoded()!, validCharacters: chars, mapSize: size) {
        check(m.x == 44 && m.y == 0, "positions clamped to the map")
    } else { check(false, "move should decode") }
    check(VillageNetMessage.decode(Data("not json".utf8), validCharacters: chars, mapSize: size) == nil, "garbage ignored")
    check(VillageNetMessage.decode(Data(repeating: 65, count: 20_000), validCharacters: chars, mapSize: size) == nil, "huge ignored")
    let start = VillageNetMessage.start(sampleSetup())
    check(VillageNetMessage.decode(start.encoded()!, validCharacters: chars, mapSize: size) == start, "duel setup round trip")
    var badSetup = sampleSetup(); badSetup.questions[0].answer = 7
    check(VillageNetMessage.decode(VillageNetMessage.start(badSetup).encoded()!, validCharacters: chars, mapSize: size) == nil, "broken question rejected")
    check(VillageNetMessage.decode(VillageNetMessage.leave("bad key!").encoded()!, validCharacters: chars, mapSize: size) == nil, "bad key rejected")
}

test("remote players glide smoothly and snap across big jumps") {
    var peer = RemotePeer(hello: PeerHello(key: "k", nick: "Ava", characterID: "ollie", version: 1), at: VPoint(10, 10))
    peer.apply(PeerMove(key: "k", x: 11, y: 10, facing: .east, moving: true), now: 1)
    peer.advance(dt: 1.0 / 60)
    check(peer.shown.x > 10 && peer.shown.x < 11, "moving toward the new spot")
    for _ in 0..<60 { peer.advance(dt: 1.0 / 60) }
    check(abs(peer.shown.x - 11) < 0.01, "arrived")
    peer.apply(PeerMove(key: "k", x: 30, y: 40, facing: .south, moving: false), now: 2)
    check(peer.shown == VPoint(30, 40), "big jump snaps")
}

test("missions: every item spot is reachable (hops count) and missions advance") {
    // reachable by walking, or by hopping over water from a reachable tile
    var reach = reachable(from: map.spawn)
    var grew = true
    while grew {
        grew = false
        for t in reach {
            for (dc, dr) in [(2, 0), (-2, 0), (0, 2), (0, -2)] {
                let q = t.offset(dc, dr)
                guard !reach.contains(q), map.isWalkable(q), map.char(t.offset(dc / 2, dr / 2)) == "~" else { continue }
                for r in reachable(from: q) where !reach.contains(r) { reach.insert(r); grew = true }
                reach.insert(q); grew = true
            }
        }
    }
    for m in MissionCatalog.all {
        check(VillageNPCDef.def(m.giver) != nil, "\(m.id) giver exists")
        for step in m.steps {
            switch step {
            case .collect(_, let spots, _): for p in spots { check(reach.contains(p), "\(m.id) item at \(p) reachable") }
            case .talk(let npc, _, _): check(VillageNPCDef.def(npc) != nil, "\(m.id) talks to a real buddy")
            case .codeLessons(let n, _): check(n > 0, "code mission")
            }
        }
    }
    var save = MissionSave()
    let gears = MissionCatalog.mission("gears")!
    check(save.status(gears) == .new && save.pickups().isEmpty, "no items before starting")
    save.start(gears)
    check(save.status(gears) == .active(step: 0) && save.pickups().count == 5, "5 gears appear")
    for p in save.pickups() { save.collect(p.key) }
    check(save.status(gears) == .readyToTurnIn && save.pickups().isEmpty, "all found → go back")
    check(save.turnIn(gears) && !save.turnIn(gears), "reward once")
    let mail = MissionCatalog.mission("mail")!
    save.start(mail)
    check(save.talked(to: "stella") == nil, "wrong order doesn't count")
    check(save.talked(to: "pip")?.0 == mail && save.talked(to: "stella")?.0 == mail, "deliveries in order")
    check(save.status(mail) == .readyToTurnIn, "mail ready")
    let code = MissionCatalog.mission("code")!
    save.start(code); save.codeLessonsDone(2)
    check(save.status(code) == .active(step: 0), "2 lessons isn't enough")
    save.codeLessonsDone(3)
    check(save.status(code) == .readyToTurnIn, "3 lessons done")
    check(save.collect("nonsense.0.0") == nil, "unknown items ignored")
    let back = try JSONDecoder().decode(MissionSave.self, from: JSONEncoder().encode(save))
    check(back == save, "mission save round trip")
}

test("Hop crosses water onto lily pads, but never over trees") {
    var p = VillagePlayerController(map: map, start: GridPoint(17, 49), facing: .east)
    p.step(dt: 1.0 / 60)
    // walk onto the first pad, then hop pad to pad
    p.place(at: GridPoint(18, 49), facing: .east)
    for expected in [20, 22, 24, 26, 28] {
        check(p.hopForward(), "hop")
        while p.isHopping { p.step(dt: 1.0 / 60) }
        check(p.tile == GridPoint(expected, 49), "landed on lily pad \(expected) (at \(p.tile))")
    }
    // trees block: hop north from the forest trail into the tree line stops early
    var t = VillagePlayerController(map: map, start: GridPoint(4, 40), facing: .north)
    t.hopForward()
    while t.isHopping { t.step(dt: 1.0 / 60) }
    check(col.fits(t.position) && map.isWalkable(t.tile), "trees stop the hop")
}


test("seasons, weather and festivals follow the calendar") {
    check(Season.of(month: 4) == .spring && Season.of(month: 7) == .summer && Season.of(month: 10) == .autumn && Season.of(month: 1) == .winter && Season.of(month: 12) == .winter, "months → seasons")
    // the same date always gives the same weather, and snow only falls in winter
    var counts: [Weather: Int] = [:]
    for m in 1...12 {
        for d in 1...28 {
            let w = Weather.on(year: 2026, month: m, day: d)
            check(w == Weather.on(year: 2026, month: m, day: d), "weather is stable for a date")
            if w == .snowy { check(Season.of(month: m) == .winter, "snow only in winter (\(m)/\(d))") }
            counts[w, default: 0] += 1
        }
    }
    check(counts.count == Weather.allCases.count, "every kind of weather happens in a year: \(counts)")
    check((counts[.sunny] ?? 0) > (counts[.rainy] ?? 0), "more sunny days than rainy ones")
    for s in Season.allCases {
        check(s.festivals.count == 2, "\(s) has two festivals")
        let weeks = Set((1...8).map { Festival.ofWeek($0, season: s) })
        check(weeks == Set(s.festivals), "\(s) festivals take turns week by week")
    }
    check(Set(Season.allCases.flatMap(\.festivals)) == Set(Festival.allCases), "every festival happens some time in the year")
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    let oct = cal.date(from: DateComponents(year: 2026, month: 10, day: 16))!
    let day = VillageDay(date: oct, calendar: cal)
    check(day.season == .autumn && Season.autumn.festivals.contains(day.weekFestival), "a date in October: \(day)")
    check(day.festival(picked: nil) == day.weekFestival && day.festival(picked: "kite") == .kite && day.festival(picked: "nonsense") == day.weekFestival, "the notice-board pick wins")
}

test("festival missions: hosted by Gemma, reachable, one house decoration each") {
    let host = VillageNPCDef.def(FestivalMissions.hostID)
    check(host != nil, "Gemma lives in the village")
    check(FestivalMissions.all.count == Festival.allCases.count, "one mission per festival")
    check(Set(Festival.allCases.map(\.houseReward)).count == Festival.allCases.count, "every festival gives a different decoration")
    for f in Festival.allCases {
        let m = FestivalMissions.mission(for: f)
        check(m != nil && m?.giver == FestivalMissions.hostID && m!.reward > 0, "\(f) mission")
        check(MissionCatalog.all.contains { $0.id == f.missionID }, "\(f) is in the mission catalog (so items show up)")
    }
    // the host offers this week's festival, but always finishes one in progress first
    var save = MissionSave()
    check(MissionCatalog.offer(from: FestivalMissions.hostID, save: save, festival: .kite)?.id == "fest_kite", "host offers the current festival")
    save.start(FestivalMissions.mission(for: .harvest)!)
    check(MissionCatalog.offer(from: FestivalMissions.hostID, save: save, festival: .kite)?.id == "fest_harvest", "a festival in progress comes first")
    check(MissionCatalog.offer(from: "acorn", save: save, festival: .kite)?.id == "gears", "other villagers keep their own missions")
    check(MissionCatalog.mission(givenBy: FestivalMissions.hostID) == nil, "festivals aren't a plain villager mission")
    let visible = MissionCatalog.visible(save: save, festival: .kite).map(\.id)
    check(visible.contains("fest_kite") && visible.contains("fest_harvest") && !visible.contains("fest_snow"), "log shows current + started festivals: \(visible)")
    // snow day: snowballs, then build the snowman with Gemma
    var snow = MissionSave()
    let sm = FestivalMissions.mission(for: .snow)!
    snow.start(sm)
    for p in snow.pickups() { snow.collect(p.key) }
    check(snow.status(sm) == .active(step: 1), "snowballs found → build with Gemma")
    check(snow.talked(to: FestivalMissions.hostID)?.0 == sm && snow.status(sm) == .readyToTurnIn, "snowman built")
    check(snow.turnIn(sm) && !snow.turnIn(sm), "festival reward once, ever")
}

test("your house: styles, decorations, saves") {
    check(map.building(.home) != nil, "the house is on the map")
    if let home = map.building(.home) {
        check(home.widthTiles == 5 && home.heightTiles == 4, "house footprint 5x4")
        check(map.isWalkable(home.doorstep), "house doorstep walkable")
        check(reachable(from: map.spawn).contains(home.doorstep), "house reachable from the square")
    }
    var style = HomeStyle()
    check(style.layers == ["home_wall_0", "home_roof_0", "home_door_0", "home_extra_flowerBox"], "default house: \(style.layers)")
    style.extras = [.snowman, .kite, .mailbox]
    check(style.layers.suffix(3) == ["home_extra_mailbox", "home_extra_kite", "home_extra_snowman"], "decorations in a fixed order")
    let back = try JSONDecoder().decode(HomeStyle.self, from: JSONEncoder().encode(style))
    check(back == style, "house round trip")
    let odd = try JSONDecoder().decode(HomeStyle.self, from: Data(#"{"wall":9,"roof":-2,"extras":["kite","jetpack"]}"#.utf8))
    check(odd.wall == 3 && odd.roof == 0 && odd.extras == [.kite], "bad values clamped, unknown decorations skipped")
    let starters = HomeStyle.unlocked(missionsDone: [])
    check(starters == [.flowerBox, .mailbox, .flag, .lamp], "4 decorations from the start")
    check(HomeStyle.unlocked(missionsDone: ["fest_kite", "fest_snow"]).contains(.kite) && HomeStyle.unlocked(missionsDone: ["fest_kite"]).count == 5, "festivals unlock decorations")
    // older saves load with a default house and seasons on
    let v = try JSONDecoder().decode(VillageSaveState.self, from: Data(#"{"version":2,"tileX":5,"tileY":5}"#.utf8))
    check(v.home == HomeStyle() && v.seasons && v.festivalPick == nil, "v2.5 saves get the new village fields")
    var v2 = v; v2.festivalPick = "music"; v2.home.roof = 2
    check(try JSONDecoder().decode(VillageSaveState.self, from: JSONEncoder().encode(v2)) == v2, "village save round trip")
}

test("villager stories change with the season and weather") {
    for id in VillageNPCDef.everyone.map(\.id) {
        check(VillageStories.npcIDs.contains(id), "\(id) has seasonal lines")
    }
    let day = VillageDay(season: .winter, weather: .snowy, weekFestival: .snow)
    let a = VillageStories.line(npc: "pip", day: day, turn: 0), b = VillageStories.line(npc: "pip", day: day, turn: 1)
    check(a != b && (a.contains("penguin") || b.contains("penguin")) && (a.contains("snowflake") || b.contains("snowflake")), "season and weather lines alternate: \(a) / \(b)")
    check(!VillageStories.line(npc: "nobody", day: day, turn: 0).isEmpty, "unknown villagers still get a weather line")
    let heard = Set((0..<8).map { VillageStories.line(npc: "pip", day: day, turn: $0) })
    check(heard.count == 3, "over a few chats you hear the season line and both weather lines: \(heard.count)")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
