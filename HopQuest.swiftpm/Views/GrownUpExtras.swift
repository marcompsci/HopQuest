import SwiftUI
import Charts

/// Grown-ups' weekly chart (v7.8): minutes played each day this week, from this device only.
struct PlayWeekSection: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let week = (store.profile?.playHistory ?? PlayHistory()).week(endingOn: Date())
        let total = week.reduce(0) { $0 + $1.minutes }
        Section {
            Chart(week, id: \.day) { d in
                BarMark(x: .value("Day", d.day, unit: .day), y: .value("Minutes", d.minutes))
                    .foregroundStyle(Palette.purple.gradient)
                    .cornerRadius(5)
                    .annotation(position: .top) {
                        if d.minutes > 0 { Text("\(d.minutes)").font(.caption2.weight(.semibold)).foregroundStyle(.secondary) }
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) }
            }
            .chartYAxisLabel("min")
            .frame(height: 160)
            .padding(.vertical, 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Minutes played each day this week: " + week.map { "\($0.day.formatted(.dateTime.weekday(.wide))) \($0.minutes)" }.joined(separator: ", "))
            LabeledContent("This week", value: total == 1 ? "1 minute" : "\(total) minutes")
        } header: {
            Text("Play this week")
        } footer: {
            Text("Counted only while HopQuest is open and on screen. Kept on this device for two weeks, never sent anywhere.")
        }
    }
}

/// Certificates (v7.9): one for each learning place where every game has 2 stars or more.
struct CertificatesSection: View {
    @EnvironmentObject var store: GameStore
    @State private var showing: LearningArea?

    var body: some View {
        let done = store.learningAreas.filter(\.finished)
        Section {
            if done.isEmpty {
                Text("When every game in a place has 2 stars or more, a certificate for it shows up here.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ForEach(done) { a in
                    Button { showing = a } label: {
                        Label(a.title, systemImage: "rosette")
                    }
                }
            }
        } header: {
            Text("Certificates")
        } footer: {
            if !done.isEmpty {
                Text("Open one to print it or share it. Nothing is shared unless you choose to.")
            }
        }
        .sheet(item: $showing) { a in CertificateSheet(area: a) }
    }
}

struct CertificateSheet: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let area: LearningArea
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                CertificateCard(name: store.profile?.name ?? "Explorer", place: area.title,
                                skills: area.skills.map(\.skill), character: store.character, date: Date())
                    .aspectRatio(1.414, contentMode: .fit)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .padding(.horizontal)
                if let image {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("\(area.title) certificate", image: Image(uiImage: image))) {
                        Label("Print or share", systemImage: "square.and.arrow.up")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear { render() }
        }
    }

    @MainActor private func render() {
        let card = CertificateCard(name: store.profile?.name ?? "Explorer", place: area.title,
                                   skills: area.skills.map(\.skill), character: store.character, date: Date())
            .frame(width: 1123, height: 794)   // A4 landscape at 96 dpi
        let r = ImageRenderer(content: card)
        r.scale = 2
        image = r.uiImage
    }
}

/// The certificate itself. Drawn in plain fixed sizes so it prints the same everywhere.
struct CertificateCard: View {
    let name: String
    let place: String
    let skills: [String]
    let character: GameCharacter
    let date: Date

