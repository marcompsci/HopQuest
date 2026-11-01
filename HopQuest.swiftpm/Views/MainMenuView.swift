import SwiftUI

/// The main menu: a big PLAY button into Hop Village, and every game in one place
/// (the six adventures, Stickers, Fort Friends, Pillow Bop, Bubble Kart, Together, My Castle and the map).
struct MainMenuView: View {
    @EnvironmentObject var store: GameStore
    var onPlay: () -> Void
    var onChapter: (Chapter) -> Void
    var onStickers: () -> Void
    var onFort: () -> Void
    var onBop: () -> Void
    var onKart: () -> Void
    var onTeam: () -> Void
    var onCastle: () -> Void
    var onCodingLab: () -> Void
    var onReading: () -> Void = {}
    var onMarket: () -> Void = {}
    var onStories: () -> Void = {}
    var onScience: () -> Void = {}
    var onMusic: () -> Void = {}
    var onWriting: () -> Void = {}
    var onClock: () -> Void = {}
    var onWorldTour: () -> Void = {}
    var onQuickGame: () -> Void = {}
    var onQuizPlace: (String) -> Void = { _ in }
    var onStoryMaker: () -> Void = {}
    var onBadges: () -> Void = {}
    var onStarHop: () -> Void = {}
    var onBreathe: () -> Void = {}
    /// Surprise Me: opens a learning place by id.
    var onSurprise: (String) -> Void = { _ in }
    var onMap: () -> Void
    /// Opens a story world from data (Snowy Peaks).
    var onWorld: (String) -> Void = { _ in }

