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
    for ch in [1, 2, 3, 4, 5, 6, 9, 12, 15, 18, 21] { check(StoryBook.after(chapter: ch) != nil, "a story after chapter \(ch)") }
    for ch in [7, 8, 10, 11, 13, 14, 16, 17, 19, 20, 101, 201] { check(StoryBook.after(chapter: ch) == nil, "no story after chapter \(ch)") }
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
    check(ClockTime(3, 30).handsDescription == "The short hand is between 3 and 4. The long hand points to 6.", "VoiceOver hands, half past")
    check(ClockTime(12).handsDescription == "The short hand is on 12. The long hand points to 12.", "VoiceOver hands, o'clock")
    check(!ClockTime(3, 15).handsDescription.contains("quarter"), "VoiceOver describes the hands, not the answer")
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

test("Around the World: the map puts real places on the right continent") {
    let places: [(String, Double, Double, Continent?)] = [
        ("Paris", 2.3, 48.9, .europe), ("Beijing", 116.4, 39.9, .asia), ("Cairo", 31.2, 30.0, .africa), ("Nairobi", 36.8, -1.3, .africa),
        ("Sydney", 151.2, -33.9, .australia), ("Alice Springs", 133.9, -23.7, .australia), ("Brasília", -47.9, -15.8, .southAmerica),
        ("Lima", -77.0, -12.0, .southAmerica), ("Chicago", -87.6, 41.9, .northAmerica), ("Mexico City", -99.1, 19.4, .northAmerica),
        ("Delhi", 77.2, 28.6, .asia), ("Riyadh", 46.7, 24.7, .asia), ("Sanaa", 44.2, 15.4, .asia), ("Moscow", 37.6, 55.8, .europe), ("South Pole station", 0, -80, .antarctica),
        ("Middle of the Pacific", -150, 0, nil), ("Middle of the Atlantic", -30, 10, nil), ("Indian Ocean", 80, -20, nil),
    ]
    for (name, lon, lat, want) in places {
        let p = WorldMap.point(lon: lon, lat: lat)
        check(WorldMap.continent(atX: p.x, y: p.y) == want, "\(name) → \(want?.name ?? "ocean")")
    }
    for c in Continent.allCases {
        let center = WorldMap.center(c)
        if c != .asia && c != .northAmerica { check(WorldMap.continent(atX: center.x, y: center.y) == c, "\(c.name)'s label sits on it") }
        check(c.mapOutline.allSatisfy { $0.x >= 0 && $0.x <= 1 && $0.y >= 0 && $0.y <= 0.5 }, "\(c.name) fits the map")
    }
    var overlaps = 0
    for xi in 0..<200 { for yi in 0..<100 {
        let x = Double(xi) / 200 + 0.0025, y = Double(yi) / 200 + 0.0025
        if Continent.allCases.filter({ WorldMap.contains($0.mapOutline, x: x, y: y) }).count > 1 { overlaps += 1 }
    } }
    check(overlaps < 20, "continents barely overlap (\(overlaps) of 20,000 points)")
}

test("Around the World: every game, 300 seeds, and wrong choices are really wrong") {
    for seed in 0..<300 {
        var rng = SeededRNG(state: UInt64(seed))
        for game in WorldGame.allCases {
            let rounds = WorldBank.rounds(for: game, using: &rng)
            check(rounds.count == 5 && Set(rounds.map(\.say)).count == 5, "\(game): five different rounds")
            for r in rounds {
                if r.kind == .tapMap {
                    check(Continent(rawValue: r.answer) != nil && r.continent?.rawValue == r.answer, "tap the named continent")
                } else {
                    check(r.choices.count == 3 && Set(r.choices).count == 3 && r.choices.contains(r.answer), "\(game): three choices with the answer")
                }
            }
        }
    }
    for t in WorldBank.animals + WorldBank.landmarks {
        var rng = SeededRNG(state: 1)
        check(WorldBank.wrongContinents(for: t, using: &rng).allSatisfy { !t.places.contains($0) }, "\(t.name): wrong choices never include a real home")
    }
    check(Set(WorldBank.animals.map(\.emoji)).count == WorldBank.animals.count, "no repeated animal pictures")
    check(Set((WorldBank.animals + WorldBank.landmarks).map(\.home)) == Set(Continent.allCases), "every continent has animals or places")
    check(WorldBank.oceans.allSatisfy { !$0.wrong.contains($0.answer) && $0.wrong.count == 2 }, "ocean questions")
    var w = WorldTourSave()
    check(w.collect([.asia, .asia, .africa]) == [.asia, .africa] && w.collect([.asia]).isEmpty && w.postcards.count == 2, "postcards collect once")
    check(w.record(.oceans, stars: 2) == 2 && WorldTourSave.maxStars == 12, "best only")
    check(try JSONDecoder().decode(WorldTourSave.self, from: JSONEncoder().encode(w)) == w, "round trip")
}

