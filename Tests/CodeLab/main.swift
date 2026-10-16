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
func run(_ src: String) throws -> [String] {
    let py = MiniPython()
    try py.run(src)
    return py.output
}
func fails(_ src: String, line: Int? = nil, contains: String) -> Bool {
    do { _ = try run(src); return false } catch let e as PyError {
        return (line == nil || e.line == line!) && e.message.contains(contains)
    } catch { return false }
}

print("Coding Lab engine tests")

test("print, strings and numbers") {
    check(try run("print(\"Hello, Hop Village!\")") == ["Hello, Hop Village!"], "hello")
    check(try run("print('a', 3, True, None)") == ["a 3 True None"], "print joins with spaces")
    check(try run("print(2 + 3 * 4)\nprint((2 + 3) * 4)\nprint(7 // 2, 7 % 3, -4 + 1)") == ["14", "20", "3 1 -3"], "math precedence")
    check(try run("name = \"Pip\"\nprint(\"Hi \" + name + \"!\")") == ["Hi Pip!"], "string join")
    check(try run("print(\"ab\" * 3)\nprint(len(\"hop\"))\nprint(\"Score: \" + str(10))") == ["ababab", "3", "Score: 10"], "string tools")
    check(try run("print(int(\"42\") + 1, max(3, 9, 2), min(4, 1), abs(-5))") == ["43 9 1 5"], "built-ins")
    check(try run("# a comment\nx = 5 # set x\nprint(x)  # show it") == ["5"], "comments ignored")
    check(try run("print(\"# not a comment\")") == ["# not a comment"], "hash inside a string kept")
}

test("variables and changing them") {
    check(try run("stars = 3\nstars = stars + 4\nstars += 1\nstars -= 2\nstars *= 10\nprint(stars)") == ["60"], "update a variable")
}

test("loops") {
    check(try run("for i in range(3):\n    print(\"Hop!\")") == ["Hop!", "Hop!", "Hop!"], "repeat")
    check(try run("for i in range(4):\n    print(i)") == ["0", "1", "2", "3"], "counts from 0")
    check(try run("for i in range(2, 10, 3):\n    print(i)") == ["2", "5", "8"], "start, stop, step")
    check(try run("for i in range(5, 0, -2):\n    print(i)") == ["5", "3", "1"], "counting down")
    check(try run("total = 0\nfor i in range(1, 6):\n    total += i\nprint(total)") == ["15"], "adding in a loop")
    check(try run("for i in range(2):\n    for j in range(2):\n        print(i, j)") == ["0 0", "0 1", "1 0", "1 1"], "nested loops")
}

test("if / elif / else") {
    let src = """
    stars = 7
    if stars > 10:
        print("Mega star!")
    elif stars > 5:
        print("Super star!")
    else:
        print("Keep going!")
    print("done")
    """
    check(try run(src) == ["Super star!", "done"], "elif chosen")
    check(try run("if 3 == 3 and not False:\n    print(\"yes\")") == ["yes"], "and / not")
    check(try run("x = 0\nif x:\n    print(\"no\")\nelse:\n    print(\"zero is False\")") == ["zero is False"], "truthiness")
}

test("functions, inputs, return, global, events") {
    check(try run("def greet(name):\n    return \"Hi \" + name\nprint(greet(\"Ollie\"))") == ["Hi Ollie"], "params + return")
    let game = """
    score = 0
    def on_star():
        global score
        score = score + 2
        if score >= 4:
            print("You win!")
    """
    let py = MiniPython()
    try py.run(game)
    check(py.hasFunction("on_star"), "function defined")
    try py.call("on_star")
    check(py.value(of: "score") == .int(2) && py.output.isEmpty, "global updated")
    try py.call("on_star")
    check(py.value(of: "score") == .int(4) && py.output == ["You win!"], "event logic")
    check(try py.call("missing") == nil, "missing event is fine")
    // without global, assignment stays local (real Python rule)
    let local = MiniPython()
    try local.run("x = 1\ndef f():\n    x = 5\nf()\nprint(x)")
    check(local.output == ["1"], "locals don't leak")
}

