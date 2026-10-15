import SwiftUI
import SpriteKit

// MARK: - Hop levels

struct HopGameView: View {
    let chapter: Chapter
    var team: Bool = false
    var onExit: () -> Void
    var onComplete: (Int) -> Void

    @EnvironmentObject var store: GameStore
    @State private var scene: HopScene?
    @State private var deck: [Question] = []
    @State private var quiz: Question?
    @State private var gateRow = 0
    @State private var tip: String?
    @State private var stars = 0
    @State private var progress = 0.0
    @State private var showPad = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0x8FD86E).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }

                VStack(spacing: 10) {
                    GameTopBar(onExit: onExit, progress: progress, stars: stars)
                    Text(chapter.title)
                        .font(.kid(16))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2)
                    if let tip {
                        MessageBubble(text: tip)
                    }
                    Spacer()
                    if team {
                        teamLegend
                    } else if showPad {
                        arrowPad
                    } else {
                        HStack {
                            Text("Tap to hop · Swipe to steer")
                                .font(.kid(15, .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(.black.opacity(0.25)))
                            Button { showPad = true } label: {
                                Image(systemName: "dpad.fill").font(.title2).foregroundStyle(.white)
                            }
                            .accessibilityLabel("Show arrow buttons")
                        }
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: tip)

                if let quiz {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    QuizCard(question: quiz, teamNote: team ? "\(store.profile?.name ?? "Kid") answers — grown-ups can give a hint!" : nil) { firstTry in
                        if firstTry { stars += 1 }
                        self.quiz = nil
                        scene?.clearGate(row: gateRow)
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: quiz?.id)
            .onAppear { setUp(size: geo.size) }
            .onDisappear { Narrator.shared.stop() }
        }
    }

    /// Bottom labels showing which half of the screen belongs to whom.
    private var teamLegend: some View {
        HStack {
            legendSide(store.character, name: store.profile?.name ?? "Kid", tag: "⭐", arrow: "←")
            Spacer()
            legendSide(store.coopCharacter, name: "Grown-up", tag: "💜", arrow: "→")
        }
        .padding(.horizontal, 14)
        .allowsHitTesting(false)   // taps pass through to the game
    }

    private func legendSide(_ c: GameCharacter, name: String, tag: String, arrow: String) -> some View {
        HStack(spacing: 6) {
            CharacterBadge(character: c, size: 34)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(tag) \(name)").font(.kid(14, .black))
                Text("taps this side").font(.kid(11, .bold)).opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(.black.opacity(0.28)))
        .accessibilityElement(children: .combine)
    }

    private var arrowPad: some View {
        VStack(spacing: 8) {
            padButton("arrow.up", "Hop forward") { scene?.hop(dc: 0, dr: 1) }
            HStack(spacing: 8) {
                padButton("arrow.left", "Hop left") { scene?.hop(dc: -1, dr: 0) }
                padButton("arrow.down", "Hop back") { scene?.hop(dc: 0, dr: -1) }
                padButton("arrow.right", "Hop right") { scene?.hop(dc: 1, dr: 0) }
            }
        }
    }

    private func padButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(Palette.ink)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.92)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }

    private func setUp(size: CGSize) {
        guard scene == nil, size.width > 0 else { return }
        deck = QuestionBank.deck(for: chapter)
        let players = team ? [store.character, store.coopCharacter] : [store.character]
        let s = HopScene(size: size, chapter: chapter, characters: players, theme: store.theme)
        s.onGate = { row in
            gateRow = row
            if deck.isEmpty { deck = QuestionBank.deck(for: chapter) }
            quiz = deck.removeFirst()
        }
        s.onTip = { text in showTip(text) }
        s.onProgress = { value in progress = value }
        s.onFinish = { onComplete(stars + 1) }
        scene = s
        if team {
            showTip("Team Hop! Left side moves \(store.profile?.name ?? "the kid"), right side moves the grown-up. Get to the castle together! 🤝")
        } else {
            showTip("Hop to the castle! Answer the Brain Gates on the way. 🏰")
        }
    }

    private func showTip(_ text: String) {
        tip = text
        Narrator.shared.say(text)
        let current = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            if tip == current { tip = nil }
        }
    }
}

