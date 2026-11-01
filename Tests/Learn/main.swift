import Foundation

var failures = 0, passes = 0
func check(_ ok: Bool, _ what: @autoclosure () -> String, line: Int = #line) {
    if ok { passes += 1 } else { failures += 1; print("FAIL [\(line)] \(what())") }
}
func test(_ name: String, _ body: () throws -> Void) {
    let before = failures
    do { try body() } catch { failures += 1; print("FAIL \(name): threw \(error)") }
    print(failures == before ? "  ok   \(name)" : "  FAIL \(name)")
}

/// Repeatable randomness so every seed is a different, checkable play.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

print("Reading Nook and Math Market tests")

test("word bank: short words with pictures, no repeats") {
    let words = ReadingBank.words
    check(words.count >= 20, "enough words")
    check(Set(words.map(\.word)).count == words.count, "no repeated words")
    check(Set(words.map(\.emoji)).count == words.count, "no repeated pictures")
    check(words.allSatisfy { $0.word.count == 3 && $0.word == $0.word.lowercased() }, "three-letter lowercase words")
    check(words.allSatisfy { "aeiou".contains($0.word[$0.word.index(after: $0.word.startIndex)]) }, "middle letter is a vowel (can be sounded out)")
    check(ReadingBank.rhymeFamilies.count >= 5, "at least five rhyme families")
    check(Set(ReadingBank.sightWords).count == ReadingBank.sightWords.count, "no repeated sight words")
}

test("every game, 400 seeds: answers are always among the choices, and nothing repeats") {
    for seed in 0..<400 {
        var rng = SeededRNG(state: UInt64(seed))
        for game in ReadingGame.allCases {
            let rounds = ReadingBank.rounds(for: game, count: 5, using: &rng)
            check(rounds.count == 5, "\(game) has 5 rounds")
            for r in rounds {
                check(!r.say.isEmpty && !r.show.isEmpty && !r.cheer.isEmpty, "\(game) round has words")
                check(Set(r.choices).count == r.choices.count, "\(game) choices are different: \(r.choices)")
                switch r.kind {
                case .choose:
                    check(r.choices.filter { $0 == r.answer }.count == 1, "\(game) answer appears once: \(r.answer) in \(r.choices)")
                    check((3...4).contains(r.choices.count), "\(game) 3 or 4 choices")
                case .spell:
                    var tiles = r.choices
                    for ch in r.answer {
                        if let i = tiles.firstIndex(of: String(ch)) { tiles.remove(at: i) } else { check(false, "tile for \(ch) in \(r.answer)") }
                    }
                    check(tiles.count == 1, "exactly one extra tile")
                }
            }
            if game == .firstSound || game == .buildWord || game == .sightWords {
                let shows = rounds.map(\.say)
                check(Set(shows).count == shows.count, "\(game) doesn't repeat a word in one play")
            }
        }
    }
}

test("each game checks the right thing") {
    var rng = SeededRNG(state: 7)
    for r in ReadingBank.rounds(for: .firstSound, count: 20, using: &rng) {
        let w = ReadingBank.words.first { $0.emoji == r.show }!
        check(r.answer == w.firstLetter, "first letter of \(w.word)")
    }
    for r in ReadingBank.rounds(for: .rhymes, count: 30, using: &rng) {
        let target = String(r.show.split(separator: " ").last!)
        check(r.answer.dropFirst() == target.dropFirst() && r.answer != target, "\(r.answer) rhymes with \(target)")
        for c in r.choices where c != r.answer { check(c.dropFirst() != target.dropFirst(), "\(c) doesn't rhyme with \(target)") }
    }
    for r in ReadingBank.rounds(for: .sentences, count: 30, using: &rng) {
        let words = r.show.dropLast().split(separator: " ").map(String.init)   // The cat is on the bed
        let animal = ReadingBank.words.first { $0.word == words[1] }!, place = ReadingBank.words.first { $0.word == words[5] }!
        check(r.answer == ReadingBank.picture(animal, place), "the picture matches \(r.show)")
        check(r.choices.count == 3, "three pictures")
    }
    for r in ReadingBank.rounds(for: .sightWords, count: 10, using: &rng) {
        check(r.say.hasSuffix("\(r.answer)."), "says the word to find")
    }
}