test("host commands (game API)") {
    var calls: [String] = []
    let py = MiniPython()
    py.host["jump"] = { args in calls.append("jump \(args.first?.description ?? "")"); return .none }
    py.host["set_background"] = { args in
        guard case .str(let s)? = args.first, ["meadow", "night"].contains(s) else { throw PyError(line: 0, message: "Pick meadow or night.") }
        calls.append("bg \(s)"); return .none
    }
    try py.run("set_background(\"night\")\ndef on_tap():\n    jump(120)")
    try py.call("on_tap")
    check(calls == ["bg night", "jump 120"], "host functions called: \(calls)")
    do { try py.run("set_background(\"lava\")"); check(false, "bad background should fail") }
    catch let e as PyError { check(e.line == 1 && e.message.contains("meadow"), "host error gets the line number") }
}

test("kind error messages with line numbers") {
    check(fails("print(\"hi\"", line: 1, contains: "closing"), "missing paren")
    check(fails("print(\"hi)", line: 1, contains: "closing"), "missing quote")
    check(fails("x = 1\nprint(y)", line: 2, contains: "doesn't know 'y'"), "unknown name")
    check(fails("print(\"Age \" + 7)", line: 1, contains: "str()"), "text + number")
    check(fails("if x = 3:\n    print(1)", line: 1, contains: "=="), "= vs ==")
    check(fails("for i in range(3):\nprint(1)", line: 1, contains: "pushed in"), "missing indent")
    check(fails("print(1)\n    print(2)", line: 2, contains: "too many spaces"), "extra indent")
    check(fails("x = 3.5", contains: "whole numbers"), "no decimals")
    check(fails("prnt(\"hi\")", contains: "spelling"), "typo in function name")
    check(fails("else:\n    print(1)", contains: "after an if"), "else alone")
    check(fails("print(5 / 2)", contains: "//"), "inexact division")
    check(fails("jump", contains: "doesn't know"), "bare unknown name")
    check(fails("score += 1", contains: "starting value"), "augment before set")
    check(fails("import os", contains: "built in"), "import explained")
    check(fails("while True:\n    pass", contains: "for"), "while explained")
}

test("safety limits") {
    check(fails("x = 0\nfor i in range(1000):\n    for j in range(1000):\n        x += 1", contains: "too long"), "step limit stops long programs")
    check(fails("for i in range(5000):\n    pass", contains: "huge"), "big range refused")
    check(fails("def f():\n    f()\nf()", contains: "Too many"), "deep recursion stopped")
    check(fails("s = \"ab\" * 5000", contains: "too long"), "giant strings refused")
}

// MARK: - Curriculum

func project(_ track: CodeTrack, pick: (CodeSlot) -> String) -> CodeProject {
    var values: [String: String] = [:]
    for l in CodeCurriculum.lessons(for: track) { for t in l.lines { for s in t.slots { values["\(l.id).\(s.id)"] = pick(s) } } }
    var p = CodeProject(track: track, lessons: CodeCurriculum.lessons(for: track), values: values)
    p.kid = "Ava"; p.buddy = "Lavender Lop"; p.buddyID = "lavender"
    return p
}
let heroes: Set<String> = ["lavender", "rocky", "pip", "ollie"]

test("curriculum: 3 tracks x 8 lessons, every blank has choices, ids unique") {
    check(CodeCurriculum.lessons.count == 24, "24 lessons")
    for t in CodeTrack.allCases {
        let ls = CodeCurriculum.lessons(for: t)
        check(ls.map(\.number) == Array(1...8), "\(t) numbered 1-8")
        for l in ls {
            check(!l.cards.isEmpty && !l.funFact.isEmpty && !l.goal.isEmpty, "\(l.id) teaches something")
            check((2...4).contains(l.quiz.choices.count), "\(l.id) quiz")
            for line in l.lines {
                for s in line.slots { check(s.choices.count >= 2 && line.text.contains("[[\(s.id)]]"), "\(l.id).\(s.id) wired") }
                let ids = line.text.components(separatedBy: "[[").dropFirst().map { String($0.prefix { $0 != "]" }) }
                check(Set(ids) == Set(line.slots.map(\.id)), "\(l.id) placeholders match slots: \(ids)")
            }
        }
    }
    check(Set(CodeCurriculum.lessons.flatMap(\.slotKeys)).count == CodeCurriculum.lessons.flatMap(\.slotKeys).count, "slot keys unique")
}

