import SwiftUI

/// A learning place built on the shared quiz engine (Spelling Bee, Fraction Bakery, Shape Studio, and five more from v6.8).
struct QuizPlace {
    let id: String
    let title: String
    let line: String
    let greeting: String
    let host: GameCharacter
    let accent: Color
    let background: [Color]
    let games: [QuizGameInfo]
    let rounds: (String) -> [QuizRound]

    static var spelling: QuizPlace {
        QuizPlace(id: "spelling", title: "Spelling Bee", line: "Bzz! Let's spell some words.",
                  greeting: "Bzz bzz! I'm Buzzy. Welcome to the Spelling Bee!", host: Roster.character(id: "buzzy"),
                  accent: Color(hex: 0xB7791F), background: [Color(hex: 0xFFF8E1), Color(hex: 0xFFE7A8)], games: SpellingBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return SpellingBank.rounds(for: id, using: &g) })
    }

    static var fractions: QuizPlace {
        QuizPlace(id: "fractions", title: "Fraction Bakery", line: "Fresh pies! Let's cut them into fair pieces.",
                  greeting: "Hello, I'm Stella! Welcome to the Fraction Bakery. Everything here is cut into fair shares.", host: Roster.character(id: "stella"),
                  accent: Color(hex: 0xC2185B), background: [Color(hex: 0xFFF0F5), Color(hex: 0xFFD6E5)], games: FractionBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return FractionBank.rounds(for: id, using: &g) })
    }

    static var rhyme: QuizPlace {
        QuizPlace(id: "rhyme", title: "Rhyme Pond", line: "Cat, hat, bat! Let's play with sounds.",
                  greeting: "Ribbit! I'm Fizz. Welcome to Rhyme Pond, where words sound alike!", host: Roster.character(id: "fizz"),
                  accent: Color(hex: 0x2E8B3E), background: [Color(hex: 0xEFFBEA), Color(hex: 0xCDEFC4)], games: RhymeBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return RhymeBank.rounds(for: id, using: &g) })
    }

    static var numbers: QuizPlace {
        QuizPlace(id: "numbers", title: "Number Builder", line: "Tens and ones! Let's build big numbers.",
                  greeting: "Hi, I'm Ocho! I have eight arms for counting. Welcome to Number Builder!", host: Roster.character(id: "ocho"),
                  accent: Color(hex: 0x6A3FB5), background: [Color(hex: 0xF4EEFF), Color(hex: 0xDCCDF7)], games: NumberBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return NumberBank.rounds(for: id, using: &g) })
    }

    static var times: QuizPlace {
        QuizPlace(id: "times", title: "Times Treehouse", line: "Groups of acorns! Count them fast.",
                  greeting: "Hello! I'm Iron Acorn. Welcome to my Times Treehouse, where we count in groups!", host: Roster.character(id: "acorn"),
                  accent: Color(hex: 0x8A5A2B), background: [Color(hex: 0xFFF5E6), Color(hex: 0xF3DDBA)], games: TimesBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return TimesBank.rounds(for: id, using: &g) })
    }

    static var measure: QuizPlace {
        QuizPlace(id: "measure", title: "Measure Meadow", line: "Long, short, heavy, light. Let's measure!",
                  greeting: "Hi, I'm Ellie! Welcome to Measure Meadow. Let's find out how long and how heavy things are.", host: Roster.character(id: "ellie"),
                  accent: Color(hex: 0x2F6F9F), background: [Color(hex: 0xEAF6FF), Color(hex: 0xC9E6F7)], games: MeasureBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return MeasureBank.rounds(for: id, using: &g) })
    }

    static var feelings: QuizPlace {
        QuizPlace(id: "feelings", title: "Feelings Corner", line: "All feelings are okay. Let's learn about them.",
                  greeting: "Hi, I'm Kip. Welcome to the Feelings Corner. Every feeling is okay to have.", host: Roster.character(id: "kip"),
                  accent: Color(hex: 0xC2185B), background: [Color(hex: 0xFFF0F6), Color(hex: 0xF9D5E5)], games: FeelingsBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return FeelingsBank.rounds(for: id, using: &g) })
    }

    /// Every place, by id.
    static func named(_ id: String) -> QuizPlace {
        switch id {
        case "spelling": return .spelling
        case "fractions": return .fractions
        case "rhyme": return .rhyme
        case "numbers": return .numbers
        case "times": return .times
        case "measure": return .measure
        case "feelings": return .feelings
        default: return .shapes
        }
    }

    static var shapes: QuizPlace {
        QuizPlace(id: "shapes", title: "Shape Studio", line: "Circles, squares, cubes and cones. Let's look closely!",
                  greeting: "Hi, I'm Rocky! Welcome to Shape Studio.", host: Roster.character(id: "rocky"),
                  accent: Color(hex: 0x00796B), background: [Color(hex: 0xE8F7F5), Color(hex: 0xC4ECE6)], games: ShapeBank.games,
                  rounds: { id in var g = SystemRandomNumberGenerator(); return ShapeBank.rounds(for: id, using: &g) })
    }
}

