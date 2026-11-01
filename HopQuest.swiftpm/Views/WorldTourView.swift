import SwiftUI

/// Around the World: Pip Penguin's trip to all seven continents, with four games and a postcard for every continent.
struct WorldTourView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var playing: WorldGame?
    @State private var reading: Continent?

    private let accent = Color(hex: 0x5B4BC4)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xEEF6FF), Color(hex: 0xCFE6FA)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let game = playing {
                WorldGameView(game: game, color: accent,
                              onFinish: { stars, places in store.recordWorld(game, stars: stars, places: places) },
                              onBack: { playing = nil; greet(again: true) })
                    .id(game)
                    .transition(.pushIn)
            } else {
                list.transition(.pushedBack)
            }
        }
        .animation(Motion.standard, value: playing)
        .overlay {
            if let c = reading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { reading = nil }
                    PostcardView(continent: c) { reading = nil }
                        .transition(.panel)
                }
            }
        }
        .animation(Motion.present, value: reading)
        .onAppear { greet(again: false) }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PlaceHeader(host: PlaceHost.world, title: "Around the World", line: "Pack your bags! Let's visit all seven continents.",
                            stars: store.profile?.world.totalStars ?? 0, maxStars: WorldTourSave.maxStars,
                            accent: accent, onBack: onBack)
                    .padding(.bottom, 4)
                postcards
                ForEach(WorldGame.allCases) { g in
                    LearnGameCard(symbol: g.symbol, title: g.title, blurb: g.intro, stars: store.profile?.world.best(g) ?? 0,
                                  color: accent) {
                        playing = g
                    }
                }
                Text("Get a continent right to send a postcard home.")
                    .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    /// Seven postcard slots; collected ones can be opened and read.
    private var postcards: some View {
        let have = store.profile?.world.postcards ?? []
        return VStack(alignment: .leading, spacing: 8) {
            Text("Postcards \(have.count) of 7").font(.kid(16, .black)).foregroundStyle(Palette.ink).monospacedDigit()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Continent.allCases) { c in
                        let got = have.contains(c.rawValue)
                        Button {
                            guard got else {
                                Haptics.bump(.oops)
                                Narrator.shared.say("Get a question about \(c.name) right to get this postcard!")
                                return
                            }
                            Haptics.tap()
                            reading = c
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: got ? "envelope.open.fill" : "envelope")
                                    .font(.system(size: 22, weight: .bold))
                                Text(c.name).font(.kid(11, .bold)).lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(got ? Palette.ink : Palette.ink.opacity(0.35))
                            .frame(width: 86, height: 70)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(got ? Color(hex: c.colorHex).opacity(0.55) : Color.white.opacity(0.6)))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel(got ? "Postcard from \(c.name). Tap to read." : "\(c.name) postcard, not yet")
                    }
                }
            }
        }
    }

    private func greet(again: Bool) {
        Narrator.shared.say(again ? "Where to next?" : "Hi! I'm Pip. I came all the way from Antarctica! Let's go around the world!")
    }
}

/// A postcard from one continent, read aloud.
struct PostcardView: View {
    let continent: Continent
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ContinentMap(highlight: continent, wrong: [], showLabels: false, onTap: nil)
                .frame(height: 150)
            Text(continent.name).font(.kid(26, .black)).displayTracking(26).foregroundStyle(Palette.ink)
            Text(continent.postcard).font(.kid(17, .semibold)).foregroundStyle(Palette.ink.opacity(0.8))
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                SpeakButton(label: "Read the postcard") { Narrator.shared.sayAnyway(continent.postcard) }
                BigButton(title: "Done", color: Palette.purple, action: onClose)
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.2), radius: 14, y: 6))
        .padding(.horizontal, 20)
        .onAppear { Narrator.shared.say(continent.postcard) }
    }
}