// MARK: - Brain Gate card

struct QuizCard: View {
    let question: Question
    var teamNote: String? = nil
    var onDone: (Bool) -> Void

    @State private var wrong: Set<Int> = []
    @State private var solved = false
    @State private var shake: CGFloat = 0
    @State private var hostHop = false

    @EnvironmentObject private var store: GameStore

    private static let letterColors: [UInt32] = [0x4D96FF, 0xFF7A59, 0x34C77B, 0xB983FF]
    private static let host = Roster.character(id: "ollie")

    var body: some View {
        VStack(spacing: 0) {
            // Ollie Owl hosts every Brain Gate
            CharacterBadge(character: Self.host, size: 84, animated: true)
                .offset(y: hostHop ? -14 : 0)
                .zIndex(1)
                .padding(.bottom, -18)

            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Text("Brain Gate").font(.kid(16, .black)).foregroundStyle(.white)
                        Text(question.subject.rawValue)
                            .font(.kid(12, .heavy))
                            .foregroundStyle(Palette.purple)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(.white))
                    }
                    Spacer()
                    SpeakButton(label: "Read the question again") {
                        if solved { Narrator.shared.say(question.explain) } else { Narrator.shared.ask(question) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Palette.purple)

                VStack(spacing: 12) {
                    if let teamNote {
                        Text(teamNote)
                            .font(.kid(13, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Palette.purple.opacity(0.8)))
                    }
                    Text(question.prompt)
                        .font(.kid(24))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(question.choices.indices, id: \.self) { i in
                        answerButton(i)
                    }

                    if solved {
                        HStack(alignment: .top, spacing: 8) {
                            ArtImage("goal_star").frame(width: 30, height: 30)
                            Text(question.explain)
                                .font(.kid(16, .semibold))
                                .foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0xFFF4C2)))
                        BigButton(title: "Keep going! ➜", color: Palette.green) {
                            onDone(wrong.isEmpty)
                        }
                    } else if !wrong.isEmpty {
                        Text("Almost! Try another one. 💪")
                            .font(.kid(17, .bold))
                            .foregroundStyle(Palette.purple)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Palette.purple, lineWidth: 4))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }
        .padding(.horizontal, 20)
        .modifier(Shake(animatableData: shake))
        .onAppear { Narrator.shared.ask(question) }
    }

    private func answerButton(_ i: Int) -> some View {
        let isRight = solved && i == question.answer
        let isWrong = wrong.contains(i)
        let tint = Color(hex: Self.letterColors[i % Self.letterColors.count])
        return Button { pick(i) } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(isWrong ? Color.gray.opacity(0.35) : (isRight ? Palette.green : tint))
                    if isRight {
                        Image(systemName: "checkmark").font(.system(size: 16, weight: .black)).foregroundStyle(.white)
                    } else {
                        Text(["A", "B", "C", "D", "E"][i % 5]).font(.kid(16, .black)).foregroundStyle(.white)
                    }
                }
                .frame(width: 34, height: 34)
                Text(question.choices[i])
                    .font(.kid(20, .bold))
                    .foregroundStyle(isWrong ? Palette.ink.opacity(0.35) : Palette.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill(for: i))
                    .shadow(color: (isWrong ? Color.gray : tint).opacity(isWrong ? 0.15 : 0.35), radius: 0, x: 0, y: 4)
            )
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isRight ? Palette.green : .clear, lineWidth: 3))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(solved || isWrong)
    }

    private func fill(for i: Int) -> Color {
        if solved && i == question.answer { return Color(hex: 0xB8F2CF) }
        if wrong.contains(i) { return Color(hex: 0xEDEDF2) }
        return Color(hex: 0xF3ECFF)
    }

    private func pick(_ i: Int) {
        if i == question.answer {
            Haptics.success(.correct)
            withAnimation(.spring()) { solved = true }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4).repeatCount(3, autoreverses: true)) { hostHop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { withAnimation(.spring()) { hostHop = false } }
            Narrator.shared.say((wrong.isEmpty ? "Yes! " : "You got it! ") + question.explain)
            store.recordAnswer(subject: question.subject.rawValue, firstTry: wrong.isEmpty)
        } else {
            Haptics.bump(.oops)
            Narrator.shared.say("Almost! Try another one.")
            wrong.insert(i)
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
    }
}

