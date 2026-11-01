import SwiftUI

/// The Writing Desk: Polly Panda's desk, with four tracing games (big letters, small letters, numbers, words).
struct WritingDeskView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: WritingGame?

    private let accent = Color(hex: 0x2F6FD1)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF2F7FF), Color(hex: 0xD9E8FF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let game = playing {
                WritingGameView(game: game, color: accent,
                                onFinish: { stars, letters in store.recordWriting(game, stars: stars, letters: letters) },
                                onBack: { playing = nil; greet(again: true) })
                    .id(game)
                    .transition(.pushIn)
            } else {
                list.transition(.pushedBack)
            }
        }
        .animation(Motion.standard, value: playing)
        .onAppear { greet(again: false) }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PlaceHeader(host: PlaceHost.writing, title: "Writing Desk", line: "Grab a pencil! Let's write together.",
                            stars: store.profile?.writing.totalStars ?? 0, maxStars: WritingSave.maxStars,
                            accent: accent, onBack: onBack)
                    .padding(.bottom, 4)
                ForEach(WritingGame.allCases) { g in
                    LearnGameCard(symbol: g.symbol, title: g.title, blurb: g.intro, stars: store.profile?.writing.best(g) ?? 0,
                                  color: accent) {
                        playing = g
                    }
                }
                let written = store.profile?.writing.written.count ?? 0
                Text(written > 0 ? "You've written \(written) of 62 letters and numbers." : "Each game gives up to 3 stars. Beat your best for more.")
                    .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    private func greet(again: Bool) {
        Narrator.shared.say(again ? "Pick another writing game!" : "Hi, I'm Polly! Welcome to the Writing Desk. Pick something to write!")
    }
}

/// One play: trace each letter stroke by stroke, then stars.
struct WritingGameView: View {
    let game: WritingGame
    let color: Color
    /// Returns the new stars given.
    var onFinish: (Int, [String]) -> Int
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rounds: [WritingRound] = []
    @State private var index = 0
    /// Which letter of the round (words have three) and which stroke of that letter.
    @State private var letter = 0
    @State private var stroke = 0
    @State private var ink: [PenPoint] = []
    @State private var missed = false
    @State private var firstTry = 0
    @State private var hint: TraceVerdict?
    @State private var shakes = 0
    @State private var demoStart: Date?
    @State private var roundDone = false
    @State private var result: (stars: Int, earned: Int)?
    @State private var advanceTask: Task<Void, Never>?

