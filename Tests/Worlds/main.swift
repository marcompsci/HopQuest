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

print("Story world data tests")
let path = CommandLine.arguments[1]
let builtIn = Set(Chapters.all.map(\.id) + Chapters.team.map(\.id) + Chapters.kartCups.map(\.id))

test("worlds.json decodes and passes every check") {
    let file = try WorldData.decode(Data(contentsOf: URL(fileURLWithPath: path)))
    let problems = WorldData.problems(in: file, builtInIDs: builtIn)
    check(problems.isEmpty, "no problems: \(problems)")
    check(file.worlds.count >= 1, "at least one world")
}

test("Snowy Peaks: three snowy hop levels after Castle Hill") {
    let file = try WorldData.decode(Data(contentsOf: URL(fileURLWithPath: path)))
    guard let w = file.worlds.first(where: { $0.id == "snowy-peaks" }) else { check(false, "Snowy Peaks exists"); return }
    check(w.unlockAfter == 6, "opens after Castle Hill")
    check(w.chapters.map(\.id) == [7, 8, 9], "chapters 7, 8, 9")
    check(w.chapters.allSatisfy { $0.style.isSnow && $0.style.floaters == "ice" }, "snow and ice everywhere")
    check(zip(w.chapters, w.chapters.dropFirst()).allSatisfy { $0.difficulty < $1.difficulty && $0.rows <= $1.rows }, "each level a bit harder and longer")
    check(w.chapters.allSatisfy { $0.style.questions.count >= 3 }, "each level brings its own questions")
    let chapters = WorldData.chapters(of: w)
    check(chapters.allSatisfy { $0.kind == .hop && $0.style != nil && $0.gateEvery > 0 }, "converted to hop chapters with a style")
    check(chapters.first?.rows == 28 && chapters.last?.rows == 40, "lengths carried over")
    let subjects = Set(w.chapters.flatMap(\.style.questions).map(\.subject))
    check(subjects.isSubset(of: ["Math", "Road Safety", "Nature", "Science", "Words", "Coding", "Kindness"]), "question subjects are real subjects: \(subjects)")
}

test("the checker catches broken data") {
    var file = try WorldData.decode(Data(contentsOf: URL(fileURLWithPath: path)))
    file.worlds[0].chapters[0].id = 3                 // clashes with Robot Lab
    file.worlds[0].chapters[1].rows = 5                // too short
    file.worlds[0].chapters[2].style.floaters = "boat" // unknown
    file.worlds[0].chapters[2].style.questions.append(WorldQuestion(subject: "Science", prompt: "?", choices: ["A"], explain: "x"))
    file.worlds[0].unlockAfter = 99
    let p = WorldData.problems(in: file, builtInIDs: builtIn)
    check(p.contains { $0.contains("used twice") }, "duplicate id")
    check(p.contains { $0.contains("rows 5") }, "rows range")
    check(p.contains { $0.contains("floaters boat") }, "unknown floater")
    check(p.contains { $0.contains("2 to 4 choices") }, "question choices")
    check(p.contains { $0.contains("doesn't exist") }, "unlock chapter must exist")
    // missing style fields fall back to the classic look
    let minimal = #"{"version":1,"worlds":[{"id":"w","title":"W","icon":"x","blurb":"b","unlockAfter":6,"color":"FFFFFF","chapters":[{"id":50,"title":"T","kind":"hop","icon":"x","rows":20,"gateEvery":5,"difficulty":0.2,"intro":"hi","style":{}}]}]}"#
    let m = try WorldData.decode(Data(minimal.utf8))
    check(m.worlds[0].chapters[0].style == HopStyle(), "an empty style is the classic meadow")
    check(WorldData.problems(in: m, builtInIDs: builtIn).isEmpty, "a minimal world is valid")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
