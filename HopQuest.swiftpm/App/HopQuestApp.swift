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
    case stickers
    case balloon(next: Int?)
}

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @State private var route: Route = .map(landing: nil)
    @State private var sessionStart = Date()
    @State private var showBreak = false
    @State private var raceNonce = 0
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
        }
        .animation(.easeInOut(duration: 0.35), value: route)
        .animation(.easeInOut(duration: 0.35), value: store.profile == nil)
        .onAppear { updateMusic() }
        .onChange(of: route) { _, _ in updateMusic() }
        .onReceive(ticker) { _ in
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
                         onPlay: { chapter in route = .playing(chapter.id) },
                         onTeam: { route = .teamSetup },
                         onKart: { route = .kartSelect },
                         onBop: { route = .bop },
                         onStickers: { route = .stickers })

        case .bop:
            BopGameView(onExit: { route = .map(landing: nil) }) { stars, again in
                store.addStars(stars)
                if again {
                    raceNonce += 1
                } else {
                    route = .balloon(next: nil)
                }
            }
            .id("bop-\(raceNonce)")

        case .stickers:
            StickerBookView(onBack: { route = .map(landing: nil) })

        case .kartSelect:
            KartSelectView(onBack: { route = .map(landing: nil) },
                           onStart: { cup in route = .playing(cup.id) })

        case .teamSetup:
            TeamSetupView(onBack: { route = .map(landing: nil) },
                          onStart: { chapter in route = .playing(chapter.id) })

        case .playing(let id):
            let chapter = Chapters.chapter(id)
            let team = Chapters.isTeam(id)
            let exit: () -> Void = {
                if team { route = .teamSetup }
                else if chapter.kind == .kart { route = .kartSelect }
                else { route = .map(landing: nil) }
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
                             onComplete: { stars in finish(chapter, stars: stars) })
                    .id(id)
            }

        case .balloon(let next):
            BalloonFlightView(theme: store.theme, character: store.character) {
                route = .map(landing: next)
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