test("Python Coder: the finished program runs for every choice") {
    for k in 0..<5 {
        let p = project(.python) { $0.choices[k % $0.choices.count] }
        check(p.missingSlots.isEmpty, "all filled")
        let py = MiniPython()
        do { try py.run(p.source) } catch { check(false, "python program \(k) failed: \(error)\n\(p.source)") }
        check(py.output.count >= 5, "prints several lines (\(py.output))")
    }
    let p = project(.python) { $0.choices[0] }
    let py = MiniPython(); try py.run(p.source)
    check(py.output.first == "Hello, Hop Village!", "lesson 1 output")
    check(py.output.contains("My buddy is Lavender Lop"), "{buddy} filled in")
    // lessons 6-8: functions, return, and the Hop-Skip counting game
    check(py.output.contains("Go, Lavender Lop!") && py.output.contains("Go, Stella!"), "cheer() function called twice: \(py.output)")
    check(py.output.contains("The answer is 8"), "times(4) returns 8")
    let hopSkip = Array(py.output.suffix(6))
    check(hopSkip == ["1", "2 Hop! 🐰", "3", "4 Hop! 🐰", "5", "6 Hop! 🐰"], "loop + if + %: \(hopSkip)")
}

test("Python Coder: every lesson's program runs on its own track so far") {
    let all = CodeCurriculum.lessons(for: .python)
    for n in 1...all.count {
        var values: [String: String] = [:]
        for l in all.prefix(n) { for t in l.lines { for s in t.slots { values["\(l.id).\(s.id)"] = s.choices.last! } } }
        var p = CodeProject(track: .python, lessons: Array(all.prefix(n)), values: values)
        p.kid = "Ava"; p.buddy = "Pip"
        let py = MiniPython()
        do { try py.run(p.source) } catch { check(false, "after python\(n): \(error)\n\(p.source)") }
    }
}

test("Game Maker: the finished game sets up, jumps, scores and wins") {
    for k in 0..<4 {
        let p = project(.games) { $0.choices[k % $0.choices.count] }
        let g = GameProgram(validHeroes: heroes)
        do { try g.load(p.source) } catch { check(false, "game \(k) failed: \(error)\n\(p.source)"); continue }
        check(g.setup.background != nil && g.setup.hero != nil && g.setup.stars >= 3, "setup \(g.setup)")
        check(g.hasTapEvent && g.hasStarEvent && g.score == 0, "events + score")
        try g.tap()
        if case .jump(let h)? = g.drainEffects().first { check([80, 120, 160].contains(h), "jumps") } else { check(false, "tap should jump") }
        var won = false
        for _ in 0..<30 { try g.starCollected(); if g.drainEffects().contains(where: { if case .say = $0 { return true }; return false }) { won = true; break } }
        check(won, "reaching the goal says the win message (score \(g.score ?? -1))")
        check(g.setup.bubbles >= 1 && g.hasBumpEvent && g.hasScoreEvent, "bubbles and new events: \(g.setup)")
        try g.bumped()
        check(g.drainEffects().contains { if case .say = $0 { return true }; return false }, "on_bump says something")
    }
}

test("Game Maker: speed and levelling up while playing") {
    let p = project(.games) { $0.choices[0] }   // meadow, speed 2, level 2 at 3 points: night, speed 5
    let g = GameProgram(validHeroes: heroes)
    try g.load(p.source)
    check(g.setup.speed == 2 && g.setup.background == "meadow", "setup speed and world: \(g.setup)")
    check(!g.drainEffects().contains { if case .background = $0 { return true }; return false }, "no world change during setup")
    var levelled = false
    for _ in 0..<10 {
        try g.starCollected()
        let fx = g.drainEffects()
        if fx.contains(.background("night")) && fx.contains(.speed(5)) { levelled = true; break }
    }
    check(levelled, "on_score changes the world and speed (score \(g.score ?? -1))")
    try g.starCollected()
    check(!g.drainEffects().contains { if case .background = $0 { return true }; return false }, "no repeat world change once there")
    check(GameProgram.pointsPerSecond(3) == 150, "speed 3 keeps the classic pace")
    let bad = GameProgram(validHeroes: heroes)
    check((try? bad.load("set_speed(0)")) == nil && (try? bad.load("set_speed(11)")) == nil, "speed outside 1-10 refused")
    let late = GameProgram(validHeroes: heroes)
    try late.load("def on_tap():\n    add_star()")
    check((try? late.tap()) == nil, "can't add stars inside an event")
    let many = GameProgram(validHeroes: heroes)
    check((try? many.load("for i in range(9):\n    add_bubble()")) == nil, "too many bubbles refused")
}

