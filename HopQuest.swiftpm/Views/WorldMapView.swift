import SwiftUI

struct WorldMapView: View {
    @EnvironmentObject var store: GameStore
    var landing: Int?
    var onPlay: (Chapter) -> Void
    var onTeam: () -> Void = {}
    var onKart: () -> Void = {}

    @State private var showParent = false
    @State private var showCharacters = false
    @State private var balloonOffset: CGFloat = -1000
    @State private var balloonVisible = false
    @State private var puff = false
    @State private var bob = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                clouds(size)

                // painted landscape (sky stays the castle theme's colors)
                if let land = ArtLibrary.image("map_bg") {
                    Image(uiImage: land)
                        .resizable()
                        .frame(width: size.width, height: size.height + geo.safeAreaInsets.bottom)
                        .position(x: size.width / 2, y: (size.height + geo.safeAreaInsets.bottom) / 2)
                        .allowsHitTesting(false)
                }

                trail(size)

                CastleView(theme: store.theme, width: min(size.width * 0.42, 190))
                    .position(x: size.width * 0.5, y: size.height * 0.2)

                ForEach(Chapters.all) { chapter in
                    node(chapter)
                        .position(point(chapter, size))
                }

                avatar(size)
                balloonDrop(size)

                VStack {
                    header
                    Spacer()
                    HStack {
                        Spacer()
                        kartButton
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 10)
                }
            }
        }
        .sheet(isPresented: $showParent) {
            ParentGateView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showCharacters) {
            CharacterSelectView(theme: store.theme, initialID: store.profile?.characterID, buttonTitle: "Use this buddy") { picked in
                store.profile?.characterID = picked.id
                showCharacters = false
            }
            .background(LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
        .onAppear(perform: startLanding)
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 10) {
            Button { showCharacters = true } label: {
                CharacterBadge(character: store.character, size: 52)
                    .background(Circle().fill(.white.opacity(0.9)))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Change your buddy")

            VStack(alignment: .leading, spacing: 0) {
                Text("Hi, \(store.profile?.name ?? "friend")!")
                    .font(.kid(22, .black))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 4) {
                    ArtImage("goal_star").frame(width: 20, height: 20)
                    Text("\(store.profile?.stars ?? 0) stars")
                }
                .font(.kid(16, .bold))
                .foregroundStyle(Palette.purple)
            }
            Spacer()
            Button {
                Haptics.tap()
                onTeam()
            } label: {
                VStack(spacing: 0) {
                    ArtImage("icon_together").frame(width: 30, height: 30)
                    Text("Together").font(.kid(11, .black)).foregroundStyle(Palette.ink)
                }
                .frame(width: 64, height: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(store.theme.accent.opacity(0.35)))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Grown-up and me: play together")
            CircleIconButton(systemName: "gearshape.fill", label: "Grown-ups") { showParent = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.75)))
        .padding(.horizontal, 12)
    }

    private var kartButton: some View {
        Button {
            Haptics.tap()
            onKart()
        } label: {
            HStack(spacing: 6) {
                ArtImage("icon_kart").frame(width: 46, height: 46)
                Text("Bubble Kart").font(.kid(20, .black))
            }
            .foregroundStyle(.white)
            .padding(.leading, 10)
            .padding(.trailing, 22)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(hex: 0xFF7A59)).shadow(color: Color(hex: 0xC2410C), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Bubble Kart racing")
    }

    private func point(_ chapter: Chapter, _ size: CGSize) -> CGPoint {
        CGPoint(x: chapter.mapX * size.width, y: chapter.mapY * size.height)
    }

    private func trail(_ size: CGSize) -> some View {
        let road = Path { p in
            let pts = Chapters.all.map { point($0, size) } + [CGPoint(x: size.width * 0.5, y: size.height * 0.26)]
            guard let first = pts.first else { return }
            p.move(to: first)
            for (a, b) in zip(pts, pts.dropFirst()) {
                let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                p.addQuadCurve(to: b, control: CGPoint(x: mid.x + (b.x > a.x ? -30 : 30), y: mid.y + 20))
            }
        }
        // a winding dirt path with a dotted center line
        return ZStack {
            road.stroke(Color(hex: 0xD9B86A), style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
            road.stroke(Color(hex: 0xF3D99B), style: StrokeStyle(lineWidth: 22, lineCap: .round, lineJoin: .round))
            road.stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [2, 14]))
        }
        .allowsHitTesting(false)
    }

    private func art(for chapter: Chapter) -> String {
        switch chapter.id {
        case 1: return "level_meadow"
        case 2: return "level_driving"
        case 3: return "level_robot"
        case 4: return "level_lily"
        case 5: return "level_rally"
        default: return "level_castle"
        }
    }

    private func node(_ chapter: Chapter) -> some View {
        let state = store.state(of: chapter)
        return Button {
            Haptics.tap()
            onPlay(chapter)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(state == .locked ? Color(hex: 0xEDEFF3) : .white)
                        .frame(width: 76, height: 76)
                        .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 5)
                    ArtImage(art(for: chapter))
                        .frame(width: 58, height: 58)
                        .saturation(state == .locked ? 0 : 1)
                        .opacity(state == .locked ? 0.45 : 1)
                    if state == .locked {
                        ArtImage("level_lock").frame(width: 30, height: 30).offset(x: 26, y: 24)
                    }
                    if state == .done {
                        ArtImage("goal_star").frame(width: 30, height: 30).offset(x: 27, y: -27)
                    }
                }
                .overlay(Circle().stroke(store.theme.accent, lineWidth: state == .open ? 5 : 0).frame(width: 76, height: 76))
                Text(chapter.title)
                    .font(.kid(13, .bold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.9)))
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(state == .locked)
        .accessibilityLabel("\(chapter.title), \(state == .locked ? "locked" : state == .done ? "finished" : "ready to play")")
    }

    @ViewBuilder
    private func avatar(_ size: CGSize) -> some View {
        if !balloonVisible {
            let open = Chapters.chapter(store.nextChapterID)
            let p = point(open, size)
            CharacterBadge(character: store.character, size: 50)
                .offset(y: bob ? -8 : 0)
                .position(x: p.x, y: p.y - 66)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { bob = true }
                }
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func balloonDrop(_ size: CGSize) -> some View {
        if balloonVisible, let landing {
            let p = point(Chapters.chapter(landing), size)
            ZStack {
                BalloonView(theme: store.theme, character: store.character, size: 70)
                    .offset(y: balloonOffset)
                if puff {
                    Text("✨💨✨").font(.system(size: 40)).offset(y: 40)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .position(x: p.x, y: p.y - 95)
            .allowsHitTesting(false)
        }
    }

    // MARK: Balloon landing: tiny balloon drops onto the next level and bounces.

    private func startLanding() {
        guard landing != nil else { return }
        balloonVisible = true
        balloonOffset = -900
        withAnimation(.interpolatingSpring(stiffness: 70, damping: 8).delay(0.15)) {
            balloonOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            Haptics.success()
            if let landing {
                let done = store.profile?.completedChapters.count ?? 0
                if done >= Chapters.all.count {
                    Narrator.shared.say("You finished every adventure! Tap any level to play it again.")
                } else {
                    Narrator.shared.say("Next up: \(Chapters.chapter(landing).title)! Tap it to play.")
                }
            }
            withAnimation(.spring()) { puff = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                puff = false
                balloonVisible = false
            }
        }
    }

    private func clouds(_ size: CGSize) -> some View {
        ZStack {
            CloudView().frame(width: 110, height: 50).position(x: size.width * 0.15, y: size.height * 0.16)
            CloudView().frame(width: 140, height: 60).position(x: size.width * 0.85, y: size.height * 0.24)
            CloudView().frame(width: 90, height: 40).position(x: size.width * 0.8, y: size.height * 0.08)
        }
    }
}

// MARK: - Big-to-little balloon flight between levels

struct BalloonFlightView: View {
    let theme: CastleTheme
    let character: GameCharacter
    var onDone: () -> Void

    @State private var flying = false
    private let cloudXs: [CGFloat] = [0.15, 0.8, 0.4, 0.9, 0.2, 0.65, 0.35]

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: theme.sky + [.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ForEach(cloudXs.indices, id: \.self) { i in
                    CloudView()
                        .frame(width: 130, height: 56)
                        .position(x: cloudXs[i] * geo.size.width,
                                  y: (flying ? h * 1.1 : 0) + CGFloat(i) * h * 0.16 - h * 0.1)
                }
                BalloonView(theme: theme, character: character, size: 120)
                    .scaleEffect(flying ? 0.2 : 2.0)
                    .position(x: geo.size.width / 2, y: flying ? h * 0.06 : h * 0.72)
                Text("Up, up and away! 🎈")
                    .font(.kid(30, .black))
                    .foregroundStyle(Palette.purple)
                    .position(x: geo.size.width / 2, y: h * 0.18)
                    .opacity(flying ? 0 : 1)
            }
        }
        .onAppear {
            Narrator.shared.say("Up, up and away!")
            SoundFX.shared.play(.whoosh)
            withAnimation(.easeIn(duration: 2.0)) { flying = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) { onDone() }
        }
    }
}

// MARK: - Break reminder

struct BreakView: View {
    let name: String
    var onDone: () -> Void
    @State private var seconds = 20
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🧘").font(.system(size: 70))
                Text("Stretch break, \(name)!")
                    .font(.kid(28, .black))
                    .foregroundStyle(Palette.ink)
                Text("Wiggle your fingers, roll your shoulders, and look at something far away.")
                    .font(.kid(18, .semibold))
                    .foregroundStyle(Palette.ink.opacity(0.8))
                    .multilineTextAlignment(.center)
                if seconds > 0 {
                    Text("\(seconds)")
                        .font(.kid(44, .black))
                        .foregroundStyle(Palette.purple)
                        .contentTransition(.numericText())
                } else {
                    BigButton(title: "I'm ready!", color: Palette.green, action: onDone)
                }
            }
            .padding(26)
            .background(RoundedRectangle(cornerRadius: 30).fill(.white))
            .padding(26)
        }
        .onReceive(timer) { _ in
            if seconds > 0 { withAnimation { seconds -= 1 } }
        }
        .onAppear {
            Narrator.shared.say("Stretch break, \(name)! Wiggle your fingers, roll your shoulders, and look at something far away.")
        }
    }
}