    @State private var showParent = false
    @State private var showCharacters = false
    @State private var bounce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var note: String?
    @Environment(\.scenePhase) private var scenePhase

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    playButton
                        .padding(.top, 6)
                    surpriseButton
                    section("Adventures")
                        .padding(.top, 10)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Chapters.all) { chapter in chapterTile(chapter) }
                    }
                    section("Games")
                        .padding(.top, 10)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        let packs = store.packsAvailable
                        gameTile(art: "icon_stickers", title: "Stickers", color: Color(hex: 0xFF9F45), shadow: Color(hex: 0xD9731C),
                                 badge: packs, label: packs > 0 ? "Sticker Book, \(packs) new packs" : "Sticker Book", action: onStickers)
                        gameTile(art: "icon_fort", title: "Fort Friends", color: Color(hex: 0x34C77B), shadow: Color(hex: 0x239A5C),
                                 badge: 0, label: "Fort Friends building game", action: onFort)
                        gameTile(art: "icon_bop", title: "Pillow Bop", color: Color(hex: 0xB983FF), shadow: Palette.purple,
                                 badge: 0, label: "Pillow Bop party game", action: onBop)
                        gameTile(art: "icon_kart", title: "Bubble Kart", color: Color(hex: 0xFF7A59), shadow: Color(hex: 0xC2410C),
                                 badge: 0, label: "Bubble Kart racing", action: onKart)
                        gameTile(art: "icon_dash", title: "Star Dash", color: Color(hex: 0x4D7CFF), shadow: Color(hex: 0x2F55C7),
                                 badge: 0, detail: (store.profile?.quick.best ?? 0) > 0 ? "Best \(store.profile?.quick.best ?? 0)" : "1-minute quick game",
                                 label: "Star Dash, a one-minute quick game", action: onQuickGame)
                        gameTile(art: "icon_starhop", title: "Star Hop", color: Color(hex: 0x5B4BC4), shadow: Color(hex: 0x3B2F8C),
                                 badge: 0, detail: "\(SharedStore.loadHop().levelsCleared) of \(StarHop.levels.count) levels",
                                 label: "Star Hop, \(SharedStore.loadHop().levelsCleared) of \(StarHop.levels.count) levels", action: onStarHop)
                        gameTile(art: "icon_breathe", title: "Breathe", color: Color(hex: 0x4A9EDB), shadow: Color(hex: 0x2F74A8),
                                 badge: 0, detail: "Calm breaths with your buddy",
                                 label: "Breathe with Buddy, a calm break", action: onBreathe)
                    }
                    section("Learn")
                        .padding(.top, 10)
                    codingLabCard
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        let p = store.profile
                        gameTile(art: "icon_reading", title: "Reading Nook", color: Color(hex: 0xD94A57), shadow: Color(hex: 0x9E2A3A),
                                 badge: 0, detail: "\(p?.reading.totalStars ?? 0) of \(ReadingSave.maxStars) stars",
                                 label: "Reading Nook, \(p?.reading.totalStars ?? 0) of \(ReadingSave.maxStars) stars", action: onReading)
                        gameTile(art: "icon_market", title: "Math Market", color: Color(hex: 0xE07B00), shadow: Color(hex: 0xA35A00),
                                 badge: 0, detail: "\(p?.market.totalStars ?? 0) of \(MarketSave.maxStars) stars",
                                 label: "Math Market, \(p?.market.totalStars ?? 0) of \(MarketSave.maxStars) stars", action: onMarket)
                        gameTile(art: "icon_science", title: "Science Lab", color: Color(hex: 0x1F7A8C), shadow: Color(hex: 0x135563),
                                 badge: 0, detail: "\(p?.science.totalStars ?? 0) of \(ScienceSave.maxStars) stars",
                                 label: "Science Lab, \(p?.science.totalStars ?? 0) of \(ScienceSave.maxStars) stars", action: onScience)
                        gameTile(art: "icon_music", title: "Music Maker", color: Color(hex: 0xB0459C), shadow: Color(hex: 0x7E2C6F),
                                 badge: 0, detail: "\(p?.music.totalStars ?? 0) of \(MusicSave.maxStars) stars",
                                 label: "Music Maker, \(p?.music.totalStars ?? 0) of \(MusicSave.maxStars) stars", action: onMusic)
                        gameTile(art: "icon_writing", title: "Writing Desk", color: Color(hex: 0x2F6FD1), shadow: Color(hex: 0x1D4A96),
                                 badge: 0, detail: "\(p?.writing.totalStars ?? 0) of \(WritingSave.maxStars) stars",
                                 label: "Writing Desk, \(p?.writing.totalStars ?? 0) of \(WritingSave.maxStars) stars", action: onWriting)
                        gameTile(art: "icon_clock", title: "Clock Tower", color: Color(hex: 0x2E7D4F), shadow: Color(hex: 0x1D5434),
                                 badge: 0, detail: "\(p?.clock.totalStars ?? 0) of \(ClockSave.maxStars) stars",
                                 label: "Clock Tower, \(p?.clock.totalStars ?? 0) of \(ClockSave.maxStars) stars", action: onClock)
                        gameTile(art: "icon_world", title: "Around the World", color: Color(hex: 0x5B4BC4), shadow: Color(hex: 0x3B2F8C),
                                 badge: 0, detail: "\(p?.world.postcards.count ?? 0) of 7 postcards",
                                 label: "Around the World, \(p?.world.postcards.count ?? 0) of 7 postcards", action: onWorldTour)
                        placeTile("spelling", art: "icon_spelling", title: "Spelling Bee", color: 0xB7791F, shadow: 0x8A5A12)
                        placeTile("fractions", art: "icon_fractions", title: "Fraction Bakery", color: 0xC2185B, shadow: 0x8E1243)
                        placeTile("shapes", art: "icon_shapes", title: "Shape Studio", color: 0x00796B, shadow: 0x00564C)
                        placeTile("rhyme", art: "icon_rhyme", title: "Rhyme Pond", color: 0x2E8B3E, shadow: 0x1E5E29)
                        placeTile("numbers", art: "icon_numbers", title: "Number Builder", color: 0x6A3FB5, shadow: 0x482A7D)
                        placeTile("times", art: "icon_times", title: "Times Treehouse", color: 0x8A5A2B, shadow: 0x5E3D1D)
                        placeTile("measure", art: "icon_measure", title: "Measure Meadow", color: 0x2F6F9F, shadow: 0x1F4B6C)
                        placeTile("feelings", art: "icon_feelings", title: "Feelings Corner", color: 0xC2185B, shadow: 0x8E1243)
                        gameTile(art: "icon_story", title: "Story Maker", color: Color(hex: 0x6A4C93), shadow: Color(hex: 0x4A3368),
                                 badge: 0, detail: "\(store.profile?.storyMaker.stories.count ?? 0) stories",
                                 label: "Story Maker, \(store.profile?.storyMaker.stories.count ?? 0) stories", action: onStoryMaker)
                    }
                    section("Worlds")
                        .padding(.top, 10)
                    ForEach(Worlds.all) { w in worldCard(w) }
                    badgesCard
                    castleCard
                    HStack(spacing: 12) {
                        smallButton(icon: "map.fill", title: "Adventure Map", action: onMap)
                        smallButton(icon: "person.2.fill", title: "Together", action: onTeam)
                        smallButton(icon: "book.fill", title: "Stories", action: onStories)
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }

            if let note {
                VStack {
                    Spacer()
                    MessageBubble(text: note).padding(.bottom, 30)
                }
                .animation(.spring(), value: note)
            }
        }
        // stars earned in Star Hop on the home-screen widget arrive here
        .onAppear { collectHopStars() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { collectHopStars() } }
        // The sky, land and season drift sit behind the content, so the big land picture
        // can never stretch the layout past the screen and push the header under the clock.
        .background {
            ZStack {
                LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom)
                if let land = ArtLibrary.image("map_bg") {
                    Color.clear.overlay(
                        Image(uiImage: land).resizable().scaledToFill().opacity(0.55)
                    )
                    .clipped()
                }
                if let hex = Season.shown?.driftTintHex {
                    // the season drifts by: spring petals, autumn leaves, winter snow
                    SnowfallView(tint: Color(hex: hex)).accessibilityHidden(true)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
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

    // MARK: Pieces

    /// The greeting sits straight on the sky: buddy, name, a star count, and the grown-ups button.
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button { showCharacters = true } label: {
                BuddyAvatar(character: store.character, hat: store.profile?.hat ?? .none, size: 50)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.regularMaterial))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Palette.purple))
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Change your buddy")

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr("Hi, \(displayName)!"))
                    .font(.kid(26, .black))
                    .displayTracking(26)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 5) {
                    ArtImage("goal_star").frame(width: 18, height: 18)
                    Text("\(store.profile?.stars ?? 0)").monospacedDigit()
                    Text(L10n.isSpanish ? "estrellas" : "stars").foregroundStyle(Palette.ink.opacity(0.55))
                }
                .font(.kid(15, .bold))
                .foregroundStyle(Palette.ink)
                .padding(.leading, 8).padding(.trailing, 10).padding(.vertical, 4)
                .background(Capsule().fill(.regularMaterial))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(store.profile?.stars ?? 0) stars")
            }

            Spacer(minLength: 8)

            Button { showParent = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Palette.ink.opacity(0.75))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.regularMaterial))
                    .overlay(alignment: .topTrailing) {
                        // a quiet dot for grown-ups: a milestone note is waiting behind the gate
                        if !store.pendingMilestones.isEmpty {
                            Circle().fill(Palette.red).frame(width: 11, height: 11)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel(store.pendingMilestones.isEmpty ? "Grown-ups" : "Grown-ups, a milestone note is ready")
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }

    /// Names are shown as typed, but an all-caps name ("MAR") reads as shouting, so it's softened to "Mar".
    private var displayName: String {
        let n = (store.profile?.name ?? "friend").trimmingCharacters(in: .whitespaces)
        guard n.count > 1, n == n.uppercased(), n.rangeOfCharacter(from: .letters) != nil else { return n }
        return String(n.prefix(1)) + n.dropFirst().lowercased()
    }

    /// The big way into Hop Village: what it is, and how far along the castle is.
    private var playButton: some View {
        let progress = store.challengeProgress
        let left = ChallengeProgress.total - progress.doneCount
        return Button {
            Haptics.success(.whoosh)
            onPlay()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Color(hex: 0x1F8F55))
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(.white))
                        .offset(x: 2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.tr("Play")).font(.kid(36, .black)).displayTracking(36)
                        Text(L10n.tr("Hop Village")).font(.kid(17, .bold)).opacity(0.85)
                    }
                    Spacer(minLength: 0)
                    ArtImage("village_castle_\(store.theme.rawValue)")
                        .frame(width: 92, height: 92)
                        .opacity(progress.allDone ? 1 : 0.92)
                        .offset(y: bounce ? -3 : 0)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill").font(.system(size: 13, weight: .bold))
                        Text(L10n.tr("\(progress.doneCount) of \(ChallengeProgress.total) challenges")).monospacedDigit()
                    }
                    .font(.kid(14, .bold))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.28))
                            Capsule().fill(.white)
                                .frame(width: max(10, geo.size.width * CGFloat(progress.doneCount) / CGFloat(ChallengeProgress.total)))
                        }
                    }
                    .frame(height: 8)
                    Text(L10n.tr(progress.allDone ? "Your castle is open!" : "\(left) more to open your castle"))
                        .font(.kid(13, .semibold)).opacity(0.8)
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x34C77B))
                .shadow(color: Color(hex: 0x239A5C), radius: 0, x: 0, y: 6))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Play Hop Village. \(progress.doneCount) of \(ChallengeProgress.total) challenges done.")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bounce = true }
        }
    }

    private func section(_ title: String) -> some View {
        HStack {
            Text(L10n.tr(title)).font(.kid(20, .black)).tracking(-0.3).foregroundStyle(Palette.ink)
            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }

    private func art(for chapter: Chapter) -> String {
        switch chapter.id {
        case 1: return "level_meadow"
        case 2: return "level_driving"
        case 3: return "level_robot"
        case 4: return "level_lily"
        case 5: return "level_rally"
        default: return "level_castle"
        }
    }

    private func chapterTile(_ chapter: Chapter) -> some View {
        let state = store.state(of: chapter)
        let title = chapter.kind == .robot && state == .done ? "Code Club" : chapter.title
        return Button {
            guard state != .locked else {
                Haptics.bump(.oops)
                showNote("\(chapter.title) opens later. Next up: \(Chapters.chapter(store.nextChapterID).title)!")
                return
            }
            Haptics.tap()
            onChapter(chapter)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(state == .locked ? Color(hex: 0xEDEFF3) : .white)
                        .frame(width: 74, height: 74)
                        .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4)
                    ArtImage(art(for: chapter))
                        .frame(width: 54, height: 54)
                        .saturation(state == .locked ? 0 : 1)
                        .opacity(state == .locked ? 0.45 : 1)
                    if state == .locked {
                        ArtImage("level_lock").frame(width: 28, height: 28).offset(x: 25, y: 24)
                    }
                    if state == .done {
                        ArtImage("goal_star").frame(width: 28, height: 28).offset(x: 26, y: -26)
                    }
                }
                .overlay(Circle().stroke(store.theme.accent, lineWidth: state == .open ? 5 : 0).frame(width: 74, height: 74))
                Text(title)
                    .font(.kid(13, .black))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.75)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(title), \(state == .locked ? "locked" : state == .done ? "finished" : "ready to play")")
    }

    private func gameTile(art: String, title: String, color: Color, shadow: Color, badge: Int, detail: String? = nil, label: String,
                          action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 4) {
                ArtImage(art).frame(width: 64, height: 64)
                Text(L10n.tr(title)).font(.kid(18, .black)).lineLimit(1).minimumScaleFactor(0.7)
                if let detail {
                    Text(L10n.tr(detail)).font(.kid(12, .semibold)).opacity(0.85).monospacedDigit()
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 22).fill(color).shadow(color: shadow, radius: 0, x: 0, y: 5))
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text("\(badge)")
                        .font(.kid(15, .black))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Palette.red))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: 6, y: -8)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }

    private func placeTile(_ id: String, art: String, title: String, color: UInt32, shadow: UInt32) -> some View {
        let stars = store.profile?.places[id]?.totalStars ?? 0
        return gameTile(art: art, title: title, color: Color(hex: color), shadow: Color(hex: shadow), badge: 0,
                        detail: "\(stars) of 12 stars", label: "\(title), \(stars) of 12 stars") { onQuizPlace(id) }
    }

    /// The badges wall: a row of the latest badges earned.
    private var badgesCard: some View {
        let earned = Badges.earned(store.badgeInput)
        return Button { Haptics.tap(); onBadges() } label: {
            HStack(spacing: 12) {
                Image(systemName: "rosette").font(.system(size: 26, weight: .bold)).foregroundStyle(Color(hex: 0xE0A800))
                    .frame(width: 48, height: 48).background(Circle().fill(Color(hex: 0xFFF4C2)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr("Badges")).font(.kid(19, .black)).foregroundStyle(Palette.ink)
                    Text(L10n.tr("\(earned.count) of \(Badges.all.count) earned")).font(.kid(13, .semibold)).foregroundStyle(Palette.ink.opacity(0.6)).monospacedDigit()
                }
                Spacer()
                HStack(spacing: -10) {
                    ForEach(earned.suffix(4)) { b in
                        Image(systemName: b.symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 30, height: 30).background(Circle().fill(Color(hex: b.colorHex)))
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.35))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.9))
                .shadow(color: Palette.ink.opacity(0.1), radius: 0, x: 0, y: 4))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Badges, \(earned.count) of \(Badges.all.count) earned")
    }

    private var codingLabCard: some View {
        let done = store.profile?.codeLab.completed.count ?? 0
        return Button {
            Haptics.tap()
            onCodingLab()
        } label: {
            HStack(spacing: 14) {
                ArtImage("icon_code").frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coding Lab").font(.kid(22, .black))
                    Text("Web pages, Python and games")
                        .font(.kid(14, .semibold)).opacity(0.85)
                    Text("\(done) of \(CodeCurriculum.lessons.count) lessons")
                        .font(.kid(12, .semibold)).opacity(0.7).monospacedDigit()
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0x3A2E6E))
                .shadow(color: Color(hex: 0x1E1B2E), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Coding Lab: \(done) of \(CodeCurriculum.lessons.count) lessons done")
    }

    /// A story world from data, like Snowy Peaks. Opens after its unlock chapter.
    private func worldCard(_ w: WorldDef) -> some View {
        let open = store.isUnlocked(w)
        let done = w.chapters.filter { store.profile?.completedChapters.contains($0.id) == true }.count
        let unlockTitle = Chapters.chapter(w.unlockAfter).title
        let tint = Color(hex: UInt32(w.color, radix: 16) ?? 0x4D96FF)
        return Button {
            if open {
                Haptics.tap()
                onWorld(w.id)
            } else {
                Haptics.bump(.oops)
                showNote("\(w.title) opens after you finish \(unlockTitle). 🔒")
            }
        } label: {
            HStack(spacing: 14) {
                Text(w.icon).font(.system(size: 50))
                    .frame(width: 90, height: 70)
                    .saturation(open ? 1 : 0.2)
                    .overlay(alignment: .bottomTrailing) {
                        if !open { ArtImage("level_lock").frame(width: 32, height: 32) }
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(w.title).font(.kid(22, .black))
                    Text(open ? "\(done) of \(w.chapters.count) levels done" : "Opens after \(unlockTitle)")
                        .font(.kid(14, .bold)).opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 24).fill(open ? tint : Color(hex: 0x9AA6B8))
                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(open ? "\(w.title), \(done) of \(w.chapters.count) levels done" : "\(w.title), locked until you finish \(unlockTitle)")
    }

    private var castleCard: some View {
        let progress = store.challengeProgress
        let open = progress.allDone
        return Button {
            if open {
                Haptics.tap()
                onCastle()
            } else {
                Haptics.bump(.oops)
                showNote("Finish all \(ChallengeProgress.total) Hop Village challenges to open your castle. You've done \(progress.doneCount)!")
            }
        } label: {
            HStack(spacing: 14) {
                CastleView(theme: store.theme, width: 90)
                    .saturation(open ? 1 : 0.3)
                    .overlay(alignment: .bottomTrailing) {
                        if !open { ArtImage("level_lock").frame(width: 32, height: 32) }
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text("🏠 My Castle").font(.kid(22, .black))
                    Text(open ? "Decorate your room and visit your buddies"
                              : "Opens after all \(ChallengeProgress.total) challenges (\(progress.doneCount) done)")
                        .font(.kid(14, .bold)).opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 24).fill(open ? Palette.purple : Color(hex: 0x9A8FB8))
                .shadow(color: Color(hex: 0x5B32D6), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(open ? "My Castle" : "My Castle, locked. \(progress.doneCount) of \(ChallengeProgress.total) challenges done.")
    }

    private func smallButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(L10n.tr(title)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .font(.kid(17, .black))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.9)))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func collectHopStars() {
        let n = store.collectHopStars()
        guard n > 0 else { return }
        Haptics.success()
        showNote(n == 1 ? "You earned 1 star in Star Hop!" : "You earned \(n) stars in Star Hop!")
    }

    /// Surprise Me: one tap to a learning place with something still to finish.
    private var surpriseButton: some View {
        Button {
            Haptics.tap()
            if let id = store.surprisePlace() {
                onSurprise(id)
            } else {
                showNote("You've finished every game! Pick any one you like.")
            }
        } label: {
            HStack(spacing: 12) {
                ArtImage("icon_surprise").frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.tr("Surprise me!")).font(.kid(19, .black)).foregroundStyle(Palette.ink)
                    Text(L10n.tr("Pick something new to learn")).font(.kid(13, .semibold)).foregroundStyle(Palette.ink.opacity(0.6))
                }
                Spacer()
                Image(systemName: "shuffle").font(.system(size: 18, weight: .black)).foregroundStyle(Palette.purple)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.9)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Surprise me! Pick something new to learn")
    }

    private func showNote(_ text: String) {
        note = text
        Narrator.shared.say(text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if note == text { note = nil }
        }
    }
}
