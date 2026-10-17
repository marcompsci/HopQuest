import SwiftUI

/// The Science Lab: Professor Ocho's five experiments. Guess, then watch the experiment happen.
struct ScienceLabView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: Experiment?

    private static let colors: [Experiment: UInt32] = [
        .sinkFloat: 0x4D96FF, .magnets: 0xFF6B6B, .plantParts: 0x34C77B, .weather: 0xFF9F1C, .matter: 0x7C4DFF,
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE4F7FF), Color(hex: 0xD6F5E3)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let e = playing {
                ExperimentView(experiment: e, color: Color(hex: Self.colors[e] ?? 0x7C4DFF),
                               onFinish: { stars in store.recordScience(e, stars: stars) },
                               onBack: { playing = nil; Narrator.shared.say("Pick another experiment!") })
                    .id(e)
                    .transition(.move(edge: .trailing))
            } else {
                list.transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: playing)
        .onAppear { Narrator.shared.say("Welcome to the Science Lab! I'm Professor Ocho. Scientists guess first, then test. Pick an experiment!") }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                    Spacer()
                    Text("⭐ \(store.profile?.science.totalStars ?? 0)/\(ScienceSave.maxStars)")
                        .font(.kid(17, .black)).foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .background(Capsule().fill(.white.opacity(0.9)))
                }
                Text("🐙🔬").font(.system(size: 60)).accessibilityHidden(true)
                Text("Science Lab").font(.kid(34, .black)).foregroundStyle(Color(hex: 0x1F7A8C))
                Text("Guess first, then test it, like a real scientist!")
                    .font(.kid(16, .bold)).foregroundStyle(Palette.ink.opacity(0.85))
                    .multilineTextAlignment(.center)
                ForEach(Experiment.allCases) { e in
                    LearnGameCard(icon: e.icon, title: e.title, blurb: e.intro, stars: store.profile?.science.best(e) ?? 0,
                                  color: Color(hex: Self.colors[e] ?? 0x7C4DFF)) { playing = e }
                }
                Text("Each experiment gives up to 3 stars. Beat your best for more!")
                    .font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }
}

/// One experiment: five rounds of guess-then-see.
struct ExperimentView: View {
    let experiment: Experiment
    let color: Color
    var onFinish: (Int) -> Int
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rounds: [ScienceRound] = []
    @State private var index = 0
    @State private var missed = false
    @State private var firstTry = 0
    @State private var wrong: Set<String> = []
    @State private var right: String?
    /// The experiment animation has run (object dropped, magnet pulled).
    @State private var tested = false
    @State private var result: (stars: Int, earned: Int)?
    @State private var advanceTask: Task<Void, Never>?

    private var round: ScienceRound? { rounds.indices.contains(index) ? rounds[index] : nil }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop", action: { advanceTask?.cancel(); onBack() })
                Spacer()
                Text(experiment.title).font(.kid(20, .black)).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                SpeakButton(label: "Say it again") { if let r = round { Narrator.shared.sayAnyway(right == nil ? r.say : r.explain) } }
            }
            RoundDots(done: index, total: max(rounds.count, 1))
            if let r = round, result == nil {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        stage(r)
                        Text(r.say).font(.kid(22, .black)).foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if right != nil {
                            Text("🐙 \(r.explain)")
                                .font(.kid(17, .bold)).foregroundStyle(Palette.ink)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xFFF6D6)))
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.opacity)
                            BigButton(title: index + 1 < rounds.count ? "Next ▶" : "Finish ✓", color: color) {
                                advanceTask?.cancel()
                                advance()
                            }
                        }
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: r.choices.count == 2 ? 2 : 1)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(r.choices, id: \.self) { c in
                                AnswerButton(text: c, font: .kid(26, .black),
                                             state: right == c ? .right : wrong.contains(c) ? .wrong : .plain) { pick(c, in: r) }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
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
                    LearnDoneCard(title: experiment.title, stars: result.stars, earned: result.earned, firstTry: firstTry,
                                  total: rounds.count, onAgain: start, onBack: onBack)
                }
            }
        }
        .onAppear { start() }
        .onDisappear { advanceTask?.cancel() }
    }

    /// The experiment itself: a water tank, a magnet, or just the thing being studied.
    @ViewBuilder
    private func stage(_ r: ScienceRound) -> some View {
        switch experiment {
        case .sinkFloat:
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xDDF5FF))
                RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [Color(hex: 0x7FD0F5), Color(hex: 0x3C9BE0)],
                                                                     startPoint: .top, endPoint: .bottom))
                    .frame(height: 120).offset(y: 50)
                Text(r.show).font(.system(size: 64))
                    .offset(y: tested ? (r.answer == "Sink" ? 108 : 26) : -4)
                    .animation(reduceMotion ? nil : .interpolatingSpring(stiffness: 60, damping: 9), value: tested)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tested ? "\(r.name.capitalized) \(r.answer == "Sink" ? "sank to the bottom" : "floated on top")" : "A tank of water and \(r.name)")
        case .magnets:
            HStack {
                Text(r.show).font(.system(size: 64))
                    .offset(x: tested && r.answer == "Yes" ? 70 : 0)
                Spacer()
                Text("🧲").font(.system(size: 64)).rotationEffect(.degrees(-90))
                    .offset(x: tested ? -40 : 0)
            }
            .padding(.horizontal, 30)
            .frame(height: 140)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))
            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: tested)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tested ? (r.answer == "Yes" ? "The magnet pulled \(r.name)" : "The magnet didn't move \(r.name)") : "\(r.name.capitalized) and a magnet")
        default:
            Text(r.show).font(.system(size: 90))
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))
                .scaleEffect(tested && !reduceMotion ? 1.08 : 1)
                .animation(.spring(), value: tested)
                .accessibilityHidden(true)
        }
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = ScienceBank.rounds(for: experiment)
        index = 0; firstTry = 0; result = nil
        resetRound()
        Narrator.shared.say("\(experiment.intro) \(rounds.first?.say ?? "")")
    }

    private func resetRound() {
        missed = false; wrong = []; right = nil; tested = false
    }

    private func pick(_ c: String, in r: ScienceRound) {
        guard right == nil else { return }
        if c == r.answer {
            right = c
            tested = true
            Haptics.success(.correct)
            if !missed { firstTry += 1 }
            Narrator.shared.say("\(ScienceBank.cheers.randomElement()!) \(r.explain)")
            advanceTask?.cancel()
            advanceTask = Task { @MainActor in
                // time to watch the experiment and hear why
                try? await Task.sleep(nanoseconds: 4_200_000_000)
                guard !Task.isCancelled else { return }
                advance()
            }
        } else {
            missed = true
            wrong.insert(c)
            Haptics.bump(.oops)
            Narrator.shared.say("Hmm, let's test the other idea!")
        }
    }

    private func advance() {
        if index + 1 < rounds.count {
            index += 1
            resetRound()
            Narrator.shared.say(rounds[index].say)
        } else {
            index = rounds.count
            let stars = LearnScore.stars(firstTry: firstTry, of: rounds.count)
            let earned = onFinish(stars)
            Haptics.success(.fanfare)
            withAnimation(.spring()) { result = (stars, earned) }
            Narrator.shared.say(earned > 0 ? "Great experimenting! \(earned) new stars!" : "Great experimenting!")
        }
    }
}