    var body: some View {
        GeometryReader { g in
            let u = g.size.width / 1123
            ZStack {
                Color(hex: 0xFFFBF0)
                RoundedRectangle(cornerRadius: 24 * u).stroke(Color(hex: 0xE0A800), lineWidth: 14 * u).padding(22 * u)
                RoundedRectangle(cornerRadius: 16 * u).stroke(Color(hex: 0x7C4DFF).opacity(0.5), lineWidth: 3 * u).padding(44 * u)
                VStack(spacing: 14 * u) {
                    Text("HopQuest").font(.system(size: 30 * u, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0x7C4DFF))
                    Text("Certificate of Learning").font(.system(size: 54 * u, weight: .black, design: .rounded)).foregroundStyle(Color(hex: 0x2B1B3D))
                    Text("This certificate is proudly given to").font(.system(size: 24 * u, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Text(name).font(.system(size: 72 * u, weight: .black, design: .rounded)).foregroundStyle(Color(hex: 0xC2185B))
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text("for finishing every game in \(place)").font(.system(size: 28 * u, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x2B1B3D))
                    Text(skills.prefix(4).map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " · "))
                        .font(.system(size: 19 * u, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 120 * u).lineLimit(2).minimumScaleFactor(0.7)
                    HStack(alignment: .bottom) {
                        VStack(spacing: 4 * u) {
                            Text(date.formatted(date: .long, time: .omitted)).font(.system(size: 22 * u, weight: .semibold, design: .rounded))
                            Rectangle().fill(Color(hex: 0x2B1B3D).opacity(0.4)).frame(width: 240 * u, height: 2 * u)
                            Text("Date").font(.system(size: 16 * u, design: .rounded)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        CharacterBadge(character: character, size: 130 * u)
                        Spacer()
                        VStack(spacing: 4 * u) {
                            Text(" ").font(.system(size: 22 * u))
                            Rectangle().fill(Color(hex: 0x2B1B3D).opacity(0.4)).frame(width: 240 * u, height: 2 * u)
                            Text("Grown-up").font(.system(size: 16 * u, design: .rounded)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 110 * u).padding(.top, 10 * u)
                }
                .padding(.vertical, 60 * u)
                Image(systemName: "star.fill").font(.system(size: 50 * u)).foregroundStyle(Color(hex: 0xFFD93D)).position(x: 110 * u, y: 110 * u)
                Image(systemName: "star.fill").font(.system(size: 50 * u)).foregroundStyle(Color(hex: 0xFFD93D)).position(x: g.size.width - 110 * u, y: 110 * u)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Certificate of Learning for \(name), for finishing every game in \(place)")
    }
}

// MARK: - Practice sheets (v8.8)

/// Printable practice for any game in the quiz-engine places: ten questions on a page, and the answers on the next.
struct PracticeSheetsSection: View {
    @EnvironmentObject var store: GameStore
    static let places = ["spelling", "fractions", "shapes", "rhyme", "numbers", "times", "measure", "feelings", "nature", "calendar", "compass"]

    var body: some View {
        Section {
            ForEach(Self.places, id: \.self) { id in
                let place = QuizPlace.named(id)
                NavigationLink {
                    PracticeGamesList(place: place)
                } label: {
                    HStack {
                        Text(place.title)
                        Spacer()
                        let practising = place.games.filter { (store.profile?.places[id]?.best($0.id) ?? 0) == 1 }.count
                        if practising > 0 {
                            Text("\(practising) practising").font(.footnote).foregroundStyle(.orange)
                        }
                    }
                }
            }
        } header: {
            Text("Practice sheets")
        } footer: {
            Text("Print ten questions to do together on paper, with an answer page. Games your child is still practising are marked. Made on this device.")
        }
    }
}

struct PracticeGamesList: View {
    @EnvironmentObject var store: GameStore
    let place: QuizPlace
    @State private var file: URL?
    @State private var making: String?

    var body: some View {
        List {
            ForEach(place.games) { g in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(g.title)
                        Text(g.skill.firstCapitalized).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if making == g.id, let file {
                        ShareLink(item: file) { Label("Print or share", systemImage: "printer.fill") }
                    } else {
                        Button("Make sheet") { make(g) }.buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle(place.title)
    }

    @MainActor private func make(_ g: QuizGameInfo) {
        let rounds = Array((place.rounds(g.id) + place.rounds(g.id)).prefix(10))
        let name = store.profile?.name ?? ""
        let pages: [AnyView] = [
            AnyView(PracticePage(place: place, game: g, rounds: rounds, name: name, answers: false)),
            AnyView(PracticePage(place: place, game: g, rounds: rounds, name: name, answers: true)),
        ]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(place.title) - \(g.title).pdf")
        if PracticePDF.write(pages, to: url) {
            file = url
            making = g.id
        }
    }
}

enum PracticePDF {
    static let size = CGSize(width: 612, height: 792)   // US Letter

    @MainActor static func write(_ pages: [AnyView], to url: URL) -> Bool {
        var box = CGRect(origin: .zero, size: size)
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return false }
        for page in pages {
            let r = ImageRenderer(content: page.frame(width: size.width, height: size.height).environment(\.colorScheme, .light))
            r.render { _, draw in
                ctx.beginPDFPage(nil)
                draw(ctx)
                ctx.endPDFPage()
            }
        }
        ctx.closePDF()
        return true
    }
}

/// One printed page: the questions, or the answers.
struct PracticePage: View {
    let place: QuizPlace
    let game: QuizGameInfo
    let rounds: [QuizRound]
    let name: String
    let answers: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HopQuest · \(place.title)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(place.accent)
                    Text(answers ? "\(game.title): answers" : game.title).font(.system(size: 22, weight: .heavy, design: .rounded))
                }
                Spacer()
                if !answers {
                    Text("Name: \(name.isEmpty ? "______________" : name)").font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
            if !answers {
                Text(game.intro).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
            }
            Divider()
            if answers {
                ForEach(Array(rounds.enumerated()), id: \.offset) { i, r in
                    HStack(alignment: .top) {
                        Text("\(i + 1).").font(.system(size: 13, weight: .bold, design: .rounded)).frame(width: 24, alignment: .leading)
                        Text(r.say).font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary).lineLimit(2)
                        Spacer()
                        Text(r.answer).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(place.accent)
                    }
                }
            } else {
                let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(Array(rounds.enumerated()), id: \.offset) { i, r in question(i, r) }
                }
            }
            Spacer(minLength: 0)
            Text("Made with HopQuest. Do it together: read each question out loud, then circle or write the answer.")
                .font(.system(size: 9, design: .rounded)).foregroundStyle(.secondary)
        }
        .padding(36)
        .foregroundStyle(Color.black)
        .background(Color.white)
    }

    private func question(_ i: Int, _ r: QuizRound) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(i + 1). \(r.say)").font(.system(size: 11, weight: .semibold, design: .rounded)).lineLimit(3).fixedSize(horizontal: false, vertical: true)
            if r.visual != .none {
                QuizVisualView(visual: r.visual, accent: place.accent, large: false)
                    .frame(maxWidth: .infinity, maxHeight: 70)
                    .scaleEffect(0.8)
            }
            if r.kind == .spell {
                Text("Write it: ____________").font(.system(size: 12, design: .rounded))
            } else if !r.choiceVisuals.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(r.choices.enumerated()), id: \.offset) { k, c in
                        VStack(spacing: 2) {
                            QuizVisualView(visual: r.choiceVisuals[k], accent: place.accent, large: false).frame(height: 44).scaleEffect(0.6)
                            Text("○ \(c)").font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                    }
                }
            } else {
                Text(r.choices.map { "○ \($0)" }.joined(separator: "   ")).font(.system(size: 11, design: .rounded))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.15), lineWidth: 1))
    }
}
