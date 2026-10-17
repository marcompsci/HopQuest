import SwiftUI

@main
struct HopQuestApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var network = VillageNetwork()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(network)
                .preferredColorScheme(.light)
        }
    }
}

enum Route: Equatable {
    case menu
    case map(landing: Int?)
    case playing(Int)
    case teamSetup
    case kartSelect
    case bop
    case fortSelect
    case fort(Int)
    case stickers
    case castle
    case codeClub
    case village
    case codingLab
    case readingNook
    /// A story cutscene (by id); `afterStory` says where to go next.
    case story(String)
    case storyBook
    case scienceLab
    case mathMarket
    // two players on one phone
    case teamKartSelect
    case teamKart(Int)
    case teamBop
    case teamCode
    case teamFortSelect
    case teamFort(Int)
    /// A story world from data (Snowy Peaks).
    case world(String)
    case balloon(next: Int?)
}

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @State private var route: Route = .menu
    /// Where to go when the cutscene ends.
    @State private var afterStory: Route?
    @State private var sessionStart = Date()
    @State private var showBreak = false
    @State private var restTime = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var raceNonce = 0
    /// Where "back" and balloon landings return: the menu, the world map, or Hop Village.
    private enum Hub { case menu, map, village }
    @State private var hub: Hub = .menu
    @State private var castleNote: String?
    private let ticker = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if store.profile == nil {
                OnboardingView()
                    .transition(.opacity)
            } else {
                content
                    .transition(.opacity)
            }
            if showBreak {
                BreakView(name: store.profile?.name ?? "friend") {
                    showBreak = false
                    sessionStart = Date()
                }
                .transition(.opacity)
            }
            if restTime && store.profile != nil {
                RestTimeView {
                    restTime = false
                    sessionStart = Date()
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .overlay(alignment: .bottom) {
            if let castleNote {
                MessageBubble(text: castleNote).padding(.bottom, 40)
            }
        }
        .modifier(TabletFrame(sky: store.theme.sky))
        .animation(.easeInOut(duration: 0.35), value: route)
        .animation(.easeInOut(duration: 0.35), value: store.profile == nil)
        .onAppear {
            updateMusic()
            if store.timeIsUp { restTime = true }
        }
        .onChange(of: restTime) { _, resting in
            if resting {
                Narrator.shared.stop()
                SoundFX.shared.playMusic(.adventure)
            }
        }
        .onChange(of: route) { _, _ in updateMusic() }
        .onReceive(ticker) { _ in
            // daily play limit (counts only while the app is open and in front)
            if scenePhase == .active, store.profile != nil, !restTime, store.addPlayTime(20) {
                restTime = true
                return
            }
            guard let minutes = store.profile?.breakReminderMinutes, minutes > 0, !showBreak else { return }
            if Date().timeIntervalSince(sessionStart) >= Double(minutes * 60) {
                showBreak = true
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .menu:
            MainMenuView(onPlay: { hub = .village; route = .village },
                         onChapter: { chapter in play(chapter) },
                         onStickers: { route = .stickers },
                         onFort: { route = .fortSelect },
                         onBop: { route = .bop },
                         onKart: { route = .kartSelect },
                         onTeam: { route = .teamSetup },
                         onCastle: { openCastle() },
                         onCodingLab: { route = .codingLab },
                         onReading: { route = .readingNook },
                         onMarket: { route = .mathMarket },
                         onStories: { route = .storyBook },
                         onScience: { route = .scienceLab },
                         onMap: { hub = .map; route = .map(landing: nil) },
                         onWorld: { id in route = .world(id) })
                .onAppear { hub = .menu }

        case .map(let landing):
            WorldMapView(landing: landing,
                         onPlay: { chapter in play(chapter) },
                         onTeam: { route = .teamSetup },
                         onKart: { route = .kartSelect },
                         onBop: { route = .bop },
                         onFort: { route = .fortSelect },
                         onStickers: { route = .stickers },
                         onCastle: { openCastle() },
                         onVillage: {
                             hub = .village
                             route = .village
                         })
                .onAppear { hub = .map }

        case .village:
            HopVillageView(onOpen: { destination in
                               switch destination {
                               case .castle: route = .castle
                               case .stickers: route = .stickers
                               case .bop: route = .bop
                               case .fortSelect: route = .fortSelect
                               case .kartSelect: route = .kartSelect
                               case .together: route = .teamSetup
                               case .codingLab: route = .codingLab
                               case .readingNook: route = .readingNook
                               case .mathMarket: route = .mathMarket
                               case .chapter(let id): play(Chapters.chapter(id))
                               }
                           },
                           onMenu: {
                               hub = .menu
                               route = .menu
                           })
                .onAppear { hub = .village }

        case .bop:
            BopGameView(onExit: goHome) { stars, again in
                store.addStars(stars)
                if again {
                    raceNonce += 1
                } else {
                    route = .balloon(next: nil)
                }
            }
            .id("bop-\(raceNonce)")

        case .fortSelect:
            FortSelectView(onBack: goHome,
                           onStart: { level in route = .fort(level.id) })

        case .fort(let id):
            FortGameView(level: FortLevel.level(id), onExit: { route = .fortSelect }) { stars, balloons, again in
                store.addStars(stars)
                store.recordFort(level: id, balloons: balloons)
                if again {
                    raceNonce += 1
                } else {
                    route = .balloon(next: nil)
                }
            }
            .id("fort-\(id)-\(raceNonce)")

        case .codeClub:
            CodeClubView(onBack: goHome,
                         onEarn: { stars in store.addStars(stars) })

        case .codingLab:
            CodingLabView(onBack: goHome)

        case .readingNook:
            ReadingNookView(onBack: goHome)

        case .story(let id):
            if let scene = StoryBook.cutscene(id) {
                CutsceneView(scene: scene, character: store.character) {
                    // a fast double tap on Done mustn't skip where we were going
                    guard case .story(let current) = route, current == id else { return }
                    store.markStorySeen(id)
                    let next = afterStory
                    afterStory = nil
                    if let next { route = next } else { goHome() }
                }
            }

        case .storyBook:
            StoryBookView(onBack: goHome)

        case .scienceLab:
            ScienceLabView(onBack: goHome)

        case .mathMarket:
            MathMarketView(onBack: goHome)

        case .castle:
            MyCastleView(onBack: goHome)

        case .stickers:
            StickerBookView(onBack: goHome)

        case .kartSelect:
            KartSelectView(onBack: goHome,
                           onStart: { cup in route = .playing(cup.id) })

        case .teamSetup:
            TeamSetupView(onBack: goHome,
                          onStart: { chapter in route = .playing(chapter.id) },
                          onMode: { mode in
                              switch mode {
                              case .kart: route = .teamKartSelect
                              case .bop: route = .teamBop
                              case .code: route = .teamCode
                              case .fort: route = .teamFortSelect
                              }
                          })

        case .teamKartSelect:
            KartSelectView(onBack: { route = .teamSetup },
                           onStart: { cup in route = .teamKart(cup.id) })

        case .teamKart(let id):
            // two players earn stars together, but cup trophies stay a solo record
            KartGameView(chapter: Chapters.chapter(id), partner: store.coopCharacter, onExit: { route = .teamSetup }) { stars, _, again in
                store.addStars(stars)
                if again {
                    raceNonce += 1
                } else {
                    route = .balloon(next: nil)
                }
            }
            .id("teamkart-\(id)-\(raceNonce)")

        case .teamBop:
            BopGameView(partner: store.coopCharacter, onExit: { route = .teamSetup }) { stars, again in
                store.addStars(stars)
                if again {
                    raceNonce += 1
                } else {
                    route = .balloon(next: nil)
                }
            }
            .id("teambop-\(raceNonce)")

        case .teamFortSelect:
            FortSelectView(onBack: { route = .teamSetup },
                           onStart: { level in route = .teamFort(level.id) })

        case .teamFort(let id):
            // building together earns stars, but the balloon record stays the kid's own
            FortGameView(level: FortLevel.level(id), team: true, onExit: { route = .teamFortSelect }) { stars, _, again in
                store.addStars(stars)
                if again {
                    raceNonce += 1
                } else {
                    route = .balloon(next: nil)
                }
            }
            .id("teamfort-\(id)-\(raceNonce)")

        case .world(let id):
            if let w = Worlds.all.first(where: { $0.id == id }) {
                WorldView(world: w, onBack: goHome, onPlay: { chapter in route = .playing(chapter.id) })
            } else {
                Color.clear.onAppear { goHome() }
            }

        case .teamCode:
            CodeClubView(team: true, onBack: { route = .teamSetup },
                         onEarn: { stars in store.addStars(stars) })

        case .playing(let id):
            let chapter = Chapters.chapter(id)
            let team = Chapters.isTeam(id)
            let exit: () -> Void = {
                if team { route = .teamSetup }
                else if chapter.kind == .kart { route = .kartSelect }
                else if let w = Worlds.world(containing: chapter.id) { route = .world(w.id) }
                else { goHome() }
            }
            switch chapter.kind {
            case .hop:
                HopGameView(chapter: chapter, team: team, onExit: exit,
                            onComplete: { stars in finish(chapter, stars: stars) })
                    .id(id)
            case .drive:
                DriveGameView(chapter: chapter, team: team, onExit: exit,
                              onComplete: { stars in finish(chapter, stars: stars) })
                    .id(id)
            case .kart:
                KartGameView(chapter: chapter, onExit: exit) { stars, place, again in
                    store.addStars(stars)
                    store.recordKart(cup: chapter.id, place: place)
                    if again {
                        raceNonce += 1
                    } else {
                        route = .balloon(next: nil)
                    }
                }
                .id("\(id)-\(raceNonce)")
            case .robot:
                RobotLabView(onExit: exit,
                             onComplete: { stars in finish(chapter, stars: stars) },
                             onCodeClub: { stars in
                                 let firstTime = store.profile?.completedChapters.contains(chapter.id) == false
                                 store.complete(chapter: chapter.id, stars: stars)
                                 if firstTime, let scene = StoryBook.after(chapter: chapter.id), !store.hasSeenStory(scene.id) {
                                     afterStory = .codeClub
                                     route = .story(scene.id)
                                 } else {
                                     route = .codeClub
                                 }
                             })
                    .id(id)
            }

        case .balloon(let next):
            BalloonFlightView(theme: store.theme, character: store.character) {
                // the balloon lands back where the child set off from: the village or the map
                switch hub {
                case .village: route = .village
                case .menu: route = .menu
                case .map: route = .map(landing: next)
                }
            }
        }
    }

    /// Racing music for driving and karts; the adventure theme everywhere else.
    private func updateMusic() {
        switch route {
        case .kartSelect, .bop, .teamKartSelect, .teamKart, .teamBop:
            SoundFX.shared.playMusic(.race)
        case .playing(let id):
            let kind = Chapters.chapter(id).kind
            SoundFX.shared.playMusic(kind == .drive || kind == .kart ? .race : .adventure)
        default:
            SoundFX.shared.playMusic(.adventure)
        }
    }

    /// Back to wherever the child came from (the menu, Hop Village or the world map).
    private func goHome() {
        switch hub {
        case .village: route = .village
        case .menu: route = .menu
        case .map: route = .map(landing: nil)
        }
    }

    /// My Castle opens once every Hop Village challenge is done.
    private func openCastle() {
        if store.castleOpen {
            route = .castle
        } else {
            let text = "Your castle opens after all \(ChallengeProgress.total) Hop Village challenges. You've done \(store.challengeProgress.doneCount)! 🏆"
            castleNote = text
            Narrator.shared.say(text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { if castleNote == text { castleNote = nil } }
        }
    }

    /// Opens a story chapter. Once the robot is built, the Robot Lab stop opens Code Club.
    private func play(_ chapter: Chapter) {
        if chapter.id == 1 && !store.hasSeenStory(StoryBook.intro.id) && store.profile?.completedChapters.isEmpty == true {
            // the very first level starts with the story's invitation
            afterStory = .playing(chapter.id)
            route = .story(StoryBook.intro.id)
            return
        }
        if chapter.kind == .robot && store.state(of: chapter) == .done {
            route = .codeClub
        } else {
            route = .playing(chapter.id)
        }
    }

    private func finish(_ chapter: Chapter, stars: Int) {
        let firstTime = store.profile?.completedChapters.contains(chapter.id) == false
        let next: Route
        if Chapters.isWorldChapter(chapter.id) {
            // Snowy Peaks and later worlds: saved as finished, then back to the world screen
            store.complete(chapter: chapter.id, stars: stars)
            if let w = Worlds.world(containing: chapter.id) { next = .world(w.id) } else { next = .balloon(next: nil) }
        } else if !Chapters.isStory(chapter.id) {
            // Team play earns stars but doesn't move the story along.
            store.addStars(stars)
            route = .balloon(next: nil)
            return
        } else {
            store.complete(chapter: chapter.id, stars: stars)
            next = .balloon(next: store.nextChapterID)
        }
        // the first time a story level is finished, its cutscene plays before moving on
        if firstTime, let scene = StoryBook.after(chapter: chapter.id), !store.hasSeenStory(scene.id) {
            afterStory = next
            route = .story(scene.id)
        } else {
            route = next
        }
    }
}
