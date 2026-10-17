import SwiftUI

/// A story world from data (Snowy Peaks and later): its levels in order, each opening after the one before.
struct WorldView: View {
    @EnvironmentObject var store: GameStore
    let world: WorldDef
    var onBack: () -> Void
    var onPlay: (Chapter) -> Void

    private var tint: Color { Color(hex: UInt32(world.color, radix: 16) ?? 0x4D96FF) }

    var body: some View {
        ZStack {
            LinearGradient(colors: world.ground == "sand" ? [Color(hex: 0xFFF4D6), Color(hex: 0x9FE6EA)]
                                 : world.ground == "jungle" ? [Color(hex: 0xD8F5C8), Color(hex: 0x7CC47F)]
                                 : [Color(hex: 0xEAF6FF), Color(hex: 0xBFE3FF)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            // gentle falling snow (or rising sea bubbles) behind everything
            SnowfallView(rising: world.ground == "sand", tint: world.ground == "jungle" ? Color(hex: 0x2E7D32) : .white).ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        CircleIconButton(systemName: "house.fill", label: "Back", action: onBack)
                        Spacer()
                        SpeakButton { Narrator.shared.say(world.blurb) }
                    }
                    Text(world.icon).font(.system(size: 64))
                        .accessibilityHidden(true)
                    Text(world.title)
                        .font(.kid(36, .black))
                        .foregroundStyle(tint)
                    Text(world.blurb)
                        .font(.kid(16, .bold))
                        .foregroundStyle(Palette.ink.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    ForEach(Array(world.chapters.enumerated()), id: \.element.id) { i, c in
                        levelCard(c, number: i + 1)
                    }
                    if world.chapters.allSatisfy({ store.profile?.completedChapters.contains($0.id) == true }) {
                        Text("🏆 You finished \(world.title)! Play any level again whenever you like.")
                            .font(.kid(17, .black)).foregroundStyle(Palette.green)
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.9)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .onAppear { Narrator.shared.say("\(world.title)! \(world.blurb)") }
        .onDisappear { Narrator.shared.stop() }
    }

    private func levelCard(_ c: WorldChapter, number: Int) -> some View {
        let state = store.state(of: c, in: world)
        return Button {
            guard state != .locked else {
                Haptics.bump(.oops)
                Narrator.shared.say("Finish the level before this one to open it!")
                return
            }
            Haptics.tap()
            onPlay(Chapters.chapter(c.id))
        } label: {
            HStack(spacing: 14) {
                Text(state == .locked ? "🔒" : c.icon).font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.white.opacity(0.3)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(number). \(c.title)").font(.kid(21, .black))
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(state == .done ? "Finished! Play again ▶" : state == .open ? "Ready to play ▶" : "Locked")
                        .font(.kid(14, .bold)).opacity(0.9)
                }
                Spacer(minLength: 0)
                if state == .done { Image(systemName: "checkmark.seal.fill").font(.title) }
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(state == .locked ? Color(hex: 0x9AA6B8) : tint)
                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Level \(number), \(c.title), \(state == .locked ? "locked" : state == .done ? "finished" : "ready to play")")
    }
}

/// Soft snowflakes drifting down (stops when Reduce Motion is on).
struct SnowfallView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Bubbles that float up instead of snow that falls.
    var rising = false
    /// Snow is white; jungle leaves are green.
    var tint: Color = .white

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let t = context.date.timeIntervalSinceReferenceDate
                    for i in 0..<40 {
                        let seed = Double(i) * 12.9898
                        let x = (sin(seed) * 0.5 + 0.5) * size.width + sin(t * 0.6 + seed) * 18
                        let speed = 18 + Double(i % 5) * 7
                        let fall = (t * speed + seed * 37).truncatingRemainder(dividingBy: size.height + 20) - 10
                        let y = rising ? size.height - fall : fall
                        let r = rising ? 4.0 + Double(i % 4) * 2 : 2.0 + Double(i % 3)
                        let rect = CGRect(x: x, y: y, width: r, height: r)
                        if rising {
                            ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.8)), lineWidth: 1.2)
                        } else {
                            ctx.fill(Path(ellipseIn: rect), with: .color(tint.opacity(0.85)))
                        }
                    }
                }
            }
        }
    }
}
