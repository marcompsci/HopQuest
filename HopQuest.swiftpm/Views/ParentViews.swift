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
                Label("No chat or strangers", systemImage: "person.2.slash")
                Label("Nothing leaves this device", systemImage: "iphone")
                Text("HopQuest saves only a first name, the choices above, and stars — on this device. No accounts, no tracking, no analytics.")
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
            LabeledContent("Story levels", value: "\(p?.completedChapters.count ?? 0) of \(Chapters.all.count)")
            LabeledContent("Coding (Code Club)", value: "\(p?.codeBest.count ?? 0) of \(CodeChallenge.all.count) puzzles")
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
         (Subject.words.rawValue, "textformat.abc")]
    }
}