struct QuizPlaceView: View {
    @EnvironmentObject var store: GameStore
    let place: QuizPlace
    var onBack: () -> Void

    @State private var playing: QuizGameInfo?

    var body: some View {
        ZStack {
            LinearGradient(colors: place.background, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let game = playing {
                QuizGameView(place: place, game: game,
                             onFinish: { stars in store.recordPlace(place.id, game: game.id, stars: stars) },
                             onBack: { playing = nil; Narrator.shared.say("Pick another game!") })
                    .id(game.id)
                    .transition(.pushIn)
            } else {
                list.transition(.pushedBack)
            }
        }
        .animation(Motion.standard, value: playing)
        .onAppear { Narrator.shared.say("\(place.greeting) Pick a game!") }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        let save = store.profile?.places[place.id] ?? PlaceSave()
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PlaceHeader(host: place.host, title: place.title, line: place.line,
                            stars: save.totalStars, maxStars: place.games.count * 3, accent: place.accent, onBack: onBack)
                    .padding(.bottom, 4)
                ForEach(place.games) { g in
                    LearnGameCard(symbol: g.symbol, title: g.title, blurb: g.intro, stars: save.best(g.id), color: place.accent) {
                        playing = g
                    }
                }
                Text("Each game gives up to 3 stars. Beat your best for more.")
                    .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }
}

extension QuizGameInfo: Hashable {
    func hash(into h: inout Hasher) { h.combine(id) }
}

/// Five rounds, then stars. Handles pick-one rounds and letter-tile spelling.
struct QuizGameView: View {
    let place: QuizPlace
    let game: QuizGameInfo
    var onFinish: (Int) -> Int
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rounds: [QuizRound] = []
    @State private var index = 0
    @State private var missed = false
    @State private var firstTry = 0
    @State private var wrong: Set<String> = []
    @State private var right: String?
    @State private var typed = ""
    @State private var usedTiles: Set<Int> = []
    @State private var shakeTile: Int?
    @State private var result: (stars: Int, earned: Int)?
    @State private var advanceTask: Task<Void, Never>?

