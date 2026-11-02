import SwiftUI
import MessageUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// Grown-ups only (behind the parental gate): what the child has practised, where they could use a hand,
// and milestone notes a grown-up can text to themselves or a family member.

extension String {
    var firstCapitalized: String { isEmpty ? self : prefix(1).uppercased() + String(dropFirst()) }
}

extension MusicGame {
    var skill: String {
        switch self {
        case .echo: return "listening and remembering notes"
        case .rhythm: return "copying a rhythm"
        case .learnTune: return "playing a simple song"
        }
    }
}

extension GameStore {
    /// Every learning place, game by game.
    var learningAreas: [LearningArea] {
        guard let p = profile else { return [] }
        return [
            LearningArea(id: "reading", title: "Reading Nook", skills: ReadingGame.allCases.map { SkillProgress(skill: $0.skill, best: p.reading.best($0)) }),
            LearningArea(id: "writing", title: "Writing Desk", skills: WritingGame.allCases.map { SkillProgress(skill: $0.skill, best: p.writing.best($0)) }),
            LearningArea(id: "market", title: "Math Market", skills: MarketGame.allCases.map { SkillProgress(skill: $0.skill, best: p.market.best($0)) }),
            LearningArea(id: "clock", title: "Clock Tower", skills: ClockGame.allCases.map { SkillProgress(skill: $0.skill, best: p.clock.best($0)) }),
            LearningArea(id: "science", title: "Science Lab", skills: Experiment.allCases.map { SkillProgress(skill: $0.skill, best: p.science.best($0)) }),
            LearningArea(id: "world", title: "Around the World", skills: WorldGame.allCases.map { SkillProgress(skill: $0.skill, best: p.world.best($0)) }),
            LearningArea(id: "music", title: "Music Maker", skills: MusicGame.allCases.map { SkillProgress(skill: $0.skill, best: p.music.best($0)) }),
            LearningArea(id: "spelling", title: "Spelling Bee", skills: SpellingBank.games.map { SkillProgress(skill: $0.skill, best: p.places["spelling"]?.best($0.id) ?? 0) }),
            LearningArea(id: "fractions", title: "Fraction Bakery", skills: FractionBank.games.map { SkillProgress(skill: $0.skill, best: p.places["fractions"]?.best($0.id) ?? 0) }),
            LearningArea(id: "shapes", title: "Shape Studio", skills: ShapeBank.games.map { SkillProgress(skill: $0.skill, best: p.places["shapes"]?.best($0.id) ?? 0) }),
            LearningArea(id: "rhyme", title: "Rhyme Pond", skills: RhymeBank.games.map { SkillProgress(skill: $0.skill, best: p.places["rhyme"]?.best($0.id) ?? 0) }),
            LearningArea(id: "numbers", title: "Number Builder", skills: NumberBank.games.map { SkillProgress(skill: $0.skill, best: p.places["numbers"]?.best($0.id) ?? 0) }),
            LearningArea(id: "times", title: "Times Treehouse", skills: TimesBank.games.map { SkillProgress(skill: $0.skill, best: p.places["times"]?.best($0.id) ?? 0) }),
            LearningArea(id: "measure", title: "Measure Meadow", skills: MeasureBank.games.map { SkillProgress(skill: $0.skill, best: p.places["measure"]?.best($0.id) ?? 0) }),
            LearningArea(id: "feelings", title: "Feelings Corner", skills: FeelingsBank.games.map { SkillProgress(skill: $0.skill, best: p.places["feelings"]?.best($0.id) ?? 0) }),
            LearningArea(id: "nature", title: "Nature Trail", skills: NatureBank.games.map { SkillProgress(skill: $0.skill, best: p.places["nature"]?.best($0.id) ?? 0) }),
            LearningArea(id: "calendar", title: "Calendar Corner", skills: CalendarBank.games.map { SkillProgress(skill: $0.skill, best: p.places["calendar"]?.best($0.id) ?? 0) }),
            LearningArea(id: "compass", title: "Compass Camp", skills: CompassBank.games.map { SkillProgress(skill: $0.skill, best: p.places["compass"]?.best($0.id) ?? 0) }),
            LearningArea(id: "healthy", title: "Healthy Hut", skills: HealthyBank.games.map { SkillProgress(skill: $0.skill, best: p.places["healthy"]?.best($0.id) ?? 0) }),
            LearningArea(id: "planet", title: "Earth Helpers", skills: PlanetBank.games.map { SkillProgress(skill: $0.skill, best: p.places["planet"]?.best($0.id) ?? 0) }),
            LearningArea(id: "code", title: "Code Club", skills: CodeChallenge.all.map { SkillProgress(skill: "coding: \($0.topic.lowercased())", best: p.codeBest[$0.id] ?? 0) }),
        ]
    }

