import SwiftUI
import SpriteKit

/// Pillow Bop Arena: how-to card, the match, and the results.
struct BopGameView: View {
    /// Two players on one phone: the second player's buddy.
    var partner: GameCharacter? = nil
    var onExit: () -> Void
    /// (stars, playAgain)
    var onFinish: (Int, Bool) -> Void

    @EnvironmentObject var store: GameStore
    @StateObject private var hud = BopHUD()
    @State private var scene: BopScene?
    @State private var showIntro = true
    @AppStorage(Handedness.key) private var leftHanded = false
    @AppStorage("hopquest.bop.arena") private var arenaID = BopArena.cloud.rawValue
    private var arena: BopArena { BopArena(rawValue: arenaID) ?? .cloud }
    @State private var left = false
    @State private var right = false
    @State private var left2 = false
    @State private var right2 = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0xBFE6FF).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }

                if !showIntro {
                    VStack(spacing: 8) {
                        topBar
                        scoreboard
                        if let message = hud.message {
                            MessageBubble(text: message)
                        }
                        Spacer()
                        controls
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 14)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hud.message)
                }

                if let count = hud.countdown {
                    Text(count)
                        .font(.kid(96, .black))
                        .foregroundStyle(.white)
                        .shadow(color: Palette.purple, radius: 0, x: 4, y: 6)
                        .id(count)
                        .transition(.scale(scale: 2).combined(with: .opacity))
                }

                if let q = hud.question {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    QuizCard(question: q) { firstTry in
                        scene?.answered(firstTry: firstTry)
                    }
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if showIntro {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    intro
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                if hud.finished {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    results
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hud.countdown)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: hud.question?.id)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: hud.finished)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showIntro)
            .onAppear {
                Narrator.shared.say(introText)
                // the arena is visible (paused) behind the how-to card
                guard scene == nil, geo.size.width > 0 else { return }
                let s = BopScene(size: geo.size, character: store.character, partner: partner, theme: store.theme, hud: hud)
                s.arena = arena
                scene = s
            }
            .onDisappear { Narrator.shared.stop() }
        }
    }

    private var introText: String {
        "Pillow Bop! Bop your friends with a fluffy pillow to push them toward the edge. If anyone falls, a balloon floats them right back. Pop the Brain Bubble and answer the question for a giant pillow!"
    }

    // MARK: How to play

    private var intro: some View {
        VStack(spacing: 14) {
            HStack {
                CircleIconButton(systemName: "house.fill", label: "Back to map", action: onExit)
                Spacer()
                SpeakButton { Narrator.shared.say(introText) }
            }
            // the art and rows scroll on small phones; the start button always stays on screen
            ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
            ArtImage("icon_bop").frame(width: 90, height: 90)
            Text("Pillow Bop")
                .font(.kid(36, .black))
                .foregroundStyle(Palette.purple)
            VStack(alignment: .leading, spacing: 10) {
                if partner != nil {
                    row(icon: "person.2.fill", "**Two players:** ⭐ uses the buttons on the left, 💜 uses the buttons on the right.")
                }
                row(art: "pillow", "Tap **BOP** to swing your pillow. Each bop is a point!")
                row(icon: "arrow.up.circle.fill", "Tap **JUMP** to reach the clouds. Tap again in the air for a double jump.")
                row(art: "balloon_\(store.theme.rawValue)", "Fall off? No problem! A balloon floats you back.")
                row(art: "brain_bubble", "Pop the **Brain Bubble** and answer it for a GIANT pillow.")
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xF3ECFF)))
            arenaPicker
            }
            }
            BigButton(title: "Let's bop! 🪶", color: Palette.green) {
                showIntro = false
                scene?.begin()
                SoundFX.shared.play(.go)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(18)
    }

    /// Pick where to bop. Each arena plays a little differently.
    private var arenaPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick an arena").font(.kid(18, .black)).foregroundStyle(Palette.ink)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(BopArena.allCases) { a in
                    let on = a == arena
                    Button {
                        Haptics.tap(.pop)
                        arenaID = a.rawValue
                        scene?.arena = a
                        Narrator.shared.say("\(a.title)! \(a.blurb) \(a.fact ?? "")")
                    } label: {
                        VStack(spacing: 2) {
                            Text(a.icon).font(.system(size: 28))
                            Text(a.title).font(.kid(14, .black)).foregroundStyle(Palette.ink)
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text(a.blurb).font(.kid(11, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 16).fill(on ? Color(hex: 0xDDF7E5) : Color(hex: 0xF3F1FA)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(on ? Palette.green : .clear, lineWidth: 3))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("\(a.title). \(a.blurb)\(on ? ", chosen" : "")")
                }
            }
        }
    }

    private func row(art: String? = nil, icon: String? = nil, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Group {
                if let art { ArtImage(art) } else if let icon {
                    Image(systemName: icon).resizable().scaledToFit().foregroundStyle(Palette.purple)
                }
            }
            .frame(width: 38, height: 38)
            Text(text).font(.kid(16, .medium)).foregroundStyle(Palette.ink)
            Spacer(minLength: 0)
        }
    }

    // MARK: HUD

    private var topBar: some View {
        HStack(spacing: 8) {
            CircleIconButton(systemName: "house.fill", label: "Leave the arena", action: onExit)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "timer").font(.system(size: 18, weight: .black))
                Text("\(hud.timeLeft)")
                    .contentTransition(.numericText())
            }
            .font(.kid(22, .black))
            .foregroundStyle(hud.timeLeft <= 10 ? Palette.red : Palette.ink)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Capsule().fill(.white.opacity(0.92)))
            .accessibilityLabel("\(hud.timeLeft) seconds left")
            Spacer()
            if hud.giant || hud.giant2 {
                Text(partner == nil ? "GIANT!" : "\(hud.giant ? "⭐" : "")\(hud.giant2 ? "💜" : "") GIANT!")
                    .font(.kid(16, .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).frame(height: 36)
                    .background(Capsule().fill(Color(hex: 0xFFB020)))
                    .transition(.scale)
            } else {
                Color.clear.frame(width: 48, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .animation(.spring(), value: hud.giant)
    }

    private var scoreboard: some View {
        HStack(spacing: 8) {
            ForEach(hud.entries) { e in
                VStack(spacing: 3) {
                    ZStack(alignment: .topTrailing) {
                        CharacterBadge(character: e.character, size: 40)
                            .opacity(e.floating ? 0.4 : 1)
                        if e.floating { Text("🎈").font(.system(size: 16)).offset(x: 6, y: -4) }
                    }
                    Text("\(e.bops)")
                        .font(.kid(18, .black))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    // giggle meter: the higher it is, the farther a bop pushes you
                    Capsule()
                        .fill(Palette.ink.opacity(0.12))
                        .frame(width: 46, height: 7)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(e.giggles > 0.6 ? Palette.red : e.giggles > 0.3 ? Color(hex: 0xFFB020) : Palette.green)
                                .frame(width: max(4, 46 * e.giggles), height: 7)
                        }
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(e.isPlayer ? 0.95 : 0.75))
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(e.isPlayer ? (e.seat == 1 ? Palette.purple : store.theme.accent) : .clear, lineWidth: 3))
                .overlay(alignment: .top) {
                    if let seat = e.seat { Text(seat == 0 ? "⭐" : "💜").font(.system(size: 14)).offset(y: -9) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(name(e)): \(e.bops) bops")
            }
        }
        .padding(.horizontal, 14)
        .animation(.spring(response: 0.3), value: hud.entries)
    }

    private func name(_ e: BopHUD.Entry) -> String {
        switch e.seat {
        case 0?: return "⭐ \(e.character.name)"
        case 1?: return "💜 \(e.character.name)"
        default: return e.isPlayer ? "You" : e.character.name
        }
    }

    @ViewBuilder
    private var controls: some View {
        if partner != nil { twoPlayerControls } else { soloControls }
    }

    /// One cluster per player: ⭐ on the left, 💜 on the right.
    private var twoPlayerControls: some View {
        HStack(alignment: .bottom) {
            seatCluster(0, left: $left, right: $right)
            Spacer(minLength: 6)
            seatCluster(1, left: $left2, right: $right2)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: left) { _, _ in updateMove() }
        .onChange(of: right) { _, _ in updateMove() }
        .onChange(of: left2) { _, _ in updateMove() }
        .onChange(of: right2) { _, _ in updateMove() }
    }

    private func seatCluster(_ seat: Int, left: Binding<Bool>, right: Binding<Bool>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                actionButton(title: "JUMP", color: Color(hex: 0x4D96FF), size: 64) { scene?.jump(seat: seat) }
                actionButton(title: "BOP!", color: Color(hex: 0xFF7FC4), size: 70) { scene?.bop(seat: seat) }
            }
            HStack(spacing: 8) {
                WalkButton(icon: "arrowtriangle.left.fill", label: (seat == 0 ? "Star player " : "Heart player ") + "move left", pressed: left)
                WalkButton(icon: "arrowtriangle.right.fill", label: (seat == 0 ? "Star player " : "Heart player ") + "move right", pressed: right)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: seat == 0 ? 0xFFD93D : 0xB983FF).opacity(0.35)))
        .overlay(alignment: .topLeading) {
            Text(seat == 0 ? "⭐" : "💜").font(.system(size: 20)).offset(x: -4, y: -12)
        }
    }

    private var soloControls: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if leftHanded {
                actionButton(title: "BOP!", color: Color(hex: 0xFF7FC4), size: 92) { scene?.bop() }
                actionButton(title: "JUMP", color: Color(hex: 0x4D96FF), size: 74) { scene?.jump() }
                Spacer(minLength: 0)
                WalkButton(icon: "arrowtriangle.left.fill", label: "Move left", pressed: $left)
                WalkButton(icon: "arrowtriangle.right.fill", label: "Move right", pressed: $right)
            } else {
                WalkButton(icon: "arrowtriangle.left.fill", label: "Move left", pressed: $left)
                WalkButton(icon: "arrowtriangle.right.fill", label: "Move right", pressed: $right)
                Spacer(minLength: 0)
                actionButton(title: "JUMP", color: Color(hex: 0x4D96FF), size: 74) { scene?.jump() }
                actionButton(title: "BOP!", color: Color(hex: 0xFF7FC4), size: 92) { scene?.bop() }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: left) { _, _ in updateMove() }
        .onChange(of: right) { _, _ in updateMove() }
    }

    private func updateMove() {
        scene?.moveInput = (right ? 1 : 0) - (left ? 1 : 0)
        scene?.moveInput2 = (right2 ? 1 : 0) - (left2 ? 1 : 0)
    }

    private func actionButton(title: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        TapDownButton(title: title, color: color, size: size, action: action)
    }

    // MARK: Results

    /// The best place a person got (with two players, the team's best).
    private var bestPlace: Int { (hud.ranking.firstIndex { $0.isPlayer } ?? 3) + 1 }

    private var stars: Int {
        [3, 2, 1, 1][min(bestPlace, 4) - 1] + hud.brainRight
    }

    private var results: some View {
        let place = bestPlace
        return VStack(spacing: 14) {
            Text(place == 1 ? (partner == nil ? "🏆 Pillow Champ!" : "🏆 \(hud.ranking.first.map(name) ?? "") wins!") : "🪶 What a bop-fest!")
                .font(.kid(30, .black))
                .foregroundStyle(Palette.purple)
            VStack(spacing: 8) {
                ForEach(Array(hud.ranking.enumerated()), id: \.element.id) { i, e in
                    HStack(spacing: 10) {
                        Text(["🥇", "🥈", "🥉", "🎀"][min(i, 3)]).font(.system(size: 26))
                        CharacterBadge(character: e.character, size: 40)
                        Text(name(e))
                            .font(.kid(18, .bold))
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(e.bops) bops").font(.kid(17, .black)).foregroundStyle(Palette.purple)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 14).fill(e.isPlayer ? Color(hex: 0xFFF4C2) : Color(hex: 0xF3ECFF)))
                }
            }
            HStack(spacing: 16) {
                Label("\(hud.brainRight) Brain Bubbles", systemImage: "lightbulb.fill")
                HStack(spacing: 4) {
                    ArtImage("goal_star").frame(width: 22, height: 22)
                    Text("+\(stars)")
                }
            }
            .font(.kid(17, .bold))
            .foregroundStyle(Palette.ink)
            HStack(spacing: 12) {
                BigButton(title: "Again 🔁", color: Palette.purple) { onFinish(stars, true) }
                BigButton(title: "Done 🎈", color: Palette.green) { onFinish(stars, false) }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(18)
        .onAppear {
            if partner == nil {
                // best scores are a solo record, so a grown-up can't set one for the kid
                store.recordBop(hud.ranking.first { $0.isPlayer }?.bops ?? 0)
                let words = ["first", "second", "third", "fourth"][min(place, 4) - 1]
                Narrator.shared.say("You came in \(words) with \(hud.ranking.first { $0.isPlayer }?.bops ?? 0) bops, and earned \(stars) stars! Great sportsmanship!")
            } else {
                let a = hud.ranking.first { $0.seat == 0 }?.bops ?? 0, b = hud.ranking.first { $0.seat == 1 }?.bops ?? 0
                Narrator.shared.say("Star player bopped \(a) times and heart player bopped \(b) times! You earned \(stars) stars together. Great sportsmanship!")
            }
        }
    }
}

/// A button you hold down (for walking left and right).
struct WalkButton: View {
    let icon: String
    let label: String
    @Binding var pressed: Bool
    /// Resets by itself if the touch is interrupted (a call, Control Center, the app going to the background),
    /// so a buddy never keeps walking on its own.
    @GestureState private var holding = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 30, weight: .black))
            .foregroundStyle(Palette.ink)
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(pressed ? 1 : 0.9))
                    .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: pressed ? 1 : 5)
            )
            .offset(y: pressed ? 4 : 0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($holding) { _, state, _ in state = true }
            )
            .onChange(of: holding) { _, isDown in
                pressed = isDown
                if isDown { Haptics.tap(nil) }
            }
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                // VoiceOver: a short walk
                pressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { pressed = false }
            }
    }
}

/// A round button that fires the moment your finger touches it (no waiting for lift-off).
struct TapDownButton: View {
    let title: String
    let color: Color
    let size: CGFloat
    var action: () -> Void
    /// Resets by itself if the touch is interrupted, so the button never gets stuck.
    @GestureState private var down = false

    var body: some View {
        Text(title)
            .font(.kid(size * 0.24, .black))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(color)
                    .shadow(color: color.opacity(0.6), radius: 0, x: 0, y: down ? 1 : 5)
            )
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .offset(y: down ? 4 : 0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($down) { _, state, _ in state = true }
            )
            .onChange(of: down) { _, isDown in if isDown { action() } }
            .accessibilityElement()
            .accessibilityLabel(title == "BOP!" ? "Bop" : "Jump")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
            .accessibilityAction { action() }
    }
}