    private var round: QuizRound? { rounds.indices.contains(index) ? rounds[index] : nil }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop playing", action: { advanceTask?.cancel(); onBack() })
                Spacer()
                Text(L10n.tr(game.title)).font(.kid(20, .black)).displayTracking(20).foregroundStyle(Palette.ink)
                Spacer()
                SpeakButton(label: "Say it again") { if let r = round { Narrator.shared.sayAnyway(r.say) } }
            }
            RoundDots(done: index, total: max(rounds.count, 1))
            if let r = round, result == nil {
                question(r)
                Spacer(minLength: 0)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .overlay {
            if let result {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    LearnDoneCard(title: game.title, stars: result.stars, earned: result.earned, firstTry: firstTry, total: rounds.count,
                                  host: place.host, onAgain: start, onBack: onBack)
                }
            }
        }
        .onAppear(perform: start)
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func question(_ r: QuizRound) -> some View {
        VStack(spacing: 16) {
            if r.visual != .none {
                QuizVisualView(visual: r.visual, accent: place.accent, large: true)
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white.opacity(0.88)))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(r.visual.spoken.map { "\($0). \(r.say)" } ?? r.say)
            }
            Text(r.say).font(.kid(19, .bold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if r.kind == .spell {
                spellArea(r)
            } else if !r.choiceVisuals.isEmpty, r.choiceVisuals.allSatisfy({ if case .bar = $0 { return true }; return false }) {
                // ribbons line up one under another, so their lengths can be compared from the same starting edge
                VStack(spacing: 10) {
                    ForEach(Array(r.choices.enumerated()), id: \.offset) { i, c in
                        Button { pick(c, in: r) } label: {
                            HStack(spacing: 10) {
                                Text(c.capitalized).font(.kid(17, .black)).foregroundStyle(Palette.ink).frame(width: 74, alignment: .leading)
                                QuizVisualView(visual: r.choiceVisuals[i], accent: place.accent, large: false)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(right == c ? Palette.green : wrong.contains(c) ? Palette.red : Palette.ink.opacity(0.15), lineWidth: right == c || wrong.contains(c) ? 4 : 2))
                            .opacity(wrong.contains(c) ? 0.5 : 1)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("\(c) ribbon\(r.choiceVisuals[i].spoken.map { ", \($0)" } ?? "")\(wrong.contains(c) ? ", not this one" : "")")
                    }
                }
            } else if !r.choiceVisuals.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(r.choices.enumerated()), id: \.offset) { i, c in
                        Button { pick(c, in: r) } label: {
                            QuizVisualView(visual: r.choiceVisuals[i], accent: place.accent, large: false)
                                .frame(maxWidth: .infinity, minHeight: 110)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(right == c ? Palette.green : wrong.contains(c) ? Palette.red : Palette.ink.opacity(0.15), lineWidth: right == c || wrong.contains(c) ? 4 : 2))
                                .opacity(wrong.contains(c) ? 0.5 : 1)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Picture \(c)\(r.choiceVisuals[i].spoken.map { ": \($0)" } ?? "")\(wrong.contains(c) ? ", not this one" : "")")
                    }
                }
            } else {
                let columns = r.choices.count == 2 ? [GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(r.choices, id: \.self) { c in
                        AnswerButton(text: c, font: .kid(c.count > 8 ? 22 : 28, .black),
                                     state: right == c ? .right : wrong.contains(c) ? .wrong : .plain) {
                            pick(c, in: r)
                        }
                    }
                }
            }
        }
    }

    private func spellArea(_ r: QuizRound) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(Array(r.answer.enumerated()), id: \.offset) { i, _ in
                    let ch = i < typed.count ? String(typed[typed.index(typed.startIndex, offsetBy: i)]) : ""
                    Text(ch.isEmpty ? " " : ch)
                        .font(.kid(34, .black)).foregroundStyle(Palette.ink)
                        .frame(width: 52, height: 62)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(place.accent, lineWidth: i == typed.count ? 4 : 2))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(typed.isEmpty ? "No letters yet" : "Spelled so far: \(typed.map(String.init).joined(separator: ", "))")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Array(r.choices.enumerated()), id: \.offset) { i, letter in
                    Button { tapTile(i, letter, in: r) } label: {
                        Text(letter).font(.kid(30, .black)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(RoundedRectangle(cornerRadius: 14).fill(usedTiles.contains(i) ? Color.gray.opacity(0.35) : place.accent)
                                .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 4))
                            .modifier(Shake(animatableData: shakeTile == i && !reduceMotion ? 1 : 0))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(usedTiles.contains(i))
                    .accessibilityLabel("Letter \(letter)")
                }
            }
        }
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = place.rounds(game.id)
        index = 0; firstTry = 0; result = nil
        reset()
        Narrator.shared.say("\(game.intro) \(rounds.first?.say ?? "")")
    }

    private func reset() { missed = false; wrong = []; right = nil; typed = ""; usedTiles = []; shakeTile = nil }

    private func pick(_ c: String, in r: QuizRound) {
        guard right == nil else { return }
        if c == r.answer {
            right = c
            succeed(r)
        } else {
            missed = true
            wrong.insert(c)
            Haptics.bump(.oops)
            Narrator.shared.say("Not quite. Try another one!")
        }
    }

    private func tapTile(_ i: Int, _ letter: String, in r: QuizRound) {
        guard right == nil, typed.count < r.answer.count else { return }
        let need = String(r.answer[r.answer.index(r.answer.startIndex, offsetBy: typed.count)])
        if letter == need {
            Haptics.tap(.pop)
            usedTiles.insert(i)
            typed += letter
            Narrator.shared.say(letter.uppercased())
            if typed == r.answer { right = r.answer; succeed(r) }
        } else {
            missed = true
            Haptics.bump(.oops)
            withAnimation(.easeOut(duration: 0.35)) { shakeTile = i }
            Narrator.shared.say("Try another letter. Listen: \(r.answer).")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                shakeTile = nil
            }
        }
    }

    private func succeed(_ r: QuizRound) {
        Haptics.success(.correct)
        if !missed { firstTry += 1 }
        Narrator.shared.say(r.cheer)
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            if index + 1 < rounds.count {
                index += 1
                reset()
                Narrator.shared.say(rounds[index].say)
            } else {
                index = rounds.count
                let stars = LearnScore.stars(firstTry: firstTry, of: rounds.count)
                let earned = onFinish(stars)
                Haptics.success(.fanfare)
                withAnimation(Motion.present) { result = (stars, earned) }
                Narrator.shared.say(earned > 0 ? "You did it! \(earned) new stars!" : "You did it! Great work!")
            }
        }
    }
}

