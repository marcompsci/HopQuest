import SwiftUI

/// The Reading Nook: Ollie Owl's little library in Hop Village, with five reading games.
struct ReadingNookView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: ReadingGame?

    /// One accent for the whole place: the five games read as one group.
    private let accent = Color(hex: 0xC2364A)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF4E0), Color(hex: 0xFFD9C2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let game = playing {
                ReadingGameView(game: game, color: accent,
                                onFinish: { stars in store.recordReading(game, stars: stars) },
                                onBack: { playing = nil; greet(again: true) })
                    .id(game)
                    .transition(.pushIn)
            } else {
                list.transition(.pushedBack)
            }
        }
        .animation(Motion.standard, value: playing)
        .onAppear { greet(again: false) }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PlaceHeader(host: PlaceHost.reading, title: "Reading Nook", line: "Hoo! Which story game shall we play?",
                            stars: store.profile?.reading.totalStars ?? 0, maxStars: ReadingSave.maxStars,
                            accent: accent, onBack: onBack)
                    .padding(.bottom, 4)
                ForEach(ReadingGame.allCases) { g in
                    LearnGameCard(symbol: g.symbol, title: g.title, blurb: g.intro, stars: store.profile?.reading.best(g) ?? 0,
                                  color: accent) {
                        playing = g
                    }
                }
                Text("Each game gives up to 3 stars. Beat your best for more.")
                    .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    private func greet(again: Bool) {
        Narrator.shared.say(again ? "Pick another reading game!" : "Hoo hoo! Welcome to the Reading Nook. Pick a reading game!")
    }
}

/// One play of a reading game: five rounds, then stars.
struct ReadingGameView: View {
    let game: ReadingGame
    let color: Color
    /// Returns the new stars given.
    var onFinish: (Int) -> Int
    var onBack: () -> Void

    @State private var rounds: [ReadingRound] = []
    @State private var index = 0
    @State private var missed = false
    @State private var firstTry = 0
    @State private var wrong: Set<String> = []
    @State private var right: String?
    /// Spelling: letters typed so far, and which tiles are used.
    @State private var typed = ""
    @State private var usedTiles: Set<Int> = []
    @State private var result: (stars: Int, earned: Int)?
    @State private var advanceTask: Task<Void, Never>?

    private var round: ReadingRound? { rounds.indices.contains(index) ? rounds[index] : nil }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop playing", action: { advanceTask?.cancel(); onBack() })
                Spacer()
                Text(game.title).font(.kid(20, .black)).foregroundStyle(Palette.ink)
                Spacer()
                SpeakButton(label: "Say it again") { if let r = round { Narrator.shared.sayAnyway(r.say) } }
            }
            RoundDots(done: index, total: max(rounds.count, 1))
            if let r = round, result == nil {
                question(r)
                Spacer(minLength: 0)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .overlay {
            if let result {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    LearnDoneCard(title: game.title, stars: result.stars, earned: result.earned, firstTry: firstTry, total: rounds.count,
                                  host: PlaceHost.reading, onAgain: start, onBack: onBack)
                }
            }
        }
        .onAppear {
            start()
        }
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func question(_ r: ReadingRound) -> some View {
        VStack(spacing: 18) {
            // the picture, word or sentence
            Text(r.show)
                .font(game == .sentences ? .kid(34, .black) : .system(size: game == .rhymes ? 56 : 96))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 140)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.85)))
                .accessibilityLabel(game == .firstSound || game == .buildWord || game == .sightWords ? r.say : r.show)
            if r.kind == .spell {
                spellArea(r)
            } else {
                let columns = r.choices.count == 4 ? [GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(r.choices, id: \.self) { c in
                        AnswerButton(text: c, font: game == .sentences ? .system(size: 40) : .kid(32, .black),
                                     state: right == c ? .right : wrong.contains(c) ? .wrong : .plain) {
                            pick(c, in: r)
                        }
                        .accessibilityLabel(accessible(c))
                    }
                }
            }
        }
    }

    private func spellArea(_ r: ReadingRound) -> some View {
        VStack(spacing: 16) {
            // the slots
            HStack(spacing: 10) {
                ForEach(Array(r.answer.enumerated()), id: \.offset) { i, _ in
                    let ch = i < typed.count ? String(typed[typed.index(typed.startIndex, offsetBy: i)]) : ""
                    Text(ch.isEmpty ? " " : ch)
                        .font(.kid(40, .black)).foregroundStyle(Palette.ink)
                        .frame(width: 64, height: 72)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color, lineWidth: i == typed.count ? 4 : 2))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(typed.isEmpty ? "No letters yet" : "Spelled so far: \(typed.map(String.init).joined(separator: ", "))")
            // the tiles
            HStack(spacing: 10) {
                ForEach(Array(r.choices.enumerated()), id: \.offset) { i, letter in
                    Button {
                        tapTile(i, letter, in: r)
                    } label: {
                        Text(letter).font(.kid(34, .black))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 64)
                            .background(RoundedRectangle(cornerRadius: 16).fill(usedTiles.contains(i) ? Color.gray.opacity(0.35) : color)
                                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 4))
                            .modifier(Shake(animatableData: wrong.contains("\(i)") ? 1 : 0))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(usedTiles.contains(i))
                    .accessibilityLabel("Letter \(letter)")
                }
            }
        }
    }

    private func accessible(_ choice: String) -> String {
        guard game == .sentences else { return choice }
        // "🐱 on 🛏️" → "cat on bed"
        return choice.split(separator: " ").map { part in
            ReadingBank.words.first { $0.emoji == String(part) }?.word ?? String(part)
        }.joined(separator: " ")
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = ReadingBank.rounds(for: game)
        index = 0; firstTry = 0; result = nil
        resetRound()
        Narrator.shared.say("\(game.intro) \(rounds.first?.say ?? "")")
    }

    private func resetRound() {
        missed = false; wrong = []; right = nil; typed = ""; usedTiles = []
    }

    private func pick(_ c: String, in r: ReadingRound) {
        guard right == nil else { return }
        if c == r.answer {
            right = c
            succeed(r)
        } else {
            missed = true
            wrong.insert(c)
            Haptics.bump(.oops)
            Narrator.shared.say("Not quite. \(r.say)")
        }
    }

    private func tapTile(_ i: Int, _ letter: String, in r: ReadingRound) {
        guard right == nil, let need = ReadingBank.nextLetter(of: r.answer, typed: typed) else { return }
        if letter == need {
            Haptics.tap(.pop)
            usedTiles.insert(i)
            typed += letter
            Narrator.shared.say(letter.uppercased())   // a lone "a" is read as "uh"; the letter name is clearer
            if typed == r.answer {
                right = r.answer
                succeed(r)
            }
        } else {
            missed = true
            Haptics.bump(.oops)
            wrong.insert("\(i)")
            Narrator.shared.say("Try another letter. Listen: \(r.answer).")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                wrong.remove("\(i)")
            }
        }
    }

    private func succeed(_ r: ReadingRound) {
        Haptics.success(.correct)
        if !missed { firstTry += 1 }
        Narrator.shared.say(r.cheer)
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            if index + 1 < rounds.count {
                index += 1
                resetRound()
                Narrator.shared.say(rounds[index].say)
            } else {
                index = rounds.count
                let stars = LearnScore.stars(firstTry: firstTry, of: rounds.count)
                let earned = onFinish(stars)
                Haptics.success(.fanfare)
                withAnimation(Motion.present) { result = (stars, earned) }
                Narrator.shared.say(earned > 0 ? "You did it! \(earned) new stars!" : "You did it! Great reading!")
            }
        }
    }
}
