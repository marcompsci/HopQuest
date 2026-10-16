import SwiftUI
import SpriteKit

/// Pick a Fort Friends level.
struct FortSelectView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void
    var onStart: (FortLevel) -> Void

    private let intro = "Fort Friends! Build ramps, blocks, and bridges to find the balloons and reach the fort. A sleepy rain cloud follows you, so keep building forward!"

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xD8F7FF), Color(hex: 0xFFF0C9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        CircleIconButton(systemName: "house.fill", label: "Back to map", action: onBack)
                        Spacer()
                        SpeakButton { Narrator.shared.say(intro) }
                    }
                    HStack(spacing: 6) {
                        ArtImage("icon_fort").frame(width: 70, height: 70)
                        Text("Fort Friends")
                            .font(.kid(36, .black))
                            .foregroundStyle(Palette.purple)
                    }
                    HStack(spacing: 10) {
                        CharacterBadge(character: store.character, size: 56)
                        Text("Build your way to the fort. No fighting, just building!")
                            .font(.kid(16, .semibold))
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))

                    ForEach(Array(FortLevel.all.enumerated()), id: \.element.id) { i, level in
                        levelCard(level, index: i)
                    }
                    sandboxCard

                    howTo
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .onAppear { Narrator.shared.say(intro) }
    }

    /// Builder's Island: free build, always open.
    private var sandboxCard: some View {
        let pieces = store.profile?.fortSandbox.count ?? 0
        return Button {
            Haptics.tap()
            onStart(FortLevel.sandbox)
        } label: {
            HStack(spacing: 14) {
                Text("🏗️").font(.system(size: 40)).frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Builder's Island").font(.kid(22, .black)).foregroundStyle(.white)
                    Text(pieces == 0 ? "Free build: endless bricks, no rain" : "Your island: \(pieces) pieces")
                        .font(.kid(14, .bold)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill").font(.system(size: 30)).foregroundStyle(.white)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0xFF9F45))
                .shadow(color: Color(hex: 0xD9731C), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Builder's Island, free build")
    }

    private func levelCard(_ level: FortLevel, index: Int) -> some View {
        let best = store.profile?.fortBest[level.id]
        let total = level.rows.joined().filter { $0 == "B" }.count
        let colors: [UInt32] = [0x34C77B, 0x4D96FF, 0xB983FF]
        let color = Color(hex: colors[index % colors.count])
        return Button {
            Haptics.tap()
            onStart(level)
        } label: {
            HStack(spacing: 14) {
                ArtImage(["fort_grass", "piece_bridge", "fort_goal"][index % 3]).frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title).font(.kid(22, .black)).foregroundStyle(.white)
                    Text(level.blurb).font(.kid(14, .bold)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<total, id: \.self) { b in
                            ArtImage("party_balloon")
                                .frame(width: 20, height: 20)
                                .opacity(b < (best ?? 0) ? 1 : 0.3)
                        }
                    }
                    if best != nil {
                        Text("🏰 Done").font(.kid(12, .black)).foregroundStyle(.white)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(color).shadow(color: color.opacity(0.6), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(level.title). \(level.blurb)")
    }

    private var howTo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to build").font(.kid(20, .black)).foregroundStyle(Palette.ink)
            row("piece_ramp", "**Ramp** (2 bricks): walk into it to climb one step up.")
            row("piece_block", "**Block** (1 brick): holds up a ramp so you can climb higher.")
            row("piece_bridge", "**Bridge** (1 brick): walk across gaps and water.")
            row("crate", "**Crates** give bricks. **Golden crates** ask a Brain question for extra bricks!")
            row("rain_cloud", "A sleepy rain cloud drifts behind you. If it catches you, you drop 2 bricks.")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))
    }

    private func row(_ art: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ArtImage(art).frame(width: 34, height: 34)
            Text(text).font(.kid(14, .medium)).foregroundStyle(Palette.ink.opacity(0.85))
        }
    }
}

/// A Fort Friends level plus the results at the end.
struct FortGameView: View {
    let level: FortLevel
    /// Grown-up & Me: the kid walks, the grown-up builds.
    var team = false
    var onExit: () -> Void
    /// (stars, balloons, playAgain)
    var onFinish: (Int, Int, Bool) -> Void

    @EnvironmentObject var store: GameStore
    @StateObject private var hud = FortHUD()
    @State private var scene: FortScene?
    @State private var tool: FortTool?
    @State private var left = false
    @State private var right = false
    /// Builder's Island: the first tap on "Start over" asks to tap again.
    @State private var confirmClear = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0xBFE6FF).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }

                VStack(spacing: 8) {
                    topBar
                    if let message = hud.message {
                        MessageBubble(text: message)
                    }
                    Spacer()
                    controls
                }
                .padding(.top, 6)
                .padding(.bottom, 10)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hud.message)

                if let q = hud.question {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    QuizCard(question: q) { firstTry in
                        scene?.answered(firstTry: firstTry)
                    }
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if hud.finished {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    results
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: hud.question?.id)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: hud.finished)
            .onAppear {
                guard scene == nil, geo.size.width > 0 else { return }
                let s = FortScene(size: geo.size, level: level, character: store.character, theme: store.theme, hud: hud,
                                  team: team, saved: level.sandbox ? (store.profile?.fortSandbox ?? []) : [])
                s.onSandboxChange = { [store] pieces in store.setFortSandbox(pieces) }
                scene = s
            }
            .onDisappear { Narrator.shared.stop() }
        }
    }

    // MARK: HUD

    private var topBar: some View {
        HStack(spacing: 8) {
            CircleIconButton(systemName: "house.fill", label: "Leave the level", action: onExit)
            pill(art: "icon_bricks", hud.endless ? "∞" : "\(hud.bricks)")
                .accessibilityLabel(hud.endless ? "Endless bricks" : "\(hud.bricks) bricks")
            if hud.totalBalloons > 0 {
                pill(art: "party_balloon", "\(hud.balloons)/\(hud.totalBalloons)")
                    .accessibilityLabel("\(hud.balloons) of \(hud.totalBalloons) balloons")
            }
            if team {
                Text("⭐ walks · 💜 builds")
                    .font(.kid(13, .black)).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .padding(.horizontal, 10).frame(height: 36)
                    .background(Capsule().fill(.white.opacity(0.92)))
            }
            Spacer()
            if level.sandbox {
                Button {
                    Haptics.tap()
                    if confirmClear {
                        scene?.clearIsland()
                        confirmClear = false
                    } else {
                        confirmClear = true
                        Narrator.shared.say("Tap again to clear your island.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confirmClear = false }
                    }
                } label: {
                    Text(confirmClear ? "Tap again" : "Start over")
                        .font(.kid(14, .black)).foregroundStyle(confirmClear ? .white : Palette.ink)
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .background(Capsule().fill(confirmClear ? Palette.red : .white.opacity(0.92)))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(confirmClear ? "Tap again to clear your island" : "Start over with an empty island")
            }
            if hud.rainNear {
                HStack(spacing: 4) {
                    ArtImage("rain_cloud").frame(width: 34, height: 20)
                    Text("Rain!").font(.kid(14, .black))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Capsule().fill(Color(hex: 0x6C7BD9)))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .animation(.spring(), value: hud.rainNear)
    }

    private func pill(art: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            ArtImage(art).frame(width: 26, height: 26)
            Text(text).contentTransition(.numericText())
        }
        .font(.kid(20, .black))
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Capsule().fill(.white.opacity(0.92)))
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(FortTool.allCases) { t in
                    toolButton(t)
                }
            }
            HStack(spacing: 12) {
                WalkButton(icon: "arrowtriangle.left.fill", label: "Walk left", pressed: $left)
                WalkButton(icon: "arrowtriangle.right.fill", label: "Walk right", pressed: $right)
                Spacer(minLength: 0)
                Text(tool == nil ? "Pick a piece, then tap a glowing square!" :
                        tool == .recycle ? "Tap a piece to take it back." : "Tap a glowing square to build.")
                    .font(.kid(13, .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .shadow(color: .black.opacity(0.4), radius: 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: left) { _, _ in updateMove() }
        .onChange(of: right) { _, _ in updateMove() }
        .onChange(of: tool) { _, t in scene?.tool = t }
    }

    private func updateMove() {
        scene?.moveInput = (right ? 1 : 0) - (left ? 1 : 0)
    }

    private func toolButton(_ t: FortTool) -> some View {
        let selected = tool == t
        return Button {
            Haptics.tap()
            tool = selected ? nil : t
        } label: {
            VStack(spacing: 0) {
                Group {
                    if let art = t.art {
                        ArtImage(art)
                    } else {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .resizable().scaledToFit()
                            .foregroundStyle(Palette.red)
                    }
                }
                .frame(width: 34, height: 34)
                Text(t.title).font(.kid(12, .black)).lineLimit(1).minimumScaleFactor(0.7)
                if t.cost > 0 && !hud.endless {
                    Text("\(t.cost) 🧱").font(.kid(11, .bold)).opacity(0.75)
                }
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(selected ? Color(hex: 0xFFF4C2) : .white.opacity(0.92))
                    .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: selected ? 1 : 4)
            )
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color(hex: 0xFFB020) : .clear, lineWidth: 4))
            .offset(y: selected ? 3 : 0)
            .opacity(!hud.endless && t.cost > hud.bricks && t != .recycle ? 0.6 : 1)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(t.cost > 0 ? "\(t.title), \(t.cost) bricks" : t.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Results

    private var stars: Int { 1 + hud.balloons + hud.brainRight }

    private var results: some View {
        VStack(spacing: 14) {
            ArtImage("fort_goal").frame(width: 110, height: 140)
            Text("You reached the fort!")
                .font(.kid(30, .black))
                .foregroundStyle(Palette.purple)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(0..<hud.totalBalloons, id: \.self) { i in
                    ArtImage("party_balloon")
                        .frame(width: 40, height: 40)
                        .opacity(i < hud.balloons ? 1 : 0.25)
                }
            }
            HStack(spacing: 16) {
                Label("\(hud.brainRight) Brain crate", systemImage: "lightbulb.fill")
                HStack(spacing: 4) {
                    ArtImage("goal_star").frame(width: 22, height: 22)
                    Text("+\(stars)")
                }
            }
            .font(.kid(17, .bold))
            .foregroundStyle(Palette.ink)
            HStack(spacing: 12) {
                BigButton(title: "Again 🔁", color: Palette.purple) { onFinish(stars, hud.balloons, true) }
                BigButton(title: "Done 🎈", color: Palette.green) { onFinish(stars, hud.balloons, false) }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(18)
        .onAppear {
            let missing = hud.totalBalloons - hud.balloons
            Narrator.shared.say("You built your way to the fort! You found \(hud.balloons) balloons\(missing > 0 ? ". Try again to find the other \(missing)!" : ", every single one!") You earned \(stars) stars!")
        }
    }
}