/// Draws a round's picture: words, emoji, fraction pies and bars, shapes and patterns.
struct QuizVisualView: View {
    let visual: QuizVisual
    let accent: Color
    let large: Bool

    var body: some View {
        switch visual {
        case .none:
            EmptyView()
        case .text(let t):
            Text(t).font(.kid(large ? 48 : 26, .black)).foregroundStyle(Palette.ink).minimumScaleFactor(0.5).lineLimit(2)
        case .picture(let p):
            Text(p).font(.system(size: p.count > 4 ? (large ? 40 : 24) : (large ? 88 : 48)))
                .multilineTextAlignment(.center).minimumScaleFactor(0.4)
        case .fraction(let parts, let shaded, let round):
            FractionDrawing(parts: parts, shaded: shaded, round: round, color: accent)
                .frame(width: large ? 150 : 80, height: round ? (large ? 150 : 80) : (large ? 70 : 40))
        case .shapes(let s):
            HStack(spacing: 12) {
                ForEach(Array(s.enumerated()), id: \.offset) { _, k in ShapeDrawing(kind: k, color: accent).frame(width: large ? 130 : 60, height: large ? 130 : 60) }
            }
        case .blocks(let tens, let ones):
            BlocksDrawing(tens: tens, ones: ones, color: accent, large: large)
        case .groups(let count, let each, let item, let rows):
            GroupsDrawing(count: count, each: each, item: item, rows: rows, large: large, color: accent)
        case .bar(let length, let color, let units):
            RibbonDrawing(length: length, color: QuizColors.named(color), units: units, large: large)
        case .pattern(let s):
            HStack(spacing: 6) {
                ForEach(Array(s.enumerated()), id: \.offset) { _, k in ShapeDrawing(kind: k, color: accent).frame(width: 40, height: 40) }
                Text("?").font(.kid(30, .black)).foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(accent, style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
            }
        }
    }
}

enum QuizColors {
    static func named(_ name: String) -> Color {
        switch name {
        case "red": return Color(hex: 0xE5484D)
        case "blue": return Color(hex: 0x3E7BFA)
        case "green": return Color(hex: 0x2FA35B)
        case "yellow": return Color(hex: 0xF2B705)
        default: return Color(hex: 0x8E4EC6)
        }
    }
}

/// Base-ten blocks: tall rods of ten little cubes, then single cubes.
struct BlocksDrawing: View {
    let tens: Int
    let ones: Int
    let color: Color
    let large: Bool

    var body: some View {
        let cube: CGFloat = large ? 12 : 7
        HStack(alignment: .bottom, spacing: large ? 5 : 3) {
            ForEach(0..<tens, id: \.self) { _ in
                VStack(spacing: 1) {
                    ForEach(0..<10, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: cube, height: cube)
                    }
                }
                .padding(1)
                .background(RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.35)))
            }
            if ones > 0 {
                // ones in a little grid of up to 3 wide, so they never look like a rod
                let cols = 3
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(0..<((ones + cols - 1) / cols), id: \.self) { r in
                        HStack(spacing: 2) {
                            ForEach(0..<min(cols, ones - r * cols), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xFF9F45)).frame(width: cube, height: cube)
                            }
                        }
                    }
                }
                .padding(.leading, large ? 8 : 4)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Equal groups in circles, or neat rows (an array).
struct GroupsDrawing: View {
    let count: Int
    let each: Int
    let item: String
    let rows: Bool
    let large: Bool
    let color: Color

    var body: some View {
        let size: CGFloat = large ? 22 : 12
        if rows {
            VStack(spacing: large ? 4 : 2) {
                ForEach(0..<count, id: \.self) { _ in
                    HStack(spacing: large ? 4 : 2) {
                        ForEach(0..<each, id: \.self) { _ in Text(item).font(.system(size: size)) }
                    }
                }
            }
            .accessibilityHidden(true)
        } else {
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: large ? 8 : 4), count: min(count, large ? 3 : 2))
            LazyVGrid(columns: columns, spacing: large ? 8 : 4) {
                ForEach(0..<count, id: \.self) { _ in
                    // each group: its things in a small cluster inside a circle
                    let inRow = each <= 3 ? each : (each + 1) / 2
                    VStack(spacing: 0) {
                        ForEach(0..<((each + inRow - 1) / inRow), id: \.self) { r in
                            HStack(spacing: 0) {
                                ForEach(0..<min(inRow, each - r * inRow), id: \.self) { _ in Text(item).font(.system(size: size)) }
                            }
                        }
                    }
                    .padding(large ? 8 : 4)
                    .background(Circle().fill(color.opacity(0.12)).overlay(Circle().stroke(color.opacity(0.5), lineWidth: 2)))
                }
            }
            .accessibilityHidden(true)
        }
    }
}

