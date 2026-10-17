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
    var onMap: () -> Void
    /// Opens a story world from data (Snowy Peaks).
    var onWorld: (String) -> Void = { _ in }

    @State private var showParent = false
    @State private var showCharacters = false
    @State private var bounce = false
    @State private var note: String?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let land = ArtLibrary.image("map_bg") {
                Image(uiImage: land).resizable().scaledToFill().ignoresSafeArea().opacity(0.55).allowsHitTesting(false)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    playButton
                    section("Adventures")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Chapters.all) { chapter in chapterTile(chapter) }
                    }
                    section("Games")
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
                    }
                    codingLabCard
                    learnCard(icon: "📚", title: "Reading Nook",
                              subtitle: "Letter sounds, spelling, sight words, rhymes and sentences · \(store.profile?.reading.totalStars ?? 0)/\(ReadingSave.maxStars) ⭐",
                              color: 0xD94A57, shadow: 0x9E2A3A, action: onReading)
                    learnCard(icon: "🛒", title: "Math Market",
                              subtitle: "Count coins, pay, make change and compare prices · \(store.profile?.market.totalStars ?? 0)/\(MarketSave.maxStars) ⭐",
                              color: 0xE07B00, shadow: 0xA35A00, action: onMarket)
                    learnCard(icon: "🔬", title: "Science Lab",
                              subtitle: "Sink or float, magnets, plants, weather, solids and liquids · \(store.profile?.science.totalStars ?? 0)/\(ScienceSave.maxStars) ⭐",
                              color: 0x1F7A8C, shadow: 0x135563, action: onScience)
                    ForEach(Worlds.all) { w in worldCard(w) }
                    castleCard
                    HStack(spacing: 12) {
                        smallButton(icon: "map.fill", title: "Adventure Map", action: onMap)
                        smallButton(icon: "person.2.fill", title: "Together", action: onTeam)
                        smallButton(icon: "book.fill", title: "Stories", action: onStories)
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            if let note {
                VStack {
                    Spacer()
                    MessageBubble(text: note).padding(.bottom, 30)
                }
                .animation(.spring(), value: note)
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

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 10) {
            Button { showCharacters = true } label: {
                CharacterBadge(character: store.character, size: 52)
                    .background(Circle().fill(.white.opacity(0.9)))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Change your buddy")

            VStack(alignment: .leading, spacing: 0) {
                Text("Hi, \(store.profile?.name ?? "friend")!")
                    .font(.kid(22, .black))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 4) {
                    ArtImage("goal_star").frame(width: 20, height: 20)
                    Text("\(store.profile?.stars ?? 0) stars")
                }
                .font(.kid(16, .bold))
                .foregroundStyle(Palette.purple)
            }
            Spacer()
            CircleIconButton(systemName: "gearshape.fill", label: "Grown-ups") { showParent = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.8)))
    }

    private var playButton: some View {
        let progress = store.challengeProgress
        return Button {
            Haptics.success(.whoosh)
            onPlay()
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 14) {
                    CharacterBadge(character: store.character, size: 70)
                        .offset(y: bounce ? -6 : 0)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill").font(.system(size: 30, weight: .black))
                            Text("PLAY").font(.kid(44, .black))
                        }
                        Text("Hop Village").font(.kid(20, .black)).opacity(0.95)
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 6) {
                    Text("🏆 \(progress.doneCount)/\(ChallengeProgress.total) challenges")
                    Spacer()
                    Text(progress.allDone ? "Castle open! 🏰" : "Finish all to open your castle")
                }
                .font(.kid(13, .bold))
                .opacity(0.95)
                ProgressView(value: Double(progress.doneCount), total: Double(ChallengeProgress.total))
                    .tint(.white)
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color(hex: 0x34C77B))
                .shadow(color: Color(hex: 0x239A5C), radius: 0, x: 0, y: 7))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.white, lineWidth: 4))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Play Hop Village. \(progress.doneCount) of \(ChallengeProgress.total) challenges done.")
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { bounce = true }
        }
    }

    private func section(_ title: String) -> some View {
        HStack {
            Text(title).font(.kid(20, .black)).foregroundStyle(Palette.ink)
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

    private func gameTile(art: String, title: String, color: Color, shadow: Color, badge: Int, label: String,
                          action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 4) {
                ArtImage(art).frame(width: 64, height: 64)
                Text(title).font(.kid(18, .black)).lineLimit(1).minimumScaleFactor(0.7)
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

    private var codingLabCard: some View {
        let done = store.profile?.codeLab.completed.count ?? 0
        return Button {
            Haptics.tap()
            onCodingLab()
        } label: {
            HStack(spacing: 14) {
                Text("💻").font(.system(size: 44))
                    .frame(width: 70, height: 70)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.2)))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coding Lab").font(.kid(22, .black))
                    Text("Build web pages, Python programs and games · \(done)/\(CodeCurriculum.lessons.count) lessons")
                        .font(.kid(14, .bold)).opacity(0.9)
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

    /// A learning place from the village (Reading Nook, Math Market) as a big menu card.
    private func learnCard(icon: String, title: String, subtitle: String, color: UInt32, shadow: UInt32, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Text(icon).font(.system(size: 44))
                    .frame(width: 70, height: 70)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.2)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.kid(22, .black))
                    Text(subtitle).font(.kid(14, .bold)).opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: color))
                .shadow(color: Color(hex: shadow), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(title): \(subtitle)")
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
                Text(title).lineLimit(1).minimumScaleFactor(0.6)
            }
            .font(.kid(17, .black))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.9)))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func showNote(_ text: String) {
        note = text
        Narrator.shared.say(text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if note == text { note = nil }
        }
    }
}