/// Pip's world map: ocean, and the seven continents. With `onTap`, tapping reports the continent under the finger.
struct ContinentMap: View {
    let highlight: Continent?
    let wrong: Set<Continent>
    var showLabels = false
    var onTap: ((Continent?) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let frame = MapFrame(size: geo.size)
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: 0x7CC6EC))
                Canvas { ctx, _ in
                    for c in Continent.allCases {
                        let p = frame.path(c)
                        ctx.fill(p, with: .color(fillColor(c)))
                        let on = c == highlight
                        ctx.stroke(p, with: .color(Palette.ink.opacity(on ? 1 : 0.55)),
                                   style: StrokeStyle(lineWidth: on ? 4 : 2, lineJoin: .round))
                    }
                }
                if showLabels || highlight != nil {
                    ForEach(Continent.allCases.filter { showLabels || $0 == highlight }) { c in
                        Text(c.name)
                            .font(.kid(12, .black)).foregroundStyle(Palette.ink)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(.white.opacity(0.85)))
                            .position(frame.center(c))
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { loc in
                guard let onTap else { return }
                let u = frame.unit(loc)
                onTap(WorldMap.continent(atX: u.x, y: u.y) ?? nearest(x: u.x, y: u.y))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func fillColor(_ c: Continent) -> Color {
        let base = Color(hex: c.colorHex)
        if c == highlight { return base }
        if wrong.contains(c) { return base.opacity(0.3) }
        return base.opacity(highlight == nil ? 0.9 : 0.55)
    }

    /// Map units (x 0…1, y 0…0.5) ↔ points. The map is twice as wide as it is tall, centered.
    struct MapFrame {
        let origin: CGPoint
        let width: CGFloat

        init(size: CGSize) {
            let w = min(size.width, size.height * 2)
            width = w
            origin = CGPoint(x: (size.width - w) / 2, y: (size.height - w / 2) / 2)
        }

        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: origin.x + CGFloat(x) * width, y: origin.y + CGFloat(y) * width)
        }

        func unit(_ p: CGPoint) -> (x: Double, y: Double) {
            (Double((p.x - origin.x) / width), Double((p.y - origin.y) / width))
        }

        func path(_ c: Continent) -> Path {
            var p = Path()
            let pts = c.mapOutline
            p.move(to: point(pts[0].x, pts[0].y))
            for q in pts.dropFirst() { p.addLine(to: point(q.x, q.y)) }
            p.closeSubpath()
            return p
        }

        func center(_ c: Continent) -> CGPoint {
            let m = WorldMap.center(c)
            return point(m.x, m.y)
        }
    }

    /// Small fingers on small continents: a tap just off the coast counts for the closest continent.
    private func nearest(x: Double, y: Double) -> Continent? {
        var best: Continent?
        var bestDistance: Double = 0.03
        for c in Continent.allCases {
            for p in c.mapOutline {
                let dx: Double = p.x - x
                let dy: Double = p.y - y
                let d: Double = (dx * dx + dy * dy).squareRoot()
                if d < bestDistance { bestDistance = d; best = c }
            }
        }
        return best
    }
}

/// One play: five questions, then stars and any new postcards.
struct WorldGameView: View {
    let game: WorldGame
    let color: Color
    var onFinish: (Int, [Continent]) -> (earned: Int, newCards: [Continent])
    var onBack: () -> Void

    @State private var rounds: [WorldRound] = []
    @State private var index = 0
    @State private var missed = false
    @State private var firstTry = 0
    @State private var wrong: Set<String> = []
    @State private var wrongPlaces: Set<Continent> = []
    @State private var right: String?
    @State private var places: [Continent] = []
    @State private var result: (stars: Int, earned: Int)?
    @State private var newCards: [Continent] = []
    @State private var advanceTask: Task<Void, Never>?

    private var round: WorldRound? { rounds.indices.contains(index) ? rounds[index] : nil }