// MARK: - Driving levels

struct DriveGameView: View {
    let chapter: Chapter
    var team: Bool = false
    var onExit: () -> Void
    var onComplete: (Int) -> Void

    @EnvironmentObject var store: GameStore
    @StateObject private var hud = DriveHUD()
    @State private var scene: DriveScene?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0x8FD86E).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 120)
                        .ignoresSafeArea()
                }

                VStack(spacing: 10) {
                    topBar
                    HStack(alignment: .top) {
                        SpeedDial(mph: hud.mph, limit: hud.limit)
                        Spacer()
                        if let limit = hud.limit {
                            limitSign(limit)
                        }
                    }
                    .padding(.horizontal, 14)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hud.limit)
                    if let message = hud.message {
                        MessageBubble(text: message)
                    }
                    Spacer()
                    dashboard
                }
                .padding(.top, 6)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hud.message)
            }
            .onAppear {
                guard scene == nil, geo.size.width > 0 else { return }
                scene = DriveScene(size: geo.size, chapter: chapter, character: store.character,
                                   theme: store.theme, hud: hud)
            }
        }
        .onChange(of: hud.finished) { _, done in
            if done { onComplete(hud.stars) }
        }
        .onChange(of: hud.message) { _, message in
            if let message { Narrator.shared.say(message) }
        }
        .onDisappear { Narrator.shared.stop() }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "house.fill", label: "Back to map", action: onExit)
            RoadProgress(progress: hud.progress, character: store.character)
            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(Color(hex: 0xFFC21A))
                Text("\(hud.stars)").contentTransition(.numericText())
            }
            .font(.kid(17, .black))
            HStack(spacing: 4) {
                CoinIcon(size: 20)
                Text("\(hud.coins)").contentTransition(.numericText())
            }
            .font(.kid(17, .black))
        }
        .foregroundStyle(Palette.ink)
        .padding(.leading, 4)
        .padding(.trailing, 14)
        .padding(.vertical, 4)
        .background(Capsule().fill(.ultraThinMaterial))
        .padding(.horizontal, 10)
    }

    private func limitSign(_ limit: Int) -> some View {
        VStack(spacing: 0) {
            Text("SPEED").font(.kid(11, .black))
            Text("LIMIT").font(.kid(11, .black))
            Text("\(limit)").font(.kid(30, .black))
        }
        .foregroundStyle(Palette.ink)
        .frame(width: 66, height: 84)
        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.ink, lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
        .transition(.scale)
    }

    /// Car-style controls: steering wheel + blinkers on the left, brake then gas pedal on the right.
    private var dashboard: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(spacing: 8) {
                if team { roleLabel("💜 Grown-up steers") }
                HStack(spacing: 12) {
                    BlinkerButton(dir: -1, blinker: $hud.blinker)
                    BlinkerButton(dir: 1, blinker: $hud.blinker)
                }
                SteeringWheel(diameter: 140) { value in scene?.steerInput = value }
            }
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                if team { roleLabel("⭐ \(store.profile?.name ?? "Kid") drives") }
                HStack(alignment: .bottom, spacing: 12) {
                    Pedal(kind: .brake) { scene?.brakePedal = $0 }
                    Pedal(kind: .gas) { scene?.gasPedal = $0 }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func roleLabel(_ text: String) -> some View {
        Text(text)
            .font(.kid(13, .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(.black.opacity(0.35)))
    }
}
