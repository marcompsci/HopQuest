import WidgetKit
import SwiftUI
import AppIntents

// HopQuest home-screen widgets (v5.6–v5.7).
// • My Buddy: the buddy, stars, what's up next and the skill being practised. Tapping opens HopQuest.
// • Star Hop: a tap-to-play game with twelve levels (v6.6–v6.7). Tap the left half to step left, the right half to jump, and the
//   right half again in the air to double jump. Counting and spelling levels, puff clouds and hearts. Small, medium and large.
//   "Star Dash" (large size) opens the full-speed game in the app.
// Everything is read from the shared App Group on this device; widgets never use the network.

// MARK: - Timeline

struct HopEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let hop: StarHop
}

struct HopProvider: TimelineProvider {
    func placeholder(in context: Context) -> HopEntry {
        HopEntry(date: Date(), snapshot: .placeholder, hop: StarHop())
    }

    func getSnapshot(in context: Context, completion: @escaping (HopEntry) -> Void) {
        completion(HopEntry(date: Date(), snapshot: SharedStore.loadSnapshot(), hop: SharedStore.loadHop()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HopEntry>) -> Void) {
        let entry = HopEntry(date: Date(), snapshot: SharedStore.loadSnapshot(), hop: SharedStore.loadHop())
        // the app asks for a reload whenever progress changes, so no clock-driven refreshes are needed
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - Look

enum WidgetTheme {
    static let ink = Color(red: 0.17, green: 0.11, blue: 0.24)
    static let purple = Color(red: 0.49, green: 0.30, blue: 1.0)
    static let sky = [Color(red: 0.78, green: 0.91, blue: 1.0), Color(red: 0.93, green: 0.97, blue: 1.0)]
    static let grass = Color(red: 0.35, green: 0.77, blue: 0.42)
    static let soil = Color(red: 0.71, green: 0.48, blue: 0.27)

    static func round(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font { .system(size: size, weight: weight, design: .rounded) }
}

struct BuddyImage: View {
    let id: String
    let emoji: String
    var body: some View {
        if let img = UIImage(named: "char_\(id)") {
            Image(uiImage: img).resizable().scaledToFit()
        } else {
            Text(emoji).font(.system(size: 40)).minimumScaleFactor(0.3)
        }
    }
}

// MARK: - My Buddy (progress)

struct BuddyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HopEntry

    var body: some View {
        let s = entry.snapshot
        Group {
            switch family {
            case .accessoryCircular: circular(s)
            case .accessoryRectangular: rectangular(s)
            case .accessoryInline: Text("⭐ \(s.stars) · \(s.lessonTitle)")
            case .systemSmall: small(s).foregroundStyle(WidgetTheme.ink)
            default: medium(s).foregroundStyle(WidgetTheme.ink)
            }
        }
        .widgetURL(URL(string: "hopquest://open"))
    }

    private func t(_ text: String) -> String { HopWords.tr(text, entry.snapshot.spanish == true) }

    // MARK: Lock Screen (v8.0)

    /// Stars in a ring that fills as skills are learned.
    private func circular(_ s: WidgetSnapshot) -> some View {
        Gauge(value: s.progress) {
            Image(systemName: "star.fill")
        } currentValueLabel: {
            Text("\(s.stars)").font(.system(size: 15, weight: .black, design: .rounded)).minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .accessibilityLabel("\(s.stars) stars. \(s.skillsLearned) of \(s.skillsTotal) skills learned.")
    }

    private func rectangular(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.system(size: 11, weight: .black)).widgetAccentable()
                Text("\(s.stars)").font(.system(size: 14, weight: .black, design: .rounded))
                // no child's name on the Lock Screen, where anyone holding the phone can see it
                Text(entry.snapshot.spanish == true ? "estrellas" : "stars").font(.system(size: 14, weight: .semibold, design: .rounded)).lineLimit(1)
            }
            Text("\(t(s.skillState)): \(s.lessonTitle)").font(.system(size: 13, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
            ProgressView(value: s.progress).widgetAccentable()
        }
    }

    private func small(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                BuddyImage(id: s.buddyID, emoji: s.buddyEmoji).frame(width: 52, height: 56)
                Spacer(minLength: 0)
                starPill(s.stars)
            }
            Spacer(minLength: 0)
            Text(t(s.skillState).uppercased()).font(WidgetTheme.round(10, .black)).foregroundStyle(WidgetTheme.purple).tracking(0.4)
            Text(s.lessonTitle).font(WidgetTheme.round(15, .black)).lineLimit(1).minimumScaleFactor(0.7)
            ProgressView(value: s.progress).tint(WidgetTheme.purple)
        }
    }

    private func medium(_ s: WidgetSnapshot) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                BuddyImage(id: s.buddyID, emoji: s.buddyEmoji).frame(width: 78, height: 84)
                starPill(s.stars)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(t("Hi, \(s.name)!")).font(WidgetTheme.round(18, .black)).lineLimit(1).minimumScaleFactor(0.7)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t(s.skillState).uppercased()).font(WidgetTheme.round(10, .black)).foregroundStyle(WidgetTheme.purple).tracking(0.4)
                    Text(s.lessonTitle).font(WidgetTheme.round(15, .black)).lineLimit(1)
                    Text(s.skill.prefix(1).uppercased() + s.skill.dropFirst())
                        .font(WidgetTheme.round(13, .semibold)).foregroundStyle(WidgetTheme.ink.opacity(0.65)).lineLimit(2)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ProgressView(value: s.progress).tint(WidgetTheme.purple)
                    Text("\(s.skillsLearned)/\(s.skillsTotal)").font(WidgetTheme.round(11, .bold)).monospacedDigit()
                        .foregroundStyle(WidgetTheme.ink.opacity(0.6))
                }
            }
        }
    }

    private func starPill(_ n: Int) -> some View {
        HStack(spacing: 3) {
            Image("goal_star").resizable().frame(width: 16, height: 16)
            Text("\(n)").font(WidgetTheme.round(14, .black)).monospacedDigit()
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(.white.opacity(0.85)))
    }
}