test("spelling: next letter") {
    check(ReadingBank.nextLetter(of: "cat", typed: "") == "c", "first")
    check(ReadingBank.nextLetter(of: "cat", typed: "ca") == "t", "last")
    check(ReadingBank.nextLetter(of: "cat", typed: "cat") == nil, "done")
    check(ReadingBank.nextLetter(of: "cat", typed: "x") == nil, "off track")
}

test("stars: first-try score, and stars only for beating your best") {
    check(LearnScore.stars(firstTry: 5, of: 5) == 3 && LearnScore.stars(firstTry: 3, of: 5) == 2
          && LearnScore.stars(firstTry: 2, of: 5) == 1 && LearnScore.stars(firstTry: 0, of: 5) == 1, "1 to 3 stars")
    var s = ReadingSave()
    check(s.record(.rhymes, stars: 2) == 2, "first play gives its stars")
    check(s.record(.rhymes, stars: 1) == 0, "a lower score gives nothing")
    check(s.record(.rhymes, stars: 3) == 1, "beating the best gives the difference")
    check(s.record(.rhymes, stars: 3) == 0, "never more than 3 per game")
    check(s.totalStars == 3 && s.plays == 4, "totals")
    let back = try JSONDecoder().decode(ReadingSave.self, from: JSONEncoder().encode(s))
    check(back == s, "round trip")
    check(try JSONDecoder().decode(ReadingSave.self, from: Data("{}".utf8)) == ReadingSave(), "empty save")
}


test("Math Market: coins and fewest coins") {
    check(MarketBank.total([.quarter, .dime, .nickel, .penny]) == 41, "41 cents")
    for amount in 0...99 {
        let coins = MarketBank.fewestCoins(amount)
        check(MarketBank.total(coins) == amount, "fewest coins add up to \(amount)")
        let small = MarketBank.fewestCoins(amount, from: Coin.forLevel(1))
        check(MarketBank.total(small) == amount && !small.contains(.quarter), "little learners never need a quarter")
    }
    check(Coin.forLevel(1) == [.penny, .nickel, .dime] && Coin.forLevel(3).count == 4, "coins by level")
}

