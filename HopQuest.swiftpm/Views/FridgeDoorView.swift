import SwiftUI

/// The Fridge Door (v9.6): every picture, Star Hop level, song and story the child made, hung up one at a time
/// to show a grown-up. Nothing here is shared, sent or printed; it only shows what is already saved on this device.
struct FridgeDoorView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var index = 0
    @State private var playTask: Task<Void, Never>?
    @State private var playingStep: Int?

    private let accent = Color(hex: 0x2F8F83)

    private var items: [FridgeItem] {
        guard let p = store.profile else { return [] }
        return FridgeDoor.items(pictures: p.scenes.scenes, levels: p.levelMaker.levels, songs: p.music.shelf, stories: p.storyMaker.stories)
    }

    var body: some View {
        let all = items
        ZStack {
            // the fridge: a soft enamel door with a handle down the side
            LinearGradient(colors: [Color(hex: 0xEAF7F4), Color(hex: 0xCFEDE7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            HStack {
                Spacer()
                Capsule().fill(Color(hex: 0xB7D9D2)).frame(width: 12, height: 180)
                    .padding(.trailing, 6)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                header(count: all.count)
                if all.isEmpty {
                    emptyDoor
                } else {
                    let i = min(index, all.count - 1)
                    TabView(selection: $index) {
                        ForEach(Array(all.enumerated()), id: \.element.id) { n, item in
                            card(item, number: n)
                                .padding(.horizontal, 22)
                                .tag(n)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: index) { _, _ in stopSong() }
                    pager(i, of: all.count)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .onAppear {
            Narrator.shared.say(all.isEmpty ? "Make a picture, a level, a song or a story, and it goes up here." : "Show a grown-up what you made!")
        }
        .onDisappear { stopSong(); Narrator.shared.stop() }
    }

    // MARK: Parts

    private func header(count: Int) -> some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "chevron.left", label: "Back", action: { stopSong(); onBack() })
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.tr("Fridge Door")).font(.kid(26, .black)).foregroundStyle(accent)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(L10n.tr("Show a grown-up what you made!")).font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                    .lineLimit(2).minimumScaleFactor(0.8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
        }
    }

    private var emptyDoor: some View {
        VStack(spacing: 16) {
            Spacer()
            HStack(spacing: 14) {
                magnet(0xFF6B6B); magnet(0xFFD93D); magnet(0x4D96FF); magnet(0x34C77B)
            }
            .accessibilityHidden(true)
            Text(L10n.tr("Make a picture, a level, a song or a story, and it goes up here."))
                .font(.kid(19, .bold)).foregroundStyle(Palette.ink.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    private func magnet(_ hex: UInt32) -> some View {
        Circle().fill(Color(hex: hex))
            .overlay(Circle().fill(.white.opacity(0.45)).frame(width: 8, height: 8).offset(x: -5, y: -5))
            .frame(width: 30, height: 30)
            .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 2)
    }

    /// One thing on the door: a paper card held up by a magnet, tilted a little like real fridge art.
    private func card(_ item: FridgeItem, number: Int) -> some View {
        let colors: [UInt32] = [0xFF6B6B, 0xFFD93D, 0x4D96FF, 0x34C77B, 0xB983FF]
        let tilt = [-2.0, 1.5, -1.0, 2.0][number % 4]
        let description = FridgeDoor.describe(item) { Roster.character(id: $0).name }
        return VStack(spacing: 10) {
            magnet(colors[number % colors.count]).accessibilityHidden(true)
            VStack(spacing: 10) {
                content(item)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(description)
                Text(L10n.tr(item.kind)).font(.kid(18, .black)).foregroundStyle(Palette.ink)
                    .accessibilityHidden(true)
                action(item)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4))
            .rotationEffect(.degrees(tilt))
            .padding(.top, -24)
            Spacer(minLength: 0)
        }
        .padding(.top, 6)
    }

    @ViewBuilder private func content(_ item: FridgeItem) -> some View {
        switch item {
        case .picture(let s):
            SceneCanvas(scene: s, selected: nil, interactive: false, onDrag: { _, _ in }, onDragEnd: { _ in }, onTap: { _ in })
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .level(let l):
            VStack(spacing: 6) {
                MiniBoard(level: l).aspectRatio(16 / 9, contentMode: .fit)
                Text(l.name).font(.kid(16, .black)).foregroundStyle(Palette.ink)
            }
        case .song(let s):
            songPicture(s)
        case .story(let s):
            VStack(alignment: .leading, spacing: 8) {
                Text(s.title).font(.kid(20, .black)).foregroundStyle(Palette.ink)
                ForEach(Array(s.pages.enumerated()), id: \.offset) { n, page in
                    HStack(alignment: .top, spacing: 8) {
                        Text(page.heroEmoji).font(.system(size: 26))
                        Text(StoryMakerBank.sentence(page, index: n)).font(.kid(15, .semibold)).foregroundStyle(Palette.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The song drawn as colored notes (high notes higher) with its drums underneath.
    private func songPicture(_ s: ShelfSong) -> some View {
        VStack(spacing: 6) {
            Text(L10n.tr(s.title)).font(.kid(20, .black)).foregroundStyle(Color(hex: MusicKeys.colors[s.color]))
            GeometryReader { g in
                let w = g.size.width / CGFloat(SongSteps.length)
                let h = g.size.height
                ZStack(alignment: .topLeading) {
                    ForEach(0..<4, id: \.self) { line in
                        Rectangle().fill(Palette.ink.opacity(0.12)).frame(height: 1.5)
                            .offset(y: h * CGFloat(line + 1) / 5.0)
                    }
                    ForEach(0..<SongSteps.length, id: \.self) { step in
                        if let k = s.song.steps[step] {
                            let y = h * (0.88 - 0.76 * CGFloat(k) / CGFloat(MusicKeys.count - 1))
                            Circle().fill(Color(hex: MusicKeys.colors[k]))
                                .frame(width: min(w * 0.7, 26), height: min(w * 0.7, 26))
                                .scaleEffect(playingStep == step ? 1.3 : 1)
                                .position(x: (CGFloat(step) + 0.5) * w, y: y)
                        }
                    }
                }
            }
            .frame(height: 120)
            HStack(spacing: 0) {
                ForEach(0..<SongSteps.length, id: \.self) { step in
                    Text(s.song.beats[step].map { MusicKeys.drumEmoji[$0] } ?? "·")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder private func action(_ item: FridgeItem) -> some View {
        switch item {
        case .song(let s):
            let playing = playTask != nil
            Button {
                Haptics.tap()
                if playing { stopSong() } else { play(s.song) }
            } label: {
                Label(L10n.tr(playing ? "■ Stop" : "▶ Play"), systemImage: playing ? "stop.fill" : "play.fill")
                    .labelStyle(.titleOnly)
                    .font(.kid(18, .black)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.green))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel(playing ? "Stop \(s.title)" : "Play \(s.title)")
        case .story(let s):
            Button {
                Haptics.tap()
                let lines = s.pages.enumerated().map { StoryMakerBank.sentence($0.element, index: $0.offset) }
                Narrator.shared.say(([s.title + "."] + lines).joined(separator: " "))
            } label: {
                Text("🔊 " + L10n.tr("Read it to me"))
                    .font(.kid(18, .black)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x6A4C93)))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Read \(s.title) to me")
        default:
            EmptyView()
        }
    }

    /// Back and next buttons (for anyone who can't swipe), and where you are.
    private func pager(_ i: Int, of count: Int) -> some View {
        HStack(spacing: 14) {
            CircleIconButton(systemName: "chevron.left.circle.fill", label: "Before") {
                guard i > 0 else { return }
                withAnimation(Motion.snappy) { index = i - 1 }
            }
            .opacity(i > 0 ? 1 : 0.35)
            Text("\(i + 1) / \(count)").font(.kid(18, .black)).foregroundStyle(Palette.ink).monospacedDigit()
                .frame(minWidth: 70)
                .accessibilityLabel("\(i + 1) of \(count)")
            CircleIconButton(systemName: "chevron.right.circle.fill", label: "Next") {
                guard i + 1 < count else { return }
                withAnimation(Motion.snappy) { index = i + 1 }
            }
            .opacity(i + 1 < count ? 1 : 0.35)
        }
    }

    // MARK: Playing a song

    private func play(_ song: SongSteps) {
        stopSong()
        let inst = song.instrument == .drums ? Instrument.xylophone : song.instrument
        let nanos = UInt64(song.stepSeconds * 1_000_000_000)
        playTask = Task { @MainActor in
            for _ in 0..<2 {
                for step in 0..<SongSteps.length {
                    guard !Task.isCancelled else { return }
                    playingStep = step
                    if let d = song.beats[step] { SoundFX.shared.playNote(.drums, key: d, volume: 0.8) }
                    if let k = song.steps[step] { SoundFX.shared.playNote(inst, key: k) }
                    try? await Task.sleep(nanoseconds: nanos)
                }
            }
            playingStep = nil
            playTask = nil
        }
    }

    private func stopSong() {
        playTask?.cancel()
        playTask = nil
        playingStep = nil
    }
}
