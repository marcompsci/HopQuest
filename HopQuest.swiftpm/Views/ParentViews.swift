import SwiftUI

/// Grown-ups only. Uses a typed multiplication answer (not tap-to-pick), which young kids
/// can't easily guess — the kind of parental gate Apple expects in Kids Category apps.
struct ParentGateView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var a = Int.random(in: 6...12)
    @State private var b = Int.random(in: 6...12)
    @State private var answer = ""
    @State private var unlocked = false
    @State private var wrong = false

    var body: some View {
        NavigationStack {
            Group {
                if unlocked {
                    ParentSettingsView()
                } else {
                    gate
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var gate: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("👨‍👩‍👧 Grown-ups only").font(.kid(28, .black))
            Text("To open settings, type the answer:")
                .font(.kid(17, .medium))
                .foregroundStyle(.secondary)
            Text("\(a) × \(b) = ?").font(.kid(40, .black)).foregroundStyle(Palette.purple)
            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .font(.kid(28, .bold))
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal, 60)
            if wrong {
                Text("Not quite — new question below.").foregroundStyle(Palette.red).font(.kid(15, .semibold))
            }
            BigButton(title: "Unlock") { check() }
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
    }

    private func check() {
        if Int(answer) == a * b {
            unlocked = true
        } else {
            wrong = true
            answer = ""
            a = Int.random(in: 6...12)
            b = Int.random(in: 6...12)
        }
    }
}

struct ParentSettingsView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var soundTick = false
    @State private var confirmStartOver = false

    var body: some View {
        Form {
            Section("Player") {
                TextField("Name", text: binding(\.name, ""))
                Picker("Kid picked", selection: binding(\.identity, .noAnswer)) {
                    ForEach(KidIdentity.allCases) { Text($0.label).tag($0) }
                }
                Picker("Castle style", selection: binding(\.theme, .rainbow)) {
                    ForEach(CastleTheme.allCases) { Text($0.title).tag($0) }
                }
                Text("Every castle and character is open to every child. \"Kid picked\" only changes which ones show up first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Reading help") {
                Toggle("Read everything out loud", isOn: binding(\.narration, true))
                Text("Reads questions, tips, and lessons aloud for kids who are still learning to read. Uses the built-in iPhone voice; no recordings are made.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Sound") {
                Toggle("Music", isOn: Binding(
                    get: { SoundFX.shared.musicOn },
                    set: { UserDefaults.standard.set($0, forKey: SoundFX.musicKey); SoundFX.shared.applySettings(); soundTick.toggle() }))
                Toggle("Sound effects", isOn: Binding(
                    get: { SoundFX.shared.sfxOn },
                    set: { UserDefaults.standard.set($0, forKey: SoundFX.sfxKey); SoundFX.shared.applySettings(); soundTick.toggle() }))

            }

            Section {
                Picker("Question level", selection: binding(\.learnerTier, .auto)) {
                    ForEach(LearnerTier.allCases) { Text($0.label).tag($0) }
                }
                LabeledContent("Right now", value: store.tierNote)
            } header: {
                Text("Learning level")
            } footer: {
                Text("Brain Gate questions match your child's level: picture counting for little learners, times tables and harder words for big learners. Automatic starts in the middle, then steps up after lots of first-try answers or eases down if questions feel too hard.")
            }

            Section {
                Picker("Daily play limit", selection: binding(\.dailyLimitMinutes, 0)) {
                    Text("No limit").tag(0)
                    Text("20 minutes").tag(20)
                    Text("30 minutes").tag(30)
                    Text("45 minutes").tag(45)
                    Text("1 hour").tag(60)
                    Text("1½ hours").tag(90)
                }
                if (store.profile?.dailyLimitMinutes ?? 0) > 0 {
                    LabeledContent("Played today", value: "\((store.profile?.playedSeconds ?? 0) / 60) min")
                }
            } header: {
                Text("Daily play")
            } footer: {
                Text("When time is up, your child's buddy says a gentle goodbye and the game rests until tomorrow. HopQuest has no streaks, no daily-login rewards, and never sends notifications, so it won't nag kids to come back.")
            }

            Section {
                Picker("Play with others", selection: Binding(
                    get: { store.profile?.village.playMode ?? .off },
                    set: { mode in store.updateVillage { $0.playMode = mode } })) {
                    ForEach(VillagePlayMode.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                Toggle("Lighter effects (older phones)", isOn: villageBinding(\.lightEffects))
                Toggle("Evening lights follow the clock", isOn: villageBinding(\.eveningLights))
                Toggle("Seasons and weather follow the calendar", isOn: villageBinding(\.seasons))
            } header: {
                Text("Hop Village")
            } footer: {
                Text("Play with others lets kids see friends' buddies in the village and play Brain Duels: five quiz questions, no chat, no free text. Nearby only uses Wi-Fi or Bluetooth in the same room (no internet) and shows your child's first name to those nearby. Game Center modes go online through Apple's Game Center and only show buddy names; Game Center follows Screen Time's multiplayer limits. Village buddies only say pre-written, kid-safe lines. Lighter effects shows fewer butterflies, leaves, raindrops and snowflakes. With seasons off, the village is always a sunny spring day. Seasons and weather come from the device date: nothing is downloaded.")
            }

            Section("Play time") {
                Picker("Stretch-break reminder", selection: binding(\.breakReminderMinutes, 30)) {
                    Text("Off").tag(0)
                    Text("Every 15 min").tag(15)
                    Text("Every 20 min").tag(20)
                    Text("Every 30 min").tag(30)
                    Text("Every 45 min").tag(45)
                }
                Text("For hard daily limits, use Screen Time in iPhone Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Progress") {
                LabeledContent("Stars earned", value: "\(store.profile?.stars ?? 0)")
                LabeledContent("Levels finished", value: "\(store.profile?.completedChapters.count ?? 0) of \(Chapters.all.count)")
                Button("Reset level progress", role: .destructive) { confirmReset = true }
                Button("Start over with a new player", role: .destructive) { confirmStartOver = true }
            }

            LearningReportSection()

            Section("Privacy & safety") {
                Label("No ads", systemImage: "nosign")
                Label("No in-app purchases", systemImage: "cart.badge.minus")
                Label("No chat or free text, ever", systemImage: "hand.raised.fill")
                switch store.profile?.village.playMode ?? .off {
                case .off:
                    Label("Nothing leaves this device", systemImage: "iphone")
                case .nearby:
                    Label("Live play: same room only, no internet", systemImage: "wifi")
                case .friends:
                    Label("Live play: Game Center friends", systemImage: "person.2")
                case .anyone:
                    Label("Live play: anyone on Game Center", systemImage: "globe")
                }
                Text("HopQuest saves only a first name, the choices above, and stars, on this device. No accounts of its own, no tracking, no analytics. During live play, phones share only buddy positions, buddy choices, a short nickname and duel answers.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Grown-up settings")
        .confirmationDialog("Reset all level progress and stars?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive) { store.resetProgress() }
        }
        .confirmationDialog("Erase this player and start onboarding again?", isPresented: $confirmStartOver, titleVisibility: .visible) {
            Button("Start over", role: .destructive) {
                dismiss()
                store.startOver()
            }
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<PlayerProfile, T>, _ fallback: T) -> Binding<T> {
        Binding(
            get: { store.profile?[keyPath: keyPath] ?? fallback },
            set: { store.profile?[keyPath: keyPath] = $0 }
        )
    }

    private func villageBinding(_ keyPath: WritableKeyPath<VillageSaveState, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.profile?.village[keyPath: keyPath] ?? false },
            set: { value in store.updateVillage { $0[keyPath: keyPath] = value } }
        )
    }
}

/// What the child has practiced, for grown-ups. Everything is counted on this device only.
struct LearningReportSection: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let p = store.profile
        Section {
            ForEach(Array(subjects.enumerated()), id: \.offset) { _, s in
                let answered = p?.brainAnswered[s.name] ?? 0
                let first = p?.brainFirstTry[s.name] ?? 0
                HStack {
                    Label(s.name, systemImage: s.icon)
                    Spacer()
                    if answered == 0 {
                        Text("Not yet").foregroundStyle(.secondary)
                    } else {
                        Text("\(answered) solved · \(Int((Double(first) / Double(answered) * 100).rounded()))% first try")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            LabeledContent("Question level", value: store.tierNote)
            LabeledContent("Story levels", value: "\(Chapters.all.filter { p?.completedChapters.contains($0.id) == true }.count) of \(Chapters.all.count)")
            ForEach(Worlds.all) { w in
                LabeledContent("\(w.title) levels", value: "\(w.chapters.filter { p?.completedChapters.contains($0.id) == true }.count) of \(w.chapters.count)")
            }
            LabeledContent("Coding (Code Club)", value: "\(CodeChallenge.all.filter { p?.codeBest[$0.id] != nil }.count) of \(CodeChallenge.all.count) puzzles")
            LabeledContent("Machine Workshop", value: "\(MachinePuzzle.all.filter { p?.codeBest[$0.id] != nil }.count) of \(MachinePuzzle.all.count) machines")
            LabeledContent("Coding Lab lessons", value: "\(p?.codeLab.completed.count ?? 0) of \(CodeCurriculum.lessons.count)")
            LabeledContent("Village missions", value: "\(MissionCatalog.base.filter { p?.missions.done.contains($0.id) == true }.count) of \(MissionCatalog.base.count)")
            LabeledContent("Festivals celebrated", value: "\(FestivalMissions.all.filter { p?.missions.done.contains($0.id) == true }.count) of \(FestivalMissions.all.count)")
            LabeledContent("Engineering (Fort Friends)", value: "\(p?.fortBest.count ?? 0) of \(FortLevel.all.count) forts")
            LabeledContent("Bubble Kart cups", value: "\(p?.kartBest.count ?? 0) of \(Chapters.kartCups.count)")
            LabeledContent("Pillow Bop best", value: "\(p?.bopBest ?? 0) bops")
            LabeledContent("Buddy stickers", value: "\(store.ownedStickers.count) of \(Roster.all.count)")
            LabeledContent("Stars ever earned", value: "\(p?.lifetimeStars ?? 0)")
        } header: {
            Text("Learning report")
        } footer: {
            Text("Brain Gate questions never count against a child: a wrong pick just gets a hint and another try. \"First try\" shows how often they knew it right away. Counts start from this version of the app.")
        }
    }

    private var subjects: [(name: String, icon: String)] {
        [(Subject.math.rawValue, "plus.forwardslash.minus"),
         (Subject.road.rawValue, "car.fill"),
         (Subject.nature.rawValue, "leaf.fill"),
         (Subject.science.rawValue, "atom"),
         (Subject.words.rawValue, "textformat.abc"),
         (Subject.coding.rawValue, "chevron.left.forwardslash.chevron.right"),
         (Subject.kindness.rawValue, "heart.fill")]
    }
}

/// The gentle end of today's play time. A grown-up can add 15 minutes after the parental gate.
struct RestTimeView: View {
    @EnvironmentObject var store: GameStore
    var onMore: () -> Void

    @State private var showGate = false
    @State private var a = Int.random(in: 6...12)
    @State private var b = Int.random(in: 6...12)
    @State private var answer = ""
    @State private var sway = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2E3A8C), Color(hex: 0x6C5BD9), Color(hex: 0xFF9ECF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ForEach(0..<18, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(8 + (i * 5) % 12)))
                    .foregroundStyle(.white.opacity(0.75))
                    .position(x: CGFloat((i * 61) % 380) + 10, y: CGFloat((i * 97) % 420) + 40)
            }
            VStack(spacing: 18) {
                Spacer()
                Text("🌙").font(.system(size: 70))
                CharacterBadge(character: store.character, size: 150)
                    .rotationEffect(.degrees(sway ? 3 : -3), anchor: .bottom)
                Text("Time to rest, \(store.profile?.name ?? "friend")!")
                    .font(.kid(32, .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("You played so well today. \(store.character.name) is getting sleepy too. Your castle and stars will be right here tomorrow!")
                    .font(.kid(18, .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Spacer()
                if showGate {
                    gate
                } else {
                    Button("Grown-ups") { showGate = true }
                        .font(.kid(16, .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            Narrator.shared.say("Time to rest! You played so well today. See you tomorrow!")
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { sway = true }
        }
    }

    private var gate: some View {
        VStack(spacing: 10) {
            Text("Grown-ups: \(a) × \(b) = ?").font(.kid(20, .black)).foregroundStyle(Palette.ink)
            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .font(.kid(24, .bold))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0xF3ECFF)))
            BigButton(title: "Add 15 minutes", color: Palette.green) {
                if Int(answer) == a * b {
                    store.grantExtraTime(minutes: 15)
                    onMore()
                } else {
                    answer = ""
                    a = Int.random(in: 6...12)
                    b = Int.random(in: 6...12)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 26).fill(.white))
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}
