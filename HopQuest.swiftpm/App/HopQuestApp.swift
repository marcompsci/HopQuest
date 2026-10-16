import SwiftUI

@main
struct HopQuestApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

enum Route: Equatable {
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
    case balloon(next: Int?)
}

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @State private var route: Route = .map(landing: nil)
    @State private var sessionStart = Date()
    @State private var showBreak = false
    @State private var restTime = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var raceNonce = 0
    /// True when the child is playing from Hop Village, so "back" and balloon landings return there.
    @State private var homeIsVillage = false
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
        .animation(.easeInOut(duration: 0.35), value: route)
        .animation(.easeInOut(duration: 0.35), value: store.profile == nil)
        .onAppear {
            if store.profile?.village.startInVillage == true {
                homeIsVillage = true
                route = .village
            }
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
        case .map(let landing):
            WorldMapView(landing: landing,
                         onPlay: { chapter in play(chapter) },
                         onTeam: { route = .teamSetup },
                         onKart: { route = .kartSelect },
                         onBop: { route = .bop },
                         onFort: { route = .fortSelect },
                         onStickers: { route = .stickers },
                         onCastle: { route = .castle },
                         onVillage: {
                             homeIsVillage = true
                             route = .village
                         })
                .onAppear { homeIsVillage = false }

        case .village:
            HopVillageView(onOpen: { destination in
                               switch destination {
                               case .castle: route = .castle
                               case .stickers: route = .stickers
                               case .bop: route = .bop
                               case .fortSelect: route = .fortSelect
                               case .kartSelect: route = .kartSelect
                               case .chapter(let id): play(Chapters.chapter(id))
                               }
                           },
                           onMap: {
                               homeIsVillage = false
                               route = .map(landing: nil)
                           })
                .onAppear { homeIsVillage = true }

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

        case .castle:
            MyCastleView(onBack: goHome)

        case .stickers:
            StickerBookView(onBack: goHome)

        case .kartSelect:
            KartSelectView(onBack: goHome,
                           onStart: { cup in route = .playing(cup.id) })

        case .teamSetup:
            TeamSetupView(onBack: goHome,
                          onStart: { chapter in route = .playing(chapter.id) })

        case .playing(let id):
            let chapter = Chapters.chapter(id)
            let team = Chapters.isTeam(id)
            let exit: () -> Void = {
                if team { route = .teamSetup }
                else if chapter.kind == .kart { route = .kartSelect }
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
                                 store.complete(chapter: chapter.id, stars: stars)
                                 route = .codeClub
                             })
                    .id(id)
            }

        case .balloon(let next):
            BalloonFlightView(theme: store.theme, character: store.character) {
                // the balloon lands back where the child set off from: the village or the map
                route = homeIsVillage ? .village : .map(landing: next)
            }
        }
    }

    /// Racing music for driving and karts; the adventure theme everywhere else.
    private func updateMusic() {
        switch route {
        case .kartSelect, .bop:
            SoundFX.shared.playMusic(.race)
        case .playing(let id):
            let kind = Chapters.chapter(id).kind
            SoundFX.shared.playMusic(kind == .drive || kind == .kart ? .race : .adventure)
        default:
            SoundFX.shared.playMusic(.adventure)
        }
    }

    /// Back to wherever the child came from (Hop Village or the world map).
    private func goHome() {
        route = homeIsVillage ? .village : .map(landing: nil)
    }

    /// Opens a story chapter. Once the robot is built, the Robot Lab stop opens Code Club.
    private func play(_ chapter: Chapter) {
        if chapter.kind == .robot && store.state(of: chapter) == .done {
            route = .codeClub
        } else {
            route = .playing(chapter.id)
        }
    }

    private func finish(_ chapter: Chapter, stars: Int) {
        if !Chapters.isStory(chapter.id) {
            // Team play earns stars but doesn't move the story along.
            store.addStars(stars)
            route = .balloon(next: nil)
        } else {
            store.complete(chapter: chapter.id, stars: stars)
            route = .balloon(next: store.nextChapterID)
        }
    }
}
