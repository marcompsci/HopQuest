import WidgetKit
import SwiftUI
import AppIntents

// HopQuest home-screen widgets (v5.6–v5.7).
// • My Buddy: the buddy, stars, what's up next and the skill being practised. Tapping opens HopQuest.
// • Star Hop: a tap-to-play game. Tap the left half to step left, the right half to jump, and the right half again
//   in the air to double jump. "Play Star Dash" opens the full-speed game in the app.
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
            if family == .systemSmall { small(s) } else { medium(s) }
        }
        .foregroundStyle(WidgetTheme.ink)
        .widgetURL(URL(string: "hopquest://open"))
    }

    private func small(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                BuddyImage(id: s.buddyID, emoji: s.buddyEmoji).frame(width: 52, height: 56)
                Spacer(minLength: 0)
                starPill(s.stars)
            }
            Spacer(minLength: 0)
            Text(s.skillState.uppercased()).font(WidgetTheme.round(10, .black)).foregroundStyle(WidgetTheme.purple).tracking(0.4)
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
                Text("Hi, \(s.name)!").font(WidgetTheme.round(18, .black)).lineLimit(1).minimumScaleFactor(0.7)
                VStack(alignment: .leading, spacing: 1) {
                    Text(s.skillState.uppercased()).font(WidgetTheme.round(10, .black)).foregroundStyle(WidgetTheme.purple).tracking(0.4)
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
        .description("Your buddy, your stars, and what to play next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Star Hop (tap-to-play)

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

struct StarHopWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HopEntry

    var body: some View {
        let h = entry.hop
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("Star Hop").font(WidgetTheme.round(15, .black))
                Text(h.message).font(WidgetTheme.round(12, .bold)).foregroundStyle(WidgetTheme.purple).lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Image("goal_star").resizable().frame(width: 14, height: 14)
                    Text("\(h.collected)/\(StarHop.goal)").font(WidgetTheme.round(13, .black)).monospacedDigit()
                }
            }
            ZStack {
                board(h)
                if h.won {
                    wonCard(h)
                } else {
                    // the two tap halves sit on top of the board
                    HStack(spacing: 0) {
                        Button(intent: HopLeftIntent()) { zone("chevron.left", "Step") }
                            .buttonStyle(.plain)
                        Button(intent: HopRightIntent()) { zone("arrow.up.right", h.row > 0 && h.jumps == 1 ? "Double jump" : "Jump") }
                            .buttonStyle(.plain)
                    }
                }
            }
            if family == .systemLarge {
                HStack {
                    Text(h.best > 0 ? "Best: \(h.best) moves" : "Catch \(StarHop.goal) stars in as few moves as you can")
                        .font(WidgetTheme.round(12, .semibold)).foregroundStyle(WidgetTheme.ink.opacity(0.6))
                    Spacer()
                    Link(destination: URL(string: "hopquest://quickgame")!) {
                        Label("Play Star Dash", systemImage: "play.fill")
                            .font(WidgetTheme.round(13, .black)).foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(WidgetTheme.purple))
                    }
                }
            }
        }
        .foregroundStyle(WidgetTheme.ink)
    }

    /// A clear tap area with a small hint at the bottom.
    private func zone(_ icon: String, _ label: String) -> some View {
        Rectangle().fill(.clear)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Label(label, systemImage: icon)
                    .font(WidgetTheme.round(10, .black)).foregroundStyle(WidgetTheme.ink.opacity(0.55))
                    .padding(.bottom, 2)
            }
            .accessibilityLabel(label)
    }

    private func board(_ h: StarHop) -> some View {
        GeometryReader { geo in
            let cw = geo.size.width / CGFloat(StarHop.columns)
            let ground: CGFloat = 12
            let rh = (geo.size.height - ground - 14) / CGFloat(StarHop.rows)
            let y = { (row: Int) in geo.size.height - ground - (CGFloat(row) + 0.5) * rh }
            ZStack(alignment: .topLeading) {
                // grass and soil along the bottom
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(WidgetTheme.grass).frame(height: 5)
                    Rectangle().fill(WidgetTheme.soil).frame(height: ground - 5)
                }
                ForEach(h.stars, id: \.self) { s in
                    Image("goal_star").resizable().frame(width: min(cw, rh) * 0.7, height: min(cw, rh) * 0.7)
                        .position(x: (CGFloat(s % StarHop.columns) + 0.5) * cw, y: y(s / StarHop.columns))
                }
                BuddyImage(id: entry.snapshot.buddyID, emoji: entry.snapshot.buddyEmoji)
                    .frame(width: min(cw, rh) * 0.95, height: min(cw, rh) * 1.05)
                    .position(x: (CGFloat(h.col) + 0.5) * cw, y: y(h.row) - 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Star Hop. \(h.collected) of \(StarHop.goal) stars caught.")
    }

    private func wonCard(_ h: StarHop) -> some View {
        VStack(spacing: 6) {
            Text("You caught \(StarHop.goal) stars!").font(WidgetTheme.round(16, .black))
            Text("\(h.moves) moves").font(WidgetTheme.round(12, .bold)).foregroundStyle(WidgetTheme.ink.opacity(0.6))
            Button(intent: HopNewGameIntent()) {
                Label("Play again", systemImage: "arrow.clockwise")
                    .font(WidgetTheme.round(13, .black)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(WidgetTheme.purple))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.92)))
    }
}

struct StarHopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HopQuestStarHop", provider: HopProvider()) { entry in
            StarHopWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: WidgetTheme.sky, startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Star Hop")
        .description("Tap left to step, tap right to jump, tap right again to double jump!")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct HopQuestWidgets: WidgetBundle {
    var body: some Widget {
        BuddyWidget()
        StarHopWidget()
    }
}