/// A ribbon measured in blocks. Every ribbon starts at the same left edge.
struct RibbonDrawing: View {
    let length: Int
    let color: Color
    let units: Bool
    let large: Bool

    var body: some View {
        let unit: CGFloat = large ? 30 : 20
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 5).fill(color)
                .frame(width: unit * CGFloat(length), height: large ? 20 : 14)
                .overlay(alignment: .trailing) { Circle().fill(.white.opacity(0.6)).frame(width: 6, height: 6).padding(.trailing, 4) }
            if units {
                HStack(spacing: 0) {
                    ForEach(0..<length, id: \.self) { i in
                        Rectangle().fill(i % 2 == 0 ? Palette.ink.opacity(0.14) : Palette.ink.opacity(0.06))
                            .frame(width: unit, height: unit * 0.7)
                            .overlay(Rectangle().stroke(Palette.ink.opacity(0.35), lineWidth: 1))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// A pie or a bar cut into equal pieces.
struct FractionDrawing: View {
    let parts: Int
    let shaded: Int
    let round: Bool
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let n = max(1, parts)
            if round {
                let r = min(size.width, size.height) / 2 - 3
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<n {
                    var p = Path()
                    p.move(to: c)
                    p.addArc(center: c, radius: r, startAngle: .degrees(-90 + 360 * Double(i) / Double(n)),
                             endAngle: .degrees(-90 + 360 * Double(i + 1) / Double(n)), clockwise: false)
                    p.closeSubpath()
                    ctx.fill(p, with: .color(i < shaded ? color : Color(hex: 0xFFF4E0)))
                    ctx.stroke(p, with: .color(Palette.ink), lineWidth: 2.5)
                }
            } else {
                let w = (size.width - 6) / CGFloat(n)
                for i in 0..<n {
                    let rect = CGRect(x: 3 + CGFloat(i) * w, y: 3, width: w, height: size.height - 6)
                    ctx.fill(Path(rect), with: .color(i < shaded ? color : Color(hex: 0xFFF4E0)))
                    ctx.stroke(Path(rect), with: .color(Palette.ink), lineWidth: 2.5)
                }
            }
        }
        .accessibilityLabel("\(shaded) of \(parts) parts colored")
    }
}

/// Flat shapes drawn as paths; solid shapes as SF Symbols.
struct ShapeDrawing: View {
    let kind: ShapeKind
    let color: Color

    var body: some View {
        if kind.isSolid {
            Image(systemName: symbol).resizable().scaledToFit().foregroundStyle(color)
        } else {
            Canvas { ctx, size in
                let p = path(in: CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4))
                ctx.fill(p, with: .color(color))
                ctx.stroke(p, with: .color(Palette.ink), lineWidth: 3)
            }
        }
    }

    private var symbol: String {
        switch kind {
        case .cube: return "cube.fill"
        case .sphere: return "circle.fill"
        case .cylinder: return "cylinder.fill"
        case .cone: return "cone.fill"
        default: return "pyramid.fill"
        }
    }

    private func path(in r: CGRect) -> Path {
        func polygon(_ n: Int, rotate: Double = -90) -> Path {
            var p = Path()
            let c = CGPoint(x: r.midX, y: r.midY), rad = min(r.width, r.height) / 2
            for i in 0..<n {
                let a = (rotate + 360 * Double(i) / Double(n)) * .pi / 180
                let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            return p
        }
        switch kind {
        case .circle: return Path(ellipseIn: r.insetBy(dx: (r.width - min(r.width, r.height)) / 2, dy: (r.height - min(r.width, r.height)) / 2))
        case .oval: return Path(ellipseIn: r.insetBy(dx: 0, dy: r.height * 0.2))
        case .square: return Path(r.insetBy(dx: r.width * 0.08, dy: r.height * 0.08))
        case .rectangle: return Path(r.insetBy(dx: 0, dy: r.height * 0.25))
        case .triangle: return polygon(3)
        case .pentagon: return polygon(5)
        case .hexagon: return polygon(6, rotate: 0)
        case .rhombus:
            var p = Path()
            p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.midY))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX + r.width * 0.15, y: r.midY)); p.closeSubpath()
            return p
        default: return Path(r)
        }
    }
}
