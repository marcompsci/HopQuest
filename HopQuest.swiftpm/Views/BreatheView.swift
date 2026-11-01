import SwiftUI

/// Breathe with Buddy (v7.3): a calm break. The balloon grows while you breathe in, waits while you hold,
/// and shrinks while you breathe out. Five slow breaths. No stars, no timer to beat.
struct BreatheView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var plan = BreathPlan()
    @State private var started: Date?
    @State private var elapsed: Double = 0
    @State private var lastStep: BreathPlan.Step?
    private let tick = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let st = plan.state(at: elapsed)
        ZStack {
            LinearGradient(colors: [Color(hex: 0xDDF1FF), Color(hex: 0xF4ECFF)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                    Spacer()
                    Text(L10n.tr("Breathe with Buddy")).font(.kid(24, .black)).foregroundStyle(Palette.ink)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                Spacer(minLength: 0)
                balloon(size: st.size, step: st.step)
                    .frame(width: 280, height: 300)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(started == nil ? "A balloon, ready to breathe with you" : "\(st.step.rawValue). Breath \(st.breath) of \(plan.breaths).")
                if started != nil && st.step != .done {
                    Text(L10n.tr(st.step.rawValue)).font(.kid(34, .black)).foregroundStyle(Palette.ink)
                        .id(st.step).transition(.opacity)
                    HStack(spacing: 8) {
                        ForEach(1...plan.breaths, id: \.self) { i in
                            Circle().fill(i < st.breath ? Color(hex: 0x7FC8F8) : (i == st.breath ? Color(hex: 0x4A9EDB) : Palette.ink.opacity(0.12)))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .accessibilityHidden(true)
                } else if st.step == .done {
                    Text(L10n.tr("Nice and calm.")).font(.kid(30, .black)).foregroundStyle(Palette.ink)
                    Text(L10n.tr("You can come back and breathe any time.")).font(.kid(16, .semibold)).foregroundStyle(Palette.ink.opacity(0.65))
                } else {
                    Text(L10n.tr("Big feelings? Let's breathe slowly together.")).font(.kid(19, .bold)).foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)
                if started == nil || st.step == .done {
                    BigButton(title: st.step == .done ? "Again" : "Start", color: Color(hex: 0x4A9EDB)) { begin() }
                    if st.step == .done {
                        Button(L10n.tr("Done")) { onBack() }.font(.kid(17, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 22).padding(.vertical, 10)
        }
        .animation(.easeInOut(duration: 0.4), value: st.step)
        .onReceive(tick) { _ in
            guard let started else { return }
            elapsed = Date().timeIntervalSince(started)
            let now = plan.state(at: elapsed).step
            if now != lastStep {
                lastStep = now
                switch now {
                case .breatheIn: Narrator.shared.say(L10n.tr("Breathe in"))
                case .hold: break
                case .breatheOut: Narrator.shared.say(L10n.tr("Breathe out"))
                case .done:
                    Haptics.success(nil)
                    Narrator.shared.say(L10n.tr("Nice and calm."))
                }
            }
        }
        .onAppear { Narrator.shared.say(L10n.tr("Big feelings? Let's breathe slowly together.")) }
        .onDisappear { Narrator.shared.stop() }
    }

    private func begin() {
        Haptics.tap()
        elapsed = 0
        lastStep = nil
        started = Date()
    }

    /// The balloon. With Reduce Motion it stays the same size and fills up and empties instead.
    private func balloon(size: Double, step: BreathPlan.Step) -> some View {
        let scale = reduceMotion ? 1 : 0.55 + 0.45 * size
        return VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Circle().fill(Color(hex: 0xBFE3FF))
                if reduceMotion {
                    Circle().fill(Color(hex: 0x7FC8F8))
                        .mask(alignment: .bottom) { Rectangle().frame(height: 220 * size) }
                } else {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xA9DBFF), Color(hex: 0x6BB8F0)], center: .topLeading, startRadius: 10, endRadius: 220))
                }
                Ellipse().fill(.white.opacity(0.45)).frame(width: 34, height: 54).rotationEffect(.degrees(30))
                    .offset(x: -50, y: -120)
            }
            .frame(width: 220, height: 220)
            .overlay(Circle().stroke(Palette.ink, lineWidth: 5))
            .overlay(alignment: .center) {
                CharacterBadge(character: store.character, size: 92)
                    .offset(y: 8)
            }
            .scaleEffect(scale)
            BalloonKnot().fill(Color(hex: 0x6BB8F0)).frame(width: 22, height: 14).overlay(BalloonKnot().stroke(Palette.ink, lineWidth: 3))
                .offset(y: -220 * (1 - scale) / 2)
            Path { p in p.move(to: CGPoint(x: 11, y: 0)); p.addQuadCurve(to: CGPoint(x: 11, y: 50), control: CGPoint(x: -6, y: 25)) }
                .stroke(Palette.ink, lineWidth: 3).frame(width: 22, height: 50)
                .offset(y: -220 * (1 - scale) / 2)
        }
    }
}

private struct BalloonKnot: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}
