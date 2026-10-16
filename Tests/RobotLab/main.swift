import Foundation

var failures = 0, passes = 0
func check(_ ok: Bool, _ what: String, line: Int = #line) {
    if ok { passes += 1 } else { failures += 1; print("FAIL [\(line)] \(what)") }
}
func test(_ name: String, _ body: () throws -> Void) {
    let before = failures
    do { try body() } catch { failures += 1; print("FAIL \(name): threw \(error)") }
    print(failures == before ? "  ok   \(name)" : "  FAIL \(name)")
}

let F = RobotBlock.step(.forward), L = RobotBlock.step(.left), R = RobotBlock.step(.right)
func rep(_ n: Int, _ body: RobotBlock...) -> RobotBlock { RobotBlock(.repeatTimes(n), body: body) }
func until(_ body: RobotBlock...) -> RobotBlock { RobotBlock(.repeatUntilGoal, body: body) }
func ifBlocked(_ then: [RobotBlock], else other: [RobotBlock] = []) -> RobotBlock { RobotBlock(.ifBlocked, body: then, elseBody: other) }
func puzzle(_ id: Int) -> CodeChallenge { CodeChallenge.all.first { $0.id == id }! }
func solves(_ program: [RobotBlock], _ p: CodeChallenge) -> Bool {
    p.runAll(program).allSatisfy(\.solved)
}

/// Searches every program up to `maxPieces` built from the blocks a puzzle offers, to prove there's a solution
/// within the block limit (and to show which ones exist). Small search space: it finishes in moments.
func programs(maxPieces: Int, sensors: Bool) -> [[RobotBlock]] {
    let steps: [RobotBlock] = [F, L, R]
    var inner: [[RobotBlock]] = [[]]
    // bodies of up to 3 steps
    for n in 1...4 { inner += product(steps, n) }
    var singles: [RobotBlock] = steps
    for body in inner where !body.isEmpty {
        for t in 2...5 { singles.append(RobotBlock(.repeatTimes(t), body: body)) }
        if sensors { singles.append(RobotBlock(.repeatUntilGoal, body: body)) }
    }
    if sensors {
        var ifs: [RobotBlock] = []
        for a in inner.filter({ $0.count <= 2 }) { for b in inner.filter({ $0.count <= 2 }) where !(a.isEmpty && b.isEmpty) {
            ifs.append(RobotBlock(.ifBlocked, body: a, elseBody: b))
        } }
        singles += ifs
        for i in ifs { singles.append(RobotBlock(.repeatUntilGoal, body: [i])) }
    }
    var out: [[RobotBlock]] = []
    func grow(_ prog: [RobotBlock], _ used: Int) {
        if !prog.isEmpty { out.append(prog) }
        guard prog.count < 3 else { return }
        for s in singles where used + s.pieces <= maxPieces { grow(prog + [s], used + s.pieces) }
    }
    grow([], 0)
    return out
}
func product(_ xs: [RobotBlock], _ n: Int) -> [[RobotBlock]] {
    n == 0 ? [[]] : product(xs, n - 1).flatMap { p in xs.map { p + [$0] } }
}

print("Robot Lab engine tests")

test("steps, turns, walls and rocks") {
    let w = RobotWorld(start: RobotCell(x: 0, y: 5), dir: 0, goal: RobotCell(x: 0, y: 2), rocks: [RobotCell(x: 1, y: 4)])
    var t = RobotRunner.run([F, F, F], in: w, needsGears: false)
    check(t.solved && t.robot == RobotCell(x: 0, y: 2), "three forwards reach the star")
    t = RobotRunner.run([F, F], in: w, needsGears: false)
    check(t.outcome == .stoppedShort, "stops short")
    t = RobotRunner.run([L, F], in: w, needsGears: false)
    check(t.outcome == .bonkedWall && t.steps.last?.event == .bonked(rock: false), "bonks the wall")
    t = RobotRunner.run([R, F, L, F], in: RobotWorld(start: RobotCell(x: 0, y: 4), dir: 0, goal: RobotCell(x: 5, y: 5), rocks: [RobotCell(x: 1, y: 4)]), needsGears: false)
    check(t.outcome == .bonkedRock, "bonks a rock")
    t = RobotRunner.run([R, R, R, R], in: w, needsGears: false)
    check(t.dir == 0 && t.steps.count == 4, "four right turns face the same way")
    t = RobotRunner.run([F, F, F, F, F], in: w, needsGears: false)
    check(t.solved && t.steps.count == 3, "the program stops as soon as the star is reached")
}