test("Grown-ups progress: skills, areas and milestones") {
    func area(_ id: String, _ bests: [Int]) -> LearningArea {
        LearningArea(id: id, title: id.capitalized + " Place", skills: bests.enumerated().map { SkillProgress(skill: "\(id) skill \($0.offset)", best: $0.element) })
    }
    check(SkillProgress(skill: "x", best: 0).status == .notStarted && SkillProgress(skill: "x", best: 1).status == .practising
          && SkillProgress(skill: "x", best: 3).status == .gotIt, "status from stars")
    let done = area("reading", [2, 3, 3]), half = area("clock", [1, 0, 3])
    check(done.finished && !half.finished && half.started && half.needsPractice.count == 1 && half.stars == 4 && half.maxStars == 9, "area sums")
    check(!area("empty", []).finished, "an empty area is never finished")
    var input = MilestoneInput(lifetimeStars: 60, areas: [done, half], postcards: 7, lettersWritten: 10, storyFinished: false)
    let ids = Milestones.reached(input).map(\.id)
    check(ids == ["stars25", "stars50", "area-reading", "postcards7"], "reached: \(ids)")
    check(Milestones.pending(input, shared: ["stars25", "area-reading"]).map(\.id) == ["stars50", "postcards7"], "pending skips shared ones")
    input.lettersWritten = 62; input.storyFinished = true; input.lifetimeStars = 600
    check(Milestones.reached(input).count == 9, "every milestone at once")
    let note = Milestones.note(name: "Sam", milestone: Milestones.reached(input).first, input: input)
    check(note.hasPrefix("HopQuest news: Sam just earned 25 stars"), "note opens with the news")
    check(note.contains("Skills practised: reading skill 0") && note.contains("Working on next: clock skill 0.") && note.contains("600"), "note lists skills and stars")
    check(!note.contains("@") && !note.contains("http"), "no links or addresses in the note")
    check(Milestones.note(name: "  ", milestone: nil, input: input).hasPrefix("HopQuest update for Your child"), "no name, no problem")
    check(Milestones.list(["a"]) == "a" && Milestones.list(["a", "b"]) == "a and b" && Milestones.list(["a", "b", "c"]) == "a, b and c", "lists read naturally")
    check(Milestones.cleanPhone(" (555) 123-4567 ") == "5551234567" && Milestones.cleanPhone("+44 20 7946 0958") == "+442079460958", "phone numbers")
    check(Milestones.cleanPhone("123") == "" && Milestones.cleanPhone("call me") == "", "not a phone number")
    var m = MilestoneSettings(); m.enabled = true; m.phone = "5551234567"; m.shared = ["stars25"]
    check(try JSONDecoder().decode(MilestoneSettings.self, from: JSONEncoder().encode(m)) == m, "round trip")
    check(try JSONDecoder().decode(MilestoneSettings.self, from: Data("{}".utf8)) == MilestoneSettings(), "off by default")
    check(try JSONDecoder().decode(MilestoneSettings.self, from: Data(#"{"enabled":true,"phone":"hi"}"#.utf8)).phone == "", "junk numbers are dropped")
}

test("Quick Game: physics, jumps, double jumps, gaps and the finish") {
    var g = QuickGameState.level(seed: 1)
    check(g.onGround && g.y == 0, "starts on the ground")
    g.step(1.0 / 60, QuickInput(jump: true))
    check(!g.onGround && g.jumpsUsed == 1 && g.vy > 0, "a tap jumps")
    for _ in 0..<10 { g.step(1.0 / 60, QuickInput()) }
    let before = g.vy
    g.step(1.0 / 60, QuickInput(jump: true))
    check(g.jumpsUsed == 2 && g.vy > before, "a second tap in the air double jumps")
    g.step(1.0 / 60, QuickInput(jump: true))
    check(g.jumpsUsed == 2, "no triple jump")
    for _ in 0..<120 { g.step(1.0 / 60, QuickInput()) }
    check(g.onGround && g.jumpsUsed == 0, "lands and can jump again")
    let x0 = g.x
    for _ in 0..<30 { g.step(1.0 / 60, QuickInput(left: true)) }
    check(g.x < x0 && !g.facingRight, "holding left runs left")
    for _ in 0..<1000 { g.step(1.0 / 60, QuickInput(left: true)) }
    check(g.x >= -150, "can't run off the start")

    // a simple player: run right, jump at every edge, double jump at the top. Every seed must be finishable in time.
    for seed in 0..<60 {
        var q = QuickGameState.level(seed: UInt64(seed))
        var frames = 0
        while !q.over && frames < 60 * 70 {
            let ahead = q.floor(at: q.x + 40, below: q.y + 1)
            let jump = q.onGround && (ahead == nil || ahead! < q.y - 1 || (q.floor(at: q.x + 40, below: q.y + 60) ?? 0) > q.y)
            let dbl = !q.onGround && q.jumpsUsed == 1 && q.vy < 50 && q.floor(at: q.x + 60, below: q.y) == nil
            q.step(1.0 / 60, QuickInput(right: true, jump: jump || dbl))
            frames += 1
        }
        check(q.finished, "seed \(seed): reachable finish (falls \(q.falls))")
        check(q.collected > 0 && q.score >= q.collected * 10 + 50, "seed \(seed): stars and finish bonus")
    }

    // every star sits where a jump or double jump can reach: within 230 of the platform under it
    for seed in 0..<60 {
        let q = QuickGameState.level(seed: UInt64(seed))
        for s in q.stars {
            let under = q.platforms.filter { s.x >= $0.x - 80 && s.x <= $0.x + $0.width + 80 && $0.y <= s.y }.map(\.y).max()
            check(under != nil && s.y - under! <= 230, "seed \(seed): star at \(Int(s.x)) can be reached")
        }
    }
    var f = QuickGameState.level(seed: 3)
    f.x = 900; f.y = -100; f.vy = -500; f.onGround = false
    for _ in 0..<60 where f.falls == 0 { f.step(1.0 / 60, QuickInput()) }
    check(f.falls == 1 && f.floatBack > 0, "falling into a gap floats you back")
    for _ in 0..<80 { f.step(1.0 / 60, QuickInput()) }
    check(f.onGround && f.y >= 0 && f.floatBack <= 0, "back on safe ground")
    var t = QuickGameState.level(seed: 4)
    for _ in 0..<(61 * 60) { t.step(1.0 / 60, QuickInput()) }
    check(t.over && !t.finished && t.timeLeft == 0, "time runs out after a minute")
}

test("Widget: snapshot saving and the Star Hop game") {
    let d = UserDefaults(suiteName: "hopquest.tests.widget")!
    d.removePersistentDomain(forName: "hopquest.tests.widget")
    check(SharedStore.loadSnapshot(d) == .placeholder, "placeholder before the app writes")
    var snap = WidgetSnapshot.placeholder; snap.stars = 42; snap.name = "Sam"
    check(SharedStore.save(snap, d), "first save changes")
    check(!SharedStore.save(snap, d), "saving the same thing again changes nothing (no extra widget reloads)")
    check(SharedStore.loadSnapshot(d) == snap, "round trip")
    check(WidgetSnapshot(name: "", buddyName: "", buddyEmoji: "", buddyID: "", stars: 0, lifetimeStars: 0, lessonTitle: "", skill: "",
                         skillState: "", skillsLearned: 5, skillsTotal: 0, quickBest: 0).progress == 0, "no divide by zero")

    var h = StarHop()
    check(h.level == 1 && h.hearts == 3 && h.clouds.isEmpty && h.stars.count == 2 && h.goal == 8, "a new game starts on level 1")
    h.stars = []
    h.right()
    check(h.row == 1 && h.col == 2 && h.jumps == 1 && h.message == "Jump!" && !h.facingLeft, "tap right jumps up and right")
    h.stars = []
    h.right()
    check(h.row == 2 && h.col == 3 && h.jumps == 2 && h.message == "Double jump!", "tap right again in the air double jumps")
    h.stars = []
    h.right()
    check(h.row == 1 && h.col == 4, "a third tap glides down")
    h.stars = []
    h.left()
    check(h.row == 0 && h.col == 3 && h.jumps == 0 && h.facingLeft, "tap left steps left, comes down and faces left")
    h.left(); h.left(); h.left(); h.left()
    check(h.col == 5, "the board wraps around")
    check(h.stars.count == 2 && !h.stars.contains { $0.cell == h.buddyCell }, "always two stars, never on the buddy")
    check(h.stars.allSatisfy { (0..<(StarHop.columns * StarHop.rows)).contains($0.cell) }, "stars stay on the board")
    check(Set(h.stars.map(\.id)).count == h.stars.count, "every star has its own id (so the widget can animate it)")

    // catching
    var c = StarHop()
    c.stars = [HopStar(id: 90, cell: c.cell(2, 1))]
    c.right()
    check(c.collected == 1 && c.lastCatch == c.cell(2, 1) && c.message.hasPrefix("Got it"), "landing on a star catches it")
    c.startLevel(2)
    c.clouds = []
    c.stars = [HopStar(id: 91, cell: c.cell(2, 1), golden: true)]
    c.right()
    check(c.collected == 2 && c.message == "Golden star! +2", "golden stars count twice")

    // clouds
    var b = StarHop(); b.startLevel(2)
    check(b.clouds.count == 1 && b.clouds.allSatisfy { $0 / StarHop.columns > 0 }, "level 2 has one puff cloud, up in the sky")
    b.clouds = [b.cell(2, 1)]; b.stars = []
    b.right()
    check(b.hearts == 2 && b.bumped && b.row == 0 && b.jumps == 0, "bumping a cloud costs a heart and drops you to the ground")
    b.stars = []
    b.left()
    check(!b.bumped && b.hearts == 2, "the ground is always safe")
    b.hearts = 1; b.clouds = [b.cell((b.col + 1) % StarHop.columns, 1)]; b.stars = []
    b.right()
    check(b.outOfHearts && !b.playing && b.message == "Out of hearts!", "no hearts left ends the try")
    let stuck = b
    b.right(); b.left()
    check(b == stuck, "no moves while out of hearts")
    b.retry()
    check(b.level == 2 && b.hearts == 3 && b.collected == 0 && b.playing, "try again restarts the same level")

    // counting, spelling and counting by twos
    var n = StarHop(); n.startLevel(3)
    check(n.sequence == ["1", "2", "3", "4", "5", "6"] && n.needed == "1" && n.goal == 6, "level 3 counts 1 to 6")
    check(n.stars.contains { $0.label == "1" } && n.stars.count == 2 && Set(n.stars.compactMap(\.label)).count == 2,
          "the number needed is always on the board, with one other number")
    n.clouds = []
    n.stars = [HopStar(id: 80, cell: n.cell(2, 1), label: "4")]
    n.right()
    check(n.collected == 0 && n.hearts == 3 && n.message == "That's 4. Find 1 first!", "a wrong number does no harm")
    check(n.stars.contains { $0.label == "1" }, "and the right one is still there")
    n.stars = [HopStar(id: 81, cell: n.cell(3, 2), label: "1")]
    n.right()
    check(n.collected == 1 && n.needed == "2", "the right number counts")
    var w = StarHop(); w.startLevel(5)
    check(w.word != nil && w.sequence.joined() == w.word && Set(w.sequence).count == w.sequence.count, "level 5 spells a word with no repeated letters")
    let firstWord = w.word
    w.retry()
    check(w.word != firstWord, "trying again gives a new word")
    var t = StarHop(); t.startLevel(6)
    check(t.sequence == ["2", "4", "6", "8", "10", "12"] && t.info.night && t.clouds.count == 2, "level 6 counts by twos at night")
    check(StarHop.words.allSatisfy { Set($0).count == $0.count }, "no spelling word repeats a letter")

    // Star Hop 3: new levels, springs, bubbles, ratings
    check(StarHop.levels.count == 12 && StarHop.levels.map(\.number) == Array(1...12), "twelve levels, numbered in order")
    var abc = StarHop(); abc.startLevel(7)
    check(abc.sequence == ["A", "B", "C", "D", "E", "F"] && abc.needed == "A", "ABC Garden is the alphabet in order")
    var down = StarHop(); down.startLevel(8)
    check(down.sequence == ["6", "5", "4", "3", "2", "1"], "Rocket Launch counts down")
    var tens = StarHop(); tens.startLevel(10)
    check(tens.sequence == ["10", "20", "30", "40", "50", "60"], "Tens Tower counts by tens")
    for lv in [9, 11] {
        for plays in 0..<60 {
            var m = StarHop(); m.plays = plays; m.startLevel(lv)
            check(m.prompts.count == 5 && m.sequence.count == 5, "level \(lv): five questions")
            for (q, a) in zip(m.prompts, m.sequence) {
                let parts = q.split(separator: " ")
                let x = Int(parts[0])!, y = Int(parts[2])!, ans = Int(a)!
                check((lv == 9 ? x + y : x - y) == ans && (1...10).contains(ans), "level \(lv): \(q) = \(a) is right and between 1 and 10")
            }
            check(zip(m.sequence, m.sequence.dropFirst()).allSatisfy { $0 != $1 }, "level \(lv): no answer twice in a row")
            check(m.stars.contains { $0.label == m.needed } && m.stars.filter { $0.label != m.needed }.allSatisfy { $0.label.flatMap(Int.init).map { (1...10).contains($0) } ?? false },
                  "level \(lv): the answer is on the board, next to a different number")
        }
    }
    var mq = StarHop(); mq.startLevel(9); mq.clouds = []
    let q0 = mq.prompt!, a0 = mq.needed!
    mq.stars = [HopStar(id: 70, cell: mq.cell(2, 1), label: a0)]
    mq.right()
    check(mq.collected == 1 && mq.message == "\(q0) = \(a0)! ✓", "catching the answer says the whole sum")

    var sp = StarHop(); sp.startLevel(7); sp.clouds = []; sp.stars = []
    sp.col = 4; sp.row = 0
    sp.left()
    check(sp.col == 3 && sp.row == StarHop.rows - 1 && sp.jumps == 2 && sp.bounced && sp.message == "Boing!", "a spring pad bounces you to the top")
    check(!sp.stars.contains { $0.cell == sp.cell(3, 0) }, "stars never sit on the spring")

    var bu = StarHop(); bu.startLevel(4); bu.stars = []
    bu.bubble = bu.cell(2, 1); bu.clouds = [bu.cell(4, 2), bu.cell(5, 1)]
    bu.right()
    check(bu.shield && bu.bubble == nil && bu.message.hasPrefix("Bubble shield"), "catching a bubble gives a shield")
    bu.clouds = [bu.cell(3, 2)]; bu.stars = []
    bu.right()
    check(!bu.shield && bu.popped && bu.hearts == 3 && bu.bumps == 0 && bu.row == 2, "the bubble takes the bump, no heart lost")
    var sawBubble = false
    var bg = StarHop(); bg.startLevel(4)
    for _ in 0..<40 where bg.playing { bg.left(); if bg.bubble != nil { sawBubble = true } }
    check(sawBubble, "bubbles do show up on bubble levels")
    var nb = StarHop()
    for _ in 0..<40 where nb.playing { nb.left(); check(nb.bubble == nil, "no bubbles on level 1") }

    var r = StarHop(); r.clouds = []
    r.collected = r.goal - 1; r.stars = [HopStar(id: 60, cell: r.cell(2, 1))]
    r.right()
    check(r.levelDone && r.lastRating == 3 && r.rating[0] == 3 && r.totalRating == 3, "no bumps and quick feet: three stars")
    var r2 = StarHop(); r2.startLevel(2); r2.bumps = 1; r2.moves = r2.par + 5; r2.clouds = []
    r2.collected = r2.goal - 1; r2.stars = [HopStar(id: 61, cell: r2.cell(2, 1))]
    r2.right()
    check(r2.lastRating == 1 && r2.rating[1] == 1, "bumped and slow: one star for finishing")
    r2.rating[1] = 3; r2.retry(); r2.bumps = 1; r2.clouds = []; r2.collected = r2.goal - 1; r2.stars = [HopStar(id: 62, cell: r2.cell(2, 1))]
    r2.right()
    check(r2.rating[1] == 3, "a level keeps its best rating")

    // saves from before Star Hop 3 keep their progress
    let old = #"{"level":4,"col":1,"row":0,"jumps":0,"facingLeft":false,"stars":[],"clouds":[],"collected":3,"sequence":[],"hearts":2,"moves":9,"turn":40,"nextStarID":30,"plays":5,"best":[20,18,25,0,0,0],"levelsCleared":3,"message":"Hi","bumped":false}"#
    let up = try! JSONDecoder().decode(StarHop.self, from: Data(old.utf8))
    check(up.level == 4 && up.levelsCleared == 3 && up.best.count == 12 && Array(up.best.prefix(3)) == [20, 18, 25], "an old save keeps its level and bests")
    check(Array(up.rating.prefix(4)) == [1, 1, 1, 0] && up.rating.count == 12, "levels finished before ratings count as one star")
    check(up.playing && up.hearts == 3 && up.stars.count == 2, "and the level starts fresh under the new rules")
    let rt = try! JSONDecoder().decode(StarHop.self, from: try! JSONEncoder().encode(r2))
    check(rt == r2, "a new save round-trips exactly")

    // picking levels
    var p = StarHop()
    p.pick(3)
    check(p.level == 1, "levels not reached yet can't be picked")
    p.levelsCleared = 2; p.pick(3)
    check(p.level == 3, "the next level after the ones finished can be picked")

    // a careful player can finish every level: look a few taps ahead for a catch that doesn't bump a cloud
    func plan(_ g: StarHop) -> Bool {
        var frontier: [(StarHop, Bool)] = [(g, true), (g, false)].map { s, r in var s = s; if r { s.right() } else { s.left() }; return (s, r) }
        for _ in 0..<7 {
            if let hit = frontier.first(where: { $0.0.collected > g.collected && $0.0.hearts == g.hearts }) { return hit.1 }
            var next: [(StarHop, Bool)] = []
            for (s, first) in frontier where s.hearts == g.hearts {
                var a = s; a.right(); next.append((a, first))
                var l = s; l.left(); next.append((l, first))
            }
            frontier = next
        }
        // nothing in reach yet: take a safe step
        var r = g; r.right()
        if r.hearts == g.hearts { return true }
        return false
    }
    for seed in 0..<12 {
        var g = StarHop(); g.turn = seed * 7; g.plays = seed
        g.startLevel(1)
        var taps = 0, tries = 0
        while taps < 3000 {
            if g.champion { break }
            if g.levelDone { g.nextLevel(); continue }
            if g.outOfHearts { g.retry(); tries += 1; continue }
            if plan(g) { g.right() } else { g.left() }
            taps += 1
        }
        check(g.champion && g.levelsCleared == StarHop.levels.count, "seed \(seed): every level can be finished (\(taps) taps, \(tries) retries)")
        check(g.best.allSatisfy { $0 > 0 }, "seed \(seed): a best for every level")
        let snap = g
        g.right()
        check(g == snap, "no moves after finishing a level")
        g.nextLevel()
        check(g.level == 1 && g.best == snap.best && g.levelsCleared == StarHop.levels.count, "after the last level it starts over, keeping the bests")
    }
    SharedStore.save(h, d)
    check(SharedStore.loadHop(d) == h, "game round trip")
    d.removePersistentDomain(forName: "hopquest.tests.widget")
}

test("Spelling Bee, Fraction Bakery and Shape Studio: every game, 300 seeds, and the answers are really right") {
    func value(_ s: String) -> Double? {
        let p = s.split(separator: "/"); guard p.count == 2, let a = Double(p[0]), let b = Double(p[1]), b > 0 else { return nil }
        return a / b
    }
    let places: [([QuizGameInfo], (String, inout SeededRNG) -> [QuizRound])] = [
        (SpellingBank.games, { SpellingBank.rounds(for: $0, using: &$1) }),
        (FractionBank.games, { FractionBank.rounds(for: $0, using: &$1) }),
        (ShapeBank.games, { ShapeBank.rounds(for: $0, using: &$1) }),
    ]
    for (games, make) in places {
        check(games.count == 4 && Set(games.map(\.id)).count == 4, "four games")
        for g in games {
            for seed in 0..<300 {
                var rng = SeededRNG(state: UInt64(seed))
                let rounds = make(g.id, &rng)
                check(rounds.count == 5, "\(g.id): five rounds")
                for r in rounds {
                    if r.kind == .spell {
                        var tiles = r.choices
                        let ok = r.answer.allSatisfy { ch in
                            if let i = tiles.firstIndex(of: String(ch)) { tiles.remove(at: i); return true }
                            return false
                        }
                        check(ok && r.choices.count == r.answer.count + 2, "\(g.id): the tiles spell \(r.answer), plus two extras")
                    } else {
                        check(r.choices.contains(r.answer) && Set(r.choices).count == r.choices.count && r.choices.count >= 2, "\(g.id): choices hold the answer once")
                        check(r.choiceVisuals.isEmpty || r.choiceVisuals.count == r.choices.count, "\(g.id): one picture per choice")
                    }
                    if let v = value(r.answer), r.choiceVisuals.isEmpty {
                        check(r.choices.filter { value($0) == v }.count == 1, "\(g.id): no other choice is the same fraction (\(r.choices))")
                    }
                    if case .fraction(let parts, let shaded, _) = r.visual {
                        check(shaded >= 0 && shaded <= parts && value(r.answer) == Double(shaded) / Double(parts), "name: the picture shows \(r.answer)")
                    }
                    if g.id == "findHalf", case .text(let f) = r.visual {
                        let matches = r.choiceVisuals.enumerated().filter { _, v in
                            if case .fraction(let p, let s, _) = v { return Double(s) / Double(p) == value(f)! && s <= p }
                            return false
                        }
                        check(matches.count == 1 && r.choices[matches[0].offset] == r.answer, "findHalf: exactly one picture shows \(f)")
                        check(r.choiceVisuals.allSatisfy { if case .fraction(let p, let s, _) = $0 { return s >= 0 && s <= p } else { return false } }, "pictures are valid")
                    }
                    if g.id == "bigger", r.choices.count == 2 {
                        check(value(r.answer)! >= r.choices.compactMap(value).max()!, "bigger: the answer is the bigger slice")
                    }
                    if g.id == "sides", case .shapes(let s) = r.visual { check(r.answer == "\(s[0].sides)", "sides counted right") }
                    if g.id == "pattern", case .pattern(let s) = r.visual { check(s.count >= 4, "a pattern long enough to see") }
                }
            }
        }
    }
    check(SpellingBank.tricky.allSatisfy { !$0.wrong.contains($0.word) }, "misspellings are really wrong")
    check(SpellingBank.magicE.allSatisfy { $0.long == $0.short + "e" }, "magic e words")
    check(FractionBank.words(1, 2) == "one half" && FractionBank.words(3, 4) == "three quarters" && FractionBank.words(2, 2) == "two halves", "fraction words")
    check(ShapeKind.hexagon.sides == 6 && ShapeKind.circle.sides == 0 && ShapeKind.cube.isSolid, "shape facts")
    var ps = PlaceSave()
    check(ps.record("x", stars: 2) == 2 && ps.record("x", stars: 1) == 0 && ps.totalStars == 2, "place save best only")
    check(try JSONDecoder().decode(PlaceSave.self, from: JSONEncoder().encode(ps)) == ps, "round trip")
}

test("Story Maker: sentences, titles and saving") {
    let page = { (place: StoryPlace, action: String, thing: String) in
        MadePage(place: place, heroID: "pip", heroName: "Pip Penguin", heroEmoji: "🐧", action: action, thing: thing)
    }
    let pages = [page(.beach, "found", "shell"), page(.jungle, "shared", "shell"), page(.castle, "gave", "crown")]
    check(StoryMakerBank.sentence(pages[0], index: 0) == "One day, Pip Penguin went to the beach and found a shiny shell.", "page one")
    check(StoryMakerBank.sentence(pages[1], index: 1) == "Then at the jungle, Pip shared a shiny shell with a friend.", "page two")
    check(StoryMakerBank.sentence(pages[2], index: 2).hasPrefix("At last, at the castle, Pip gave a golden crown"), "page three")
    check(StoryMakerBank.title(for: pages) == "Pip and the Golden Crown", "title from the last thing")
    for a in StoryMakerBank.actions { check(a.text.contains("{thing}"), "\(a.id) uses the thing") }
    for p in StoryMakerBank.places { check(!StoryMakerBank.placeName(p).isEmpty, "place name") }
    check(Set(StoryMakerBank.things.map(\.id)).count == StoryMakerBank.things.count, "unique things")
    check(StoryMakerBank.isComplete(pages) && !StoryMakerBank.isComplete(Array(pages.prefix(2))), "three pages make a story")
    var sv = StoryMakerSave()
    var given = 0
    for i in 0..<8 { given += sv.save(MadeStory(id: "s\(i)", pages: pages, made: Date(timeIntervalSince1970: Double(i)))) }
    check(given == 3 && sv.stories.count == StoryMakerBank.maxSaved && sv.stories.first?.id == "s7", "three stars ever, six newest kept")
    check(sv.save(MadeStory(id: "x", pages: Array(pages.prefix(1)), made: Date())) == 0 && sv.stories.first?.id == "s7", "half a story isn't saved")
    sv.delete("s7")
    check(sv.stories.first?.id == "s6", "delete")
    let data = try JSONEncoder().encode(sv)
    check(try JSONDecoder().decode(StoryMakerSave.self, from: data) == sv, "round trip")
}

test("Badges: earned from real progress, never lost") {
    check(Set(Badges.all.map(\.id)).count == Badges.all.count && Badges.all.count == 32, "32 unique badges")
    check(Badges.earned(BadgeInput()).isEmpty, "nothing at the start")
    var b = BadgeInput()
    b.chaptersDone = [1]; b.lifetimeStars = 160; b.finishedAreas = ["reading", "clock"]
    let ids = Set(Badges.earned(b).map(\.id))
    check(ids == ["firstHop", "stars50", "stars150", "area-reading", "area-clock"], "earned: \(ids.sorted())")
    b.chaptersDone.insert(21); b.postcards = 7; b.lettersWritten = 62; b.storiesMade = 3; b.biggestIsland = 40; b.dashFinished = true
    b.codePuzzles = 10; b.stickers = 20; b.lifetimeStars = 300
    check(!Badges.earned(b).contains { $0.id == "hopper" }, "Star Hopper needs the widget levels")
    b.hopLevels = 12
    b.finishedAreas = Set(Badges.areaBadges.map(\.0))
    check(Badges.earned(b).count == Badges.all.count, "every badge can be earned")
    check(Badges.all.allSatisfy { !$0.how.isEmpty && !$0.title.isEmpty }, "every badge says how to earn it")
    check(!Badges.all.contains { $0.how.lowercased().contains("every day") || $0.how.lowercased().contains("in a row") }, "no streaks")
}

test("Español: the interface table, patterns and the narrator never mixing languages") {
    check(L10n.patterns.count == L10n.rawPatterns.count + L10n.moreRawPatterns.count, "every pattern compiles")
    check(L10n.spanish("Play") == "Jugar" && L10n.spanish("Hi, Mar!") == "¡Hola, Mar!", "words and patterns")
    check(L10n.spanish("12 of 15 stars") == "12 de 15 estrellas" && L10n.spanish("You did it! 3 new stars!") == "¡Lo lograste! ¡3 estrellas nuevas!", "numbers")
    check(L10n.spanishSpeech("Not quite. Try another one!") == "Casi. ¡Prueba otra!", "a whole line")
    check(L10n.spanishSpeech("Pick a game! Nice!") == "¡Elige un juego! ¡Bien!", "sentence by sentence")
    check(L10n.spanishSpeech("Pick a game! How much is colored?") == nil, "half-translated lines stay English")
    check(L10n.table.values.allSatisfy { !$0.isEmpty } && L10n.table.count > 150, "a full table")
    let titles = WritingGame.allCases.map(\.title) + ClockGame.allCases.map(\.title) + WorldGame.allCases.map(\.title)
        + SpellingBank.games.map(\.title) + FractionBank.games.map(\.title) + ShapeBank.games.map(\.title)
        + RhymeBank.games.map(\.title) + NumberBank.games.map(\.title) + TimesBank.games.map(\.title) + MeasureBank.games.map(\.title) + FeelingsBank.games.map(\.title)
        + HatKind.allCases.map(\.title)
        + NatureBank.games.map(\.title) + CalendarBank.games.map(\.title) + CompassBank.games.map(\.title)
        + ReadingGame.allCases.map(\.title) + MarketGame.allCases.map(\.title) + Continent.allCases.map(\.name)
    for t in titles { check(L10n.spanish(t) != nil, "\(t) has Spanish") }
    let intros = WritingGame.allCases.map(\.intro) + ClockGame.allCases.map(\.intro) + WorldGame.allCases.map(\.intro)
        + SpellingBank.games.map(\.intro) + FractionBank.games.map(\.intro) + ShapeBank.games.map(\.intro)
        + RhymeBank.games.map(\.intro) + NumberBank.games.map(\.intro) + TimesBank.games.map(\.intro) + MeasureBank.games.map(\.intro) + FeelingsBank.games.map(\.intro)
        + NatureBank.games.map(\.intro) + CalendarBank.games.map(\.intro) + CompassBank.games.map(\.intro)
    for t in intros { check(L10n.spanish(t) != nil, "intro has Spanish: \(t)") }
    check(Set(L10n.table.keys).isDisjoint(with: L10n.more.keys), "no word translated twice")
    check(L10n.spanish("Level 3 done!") == "¡Nivel 3 terminado!" && L10n.spanish("You earned 4 stars in Star Hop!") == "¡Ganaste 4 estrellas en Salto Estelar!", "new patterns")
    UserDefaults.standard.set(AppLanguage.english.rawValue, forKey: L10n.key)
    check(L10n.tr("Play") == "Play", "English stays English")
    UserDefaults.standard.set(AppLanguage.spanish.rawValue, forKey: L10n.key)
    check(L10n.tr("Play") == "Jugar" && L10n.tr("Not in the table") == "Not in the table", "Spanish, with English for anything missing")
    UserDefaults.standard.removeObject(forKey: L10n.key)
}

test("Rhyme Pond, Number Builder, Times Treehouse, Measure Meadow, Feelings Corner: every game, 300 seeds, answers really right") {
    let places: [(String, [QuizGameInfo], (String, inout SeededRNG) -> [QuizRound])] = [
        ("rhyme", RhymeBank.games, { RhymeBank.rounds(for: $0, using: &$1) }),
        ("numbers", NumberBank.games, { NumberBank.rounds(for: $0, using: &$1) }),
        ("times", TimesBank.games, { TimesBank.rounds(for: $0, using: &$1) }),
        ("measure", MeasureBank.games, { MeasureBank.rounds(for: $0, using: &$1) }),
        ("feelings", FeelingsBank.games, { FeelingsBank.rounds(for: $0, using: &$1) }),
    ]
    // rhyme families really are separate: no word sits in two families, and words in a family share an ending sound
    let allWords = RhymeBank.families.flatMap { $0.map(\.word) }
    check(Set(allWords).count == allWords.count, "no word is in two rhyme families")
    func family(_ w: String) -> Int? { RhymeBank.families.firstIndex { $0.contains { $0.word == w } } }
    check(RhymeBank.finish.allSatisfy { family($0.end) != nil }, "every rhyme ending is in a family")
    check(RhymeBank.finish.allSatisfy { f in f.start.lowercased().split(separator: " ").contains { family(String($0)) == family(f.end) } },
          "every silly sentence has a word that rhymes with its ending")
    check(Set(RhymeBank.finish.map { family($0.end) }).count == RhymeBank.finish.count, "sentence endings are all from different families")
    for (place, games, make) in places {
        check(games.count == 4 && Set(games.map(\.id)).count == 4, "\(place): four games")
        for g in games {
            for seed in 0..<300 {
                var rng = SeededRNG(state: UInt64(seed))
                let rounds = make(g.id, &rng)
                check(rounds.count == 5, "\(place)/\(g.id): five rounds")
                for r in rounds {
                    check(r.choices.contains(r.answer) && Set(r.choices).count == r.choices.count && r.choices.count >= 2, "\(place)/\(g.id): choices hold the answer once (\(r.choices))")
                    check(r.choiceVisuals.isEmpty || r.choiceVisuals.count == r.choices.count, "\(place)/\(g.id): one picture per choice")
                    switch (place, g.id) {
                    case ("rhyme", "rhyme"):
                        let target = r.say.split(separator: " ").last!.dropLast()
                        check(family(r.answer) == family(String(target)) && r.answer != String(target), "rhyme: \(r.answer) rhymes with \(target)")
                        check(r.choices.filter { family($0) == family(String(target)) }.count == 1, "rhyme: only one choice rhymes")
                    case ("rhyme", "oddOne"):
                        let others = r.choices.filter { $0 != r.answer }
                        check(family(others[0]) == family(others[1]) && family(r.answer) != family(others[0]), "oddOne: \(r.answer) is the odd one")
                    case ("rhyme", "beats"):
                        let w = RhymeBank.beats.first { r.say.hasPrefix($0.word.capitalized + ".") }
                        check(w != nil && r.answer == "\(w!.beats)", "beats: \(r.say) → \(r.answer)")
                    case ("rhyme", "finish"):
                        check(r.choices.filter { c in RhymeBank.finish.contains { r.say.hasPrefix($0.start) && family($0.end) == family(c) } }.count == 1, "finish: only one ending rhymes")
                        // no wrong choice rhymes with any word in the sentence either ("sat" would make "hat" right too)
                        let words = Set(r.say.lowercased().split { !$0.isLetter }.map(String.init))
                        for c in r.choices where c != r.answer {
                            check(!words.contains { family($0) != nil && family($0) == family(c) } && !words.contains("sat"),
                                  "finish: \(c) doesn't also rhyme with \(r.say)")
                        }
                    case ("numbers", "count"):
                        if case .blocks(let t, let o) = r.visual { check(r.answer == "\(t * 10 + o)" && o > 0 && o < 10, "count: blocks show \(r.answer)") } else { check(false, "count shows blocks") }
                    case ("numbers", "tens"):
                        if case .text(let v) = r.visual, let n = Int(v) {
                            check(r.answer == (r.say.contains("tens") ? "\(n / 10)" : "\(n % 10)"), "tens: \(r.say) → \(r.answer)")
                        }
                    case ("numbers", "build"):
                        if case .text(let v) = r.visual, let n = Int(v) {
                            let ok = r.choiceVisuals.enumerated().filter { _, cv in if case .blocks(let t, let o) = cv { return t * 10 + o == n && o < 10 } else { return false } }
                            check(ok.count == 1 && r.choices[ok[0].offset] == r.answer, "build: exactly one picture makes \(n)")
                        }
                    case ("numbers", "bigger"):
                        check(Int(r.answer)! == r.choices.compactMap(Int.init).max()! && Set(r.choices).count == 2, "bigger: \(r.answer) is the bigger one")
                        for (c, cv) in zip(r.choices, r.choiceVisuals) { if case .blocks(let t, let o) = cv { check("\(t * 10 + o)" == c, "bigger: pictures match their numbers") } }
                    case ("times", "groups"), ("times", "arrays"):
                        if case .groups(let c, let e, _, let rows) = r.visual { check(r.answer == "\(c * e)" && rows == (g.id == "arrays"), "\(g.id): \(c) × \(e) = \(r.answer)") }
                    case ("times", "skip"):
                        if case .text(let t) = r.visual {
                            let nums = t.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                            check(nums.count == 3 && Int(r.answer)! - nums[2] == nums[1] - nums[0], "skip: \(t) → \(r.answer)")
                        }
                    case ("times", "match"):
                        let ok = r.choiceVisuals.enumerated().filter { _, cv in
                            if case .groups(let c, let e, _, _) = cv { return r.say.contains("\(c) groups of \(e)?") } else { return false }
                        }
                        check(ok.count == 1 && r.choices[ok[0].offset] == r.answer, "match: exactly one picture is \(r.say)")
                    case ("measure", "longer"):
                        let lens = r.choiceVisuals.compactMap { cv -> Int? in if case .bar(let n, _, _) = cv { return n } else { return nil } }
                        let target = r.say.contains("longest") ? lens.max()! : lens.min()!
                        check(Set(lens).count == lens.count && r.choices[lens.firstIndex(of: target)!] == r.answer, "longer: the right ribbon")
                    case ("measure", "units"):
                        if case .bar(let n, _, let units) = r.visual { check(units && r.answer == "\(n)", "units: \(n) blocks") }
                    case ("measure", "heavy"):
                        let pair = MeasureBank.heavy.first { r.choices.contains($0.bigName) && r.choices.contains($0.smallName) }
                        check(pair != nil && r.answer == (r.say.contains("heavier") ? pair!.bigName : pair!.smallName), "heavy: \(r.say) → \(r.answer)")
                    case ("measure", "tools"):
                        check(MeasureBank.tools.contains { r.say.contains($0.ask) && $0.tool == r.answer }, "tools: \(r.answer)")
                    case ("feelings", "faces"):
                        if case .picture(let f) = r.visual { check(FeelingsBank.faces.first { $0.face == f }?.feeling == r.answer, "faces: \(f) is \(r.answer)") }
                        check(r.choices.allSatisfy { !(FeelingsBank.lookAlikes[r.answer] ?? []).contains($0) }, "faces: no look-alike feeling offered as wrong")
                        if case .picture(let f) = r.visual { check(r.visual.spoken != nil && !r.visual.spoken!.lowercased().contains(r.answer), "faces: described for VoiceOver without giving the answer (\(f))") }
                    case ("feelings", "stories"):
                        let st = FeelingsBank.stories.first { r.say.hasPrefix($0.text) }!
                        check(r.answer == st.answer && r.choices.filter { st.fits.contains($0) }.count == 1, "stories: only one choice fits \(st.text)")
                    case ("feelings", "helps"):
                        check(FeelingsBank.helps.contains { $0.good == r.answer }, "helps: the helpful choice")
                    default:
                        check(FeelingsBank.kind.contains { $0.kind == r.answer }, "kind: the kind words")
                    }
                }
            }
        }
    }
    check(QuizVisual.blocks(tens: 3, ones: 1).spoken == "3 tens and 1 one" && QuizVisual.groups(count: 2, each: 4, item: "🍎", rows: false).spoken == "2 groups of 4",
          "pictures are described for VoiceOver")
}

test("Breathe with Buddy, Surprise Me and buddy hats") {
    let b = BreathPlan()
    check(b.total == 55 && b.breathLength == 11, "five slow breaths, 11 seconds each (in 4, hold 2, out 5)")
    check(b.state(at: 0).step == .breatheIn && b.state(at: 0).size == 0, "starts empty, breathing in")
    check(b.state(at: 4.5).step == .hold && b.state(at: 4.5).size == 1, "full while holding")
    check(b.state(at: 8.5).step == .breatheOut && abs(b.state(at: 8.5).size - 0.5) < 0.01, "halfway out, half full")
    check(b.state(at: 11.2).breath == 2 && b.state(at: 11.2).step == .breatheIn, "then the next breath")
    check(b.state(at: 60).step == .done && b.state(at: -3).step == .breatheIn, "done at the end, safe before the start")
    var last = -1.0, smooth = true
    for i in 0..<550 { let s = b.state(at: Double(i) / 10).size; if last >= 0 && abs(s - last) > 0.08 { smooth = false }; last = s }
    check(smooth, "the balloon never jumps in size")

    var rng = SeededRNG(state: 7)
    let areas: [(id: String, bests: [Int])] = [("reading", [3, 3, 3]), ("rhyme", [0, 0, 0, 0]), ("clock", [2, 1, 3])]
    var seen: [String: Int] = [:]
    for _ in 0..<600 { if let p = SurpriseMe.pick(areas: areas, last: nil, using: &rng) { seen[p, default: 0] += 1 } }
    check(seen["reading"] == nil && seen["rhyme"] != nil && seen["clock"] != nil, "only places with something left: \(seen)")
    check((seen["rhyme"] ?? 0) > (seen["clock"] ?? 0), "places not started come up more often")
    for _ in 0..<100 { check(SurpriseMe.pick(areas: areas, last: "rhyme", using: &rng) == "clock", "never the same place twice in a row") }
    check(SurpriseMe.pick(areas: [("rhyme", [0])], last: "rhyme", using: &rng) == "rhyme", "unless it's the only one left")
    check(SurpriseMe.pick(areas: [("reading", [2, 3])], last: nil, using: &rng) == nil, "nothing when everything is finished")

    check(HatKind.allCases.filter { $0.unlocked(badges: 0) } == [.none, .party], "a hat from the start")
    check(HatKind.allCases.allSatisfy { $0.badgesNeeded <= Badges.all.count }, "every hat can be unlocked")
    check(HatKind.next(badges: 3)! == (.flower, 1) && HatKind.next(badges: 99) == nil, "the next hat and how far away")
    check(zip(HatKind.allCases, HatKind.allCases.dropFirst()).allSatisfy { $0.badgesNeeded <= $1.badgesNeeded }, "hats in unlock order")
}

test("Play this week: minutes per day, two weeks kept") {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    let day0 = Date(timeIntervalSince1970: 1_790_000_000)
    var h = PlayHistory()
    h.add(600, on: day0, calendar: cal); h.add(50, on: day0, calendar: cal)
    h.add(20 * 60, on: cal.date(byAdding: .day, value: -2, to: day0)!, calendar: cal)
    let w = h.week(endingOn: day0, calendar: cal)
    check(w.count == 7 && w.last!.minutes == 11 && w[4].minutes == 20 && w[0].minutes == 0, "today, two days ago, and empty days: \(w.map(\.minutes))")
    check(h.weekTotal(endingOn: day0, calendar: cal) == 31, "week total")
    check(cal.isDate(w.last!.day, inSameDayAs: day0) && w.first!.day < w.last!.day, "oldest first, ending today")
    for back in 1...20 { h.add(60, on: cal.date(byAdding: .day, value: back, to: day0)!, calendar: cal) }
    check(h.days.count <= PlayHistory.keep, "only two weeks kept (\(h.days.count) days)")
    h.add(0, on: day0, calendar: cal); h.add(-5, on: day0, calendar: cal)
    check(h.days.values.allSatisfy { $0 > 0 }, "nothing negative")
    let back = try! JSONDecoder().decode(PlayHistory.self, from: try! JSONEncoder().encode(h))
    check(back == h, "round trip")
}

test("Widgets in Spanish: every Star Hop message, level and button") {
    check(StarHop.levels.allSatisfy { HopWords.tr($0.title, true) != $0.title && HopWords.tr($0.tip, true) != $0.tip }, "every level title and tip")
    check(HopWords.tr("Jump!", false) == "Jump!", "English stays English")
    var messages: Set<String> = []
    for seed in 0..<30 {
        for lv in 1...StarHop.levels.count {
            var g = StarHop(); g.plays = seed; g.turn = seed; g.startLevel(lv)
            messages.insert(g.message)
            var x = UInt64(seed * 31 + lv)
            for _ in 0..<120 {
                x = x &* 6364136223846793005 &+ 1442695040888963407
                if g.outOfHearts { g.retry() } else if g.levelDone { g.nextLevel() }
                if (x >> 33) % 2 == 0 { g.right() } else { g.left() }
                messages.insert(g.message)
            }
        }
    }
    var g = StarHop(); g.newGame(); messages.insert(g.message)
    let missed = messages.filter { !$0.isEmpty && HopWords.tr($0, true) == $0 }
    check(missed.isEmpty, "every message has Spanish (\(messages.count) seen), missing: \(missed.sorted().prefix(8))")
    check(HopWords.tr("Next: Breezy Beach", true) == "Siguiente: Playa Ventosa", "level names inside a line")
    check(HopWords.tr("2 + 3 = 5! ✓", true) == "¡2 + 3 = 5! ✓" && HopWords.tr("That's 4. Find 1 first!", true) == "Ese es 4. ¡Primero busca 1!", "messages with numbers")
    for w in ["Practising", "Up next", "Got it", "Step", "Jump", "Double jump", "Next level", "Try again", "Play again", "Out of hearts!",
              "✓ Finished", "✓ No bumps", "· No bumps", "✓ Quick feet", "· Quick feet", "Next", "Hi, Sam!", "Level 2 done!", "You beat all 12 levels! 🏆",
              "30 of 36 stars", "Best on this level: 14 moves"] {
        check(HopWords.tr(w, true) != w, "widget word: \(w)")
    }
    var snap = WidgetSnapshot.placeholder
    check(snap.spanish == nil, "old snapshots have no language")
    snap.spanish = true
    let back = try! JSONDecoder().decode(WidgetSnapshot.self, from: try! JSONEncoder().encode(snap))
    check(back.spanish == true, "the language travels to the widget")
    let old = #"{"name":"A","buddyName":"B","buddyEmoji":"x","buddyID":"pip","stars":1,"lifetimeStars":1,"lessonTitle":"L","skill":"s","skillState":"Up next","skillsLearned":0,"skillsTotal":1,"quickBest":0}"#
    check((try? JSONDecoder().decode(WidgetSnapshot.self, from: Data(old.utf8)))?.name == "A", "a snapshot from before still loads")
}

test("Read with Me: the right word lights up") {
    func word(_ s: String, _ r: Range<String.Index>?) -> String? { r.map { String(s[$0]) } }
    let line = "One day, Pip Penguin went to the beach and found a kite."
    let speech = ReadAlongMath.speakable(line)
    for (i, w) in ReadAlongMath.words(speech).enumerated() {
        let loc = speech.utf16.distance(from: speech.utf16.startIndex, to: w.lowerBound.samePosition(in: speech.utf16)!)
        let idx = ReadAlongMath.spokenWordIndex(speech: speech, utf16Location: loc)
        check(idx == i, "word \(i) found from its position (\(idx))")
        check(word(line, ReadAlongMath.displayRange(display: line, source: line, spoken: idx)) == String(speech[w]), "screen word matches spoken word \(i)")
    }
    // the title is read first but isn't on the page
    let titled = "Pip and the Kite. " + line
    check(word(line, ReadAlongMath.displayRange(display: line, source: titled, spoken: 4)) == "One", "after the title, the first page word")
    check(ReadAlongMath.displayRange(display: line, source: titled, spoken: 1) == nil, "nothing lights up while the title is read")
    // emoji make no sound and are skipped
    let fun = "Hooray 🎉 you did it!"
    check(word(fun, ReadAlongMath.displayRange(display: fun, source: fun, spoken: 1)) == "you", "an emoji is skipped")
    check(ReadAlongMath.displayRange(display: "Hello there", source: "Something else", spoken: 0) == nil, "no light when the screen shows something else")
    check(ReadAlongMath.displayRange(display: line, source: line, spoken: 99) == nil, "past the end, nothing")
    check(ReadAlongMath.spokenWordIndex(speech: "", utf16Location: 5) == 0, "empty is safe")
    check(ReadAlongMath.speakable("3 × 4 = 12 🎉") == "3 times 4 = 12", "symbols are read as words")
}

test("Nature Trail, Calendar Corner, Compass Camp: every game, 300 seeds, answers really right") {
    let places: [(String, [QuizGameInfo], (String, inout SeededRNG) -> [QuizRound])] = [
        ("nature", NatureBank.games, { NatureBank.rounds(for: $0, using: &$1) }),
        ("calendar", CalendarBank.games, { CalendarBank.rounds(for: $0, using: &$1) }),
        ("compass", CompassBank.games, { CompassBank.rounds(for: $0, using: &$1) }),
    ]
    let days = CalendarBank.days, months = CalendarBank.months
    check(Set(NatureBank.babies.map(\.animal)).count == NatureBank.babies.count, "one baby name per animal")
    check(CompassBank.mapThings.allSatisfy { GridWords.names[$0] != nil }, "every map picture has a name")
    for (place, games, make) in places {
        check(games.count == 4 && Set(games.map(\.id)).count == 4, "\(place): four games")
        for g in games {
            for seed in 0..<300 {
                var rng = SeededRNG(state: UInt64(seed))
                let rounds = make(g.id, &rng)
                check(rounds.count == 5, "\(place)/\(g.id): five rounds")
                for r in rounds {
                    check(r.choices.contains(r.answer) && Set(r.choices).count == r.choices.count && r.choices.count >= 2, "\(place)/\(g.id): choices hold the answer once (\(r.choices))")
                    switch (place, g.id) {
                    case ("nature", "homes"):
                        let a = NatureBank.homes.first { r.say.contains("the \($0.animal) live") }!
                        check(r.answer == a.home, "homes: \(a.animal) → \(a.home)")
                        check(r.choices.allSatisfy { !(NatureBank.alsoFits[a.animal] ?? []).contains($0) }, "homes: no other fair home offered as wrong")
                    case ("nature", "cycles"):
                        let c = NatureBank.cycles.first { r.say.hasPrefix("A \($0.name) grows") }!
                        let names = c.stages.map(\.0)
                        let last = r.say.components(separatedBy: "After the ")[1].components(separatedBy: ",")[0]
                        let k = names.firstIndex(of: last)!
                        check(names[k + 1] == r.answer, "cycles: after \(last) comes \(r.answer)")
                    case ("nature", "senses"):
                        let s = NatureBank.senses.first { r.say.hasSuffix("to \($0.thing)?") }!
                        check(r.answer == (r.say.hasPrefix("Which sense") ? s.sense : s.part), "senses: \(s.thing)")
                    case ("nature", "babies"):
                        let b = NatureBank.babies.first { r.say == "What is a baby \($0.animal) called?" }!
                        check(r.answer == b.baby, "babies: \(b.animal)")
                        check(r.choices.allSatisfy { !(NatureBank.babyAlsoFits[b.animal] ?? []).contains($0) }, "babies: no other fair name offered as wrong")
                    case ("calendar", "days"):
                        if case .text(let d) = r.visual, let i = days.firstIndex(of: d) {
                            check(r.answer == days[(i + (r.say.contains("before") ? 6 : 1)) % 7], "days: \(r.say) → \(r.answer)")
                        }
                    case ("calendar", "yesterday"):
                        let d = days.firstIndex { r.say.hasPrefix("Today is \($0).") }!
                        check(r.answer == days[(d + (r.say.contains("tomorrow") ? 1 : 6)) % 7], "yesterday: \(r.say) → \(r.answer)")
                    case ("calendar", "months"):
                        if case .text(let m) = r.visual, let i = months.firstIndex(of: m) { check(r.answer == months[(i + 1) % 12], "months: after \(m)") }
                    case ("calendar", "seasons"):
                        check(CalendarBank.seasonClues.contains { r.say.hasPrefix($0.clue) && $0.season == r.answer }, "seasons: \(r.answer)")
                    case ("compass", "leftRight"):
                        if case .picture(let row) = r.visual {
                            let items = row.split(separator: " ").map { GridWords.name(String($0)) }
                            let target = r.say.components(separatedBy: "of the ")[1].dropLast()
                            let k = items.firstIndex(of: String(target))!
                            check(items[k + (r.say.contains("left") ? -1 : 1)] == r.answer, "leftRight: \(r.say) → \(r.answer)")
                            // VoiceOver reads the row with the same names the question uses
                            check(r.visual.spoken == "From left to right: " + items.joined(separator: ", "), "leftRight: VoiceOver row \(r.visual.spoken ?? "nil")")
                        }
                    case ("compass", "compass"):
                        if case .compass(let n, let e, let s, let w) = r.visual {
                            let four = [n, e, s, w].map(GridWords.name)
                            if r.say.hasPrefix("What is to the") {
                                let d = CompassBank.directions.firstIndex { r.say.contains($0) }!
                                check(four[d] == r.answer, "compass: \(r.say)")
                            } else {
                                let thing = four.firstIndex { r.say.contains("the \($0)?") }!
                                check(CompassBank.directions[thing] == r.answer, "compass: \(r.say)")
                            }
                            check(Set(four).count == 4, "compass: four different things")
                        }
                    case ("compass", "gridFind"):
                        if case .gridMap(let cols, _, let items, _) = r.visual {
                            if r.say.hasPrefix("What is at") {
                                let spot = String(r.say.dropFirst(11).dropLast())
                                let cell = items.keys.first { CompassBank.cellName($0, cols: cols) == spot }!
                                check(GridWords.name(items[cell]!) == r.answer, "gridFind: \(spot)")
                            } else {
                                let cell = items.keys.first { CompassBank.cellName($0, cols: cols) == r.answer }
                                check(cell != nil && r.say.contains(GridWords.name(items[cell!]!)), "gridFind: where is → \(r.answer)")
                            }
                            check(Set(items.values).count == items.count, "gridFind: nothing twice on a map")
                        }
                    default: // follow
                        if case .gridMap(let cols, let rows, let items, let marker) = r.visual, let start = marker {
                            var c = start % cols, rr = start / cols
                            let path = r.say.components(separatedBy: "Go ")[1].components(separatedBy: ". What")[0]
                            for step in path.components(separatedBy: ", then ") {
                                let parts = step.split(separator: " "); let n = Int(parts[0])!
                                switch parts[1] { case "up": rr -= n; case "down": rr += n; case "left": c -= n; default: c += n }
                                check(c >= 0 && c < cols && rr >= 0 && rr < rows, "follow: stays on the map")
                            }
                            check(items[rr * cols + c].map(GridWords.name) == r.answer && items[start] == nil, "follow: the walk ends at \(r.answer)")
                            check(r.visual.spoken?.hasPrefix("A map. The flag is at \(CompassBank.cellName(start, cols: cols))") == true, "follow: VoiceOver names the flag")
                        }
                    }
                }
            }
        }
    }
}

test("Brain Bubble widget: questions, one try each, every question before any repeat") {
    let all = BubbleBank.all
    check(all.count == 41, "41 questions (prime, so stepping by 7 visits them all)")
    for q in all {
        check(q.choices.count == 3 && Set(q.choices).count == 3 && q.choices.indices.contains(q.answer), "three different choices: \(q.question)")
        check(!q.fact.isEmpty && !q.emoji.isEmpty, "a fact and a picture: \(q.question)")
    }
    check(Set(all.map(\.question)).count == all.count, "no question twice")
    // spot-check some answers
    func ans(_ s: String) -> String? { all.first { $0.question == s }.map { $0.choices[$0.answer] } }
    check(ans("What is 4 + 3?") == "7" && ans("What is 9 − 4?") == "5" && ans("What is 10 + 6?") == "16" && ans("What is 2 groups of 3?") == "6", "math answers")
    check(ans("How many legs does a spider have?") == "8" && ans("How many continents are there?") == "7", "facts")
    var b = BrainBubble(); b.start = 5
    var seen: Set<Int> = []
    for _ in 0..<all.count { seen.insert(b.index); b.next() }
    check(seen.count == all.count, "every question comes up once per lap")
    var c = BrainBubble()
    let right = c.question.answer
    c.pick((right + 1) % 3)
    check(c.isAnswered && !c.gotIt && c.right == 0 && c.answered == 1, "a wrong answer")
    c.pick(right)
    check(c.right == 0 && c.answered == 1, "one try per question")
    c.next()
    check(!c.isAnswered && c.turn == 1, "next question")
    c.pick(c.question.answer)
    check(c.gotIt && c.right == 1, "a right answer")
    c.pick(99)
    var stale = BrainBubble(); stale.start = 3
    stale.pick(stale.question.answer, asked: stale.index + 1)
    check(!stale.isAnswered, "a tap from an out-of-date widget is ignored")
    stale.pick(stale.question.answer, asked: stale.index)
    check(stale.gotIt, "a tap on the question shown counts")
    let shown = stale.index
    stale.next(asked: shown)
    stale.next(asked: shown)   // a second tap on the same old "Next question"
    check(stale.turn == 1 && !stale.isAnswered && stale.index != shown, "two taps on one Next button move on once")
    let d = UserDefaults(suiteName: "hopquest.tests.bubble")!
    d.removePersistentDomain(forName: "hopquest.tests.bubble")
    let first = SharedStore.loadBubble(d)
    check(SharedStore.loadBubble(d) == first, "the first question is saved, so it stays the same until answered")
    SharedStore.save(c, d)
    check(SharedStore.loadBubble(d) == c, "saved")
    check(HopWords.tr("It's 7.", true) == "Es 7." && HopWords.tr("3 right", true) == "3 correctas" && HopWords.tr("Next question", true) == "Otra pregunta", "widget words in Spanish")
    check(L10n.spanish("That's the most stars: \(CustomHopLevel.maxStars).") != nil && L10n.spanish("That's the most clouds: \(CustomHopLevel.maxClouds).") != nil, "Level Maker limits in Spanish")
    d.removePersistentDomain(forName: "hopquest.tests.bubble")
}

test("Level Maker and Sticker Scenes") {
    var lv = CustomHopLevel(id: "t", name: "Test")
    check(!lv.canPlay, "an empty level can't be played")
    check(!lv.apply(.star, at: CustomHopLevel.startCell).ok, "no star where the buddy starts")
    check(!lv.apply(.cloud, at: 3).ok, "no cloud on the ground")
    check(lv.apply(.cloud, at: 9).ok && !lv.apply(.star, at: 9).ok, "a cloud, then no star on it")
    check(lv.apply(.spring, at: 4).ok && lv.spring == 4 && !lv.apply(.star, at: 4).ok, "a spring, then no star on it")
    check(!lv.apply(.spring, at: 10).ok && !lv.apply(.spring, at: StarHop.startCol).ok, "springs only on the ground, not at the start")
    check(lv.apply(.star, at: 14).ok && lv.thing(at: 14) == .star && lv.canPlay, "a star")
    lv.apply(.star, at: 14)
    check(lv.thing(at: 14) == nil, "tapping a star again takes it away")
    for c in [2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17] { lv.apply(.star, at: c) }
    check(lv.stars.count == CustomHopLevel.maxStars, "at most \(CustomHopLevel.maxStars) stars")
    lv.apply(.erase, at: 9); lv.apply(.erase, at: 4)
    check(lv.clouds.isEmpty && lv.spring == nil, "the eraser")
    for c in [7, 8, 9, 10] { lv.apply(.cloud, at: c) }
    check(lv.clouds.count <= CustomHopLevel.maxClouds, "at most 3 clouds")

    var g = StarHop(); let before = g
    var mine = CustomHopLevel(id: "m", name: "Mine")
    mine.apply(.star, at: 2); mine.apply(.star, at: 9); mine.apply(.cloud, at: 16)
    g.play(mine)
    check(g.custom != nil && g.stars.count == 2 && g.goal == 2 && g.clouds == [16] && g.info.title == "Mine", "playing a made-up level")
    let starCells = g.stars.map(\.cell)
    g.left(); g.left(); g.left()
    check(g.stars.map(\.cell) == starCells, "its stars stay where they were put")
    // finish it with the look-ahead player, and check nothing is recorded
    var taps = 0
    while !g.levelDone && taps < 200 {
        if g.outOfHearts { g.retry() }
        var best: Bool? = nil
        var frontier: [(StarHop, Bool)] = [true, false].map { r in var x = g; if r { x.right() } else { x.left() }; return (x, r) }
        for _ in 0..<7 where best == nil {
            if let hit = frontier.first(where: { $0.0.collected > g.collected && $0.0.hearts == g.hearts }) { best = hit.1; break }
            frontier = frontier.flatMap { s, f in [true, false].map { r in var x = s; if r { x.right() } else { x.left() }; return (x, f) } }
        }
        if best ?? true { g.right() } else { g.left() }
        taps += 1
    }
    check(g.levelDone && !g.champion && g.message == "You caught every star!", "a made-up level can be finished (\(taps) taps)")
    check(g.best == before.best && g.rating == before.rating && g.levelsCleared == before.levelsCleared, "and it changes no Star Hop records")
    g.nextLevel()
    check(g.custom == mine && g.collected == 0 && g.stars.count == 2, "play again replays it")
    g.startLevel(1)
    check(g.custom == nil && g.stars.count == 2 && g.level == 1, "back to the real levels")
    let rt = try! JSONDecoder().decode(StarHop.self, from: try! JSONEncoder().encode(g))
    check(rt == g, "round trip")

    // random made-up levels can always be finished
    var x: UInt64 = 99
    for n in 0..<60 {
        var r = CustomHopLevel(id: "r\(n)", name: "R")
        for _ in 0..<20 {
            x = x &* 6364136223846793005 &+ 1442695040888963407
            let tool = CustomHopLevel.Tool.allCases[Int((x >> 33) % 3)]
            r.apply(tool, at: Int((x >> 40) % 18))
        }
        guard r.canPlay else { continue }
        var p = StarHop(); p.play(r)
        var t = 0
        while !p.levelDone && t < 400 {
            if p.outOfHearts { p.retry() }
            var best: Bool? = nil
            var frontier: [(StarHop, Bool)] = [true, false].map { rr in var y = p; if rr { y.right() } else { y.left() }; return (y, rr) }
            for _ in 0..<7 where best == nil {
                if let hit = frontier.first(where: { $0.0.collected > p.collected && $0.0.hearts == p.hearts }) { best = hit.1; break }
                frontier = frontier.flatMap { s, f in [true, false].map { rr in var y = s; if rr { y.right() } else { y.left() }; return (y, f) } }
            }
            if best ?? true { p.right() } else { p.left() }
            t += 1
        }
        check(p.levelDone, "made-up level \(n) can be finished (\(r.stars.count) stars, \(r.clouds.count) clouds)")
    }

    for sp in [nil, 0, 2, 3, 4, 5] as [Int?] {
        let reach = CustomHopLevel.reachable(spring: sp)
        let blocked = Set(0..<18).subtracting(reach).subtracting(sp.map { [$0] } ?? [])
        check(blocked.count <= 1, "a spring at \(String(describing: sp)) blocks at most one square: \(blocked.sorted())")
    }
    var sp = CustomHopLevel(id: "s", name: "S")
    sp.apply(.star, at: 16)
    let r2 = sp.apply(.spring, at: 2)
    check(sp.spring == 2 && !sp.stars.contains(16) && r2.why != nil, "a new spring sends an unreachable star away, and says so")
    check(!sp.apply(.star, at: 16).ok, "and won't let a star go there")

    var save = LevelMakerSave()
    for _ in 0..<8 { save.save(save.newLevel()) }
    check(save.levels.count == CustomHopLevel.maxSaved && save.made == 8, "six levels kept")

    var sc = StickerScene(id: "s")
    let a = sc.add("pip")!, b = sc.add("mochi")!
    check(sc.placed.count == 2 && sc.placed[0].x != sc.placed[1].x, "stickers don't land on top of each other")
    sc.move(a, x: 1.4, y: -0.2)
    check(sc.placed.first { $0.id == a }!.x == 1 && sc.placed.first { $0.id == a }!.y == 0, "moves stay inside the picture")
    for _ in 0..<10 { sc.resize(b, by: 1.5) }
    check(sc.placed.first { $0.id == b }!.scale == StickerScene.maxScale, "can't grow forever")
    sc.raise(a)
    check(sc.placed.last!.id == a, "bring to front")
    sc.flip(a); sc.remove(b)
    check(sc.placed.count == 1 && sc.placed[0].flipped, "flip and remove")
    for _ in 0..<20 { sc.add("pip") }
    check(sc.placed.count == StickerScene.maxStickers, "at most \(StickerScene.maxStickers) stickers")
    var ss = SceneSave()
    for _ in 0..<9 { ss.save(ss.newScene()) }
    check(ss.scenes.count == SceneSave.maxSaved, "six scenes kept")
}

test("Bedtime: goodnight from bedtime until 6 in the morning, a grown-up can add time") {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    func at(_ h: Int, _ m: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: h, minute: m))! }
    let bed = 19 * 60 + 30
    check(!Bedtime.isBedtime(now: at(19, 29), bedtime: bed, snoozeUntil: nil, calendar: cal), "not yet at 7:29")
    check(Bedtime.isBedtime(now: at(19, 30), bedtime: bed, snoozeUntil: nil, calendar: cal), "bedtime at 7:30")
    check(Bedtime.isBedtime(now: at(23, 59), bedtime: bed, snoozeUntil: nil, calendar: cal) && Bedtime.isBedtime(now: at(3, 0), bedtime: bed, snoozeUntil: nil, calendar: cal), "through the night")
    check(!Bedtime.isBedtime(now: at(6, 0), bedtime: bed, snoozeUntil: nil, calendar: cal) && !Bedtime.isBedtime(now: at(12, 0), bedtime: bed, snoozeUntil: nil, calendar: cal), "morning and daytime are fine")
    check(!Bedtime.isBedtime(now: at(21, 0), bedtime: 0, snoozeUntil: nil, calendar: cal), "off means off")
    check(!Bedtime.isBedtime(now: at(20, 0), bedtime: bed, snoozeUntil: at(20, 15), calendar: cal), "15 more minutes")
    check(Bedtime.isBedtime(now: at(20, 16), bedtime: bed, snoozeUntil: at(20, 15), calendar: cal), "then goodnight again")
    check(Bedtime.label(19 * 60 + 30) == "7:30 PM" && Bedtime.label(21 * 60) == "9:00 PM" && Bedtime.label(0) == "Off", "labels")
    check(Bedtime.choices.allSatisfy { $0 == 0 || $0 > Bedtime.wakeMinutes }, "every choice is in the evening")
}

test("Try at home (v9.7): every place has a plain summary and short ideas, practising places come first") {
    let ids = ["reading", "writing", "market", "clock", "science", "world", "music", "spelling", "fractions", "shapes", "rhyme",
               "numbers", "times", "measure", "feelings", "nature", "calendar", "compass", "code"]
    for id in ids {
        let a = AtHome.byPlace[id]
        check(a != nil, "\(id) has at-home ideas")
        guard let a else { continue }
        check(!a.learning.isEmpty && a.learning.count <= 140, "\(id): summary is one short line (\(a.learning.count))")
        check((2...3).contains(a.ideas.count), "\(id): two or three ideas")
        for i in a.ideas {
            check(!i.isEmpty && i.count <= 110, "\(id): idea is short: \(i)")
            let lower = i.lowercased()
            let words = Set(lower.split { !$0.isLetter }.map(String.init))
            for word in ["buy", "app", "download", "website", "online", "screen", "streak"] {
                check(!words.contains(word), "\(id): no '\(word)' in an idea: \(i)")
            }
        }
    }
    check(AtHome.ideas(for: "not-a-place") == AtHome.general, "unknown places get the general ideas")
    func area(_ id: String, _ bests: [Int]) -> LearningArea {
        LearningArea(id: id, title: id, skills: bests.map { SkillProgress(skill: "s", best: $0) })
    }
    let areas = [area("fresh", [0, 0]), area("half", [3, 0]), area("done", [3, 2]), area("stuck", [1, 3]), area("stuck2", [2, 1])]
    let s = AtHome.suggested(areas)
    check(s.map(\.id) == ["stuck", "stuck2", "half"], "practising first, then started; not-started and finished left out (\(s.map(\.id)))")
    check(AtHome.suggested(areas, limit: 1).map(\.id) == ["stuck"], "limit")
    check(AtHome.suggested([area("fresh", [0])]).isEmpty, "nothing to suggest before playing")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