test("Game Maker: half-built games still run (lesson by lesson)") {
    let all = CodeCurriculum.lessons(for: .games)
    for n in 1...all.count {
        var values: [String: String] = [:]
        for l in all.prefix(n) { for t in l.lines { for s in t.slots { values["\(l.id).\(s.id)"] = s.choices[0] } } }
        var p = CodeProject(track: .games, lessons: Array(all.prefix(n)), values: values)
        p.buddyID = "lavender"
        let g = GameProgram(validHeroes: heroes)
        do { try g.load(p.source) } catch { check(false, "after lesson \(n): \(error)") }
        check(g.hasTapEvent == (n >= 3), "tap event appears in lesson 3")
    }
    let g = GameProgram(validHeroes: heroes)
    check((try? g.load("set_background(\"lava\")")) == nil, "unknown world refused")
    check((try? g.load("add_player(\"mickey\")")) == nil, "unknown hero refused")
    check((try? g.load("for i in range(50):\n    add_star()")) == nil, "too many stars refused")
}

test("Web Designer: the page is real, balanced HTML with CSS") {
    let p = project(.web) { $0.choices[1] }
    let html = p.source
    for tag in ["html", "head", "style", "body", "ul", "h1", "h2", "p", "div", "span", "button"] {
        let opens = html.components(separatedBy: "<\(tag)").count - 1
        let closes = html.components(separatedBy: "</\(tag)>").count - 1
        check(opens == closes && opens > 0, "<\(tag)> opened \(opens) and closed \(closes)")
    }
    check(html.hasPrefix("<!DOCTYPE html>"), "doctype first")
    check(html.contains("body { background: pink; }") && html.contains("h1 { color: crimson; }"), "CSS rules inside <style>")
    let styleRange = html.range(of: "<style>")!.upperBound..<html.range(of: "</style>")!.lowerBound
    check(html[styleRange].contains(".card {") && !html[styleRange].contains("<h1>"), "style and body kept apart")
    check(html.contains("<h1>Welcome to my page!</h1>"), "heading")
    check(!html.contains("[[") && !html.contains("{kid}"), "no placeholders left")
    check(html[styleRange].contains("@keyframes bounce { 50% { transform: translateY(-25px); } }"), "keyframes in the style")
    check(html[styleRange].contains(".row { display: flex; gap: 12px;"), "flexbox rule")
    check(html.contains("<div class=\"bounce\">⭐</div>"), "the bouncing part")
    // braces in CSS stay balanced
    check(html[styleRange].filter { $0 == "{" }.count == html[styleRange].filter { $0 == "}" }.count, "CSS braces balanced")
}

test("editor lines: colors, blanks and names") {
    var p = CodeProject(track: .python, lessons: [CodeCurriculum.lesson("python1")!], values: [:])
    p.kid = "Ava"
    let lines = p.render()
    check(lines.count == 1, "one line")
    let segs = lines[0].segments
    check(segs.first == .code("print", .tag), "print colored as a built-in: \(segs)")
    check(segs.contains(.slot(key: "python1.hello", value: nil, kind: .text)), "blank shown")
    check(p.missingSlots == ["python1.hello"], "missing slot listed")
    p = CodeProject(track: .python, lessons: [CodeCurriculum.lesson("python1")!], values: ["python1.hello": "Hi, I'm {kid}!"])
    p.kid = "Ava<script>"
    check(p.source == "print(\"Hi, I'm Avascript!\")", "kid name made safe: \(p.source)")
    let web = CodeProject(track: .web, lessons: [CodeCurriculum.lesson("web3")!], values: ["web3.bg": "pink"]).render()
    check(web.contains { $0.segments.contains(.code("background", .property)) }, "CSS property colored")
    check(web.contains { $0.segments.contains(.slot(key: "web3.bg", value: "pink", kind: .color)) }, "CSS value slot")
    check(web.first?.lessonID == nil && web.first?.segments.first == .code("<!DOCTYPE", .tag), "scaffolding lines")
    check(web.contains { $0.segments.first == .code("body", .tag) }, "CSS selector colored")
    let kf = CodeProject(track: .web, lessons: [CodeCurriculum.lesson("web8")!], values: ["web8.up": "25"]).render()
    check(kf.contains { $0.segments.contains(.code("transform", .property)) }, "property inside @keyframes colored")
}

