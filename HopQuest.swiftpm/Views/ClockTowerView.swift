import SwiftUI

/// The Clock Tower: Gemma Giraffe's tower, with five games for telling time on a real clock face.
struct ClockTowerView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: ClockGame?

    private let accent = Color(hex: 0x2E7D4F)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF1FAF2), Color(hex: 0xD4EFD9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let game = playing {
                ClockGameView(game: game, color: accent,
                              onFinish: { stars in store.recordClock(game, stars: stars) },
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
                PlaceHeader(host: PlaceHost.clock, title: "Clock Tower", line: "Tick tock! From up here I can see every clock in the village.",
                            stars: store.profile?.clock.totalStars ?? 0, maxStars: ClockSave.maxStars,
                            accent: accent, onBack: onBack)
                    .padding(.bottom, 4)
                ForEach(ClockGame.allCases) { g in
                    LearnGameCard(symbol: g.symbol, title: g.title, blurb: g.intro, stars: store.profile?.clock.best(g) ?? 0,
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
        Narrator.shared.say(again ? "Pick another clock game!" : "Hello up there! I'm Gemma. Welcome to the Clock Tower. Pick a clock game!")
    }
}

/// One play: five clocks, then stars.
struct ClockGameView: View {
    let game: ClockGame
    let color: Color
    var onFinish: (Int) -> Int
    var onBack: () -> Void

    @State private var rounds: [ClockRound] = []
    @State private var index = 0
    @State private var missed = false
    @State private var firstTry = 0
    @State private var wrong: Set<String> = []
    @State private var right: String?
    /// Set the Clock: the hands the child has moved.
    @State private var shown = ClockTime(12)
    @State private var result: (stars: Int, earned: Int)?
    @State private var advanceTask: Task<Void, Never>?

    private var round: ClockRound? { rounds.indices.contains(index) ? rounds[index] : nil }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop playing", action: { advanceTask?.cancel(); onBack() })
                Spacer()
                Text(game.title).font(.kid(20, .black)).displayTracking(20).foregroundStyle(Palette.ink)
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
                                  host: PlaceHost.clock, onAgain: start, onBack: onBack)
                }
            }
        }
        .onAppear(perform: start)
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func question(_ r: ClockRound) -> some View {
        VStack(spacing: 14) {
            if !r.moment.isEmpty {
                Text(r.moment).font(.kid(18, .bold)).foregroundStyle(Palette.ink.opacity(0.75))
            }
            if r.kind == .set {
                Text(r.time.digital).font(.kid(40, .black)).monospacedDigit().foregroundStyle(color)
                    .accessibilityLabel("Show \(r.time.spoken)")
                ClockFace(time: shown, accent: color, onChange: right == nil ? { shown = $0 } : nil)
                    .frame(maxWidth: 330)
                HStack(spacing: 12) {
                    stepButton("Hour back", "gobackward") { shown = ClockTime(shown.hour - 1, shown.minute) }
                    stepButton("Hour on", "goforward") { shown = ClockTime(shown.hour + 1, shown.minute) }
                    Button { check(r) } label: {
                        Label("Done", systemImage: "checkmark")
                            .font(.kid(20, .black)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Capsule().fill(right == nil ? color : Palette.green))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(right != nil)
                }
            } else {
                ClockFace(time: r.time, accent: color, onChange: nil)
                    .frame(maxWidth: 300)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(r.choices, id: \.self) { c in
                        AnswerButton(text: c, font: .kid(28, .black),
                                     state: right == c ? .right : wrong.contains(c) ? .wrong : .plain) {
                            pick(c, in: r)
                        }
                    }
                }
            }
        }
    }

    private func stepButton(_ label: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(.tick)
            action()
        } label: {
            Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundStyle(color)
                .frame(width: 54, height: 54)
                .background(Circle().fill(.white).shadow(color: Palette.ink.opacity(0.12), radius: 0, x: 0, y: 3))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(right != nil)
        .accessibilityLabel(label)
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = ClockBank.rounds(for: game)
        index = 0; firstTry = 0; result = nil
        resetRound()
        Narrator.shared.say("\(game.intro) \(rounds.first?.say ?? "")")
    }

    private func resetRound() {
        missed = false; wrong = []; right = nil
        // start the hands somewhere that isn't the answer
        if let r = round { shown = ClockTime(r.time.hour + 5, 0) }
    }

    private func pick(_ c: String, in r: ClockRound) {
        guard right == nil else { return }
        if c == r.answer {
            right = c
            succeed(r)
        } else {
            missed = true
            wrong.insert(c)
            Haptics.bump(.oops)
            Narrator.shared.say(game == .hourLater ? "Not quite. Move the short hand on by one number." : "Not quite. Look at the short hand first, then the long hand.")
        }
    }

    private func check(_ r: ClockRound) {
        guard right == nil else { return }
        if ClockBank.isSet(shown, to: r.time) {
            right = r.answer
            succeed(r)
        } else {
            missed = true
            Haptics.bump(.oops)
            let hint = shown.minute != r.time.minute
                ? (r.time.minute == 0 ? "Point the long hand at 12." : "Point the long hand at 6.")
                : "Now move the short hand to \(r.time.hour)."
            Narrator.shared.say("Almost! \(hint)")
        }
    }

    private func succeed(_ r: ClockRound) {
        Haptics.success(.correct)
        if !missed { firstTry += 1 }
        Narrator.shared.say(r.cheer)
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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
                Narrator.shared.say(earned > 0 ? "You did it! \(earned) new stars!" : "You did it! Great timing!")
            }
        }
    }
}

