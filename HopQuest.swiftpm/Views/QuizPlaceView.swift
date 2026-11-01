import SwiftUI

/// A learning place built on the shared quiz engine (Spelling Bee, Fraction Bakery, Shape Studio).
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
                    .accessibilityLabel(r.say)
            }
            Text(r.say).font(.kid(19, .bold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if r.kind == .spell {
                spellArea(r)
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
                        .accessibilityLabel("Picture \(c)\(wrong.contains(c) ? ", not this one" : "")")
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
