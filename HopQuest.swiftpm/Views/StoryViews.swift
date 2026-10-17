import SwiftUI

/// Plays a cutscene: picture-book panels with characters that slide or pop in, and each line read aloud
/// in that character's voice. Tap Next (or anywhere) to go on; Skip ends it right away.
struct CutsceneView: View {
    let scene: Cutscene
    let character: GameCharacter
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var panel = 0
    @State private var line = 0
    @State private var shown = false

    private var current: StoryPanel { scene.panels[min(panel, scene.panels.count - 1)] }
    private var currentLine: StoryLine { current.lines[min(line, current.lines.count - 1)] }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop(geo.size)
                ForEach(Array(current.actors.enumerated()), id: \.offset) { i, actor in
                    actorView(actor)
                        .position(x: geo.size.width * actor.x, y: geo.size.height * 0.58)
                        .offset(x: shown || reduceMotion ? 0 : entranceOffset(actor.entrance, width: geo.size.width),
                                y: shown || reduceMotion ? 0 : (actor.entrance == .float ? 60 : 0))
                        .scaleEffect(shown || reduceMotion || actor.entrance != .pop ? 1 : 0.2)
                        .opacity(shown || reduceMotion ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(Double(i) * 0.15), value: shown)
                        .accessibilityHidden(true)
                }
                VStack {
                    HStack {
                        Text(scene.title).font(.kid(18, .black)).foregroundStyle(.white)
                            .padding(.horizontal, 12).frame(minHeight: 36)
                            .background(Capsule().fill(.black.opacity(0.25)))
                        Spacer()
                        Button {
                            Narrator.shared.stop()
                            onDone()
                        } label: {
                            Text("Skip ⏭").font(.kid(16, .black)).foregroundStyle(Palette.ink)
                                .padding(.horizontal, 14).frame(minHeight: 44)
                                .background(Capsule().fill(.white.opacity(0.9)))
                        }
                        .accessibilityLabel("Skip the story")
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                    bubble
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { next() }
        }
        .ignoresSafeArea(edges: .horizontal)
        .onAppear {
            shown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { shown = true }
            speak()
        }
        .onDisappear { Narrator.shared.stop() }
    }

    private func backdrop(_ size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: current.place.skyHex.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Ellipse().fill(Color(hex: current.place.groundHex))
                .frame(width: size.width * 1.6, height: size.height * 0.5)
                .offset(y: size.height * 0.2)
            ForEach(Array(current.place.props.enumerated()), id: \.offset) { i, p in
                Text(p).font(.system(size: 44)).opacity(0.75)
                    .position(x: size.width * [0.12, 0.5, 0.88][i % 3], y: size.height * [0.42, 0.3, 0.45][i % 3])
            }
        }
        .animation(.easeInOut(duration: 0.4), value: panel)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func actorView(_ a: StoryActor) -> some View {
        if a.who == "buddy" {
            CharacterBadge(character: character, size: 110 * a.size)
        } else {
            Text(a.who).font(.system(size: 90 * a.size))
        }
    }

    private func entranceOffset(_ e: StoryActor.Entrance, width: CGFloat) -> CGFloat {
        switch e {
        case .fromLeft: return -width
        case .fromRight: return width
        case .pop, .float: return 0
        }
    }

    private var bubble: some View {
        let speaker = currentLine.voice == .buddy ? character.name : currentLine.voice.name
        return VStack(alignment: .leading, spacing: 10) {
            if !speaker.isEmpty {
                Text("\(currentLine.voice == .buddy ? character.emoji : currentLine.voice.emoji) \(speaker)")
                    .font(.kid(16, .black)).foregroundStyle(Palette.purple)
            }
            Text(currentLine.text)
                .font(.kid(20, currentLine.voice == .narrator ? .bold : .heavy))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                SpeakButton(label: "Read it again") { speak() }
                Spacer()
                Button { next() } label: {
                    Text(isLast ? "Done ✓" : "Next ▶").font(.kid(18, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 20).frame(minHeight: 50)
                        .background(Capsule().fill(Palette.green))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(isLast ? "Done" : "Next")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(.white).shadow(color: .black.opacity(0.2), radius: 10, y: 4))
        .id("\(panel)-\(line)")
        .transition(.opacity)
        .accessibilityElement(children: .contain)
    }

    private var isLast: Bool { panel == scene.panels.count - 1 && line == current.lines.count - 1 }

    private func speak() {
        let l = currentLine
        Narrator.shared.say(l.text, pitch: l.voice.pitch, rate: l.voice.rate)
    }

    private func next() {
        Haptics.tap(.pop)
        if line + 1 < current.lines.count {
            withAnimation { line += 1 }
            speak()
        } else if panel + 1 < scene.panels.count {
            shown = false
            withAnimation { panel += 1; line = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { shown = true }
            speak()
        } else {
            Narrator.shared.stop()
            onDone()
        }
    }
}

/// The Story Book: every cutscene the child has seen, to watch again.
struct StoryBookView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: Cutscene?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF4E0), Color(hex: 0xE8DDFF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let playing {
                CutsceneView(scene: playing, character: store.character) { self.playing = nil }
                    .transition(.opacity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        HStack {
                            CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                            Spacer()
                        }
                        Text("📖").font(.system(size: 60)).accessibilityHidden(true)
                        Text("Story Book").font(.kid(34, .black)).foregroundStyle(Palette.purple)
                        Text("Watch your adventure again. New stories appear as you finish levels.")
                            .font(.kid(15, .bold)).foregroundStyle(Palette.ink.opacity(0.8))
                            .multilineTextAlignment(.center)
                        ForEach(Array(StoryBook.all.enumerated()), id: \.element.id) { i, c in
                            storyCard(c, number: i + 1)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: playing?.id)
        .onAppear { Narrator.shared.say("The Story Book! Pick a story to watch again.") }
    }

    private func storyCard(_ c: Cutscene, number: Int) -> some View {
        let seen = store.storyUnlocked(c.id)
        return Button {
            guard seen else {
                Haptics.bump(.oops)
                Narrator.shared.say("Keep playing to unlock this story!")
                return
            }
            Haptics.tap()
            playing = c
        } label: {
            HStack(spacing: 14) {
                Text(seen ? c.panels.first?.place.props.first ?? "📖" : "🔒").font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.white.opacity(0.3)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(number). \(seen ? c.title : "???")").font(.kid(20, .black)).lineLimit(1).minimumScaleFactor(0.7)
                    Text(seen ? "Watch again ▶" : "Not yet").font(.kid(14, .bold)).opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 22).fill(seen ? Palette.purple : Color(hex: 0x9AA6B8))
                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(seen ? "Story \(number): \(c.title). Watch again" : "Story \(number), not unlocked yet")
    }
}