test("loops and every highlight path") {
    let w = RobotWorld(start: RobotCell(x: 0, y: 5), dir: 0, goal: RobotCell(x: 0, y: 0))
    let loop = rep(5, F)
    let t = RobotRunner.run([loop], in: w, needsGears: false)
    check(t.solved && t.steps.count == 5, "repeat 5")
    check(t.steps.allSatisfy { $0.path == [loop.id, loop.body[0].id] }, "steps know which blocks ran")
    check([rep(5, F)].pieces == 2, "a loop with one step is 2 pieces")
}

test("sensors: repeat until star and if blocked") {
    let w = RobotWorld(start: RobotCell(x: 0, y: 5), dir: 0, goal: RobotCell(x: 4, y: 0))
    let prog = [until(ifBlocked([R], else: [F]))]
    let t = RobotRunner.run(prog, in: w, needsGears: false)
    check(t.solved, "corner rule reaches the star: \(t.outcome)")
    check(t.steps.contains { $0.event == .sensed(blocked: true) } && t.steps.contains { $0.event == .sensed(blocked: false) }, "sensor saw both")
    check(prog.pieces == 4, "until + if + 2 steps = 4 pieces")
    // an endless loop is caught
    let spin = RobotRunner.run([until(R)], in: w, needsGears: false)
    check(spin.outcome == .wentInCircles && spin.steps.count == RobotRunner.stepLimit, "spinning forever is stopped")
    let empty = RobotRunner.run([RobotBlock(.repeatUntilGoal)], in: w, needsGears: false)
    check(empty.outcome == .stoppedShort, "an empty loop does nothing")
    // blocked ahead counts rocks and walls
    let rock = RobotWorld(start: RobotCell(x: 2, y: 2), dir: 1, goal: RobotCell(x: 0, y: 0), rocks: [RobotCell(x: 3, y: 2)])
    check(rock.blocked(from: rock.start, facing: 1) && !rock.blocked(from: rock.start, facing: 0), "rock sensed")
    check(rock.blocked(from: RobotCell(x: 0, y: 0), facing: 3), "wall sensed")
}

test("gears: needed gears and bonus gears") {
    let p = puzzle(405)
    let square = [rep(4, F, F, F, R)]
    let t = RobotRunner.run(square, in: p.maps[0], needsGears: true)
    check(t.solved && t.gears.count == 3, "square dance solved with every gear: \(t.outcome)")
    let short = RobotRunner.run([L, L, L, L], in: p.maps[0], needsGears: true)
    check(short.outcome == .missingGears, "back on the star without gears")
}

test("every puzzle can be solved within its block limit") {
    for p in CodeChallenge.all {
        let found = programs(maxPieces: p.blockLimit, sensors: p.sensors).first { solves($0, p) }
        check(found != nil, "\(p.id) \(p.title) has a solution in \(p.blockLimit) blocks")
    }
}

test("sensor puzzles need sensors: no plain program solves every map") {
    for p in CodeChallenge.all where p.sensors && p.maps.count > 1 {
        let plain = programs(maxPieces: 8, sensors: false).first { solves($0, p) }
        check(plain == nil, "\(p.id) can't be solved by counting steps")
    }
    for p in CodeChallenge.all where p.sensors {
        let plain = programs(maxPieces: p.blockLimit, sensors: false).first { solves($0, p) }
        check(plain == nil, "\(p.id): the block-limit star needs sensors")
    }
}

test("the intended sensor solutions") {
    check(solves([until(F)], puzzle(406)), "406: repeat until star, forward")
    check(!solves([rep(3, F)], puzzle(406)), "406: a counted loop fails a map")
    let overshoot = puzzle(406).runAll([rep(5, F)])
    check(overshoot[0].outcome == .passedGoal && overshoot[1].solved, "406: counting to 5 zooms past the near stars")
    check(RobotRunner.run([rep(5, F)], in: puzzle(406).maps[0], needsGears: false).solved, "classic puzzles still stop at the star")
    let rightRule = [until(ifBlocked([R], else: [F]))]
    let leftRule = [until(ifBlocked([L], else: [F]))]
    check(solves(rightRule, puzzle(407)), "407: turn right when blocked")
    check(solves(leftRule, puzzle(408)), "408: turn left when blocked")
    check(!solves(rightRule, puzzle(408)), "408: turning right goes the wrong way")
    let maze = RobotRunner.run(rightRule, in: puzzle(409).maps[0], needsGears: false)
    check(maze.solved && maze.gears.count == 3, "409: the maze rule grabs every gear on the way")
    check(!solves([until(F)], puzzle(407)), "407: forward alone bonks the wall")
}