    var milestoneInput: MilestoneInput {
        let p = profile
        return MilestoneInput(lifetimeStars: p?.lifetimeStars ?? 0, areas: learningAreas, postcards: p?.world.postcards.count ?? 0,
                              lettersWritten: p?.writing.written.count ?? 0, storyFinished: p?.completedChapters.contains(21) == true)
    }

    /// Milestones waiting for a grown-up to share (only when milestone notes are switched on).
    var pendingMilestones: [Milestone] {
        guard let s = profile?.milestones, s.enabled else { return [] }
        return Milestones.pending(milestoneInput, shared: s.shared)
    }

    func updateMilestones(_ change: (inout MilestoneSettings) -> Void) {
        guard var p = profile else { return }
        change(&p.milestones)
        profile = p
    }

    /// The widget's view of the child: buddy, stars, and what to play next.
    var widgetSnapshot: WidgetSnapshot {
        guard let p = profile else { return .placeholder }
        let areas = learningAreas
        let c = character
        // next up: something being practised, else the first game not started, else a game already learned
        let menuAreas = areas.filter { !p.hiddenPlaces.contains($0.id) }
        let practising = menuAreas.lazy.compactMap { a in a.needsPractice.first.map { (a.title, $0.skill, "Practising") } }.first
        let fresh = menuAreas.lazy.compactMap { a in a.skills.first { $0.status == .notStarted }.map { (a.title, $0.skill, "Up next") } }.first
        let learned = menuAreas.lazy.compactMap { a in a.learned.last.map { (a.title, $0.skill, "Got it") } }.first
        let pick = practising ?? fresh ?? learned ?? ("Hop Village", "exploring", "Up next")
        let es = L10n.isSpanish
        // in Spanish, the lesson name is translated; a skill with no translation is left off rather than shown in English
        return WidgetSnapshot(name: p.name, buddyName: c.name, buddyEmoji: c.emoji, buddyID: c.id, stars: p.stars, lifetimeStars: p.lifetimeStars,
                              lessonTitle: es ? L10n.tr(pick.0) : pick.0, skill: es ? (L10n.spanish(pick.1) ?? "") : pick.1, skillState: pick.2,
                              skillsLearned: areas.reduce(0) { $0 + $1.learned.count }, skillsTotal: areas.reduce(0) { $0 + $1.skills.count },
                              quickBest: p.quick.best, spanish: es)
    }

