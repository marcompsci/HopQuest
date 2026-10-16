import SwiftUI

/// The Coding Lab: three learning tracks (Web Designer, Python Coder, Game Maker), each building one project
/// lesson by lesson, plus a shelf of everything the child has made.
struct CodingLabView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var openLesson: CodeLesson?
    @State private var openProject: CodeTrack?
    @State private var openSandbox: CodeTrack?
    @State private var expanded: CodeTrack?

    private static let teacher = Roster.character(id: "ocho")
    private var save: CodeLabSave { store.profile?.codeLab ?? CodeLabSave() }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1E1B2E), Color(hex: 0x3A2E6E)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    teacherBubble
                    ForEach(CodeTrack.allCases) { track in trackCard(track) }
                    if !save.completed.isEmpty { creations }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .fullScreenCover(item: $openLesson) { lesson in
            CodeLessonView(lesson: lesson,
                           onExit: { openLesson = nil },
                           onNext: { next in
                               openLesson = nil
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { openLesson = next }
                           })
                .environmentObject(store)
        }
        .fullScreenCover(item: $openProject) { track in
            ProjectView(track: track, onClose: { openProject = nil })
                .environmentObject(store)
        }
        .fullScreenCover(item: $openSandbox) { track in
            SandboxView(track: track, onClose: { openSandbox = nil })
                .environmentObject(store)
        }
        .onAppear {
            Narrator.shared.say("Welcome to the Coding Lab! Pick a track and let's build something.")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
            Text("Coding Lab 💻").font(.kid(28, .black)).foregroundStyle(.white)
            Spacer()
            HStack(spacing: 4) {
                ArtImage("goal_star").frame(width: 22, height: 22)
                Text("\(store.profile?.stars ?? 0)")
            }
            .font(.kid(18, .black)).foregroundStyle(Palette.ink)
            .padding(.horizontal, 12).frame(height: 44)
            .background(Capsule().fill(.white.opacity(0.92)))
        }
    }

    private var teacherBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            CharacterBadge(character: Self.teacher, size: 62, animated: true)
            Text("Hi, I'm Ocho! Here you learn real code: HTML and CSS for websites, and Python for programs and games. Every lesson, you build something new. Then try Free Build and make anything you like!")
                .font(.kid(16, .bold)).foregroundStyle(Palette.ink)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white))
        }
    }

    private func trackCard(_ track: CodeTrack) -> some View {
        let lessons = CodeCurriculum.lessons(for: track)
        let doneCount = lessons.filter { save.isDone($0) }.count
        let next = save.nextLesson(in: track)
        let tint = Color(hex: track.colorHex)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(track.icon).font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.25)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.kid(22, .black))
                    Text("\(track.language) · \(track.builds)").font(.kid(14, .bold)).opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                ForEach(lessons) { l in
                    Capsule().fill(save.isDone(l) ? Color.white : Color.white.opacity(0.3)).frame(height: 8)
                }
                Text("\(doneCount)/\(lessons.count)").font(.kid(13, .black))
            }
            HStack(spacing: 10) {
                if let next {
                    Button {
                        Haptics.tap()
                        openLesson = next
                    } label: {
                        Label(doneCount == 0 ? "Start lesson 1" : "Lesson \(next.number): \(next.title)", systemImage: "play.fill")
                            .font(.kid(16, .black)).foregroundStyle(tint)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 14).frame(height: 44)
                            .background(Capsule().fill(.white))
                    }
                    .buttonStyle(BouncyButtonStyle())
                } else {
                    Label("All done! 🏆", systemImage: "checkmark.seal.fill").font(.kid(16, .black))
                }
                Spacer()
                Button {
                    withAnimation(.spring()) { expanded = expanded == track ? nil : track }
                } label: {
                    Image(systemName: expanded == track ? "chevron.up.circle.fill" : "list.bullet.circle.fill")
                        .font(.system(size: 30))
                }
                .accessibilityLabel("Show all \(track.title) lessons")
            }
            freeBuildButton(track, tint: tint)
            if expanded == track {
                VStack(spacing: 6) {
                    ForEach(lessons) { l in lessonRow(l, tint: tint) }
                }
                .transition(.opacity)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(tint)
            .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 5))
    }

    /// Free Build opens after the first lesson of a track.
    private func freeBuildButton(_ track: CodeTrack, tint: Color) -> some View {
        let open = Sandbox.isOpen(track, save: save)
        let count = save.sandbox.lines(for: track).count
        return Button {
            guard open else { return }
            Haptics.tap()
            openSandbox = track
        } label: {
            HStack(spacing: 8) {
                Text("🧪").font(.system(size: 22))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Free Build").font(.kid(16, .black))
                    Text(open ? (count == 0 ? "Make your own \(Self.thing(track)) from scratch" : "Your project: \(count) lines")
                              : "Opens after lesson 1")
                        .font(.kid(12, .bold)).opacity(0.85)
                }
                Spacer()
                Image(systemName: open ? "chevron.right.circle.fill" : "lock.fill").font(.title3)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(open ? 0.22 : 0.1)))
            .opacity(open ? 1 : 0.65)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!open)
        .accessibilityLabel(open ? "Free Build for \(track.title)" : "Free Build, opens after lesson 1")
    }

    private static func thing(_ track: CodeTrack) -> String {
        switch track {
        case .web: return "web page"
        case .python: return "program"
        case .games: return "game"
        }
    }

    private func lessonRow(_ l: CodeLesson, tint: Color) -> some View {
        let unlocked = save.isUnlocked(l)
        return Button {
            guard unlocked else { return }
            Haptics.tap()
            openLesson = l
        } label: {
            HStack(spacing: 10) {
                Text("\(l.number)").font(.kid(16, .black)).frame(width: 30, height: 30)
                    .background(Circle().fill(.white.opacity(0.3)))
                VStack(alignment: .leading, spacing: 0) {
                    Text(l.title).font(.kid(16, .black))
                    Text(l.goal).font(.kid(12, .bold)).opacity(0.85)
                }
                Spacer()
                Image(systemName: save.isDone(l) ? "checkmark.circle.fill" : (unlocked ? "play.circle.fill" : "lock.fill"))
                    .font(.title3)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(unlocked ? 0.2 : 0.08)))
            .opacity(unlocked ? 1 : 0.6)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!unlocked)
        .accessibilityLabel("Lesson \(l.number), \(l.title), \(save.isDone(l) ? "done" : unlocked ? "ready" : "locked")")
    }

    private var creations: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My creations").font(.kid(22, .black)).foregroundStyle(.white)
            ForEach(CodeTrack.allCases.filter { t in CodeCurriculum.lessons(for: t).contains { save.isDone($0) } }) { track in
                Button {
                    Haptics.tap()
                    openProject = track
                } label: {
                    HStack {
                        Text(track.icon).font(.system(size: 28))
                        Text(track == .web ? "Open my web page" : track == .python ? "Run my Python program" : "Play my game")
                            .font(.kid(18, .black))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }
}

/// A finished (or growing) project to run and remix: every blank can be changed.
struct ProjectView: View {
    let track: CodeTrack
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0xFAF8FF).ignoresSafeArea()
            VStack(spacing: 10) {
                HStack {
                    CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
                    Text("\(track.icon) My \(track == .web ? "web page" : track == .python ? "Python program" : "game")")
                        .font(.kid(22, .black)).foregroundStyle(Palette.ink)
                    Spacer()
                }
                Text("Remix it! Tap any colored blank to change your code, then press ▶ Run.")
                    .font(.kid(14, .bold)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CodeWorkspaceView(track: track, current: nil)
            }
            .padding(14)
        }
    }
}