test("puzzle data is sane") {
    check(Set(CodeChallenge.all.map(\.id)).count == CodeChallenge.all.count, "ids unique")
    check(CodeChallenge.all.count == 9 && CodeChallenge.all.filter(\.sensors).count == 4, "9 puzzles, 4 with sensors")
    for p in CodeChallenge.all {
        for m in p.maps {
            check(m.inside(m.start) && m.inside(m.goal), "\(p.id) start and goal on the board")
            check(!m.rocks.contains(m.start) && !m.rocks.contains(m.goal), "\(p.id) start/goal not on rocks")
            check(m.rocks.isDisjoint(with: m.gears), "\(p.id) no gear under a rock")
        }
    }
}

test("editing helpers: find, update, remove, tidy") {
    var prog = [until(ifBlocked([.step(.right)], else: [.step(.forward)])), .step(.forward)]
    let ifID = prog[0].body[0].id
    check(prog.find(ifID)?.isIf == true, "find nested if")
    prog.update(ifID) { $0.elseBody.append(L) }
    check(prog[0].body[0].elseBody.count == 2, "update nested")
    let elseFirst = prog[0].body[0].elseBody[0].id
    prog.remove(elseFirst)
    check(prog[0].body[0].elseBody.map(\.kind) == [.step(.left)], "remove nested")
    let tidy = [RobotBlock(.repeatTimes(3)), RobotBlock(.ifBlocked), F].withoutEmptyContainers()
    check(tidy.count == 1, "empty containers dropped")
}

test("simple machines: gears") {
    check(GearTrain(teeth: [20, 20]).lastTurnsClockwise == false, "two gears: opposite way")
    check(GearTrain(teeth: [20, 20, 20]).lastTurnsClockwise, "three gears: same way")
    check(GearTrain(teeth: [30, 10]).turnsPerCrank == 3, "big drives small: 3x faster")
    check(GearTrain(teeth: [10, 20, 30]).turnsPerCrank == 10.0 / 30.0, "middle gears don't change speed")
    let fan = MachinePuzzle.all.first { $0.id == 501 }!
    check(fan.check(choice: 3) && !fan.check(choice: 2), "501 needs an odd number of gears")
    let fast = MachinePuzzle.all.first { $0.id == 502 }!
    check(fast.check(choice: 3, size: 10) && !fast.check(choice: 3, size: 30) && !fast.check(choice: 2, size: 10), "502 needs clockwise and a small last gear")
}

test("simple machines: levers and pulleys") {
    check(Lever(fulcrum: 2, load: 3, effort: 1).lifts, "fulcrum near the load lifts it")
    check(!Lever(fulcrum: 5, load: 3, effort: 1).lifts, "fulcrum in the middle doesn't")
    check(Lever(fulcrum: 5, load: 2, effort: 2).balanced, "equal weights balance in the middle")
    check(Pulley(ropes: 3, load: 6).effort == 2 && Pulley(ropes: 3, load: 6).ropePulled == 3, "3 ropes: a third of the force, 3x the rope")
    check(Pulley(ropes: 3, load: 8).effort == 3, "force rounds up")
    for p in MachinePuzzle.all {
        let answers = (1...9).filter { n in MachinePuzzle.gearSizes.contains { p.check(choice: n, size: $0) } }
        check(!answers.isEmpty, "\(p.id) \(p.title) has an answer")
        check(answers.count < 9, "\(p.id) not every choice works")
        check(answers.contains { n in MachinePuzzle.gearSizes.contains { p.isBest(choice: n, size: $0) } }, "\(p.id) has a best answer")
    }
    let piano = MachinePuzzle.all.first { $0.id == 506 }!
    check(piano.check(choice: 4) && !piano.check(choice: 3) && piano.isBest(choice: 4), "506: 4 ropes for 8 with strength 2")
    let pp = MachinePuzzle.all.first { $0.id == 505 }!
    check(pp.isBest(choice: 3) && pp.check(choice: 4) && !pp.isBest(choice: 4), "505: 3 is best, 4 works but pulls more rope")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
