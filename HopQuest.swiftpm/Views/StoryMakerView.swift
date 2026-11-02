import SwiftUI

/// Story Maker: build a three-page picture story from places, buddies, things that happen and things, then hear it read back.
struct StoryMakerView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    private enum Mode: Equatable { case shelf, make, read(MadeStory) }
    @State private var mode: Mode = .shelf

    private let accent = Color(hex: 0x6A4C93)
    private var host: GameCharacter { Roster.character(id: "ollie") }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF5F0FF), Color(hex: 0xE3D9FF)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            switch mode {
            case .shelf: shelf.transition(.pushedBack)
            case .make:
                StoryBuilder(accent: accent, onCancel: { mode = .shelf }) { story in
                    store.saveStory(story)
                    mode = .read(story)
                }
                .transition(.pushIn)
            case .read(let s):
                StoryReader(story: s, accent: accent) { mode = .shelf }.transition(.pushIn)
            }
        }
        .animation(Motion.standard, value: mode)
        .onAppear { Narrator.shared.say("Welcome to Story Maker! Make your own three-page story, and I'll read it to you.") }
        .onDisappear { Narrator.shared.stop() }
    }

    private var shelf: some View {
        let saved = store.profile?.storyMaker.stories ?? []
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PlaceHeader(host: host, title: "Story Maker", line: "Pick a place, a buddy and what happens. I'll read it to you!",
                            stars: min(3, store.profile?.storyMaker.made ?? 0), maxStars: 3, accent: accent, onBack: onBack)
                Button { mode = .make } label: {
                    Label("Make a new story", systemImage: "plus")
                        .font(.kid(20, .black)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(accent)
                            .shadow(color: accent.opacity(0.5), radius: 0, x: 0, y: 5))
                }
                .buttonStyle(BouncyButtonStyle())
                if !saved.isEmpty {
                    HStack { Text("My stories").font(.kid(18, .black)).foregroundStyle(Palette.ink); Spacer() }
                    ForEach(saved) { s in
                        Button { mode = .read(s) } label: {
                            HStack(spacing: 12) {
                                Text(StoryMakerBank.things.first { $0.id == s.pages.last?.thing }?.emoji ?? "📖")
                                    .font(.system(size: 30)).frame(width: 52, height: 52)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(accent.opacity(0.14)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title).font(.kid(17, .black)).foregroundStyle(Palette.ink)
                                    Text("\(StoryMakerBank.pageCount) pages").font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55))
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill").font(.system(size: 28)).foregroundStyle(accent)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                                .shadow(color: Palette.ink.opacity(0.1), radius: 0, x: 0, y: 4))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Read \(s.title)")
                    }
                }
                Text("Your first three stories earn a star each. Up to six stories are kept.")
                    .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55)).multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18).padding(.top, 8)
        }
    }
}

/// A picture of one page: the place, the buddy, and the thing.
struct StoryStage: View {
    let page: MadePage
    var height: CGFloat = 200

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: page.place.skyHex.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom)
            HStack {
                ForEach(Array(page.place.props.enumerated()), id: \.offset) { _, p in
                    Text(p).font(.system(size: 30)).frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, height * 0.42)
            .opacity(0.8)
            Rectangle().fill(Color(hex: page.place.groundHex)).frame(height: height * 0.24)
            HStack(alignment: .bottom, spacing: 18) {
                CharacterBadge(character: Roster.character(id: page.heroID), size: height * 0.42, animated: true)
                Text(StoryMakerBank.things.first { $0.id == page.thing }?.emoji ?? "").font(.system(size: height * 0.24))
            }
            .padding(.bottom, height * 0.1)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Palette.ink.opacity(0.15), lineWidth: 2))
        .accessibilityHidden(true)
    }
}

/// Pick place, buddy, what happens and the thing, page by page.
struct StoryBuilder: View {
    @EnvironmentObject var store: GameStore
    let accent: Color
    var onCancel: () -> Void
    var onDone: (MadeStory) -> Void