struct BuddyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HopQuestBuddy", provider: HopProvider()) { entry in
            BuddyWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: WidgetTheme.sky, startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("My Buddy")
        .description("Your buddy, your stars, and what to play next. Also on the Lock Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Star Hop (tap-to-play, v6.6–v6.7)

struct HopLeftIntent: AppIntent {
    static var title: LocalizedStringResource = "Step left"
    func perform() async throws -> some IntentResult {
        var h = SharedStore.loadHop(); h.left(); SharedStore.save(h)
        return .result()
    }
}

struct HopRightIntent: AppIntent {
    static var title: LocalizedStringResource = "Jump"
    func perform() async throws -> some IntentResult {
        var h = SharedStore.loadHop(); h.right(); SharedStore.save(h)
        return .result()
    }
}

struct HopNewGameIntent: AppIntent {
    static var title: LocalizedStringResource = "New Star Hop game"
    func perform() async throws -> some IntentResult {
        var h = SharedStore.loadHop(); h.newGame(); SharedStore.save(h)
        return .result()
    }
}

struct HopNextLevelIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Star Hop level"
    func perform() async throws -> some IntentResult {
        var h = SharedStore.loadHop(); h.nextLevel(); SharedStore.save(h)
        return .result()
    }
}

struct HopRetryIntent: AppIntent {
    static var title: LocalizedStringResource = "Try the Star Hop level again"
    func perform() async throws -> some IntentResult {
        var h = SharedStore.loadHop(); h.retry(); SharedStore.save(h)
        return .result()
    }
}

struct HopPickLevelIntent: AppIntent {
    static var title: LocalizedStringResource = "Pick a Star Hop level"
    @Parameter(title: "Level") var level: Int
    init() {}
    init(level: Int) { self.level = level }
    func perform() async throws -> some IntentResult {
        var h = SharedStore.loadHop(); h.pick(level); SharedStore.save(h)
        return .result()
    }
}