    private var round: WritingRound? { rounds.indices.contains(index) ? rounds[index] : nil }
    private var glyph: Glyph? { round.flatMap { $0.glyphs.indices.contains(letter) ? $0.glyphs[letter] : nil } }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop playing", action: { advanceTask?.cancel(); onBack() })
                Spacer()
                Text(game.title).font(.kid(20, .black)).displayTracking(20).foregroundStyle(Palette.ink)
                Spacer()
                SpeakButton(label: "Say it again") { if let r = round { Narrator.shared.sayAnyway(r.say) } }
            }
            RoundDots(done: index, total: max(rounds.count, 1))
            if let r = round, let g = glyph, result == nil {
                if r.glyphs.count > 1 { wordStrip(r) }
                TracePad(glyph: g, stroke: roundDone ? g.strokes.count : stroke, ink: ink, color: color,
                         demoStart: demoStart, reduceMotion: reduceMotion,
                         onBegin: { ink = [] }, onDraw: { ink.append($0) }, onLift: lift)
                    .modifier(Shake(animatableData: reduceMotion ? 0 : CGFloat(shakes)))
                    .accessibilityElement()
                    .accessibilityLabel("Tracing \(g.character). Stroke \(min(stroke + 1, g.strokes.count)) of \(g.strokes.count).")
                    .accessibilityAction(named: "Trace this stroke for me") { finishStroke() }
                HStack(spacing: 12) {
                    Label(hint?.hint ?? "Start at the green dot", systemImage: hint == nil ? "hand.point.up.left.fill" : "lightbulb.fill")
                        .font(.kid(15, .bold)).foregroundStyle(Palette.ink.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        Haptics.tap()
                        let started = Date()
                        demoStart = started
                        Narrator.shared.say("Watch me first.")
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_700_000_000)
                            if demoStart == started { demoStart = nil }
                        }
                    } label: {
                        Label("Show me", systemImage: "play.fill")
                            .font(.kid(15, .black)).foregroundStyle(.white)
                            .padding(.horizontal, 14).frame(minHeight: 44)
                            .background(Capsule().fill(color))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
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
                                  host: PlaceHost.writing, onAgain: start, onBack: onBack)
                }
            }
        }
        .onAppear(perform: start)
        .onDisappear { advanceTask?.cancel() }
    }

    /// For words: the picture and the three letters, with the one being written underlined.
    private func wordStrip(_ r: WritingRound) -> some View {
        HStack(spacing: 10) {
            Text(r.picture).font(.system(size: 44)).accessibilityHidden(true)
            ForEach(Array(r.glyphs.enumerated()), id: \.offset) { i, g in
                Text(g.character)
                    .font(.kid(34, .black))
                    .foregroundStyle(i < letter ? color : Palette.ink.opacity(i == letter ? 1 : 0.35))
                    .frame(width: 46, height: 54)
                    .overlay(alignment: .bottom) {
                        Capsule().fill(i == letter ? color : .clear).frame(height: 4)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Writing the word \(r.text), letter \(letter + 1) of \(r.glyphs.count)")
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = WritingBank.rounds(for: game)
        index = 0; firstTry = 0; result = nil
        resetRound()
        Narrator.shared.say("\(game.intro) \(rounds.first?.say ?? "")")
    }

    private func resetRound() {
        letter = 0; stroke = 0; ink = []; missed = false; hint = nil; demoStart = nil; roundDone = false
    }

    private func lift() {
        guard let g = glyph, !roundDone, g.strokes.indices.contains(stroke), !ink.isEmpty else { return }
        let verdict = TraceChecker.check(drawn: ink, against: g.strokes[stroke])
        if verdict == .good {
            finishStroke()
        } else {
            missed = true
            hint = verdict
            Haptics.bump(.oops)
            Narrator.shared.say(verdict.hint)
            withAnimation(.easeOut(duration: 0.35)) { shakes += 1 }
            ink = []
        }
    }

    private func finishStroke() {
        guard let r = round, let g = glyph, !roundDone else { return }
        ink = []; hint = nil; demoStart = nil
        if stroke + 1 < g.strokes.count {
            Haptics.tap(.pop)
            stroke += 1
            return
        }
        // the letter is done
        if letter + 1 < r.glyphs.count {
            Haptics.success(.chime)
            Narrator.shared.say(g.character.uppercased())
            letter += 1; stroke = 0
            return
        }
        roundDone = true
        Haptics.success(.correct)
        if !missed { firstTry += 1 }
        Narrator.shared.say(r.glyphs.count > 1 ? "You wrote \(r.text)! \(WritingBank.cheers.randomElement()!)" : WritingBank.cheers.randomElement()!)
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            if index + 1 < rounds.count {
                index += 1
                resetRound()
                Narrator.shared.say(rounds[index].say)
            } else {
                index = rounds.count
                let stars = LearnScore.stars(firstTry: firstTry, of: rounds.count)
                let letters = rounds.flatMap { $0.glyphs.map(\.character) }
                let earned = onFinish(stars, letters)
                Haptics.success(.fanfare)
                withAnimation(Motion.present) { result = (stars, earned) }
                Narrator.shared.say(earned > 0 ? "You did it! \(earned) new stars!" : "You did it! Lovely writing!")
            }
        }
    }
}

/// Lined paper with the letter to trace: finished strokes in color, the current one with a green start dot and an arrow,
/// and the child's own pencil line.
struct TracePad: View {
    let glyph: Glyph
    /// The stroke to trace now (strokes before it are done).
    let stroke: Int
    let ink: [PenPoint]
    let color: Color
    let demoStart: Date?
    let reduceMotion: Bool
    /// A new finger stroke started (clears anything left over from a touch the system cancelled).
    var onBegin: () -> Void
    var onDraw: (PenPoint) -> Void
    var onLift: () -> Void

    @State private var strokeStart: CGPoint?

    var body: some View {
        GeometryReader { geo in
            let map = Mapping(size: geo.size, glyph: glyph)
            TimelineView(.animation(paused: demoStart == nil)) { tl in
                Canvas { ctx, _ in
                    draw(in: &ctx, map: map, now: tl.date)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { v in
                        if strokeStart != v.startLocation {
                            strokeStart = v.startLocation
                            onBegin()
                        }
                        onDraw(map.unit(v.location))
                    }
                    .onEnded { _ in strokeStart = nil; onLift() }
            )
        }
        .aspectRatio(0.9, contentMode: .fit)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white)
            .shadow(color: Palette.ink.opacity(0.12), radius: 0, x: 0, y: 4))
        .frame(maxWidth: 520)
    }

    /// Letter units ↔ points.
    struct Mapping {
        let scale: CGFloat
        let origin: CGPoint
        init(size: CGSize, glyph: Glyph) {
            scale = min(size.height * 0.8, size.width * 1.1)
            let w = CGFloat(glyph.width - glyph.minX) * scale
            origin = CGPoint(x: (size.width - w) / 2 - CGFloat(glyph.minX) * scale, y: (size.height - scale) / 2 + scale * 0.02)
        }
        func point(_ p: PenPoint) -> CGPoint { CGPoint(x: origin.x + CGFloat(p.x) * scale, y: origin.y + CGFloat(p.y) * scale) }
        func unit(_ p: CGPoint) -> PenPoint { PenPoint(Double((p.x - origin.x) / scale), Double((p.y - origin.y) / scale)) }
        func path(_ pts: [PenPoint]) -> Path {
            var path = Path()
            guard let first = pts.first else { return path }
            path.move(to: point(first))
            for p in pts.dropFirst() { path.addLine(to: point(p)) }
            return path
        }
        /// The paper lines span the whole pad.
        func lineY(_ y: Double) -> CGFloat { origin.y + CGFloat(y) * scale }
    }

    private func draw(in ctx: inout GraphicsContext, map: Mapping, now: Date) {
        let width = map.scale * 0.085
        let full = ctx.clipBoundingRect
        // paper: top line, dashed middle, baseline
        for (y, dashed) in [(0.0, false), (0.4, true), (0.8, false)] {
            var p = Path()
            p.move(to: CGPoint(x: full.minX + 16, y: map.lineY(y)))
            p.addLine(to: CGPoint(x: full.maxX - 16, y: map.lineY(y)))
            ctx.stroke(p, with: .color(Color(hex: y == 0.8 ? 0x9DB7E8 : 0xC9D8F2)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: dashed ? [10, 8] : []))
        }
        // every stroke: done ones in color, the rest as a soft guide
        for (i, s) in glyph.strokes.enumerated() {
            let path = map.path(s)
            if i < stroke {
                ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            } else {
                ctx.stroke(path, with: .color(Color(hex: i == stroke ? 0xDCE6F7 : 0xEEF2F9)),
                           style: StrokeStyle(lineWidth: width * 1.25, lineCap: .round, lineJoin: .round))
                ctx.stroke(path, with: .color(Color(hex: 0xA9B8D3)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 9]))
            }
        }
        // the current stroke: green start dot, and an arrow showing the way
        if glyph.strokes.indices.contains(stroke) {
            let s = glyph.strokes[stroke]
            let start = map.point(s[0])
            ctx.fill(Path(ellipseIn: CGRect(x: start.x - 13, y: start.y - 13, width: 26, height: 26)), with: .color(Palette.green))
            ctx.stroke(Path(ellipseIn: CGRect(x: start.x - 13, y: start.y - 13, width: 26, height: 26)), with: .color(.white), lineWidth: 3)
            if s.count > 4 {
                let a = map.point(s[min(s.count - 1, max(2, s.count / 4))])
                let b = map.point(s[min(s.count - 1, max(3, s.count / 4 + 2))])
                drawArrow(in: &ctx, at: a, toward: b)
            }
            // "Show me": a pencil dot runs along the stroke
            if let demoStart {
                let t = now.timeIntervalSince(demoStart) / 1.3
                if reduceMotion {
                    if t < 1 { ctx.stroke(map.path(s), with: .color(color.opacity(0.6)), style: StrokeStyle(lineWidth: width, lineCap: .round)) }
                } else if t < 1.15 {
                    let n = Int(Double(s.count - 1) * min(1, t))
                    ctx.stroke(map.path(Array(s.prefix(n + 1))), with: .color(color.opacity(0.5)),
                               style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                    let p = map.point(s[n])
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20)), with: .color(color))
                }
            }
        }
        // the child's line
        if !ink.isEmpty {
            ctx.stroke(map.path(ink), with: .color(Palette.ink),
                       style: StrokeStyle(lineWidth: max(6, width * 0.55), lineCap: .round, lineJoin: .round))
        }
    }

    private func drawArrow(in ctx: inout GraphicsContext, at a: CGPoint, toward b: CGPoint) {
        let angle = atan2(b.y - a.y, b.x - a.x)
        let len: CGFloat = 16
        var p = Path()
        let tip = CGPoint(x: a.x + cos(angle) * len, y: a.y + sin(angle) * len)
        p.move(to: tip)
        p.addLine(to: CGPoint(x: a.x + cos(angle + 2.5) * len * 0.8, y: a.y + sin(angle + 2.5) * len * 0.8))
        p.addLine(to: CGPoint(x: a.x + cos(angle - 2.5) * len * 0.8, y: a.y + sin(angle - 2.5) * len * 0.8))
        p.closeSubpath()
        ctx.fill(p, with: .color(Palette.green))
    }
}