test("Math Market: every game, every level, 300 seeds") {
    for seed in 0..<300 {
        for level in 1...3 {
            var rng = SeededRNG(state: UInt64(seed * 7 + level))
            let top = MarketBank.maxCents(level)
            for game in MarketGame.allCases {
                let rounds = MarketBank.rounds(for: game, level: level, count: 5, using: &rng)
                check(rounds.count == 5, "5 rounds")
                for r in rounds {
                    check(!r.say.isEmpty && !r.cheer.isEmpty, "\(game) has words")
                    check(Set(r.choices).count == r.choices.count, "\(game) choices differ: \(r.choices)")
                    switch r.kind {
                    case .choose:
                        check(r.choices.filter { $0 == r.answer }.count == 1, "\(game) answer once: \(r.answer) in \(r.choices)")
                        check(r.choices.allSatisfy { !$0.hasPrefix("0") && !$0.hasPrefix("-") }, "\(game) no zero or negative amounts")
                    case .pay(let target):
                        check(target >= 1 && target <= top, "price in range for level \(level): \(target)")
                        let usable = Coin.forLevel(level)
                        check(r.choices == usable.map(\.label), "pay with this level's coins")
                        check(MarketBank.total(MarketBank.fewestCoins(target, from: usable)) == target, "payable exactly")
                    }
                    if level == 1, case .pay = r.kind { check(!r.choices.contains("25¢"), "no quarter to pay with for little learners") }
                    if level == 1 { check(!r.coins.contains(.quarter), "no quarters pictured for little learners") }
                }
                switch game {
                case .countCoins:
                    for r in rounds {
                        check(r.answer == MarketBank.cents(MarketBank.total(r.coins)), "count is the coins' total")
                        check(MarketBank.total(r.coins) <= top && r.coins.count >= 2, "coins within the level")
                    }
                case .makeChange:
                    for r in rounds {
                        let nums = r.show.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
                        check(nums.count == 2 && r.answer == MarketBank.cents(nums[1] - nums[0]) && nums[1] > nums[0], "change = paid - price: \(r.show)")
                    }
                case .addUp:
                    for r in rounds {
                        let nums = r.show.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
                        check(nums.count == 2 && r.answer == MarketBank.cents(nums[0] + nums[1]) && nums[0] + nums[1] <= top, "sum: \(r.show)")
                    }
                case .compare:
                    for r in rounds {
                        let prices = r.choices.map { Int($0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())! }
                        let picked = Int(r.answer.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!
                        let wantLess = r.say.contains("less")
                        check(picked == (wantLess ? prices.min()! : prices.max()!) && prices[0] != prices[1], "compare picks the \(wantLess ? "cheaper" : "pricier")")
                    }
                case .payExactly: break
                }
            }
        }
    }
}

test("Math Market save") {
    var s = MarketSave()
    check(s.record(.makeChange, stars: 1) == 1 && s.record(.makeChange, stars: 3) == 2 && s.record(.makeChange, stars: 2) == 0, "best only")
    check(s.totalStars == 3 && MarketSave.maxStars == 15, "totals")
    check(try JSONDecoder().decode(MarketSave.self, from: JSONEncoder().encode(s)) == s, "round trip")
}

test("Story Book: a cutscene after every story level and both new worlds, each one well formed") {
    check(Set(StoryBook.all.map(\.id)).count == StoryBook.all.count, "unique ids")
    check(StoryBook.intro.id == "intro" && StoryBook.all.first?.id == "intro", "the intro comes first")
    for ch in [1, 2, 3, 4, 5, 6, 9, 12, 15] { check(StoryBook.after(chapter: ch) != nil, "a story after chapter \(ch)") }
    for ch in [7, 8, 10, 11, 13, 14, 101, 201] { check(StoryBook.after(chapter: ch) == nil, "no story after chapter \(ch)") }
    for c in StoryBook.all {
        check(!c.title.isEmpty && (1...3).contains(c.panels.count), "\(c.id): 1 to 3 panels")
        for p in c.panels {
            check((1...3).contains(p.lines.count), "\(c.id): 1 to 3 lines a panel")
            check((1...3).contains(p.actors.count), "\(c.id): 1 to 3 actors")
            check(p.actors.allSatisfy { (0.05...0.95).contains($0.x) && $0.size > 0 }, "\(c.id): actors on stage")
            for l in p.lines {
                check(l.text.count >= 10 && l.text.count <= 120, "\(c.id): short, readable lines (\(l.text.count) letters)")
                check(l.text.last.map { ".!?".contains($0) } == true, "\(c.id): lines end like sentences")
            }
        }
    }
    check(StoryVoice.allCases.allSatisfy { (0.5...2).contains($0.pitch) && (0.5...1.2).contains($0.rate) }, "voices in a safe range")
    check(Set(StoryVoice.allCases.map(\.pitch)).count >= 5, "voices sound different")
    check(StoryPlace.allCases.allSatisfy { $0.skyHex.count == 2 && !$0.props.isEmpty }, "every place has a sky and props")
}

test("Science Lab: every experiment, 300 seeds, and the science is right") {
    for seed in 0..<300 {
        var rng = SeededRNG(state: UInt64(seed) &* 31 &+ 5)
        for e in Experiment.allCases {
            let rounds = ScienceBank.rounds(for: e, count: 5, using: &rng)
            check(rounds.count == 5, "\(e): 5 rounds")
            check(Set(rounds.map(\.say)).count == 5, "\(e): no repeats in one play")
            for r in rounds {
                check(r.choices.filter { $0 == r.answer }.count == 1 && Set(r.choices).count == r.choices.count, "\(e): answer once in \(r.choices)")
                check((2...3).contains(r.choices.count), "\(e): 2 or 3 choices")
                check(r.explain.count > 15 && r.say.hasSuffix("?"), "\(e): a question and an explanation")
            }
        }
    }
    check(ScienceBank.sinkFloat.contains { $0.answer == "Sink" } && ScienceBank.sinkFloat.contains { $0.answer == "Float" }, "both sink and float")
    check(ScienceBank.magnets.filter { $0.answer == "Yes" }.count >= 3 && ScienceBank.magnets.filter { $0.answer == "No" }.count >= 3, "both kinds of magnet test")
    check(Set(ScienceBank.matter.map(\.answer)) == ["Solid", "Liquid", "Gas"], "all three states")
    check(ScienceBank.plantParts.allSatisfy { ScienceBank.parts.contains($0.1) }, "plant answers are plant parts")
    check(ScienceBank.magnets.first { $0.emoji == "🪙" } == nil, "no coins in the magnet test (some coins are magnetic, some aren't)")
    var s = ScienceSave()
    check(s.record(.magnets, stars: 2) == 2 && s.record(.magnets, stars: 2) == 0 && s.record(.magnets, stars: 3) == 1, "best only")
    check(ScienceSave.maxStars == 15 && s.totalStars == 3, "totals")
}

test("Music Maker: keys, tunes, patterns, checking taps, and the song builder") {
    check(MusicKeys.names.count == 8 && MusicKeys.midi.count == 8 && MusicKeys.colors.count == 8 && MusicKeys.solfege.count == 8, "eight keys")
    check(abs(MusicKeys.hz(0) - 261.63) < 0.1 && abs(MusicKeys.hz(5) - 440) < 0.01 && abs(MusicKeys.hz(7) - 523.25) < 0.1, "middle C, A440, high C")
    check(zip(MusicKeys.midi, MusicKeys.midi.dropFirst()).allSatisfy { $0 < $1 }, "keys go up")
    // the songs as letters
    func letters(_ id: String) -> String { MusicBank.tunes.first { $0.id == id }!.keys.map { MusicKeys.names[$0] }.joined() }
    check(letters("twinkle") == "CCGGAAGFFEEDDC", "Twinkle, Twinkle")
    check(letters("mary") == "EDCDEEEDDDEGG", "Mary Had a Little Lamb")
    check(letters("buns") == "EDCEDCCCCCDDDDEDC", "Hot Cross Buns")
    check(letters("joy") == "EEFGGFEDCCDEEDD", "Ode to Joy")
    for seed in 0..<300 {
        var rng = SeededRNG(state: UInt64(seed) &+ 99)
        let echo = MusicBank.echoPatterns(using: &rng)
        check(echo.map(\.count) == [3, 3, 4, 4, 5], "echo patterns grow")
        check(echo.allSatisfy { p in zip(p, p.dropFirst()).allSatisfy { $0 != $1 } && p.allSatisfy { (0..<8).contains($0) } }, "no repeated neighbors, real keys")
        check(echo.prefix(2).allSatisfy { $0.allSatisfy { $0 <= 4 } }, "short patterns use the first five keys")
        let drums = MusicBank.rhythmPatterns(using: &rng)
        check(drums.map(\.count) == [3, 3, 4, 4, 5] && drums.allSatisfy { $0.allSatisfy { (0..<4).contains($0) } }, "drum patterns")
    }
    var c = PatternCheck([2, 4, 1])
    check(c.next == 2 && c.tap(2) == .good && c.tap(3) == .wrong && c.next == 4, "wrong tap: try the same note again")
    check(c.tap(4) == .good && c.tap(1) == .done && c.isDone && c.mistakes == 1 && c.tap(1) == .done, "finish")
    var song = SongSteps()
    song.toggle(step: 0, key: 3); song.toggle(step: 7, key: 7); song.toggle(step: 8, key: 1); song.toggle(step: 2, key: 9)
    check(song.steps[0] == 3 && song.steps[7] == 7 && song.steps.compactMap { $0 }.count == 2, "set steps, ignore bad ones")
    song.toggle(step: 0, key: 3)
    check(song.steps[0] == nil, "tap again to clear")
    var ms = MusicSave(); ms.song = song; ms.tunesLearned = ["mary"]
    check(try JSONDecoder().decode(MusicSave.self, from: JSONEncoder().encode(ms)) == ms, "round trip")
    let bad = try JSONDecoder().decode(SongSteps.self, from: Data(#"{"steps":[1,99,null,4],"instrument":"tuba"}"#.utf8))
    check(bad.steps.count == 8 && bad.steps[0] == 1 && bad.steps[1] == nil && bad.steps[3] == 4 && bad.instrument == .xylophone, "bad song data is cleaned up")
    check(ms.record(.echo, stars: 3) == 3 && ms.record(.echo, stars: 3) == 0 && MusicSave.maxStars == 9, "best only")
}

test("Writing Desk: every letter and number is well formed") {
    check(Alphabet.capitals.count == 26 && Alphabet.lowercase.count == 26 && Alphabet.digits.count == 10, "26 + 26 + 10 glyphs")
    let all = Alphabet.capitals + Alphabet.lowercase + Alphabet.digits
    check(Set(all.map(\.character)).count == all.count, "no repeats")
    for g in all {
        check(!g.strokes.isEmpty && g.strokes.allSatisfy { $0.count >= 2 }, "\(g.character) has strokes")
        let pts = g.strokes.flatMap { $0 }
        check(pts.allSatisfy { $0.x >= -0.01 && $0.x <= 0.66 && $0.y >= -0.01 && $0.y <= 1.01 }, "\(g.character) stays in its box")
        let tall = Alphabet.lowercase.contains(g) ? ["b", "d", "f", "h", "k", "l", "t"].contains(g.character) : true
        check(!tall || pts.map(\.y).min()! < 0.15, "\(g.character) reaches the top line")
        check(tall || pts.map(\.y).min()! > 0.15, "\(g.character) stays below the top line (dots aside)")
        for s in g.strokes where TraceChecker.length(s) > 0.1 {
            check(zip(s, s.dropFirst()).allSatisfy { $0.0.distance(to: $0.1) < 0.09 }, "\(g.character): no jumps inside a stroke")
        }
    }
    for c in ["g", "j", "p", "q", "y"] { check(Alphabet.glyph(c)!.maxY > 0.9, "\(c) has a tail") }
    for c in ["a", "c", "e", "m", "n", "o", "r", "s", "u", "v", "w", "x", "z"] { check(Alphabet.glyph(c)!.maxY < 0.85, "\(c) sits on the baseline") }
}

test("Writing Desk: the tracing checker") {
    var rng = SeededRNG(state: 7)
    let all = Alphabet.capitals + Alphabet.lowercase + Alphabet.digits
    for g in all {
        for s in g.strokes {
            check(TraceChecker.check(drawn: s, against: s) == .good, "\(g.character): an exact trace is good")
            let wobbly = s.map { PenPoint($0.x + Double.random(in: -0.05...0.05, using: &rng), $0.y + Double.random(in: -0.05...0.05, using: &rng)) }
            check(TraceChecker.check(drawn: wobbly, against: s) == .good, "\(g.character): a wobbly trace is still good")
            guard TraceChecker.length(s) > 0.3 else { continue }
            let closed = s.first!.distance(to: s.last!) < TraceChecker.startTolerance
            if !closed {
                check(TraceChecker.check(drawn: s.reversed(), against: s) == .wrongStart, "\(g.character): starting at the wrong end gets a hint")
            }
            check(TraceChecker.check(drawn: Array(s.prefix(s.count / 3)), against: s) == .notFinished, "\(g.character): stopping early isn't finished")
            let shifted = s.enumerated().map { $0.offset < 2 ? $0.element : PenPoint($0.element.x + 0.35, $0.element.y) }
            check(TraceChecker.check(drawn: shifted, against: s) != .good, "\(g.character): drawing off the line isn't good")
        }
    }
    let i = Alphabet.glyph("i")!
    check(TraceChecker.check(drawn: [PenPoint(0.31, 0.23)], against: i.strokes[1]) == .good, "a tap makes the dot")
    check(TraceChecker.check(drawn: [PenPoint(0.31, 0.7)], against: i.strokes[1]) == .wrongStart, "a tap far away doesn't")
    check(TraceChecker.check(drawn: [], against: i.strokes[0]) == .notFinished, "nothing drawn")
}

test("Writing Desk: rounds and saves") {
    for seed in 0..<200 {
        var rng = SeededRNG(state: UInt64(seed))
        for game in WritingGame.allCases {
            let r = WritingBank.rounds(for: game, using: &rng)
            check(r.count == (game == .words ? 3 : 5), "\(game) round count")
            check(Set(r.map(\.text)).count == r.count, "\(game) no repeats")
            check(r.allSatisfy { !$0.glyphs.isEmpty && !$0.say.isEmpty }, "\(game) rounds have letters and words")
            if game == .words { check(r.allSatisfy { $0.glyphs.count == 3 && !$0.picture.isEmpty }, "words: three letters and a picture") }
            if game == .numbers { check(r.allSatisfy { Int($0.text) != nil }, "numbers are digits") }
        }
    }
    check(Set(WritingBank.letterWords.keys).count == 26, "a word for every letter")
    var w = WritingSave()
    check(w.record(.capitals, stars: 2) == 2 && w.record(.capitals, stars: 1) == 0 && w.record(.capitals, stars: 3) == 1, "best only")
    w.written = ["A", "b"]
    check(try JSONDecoder().decode(WritingSave.self, from: JSONEncoder().encode(w)) == w, "round trip")
    check(try JSONDecoder().decode(WritingSave.self, from: Data("{}".utf8)) == WritingSave(), "empty save")
    check(WritingSave.maxStars == 12, "12 stars")
}

test("Clock Tower: times, hands and words") {
    check(ClockTime(3).digital == "3:00" && ClockTime(3, 5).digital == "3:05" && ClockTime(12, 45).digital == "12:45", "digital")
    check(ClockTime(13).hour == 1 && ClockTime(0).hour == 12 && ClockTime(-1).hour == 11, "hours wrap")
    check(ClockTime(3).spoken == "3 o'clock" && ClockTime(3, 30).spoken == "half past 3" && ClockTime(3, 15).spoken == "quarter past 3", "spoken")
    check(ClockTime(3, 45).spoken == "quarter to 4" && ClockTime(12, 45).spoken == "quarter to 1" && ClockTime(3, 50).spoken == "10 to 4", "to the next hour")
    check(ClockTime(3).hourAngle == 90 && ClockTime(3, 30).hourAngle == 105 && ClockTime(12).hourAngle == 0, "hour hand creeps")
    check(ClockTime(9, 45).minuteAngle == 270, "minute hand")
    check(ClockTime(11, 30).adding(minutes: 60) == ClockTime(12, 30) && ClockTime(12, 30).adding(minutes: 60) == ClockTime(1, 30), "an hour later wraps")
    check(ClockTime(2).adding(minutes: -60) == ClockTime(1), "an hour earlier")
    check(ClockHands.minute(fromAngle: 92) == 15 && ClockHands.minute(fromAngle: 358) == 0 && ClockHands.minute(fromAngle: 182) == 30, "snap minutes")
    check(ClockHands.hour(fromAngle: 2) == 12 && ClockHands.hour(fromAngle: 88) == 3 && ClockHands.hour(fromAngle: -30) == 11, "snap hours")
    check(abs(ClockHands.angle(dx: 1, dy: 0) - 90) < 0.001 && abs(ClockHands.angle(dx: 0, dy: 1) - 180) < 0.001 && ClockHands.angle(dx: 0, dy: -1) < 0.001, "screen angles")
    check(ClockHands.wind(ClockTime(3, 55), toMinute: 0) == ClockTime(4) && ClockHands.wind(ClockTime(4, 5), toMinute: 50) == ClockTime(3, 50), "winding past 12 moves the hour")
    check(ClockHands.wind(ClockTime(4, 20), toMinute: 30) == ClockTime(4, 30), "winding within the hour")
}

test("Clock Tower: every game, 300 seeds") {
    for seed in 0..<300 {
        var rng = SeededRNG(state: UInt64(seed))
        for game in ClockGame.allCases {
            let rounds = ClockBank.rounds(for: game, using: &rng)
            check(rounds.count == 5 && Set(rounds.map(\.time)).count == 5, "\(game): five different times")
            for r in rounds {
                switch game {
                case .oclock: check(r.time.minute == 0, "o'clock")
                case .halfPast: check([0, 30].contains(r.time.minute), "half past")
                case .quarters: check([15, 30, 45].contains(r.time.minute), "quarters")
                case .setClock, .hourLater: check([0, 30].contains(r.time.minute), "simple times")
                }
                if r.kind == .choose {
                    check(r.choices.count == 3 && Set(r.choices).count == 3 && r.choices.contains(r.answer), "\(game): three choices with the answer")
                } else {
                    check(r.choices.isEmpty && r.answer == r.time.digital, "set: no choices")
                }
                if game == .hourLater { check(r.answer == r.time.adding(minutes: 60).digital, "one hour later") }
                else { check(r.answer == r.time.digital, "the answer is the time shown") }
            }
        }
    }
    check(ClockBank.isSet(ClockTime(4, 30), to: ClockTime(4, 30)) && !ClockBank.isSet(ClockTime(5, 30), to: ClockTime(4, 30)), "set check")
    var c = ClockSave()
    check(c.record(.oclock, stars: 3) == 3 && c.record(.oclock, stars: 2) == 0 && ClockSave.maxStars == 15, "best only")
    check(try JSONDecoder().decode(ClockSave.self, from: JSONEncoder().encode(c)) == c, "round trip")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
