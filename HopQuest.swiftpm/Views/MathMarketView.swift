import SwiftUI

/// A coin drawn in SwiftUI: copper penny, silver nickel, dime and quarter, sized like the real ones.
struct CoinView: View {
    let coin: Coin
    var scale: CGFloat = 1

    private var size: CGFloat {
        switch coin {
        case .dime: return 44
        case .penny: return 48
        case .nickel: return 52
        case .quarter: return 58
        }
    }

    var body: some View {
        let copper = coin == .penny
        ZStack {
            Circle().fill(LinearGradient(colors: copper ? [Color(hex: 0xE89A5C), Color(hex: 0xB0612C)] : [Color(hex: 0xF1F3F7), Color(hex: 0xAEB7C7)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(copper ? Color(hex: 0x8A4A1F) : Color(hex: 0x7D8699), lineWidth: 3)
            Circle().stroke(.white.opacity(0.5), lineWidth: 1.5).padding(5)
            Text(coin.label).font(.kid(15 * scale, .black))
                .foregroundStyle(copper ? Color(hex: 0x5E2E10) : Color(hex: 0x3B4252))
                .minimumScaleFactor(0.6)
        }
        .frame(width: size * scale, height: size * scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(coin.name), \(coin.rawValue) cents")
    }
}

/// The Math Market: Benny Banana's shop in Hop Village, with five money games.
struct MathMarketView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: MarketGame?

    /// One accent for the whole place: the five games read as one group.
    private let accent = Color(hex: 0xD06A00)

    /// 1 = little learner, 2 = growing, 3 = big (follows the grown-ups' Learning level).
    private var level: Int { min(3, max(1, store.effectiveTier)) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF7D6), Color(hex: 0xFFE0A3)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let game = playing {
                MarketGameView(game: game, level: level, color: accent,
                               onFinish: { stars in store.recordMarket(game, stars: stars) },
                               onBack: { playing = nil; Narrator.shared.say("Pick another game!") })
                    .id(game)
                    .transition(.pushIn)
            } else {
                list.transition(.pushedBack)
            }
        }
        .animation(Motion.standard, value: playing)
        .onAppear { Narrator.shared.say("Welcome to the Math Market! I'm Benny Banana. Let's count some money!") }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PlaceHeader(host: PlaceHost.market, title: "Math Market", line: "Welcome to my shop! Let's count some coins.",
                            stars: store.profile?.market.totalStars ?? 0, maxStars: MarketSave.maxStars,
                            accent: accent, onBack: onBack)
                HStack(spacing: 8) {
                    ForEach(Coin.forLevel(level), id: \.self) { CoinView(coin: $0, scale: 0.8) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
                ForEach(MarketGame.allCases) { g in
                    LearnGameCard(symbol: g.symbol, title: g.title, blurb: g.intro, stars: store.profile?.market.best(g) ?? 0,
                                  color: accent) {
                        playing = g
                    }
                }
                Text("Prices and coins match the Learning level set by a grown-up. Each game gives up to 3 stars.")
                    .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }
}

/// One play of a market game: five rounds, then stars.
struct MarketGameView: View {
    let game: MarketGame
    let level: Int
    let color: Color
    var onFinish: (Int) -> Int
    var onBack: () -> Void

    @State private var rounds: [MarketRound] = []
    @State private var index = 0
    @State private var missed = false
    @State private var firstTry = 0
    @State private var wrong: Set<String> = []
    @State private var right: String?
    /// Pay Exactly: coins in the tray.
    @State private var tray: [Coin] = []
    @State private var payShake = false
    @State private var result: (stars: Int, earned: Int)?
    @State private var advanceTask: Task<Void, Never>?

    private var round: MarketRound? { rounds.indices.contains(index) ? rounds[index] : nil }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop playing", action: { advanceTask?.cancel(); onBack() })
                Spacer()
                Text(game.title).font(.kid(20, .black)).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                SpeakButton(label: "Say it again") { if let r = round { Narrator.shared.sayAnyway(r.say) } }
            }
            RoundDots(done: index, total: max(rounds.count, 1))
            if let r = round, result == nil {
                ScrollView(showsIndicators: false) { question(r) }
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
                                  host: PlaceHost.market, onAgain: start, onBack: onBack)
                }
            }
        }
        .onAppear { start() }
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func question(_ r: MarketRound) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                if !r.coins.isEmpty {
                    // wrap coins in rows of four
                    let rows = stride(from: 0, to: r.coins.count, by: 4).map { Array(r.coins[$0..<min($0 + 4, r.coins.count)]) }
                    ForEach(rows.indices, id: \.self) { i in
                        HStack(spacing: 10) { ForEach(Array(rows[i].enumerated()), id: \.offset) { CoinView(coin: $0.element, scale: 1.2) } }
                    }
                }
                if !r.show.isEmpty {
                    Text(r.show).font(.kid(34, .black)).foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center).minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.85)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(r.say)

            if case .pay(let target) = r.kind {
                payArea(target)
            } else {
                let columns = r.choices.count == 2 ? [GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(r.choices, id: \.self) { c in
                        AnswerButton(text: c, state: right == c ? .right : wrong.contains(c) ? .wrong : .plain) { pick(c, in: r) }
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }

    private func payArea(_ target: Int) -> some View {
        let total = MarketBank.total(tray)
        return VStack(spacing: 14) {
            // the tray: tap a coin to take it back
            VStack(spacing: 6) {
                Text("Your coins: \(total)¢ of \(target)¢").font(.kid(20, .black))
                    .foregroundStyle(total > target ? Palette.red : Palette.ink)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if tray.isEmpty {
                            Text("Tap coins below to add them").font(.kid(14, .bold)).foregroundStyle(.secondary)
                                .frame(height: 60)
                        }
                        ForEach(Array(tray.enumerated()), id: \.offset) { i, c in
                            Button {
                                guard right == nil else { return }
                                Haptics.tap(.pop)
                                tray.remove(at: i)
                            } label: { CoinView(coin: c) }
                            .accessibilityLabel("\(c.name) in your tray. Tap to take it back")
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(minHeight: 64)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.7)))
            .modifier(Shake(animatableData: payShake ? 1 : 0))

            // coins to add
            HStack(spacing: 12) {
                ForEach(Coin.forLevel(level), id: \.self) { c in
                    Button {
                        guard right == nil, tray.count < 20 else { return }
                        Haptics.tap(.coin)
                        tray.append(c)
                    } label: { CoinView(coin: c, scale: 1.3) }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Add a \(c.name), \(c.rawValue) cents")
                }
            }
            HStack(spacing: 12) {
                BigButton(title: "Clear", color: Color(hex: 0x9AA6B8)) { tray = [] }
                BigButton(title: right == nil ? "Pay" : "Paid! ✓", color: Palette.green) { pay(target) }
            }
        }
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = MarketBank.rounds(for: game, level: level)
        index = 0; firstTry = 0; result = nil
        resetRound()
        Narrator.shared.say("\(game.intro) \(rounds.first?.say ?? "")")
    }

    private func resetRound() {
        missed = false; wrong = []; right = nil; tray = []
    }

    private func pick(_ c: String, in r: MarketRound) {
        guard right == nil else { return }
        if c == r.answer {
            right = c
            succeed(r)
        } else {
            missed = true
            wrong.insert(c)
            Haptics.bump(.oops)
            Narrator.shared.say("Not quite. Try again!")
        }
    }

    private func pay(_ target: Int) {
        guard right == nil, let r = round else { return }
        let total = MarketBank.total(tray)
        if total == target {
            right = "paid"
            succeed(r)
            return
        }
        guard total > 0 else { Narrator.shared.say("Tap coins to add them first."); return }
        missed = true
        Haptics.bump(.oops)
        withAnimation(.default) { payShake.toggle() }
        if total > target {
            Narrator.shared.say("That's \(total) cents, which is too much. Tap a coin in your tray to take it back.")
        } else {
            Narrator.shared.say("That's \(total) cents. You need \(target - total) more cents.")
        }
    }

    private func succeed(_ r: MarketRound) {
        Haptics.success(.coin)
        if !missed { firstTry += 1 }
        Narrator.shared.say(r.cheer)
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_900_000_000)
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
                Narrator.shared.say(earned > 0 ? "Great shopping! \(earned) new stars!" : "Great shopping!")
            }
        }
    }
}