struct StarHopWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HopEntry

    private var h: StarHop { entry.hop }
    private func t(_ text: String) -> String { HopWords.tr(text, entry.snapshot.spanish == true) }
    private var small: Bool { family == .systemSmall }
    private var ink: Color { h.info.night ? .white : WidgetTheme.ink }
    private var accent: Color { h.info.night ? Color(hop: 0xFFD84D) : WidgetTheme.purple }

    var body: some View {
        VStack(spacing: small ? 3 : 5) {
            header
            ZStack {
                board
                    .overlay(alignment: .top) { messageLine }
                if h.champion {
                    card(title: t("You beat all \(StarHop.levels.count) levels! 🏆"),
                         detail: t("\(h.totalRating) of \(StarHop.levels.count * 3) stars"), rating: h.lastRating,
                         button: t("Play again"), icon: "arrow.clockwise", intent: HopNewGameIntent())
                } else if h.levelDone {
                    card(title: t("Level \(h.level) done!"),
                         detail: t("Next: \(StarHop.levels[min(h.level, StarHop.levels.count - 1)].title)"), rating: h.lastRating,
                         button: t("Next level"), icon: "arrow.right", intent: HopNextLevelIntent())
                } else if h.outOfHearts {
                    card(title: t("Out of hearts!"), detail: t("The puff clouds got you. You can do it!"), rating: nil, button: t("Try again"),
                         icon: "arrow.clockwise", intent: HopRetryIntent())
                } else {
                    // the two tap halves sit on top of the board
                    HStack(spacing: 0) {
                        Button(intent: HopLeftIntent()) { zone("chevron.left", t("Step")) }
                            .buttonStyle(.plain)
                        Button(intent: HopRightIntent()) { zone("arrow.up.right", t(h.row > 0 && h.jumps == 1 ? "Double jump" : "Jump")) }
                            .buttonStyle(.plain)
                    }
                }
            }
            if family == .systemLarge { footer }
        }
        .foregroundStyle(ink)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: h.turn)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 6) {
            if !small {
                Text("\(h.level)")
                    .font(WidgetTheme.round(12, .black)).foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(accent))
                Text(t(h.info.title)).font(WidgetTheme.round(15, .black)).lineLimit(1).minimumScaleFactor(0.75)
            }
            hearts
            Spacer(minLength: 0)
            progress
        }
    }

    private var hearts: some View {
        HStack(spacing: 1) {
            ForEach(0..<StarHop.maxHearts, id: \.self) { i in
                Image(systemName: i < h.hearts ? "heart.fill" : "heart")
                    .font(.system(size: small ? 10 : 11, weight: .bold))
                    .foregroundStyle(i < h.hearts ? Color(hop: 0xFF5A7A) : ink.opacity(0.3))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(h.hearts) hearts")
    }

    /// Star levels: caught / goal. Counting and spelling levels: the sequence, with the caught ones filled in.
    @ViewBuilder private var progress: some View {
        if let q = h.prompt {
            // adding and take-away levels: the question, big and clear, with how many are done
            HStack(spacing: 4) {
                Text("\(q) = ?").font(WidgetTheme.round(small ? 13 : 15, .black)).monospacedDigit().foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(accent))
                    .id("q\(h.collected)")
                    .transition(.push(from: .trailing))
                if !small {
                    Text("\(h.collected)/\(h.goal)").font(WidgetTheme.round(12, .black)).monospacedDigit()
                        .foregroundStyle(ink.opacity(0.6))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("What is \(q.replacingOccurrences(of: "−", with: "minus"))? \(h.collected) of \(h.goal) done.")
        } else if h.sequence.isEmpty {
            HStack(spacing: 3) {
                Image("goal_star").resizable().frame(width: 14, height: 14)
                Text("\(h.collected)/\(h.goal)").font(WidgetTheme.round(13, .black)).monospacedDigit()
                    .contentTransition(.numericText())
            }
        } else if small {
            HStack(spacing: 3) {
                Text(t("Next")).font(WidgetTheme.round(10, .bold)).foregroundStyle(ink.opacity(0.6))
                Text(h.needed ?? "✓").font(WidgetTheme.round(13, .black)).foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20).padding(.horizontal, 2)
                    .background(Capsule().fill(accent))
            }
        } else {
            HStack(spacing: 2) {
                ForEach(Array(h.sequence.enumerated()), id: \.offset) { i, label in
                    Text(label)
                        .font(WidgetTheme.round(11, .black)).monospacedDigit()
                        .foregroundStyle(i < h.collected ? .white : (i == h.collected ? accent : ink.opacity(0.45)))
                        .frame(minWidth: 15, minHeight: 17).padding(.horizontal, label.count > 1 ? 1 : 0)
                        .background(RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(i < h.collected ? accent : (h.info.night ? .white.opacity(0.15) : .white.opacity(0.75))))
                        .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(i == h.collected ? accent : .clear, lineWidth: 1.5))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(h.word.map { "Spelling \($0). Next letter \(h.needed ?? "")" } ?? "Next number \(h.needed ?? "")")
        }
    }

    private var messageLine: some View {
        Text(t(h.message))
            .font(WidgetTheme.round(small ? 10 : 11, .black))
            .foregroundStyle(h.bumped ? Color(hop: 0xE0445E) : accent)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Capsule().fill(h.info.night ? .black.opacity(0.25) : .white.opacity(0.7)))
            .id(h.turn)
            .transition(.push(from: .bottom))
            .allowsHitTesting(false)
    }

    // MARK: Board

    /// Which board columns show. The small widget follows the buddy with a 4-column window (the board wraps around).
    private var shownColumns: [Int] {
        small ? (0..<4).map { (h.col - 1 + $0 + StarHop.columns) % StarHop.columns } : Array(0..<StarHop.columns)
    }

    private var board: some View {
        GeometryReader { geo in
            let cols = shownColumns
            let cw = geo.size.width / CGFloat(cols.count)
            let ground: CGFloat = small ? 10 : 12
            let top: CGFloat = small ? 14 : 16
            let rh = (geo.size.height - ground - top) / CGFloat(StarHop.rows)
            let unit = min(cw, rh)
            let x = { (c: Int) -> CGFloat? in cols.firstIndex(of: c).map { (CGFloat($0) + 0.5) * cw } }
            let y = { (row: Int) in geo.size.height - ground - (CGFloat(row) + 0.5) * rh }
            ZStack(alignment: .topLeading) {
                // grass and soil along the bottom
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(Color(hop: h.info.grass)).frame(height: 5)
                    Rectangle().fill(Color(hop: h.info.soil)).frame(height: ground - 5)
                }
                if let sp = h.info.spring, let sx = x(sp) {
                    SpringPad(squashed: h.bounced)
                        .frame(width: unit * 0.7, height: unit * 0.36)
                        .position(x: sx, y: geo.size.height - ground - unit * 0.16)
                }
                if let b = h.bubble, let bx = x(b % StarHop.columns) {
                    Bubble().frame(width: unit * 0.62, height: unit * 0.62)
                        .position(x: bx, y: y(b / StarHop.columns))
                        .transition(.scale.combined(with: .opacity))
                }
                ForEach(Array(h.clouds.enumerated()), id: \.offset) { _, cell in
                    if let cx = x(cell % StarHop.columns) {
                        PuffCloud(night: h.info.night).frame(width: unit * 1.05, height: unit * 0.75)
                            .position(x: cx, y: y(cell / StarHop.columns))
                    }
                }
                ForEach(h.stars) { star in
                    if let sx = x(star.cell % StarHop.columns) {
                        starView(star, size: unit * 0.72)
                            .position(x: sx, y: y(star.cell / StarHop.columns))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                if let c = h.lastCatch, let sx = x(c % StarHop.columns) {
                    Image(systemName: "sparkles").font(.system(size: unit * 0.5, weight: .bold))
                        .foregroundStyle(Color(hop: 0xFFC83D))
                        .position(x: sx + unit * 0.35, y: y(c / StarHop.columns) - unit * 0.35)
                        .id("spark\(h.turn)")
                        .transition(.scale.combined(with: .opacity))
                }
                if let bx = x(h.col) {
                    BuddyImage(id: entry.snapshot.buddyID, emoji: entry.snapshot.buddyEmoji)
                        .frame(width: unit * 0.95, height: unit * 1.05)
                        .scaleEffect(x: h.facingLeft ? -1 : 1, y: 1)
                        .rotationEffect(.degrees(h.bumped ? -14 : (h.row > 0 ? 6 * (h.facingLeft ? -1 : 1) : 0)))
                        .overlay(alignment: .top) {
                            if h.bumped {
                                Image(systemName: "star.circle.fill").font(.system(size: unit * 0.3)).foregroundStyle(.yellow)
                                    .offset(y: -unit * 0.2)
                            }
                        }
                        .overlay {
                            if h.shield {
                                Bubble().frame(width: unit * 1.25, height: unit * 1.25).opacity(0.85)
                                    .transition(.scale.combined(with: .opacity))
                            } else if h.popped {
                                Image(systemName: "burst").font(.system(size: unit * 0.9, weight: .light))
                                    .foregroundStyle(Color(hop: 0x8FD3FF))
                                    .transition(.scale(scale: 1.4).combined(with: .opacity))
                            }
                        }
                        .position(x: bx, y: y(h.row) - 2)
                }
                if small { offscreenHint(width: geo.size.width, y: y) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(boardDescription)
    }

    private func starView(_ star: HopStar, size: CGFloat) -> some View {
        ZStack {
            Image("goal_star").resizable().frame(width: size, height: size)
                .saturation(star.golden ? 1.4 : 1)
                .shadow(color: star.golden ? Color(hop: 0xFFB300).opacity(0.9) : .clear, radius: 5)
            if star.golden {
                Image(systemName: "sparkle").font(.system(size: size * 0.32, weight: .black)).foregroundStyle(.white)
                    .offset(x: size * 0.36, y: -size * 0.36)
            }
            if let label = star.label {
                Text(label)
                    .font(WidgetTheme.round(size * (label.count > 1 ? 0.36 : 0.44), .black)).monospacedDigit()
                    .foregroundStyle(WidgetTheme.ink)
                    .offset(y: size * 0.04)
            }
        }
    }

    /// In the small widget, a little arrow points toward the star you need when it is out of view.
    @ViewBuilder private func offscreenHint(width: CGFloat, y: (Int) -> CGFloat) -> some View {
        let target = h.stars.first { $0.label == nil || $0.label == h.needed }
        if let t = target, !shownColumns.contains(t.cell % StarHop.columns) {
            let ahead = (t.cell % StarHop.columns - h.col + StarHop.columns) % StarHop.columns
            let toRight = ahead <= StarHop.columns / 2
            Image(systemName: toRight ? "chevron.right.2" : "chevron.left.2")
                .font(.system(size: 11, weight: .black)).foregroundStyle(accent)
                .padding(4).background(Circle().fill(.white.opacity(0.8)))
                .position(x: toRight ? width - 10 : 10, y: y(t.cell / StarHop.columns))
        }
    }

    private var boardDescription: String {
        var parts = ["Star Hop, level \(h.level), \(h.info.title).", "\(h.hearts) hearts."]
        if let need = h.needed { parts.append("Find \(need) next.") } else { parts.append("\(h.collected) of \(h.goal) stars caught.") }
        if let q = h.prompt { parts.append("What is \(q.replacingOccurrences(of: "−", with: "minus"))?") }
        if !h.clouds.isEmpty { parts.append(h.clouds.count == 1 ? "One puff cloud in the sky." : "\(h.clouds.count) puff clouds in the sky.") }
        if h.shield { parts.append("You have a bubble shield.") } else if h.bubble != nil { parts.append("A bubble shield is on the board.") }
        if h.info.spring != nil { parts.append("A spring pad on the ground bounces you up high.") }
        return parts.joined(separator: " ")
    }

    /// A clear tap area with a small hint at the bottom.
    private func zone(_ icon: String, _ label: String) -> some View {
        Rectangle().fill(.clear)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Label(label, systemImage: icon)
                    .labelStyle(small ? AnyLabelStyle(.iconOnly) : AnyLabelStyle(.titleAndIcon))
                    .font(WidgetTheme.round(10, .black)).foregroundStyle(ink.opacity(0.55))
                    .padding(.bottom, small ? 0 : 1)
            }
            .accessibilityLabel(label)
    }

    private func card<I: AppIntent>(title: String, detail: String, rating: Int?, button: String, icon: String, intent: I) -> some View {
        VStack(spacing: small ? 3 : 5) {
            Text(title).font(WidgetTheme.round(small ? 13 : 16, .black)).multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.8)
            if let rating { ratingRow(rating, size: small ? 16 : 22, labels: !small) }
            if !small && (family == .systemLarge || rating == nil) {
                Text(detail).font(WidgetTheme.round(12, .bold)).foregroundStyle(WidgetTheme.ink.opacity(0.6))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Button(intent: intent) {
                Label(button, systemImage: icon)
                    .font(WidgetTheme.round(13, .black)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(WidgetTheme.purple))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(WidgetTheme.ink)
        .padding(small ? 8 : 10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.94)))
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    /// 1–3 stars: finishing, no bumps, quick feet.
    private func ratingRow(_ n: Int, size: CGFloat, labels: Bool) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill").font(.system(size: size, weight: .black))
                        .foregroundStyle(i < n ? Color(hop: 0xFFC83D) : Color(hop: 0xDCD6E6))
                        .shadow(color: i < n ? Color(hop: 0xE59A00).opacity(0.6) : .clear, radius: 0, x: 0, y: 1.5)
                }
            }
            if labels {
                HStack(spacing: 8) {
                    Text(t("✓ Finished"))
                    Text(t(h.bumps == 0 ? "✓ No bumps" : "· No bumps")).opacity(h.bumps == 0 ? 1 : 0.45)
                    Text(t(h.moves <= h.par ? "✓ Quick feet" : "· Quick feet")).opacity(h.moves <= h.par ? 1 : 0.45)
                }
                .font(WidgetTheme.round(10, .bold)).foregroundStyle(WidgetTheme.ink.opacity(0.7))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(n) of 3 stars")
    }

    // MARK: Large widget footer: level picker, best, Star Dash

    private var footer: some View {
        VStack(spacing: 8) {
            // two rows of six: tap a level you've reached to play it
            ForEach(0..<2, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(StarHop.levels[(rowIndex * 6)..<min(StarHop.levels.count, rowIndex * 6 + 6)], id: \.number) { lv in
                        Button(intent: HopPickLevelIntent(level: lv.number)) {
                            levelDot(lv)
                        }
                        .buttonStyle(.plain)
                        .disabled(!h.canPick(lv.number))
                    }
                }
            }
            HStack {
                let b = h.best.indices.contains(h.level - 1) ? h.best[h.level - 1] : 0
                Text(t(b > 0 ? "Best on this level: \(b) moves" : h.info.tip))
                    .font(WidgetTheme.round(12, .semibold)).foregroundStyle(ink.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Link(destination: URL(string: "hopquest://quickgame")!) {
                    Label("Star Dash", systemImage: "play.fill")
                        .font(WidgetTheme.round(13, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(WidgetTheme.purple))
                }
            }
        }
    }

    private func levelDot(_ lv: HopLevel) -> some View {
        let open = h.canPick(lv.number)
        let done = lv.number <= h.levelsCleared
        let here = lv.number == h.level
        return ZStack {
            Circle().fill(LinearGradient(colors: [Color(hop: lv.skyTop), Color(hop: lv.grass)], startPoint: .top, endPoint: .bottom))
                .opacity(open ? 1 : 0.35)
            if open {
                Text("\(lv.number)").font(WidgetTheme.round(13, .black)).foregroundStyle(lv.night ? .white : WidgetTheme.ink)
            } else {
                Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(WidgetTheme.ink.opacity(0.5))
            }
        }
        .frame(width: 30, height: 30)
        .overlay(Circle().stroke(here ? accent : .white.opacity(0.8), lineWidth: here ? 3 : 1.5))
        .overlay(alignment: .bottom) {
            if done {
                let r = h.rating.indices.contains(lv.number - 1) ? h.rating[lv.number - 1] : 1
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill").font(.system(size: 7, weight: .black))
                            .foregroundStyle(i < r ? Color(hop: 0xFFC83D) : Color(hop: 0xCFC8DC))
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 1)
                .background(Capsule().fill(.white))
                .offset(y: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Level \(lv.number), \(lv.title)\(done ? ", \(h.rating.indices.contains(lv.number - 1) ? h.rating[lv.number - 1] : 1) stars" : "")\(open ? "" : ", locked")")
    }
}

struct AnyLabelStyle: LabelStyle {
    private let make: (Configuration) -> AnyView
    init<S: LabelStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

struct StarHopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HopQuestStarHop", provider: HopProvider()) { entry in
            StarHopWidgetView(entry: entry)
                .containerBackground(for: .widget) { HopSky(level: entry.hop.info) }
        }
        .configurationDisplayName("Star Hop")
        .description("Twelve little worlds to hop through: count, spell, add and dodge puff clouds. Tap left to step, tap right to jump!")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Brain Bubble (v8.5): one question, three answers, tap right on the widget

struct BubbleEntry: TimelineEntry {
    let date: Date
    let bubble: BrainBubble
    let spanish: Bool
}

struct BubbleProvider: TimelineProvider {
    func placeholder(in context: Context) -> BubbleEntry { BubbleEntry(date: Date(), bubble: BrainBubble(), spanish: false) }
    func getSnapshot(in context: Context, completion: @escaping (BubbleEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BubbleEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .never))
    }
    private func entry() -> BubbleEntry {
        BubbleEntry(date: Date(), bubble: SharedStore.loadBubble(), spanish: SharedStore.loadSnapshot().spanish == true)
    }
}

struct BubblePickIntent: AppIntent {
    static var title: LocalizedStringResource = "Answer the Brain Bubble"
    @Parameter(title: "Choice") var choice: Int
    /// The question the widget was showing when it was tapped.
    @Parameter(title: "Question") var question: Int
    init() {}
    init(choice: Int, question: Int) { self.choice = choice; self.question = question }
    func perform() async throws -> some IntentResult {
        var b = SharedStore.loadBubble(); b.pick(choice, asked: question); SharedStore.save(b)
        return .result()
    }
}

struct BubbleNextIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Brain Bubble question"
    /// The question the widget was showing when it was tapped.
    @Parameter(title: "Question") var question: Int
    init() {}
    init(question: Int) { self.question = question }
    func perform() async throws -> some IntentResult {
        var b = SharedStore.loadBubble(); b.next(asked: question); SharedStore.save(b)
        return .result()
    }
}

struct BrainBubbleView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BubbleEntry

    private var b: BrainBubble { entry.bubble }
    private var q: BubbleQuestion { b.question }
    private func t(_ s: String) -> String { HopWords.tr(s, entry.spanish) }

    var body: some View {
        let large = family == .systemLarge
        VStack(alignment: .leading, spacing: large ? 10 : 6) {
            HStack(spacing: 6) {
                Image(systemName: "bubbles.and.sparkles.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(WidgetTheme.purple)
                Text(t("Brain Bubble")).font(WidgetTheme.round(13, .black)).foregroundStyle(WidgetTheme.purple)
                Spacer(minLength: 0)
                if b.answered > 0 {
                    Text(t("\(b.right) right")).font(WidgetTheme.round(11, .bold)).foregroundStyle(WidgetTheme.ink.opacity(0.55)).monospacedDigit()
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Text(q.emoji).font(.system(size: large ? 46 : 34))
                    .frame(width: large ? 64 : 46, height: large ? 64 : 46)
                    .background(Circle().fill(.white.opacity(0.85)))
                    .accessibilityHidden(true)
                Text(q.question).font(WidgetTheme.round(large ? 19 : 15, .black)).lineLimit(3).minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if b.isAnswered {
                HStack(spacing: 6) {
                    Image(systemName: b.gotIt ? "checkmark.circle.fill" : "lightbulb.fill")
                        .foregroundStyle(b.gotIt ? Color(hop: 0x2FA35B) : Color(hop: 0xF2B705))
                    Text(b.gotIt ? t("Yes!") : t("Not quite.") + " " + t("It's \(q.choices[q.answer]).")).font(WidgetTheme.round(13, .black))
                }
                Text(q.fact).font(WidgetTheme.round(12, .semibold)).foregroundStyle(WidgetTheme.ink.opacity(0.7)).lineLimit(large ? 3 : 2)
                Spacer(minLength: 0)
                Button(intent: BubbleNextIntent(question: b.index)) {
                    Label(t("Next question"), systemImage: "arrow.right")
                        .font(WidgetTheme.round(13, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(WidgetTheme.purple))
                }
                .buttonStyle(.plain)
            } else {
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(Array(q.choices.enumerated()), id: \.offset) { i, c in
                        Button(intent: BubblePickIntent(choice: i, question: b.index)) {
                            Text(c).font(WidgetTheme.round(c.count > 8 ? 12 : 16, .black)).lineLimit(2).minimumScaleFactor(0.7)
                                .foregroundStyle(WidgetTheme.ink).multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: large ? 54 : 40)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(WidgetTheme.purple.opacity(0.35), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Answer: \(c)")
                    }
                }
            }
        }
        .foregroundStyle(WidgetTheme.ink)
        .animation(.spring(duration: 0.3), value: b.picked)
    }
}

struct BrainBubbleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HopQuestBrainBubble", provider: BubbleProvider()) { entry in
            BrainBubbleView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color(hop: 0xEFE7FF), Color(hop: 0xFFF6FB)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Brain Bubble")
        .description("A quick question with three answers. Tap one right on the widget!")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct HopQuestWidgets: WidgetBundle {
    var body: some Widget {
        BuddyWidget()
        StarHopWidget()
        BrainBubbleWidget()
    }
}