/// A round clock face with 12 numbers and two hands. With `onChange`, the hands can be dragged:
/// near the middle moves the short (hour) hand, farther out the long (minute) hand, snapping to 5 minutes.
struct ClockFace: View {
    let time: ClockTime
    let accent: Color
    var onChange: ((ClockTime) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draggingHour: Bool?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let r = side / 2
            ZStack {
                Circle().fill(.white)
                    .overlay(Circle().stroke(Palette.ink, lineWidth: side * 0.035))
                    .shadow(color: Palette.ink.opacity(0.14), radius: 0, x: 0, y: 5)
                ForEach(0..<60, id: \.self) { m in
                    Capsule()
                        .fill(Palette.ink.opacity(m % 5 == 0 ? 0.8 : 0.3))
                        .frame(width: m % 5 == 0 ? 3 : 1.5, height: m % 5 == 0 ? side * 0.05 : side * 0.025)
                        .offset(y: -r * 0.88)
                        .rotationEffect(.degrees(Double(m) * 6))
                }
                ForEach(1...12, id: \.self) { h in
                    let a = Double(h) * 30 * .pi / 180
                    Text("\(h)")
                        .font(.system(size: side * 0.1, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .position(x: r + CGFloat(sin(a)) * r * 0.7, y: r - CGFloat(cos(a)) * r * 0.7)
                }
                hand(length: r * 0.48, width: side * 0.045, color: Palette.ink, angle: time.hourAngle)
                hand(length: r * 0.74, width: side * 0.026, color: accent, angle: time.minuteAngle)
                Circle().fill(Palette.ink).frame(width: side * 0.07, height: side * 0.07)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : Motion.snappy, value: time)
            .contentShape(Circle())
            .gesture(drag(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), radius: r), including: onChange == nil ? .none : .all)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(onChange == nil ? "A clock. \(time.handsDescription)" : "Your clock. \(time.handsDescription)")
        .accessibilityAdjustableAction { dir in
            guard let onChange else { return }
            onChange(time.adding(minutes: dir == .increment ? 30 : -30))
        }
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color, angle: Double) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }

    private func drag(center: CGPoint, radius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                let dx = Double(v.location.x - center.x), dy = Double(v.location.y - center.y)
                if draggingHour == nil {
                    draggingHour = (dx * dx + dy * dy).squareRoot() < Double(radius) * 0.56
                }
                let a = ClockHands.angle(dx: dx, dy: dy)
                let next: ClockTime
                if draggingHour == true {
                    next = ClockTime(ClockHands.hour(fromAngle: a - Double(time.minute) / 2), time.minute)
                } else {
                    next = ClockHands.wind(time, toMinute: ClockHands.minute(fromAngle: a))
                }
                if next != time {
                    Haptics.tap(.tick)
                    onChange?(next)
                }
            }
            .onEnded { _ in draggingHour = nil }
    }
}