// MARK: - Free Build

func done(_ ids: [String]) -> CodeLabSave { var s = CodeLabSave(); s.completed = Set(ids); return s }

test("Free Build: blocks unlock with lessons") {
    let blocks = Sandbox.blocks(for: .python)
    check(blocks.count == CodeCurriculum.lessons(for: .python).reduce(0) { $0 + $1.lines.count }, "one block per lesson line")
    check(Set(blocks.map(\.id)).count == blocks.count, "block ids unique")
    check(Sandbox.block("python4.1")?.template.text == "print(\"[[cheer]]\")", "find a block by id")
    check(!Sandbox.isOpen(.python, save: CodeLabSave()), "closed before lesson 1")
    check(Sandbox.isOpen(.python, save: done(["python1"])), "open after lesson 1")
    check(Sandbox.unlockedBlocks(for: .python, save: done(["python1", "python4"])).map(\.lessonID) == ["python1", "python4", "python4"], "only finished lessons' blocks")
}

test("Free Build: adding, moving, indenting and removing lines") {
    var save = SandboxSave()
    var lines: [SandboxLine] = []
    lines = Sandbox.adding(Sandbox.block("python4.0")!, to: lines, after: nil, save: &save)   // for i in range(..):
    lines = Sandbox.adding(Sandbox.block("python1.0")!, to: lines, after: 0, save: &save)     // print(..) under it
    check(lines.map(\.indent) == [0, 1], "a line added under a ':' line is pushed in: \(lines.map(\.indent))")
    check(lines.map(\.id) == ["L1", "L2"] && save.nextID == 3, "ids count up")
    lines = Sandbox.adding(Sandbox.block("python1.0")!, to: lines, after: 1, save: &save)
    check(lines[2].indent == 1, "a line added under an indented line keeps its indent")
    lines = Sandbox.indenting(lines, at: 2, by: -1)
    check(lines[2].indent == 0, "push left")
    lines = Sandbox.indenting(lines, at: 2, by: -5)
    check(lines[2].indent == 0, "can't go past the left edge")
    lines = Sandbox.indenting(Sandbox.indenting(Sandbox.indenting(Sandbox.indenting(lines, at: 2, by: 1), at: 2, by: 1), at: 2, by: 1), at: 2, by: 1)
    check(lines[2].indent == Sandbox.maxIndent, "indent capped")
    lines = Sandbox.moving(lines, from: 2, by: -1)
    check(lines.map(\.id) == ["L1", "L3", "L2"], "move up")
    check(Sandbox.moving(lines, from: 0, by: -1) == lines, "top line can't go higher")
    lines = Sandbox.removing(lines, at: 1)
    check(lines.map(\.id) == ["L1", "L2"], "remove")
    var full: [SandboxLine] = []
    for _ in 0..<50 { full = Sandbox.adding(Sandbox.block("python1.0")!, to: full, after: nil, save: &save) }
    check(full.count == Sandbox.maxLines, "line limit")
}

test("Free Build: web lines move within their own section") {
    var save = SandboxSave()
    var lines: [SandboxLine] = []
    for id in ["web3.0", "web1.0", "web3.1", "web2.0"] { lines = Sandbox.adding(Sandbox.block(id)!, to: lines, after: nil, save: &save) }
    // order: style(L1) body(L2) style(L3) body(L4); moving L3 up skips the body line and swaps with L1
    let moved = Sandbox.moving(lines, from: 2, by: -1)
    check(moved.map(\.id) == ["L3", "L2", "L1", "L4"], "style swaps with style: \(moved.map(\.id))")
    check(Sandbox.adding(Sandbox.block("web1.0")!, to: [], after: nil, save: &save).first?.indent == 0, "web blocks keep their own indent")
}

