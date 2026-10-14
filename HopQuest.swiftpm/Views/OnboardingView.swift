import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: GameStore

    private enum Step { case welcome, name, identity, castle, character }

    @State private var step: Step = .welcome
    @State private var name = ""
    @State private var identity: KidIdentity = .noAnswer
    @State private var theme: CastleTheme = .rainbow
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.sky, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut, value: theme)

            switch step {
            case .welcome: welcome
            case .name: nameStep
            case .identity: identityStep
            case .castle: castleStep
            case .character:
                CharacterSelectView(theme: theme, initialID: nil, buttonTitle: "Start my adventure! 🎈") { picked in
                    store.profile = PlayerProfile(name: trimmedName.isEmpty ? "Explorer" : trimmedName,
                                                  identity: identity,
                                                  theme: theme,
                                                  characterID: picked.id)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
        .onAppear { speak(step) }
        .onChange(of: step) { _, newStep in speak(newStep) }
        .overlay(alignment: .topTrailing) {
            SpeakButton { speak(step) }
                .padding(.trailing, 18)
                .padding(.top, 8)
        }
    }

    private func speak(_ s: Step) {
        switch s {
        case .welcome:
            Narrator.shared.say("Welcome to HopQuest! Hop, drive, build, and learn your way to the castle! Tap Let's play.")
        case .name:
            Narrator.shared.say("What should we call you? Type your first name or a nickname.")
        case .identity:
            Narrator.shared.say("Hi \(trimmedName)! Are you a girl, a boy, or would you rather not say?")
        case .castle:
            Narrator.shared.say("Pick your castle! This is where every level ends. You can choose the Sparkle Castle, the Stone Fortress, or the Rainbow Castle.")
        case .character:
            Narrator.shared.say("Now pick your buddy! Tap a character to meet them.")
        }
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 24) {
            Spacer()
            BalloonView(theme: theme, character: Roster.character(id: "lavender"), size: 130)
            Text("HopQuest")
                .font(.kid(48, .black))
                .foregroundStyle(Palette.purple)
            Text("Hop, drive, build, and learn your way to the castle!")
                .font(.kid(20, .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
            BigButton(title: "Let's play!") { step = .name }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
        }
        .transition(.opacity)
    }

    private var nameStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("👋").font(.system(size: 70))
            Text("What should we call you?")
                .font(.kid(28))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            TextField("First name or nickname", text: $name)
                .font(.kid(26, .bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($nameFocused)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white))
                .padding(.horizontal, 32)
                .onSubmit { if !trimmedName.isEmpty { step = .identity } }
                .onChange(of: name) { _, new in
                    if new.count > 14 { name = String(new.prefix(14)) }
                }
            Text("Just a first name or nickname. It stays on this device.")
                .font(.kid(14, .medium))
                .foregroundStyle(Palette.ink.opacity(0.6))
            Spacer()
            BigButton(title: "Next ➜", color: trimmedName.isEmpty ? .gray : Palette.purple) {
                if !trimmedName.isEmpty { step = .identity }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .onAppear { nameFocused = true }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var identityStep: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Hi, \(trimmedName)! 🎉")
                .font(.kid(32, .black))
                .foregroundStyle(Palette.purple)
            Text("Are you a…")
                .font(.kid(24))
                .foregroundStyle(Palette.ink)
            ForEach(KidIdentity.allCases) { option in
                Button {
                    Haptics.tap()
                    identity = option
                    theme = option.suggestedTheme
                    nameFocused = false
                    step = .castle
                } label: {
                    HStack(spacing: 14) {
                        Text(option.emoji).font(.system(size: 36))
                        Text(option.label).font(.kid(22, .bold)).foregroundStyle(Palette.ink)
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 22).fill(.white))
                }
                .buttonStyle(BouncyButtonStyle())
                .padding(.horizontal, 28)
            }
            Spacer()
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var castleStep: some View {
        VStack(spacing: 16) {
            Text("Pick your castle!")
                .font(.kid(30, .black))
                .foregroundStyle(Palette.ink)
                .padding(.top, 30)
            Text("This is where every level ends.")
                .font(.kid(16, .medium))
                .foregroundStyle(Palette.ink.opacity(0.7))
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(CastleTheme.allCases) { option in
                        Button {
                            Haptics.tap()
                            theme = option
                            Narrator.shared.say(option.title)
                        } label: {
                            HStack(spacing: 16) {
                                CastleView(theme: option, width: 96)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(option.title).font(.kid(21)).foregroundStyle(Palette.ink)
                                    if option == identity.suggestedTheme {
                                        Text("Made for you ✨")
                                            .font(.kid(13, .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(Capsule().fill(option.accent))
                                    }
                                }
                                Spacer()
                                Image(systemName: theme == option ? "checkmark.circle.fill" : "circle")
                                    .font(.title)
                                    .foregroundStyle(theme == option ? Palette.green : .gray.opacity(0.4))
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 24).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme == option ? option.accent : .clear, lineWidth: 4))
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
            BigButton(title: "Next ➜") { step = .character }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}

// MARK: - Character picker (onboarding + change later)

struct CharacterSelectView: View {
    let theme: CastleTheme
    let buttonTitle: String
    var onPick: (GameCharacter) -> Void

    @State private var current: GameCharacter

    init(theme: CastleTheme, initialID: String?, buttonTitle: String, onPick: @escaping (GameCharacter) -> Void) {
        self.theme = theme
        self.buttonTitle = buttonTitle
        self.onPick = onPick
        let start = initialID.map { Roster.character(id: $0) } ?? Roster.featured(for: theme).first ?? Roster.all[0]
        _current = State(initialValue: start)
    }

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 12)]

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(current.color.opacity(0.55))
                        .frame(width: 150, height: 34)
                        .offset(y: 6)
                    CharacterBadge(character: current, size: 140, animated: true)
                        .id(current.id)
                        .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                }
                Text(current.name).font(.kid(26, .black)).foregroundStyle(Palette.ink)
                Text("Fun fact: \(current.fact)")
                    .font(.kid(15, .medium))
                    .foregroundStyle(Palette.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 42)
            }
            .padding(.top, 14)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: current.id)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section("Picked for you ✨", Roster.featured(for: theme))
                    ForEach(CharacterFamily.allCases) { family in
                        section(family.rawValue, Roster.all.filter { $0.family == family })
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
            }

            BigButton(title: buttonTitle) { onPick(current) }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
        }
    }

    private func section(_ title: String, _ list: [GameCharacter]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.kid(19)).foregroundStyle(Palette.ink)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(list) { c in
                    Button {
                        Haptics.tap()
                        current = c
                        Narrator.shared.say("\(c.name)! \(c.fact)")
                    } label: {
                        VStack(spacing: 4) {
                            ZStack(alignment: .bottom) {
                                Ellipse()
                                    .fill(c.color.opacity(0.5))
                                    .frame(width: 62, height: 16)
                                CharacterBadge(character: c, size: 70)
                            }
                            Text(c.name)
                                .font(.kid(12, .bold))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(height: 30)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(current.id == c.id ? 1 : 0.7)))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(current.id == c.id ? theme.accent : .clear, lineWidth: 4))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
    }
}
