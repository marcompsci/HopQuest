import SwiftUI
import QuartzCore

/// Runs Star Dash at the screen's frame rate.
@MainActor
final class QuickGameRunner: ObservableObject {
    @Published private(set) var state: QuickGameState
    var input = QuickInput()
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0
    private var seed: UInt64

    init(seed: UInt64 = UInt64.random(in: 0...9_999)) {
        self.seed = seed
        state = QuickGameState.level(seed: seed)
    }

    func start() {
        guard link == nil else { return }
        last = 0
        let l = CADisplayLink(target: Ticker(self), selector: #selector(Ticker.tick(_:)))
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    func restart() {
        seed = UInt64.random(in: 0...9_999)
        state = QuickGameState.level(seed: seed)
        input = QuickInput()
        last = 0
    }

    fileprivate func tick(_ time: CFTimeInterval) {
        let dt = last == 0 ? 1.0 / 60 : time - last
        last = time
        guard !state.over else { return }
        let before = state.collected
        let wasJumps = state.jumpsUsed
        state.step(dt, input)
        input.jump = false
        if state.collected > before { Haptics.tap(.coin) }
        if state.jumpsUsed > wasJumps { SoundFX.shared.play(state.jumpsUsed == 2 ? .whoosh : .hop, volume: 0.6) }
    }

    /// CADisplayLink keeps a strong reference to its target, so a small trampoline holds the runner weakly.
    private final class Ticker: NSObject {
        weak var runner: QuickGameRunner?
        init(_ r: QuickGameRunner) { runner = r }
        @objc func tick(_ link: CADisplayLink) {
            MainActor.assumeIsolated { runner?.tick(link.timestamp) }
        }
    }
}

/// Star Dash: a one-minute quick game. Hold the left half to run left, hold the right half to run right,
/// tap the right half to jump, and tap it again in the air to double jump.
struct QuickGameView: View {
    @EnvironmentObject var store: GameStore
    var onExit: () -> Void

    @StateObject private var runner = QuickGameRunner()
    @State private var rightDown: Date?
    @State private var result: (score: Int, earned: Int, best: Bool)?
    @State private var showHelp = true
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(CalmMotion.key) private var calmMotion = false
    private var reduceMotion: Bool { systemReduceMotion || calmMotion }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                world(geo.size)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                controls
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    hud
                    Spacer()
                    if showHelp { help.transition(.opacity) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 18)
                if let result {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    doneCard(result)
                        .transition(.panel)
                }
            }
        }
        .animation(Motion.standard, value: showHelp)
        .animation(Motion.present, value: result?.score)
        .onAppear {
            runner.start()
            Narrator.shared.say("Star Dash! Hold the left side to run left, hold the right side to run right. Tap the right side to jump, and tap again in the air to double jump!")
        }
        .onDisappear { runner.stop() }
        .onChange(of: runner.state.over) { _, over in if over { finish() } }
    }

    // MARK: World

    private func world(_ size: CGSize) -> some View {
        let s = runner.state
        // 400 world units fill about 70% of the height; the camera keeps the buddy a third of the way in
        let scale = size.height * 0.7 / 400
        let groundY = size.height * 0.78
        let camX = s.x - Double(size.width / scale) * 0.36
        let buddy = CharacterArt.image(store.character)
        let star = ArtLibrary.image("goal_star")
        return Canvas { ctx, sz in
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: CGFloat(x - camX) * scale, y: groundY - CGFloat(y) * scale) }
            // sky and two rows of hills that move slower than the ground
            ctx.fill(Path(CGRect(origin: .zero, size: sz)), with: .linearGradient(Gradient(colors: [Color(hex: 0xBFE6FF), Color(hex: 0xEAF7FF)]),
                                                                                 startPoint: .zero, endPoint: CGPoint(x: 0, y: sz.height)))
            for (speed, color, h) in [(0.2, Color(hex: 0xCDEBC0), 0.34), (0.45, Color(hex: 0xA9DE95), 0.24)] {
                var hills = Path()
                hills.move(to: CGPoint(x: 0, y: sz.height))
                let off = CGFloat(camX * speed).truncatingRemainder(dividingBy: 260)
                var x: CGFloat = -off - 260
                while x < sz.width + 260 {
                    hills.addQuadCurve(to: CGPoint(x: x + 260, y: groundY - sz.height * CGFloat(h) * 0.4),
                                       control: CGPoint(x: x + 130, y: groundY - sz.height * CGFloat(h)))
                    x += 260
                }
                hills.addLine(to: CGPoint(x: sz.width, y: sz.height))
                hills.closeSubpath()
                ctx.fill(hills, with: .color(color))
            }
            // platforms: grass on top, soil below
            for p in s.platforms {
                let a = pt(p.x, p.y)
                let w = CGFloat(p.width) * scale
                guard a.x + w > -20, a.x < sz.width + 20 else { continue }
                let h: CGFloat = p.ground ? sz.height - a.y + 4 : 18 * scale
                let body = Path(roundedRect: CGRect(x: a.x, y: a.y, width: w, height: h), cornerRadius: 10 * scale)
                ctx.fill(body, with: .color(Color(hex: p.ground ? 0xB57A45 : 0xD9A066)))
                ctx.fill(Path(roundedRect: CGRect(x: a.x, y: a.y - 2, width: w, height: 14 * scale), cornerRadius: 7 * scale),
                         with: .color(Color(hex: 0x58C46A)))
                ctx.stroke(body, with: .color(Palette.ink.opacity(0.75)), lineWidth: 2.5)
            }
            // the finish flag
            let flag = pt(s.finishX, 0)
            if flag.x < sz.width + 60 {
                var pole = Path(); pole.move(to: flag); pole.addLine(to: CGPoint(x: flag.x, y: flag.y - 150 * scale))
                ctx.stroke(pole, with: .color(Palette.ink), lineWidth: 5)
                var cloth = Path()
                cloth.move(to: CGPoint(x: flag.x, y: flag.y - 150 * scale))
                cloth.addLine(to: CGPoint(x: flag.x + 60 * scale, y: flag.y - 128 * scale))
                cloth.addLine(to: CGPoint(x: flag.x, y: flag.y - 106 * scale))
                cloth.closeSubpath()
                ctx.fill(cloth, with: .color(Palette.red))
                ctx.stroke(cloth, with: .color(Palette.ink), lineWidth: 2.5)
            }
            // stars
            let starSize = 34 * scale
            for st in s.stars where !st.taken {
                let c = pt(st.x, st.y)
                guard c.x > -40, c.x < sz.width + 40 else { continue }
                let rect = CGRect(x: c.x - starSize / 2, y: c.y - starSize / 2, width: starSize, height: starSize)
                if let star { ctx.draw(Image(uiImage: star), in: rect) } else { ctx.fill(Path(ellipseIn: rect), with: .color(.yellow)) }
            }
            // the buddy (in a balloon after a fall)
            let bw = CGFloat(QuickGameState.playerWidth + 26) * scale
            let bh = bw * 1.1
            var feet = pt(s.x, s.y)
            if s.floatBack > 0 {
                let t = 1 - s.floatBack / 0.9
                let from = pt(s.x, -60), to = pt(s.safeX, s.safeY)
                feet = CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t - CGFloat(sin(t * .pi)) * 80)
                ctx.fill(Path(ellipseIn: CGRect(x: feet.x - 18, y: feet.y - bh - 46, width: 36, height: 42)), with: .color(Palette.red))
            }
            var g = ctx
            g.translateBy(x: feet.x, y: feet.y)
            if !s.facingRight { g.scaleBy(x: -1, y: 1) }
            if !s.onGround && s.floatBack <= 0 && s.jumpsUsed == 2 && !reduceMotion {
                // a little somersault on the double jump, turning around the buddy's middle
                g.translateBy(x: 0, y: -bh / 2)
                g.rotate(by: .degrees((s.time * 720).truncatingRemainder(dividingBy: 360)))
                g.translateBy(x: 0, y: bh / 2)
            }
            let rect = CGRect(x: -bw / 2, y: -bh, width: bw, height: bh)
            if let buddy { g.draw(Image(uiImage: buddy), in: rect) } else { g.fill(Path(ellipseIn: rect), with: .color(Palette.purple)) }
        }
    }

    // MARK: Controls

    /// Two invisible halves: hold left to run left; hold right to run right; a quick tap on the right jumps.
    private var controls: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !runner.input.left { runner.input.left = true; dismissHelp() }
                    }
                    .onEnded { _ in runner.input.left = false })
                .accessibilityElement()
                .accessibilityLabel("Run left")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { nudge(left: true) }
            Color.clear
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if rightDown == nil {
                            rightDown = Date()
                            runner.input.right = true
                            dismissHelp()
                        }
                    }
                    .onEnded { _ in
                        if let down = rightDown, Date().timeIntervalSince(down) < QuickTouch.tapTime {
                            runner.input.jump = true
                        }
                        rightDown = nil
                        runner.input.right = false
                    })
                .accessibilityElement()
                .accessibilityLabel("Run right. Double tap to jump.")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { runner.input.jump = true }
                .accessibilityAction(named: "Run right") { nudge(left: false) }
        }
    }

    /// VoiceOver and Switch Control: a short run in one direction.
    private func nudge(left: Bool) {
        if left { runner.input.left = true } else { runner.input.right = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            runner.input.left = false
            runner.input.right = false
        }
    }

    private func dismissHelp() {
        if showHelp { showHelp = false }
    }

    // MARK: HUD

    private var hud: some View {
        let s = runner.state
        return HStack(spacing: 10) {
            CircleIconButton(systemName: "xmark", label: "Stop playing") { runner.stop(); onExit() }
            HStack(spacing: 6) {
                ArtImage("goal_star").frame(width: 22, height: 22)
                Text("\(s.collected)").monospacedDigit()
            }
            .font(.kid(20, .black)).foregroundStyle(Palette.ink)
            .padding(.horizontal, 12).frame(height: 44)
            .background(Capsule().fill(.regularMaterial))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(s.collected) stars")
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "timer").font(.system(size: 15, weight: .bold))
                Text("\(Int(s.timeLeft.rounded(.up)))").monospacedDigit()
            }
            .font(.kid(20, .black)).foregroundStyle(s.timeLeft < 10 ? Palette.red : Palette.ink)
            .padding(.horizontal, 12).frame(height: 44)
            .background(Capsule().fill(.regularMaterial))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Int(s.timeLeft.rounded(.up))) seconds left")
        }
    }

    private var help: some View {
        HStack(alignment: .bottom) {
            Label("Hold to run", systemImage: "arrow.left")
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label("Hold to run", systemImage: "arrow.right")
                Label("Tap to jump · tap again to double jump", systemImage: "arrow.up")
            }
        }
        .font(.kid(14, .bold)).foregroundStyle(Palette.ink)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.regularMaterial))
        .allowsHitTesting(false)
    }

    // MARK: End

    private func finish() {
        let s = runner.state
        let out = store.recordQuickGame(score: s.score, stars: s.collected, finished: s.finished)
        Haptics.success(.fanfare)
        result = (s.score, out.earned, out.newBest)
        Narrator.shared.say(s.finished ? "You reached the flag with \(s.collected) stars!" : "Time's up! You got \(s.collected) stars!")
    }

    private func doneCard(_ r: (score: Int, earned: Int, best: Bool)) -> some View {
        VStack(spacing: 14) {
            CharacterBadge(character: store.character, size: 84, animated: true)
            Text(runner.state.finished ? "You made it!" : "Time's up!").font(.kid(28, .black)).displayTracking(28)
            Text("\(runner.state.collected) stars · score \(r.score)").font(.kid(18, .bold)).monospacedDigit()
                .foregroundStyle(Palette.ink.opacity(0.75))
            if r.best { Label("New best score!", systemImage: "trophy.fill").font(.kid(16, .black)).foregroundStyle(Color(hex: 0xE0A800)) }
            if r.earned > 0 { Text("+\(r.earned) stars for your collection").font(.kid(15, .bold)).foregroundStyle(Palette.purple) }
            HStack(spacing: 12) {
                BigButton(title: "Again", color: Palette.green) {
                    result = nil
                    runner.restart()
                }
                BigButton(title: "Done", color: Palette.purple) { runner.stop(); onExit() }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.2), radius: 14, y: 6))
        .padding(.horizontal, 24)
    }
}