    @State private var pages: [MadePage] = []
    @State private var index = 0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Stop making this story", action: onCancel)
                Spacer()
                Text("Page \(index + 1) of \(StoryMakerBank.pageCount)").font(.kid(20, .black)).foregroundStyle(Palette.ink).monospacedDigit()
                Spacer()
                SpeakButton(label: "Read this page") { Narrator.shared.sayAnyway(sentence) }
            }
            if pages.indices.contains(index) {
                StoryStage(page: pages[index], height: 180)
                ReadAlongText(text: sentence, font: .kid(17, .bold)).multilineTextAlignment(.center)
                    .frame(minHeight: 48).fixedSize(horizontal: false, vertical: true)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        picker("Where?") {
                            ForEach(StoryMakerBank.places, id: \.self) { p in
                                chip(p.props.first ?? "", StoryMakerBank.placeName(p).replacingOccurrences(of: "the ", with: ""), on: pages[index].place == p) {
                                    pages[index].place = p
                                }
                            }
                        }
                        picker("Who?") {
                            ForEach(heroes) { c in
                                Button { pages[index].heroID = c.id; pages[index].heroName = c.name; pages[index].heroEmoji = c.emoji; Haptics.tap() } label: {
                                    CharacterBadge(character: c, size: 44)
                                        .frame(width: 58, height: 62)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(pages[index].heroID == c.id ? accent.opacity(0.25) : .white))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(pages[index].heroID == c.id ? accent : .clear, lineWidth: 3))
                                }
                                .buttonStyle(BouncyButtonStyle())
                                .accessibilityLabel(c.name)
                            }
                        }
                        picker("What happens?") {
                            ForEach(StoryMakerBank.actions, id: \.id) { a in
                                symbolChip(a.symbol, a.text.replacingOccurrences(of: " {thing}", with: "…").replacingOccurrences(of: "{thing}", with: "…"),
                                           on: pages[index].action == a.id) { pages[index].action = a.id }
                            }
                        }
                        picker("What thing?") {
                            ForEach(StoryMakerBank.things, id: \.id) { t in
                                chip(t.emoji, t.name.replacingOccurrences(of: "a ", with: ""), on: pages[index].thing == t.id) { pages[index].thing = t.id }
                            }
                        }
                    }
                }
                HStack(spacing: 12) {
                    if index > 0 { BigButton(title: "Back", color: Color(hex: 0x9AA0AE)) { index -= 1 } }
                    BigButton(title: index + 1 < StoryMakerBank.pageCount ? "Next page" : "Read my story", color: accent) { next() }
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 8)
        .onAppear(perform: begin)
    }

    private var heroes: [GameCharacter] {
        let mine = store.character
        return [mine] + Roster.all.filter { $0.id != mine.id }.prefix(11)
    }

    private var sentence: String {
        pages.indices.contains(index) ? StoryMakerBank.sentence(pages[index], index: index) : ""
    }

    private func begin() {
        guard pages.isEmpty else { return }
        let c = store.character
        let things = StoryMakerBank.things.shuffled()
        pages = (0..<StoryMakerBank.pageCount).map { i in
            MadePage(place: StoryMakerBank.places[i % StoryMakerBank.places.count], heroID: c.id, heroName: c.name, heroEmoji: c.emoji,
                     action: StoryMakerBank.actions[i].id, thing: things[i].id)
        }
        Narrator.shared.say("Page one. Pick where it happens, who is in it, and what happens!")
    }

    private func next() {
        Haptics.tap(.pop)
        if index + 1 < StoryMakerBank.pageCount {
            index += 1
            // the buddy carries over to the next page
            pages[index].heroID = pages[index - 1].heroID
            pages[index].heroName = pages[index - 1].heroName
            pages[index].heroEmoji = pages[index - 1].heroEmoji
            Narrator.shared.say("Page \(index + 1).")
        } else {
            onDone(MadeStory(id: UUID().uuidString, pages: pages, made: Date()))
        }
    }

    private func picker<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.kid(15, .black)).foregroundStyle(Palette.ink)
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { content() }.padding(.vertical, 2) }
        }
    }

    private func chip(_ emoji: String, _ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            HStack(spacing: 6) { Text(emoji); Text(label).font(.kid(14, .bold)).lineLimit(1) }
                .foregroundStyle(on ? .white : Palette.ink)
                .padding(.horizontal, 12).frame(minHeight: 44)
                .background(Capsule().fill(on ? accent : .white))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(label)\(on ? ", picked" : "")")
    }

    private func symbolChip(_ symbol: String, _ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            Label(label, systemImage: symbol).font(.kid(14, .bold)).lineLimit(1)
                .foregroundStyle(on ? .white : Palette.ink)
                .padding(.horizontal, 12).frame(minHeight: 44)
                .background(Capsule().fill(on ? accent : .white))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(label)\(on ? ", picked" : "")")
    }
}

/// Reads a story page by page.
struct StoryReader: View {
    let story: MadeStory
    let accent: Color
    var onDone: () -> Void

    @State private var page = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Close the story", action: onDone)
                Spacer()
                Text(story.title).font(.kid(20, .black)).displayTracking(20).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                SpeakButton(label: "Read this page again") { read() }
            }
            TabView(selection: $page) {
                ForEach(Array(story.pages.enumerated()), id: \.offset) { i, p in
                    VStack(spacing: 16) {
                        StoryStage(page: p, height: 260)
                        ReadAlongText(text: StoryMakerBank.sentence(p, index: i), font: .kid(22, .bold))
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            BigButton(title: page + 1 < story.pages.count ? "Next page" : "The End", color: accent) {
                if page + 1 < story.pages.count { withAnimation(Motion.standard) { page += 1 } } else { onDone() }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .onAppear(perform: read)
        .onChange(of: page) { _, _ in read() }
    }

    private func read() {
        guard story.pages.indices.contains(page) else { return }
        let text = StoryMakerBank.sentence(story.pages[page], index: page)
        Narrator.shared.sayAnyway(page == 0 ? "\(story.title). \(text)" : text)
    }
}
