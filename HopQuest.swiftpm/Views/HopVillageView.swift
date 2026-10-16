import SwiftUI
import SpriteKit

/// Hop Village: walk your buddy around a pixel-art village, chat with buddies, and walk through doors
/// into every HopQuest game. Routing, stars and progress stay in RootView; the village just asks to go places.
struct HopVillageView: View {
    @EnvironmentObject var store: GameStore
    /// Open an existing screen (castle, sticker book, a chapter...).
    var onOpen: (VillageDestination) -> Void
    var onMap: () -> Void

    @State private var scene: HopVillageScene?
    @State private var builtFor = ""
    @State private var interaction: VillageInteraction?
    @State private var dialogue: VillageDialogue?
    @State private var quiz: Question?
    @State private var quizNPC: String?
    @State private var academyOpen = false
    @State private var banner: String?
    @State private var note: String?
    @State private var showParent = false
    @State private var showCharacters = false

    private var anyOverlay: Bool { dialogue != nil || quiz != nil || academyOpen || showParent || showCharacters }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0x3F7F36).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                        .id(ObjectIdentifier(scene))
                        .ignoresSafeArea()
                        .accessibilityLabel("Hop Village. Tap a spot to walk there.")
                }

                VStack(spacing: 8) {
                    VillageTopBar(character: store.character, stars: store.profile?.stars ?? 0,
                                  onMap: leaveToMap,
                                  onBuddy: { showCharacters = true },
                                  onParent: { showParent = true })
                    if let banner {
                        VillageRegionBanner(text: banner)
                    }
                    if let note {
                        MessageBubble(text: note)
                    }
                    Spacer()
                    if !anyOverlay {
                        HStack(alignment: .bottom) {
                            VillageJoystick { v in scene?.setJoystick(v) }
                            Spacer()
                            actionButton
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    }
                }
                .padding(.top, 4)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: banner)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: note)

                if let dialogue {
                    VStack {
                        Spacer()
                        VillageDialogueView(dialogue: dialogue)
                            .padding(.bottom, 12)
                    }
                    .id(dialogue.id)
                }

                if academyOpen {
                    Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { closeAcademy() }
                    VillageChapterPicker(title: "Driving Academy",
                                         chapters: [Chapters.chapter(2), Chapters.chapter(5)],
                                         state: { store.state(of: $0) },
                                         onPick: { chapter in
                                             academyOpen = false
                                             leave(.chapter(chapter.id), via: .enter(.academy))
                                         },
                                         onClose: closeAcademy)
                }

                if let quiz {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    QuizCard(question: quiz) { firstTry in
                        self.quiz = nil
                        riddleFinished(firstTry: firstTry)
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dialogue?.id)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: academyOpen)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: quiz?.id)
            .onAppear { build(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in build(size: newSize) }
            .onChange(of: store.profile?.characterID) { _, _ in
                if store.character.id != builtFor { rebuild(size: geo.size) }
            }
            .onChange(of: store.profile?.village.lightEffects) { _, _ in rebuild(size: geo.size) }
            .onChange(of: store.profile?.village.eveningLights) { _, _ in rebuild(size: geo.size) }
            .onChange(of: anyOverlay) { _, open in scene?.frozen = open }
            .onDisappear {
                savePosition()
                tearDown()
                Narrator.shared.stop()
            }
        }
        .sheet(isPresented: $showParent) {
            ParentGateView().environmentObject(store)
        }
        .sheet(isPresented: $showCharacters) {
            CharacterSelectView(theme: store.theme, initialID: store.profile?.characterID, buttonTitle: "Use this buddy") { picked in
                store.profile?.characterID = picked.id
                showCharacters = false
            }
            .background(LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
    }

    // MARK: Action button

    @ViewBuilder
    private var actionButton: some View {
        switch interaction {
        case .talk(let id)?:
            let name = scene?.npcCharacter(id)?.name.components(separatedBy: " ").first ?? "buddy"
            VillageActionButton(title: "Talk to \(name)", icon: "bubble.left.fill", color: Color(hex: 0x4D96FF)) { handle(.talk(npcID: id)) }
        case .enter(let kind)?:
            VillageActionButton(title: kind == .castle ? "Go home" : "Go in", icon: "door.left.hand.open", color: Palette.green) { handle(.enter(kind)) }
        case .portal(let n)?:
            let awake = portalAwake(n)
            VillageActionButton(title: awake ? "Hop in!" : "Sleeping", icon: awake ? "sparkles" : "moon.zzz.fill",
                                color: awake ? Palette.purple : Color.gray) { handle(.portal(n)) }
        case nil:
            VillageActionButton(title: "Hop!", icon: "hare.fill", color: Color(hex: 0xFF7A59)) {
                Haptics.bump(.hop)
                scene?.hopInPlace()
            }
        }
    }

    // MARK: Building the scene

    private func build(size: CGSize) {
        guard scene == nil, size.width > 0, let profile = store.profile else { return }
        let setup = HopVillageScene.Setup(character: store.character, theme: store.theme, save: profile.village,
                                          awakePortals: Set(VillageMap.shared.portals.filter { store.isPlayable($0.chapterID) }.map(\.number)),
                                          hour: Calendar.current.component(.hour, from: Date()))
        let s = HopVillageScene(size: size, setup: setup)
        s.onInteractionChange = { i in
            if i != nil && i != interaction { Haptics.tap(nil) }
            interaction = i
        }
        s.onActivate = { i in handle(i) }
        s.onRegionChange = { name in showBanner(name) }
        s.onGreet = { [weak s] id in
            guard let c = s?.npcCharacter(id) else { return }
            showNote("\(c.name): Hi, \(store.profile?.name ?? "friend")! 👋")
        }
        scene = s
        builtFor = store.character.id
        store.updateVillage { $0.startInVillage = true }
    }

    /// New buddy or new effects setting: save where we are and build a fresh scene.
    private func rebuild(size: CGSize) {
        guard scene != nil else { return }
        savePosition()
        tearDown()
        build(size: size)
    }

    /// Breaks the scene ↔ view references so the old scene is freed.
    private func tearDown() {
        scene?.onInteractionChange = nil
        scene?.onActivate = nil
        scene?.onRegionChange = nil
        scene?.onGreet = nil
        scene = nil
        interaction = nil
    }

    // MARK: What the button (or walking into things) does

    private func handle(_ i: VillageInteraction) {
        guard !anyOverlay else { return }
        switch i {
        case .talk(let id):
            talk(to: id)
        case .enter(let kind):
            Haptics.tap(.whoosh)
            switch kind {
            case .castle: leave(.castle, via: i)
            case .museum: leave(.stickers, via: i)
            case .arena: leave(.bop, via: i)
            case .stadium: leave(.kartSelect, via: i)
            case .fortYard: leave(.fortSelect, via: i)
            case .workshop:
                if store.isPlayable(3) {
                    leave(.chapter(3), via: i)
                } else {
                    showNote("The Robot Workshop opens after Driving School. Keep going! 🛠️")
                }
            case .academy:
                academyOpen = true
            case .fountain:
                break
            }
        case .portal(let n):
            guard let portal = VillageMap.shared.portals.first(where: { $0.number == n }) else { return }
            if portalAwake(n) {
                Haptics.success(.whoosh)
                leave(.chapter(portal.chapterID), via: i)
            } else {
                let next = Chapters.chapter(store.nextChapterID).title
                showNote("This portal is still asleep 💤 Finish the adventures before it to wake it up. Next up: \(next)!")
            }
        }
    }

    private func portalAwake(_ n: Int) -> Bool {
        guard let p = VillageMap.shared.portals.first(where: { $0.number == n }) else { return false }
        return store.isPlayable(p.chapterID)
    }

    /// Save where to stand when we come back, then open the destination.
    private func leave(_ destination: VillageDestination, via i: VillageInteraction) {
        guard let scene else { return }
        let tile = scene.returnTile(for: i)
        store.updateVillage { v in
            v.tile = tile
            v.facing = .south
            v.startInVillage = true
            if case .enter(let kind) = i { v.visited.insert(kind.id) }
            if case .portal(let n) = i { v.visited.insert("portal\(n)") }
        }
        Narrator.shared.stop()
        onOpen(destination)
    }

    private func leaveToMap() {
        savePosition()
        store.updateVillage { $0.startInVillage = false }
        onMap()
    }

    private func savePosition() {
        guard let scene else { return }
        let tile = scene.playerTile, facing = scene.playerFacing
        store.updateVillage { v in
            v.tile = tile
            v.facing = facing
        }
    }

    // MARK: Conversations

    private func talk(to id: String) {
        guard let def = VillageNPCDef.def(id), let scene, let speaker = scene.npcCharacter(id) else { return }
        scene.beginTalk(id)
        store.updateVillage { $0.talkedTo.insert(id) }
        let solved = store.profile?.village.solved.contains(id) ?? false
        let close = VillageDialogue.Choice(title: "Bye!", primary: false) { endTalk(happy: false) }

        if let lesson = def.lesson, !solved {
            say(VillageDialogue(speaker: speaker, text: def.greeting, choices: [
                .init(title: "Yes, let's try!") { askRiddle(def, lesson: lesson, speaker: speaker) },
                .init(title: "Maybe later", primary: false) { endTalk(happy: false) }
            ]))
        } else {
            let line = def.chatter.randomElement() ?? def.greeting
            var choices = [close]
            if let lesson = def.lesson {
                choices.insert(.init(title: "Another riddle?") { askRiddle(def, lesson: lesson, speaker: speaker) }, at: 0)
            }
            say(VillageDialogue(speaker: speaker, text: line, choices: choices))
        }
    }

    private func askRiddle(_ def: VillageNPCDef, lesson: NPCLesson, speaker: GameCharacter) {
        dialogue = nil
        Narrator.shared.say(def.askLine)
        quizNPC = def.id
        // set in the same update as closing the dialogue, so the village never unfreezes in between
        quiz = QuestionBank.one(subject(for: lesson))
    }

    /// QuizCard already narrates and records the answer for the Learning Report; the village only adds
    /// a one-time star per buddy.
    private func riddleFinished(firstTry: Bool) {
        guard let id = quizNPC, let def = VillageNPCDef.def(id), let speaker = scene?.npcCharacter(id) else { return }
        quizNPC = nil
        let firstSolve = store.solveVillageRiddle(id)
        if firstSolve { Haptics.success(.star) }
        let text = firstSolve ? def.thanksLine : (firstTry ? "Wow, first try! " : "You figured it out! ") + (def.chatter.randomElement() ?? "")
        say(VillageDialogue(speaker: speaker, text: text, choices: [
            .init(title: firstSolve ? "Yay! ⭐" : "Thanks!") { endTalk(happy: true) }
        ]))
    }

    private func endTalk(happy: Bool) {
        dialogue = nil
        scene?.endTalk(happy: happy)
        Narrator.shared.stop()
    }

    private func say(_ d: VillageDialogue) {
        dialogue = d
        Narrator.shared.say(d.text)
    }

    private func subject(for lesson: NPCLesson) -> Subject {
        switch lesson {
        case .math: return .math
        case .road: return .road
        case .nature: return .nature
        case .science: return .science
        case .words: return .words
        }
    }

    private func closeAcademy() { academyOpen = false }

    // MARK: Little messages

    private func showBanner(_ text: String) {
        banner = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if banner == text { banner = nil }
        }
    }

    private func showNote(_ text: String) {
        note = text
        Narrator.shared.say(text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            if note == text { note = nil }
        }
    }
}
