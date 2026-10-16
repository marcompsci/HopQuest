import SwiftUI

/// One Coding Lab lesson: learn the idea (short cards read aloud), build it into your project, run it,
/// answer a quick check, and celebrate what you made.
struct CodeLessonView: View {
    @EnvironmentObject var store: GameStore
    let lesson: CodeLesson
    var onExit: () -> Void
    var onNext: (CodeLesson) -> Void

    private enum Phase: Equatable { case learn(Int), build, check, done(Bool) }

    @State private var phase: Phase = .learn(0)
    @State private var ranOK = false
    @State private var quiz: Question?

    private static let teacher = Roster.character(id: "ocho")

    var body: some View {
        ZStack {
            Color(hex: lesson.track.colorHex).opacity(0.18).ignoresSafeArea()
            Color(hex: 0xFAF8FF).opacity(0.85).ignoresSafeArea()
            VStack(spacing: 10) {
                header
                switch phase {
                case .learn(let i):
                    learnCard(i)
                case .build, .check:
                    buildArea
                case .done(let first):
                    doneView(firstTime: first)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            if let quiz {
                Color.black.opacity(0.35).ignoresSafeArea()
                QuizCard(question: quiz) { _ in
                    self.quiz = nil
                    finish()
                }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: phase)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: quiz?.id)
        .onDisappear { Narrator.shared.stop() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "xmark", label: "Leave the lesson", action: onExit)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(lesson.track.icon) \(lesson.track.title) · Lesson \(lesson.number)")
                    .font(.kid(13, .bold)).foregroundStyle(Color(hex: lesson.track.colorHex))
                Text(lesson.title).font(.kid(20, .black)).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            stepDots
        }
    }

    private var stepDots: some View {
        let index: Int
        switch phase {
        case .learn: index = 0
        case .build: index = 1
        case .check: index = 2
        case .done: index = 3
        }
        return HStack(spacing: 5) {
            ForEach(0..<4) { i in
                Circle().fill(i <= index ? Color(hex: lesson.track.colorHex) : Color(hex: 0xDDD9EA))
                    .frame(width: 9, height: 9)
            }
        }
        .accessibilityLabel(["Learn", "Build", "Check", "Done"][index])
    }

    // MARK: Learn

    private func learnCard(_ i: Int) -> some View {
        let card = lesson.cards[i]
        return VStack(spacing: 16) {
            Spacer(minLength: 0)
            HStack(alignment: .top, spacing: 12) {
                CharacterBadge(character: Self.teacher, size: 70, animated: true)
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.title).font(.kid(24, .black)).foregroundStyle(Palette.ink)
                    Text(card.text).font(.kid(19, .bold)).foregroundStyle(Palette.ink.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let example = card.example {
                Text(example)
                    .font(.system(size: 19, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xA5E075))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(CodeTheme.background))
                    .accessibilityLabel("Example code: \(example)")
            }
            if i == 0 {
                Label("You'll build: \(lesson.goal)", systemImage: "hammer.fill")
                    .font(.kid(16, .black)).foregroundStyle(Color(hex: lesson.track.colorHex))
            }
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                SpeakButton { Narrator.shared.say(card.title + ". " + card.text) }
                BigButton(title: i + 1 < lesson.cards.count ? "Next" : "Let's build! 🔨", color: Color(hex: lesson.track.colorHex)) {
                    Narrator.shared.stop()
                    if i + 1 < lesson.cards.count { phase = .learn(i + 1) } else { phase = .build }
                }
            }
            .padding(.bottom, 10)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.12), radius: 10, y: 4))
        .id(i)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        .onAppear { Narrator.shared.say(card.title + ". " + card.text) }
    }

    // MARK: Build

    private var buildArea: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                CharacterBadge(character: Self.teacher, size: 40)
                Text(ranOK ? "It works! You built \(lesson.goal.lowercased())." : "Build it: fill the blanks, then press ▶ Run.")
                    .font(.kid(15, .black)).foregroundStyle(Palette.ink)
                Spacer()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0xFFF4C2)))

            CodeWorkspaceView(track: lesson.track, current: lesson) {
                if !ranOK {
                    ranOK = true
                    Haptics.success(.correct)
                }
            }

            if ranOK {
                BigButton(title: "Quick check ✓", color: Palette.purple) {
                    phase = .check
                    quiz = makeQuiz()
                }
                .padding(.bottom, 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func makeQuiz() -> Question {
        let q = lesson.quiz
        let shuffled = q.choices.shuffled()
        return Question(subject: .coding, prompt: q.prompt, choices: shuffled,
                        answer: shuffled.firstIndex(of: q.choices[0]) ?? 0, explain: q.explain)
    }

    private func finish() {
        let first = store.completeCodeLesson(lesson.id)
        if first { Haptics.success(.fanfare) }
        phase = .done(first)
    }

    // MARK: Done

    private func doneView(firstTime: Bool) -> some View {
        let next = CodeCurriculum.lessons(for: lesson.track).first { $0.number == lesson.number + 1 }
        return VStack(spacing: 16) {
            Spacer(minLength: 0)
            Text("🎉").font(.system(size: 64))
            Text("You built \(lesson.goal.lowercased())!")
                .font(.kid(26, .black)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
            if firstTime {
                Text("+2 stars ⭐ · Saved to your project").font(.kid(18, .black)).foregroundStyle(Palette.purple)
            }
            VStack(alignment: .leading, spacing: 6) {
                Label("Did you know?", systemImage: "lightbulb.fill").font(.kid(16, .black)).foregroundStyle(Color(hex: 0xE0A92E))
                Text(lesson.funFact).font(.kid(17, .bold)).foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xFFF4C2)))
            Spacer(minLength: 0)
            if let next {
                BigButton(title: "Next lesson: \(next.title) ▶", color: Color(hex: lesson.track.colorHex)) { onNext(next) }
            } else {
                Text("You finished \(lesson.track.title)! 🏆 Open your project any time to remix it.")
                    .font(.kid(17, .black)).foregroundStyle(Palette.green).multilineTextAlignment(.center)
            }
            BigButton(title: "Back to the Coding Lab", color: Color.gray, action: onExit)
                .padding(.bottom, 10)
        }
        .onAppear {
            Narrator.shared.say("You built \(lesson.goal.lowercased())! Did you know? \(lesson.funFact)")
        }
    }
}