    func publishWidget() {
        guard profile != nil, SharedStore.save(widgetSnapshot) else { return }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func milestoneNote(_ m: Milestone?) -> String {
        Milestones.note(name: profile?.name ?? "", milestone: m, input: milestoneInput)
    }
}

/// The full progress page: each learning place, and each game's skill.
struct ProgressPageView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        List {
            let areas = store.learningAreas
            let practice = areas.flatMap { a in a.needsPractice.map { (a.title, $0.skill) } }
            Section {
                LabeledContent("Stars ever earned", value: "\(store.profile?.lifetimeStars ?? 0)")
                LabeledContent("Skills learned", value: "\(areas.reduce(0) { $0 + $1.learned.count }) of \(areas.reduce(0) { $0 + $1.skills.count })")
                if practice.isEmpty {
                    Text("Nothing stuck right now. Games at 1 star will show up here as good ones to practise together.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(practice.prefix(4).enumerated()), id: \.offset) { _, item in
                        Label("\(item.1.firstCapitalized) (\(item.0))", systemImage: "hand.raised.fill")
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("At a glance")
            } footer: {
                Text("\"Practising\" means a game was played but earned 1 star. Playing it together is the best way to help.")
            }
            AtHomeSection(areas: areas)
            PlayWeekSection()
            CertificatesSection()
            PracticeSheetsSection()
            ForEach(areas) { a in
                Section {
                    ForEach(Array(a.skills.enumerated()), id: \.offset) { _, s in
                        HStack {
                            Text(s.skill.firstCapitalized)
                            Spacer()
                            status(s.status)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    DisclosureGroup("Try at home") {
                        AtHomeIdeasView(title: nil, ideas: AtHome.ideas(for: a.id))
                    }
                    .tint(Palette.purple)
                } header: {
                    HStack {
                        Text(a.title)
                        Spacer()
                        Text("\(a.stars) of \(a.maxStars) stars").monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle("Progress")
    }

    @ViewBuilder
    private func status(_ s: SkillProgress.Status) -> some View {
        switch s {
        case .gotIt: Label("Got it", systemImage: "checkmark.circle.fill").foregroundStyle(.green).labelStyle(.titleAndIcon)
        case .practising: Label("Practising", systemImage: "arrow.triangle.2.circlepath").foregroundStyle(.orange)
        case .notStarted: Text("Not yet").foregroundStyle(.secondary)
        }
    }
}

/// Settings section: progress page link, and milestone notes (off by default).
struct ProgressAndMilestonesSection: View {
    @EnvironmentObject var store: GameStore
    @State private var phoneText = ""
    @State private var composing: String?
    @State private var composingID: String?

    var body: some View {
        let settings = store.profile?.milestones ?? MilestoneSettings()
        Section {
            NavigationLink {
                ProgressPageView()
            } label: {
                Label("Progress page", systemImage: "chart.bar.doc.horizontal")
            }
            Toggle("Milestone notes", isOn: Binding(
                get: { settings.enabled },
                set: { on in
                    store.updateMilestones { m in
                        m.enabled = on
                        // start fresh: only milestones reached from now on wait here
                        if on { m.shared.formUnion(Milestones.reached(store.milestoneInput).map(\.id)) }
                    }
                }))
            if settings.enabled {
                TextField("Your phone number (optional)", text: $phoneText)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .onSubmit(savePhone)
                    .onChange(of: phoneText) { _, _ in savePhone() }
                let pending = store.pendingMilestones
                if pending.isEmpty {
                    Text("No new milestones yet. When your child reaches one, it will wait here for you to send.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(pending) { m in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(store.profile?.name ?? "Your child") just \(m.what)!").font(.subheadline.weight(.semibold))
                        HStack {
                            Button { open(store.milestoneNote(m), id: m.id) } label: {
                                Label("Text it", systemImage: "message.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Skip") { store.updateMilestones { $0.shared.insert(m.id) } }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Button { open(store.milestoneNote(nil), id: nil) } label: {
                    Label("Send a progress note now", systemImage: "square.and.arrow.up")
                }
            }
        } header: {
            Text("Progress and milestones")
        } footer: {
            Text("Milestone notes never send by themselves. When your child reaches a milestone (like finishing every game in a place, or 100 stars), it waits here. Tap Text it and Messages opens with a short note about the skills they've learned; you press Send. Your number stays on this device and is only used to fill in the To: line.")
        }
        .onAppear { phoneText = settings.phone }
        .sheet(item: Binding(get: { composing.map(ComposeItem.init) }, set: { if $0 == nil { composing = nil } })) { item in
            MessageComposer(body: item.text, recipient: store.profile?.milestones.phone ?? "") { sent in
                if sent, let id = composingID { store.updateMilestones { $0.shared.insert(id) } }
                composing = nil
                composingID = nil
            }
            .ignoresSafeArea()
        }
    }

    private struct ComposeItem: Identifiable {
        let text: String
        var id: String { text }
    }

    private func savePhone() {
        let clean = Milestones.cleanPhone(phoneText)
        store.updateMilestones { $0.phone = clean }
    }

    private func open(_ text: String, id: String?) {
        composingID = id
        composing = text
    }
}

/// Messages with the note filled in, or the share sheet on devices that can't text (most iPads).
struct MessageComposer: UIViewControllerRepresentable {
    let body: String
    let recipient: String
    var onDone: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    func makeUIViewController(context: Context) -> UIViewController {
        if MFMessageComposeViewController.canSendText() {
            let vc = MFMessageComposeViewController()
            vc.body = body
            if !recipient.isEmpty { vc.recipients = [recipient] }
            vc.messageComposeDelegate = context.coordinator
            return vc
        }
        let share = UIActivityViewController(activityItems: [body], applicationActivities: nil)
        share.completionWithItemsHandler = { _, completed, _, _ in context.coordinator.onDone(completed) }
        return share
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDone: (Bool) -> Void
        init(onDone: @escaping (Bool) -> Void) { self.onDone = onDone }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            onDone(result == .sent)
        }
    }
}