test("Free Build: a hand-built program renders and runs") {
    var save = SandboxSave()
    var lines: [SandboxLine] = []
    lines = Sandbox.adding(Sandbox.block("python4.0")!, to: lines, after: nil, save: &save)
    lines = Sandbox.adding(Sandbox.block("python1.0")!, to: lines, after: 0, save: &save)
    var p = SandboxProgram(track: .python, lines: lines)
    p.kid = "Ava"
    check(p.missingSlots == ["sb.L1.times", "sb.L2.hello"], "blanks listed: \(p.missingSlots)")
    lines[0].values["times"] = "3"
    lines[1].values["hello"] = "Hi, I'm {kid}!"
    p = SandboxProgram(track: .python, lines: lines)
    p.kid = "Ava"
    check(p.missingSlots.isEmpty, "all filled")
    check(p.source == "for i in range(3):\n    print(\"Hi, I'm Ava!\")", "source: \(p.source)")
    let py = MiniPython(); try py.run(p.source)
    check(py.output == ["Hi, I'm Ava!", "Hi, I'm Ava!", "Hi, I'm Ava!"], "runs: \(py.output)")
    // a line pushed in the wrong amount gives a kind Python error with a line number
    var wrong = lines
    wrong[1].indent = 0
    let bad = MiniPython()
    do { try bad.run(SandboxProgram(track: .python, lines: wrong).source); check(false, "bad indent should fail") }
    catch let e as PyError { check(e.line >= 1, "error points at a line: \(e)") }
    let rows = p.rows()
    check(rows.map(\.lineID) == ["L1", "L2"] && rows[1].line.indent == 1, "rows map to lines")
    check(Sandbox.parse(key: "sb.L2.hello")! == ("L2", "hello"), "slot keys parse")
    check(Sandbox.parse(key: "python1.hello") == nil, "lesson keys aren't sandbox keys")
}

test("Free Build: web project and game project") {
    var save = SandboxSave()
    var web: [SandboxLine] = []
    for id in ["web1.0", "web3.0"] { web = Sandbox.adding(Sandbox.block(id)!, to: web, after: nil, save: &save) }
    for i in web.indices { for s in SandboxProgram(track: .web, lines: web).slots(for: web[i]) { web[i].values[s.id] = s.choices[0] } }
    let html = SandboxProgram(track: .web, lines: web).source
    check(html.hasPrefix("<!DOCTYPE html>") && html.contains("<style>") && html.contains("</html>"), "page scaffolding added")
    let styleRange = html.range(of: "<style>")!.upperBound..<html.range(of: "</style>")!.lowerBound
    check(html[styleRange].contains("background") && !html[styleRange].contains("<h1>"), "style line in <style>, page line in <body>")

    var game: [SandboxLine] = []
    for id in ["games1.0", "games2.0", "games2.1", "games3.0", "games3.1"] { game = Sandbox.adding(Sandbox.block(id)!, to: game, after: nil, save: &save) }
    game[4].indent = 1
    for i in game.indices { for s in SandboxProgram(track: .games, lines: game).slots(for: game[i]) { game[i].values[s.id] = s.choices[1] } }
    var gp = SandboxProgram(track: .games, lines: game)
    gp.buddyID = "lavender"
    let g = GameProgram(validHeroes: heroes)
    try g.load(gp.source)
    check(g.setup.background == "night" && g.setup.hero == "lavender" && g.hasTapEvent, "hand-built game works: \(g.setup)")
}

test("progress: lessons unlock in order") {
    var save = CodeLabSave()
    let l1 = CodeCurriculum.lesson("web1")!, l2 = CodeCurriculum.lesson("web2")!
    check(save.isUnlocked(l1) && !save.isUnlocked(l2), "only lesson 1 open")
    save.completed.insert("web1")
    check(save.isUnlocked(l2) && save.nextLesson(in: .web)?.id == "web2", "lesson 2 opens")
    let back = try JSONDecoder().decode(CodeLabSave.self, from: JSONEncoder().encode(save))
    check(back == save, "save round trip")
    check(try JSONDecoder().decode(CodeLabSave.self, from: Data("{}".utf8)) == CodeLabSave(), "empty save")
    var withSandbox = save
    withSandbox.sandbox = SandboxSave()
    withSandbox.sandbox.lines["python"] = [SandboxLine(id: "L1", blockID: "python1.0", indent: 0, values: ["hello": "Hi"])]
    withSandbox.sandbox.nextID = 2
    check(try JSONDecoder().decode(CodeLabSave.self, from: JSONEncoder().encode(withSandbox)) == withSandbox, "Free Build saved")
    let old = try JSONDecoder().decode(CodeLabSave.self, from: Data("{\"completed\":[\"web1\"],\"values\":{}}".utf8))
    check(old.completed == ["web1"] && old.sandbox == SandboxSave(), "v2.3 saves load with an empty Free Build")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
