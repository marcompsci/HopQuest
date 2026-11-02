import SwiftUI

/// Music Maker: rainbow keys and drum pads, three music games, and a song builder that remembers your song.
struct MusicMakerView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    enum Mode: String, CaseIterable, Identifiable {
        case play, echo, rhythm, tune, build
        var id: String { rawValue }
        var title: String {
            switch self {
            case .play: return "Play"
            case .echo: return "Echo Me"
            case .rhythm: return "Drum Copy"
            case .tune: return "Songs"
            case .build: return "Build"
            }
        }
        var icon: String {
            switch self {
            case .play: return "pianokeys"
            case .echo: return "ear.fill"
            case .rhythm: return "metronome.fill"
            case .tune: return "music.note.list"
            case .build: return "square.grid.3x3.fill"
            }
        }
    }

    @State private var mode: Mode = .play
    private let accent = Color(hex: 0xB0459C)
    @State private var instrument: Instrument = .xylophone
    /// The key that's glowing right now (being played or to play next).
    @State private var lit: Int?
    @State private var playTask: Task<Void, Never>?

    // games
    @State private var patterns: [[Int]] = []
    @State private var round = 0
    @State private var check = PatternCheck([])
    @State private var listening = false
    @State private var firstTry = 0
    @State private var roundMissed = false
    @State private var tune: Tune?
    @State private var result: (stars: Int, earned: Int, firstTry: Int, total: Int)?
    @State private var stepPlaying: Int?
    /// Which song is playing: "builder" for the one being built, or a shelf song's id (v9.4).
    @State private var playingSongID: String?
    @State private var songToDelete: ShelfSong?

    private var gameInstrument: Instrument { mode == .rhythm ? .drums : (instrument == .drums ? .xylophone : instrument) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF0F7), Color(hex: 0xE8E4FF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                header
                modePicker
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        switch mode {
                        case .play: playArea
                        case .echo, .rhythm: patternGame
                        case .tune: tuneArea
                        case .build: builder
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if let result {
                Color.black.opacity(0.25).ignoresSafeArea()
                LearnDoneCard(title: mode == .tune ? (tune?.title ?? "Song") : mode.title, stars: result.stars, earned: result.earned,
                              firstTry: result.firstTry, total: result.total, host: PlaceHost.music,
                              onAgain: { self.result = nil; startMode() },
                              onBack: { self.result = nil; mode = .play })
            }
        }
        .animation(Motion.snappy, value: mode)
        .onChange(of: mode) { _, _ in startMode() }
        .onAppear {
            instrument = store.profile?.music.song.instrument ?? .xylophone
            Narrator.shared.say("Music Maker! Tap the rainbow keys to play. Try Echo Me, Drum Copy, Songs, or build your own song!")
        }
        .onDisappear { stopAll(); Narrator.shared.stop() }
    }

    // MARK: Header and pickers

    private var header: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "chevron.left", label: "Back", action: { stopAll(); onBack() })
            CharacterBadge(character: PlaceHost.music, size: 48).accessibilityHidden(true)
            Text("Music Maker").font(.kid(24, .black)).displayTracking(24).foregroundStyle(accent)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(Color(hex: 0xFFC21A))
                Text("\(store.profile?.music.totalStars ?? 0) of \(MusicSave.maxStars)").monospacedDigit()
            }
            .font(.kid(15, .heavy)).foregroundStyle(Palette.ink)
            .padding(.horizontal, 10).frame(minHeight: 44)
            .background(Capsule().fill(.regularMaterial))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(store.profile?.music.totalStars ?? 0) of \(MusicSave.maxStars) stars")
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Mode.allCases) { m in
                    Button {
                        Haptics.tap(.pop)
                        mode = m
                    } label: {
                        Label(m.title, systemImage: m.icon).font(.kid(15, .heavy))
                            .foregroundStyle(mode == m ? .white : Palette.ink)
                            .padding(.horizontal, 14).frame(minHeight: 44)
                            .background(Capsule().fill(mode == m ? accent : .white.opacity(0.9)))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel(m.title + (mode == m ? ", chosen" : ""))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var instrumentPicker: some View {
        HStack(spacing: 8) {
            ForEach(Instrument.allCases) { i in
                Button {
                    Haptics.tap(.pop)
                    instrument = i
                    SoundFX.shared.playNote(i, key: i == .drums ? 0 : 4)
                } label: {
                    VStack(spacing: 2) {
                        Text(i.emoji).font(.system(size: 26))
                        Text(i.title).font(.kid(11, .black)).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(RoundedRectangle(cornerRadius: 14).fill(instrument == i ? Color(hex: 0xDDF7E5) : .white.opacity(0.85)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(instrument == i ? Palette.green : .clear, lineWidth: 3))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(i.title + (instrument == i ? ", chosen" : ""))
            }
        }
    }

    // MARK: Keys and pads

    private func keyboard(_ inst: Instrument, onTap: @escaping (Int) -> Void) -> some View {
        Group {
            if inst == .drums {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(0..<MusicKeys.drumNames.count, id: \.self) { k in
                        Button { hit(inst, k, onTap) } label: {
                            VStack(spacing: 4) {
                                Text(MusicKeys.drumEmoji[k]).font(.system(size: 40))
                                Text(MusicKeys.drumNames[k]).font(.kid(18, .black)).foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: MusicKeys.colors[k * 2]))
                                .brightness(lit == k ? 0.2 : 0)
                                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: lit == k ? 1 : 5))
                            .scaleEffect(lit == k ? 0.95 : 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Drum: \(MusicKeys.drumNames[k])")
                    }
                }
            } else {
                HStack(spacing: 5) {
                    ForEach(0..<MusicKeys.count, id: \.self) { k in
                        Button { hit(inst, k, onTap) } label: {
                            VStack(spacing: 2) {
                                Spacer()
                                Text(MusicKeys.names[k]).font(.kid(18, .black))
                                Text(MusicKeys.solfege[k]).font(.kid(11, .bold)).opacity(0.85)
                            }
                            .foregroundStyle(.white)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, minHeight: 190)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: MusicKeys.colors[k]))
                                .brightness(lit == k ? 0.25 : 0)
                                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: lit == k ? 1 : 5))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white, lineWidth: lit == k ? 4 : 0))
                            .offset(y: lit == k ? 3 : 0)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(MusicKeys.names[k]), \(MusicKeys.solfege[k])")
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.12), value: lit)
    }

    private func hit(_ inst: Instrument, _ k: Int, _ onTap: (Int) -> Void) {
        SoundFX.shared.playNote(inst, key: k)
        flash(k)
        onTap(k)
    }

    private func flash(_ k: Int) {
        lit = k
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { if lit == k && !listening && tune == nil { lit = nil } }
    }

    // MARK: Free play

    private var playArea: some View {
        VStack(spacing: 14) {
            instrumentPicker
            keyboard(instrument) { _ in }
            Text(instrument == .drums ? "Make a beat! Boom, tap, tss, clap." : "Low notes on the left, high notes on the right. Can you play do, re, mi?")
                .font(.kid(15, .bold)).foregroundStyle(Palette.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            if !SoundFX.shared.sfxOn {
                Label("Sounds are off in Grown-up settings.", systemImage: "speaker.slash.fill").font(.kid(14, .black)).foregroundStyle(Palette.red)
            }
        }
    }

    // MARK: Echo Me and Drum Copy

    private var patternGame: some View {
        let game: MusicGame = mode == .echo ? .echo : .rhythm
        return VStack(spacing: 14) {
            RoundDots(done: round, total: max(patterns.count, 1))
            Text(listening ? "👂 Listen…" : (patterns.isEmpty ? "" : "Your turn! \(check.position) of \(check.pattern.count)"))
                .font(.kid(22, .black)).foregroundStyle(Palette.ink)
            keyboard(gameInstrument) { k in tapPattern(k, game: game) }
                .disabled(listening)
                .opacity(listening ? 0.8 : 1)
            BigButton(title: "🔁 Hear it again", color: Color(hex: 0x4D96FF)) { playPattern() }
                .disabled(listening)
            Text("Best: \(String(repeating: "⭐", count: store.profile?.music.best(game) ?? 0))")
                .font(.kid(14, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
        }
    }

    private func tapPattern(_ k: Int, game: MusicGame) {
        guard !listening, !check.isDone, result == nil else { return }
        switch check.tap(k) {
        case .good:
            break
        case .wrong:
            roundMissed = true
            Haptics.bump(.oops)
            Narrator.shared.say("Oops! Try that note again.")
        case .done:
            Haptics.success(.correct)
            if !roundMissed { firstTry += 1 }
            playTask?.cancel()
            playTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard !Task.isCancelled else { return }
                if round + 1 < patterns.count {
                    round += 1
                    Narrator.shared.say(["Yes!", "Great listening!", "You got it!"].randomElement()!)
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    guard !Task.isCancelled else { return }
                    beginRound()
                } else {
                    round = patterns.count
                    let stars = LearnScore.stars(firstTry: firstTry, of: patterns.count)
                    let earned = store.recordMusic(game, stars: stars)
                    Haptics.success(.fanfare)
                    withAnimation(Motion.present) { result = (stars, earned, firstTry, patterns.count) }
                    Narrator.shared.say(earned > 0 ? "Amazing ears! \(earned) new stars!" : "Amazing ears!")
                }
            }
        }
    }

    private func beginRound() {
        check = PatternCheck(patterns[round])
        roundMissed = false
        playPattern()
    }

    /// Plays the current pattern with glowing keys, then it's the child's turn.
    private func playPattern() {
        guard patterns.indices.contains(round) else { return }
        playTask?.cancel()
        let p = patterns[round], inst = gameInstrument
        listening = true
        playTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            for k in p {
                guard !Task.isCancelled else { return }
                SoundFX.shared.playNote(inst, key: k)
                lit = k
                try? await Task.sleep(nanoseconds: 380_000_000)
                lit = nil
                try? await Task.sleep(nanoseconds: 170_000_000)
            }
            guard !Task.isCancelled else { return }
            listening = false
        }
    }

    // MARK: Songs

    private var tuneArea: some View {
        VStack(spacing: 14) {
            if let tune {
                Label(tune.title, systemImage: "music.note").font(.kid(22, .black)).foregroundStyle(Palette.ink)
                ProgressView(value: Double(check.position), total: Double(max(check.pattern.count, 1)))
                    .tint(Palette.green)
                instrumentPicker
                keyboard(instrument == .drums ? .xylophone : instrument) { k in tapTune(k) }
                Text("Tap the glowing key!").font(.kid(15, .bold)).foregroundStyle(Palette.ink.opacity(0.75))
            } else {
                Text("Pick a song to learn").font(.kid(20, .black)).foregroundStyle(Palette.ink)
                ForEach(MusicBank.tunes) { t in
                    let learned = store.profile?.music.tunesLearned.contains(t.id) == true
                    Button {
                        Haptics.tap()
                        tune = t
                        check = PatternCheck(t.keys)
                        lit = check.next
                        Narrator.shared.say("\(t.title)! Tap the glowing key.")
                    } label: {
                        HStack {
                            Text(learned ? "✅" : "🎵").font(.system(size: 28))
                            Text(t.title).font(.kid(19, .black)).foregroundStyle(Palette.ink)
                            Spacer()
                            Text("\(t.keys.count) notes").font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.6))
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.9)))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("\(t.title)\(learned ? ", learned" : "")")
                }
            }
        }
    }

    private func tapTune(_ k: Int) {
        guard let t = tune, result == nil else { return }
        switch check.tap(k) {
        case .good:
            lit = check.next
        case .wrong:
            Haptics.bump(nil)
            lit = check.next
        case .done:
            lit = nil
            let stars = check.mistakes == 0 ? 3 : check.mistakes <= 3 ? 2 : 1
            let earned = store.recordMusic(.learnTune, stars: stars, tune: t.id)
            Haptics.success(.fanfare)
            withAnimation(Motion.present) { result = (stars, earned, max(0, t.keys.count - check.mistakes), t.keys.count) }
            Narrator.shared.say("You played \(t.title)! Bravo!")
            tune = nil
        }
    }

    // MARK: Song builder

    private var builder: some View {
        let music = store.profile?.music ?? MusicSave()
        let song = music.song
        let playingHere = playingSongID == "builder"
        return VStack(spacing: 12) {
            instrumentPicker
            Text("Tap a box to put a note in each step. Tap the drum boxes for a beat. Then press Play.")
                .font(.kid(14, .bold)).foregroundStyle(Palette.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            // rows: high notes on top
            VStack(spacing: 4) {
                ForEach((0..<MusicKeys.count).reversed(), id: \.self) { k in
                    HStack(spacing: 4) {
                        Text(MusicKeys.names[k]).font(.kid(12, .black)).foregroundStyle(Palette.ink).frame(width: 22)
                        ForEach(0..<SongSteps.length, id: \.self) { s in
                            let on = song.steps[s] == k
                            Button {
                                var next = song
                                next.toggle(step: s, key: k)
                                next.instrument = instrument
                                store.updateMusic { $0.song = next }
                                if !on { SoundFX.shared.playNote(instrument == .drums ? .xylophone : instrument, key: k) }
                            } label: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(on ? Color(hex: MusicKeys.colors[k]) : Color.white.opacity(playingHere && stepPlaying == s ? 0.95 : 0.6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(playingHere && stepPlaying == s ? Palette.purple : .clear, lineWidth: 2))
                                    .frame(minWidth: 28, maxWidth: .infinity, minHeight: 30)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Step \(s + 1), note \(MusicKeys.names[k])\(on ? ", on" : "")")
                        }
                    }
                }
                // the beat row (v9.4): tap to go Boom, Tap, Tss, Clap, then quiet again
                HStack(spacing: 4) {
                    Text("🥁").font(.system(size: 14)).frame(width: 22).accessibilityHidden(true)
                    ForEach(0..<SongSteps.length, id: \.self) { s in
                        let d = song.beats[s]
                        let boxColor: Color = d.map { Color(hex: MusicKeys.colors[$0 * 2]) } ?? Color.white.opacity(playingHere && stepPlaying == s ? 0.95 : 0.6)
                        Button {
                            var next = song
                            next.cycleBeat(step: s)
                            next.instrument = instrument
                            store.updateMusic { $0.song = next }
                            if let nd = next.beats[s] { SoundFX.shared.playNote(.drums, key: nd) }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(boxColor)
                                if let d { Text(MusicKeys.drumEmoji[d]).font(.system(size: 15)) }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(playingHere && stepPlaying == s ? Palette.purple : .clear, lineWidth: 2))
                            .frame(minWidth: 28, maxWidth: .infinity, minHeight: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Step \(s + 1), drum: \(d.map { MusicKeys.drumNames[$0] } ?? "none")")
                        .accessibilityHint("Tap to change the drum")
                    }
                }
                .padding(.top, 4)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.5)))
            tempoPicker(song)
            HStack(spacing: 10) {
                BigButton(title: "Clear", color: Color(hex: 0x9AA6B8)) {
                    stopAll()
                    store.updateMusic { $0.song = SongSteps() }
                }
                BigButton(title: playingHere ? "■ Stop" : "▶ Play", color: Palette.green) {
                    if playingHere { stopAll() } else {
                        var now = song
                        now.instrument = instrument
                        playSong(now, id: "builder")
                    }
                }
            }
            BigButton(title: music.openSongID == nil ? "Keep on my shelf" : "Keep changes", color: accent) { keepSong() }
            shelf(music)
        }
    }

    private func tempoPicker(_ song: SongSteps) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<SongSteps.tempos.count, id: \.self) { t in
                Button {
                    Haptics.tap(.pop)
                    store.updateMusic { $0.song.tempo = t }
                } label: {
                    HStack(spacing: 4) {
                        Text(SongSteps.tempoEmoji[t]).font(.system(size: 20))
                        Text(L10n.tr(SongSteps.tempoNames[t])).font(.kid(14, .black)).foregroundStyle(Palette.ink)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(song.tempo == t ? Color(hex: 0xDDF7E5) : .white.opacity(0.85)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(song.tempo == t ? Palette.green : .clear, lineWidth: 3))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Speed: \(L10n.tr(SongSteps.tempoNames[t]))\(song.tempo == t ? ", chosen" : "")")
            }
        }
    }

    // MARK: Song shelf (v9.4)

    private func shelf(_ music: MusicSave) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(L10n.tr("My songs")) (\(music.shelf.count)/\(MusicSave.shelfSize))").font(.kid(20, .black)).foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    Haptics.tap()
                    stopAll()
                    store.updateMusic { $0.newSong() }
                    Narrator.shared.say("A new song! Tap the boxes to make it.")
                } label: {
                    Label(L10n.tr("New song"), systemImage: "plus").font(.kid(14, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(BouncyButtonStyle())
            }
            if music.shelf.isEmpty {
                Text("Keep a song and it shows up here. You can keep six.")
                    .font(.kid(14, .semibold)).foregroundStyle(Palette.ink.opacity(0.6))
            }
            ForEach(music.shelf) { item in
                let open = music.openSongID == item.id
                let playing = playingSongID == item.id
                HStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .font(.system(size: 22, weight: .black)).foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color(hex: MusicKeys.colors[item.color])))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr(item.title)).font(.kid(17, .black)).foregroundStyle(Palette.ink)
                        Text(open ? L10n.tr("Open now") : "\(item.song.noteCount) ♪ · \(item.song.beatCount) 🥁 · \(SongSteps.tempoEmoji[item.song.tempo])")
                            .font(.kid(12, .bold)).foregroundStyle(Palette.ink.opacity(0.65))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.title), \(item.song.noteCount) notes, \(item.song.beatCount) drums\(open ? ", open now" : "")")
                    Spacer(minLength: 4)
                    shelfButton(playing ? "stop.fill" : "play.fill", playing ? "Stop \(item.title)" : "Play \(item.title)") {
                        if playing { stopAll() } else { playSong(item.song, id: item.id) }
                    }
                    shelfButton("pencil", "Change \(item.title)") {
                        stopAll()
                        store.updateMusic { $0.openSong(item.id) }
                        instrument = item.song.instrument
                        Narrator.shared.say("\(item.title) is open. Change it, then keep the changes.")
                    }
                    shelfButton("trash", "Delete \(item.title)") { songToDelete = item }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(open ? 1 : 0.85)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(open ? accent : .clear, lineWidth: 3))
            }
        }
        .padding(.top, 6)
        .confirmationDialog("Delete this song?", isPresented: Binding(get: { songToDelete != nil }, set: { if !$0 { songToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let s = songToDelete {
                    if playingSongID == s.id { stopAll() }
                    store.updateMusic { $0.deleteSong(s.id) }
                }
                songToDelete = nil
            }
        }
    }

    private func shelfButton(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(hex: 0xF2EAF7)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }

    private func keepSong() {
        var result = MusicSave.KeepResult.empty
        store.updateMusic { m in
            m.song.instrument = instrument
            result = m.keepSong()
        }
        switch result {
        case .kept(let n):
            Haptics.success()
            Narrator.shared.say("Song \(n) is on your shelf!")
        case .updated(let n):
            Haptics.success()
            Narrator.shared.say("Song \(n) is saved!")
        case .empty:
            Narrator.shared.say("Tap some boxes to add notes first!")
        case .full:
            Narrator.shared.say("Your shelf is full. Delete a song first, or change one of them.")
        }
    }

    /// Plays a song twice through, notes and drums together, at the song's speed.
    private func playSong(_ song: SongSteps, id: String) {
        guard !song.isEmpty else { Narrator.shared.say("Tap some boxes to add notes first!"); return }
        stopAll()
        let inst = song.instrument == .drums ? Instrument.xylophone : song.instrument
        let nanos = UInt64(song.stepSeconds * 1_000_000_000)
        playingSongID = id
        playTask = Task { @MainActor in
            for _ in 0..<2 {
                for s in 0..<SongSteps.length {
                    guard !Task.isCancelled else { return }
                    stepPlaying = s
                    if let d = song.beats[s] { SoundFX.shared.playNote(.drums, key: d, volume: 0.8) }
                    if let k = song.steps[s] { SoundFX.shared.playNote(inst, key: k) }
                    try? await Task.sleep(nanoseconds: nanos)
                }
            }
            stepPlaying = nil
            playingSongID = nil
        }
    }

    // MARK: Flow

    private func startMode() {
        stopAll()
        result = nil
        tune = nil
        lit = nil
        switch mode {
        case .echo, .rhythm:
            patterns = mode == .echo ? MusicBank.echoPatterns() : MusicBank.rhythmPatterns()
            round = 0
            firstTry = 0
            Narrator.shared.say(mode == .echo ? MusicGame.echo.intro : MusicGame.rhythm.intro)
            playTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                guard !Task.isCancelled else { return }
                beginRound()
            }
        default:
            patterns = []
        }
    }

    private func stopAll() {
        playTask?.cancel()
        playTask = nil
        listening = false
        stepPlaying = nil
        playingSongID = nil
    }
}