    private var newCardsText: String {
        let names: String = newCards.map(\.name).joined(separator: ", ")
        return newCards.count > 1 ? "New postcards: \(names)" : "New postcard: \(names)"
    }

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
                    VStack(spacing: 10) {
                        if !newCards.isEmpty {
                            Label(newCardsText, systemImage: "envelope.open.fill")
                                .font(.kid(15, .black)).foregroundStyle(Palette.ink)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(Capsule().fill(.regularMaterial))
                        }
                        LearnDoneCard(title: game.title, stars: result.stars, earned: result.earned, firstTry: firstTry, total: rounds.count,
                                      host: PlaceHost.world, onAgain: start, onBack: onBack)
                    }
                }
            }
        }
        .onAppear(perform: start)
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func question(_ r: WorldRound) -> some View {
        VStack(spacing: 16) {
            if r.kind == .tapMap {
                Text("Find \(r.show)").font(.kid(30, .black)).displayTracking(30).foregroundStyle(color)
                ContinentMap(highlight: right != nil ? r.continent : nil, wrong: wrongPlaces, showLabels: false) { tapped in
                    tap(tapped, in: r)
                }
                .aspectRatio(2, contentMode: .fit)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("World map")
                // VoiceOver can't see a map: the same choices as buttons
                .accessibilityActions {
                    ForEach(Continent.allCases) { c in
                        Button(c.name) { tap(c, in: r) }
                    }
                }
                Text("Tip: the continents are the big pieces of land.").font(.kid(14, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
            } else {
                Text(r.show)
                    .font(.system(size: 92))
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.85)))
                    .accessibilityLabel(r.say)
                Text(r.say).font(.kid(19, .bold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 10) {
                    ForEach(r.choices, id: \.self) { c in
                        AnswerButton(text: c, font: .kid(24, .black),
                                     state: right == c ? .right : wrong.contains(c) ? .wrong : .plain) {
                            pick(c, in: r)
                        }
                    }
                }
                if right != nil, let c = r.continent {
                    ContinentMap(highlight: c, wrong: [], showLabels: false, onTap: nil)
                        .aspectRatio(2, contentMode: .fit)
                        .frame(maxHeight: 140)
                        .transition(.panel)
                }
            }
        }
        .animation(Motion.standard, value: right)
    }

    // MARK: Play

    private func start() {
        advanceTask?.cancel()
        rounds = WorldBank.rounds(for: game)
        index = 0; firstTry = 0; result = nil; places = []; newCards = []
        resetRound()
        Narrator.shared.say("\(game.intro) \(rounds.first?.say ?? "")")
    }

    private func resetRound() {
        missed = false; wrong = []; wrongPlaces = []; right = nil
    }

    private func tap(_ c: Continent?, in r: WorldRound) {
        guard right == nil else { return }
        guard let c else {
            Narrator.shared.say("That's the ocean! Tap on the land.")
            return
        }
        if c.rawValue == r.answer {
            right = r.answer
            succeed(r)
        } else {
            missed = true
            wrongPlaces.insert(c)
            Haptics.bump(.oops)
            Narrator.shared.say("That's \(c.name). Try again! \(r.say)")
        }
    }

    private func pick(_ c: String, in r: WorldRound) {
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

    private func succeed(_ r: WorldRound) {
        Haptics.success(.correct)
        if !missed { firstTry += 1 }
        if let c = r.continent { places.append(c) }
        Narrator.shared.say(r.cheer)
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            let wait: UInt64 = r.kind == .tapMap ? 1_800_000_000 : 3_200_000_000
            try? await Task.sleep(nanoseconds: wait)
            guard !Task.isCancelled else { return }
            if index + 1 < rounds.count {
                index += 1
                resetRound()
                Narrator.shared.say(rounds[index].say)
            } else {
                index = rounds.count
                let stars = LearnScore.stars(firstTry: firstTry, of: rounds.count)
                let out = onFinish(stars, places)
                newCards = out.newCards
                Haptics.success(.fanfare)
                withAnimation(Motion.present) { result = (stars, out.earned) }
                var line: String = out.earned > 0 ? "You did it! \(out.earned) new stars!" : "You did it! Great exploring!"
                if !out.newCards.isEmpty {
                    let plural: String = out.newCards.count > 1 ? "s" : ""
                    line += " You got \(out.newCards.count) new postcard\(plural)!"
                }
                Narrator.shared.say(line)
            }
        }
    }
}
