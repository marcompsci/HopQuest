import SwiftUI

/// The Machine Workshop: hands-on simple machines. Pick gears, slide a lever's fulcrum, or add pulley ropes,
/// then test it and see the math behind what happened.
struct MachineWorkshopView: View {
    @EnvironmentObject var store: GameStore
    let puzzle: MachinePuzzle
    var onBack: () -> Void
    var onSolved: (Int) -> Void
    var onNext: (MachinePuzzle) -> Void

    // gears
    @State private var gearCount = 2
    @State private var lastSize = 20
    @State private var crankStart: Date?
    // lever
    @State private var fulcrum = 5
    @State private var tilt: Double = -12
    // pulley
    @State private var ropes = 1
    @State private var lift: CGFloat = 0
    @State private var shake: CGFloat = 0

    @State private var testing = false
    @State private var misses = 0
    @State private var feedback: String?
    @State private var solvedStars: Int?

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    Text(feedback ?? puzzle.lesson)
                        .font(.kid(16, .bold))
                        .foregroundStyle(feedback == nil ? Palette.ink.opacity(0.85) : Palette.purple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 70)
                        .animation(.easeInOut, value: feedback)
                    stage
                        .frame(height: 260)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.9)))
                        .padding(.horizontal, 14)
                    controls
                        .padding(.horizontal, 14)
                    BigButton(title: testing ? "Testing…" : testTitle, color: Palette.green) { test() }
                        .padding(.horizontal, 22)
                }
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
            if let stars = solvedStars {
                Color.black.opacity(0.4).ignoresSafeArea()
                solvedCard(stars).transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: solvedStars)
        .onAppear { Narrator.shared.say(puzzle.lesson) }
    }

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", label: "Back to Code Club", action: onBack)
            Spacer()
            Text("⚙️ \(puzzle.title)").font(.kid(24, .black)).foregroundStyle(Palette.ink)
            Spacer()
            SpeakButton { Narrator.shared.say(feedback ?? puzzle.lesson) }
        }
        .padding(.horizontal, 14)
    }

    private var testTitle: String {
        switch puzzle.kind {
        case .gears: return "Crank it! 🔧"
        case .lever: return "Push down! ⬇️"
        case .pulley: return "Pull! 💪"
        }
    }

    // MARK: Stages

    @ViewBuilder
    private var stage: some View {
        switch puzzle.kind {
        case .gears(_, _, let crank): gearStage(crank: crank)
        case .lever(let load, let effort): leverStage(load: load, effort: effort)
        case .pulley(let load, let strength): pulleyStage(load: load, strength: strength)
        }
    }

    private func teeth(crank: Int) -> [Int] {
        [crank] + Array(repeating: 20, count: max(0, gearCount - 2)) + [lastSize]
    }

    private func gearStage(crank: Int) -> some View {
        let train = teeth(crank: crank)
        return TimelineView(.animation(paused: crankStart == nil)) { context in
            let elapsed = crankStart.map { context.date.timeIntervalSince($0) } ?? 0
            HStack(spacing: -10) {
                ForEach(Array(train.enumerated()), id: \.offset) { i, t in
                    let r = CGFloat(t) * 1.7 + 14
                    let direction: Double = i % 2 == 0 ? 1 : -1
                    let speed = Double(crank) / Double(t)
                    ZStack {
                        GearShape(teeth: max(6, t / 2))
                            .fill(i == 0 ? Color(hex: 0x4D96FF) : i == train.count - 1 ? Color(hex: 0xFF7A59) : Color(hex: 0xB983FF))
                            .overlay(GearShape(teeth: max(6, t / 2)).stroke(Palette.ink.opacity(0.35), lineWidth: 2))
                        Circle().fill(.white).frame(width: r * 0.3, height: r * 0.3)
                        if i == train.count - 1 {
                            Text("🌀").font(.system(size: r * 0.5))
                        }
                        if i == 0 {
                            Capsule().fill(Palette.ink).frame(width: 6, height: r * 0.7).offset(y: -r * 0.35)
                        }
                    }
                    .frame(width: r * 2, height: r * 2)
                    .rotationEffect(.degrees(direction * speed * 120 * elapsed))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                HStack {
                    Text("crank").font(.kid(13, .black)).foregroundStyle(Color(hex: 0x4D96FF))
                    Spacer()
                    Text("fan").font(.kid(13, .black)).foregroundStyle(Color(hex: 0xFF7A59))
                }
                .padding(.horizontal, 24).padding(.bottom, 10)
            }
        }
        .accessibilityLabel("\(train.count) gears. The crank gear has \(train[0]) teeth and the fan gear has \(lastSize).")
    }

    private func leverStage(load: Int, effort: Int) -> some View {
        let width: CGFloat = 300
        let f = CGFloat(fulcrum) / CGFloat(Lever.length)
        return VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .bottomLeading) {
                // the board, with the load and the buddy riding on it
                ZStack(alignment: .bottom) {
                    Capsule().fill(Color(hex: 0xC48A5A)).frame(width: width, height: 14)
                    HStack(alignment: .bottom) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x8D6E63)).frame(width: 54, height: 46)
                            Text("\(load)").font(.kid(22, .black)).foregroundStyle(.white)
                        }
                        Spacer()
                        VStack(spacing: 0) {
                            CharacterBadge(character: store.character, size: 50)
                            Text("\(effort)").font(.kid(14, .black)).foregroundStyle(Palette.ink)
                        }
                    }
                    .frame(width: width)
                    .offset(y: -12)
                }
                .rotationEffect(.degrees(tilt), anchor: UnitPoint(x: f, y: 1))
                .offset(y: -44)
                // the fulcrum
                Triangle()
                    .fill(Palette.purple)
                    .frame(width: 40, height: 44)
                    .offset(x: width * f - 20)
            }
            .frame(width: width, height: 160)
            .animation(.spring(response: 0.6, dampingFraction: 0.55), value: tilt)
            .animation(.spring(response: 0.3), value: fulcrum)
            Rectangle().fill(Color(hex: 0x6CC24A)).frame(height: 10)
            // ruler under the board so kids can count distances
            HStack(spacing: 0) {
                ForEach(0...Lever.length, id: \.self) { i in
                    Text("\(i)").font(.kid(10, .bold)).foregroundStyle(Palette.ink.opacity(i == fulcrum ? 1 : 0.45))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: width + 28)
            .padding(.vertical, 6)
        }
        .accessibilityLabel("A lever. The box weighs \(load), your buddy weighs \(effort). The fulcrum is at \(fulcrum).")
    }

    private func pulleyStage(load: Int, strength: Int) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: 0x6B6784)).frame(height: 12)
            HStack(spacing: 14) {
                ForEach(0..<ropes, id: \.self) { _ in
                    Circle().stroke(Palette.ink, lineWidth: 4).frame(width: 30, height: 30)
                        .background(Circle().fill(Color(hex: 0xFFD24D)))
                }
            }
            .padding(.top, 4)
            HStack(alignment: .bottom, spacing: 30) {
                VStack(spacing: 0) {
                    HStack(spacing: 40 - CGFloat(ropes) * 4) {
                        ForEach(0..<ropes, id: \.self) { _ in
                            Rectangle().fill(Palette.ink).frame(width: 3, height: 110 - lift)
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x8D6E63)).frame(width: 90, height: 60)
                        Text("\(load)").font(.kid(26, .black)).foregroundStyle(.white)
                    }
                    .offset(x: shake)
                }
                VStack(spacing: 2) {
                    CharacterBadge(character: store.character, size: 56)
                    Text("can pull \(strength)").font(.kid(13, .black)).foregroundStyle(Palette.ink)
                }
            }
            Spacer(minLength: 0)
            Rectangle().fill(Color(hex: 0x6CC24A)).frame(height: 10)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: lift)
        .animation(.spring(response: 0.3), value: ropes)
        .accessibilityLabel("A box weighing \(load) held by \(ropes) ropes. Your buddy can pull \(strength).")
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        switch puzzle.kind {
        case .gears:
            VStack(spacing: 10) {
                picker("Gears", options: [2, 3, 4], selected: gearCount, label: { "\($0)" }) { gearCount = $0 }
                picker("Fan gear", options: MachinePuzzle.gearSizes, selected: lastSize,
                       label: { $0 == 10 ? "Small" : $0 == 20 ? "Medium" : "Big" }) { lastSize = $0 }
            }
        case .lever:
            HStack(spacing: 14) {
                stepButton("arrow.left", "Move the fulcrum left") { fulcrum = max(1, fulcrum - 1); resetMachine() }
                Text("Fulcrum at \(fulcrum)").font(.kid(18, .black)).foregroundStyle(Palette.ink)
                stepButton("arrow.right", "Move the fulcrum right") { fulcrum = min(9, fulcrum + 1); resetMachine() }
            }
        case .pulley:
            picker("Ropes", options: [1, 2, 3, 4], selected: ropes, label: { "\($0)" }) { ropes = $0; resetMachine() }
        }
    }

    private func picker(_ title: String, options: [Int], selected: Int, label: @escaping (Int) -> String,
                        onPick: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.kid(15, .black)).foregroundStyle(Palette.ink).frame(width: 80, alignment: .leading)
            ForEach(options, id: \.self) { o in
                Button {
                    guard !testing else { return }
                    Haptics.tap()
                    onPick(o)
                    crankStart = nil
                } label: {
                    Text(label(o))
                        .font(.kid(16, .black))
                        .foregroundStyle(o == selected ? .white : Palette.ink)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(o == selected ? Palette.purple : .white))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("\(title): \(label(o))\(o == selected ? ", selected" : "")")
            }
        }
    }

    private func stepButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            guard !testing else { return }
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon).font(.system(size: 22, weight: .black)).foregroundStyle(.white)
                .frame(width: 60, height: 50)
                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.purple))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }

    private func resetMachine() {
        tilt = -12
        lift = 0
        feedback = nil
    }

    // MARK: Testing

    private func test() {
        guard !testing else { return }
        testing = true
        Haptics.tap(.pop)
        let choice: Int
        switch puzzle.kind {
        case .gears: choice = gearCount
        case .lever: choice = fulcrum
        case .pulley: choice = ropes
        }
        let ok = puzzle.check(choice: choice, size: lastSize)
        let best = puzzle.isBest(choice: choice, size: lastSize)
        let explanation = explain()
        Task { @MainActor in
            switch puzzle.kind {
            case .gears:
                crankStart = Date()
                SoundFX.shared.play(.whoosh)
                try? await Task.sleep(nanoseconds: 2_200_000_000)
            case .lever(let load, let effort):
                let lever = Lever(fulcrum: fulcrum, load: load, effort: effort)
                tilt = lever.lifts ? 14 : lever.balanced ? 0 : -6
                SoundFX.shared.play(lever.lifts ? .boing : .oops)
                try? await Task.sleep(nanoseconds: 900_000_000)
                if !lever.lifts && !lever.balanced { tilt = -12 }
            case .pulley:
                if ok {
                    lift = 70
                    SoundFX.shared.play(.whoosh)
                } else {
                    for x in [8.0, -8, 6, -6, 0] { shake = x; try? await Task.sleep(nanoseconds: 70_000_000) }
                    SoundFX.shared.play(.oops)
                }
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
            testing = false
            feedback = explanation
            Narrator.shared.say(explanation)
            if ok {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                let stars = 1 + (misses == 0 ? 1 : 0) + (best ? 1 : 0)
                Haptics.success(.fanfare)
                solvedStars = stars
                onSolved(stars)
            } else {
                misses += 1
                Haptics.bump(.oops)
            }
        }
    }

    /// What happened, with the math, in kid words.
    private func explain() -> String {
        switch puzzle.kind {
        case .gears(let wantCW, let wantFast, let crank):
            let train = GearTrain(teeth: teeth(crank: crank))
            let way = train.lastTurnsClockwise ? "clockwise ↻" : "the other way ↺"
            let ratio = train.turnsPerCrank
            let speed = ratio > 1 ? "faster than the crank" : ratio == 1 ? "the same speed as the crank" : "slower than the crank"
            var text = "The fan turned \(way), \(speed). "
            if train.lastTurnsClockwise != wantCW {
                text += "Touching gears flip the direction. Try a different number of gears!"
            } else if wantFast && ratio <= 1 {
                text += "To go faster, let a big gear turn a small one."
            } else {
                text += "That's it! 🎉"
            }
            return text
        case .lever(let load, let effort):
            let lever = Lever(fulcrum: fulcrum, load: load, effort: effort)
            let boxSide = load * fulcrum
            let buddySide = effort * (Lever.length - fulcrum)
            let math = "Box: \(load) × \(fulcrum) = \(boxSide). Buddy: \(effort) × \(Lever.length - fulcrum) = \(buddySide). "
            if lever.lifts { return math + "Your buddy wins and lifts the box! 🎉" }
            if lever.balanced { return math + "A perfect balance! Move the fulcrum a little closer to the box." }
            return math + "The box is winning. Slide the fulcrum closer to the box."
        case .pulley(let load, let strength):
            let p = Pulley(ropes: ropes, load: load)
            let math = ropes == 1 ? "One rope means pulling all \(load). " : "\(load) shared by \(ropes) ropes is about \(p.effort) each. "
            if p.effort <= strength {
                return math + "Your buddy can pull \(strength), so up it goes! You pulled \(p.ropePulled)× as much rope. 🎉"
            }
            return math + "That's more than \(strength). Add another rope!"
        }
    }

    private func solvedCard(_ stars: Int) -> some View {
        let next = MachinePuzzle.all.firstIndex { $0.id == puzzle.id }.flatMap { i in
            i + 1 < MachinePuzzle.all.count ? MachinePuzzle.all[i + 1] : nil
        }
        return VStack(spacing: 14) {
            Text("⚙️").font(.system(size: 54))
            Text("Machine works!").font(.kid(30, .black)).foregroundStyle(Palette.purple)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    ArtImage("goal_star").frame(width: 40, height: 40).opacity(i < stars ? 1 : 0.25)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Label("Did you know?", systemImage: "lightbulb.fill").font(.kid(15, .black)).foregroundStyle(Color(hex: 0xE0A92E))
                Text(puzzle.funFact).font(.kid(16, .bold)).foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0xFFF4C2)))
            HStack(spacing: 12) {
                BigButton(title: "Try again", color: Palette.purple) {
                    solvedStars = nil
                    misses = 0
                    crankStart = nil
                    resetMachine()
                }
                if let next {
                    BigButton(title: "Next ➜", color: Palette.green) { onNext(next) }
                } else {
                    BigButton(title: "Done 🎉", color: Palette.green) { onBack() }
                }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(18)
        .onAppear { Narrator.shared.say("Your machine works! Did you know? \(puzzle.funFact)") }
    }
}

/// A gear outline with square-ish teeth.
struct GearShape: Shape {
    let teeth: Int

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.8
        let n = max(teeth, 3)
        var p = Path()
        for i in 0..<(n * 4) {
            let a = Double(i) / Double(n * 4) * 2 * .pi
            // two points out, two points in, per tooth
            let r = (i % 4 == 1 || i % 4 == 2) ? outer : inner
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
