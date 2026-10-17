import SwiftUI
import SpriteKit

/// Hop Village: walk your buddy around a pixel-art village with a building for every game. Finish all ten
/// challenges to open your castle. A pop-quiz buddy drops by every couple of minutes, and friends playing
/// live can challenge each other to Brain Duels. Routing, stars and progress stay in RootView.
struct HopVillageView: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var network: VillageNetwork
    /// Open an existing screen (castle, sticker book, a chapter...).
    var onOpen: (VillageDestination) -> Void
    /// Back to the main menu.
    var onMenu: () -> Void

    private enum QuizSource: Equatable { case npc(String), pop }

    @State private var scene: HopVillageScene?
    @State private var builtFor = ""
    @State private var interaction: VillageInteraction?
    @State private var dialogue: VillageDialogue?
    @State private var quiz: Question?
    @State private var quizSource: QuizSource?
    @State private var boardOpen = false
    @State private var missionsOpen = false
    @State private var castleParty = false
    @State private var banner: String?
    @State private var note: String?
    @State private var showParent = false
    @State private var showCharacters = false
    @State private var duelStars: Int?
    @State private var homeOpen = false
    @State private var gardenOpen = false
    @AppStorage(Handedness.key) private var leftHanded = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var festivalOpen = false
    @State private var storyTurn = 0
    /// Screen height, so tall panels fit small phones.
    @State private var screenHeight: CGFloat = 800

    private var anyOverlay: Bool {
        dialogue != nil || quiz != nil || boardOpen || missionsOpen || castleParty || showParent || showCharacters
            || homeOpen || gardenOpen || festivalOpen || network.incoming != nil || network.duel != nil
    }

    private var seasonsOn: Bool { store.profile?.village.seasons ?? true }

    /// Today in the village. With seasons off it's always a sunny spring day (festivals still rotate).
    private var today: VillageDay {
        let real = VillageDay(date: Date())
        return seasonsOn ? real : VillageDay(season: .spring, weather: .sunny, weekFestival: real.weekFestival)
    }

    private var festival: Festival { today.festival(picked: store.profile?.village.festivalPick) }

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
                                  challengesDone: store.challengeProgress.doneCount,
                                  onMap: leaveToMenu,
                                  onBuddy: { showCharacters = true },
                                  onChallenges: { boardOpen = true },
                                  onParent: { showParent = true })
                    if network.isOn {
                        LivePlayPill(status: network.status, count: network.roster.count)
                    }
                    if !anyOverlay {
                        VillageTodayPill(day: today, festival: festival, seasonsOn: seasonsOn) { festivalOpen = true }
                    }
                    if let banner {
                        VillageRegionBanner(text: banner)
                    }
                    if let note {
                        MessageBubble(text: note)
                    }
                    Spacer()
                    if !anyOverlay {
                        HStack(alignment: .bottom) {
                            if leftHanded {
                                VStack(spacing: 10) {
                                    missionsButton
                                    actionButton
                                }
                                Spacer()
                                VillageJoystick { v in scene?.setJoystick(v) }
                            } else {
                                VillageJoystick { v in scene?.setJoystick(v) }
                                Spacer()
                                VStack(spacing: 10) {
                                    missionsButton
                                    actionButton
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    }
                }
                .padding(.top, 4)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: banner)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: note)

                overlays
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dialogue?.id)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: boardOpen)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: quiz?.id)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: network.incoming)
            .onAppear {
                build(size: geo.size)
                startNetwork()
                screenHeight = geo.size.height
            }
            .onChange(of: geo.size) { _, newSize in
                build(size: newSize)
                screenHeight = newSize.height
            }
            .onChange(of: store.profile?.characterID) { _, _ in
                if store.character.id != builtFor {
                    rebuild(size: geo.size)
                    startNetwork()
                }
            }
            .onChange(of: store.profile?.village.lightEffects) { _, _ in rebuild(size: geo.size) }
            .onChange(of: store.profile?.village.eveningLights) { _, _ in rebuild(size: geo.size) }
            .onChange(of: store.profile?.village.seasons) { _, _ in rebuild(size: geo.size) }
            .onChange(of: store.profile?.village.playMode) { _, _ in startNetwork() }
            .onChange(of: scenePhase) { _, phase in
                // back after a night away: the plants grew
                if phase == .active { refreshGarden() }
            }
            .onChange(of: anyOverlay) { _, open in scene?.frozen = open }
            .onChange(of: network.notice) { _, text in
                if let text { showNote(text); network.notice = nil }
            }
            .onChange(of: network.waitingFor) { _, who in
                if let who { showNote("Waiting for \(who) to answer… ⏳") }
            }
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

    // MARK: Overlays

    @ViewBuilder
    private var overlays: some View {
        if let dialogue {
            VStack {
                Spacer()
                VillageDialogueView(dialogue: dialogue)
                    .padding(.bottom, 12)
            }
            .id(dialogue.id)
        }

        if homeOpen {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { homeOpen = false }
            HomeDecorView(style: store.profile?.village.home ?? HomeStyle(),
                          unlocked: HomeStyle.unlocked(missionsDone: store.profile?.missions.done ?? []),
                          ownerName: store.profile?.name ?? "My",
                          maxHeight: screenHeight - 200,
                          onChange: { style in
                              store.updateVillage { $0.home = style }
                              scene?.updateHome(style)
                          },
                          onClose: {
                              homeOpen = false
                              scene?.celebrate()
                          })
        }

        if gardenOpen {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { gardenOpen = false }
            GardenView(garden: store.profile?.village.garden ?? GardenSave(), today: GameStore.todayKey,
                       maxHeight: screenHeight - 200,
                       onPlant: { bed, kind in
                           var planted = false
                           store.updateVillage { planted = $0.garden.plant(kind, in: bed, today: GameStore.todayKey) }
                           if planted { Narrator.shared.say("You planted a \(kind.title.lowercased()) seed! \(kind.fact)") }
                           refreshGarden()
                       },
                       onWater: { bed in
                           store.updateVillage { $0.garden.water(bed, today: GameStore.todayKey) }
                           Haptics.tap(.splash)
                           Narrator.shared.say("Splish! Plants drink water through their roots.")
                           refreshGarden()
                       },
                       onHarvest: { bed in
                           guard let picked = store.harvestGarden(bed) else { return }
                           Haptics.success(.chime)
                           Narrator.shared.say(picked.stars > 0 ? "Your first \(picked.kind.title.lowercased())! Here's a star!" : "You picked a \(picked.kind.title.lowercased())! Yum!")
                           refreshGarden()
                       },
                       onPet: { kind in
                           store.updateVillage { $0.garden.pet = kind }
                           scene?.setPet(kind)
                           if let kind { Narrator.shared.say("\(kind.name) the \(kind.title.lowercased()) will walk with you!") }
                       },
                       onClose: {
                           gardenOpen = false
                           scene?.celebrate()
                       })
        }

        if festivalOpen {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { festivalOpen = false }
            FestivalBoardView(day: today, current: festival, missions: store.profile?.missions ?? MissionSave(), seasonsOn: seasonsOn,
                              maxHeight: screenHeight - 200,
                              onPick: { f in
                                  store.updateVillage { $0.festivalPick = f == today.weekFestival ? nil : f.rawValue }
                                  scene?.setFestival(f)
                                  showNote("\(f.icon) The square is ready for the \(f.title)! Talk to Gemma to join in.")
                              },
                              onGoToHost: {
                                  festivalOpen = false
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                      if let t = scene?.npcTile(FestivalMissions.hostID) { scene?.walk(toTile: t) }
                                  }
                              },
                              onClose: { festivalOpen = false })
        }

        if missionsOpen {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { missionsOpen = false }
            MissionLogView(save: store.profile?.missions ?? MissionSave(),
                           missions: MissionCatalog.visible(save: store.profile?.missions ?? MissionSave(), festival: festival),
                           giverName: { id in scene?.npcCharacter(id)?.name ?? id.capitalized },
                           onGo: { m in
                               missionsOpen = false
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { goTo(m) }
                           },
                           onClose: { missionsOpen = false })
        }

        if boardOpen {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { boardOpen = false }
            VillageChallengeBoard(progress: store.challengeProgress,
                                  isOpen: { c in c.chapter.map { store.isPlayable($0) } ?? true },
                                  onGo: { kind in
                                      boardOpen = false
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { scene?.walk(to: kind) }
                                  },
                                  onClose: { boardOpen = false })
        }

        if let quiz {
            Color.black.opacity(0.35).ignoresSafeArea()
            QuizCard(question: quiz) { firstTry in
                self.quiz = nil
                quizFinished(firstTry: firstTry)
            }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }

        if let inc = network.incoming {
            Color.black.opacity(0.3).ignoresSafeArea()
            DuelInviteCard(nick: inc.nick) { accept in
                duelStars = nil
                network.respond(accept: accept)
            }
        }

        if network.duel != nil {
            BrainDuelView(network: network, starsGiven: duelStars) {
                network.endDuel()
                duelStars = nil
                scene?.celebrate()
            }
            .transition(.opacity)
        }

        if castleParty {
            CastleOpenView(theme: store.theme, name: store.profile?.name ?? "friend") {
                castleParty = false
                store.updateVillage { $0.castleCelebrated = true }
                leave(.castle, via: .enter(.castle))
            }
            .transition(.opacity)
        }
    }

    // MARK: Action button

    private var missionsButton: some View {
        let active = (store.profile?.missions).map { m in
            MissionCatalog.visible(save: m, festival: festival).filter { m.status($0) != .new && m.status($0) != .done }.count
        } ?? 0
        return Button {
            Haptics.tap()
            missionsOpen = true
        } label: {
            VStack(spacing: 0) {
                Text("📜").font(.system(size: 24))
                Text("Missions").font(.kid(11, .black)).foregroundStyle(Palette.ink)
            }
            .frame(width: 70, height: 62)
            .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.95)).shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 4))
            .overlay(alignment: .topTrailing) {
                if active > 0 {
                    Text("\(active)").font(.kid(13, .black)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Circle().fill(Palette.red)).offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Missions, \(active) in progress")
    }

    @ViewBuilder
    private var actionButton: some View {
        switch interaction {
        case .talk(let id)?:
            let name = scene?.npcCharacter(id)?.name.components(separatedBy: " ").first ?? "buddy"
            VillageActionButton(title: "Talk to \(name)", icon: "bubble.left.fill", color: Color(hex: 0x4D96FF)) { handle(.talk(npcID: id)) }
        case .enter(let kind)?:
            let locked = doorSign(kind) == .locked
            VillageActionButton(title: kind == .castle ? (locked ? "Locked" : "Go home") : (locked ? "Locked" : "Go in"),
                                icon: locked ? "lock.fill" : "door.left.hand.open",
                                color: locked ? Color.gray : Palette.green) { handle(.enter(kind)) }
        case .challenge(let key)?:
            let nick = network.peers[key]?.nick ?? "friend"
            VillageActionButton(title: "Duel \(nick)!", icon: "bolt.fill", color: Color(hex: 0xFF7A59)) { handle(.challenge(peerKey: key)) }
        case nil:
            VillageActionButton(title: "Hop!", icon: "hare.fill", color: Color(hex: 0xFF7A59)) {
                Haptics.bump(.hop)
                scene?.hopForward()
            }
        }
    }

    private func refreshGarden() {
        scene?.updateGarden(store.profile?.village.garden ?? GardenSave(), today: GameStore.todayKey)
    }

    // MARK: Building the scene

    private func doorSign(_ kind: BuildingKind) -> HopVillageScene.DoorSign? {
        let progress = store.challengeProgress
        if kind == .castle { return progress.allDone ? .done : .locked }
        if let c = kind.challenge, c.isDone(progress) { return .done }
        if let ch = kind.storyChapter, !store.isPlayable(ch) { return .locked }
        return nil
    }

    private func build(size: CGSize) {
        guard scene == nil, size.width > 0, let profile = store.profile else { return }
        var signs: [BuildingKind: HopVillageScene.DoorSign] = [:]
        for kind in BuildingKind.allCases { if let s = doorSign(kind) { signs[kind] = s } }
        let setup = HopVillageScene.Setup(character: store.character, theme: store.theme, save: profile.village,
                                          doorSigns: signs, hour: Calendar.current.component(.hour, from: Date()),
                                          day: today, festival: festival, today: GameStore.todayKey)
        let s = HopVillageScene(size: size, setup: setup)
        s.network = network
        s.onInteractionChange = { i in
            if i != nil && i != interaction { Haptics.tap(nil) }
            interaction = i
        }
        s.onActivate = { i in handle(i) }
        s.onRegionChange = { name in showBanner(name) }
        s.onGreet = { [weak s] id in
            guard let c = s?.npcCharacter(id) else { return }
            showNote("\(c.name): Hi, \(store.profile?.name ?? "friend")! 👋", speak: false)
        }
        s.onPopQuiz = { character in popQuiz(from: character) }
        s.onPickup = { key in pickedUp(key) }
        s.onPetTap = { kind in
            Haptics.tap(.pop)
            showNote("\(kind.emoji) \(kind.pat)", speak: true)
        }
        s.setPickups(profile.missions.pickups())
        scene = s
        builtFor = store.character.id
        configureDuels()
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
        scene?.onPopQuiz = nil
        scene?.onPickup = nil
        scene?.network = nil
        scene = nil
        interaction = nil
    }

    // MARK: Live play

    /// Starts (or restarts) live play the way the grown-ups set it up.
    private func startNetwork() {
        let mode = store.profile?.village.playMode ?? .off
        // Only the buddy's name ever leaves the device (nearby or online), never the child's name.
        let nick = store.character.name
        if mode == .off {
            network.stop()
        } else {
            network.start(mode: mode, nick: nick, characterID: store.character.id)
        }
    }

    private func configureDuels() {
        network.makeQuestions = { [store] in
            Self.duelQuestions(done: store.challengeProgress.done)
        }
        network.onDuelFinished = { [store, network] duel in
            let earned = duel.stars(for: network.myKey)
            duelStars = store.grantDuelStars(earned)
        }
    }

    /// Five questions from the games the host has played: follow-ups first, then Brain Gate questions.
    static func duelQuestions(done: [VillageChallenge]) -> [DuelQuestion] {
        var out: [DuelQuestion] = []
        var items = (done.isEmpty ? FollowUpBank.general : done.flatMap { FollowUpBank.items(for: $0) }).shuffled()
        while out.count < 3, let item = items.popLast() {
            let q = question(from: item)
            out.append(DuelQuestion(subject: q.subject.rawValue, prompt: q.prompt, choices: q.choices, answer: q.answer))
        }
        let subjects: [Subject] = [.math, .road, .nature, .science, .words].shuffled()
        var i = 0
        while out.count < BrainDuel.questionCount {
            let q = QuestionBank.one(subjects[i % subjects.count])
            i += 1
            guard (2...4).contains(q.choices.count), !out.contains(where: { $0.prompt == q.prompt }) || i > 20 else { continue }
            out.append(DuelQuestion(subject: q.subject.rawValue, prompt: q.prompt, choices: q.choices, answer: q.answer))
        }
        return out
    }

    /// Turns a written follow-up (right answer first) into a Brain Gate question with shuffled answers.
    static func question(from item: QuizItem) -> Question {
        let shuffled = item.choices.shuffled()
        return Question(subject: Subject(rawValue: item.subject) ?? .science,
                        prompt: item.prompt, choices: shuffled,
                        answer: shuffled.firstIndex(of: item.choices[0]) ?? 0,
                        explain: item.explain)
    }

    // MARK: What the button (or walking into things) does

    private func handle(_ i: VillageInteraction) {
        guard !anyOverlay else { return }
        switch i {
        case .talk(let id):
            talk(to: id)
        case .challenge(let key):
            guard let peer = network.peers[key] else { return }
            Haptics.tap()
            duelStars = nil
            network.challenge(key)
            showNote("You challenged \(peer.nick) to a Brain Duel! ⚔️")
        case .enter(let kind):
            enter(kind)
        }
    }

    private func enter(_ kind: BuildingKind) {
        let i = VillageInteraction.enter(kind)
        if kind == .castle {
            let progress = store.challengeProgress
            if progress.allDone {
                Haptics.success(.whoosh)
                if store.profile?.village.castleCelebrated == true { leave(.castle, via: i) } else { castleParty = true }
            } else {
                Haptics.bump(.oops)
                showNote("Your castle opens when all \(ChallengeProgress.total) challenges are done. You've finished \(progress.doneCount)! 🏆")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { if !anyOverlay { boardOpen = true } }
            }
            return
        }
        if kind == .garden {
            Haptics.tap(.whoosh)
            store.updateVillage { $0.visited.insert(kind.id) }
            gardenOpen = true
            Narrator.shared.say("Welcome to your garden! Plant a seed, or water your plants.")
            return
        }
        if kind == .home {
            Haptics.tap(.whoosh)
            store.updateVillage { $0.visited.insert(kind.id) }
            homeOpen = true
            Narrator.shared.say("Welcome home! Pick colors and decorations for your house.")
            return
        }
        if let chapter = kind.storyChapter, !store.isPlayable(chapter) {
            let next = Chapters.chapter(store.nextChapterID).title
            showNote("\(kind.title) opens later in your adventure. Next up: \(next)! 🔒")
            return
        }
        Haptics.tap(.whoosh)
        switch kind {
        case .museum: leave(.stickers, via: i)
        case .arena: leave(.bop, via: i)
        case .stadium: leave(.kartSelect, via: i)
        case .fortYard: leave(.fortSelect, via: i)
        case .clubhouse: leave(.together, via: i)
        case .codingLab: leave(.codingLab, via: i)
        case .nook: leave(.readingNook, via: i)
        case .market: leave(.mathMarket, via: i)
        case .cottage, .academy, .workshop, .boathouse, .garage, .tower:
            if let chapter = kind.storyChapter { leave(.chapter(chapter), via: i) }
        case .castle, .fountain, .home, .garden:
            break
        }
    }

    /// Save where to stand when we come back, then open the destination.
    private func leave(_ destination: VillageDestination, via i: VillageInteraction) {
        guard let scene else { return }
        let tile = scene.returnTile(for: i)
        store.updateVillage { v in
            v.tile = tile
            v.facing = .south
            if case .enter(let kind) = i { v.visited.insert(kind.id) }
        }
        Narrator.shared.stop()
        onOpen(destination)
    }

    private func leaveToMenu() {
        savePosition()
        network.stop()
        onMenu()
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

        // 1) a delivery or a kind visit for someone else's mission
        var delivered: (MissionDef, String)?
        store.updateMissions { delivered = $0.talked(to: id) }
        if let d = delivered {
            let (m, line) = d
            Haptics.success(.chime)
            let status = store.profile?.missions.status(m)
            let next: String
            if status == .readyToTurnIn {
                next = "Mission step done! Go back to \(scene.npcCharacter(m.giver)?.name ?? "your friend") for your stars."
            } else if case .active(let step)? = status {
                next = "Next: \(m.steps[step].hint)."
            } else {
                next = ""
            }
            say(VillageDialogue(speaker: speaker, text: line + (next.isEmpty ? "" : " " + next), choices: [
                .init(title: "Great! \(m.icon)") { endTalk(happy: true) }
            ]))
            return
        }

        // 2) this buddy's own mission (Gemma hosts the festival)
        if let missions = store.profile?.missions, let m = MissionCatalog.offer(from: id, save: missions, festival: festival) {
            switch missions.status(m) {
            case .new:
                say(VillageDialogue(speaker: speaker, text: "\(m.icon) \(m.intro)", choices: [
                    .init(title: "I'll help!") { startMission(m, speaker: speaker) },
                    .init(title: "Maybe later", primary: false) { endTalk(happy: false) }
                ]))
                return
            case .readyToTurnIn:
                let stars = store.turnInMission(m)
                Haptics.success(.fanfare)
                say(VillageDialogue(speaker: speaker, text: m.thanks + (stars > 0 ? " Here are \(stars) stars! ⭐" : ""), choices: [
                    .init(title: "Yay! 🎉") { endTalk(happy: true) }
                ]))
                return
            case .active(let step):
                let progress = missions.collectedCount(m).map { " (\($0.have) of \($0.need) so far)" } ?? ""
                var choices: [VillageDialogue.Choice] = [.init(title: "On it! \(m.icon)") { endTalk(happy: false) }]
                if let lesson = def.lesson, !solved {
                    choices.append(.init(title: "Riddle?", primary: false) { askRiddle(def, lesson: lesson) })
                }
                say(VillageDialogue(speaker: speaker, text: "\(m.title): \(m.steps[step].hint)\(progress). You can do it!", choices: choices))
                return
            case .done:
                break
            }
        }

        // 3) riddles and chatter
        if let lesson = def.lesson, !solved {
            say(VillageDialogue(speaker: speaker, text: def.greeting, choices: [
                .init(title: "Yes, let's try!") { askRiddle(def, lesson: lesson) },
                .init(title: "Maybe later", primary: false) { endTalk(happy: false) }
            ]))
        } else {
            // villagers talk about their lives, the season and the weather
            storyTurn += 1
            let line = storyTurn % 3 == 0 ? (def.chatter.randomElement() ?? def.greeting)
                : (seasonsOn ? VillageStories.line(npc: id, day: today, turn: storyTurn) : (def.chatter.randomElement() ?? def.greeting))
            var choices = [close]
            if let lesson = def.lesson {
                choices.insert(.init(title: "Another riddle?") { askRiddle(def, lesson: lesson) }, at: 0)
            }
            say(VillageDialogue(speaker: speaker, text: line, choices: choices))
        }
    }

    private func startMission(_ m: MissionDef, speaker: GameCharacter) {
        store.updateMissions { $0.start(m) }
        store.updateMissions { $0.codeLessonsDone(store.profile?.codeLab.completed.count ?? 0) }
        scene?.setPickups(store.profile?.missions.pickups() ?? [])
        Haptics.success(.chime)
        say(VillageDialogue(speaker: speaker, text: "Did you know? \(m.lesson)", choices: [
            .init(title: "Let's go! \(m.icon)") { endTalk(happy: true) }
        ]))
    }

    /// Walked over a mission item.
    private func pickedUp(_ key: String) {
        var mission: MissionDef?
        store.updateMissions { mission = $0.collect(key) }
        guard let m = mission, let missions = store.profile?.missions else { return }
        if missions.status(m) == .readyToTurnIn {
            Haptics.success(.star)
            let giver = scene?.npcCharacter(m.giver)?.name ?? "your friend"
            showNote("\(m.icon) All found! Go back to \(giver) for your stars.")
        } else if let c = missions.collectedCount(m) {
            Haptics.tap(nil)
            showNote("\(m.icon) \(c.have) of \(c.need)!", speak: false)
        }
    }

    /// "Go!" from the mission log: walk toward whatever comes next.
    private func goTo(_ m: MissionDef) {
        guard let scene, let missions = store.profile?.missions else { return }
        switch missions.status(m) {
        case .new, .readyToTurnIn, .done:
            if let t = scene.npcTile(m.giver) { scene.walk(toTile: t) }
        case .active(let step):
            switch m.steps[step] {
            case .collect:
                let here = scene.playerTile
                if let near = missions.pickups().filter({ $0.key.hasPrefix(m.id + ".") })
                    .min(by: { $0.tile.manhattan(here) < $1.tile.manhattan(here) }) {
                    scene.walk(toTile: near.tile)
                }
            case .talk(let npc, _, _):
                if let t = scene.npcTile(npc) { scene.walk(toTile: t) }
            case .codeLessons:
                scene.walk(to: .codingLab)
            }
        }
    }

    private func askRiddle(_ def: VillageNPCDef, lesson: NPCLesson) {
        dialogue = nil
        Narrator.shared.say(def.askLine)
        quizSource = .npc(def.id)
        // set in the same update as closing the dialogue, so the village never unfreezes in between
        quiz = QuestionBank.one(subject(for: lesson))
    }

    /// The pop-quiz buddy walked up.
    private func popQuiz(from speaker: GameCharacter) {
        guard !anyOverlay else {
            scene?.finishPopQuiz(happy: false)
            return
        }
        let done = store.challengeProgress.done
        let about = done.isEmpty ? "the village" : (done.randomElement()?.title ?? "your games")
        say(VillageDialogue(speaker: speaker, text: "Pop quiz! ✨ Here's a bonus question about \(about). Ready?", choices: [
            .init(title: "Let's go!") {
                dialogue = nil
                let turn = store.profile?.village.popTurn ?? 0
                store.updateVillage { $0.popTurn += 1 }
                quizSource = .pop
                quiz = Self.question(from: FollowUpBank.pick(done: done, turn: turn * 7 + Int.random(in: 0...3)))
            },
            .init(title: "Not now", primary: false) {
                dialogue = nil
                scene?.finishPopQuiz(happy: false)
            }
        ]))
    }

    /// QuizCard already narrates and records the answer for the Learning Report; the village only adds
    /// a one-time star per buddy, or a capped bonus star for pop quizzes.
    private func quizFinished(firstTry: Bool) {
        guard let source = quizSource else { return }
        quizSource = nil
        switch source {
        case .pop:
            let given = firstTry ? store.grantVillageBonus(1) : 0
            if given > 0 { Haptics.success(.star) }
            showNote(given > 0 ? "Bonus star! ⭐ +1" : (firstTry ? "Right on the first try! (You've got all of today's bonus stars.)" : "You figured it out! 🌟"))
            scene?.finishPopQuiz(happy: true)
        case .npc(let id):
            guard let def = VillageNPCDef.def(id), let speaker = scene?.npcCharacter(id) else { return }
            let firstSolve = store.solveVillageRiddle(id)
            if firstSolve { Haptics.success(.star) }
            let text = firstSolve ? def.thanksLine : (firstTry ? "Wow, first try! " : "You figured it out! ") + (def.chatter.randomElement() ?? "")
            say(VillageDialogue(speaker: speaker, text: text, choices: [
                .init(title: firstSolve ? "Yay! ⭐" : "Thanks!") { endTalk(happy: true) }
            ]))
        }
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
        case .coding: return .coding
        case .kindness: return .kindness
        }
    }

    // MARK: Little messages

    private func showBanner(_ text: String) {
        banner = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if banner == text { banner = nil }
        }
    }

    /// A message on screen. `speak: false` for little things (hellos, item counts) so the voice
    /// doesn't keep cutting itself off while walking around.
    private func showNote(_ text: String, speak: Bool = true) {
        note = text
        if speak { Narrator.shared.say(text) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            if note == text { note = nil }
        }
    }
}
