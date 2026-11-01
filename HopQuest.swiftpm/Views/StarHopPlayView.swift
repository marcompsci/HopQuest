import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Star Hop inside the app (v7.4): the same game as the home-screen widget, full screen, sharing its save,
/// so kids without the widget (or on iPad) can play, and a game started on the widget carries on here.
struct StarHopPlayView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var h = SharedStore.loadHop()
    @State private var showLevels = false

    private var ink: Color { h.info.night ? .white : Palette.ink }
    private var accent: Color { h.info.night ? Color(hop: 0xFFD84D) : Palette.purple }

    var body: some View {
        ZStack {
            HopSky(level: h.info).ignoresSafeArea()
            VStack(spacing: 10) {
                topBar
                progressRow
                ZStack {
                    board
                        .overlay(alignment: .top) { messageLine }
                    if h.playing { tapZones }
                }
                .frame(maxHeight: 460)
                Text(L10n.tr("Tap left to step. Tap right to jump, and again to double jump!"))
                    .font(.kid(14, .bold)).foregroundStyle(ink.opacity(0.7)).multilineTextAlignment(.center)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.top, 8)

            if h.champion {
                card(title: HopWords.tr("You beat all \(StarHop.levels.count) levels! 🏆", L10n.isSpanish), detail: "\(h.totalRating) of \(StarHop.levels.count * 3) stars",
                     rating: h.lastRating, button: "Play again") { act { $0.newGame() } }
            } else if h.levelDone {
                card(title: HopWords.tr("Level \(h.level) done!", L10n.isSpanish),
                     detail: HopWords.tr("Next: \(StarHop.levels[min(h.level, StarHop.levels.count - 1)].title)", L10n.isSpanish),
                     rating: h.lastRating, button: "Next level") { act { $0.nextLevel() } }
            } else if h.outOfHearts {
                card(title: "Out of hearts!", detail: "The puff clouds got you. You can do it!", rating: nil, button: "Try again") { act { $0.retry() } }
            }
        }
        .foregroundStyle(ink)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.25), value: h.turn)
        .animation(Motion.present, value: h.levelDone)
        .animation(Motion.present, value: h.outOfHearts)
        .sheet(isPresented: $showLevels) { levelPicker }
        .onAppear {
            h = SharedStore.loadHop()
            Narrator.shared.say(spokenGoal)
        }
        .onDisappear { Narrator.shared.stop() }
    }

    // MARK: Playing

    private func act(_ change: (inout StarHop) -> Void) {
        let before = h
        change(&h)
        SharedStore.save(h)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "HopQuestStarHop")
        #endif
        if h.levelDone && !before.levelDone {
            Haptics.success()
            Narrator.shared.say(h.champion ? "You beat every level!" : "Level \(h.level) done! \(h.lastRating) stars!")
        } else if h.bumped {
            Haptics.tap()
            Narrator.shared.say(h.outOfHearts ? "Out of hearts! Try again." : "Bonk! A puff cloud.")
        } else if h.collected > before.collected {
            Haptics.tap()
            Narrator.shared.say(h.needed != nil || h.prompt != nil ? spokenGoal : "Got it!")
        } else if h.level != before.level || (before.levelDone && !h.levelDone) || (before.outOfHearts && h.playing) {
            Narrator.shared.say(spokenGoal)
        }
    }

    /// What to find next, said out loud for kids who are still learning to read.
    private var spokenGoal: String {
        if let q = h.prompt { return "What is \(q.replacingOccurrences(of: "−", with: "minus").replacingOccurrences(of: "+", with: "plus"))?" }
        if let n = h.needed { return h.word != nil && h.collected == 0 ? "Spell \(h.word!.lowercased()). Find \(n)." : "Find \(n)." }
        return h.info.tip
    }

    private var tapZones: some View {
        HStack(spacing: 0) {
            Button { act { $0.left() } } label: { zone("chevron.left", "Step") }
                .buttonStyle(.plain)
                .accessibilityLabel("Step left")
            Button { act { $0.right() } } label: { zone("arrow.up.right", h.row > 0 && h.jumps == 1 ? "Double jump" : "Jump") }
                .buttonStyle(.plain)
                .accessibilityLabel(h.row > 0 && h.jumps == 1 ? "Double jump" : "Jump")
        }
    }

    private func zone(_ icon: String, _ label: String) -> some View {
        Rectangle().fill(.clear).contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Label(L10n.tr(label), systemImage: icon).font(.kid(14, .black)).foregroundStyle(ink.opacity(0.5)).padding(.bottom, 4)
            }
    }

    // MARK: Top

    private var topBar: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
            VStack(alignment: .leading, spacing: 0) {
                Text("Star Hop · \(L10n.tr("Level")) \(h.level)").font(.kid(13, .bold)).foregroundStyle(ink.opacity(0.65))
                Text(HopWords.tr(h.info.title, L10n.isSpanish)).font(.kid(22, .black)).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(0..<StarHop.maxHearts, id: \.self) { i in
                    Image(systemName: i < h.hearts ? "heart.fill" : "heart").font(.system(size: 18, weight: .bold))
                        .foregroundStyle(i < h.hearts ? Color(hop: 0xFF5A7A) : ink.opacity(0.3))
                }
            }
            .accessibilityElement(children: .ignore).accessibilityLabel("\(h.hearts) hearts")
            Button { showLevels = true } label: {
                Image(systemName: "square.grid.3x3.fill").font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.75))
                    .frame(width: 44, height: 44).background(Circle().fill(.regularMaterial))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Levels")
        }
    }

    @ViewBuilder private var progressRow: some View {
        if let q = h.prompt {
            HStack(spacing: 8) {
                Text("\(q) = ?").font(.kid(30, .black)).monospacedDigit().foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 6).background(Capsule().fill(accent))
                    .id("q\(h.collected)").transition(.push(from: .trailing))
                Text("\(h.collected)/\(h.goal)").font(.kid(16, .black)).monospacedDigit().foregroundStyle(ink.opacity(0.6))
            }
            .accessibilityElement(children: .ignore).accessibilityLabel(spokenGoal)
        } else if !h.sequence.isEmpty {
            HStack(spacing: 5) {
                ForEach(Array(h.sequence.enumerated()), id: \.offset) { i, label in
                    Text(label).font(.kid(19, .black)).monospacedDigit()
                        .foregroundStyle(i < h.collected ? .white : (i == h.collected ? accent : ink.opacity(0.45)))
                        .frame(minWidth: 34, minHeight: 38).padding(.horizontal, label.count > 1 ? 2 : 0)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(i < h.collected ? accent : (h.info.night ? .white.opacity(0.15) : .white.opacity(0.8))))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(i == h.collected ? accent : .clear, lineWidth: 2.5))
                }
            }
            .accessibilityElement(children: .ignore).accessibilityLabel(spokenGoal)
        } else {
            HStack(spacing: 6) {
                ArtImage("goal_star").frame(width: 24, height: 24)
                Text("\(h.collected) / \(h.goal)").font(.kid(22, .black)).monospacedDigit().contentTransition(.numericText())
            }
            .accessibilityElement(children: .ignore).accessibilityLabel("\(h.collected) of \(h.goal) stars")
        }
    }

    private var messageLine: some View {
        Text(HopWords.tr(h.message, L10n.isSpanish))
            .font(.kid(15, .black)).foregroundStyle(h.bumped ? Color(hop: 0xE0445E) : accent).lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(Capsule().fill(h.info.night ? .black.opacity(0.25) : .white.opacity(0.75)))
            .id(h.turn).transition(.push(from: .bottom))
            .allowsHitTesting(false)
            .padding(.top, 6)
            .accessibilityHidden(true)
    }

    // MARK: Board

    private var board: some View {
        GeometryReader { geo in
            let cw = geo.size.width / CGFloat(StarHop.columns)
            let ground: CGFloat = 22
            let top: CGFloat = 40
            let rh = (geo.size.height - ground - top) / CGFloat(StarHop.rows)
            let unit = min(cw, rh)
            let x = { (c: Int) in (CGFloat(c) + 0.5) * cw }
            let y = { (row: Int) in geo.size.height - ground - (CGFloat(row) + 0.5) * rh }
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(Color(hop: h.info.grass)).frame(height: 8)
                    Rectangle().fill(Color(hop: h.info.soil)).frame(height: ground - 8)
                }
                if let sp = h.info.spring {
                    SpringPad(squashed: h.bounced).frame(width: unit * 0.7, height: unit * 0.36)
                        .position(x: x(sp), y: geo.size.height - ground - unit * 0.16)
                }
                if let b = h.bubble {
                    Bubble().frame(width: unit * 0.62, height: unit * 0.62)
                        .position(x: x(b % StarHop.columns), y: y(b / StarHop.columns))
                        .transition(.scale.combined(with: .opacity))
                }
                ForEach(Array(h.clouds.enumerated()), id: \.offset) { _, cell in
                    PuffCloud(night: h.info.night).frame(width: unit * 1.05, height: unit * 0.75)
                        .position(x: x(cell % StarHop.columns), y: y(cell / StarHop.columns))
                }
                ForEach(h.stars) { star in
                    starView(star, size: unit * 0.72)
                        .position(x: x(star.cell % StarHop.columns), y: y(star.cell / StarHop.columns))
                        .transition(.scale.combined(with: .opacity))
                }
                if let c = h.lastCatch {
                    Image(systemName: "sparkles").font(.system(size: unit * 0.5, weight: .bold)).foregroundStyle(Color(hop: 0xFFC83D))
                        .position(x: x(c % StarHop.columns) + unit * 0.35, y: y(c / StarHop.columns) - unit * 0.35)
                        .id("spark\(h.turn)").transition(.scale.combined(with: .opacity))
                }
                CharacterBadge(character: store.character, size: unit * 0.9)
                    .scaleEffect(x: h.facingLeft ? -1 : 1, y: 1)
                    .rotationEffect(.degrees(h.bumped ? -14 : (h.row > 0 ? 6 * (h.facingLeft ? -1 : 1) : 0)))
                    .overlay {
                        if h.shield {
                            Bubble().frame(width: unit * 1.2, height: unit * 1.2).opacity(0.85)
                        } else if h.popped {
                            Image(systemName: "burst").font(.system(size: unit * 0.9, weight: .light)).foregroundStyle(Color(hop: 0x8FD3FF))
                                .transition(.scale(scale: 1.4).combined(with: .opacity))
                        }
                    }
                    .position(x: x(h.col), y: y(h.row) - 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(boardDescription)
    }

    private func starView(_ star: HopStar, size: CGFloat) -> some View {
        ZStack {
            ArtImage("goal_star").frame(width: size, height: size)
                .shadow(color: star.golden ? Color(hop: 0xFFB300).opacity(0.9) : .clear, radius: 6)
            if star.golden {
                Image(systemName: "sparkle").font(.system(size: size * 0.32, weight: .black)).foregroundStyle(.white)
                    .offset(x: size * 0.36, y: -size * 0.36)
            }
            if let label = star.label {
                Text(label).font(.kid(size * (label.count > 1 ? 0.34 : 0.42), .black)).monospacedDigit()
                    .foregroundStyle(Palette.ink).offset(y: size * 0.04)
            }
        }
    }

    /// Where things are, from the buddy, for VoiceOver.
    private var boardDescription: String {
        var parts = ["\(h.info.title). \(spokenGoal)"]
        func whereIs(_ cell: Int) -> String {
            let c = cell % StarHop.columns, r = cell / StarHop.columns
            let ahead = (c - h.col + StarHop.columns) % StarHop.columns
            let side = ahead == 0 ? "right here" : ahead <= StarHop.columns / 2 ? "\(ahead) to the right" : "\(StarHop.columns - ahead) to the left"
            let height = r == 0 ? "on the ground" : r == 1 ? "up one" : "up high"
            return "\(side), \(height)"
        }
        for s in h.stars { parts.append("\(s.label.map { "Star \($0)" } ?? (s.golden ? "Golden star" : "Star")): \(whereIs(s.cell)).") }
        for c in h.clouds { parts.append("Puff cloud: \(whereIs(c)).") }
        if let b = h.bubble { parts.append("Bubble: \(whereIs(b)).") }
        return parts.joined(separator: " ")
    }

    // MARK: Cards

    private func card(title: String, detail: String, rating: Int?, button: String, action: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 10) {
                Text(L10n.tr(title)).font(.kid(26, .black)).multilineTextAlignment(.center)
                if let rating {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: "star.fill").font(.system(size: 38, weight: .black))
                                .foregroundStyle(i < rating ? Color(hop: 0xFFC83D) : Color(hop: 0xDCD6E6))
                        }
                    }
                    .accessibilityElement(children: .ignore).accessibilityLabel("\(rating) of 3 stars")
                    HStack(spacing: 12) {
                        Text("✓ " + L10n.tr("Finished"))
                        Text((h.bumps == 0 ? "✓ " : "· ") + L10n.tr("No bumps")).opacity(h.bumps == 0 ? 1 : 0.45)
                        Text((h.moves <= h.par ? "✓ " : "· ") + L10n.tr("Quick feet")).opacity(h.moves <= h.par ? 1 : 0.45)
                    }
                    .font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                }
                Text(L10n.tr(detail)).font(.kid(15, .semibold)).foregroundStyle(Palette.ink.opacity(0.65)).multilineTextAlignment(.center)
                BigButton(title: button, color: Palette.purple, action: action)
            }
            .foregroundStyle(Palette.ink)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.white))
            .padding(.horizontal, 28)
            .transition(.panel)
        }
    }

    private var levelPicker: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 14) {
                    ForEach(StarHop.levels, id: \.number) { lv in
                        let open = h.canPick(lv.number)
                        let r = h.rating.indices.contains(lv.number - 1) ? h.rating[lv.number - 1] : 0
                        Button {
                            act { $0.pick(lv.number) }
                            showLevels = false
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(LinearGradient(colors: [Color(hop: lv.skyTop), Color(hop: lv.grass)], startPoint: .top, endPoint: .bottom))
                                    if open {
                                        Text("\(lv.number)").font(.kid(24, .black)).foregroundStyle(lv.night ? .white : Palette.ink)
                                    } else {
                                        Image(systemName: "lock.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.5))
                                    }
                                }
                                .frame(width: 64, height: 64)
                                .overlay(Circle().stroke(lv.number == h.level ? Palette.purple : .white, lineWidth: lv.number == h.level ? 4 : 2))
                                .opacity(open ? 1 : 0.45)
                                Text(lv.title).font(.kid(12, .black)).foregroundStyle(Palette.ink).lineLimit(2).multilineTextAlignment(.center)
                                HStack(spacing: 1) {
                                    ForEach(0..<3, id: \.self) { i in
                                        Image(systemName: "star.fill").font(.system(size: 10, weight: .black))
                                            .foregroundStyle(i < r ? Color(hop: 0xFFC83D) : Color(hop: 0xDCD6E6))
                                    }
                                }
                            }
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .disabled(!open)
                        .accessibilityLabel("Level \(lv.number), \(lv.title)\(open ? ", \(r) stars" : ", locked")")
                    }
                }
                .padding(18)
            }
            .navigationTitle("Star Hop levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showLevels = false } } }
        }
        .presentationDetents([.medium, .large])
    }
}
