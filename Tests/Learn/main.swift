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

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
