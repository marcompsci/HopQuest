import SwiftUI

/// The building area: your code on top (tap the blanks to fill them in), ▶ Run, and what your code makes below:
/// a real web page, Python output, or a game you can play.
struct CodeWorkspaceView: View {
    @EnvironmentObject var store: GameStore
    let track: CodeTrack
    /// The lesson being worked on (nil = remixing a finished project).
    let current: CodeLesson?
    /// Called after a successful run with every blank filled.
    var onRanOK: () -> Void = {}

    @State private var editing: String?
    @State private var output: [String] = []
    @State private var error: PyError?
    @State private var ran = false
    @State private var webHTML = ""
    @State private var game: GameProgram?
    @State private var gameNonce = 0
    @State private var toast: String?

    private var save: CodeLabSave { store.profile?.codeLab ?? CodeLabSave() }

    private var project: CodeProject {
        var p = CodeProject(track: track,
                            lessons: CodeProject.lessonsInProject(track: track, save: save, current: current),
                            values: save.values)
        p.kid = store.profile?.name ?? "Friend"
        p.buddy = store.character.name
        p.buddyID = store.character.id
        return p
    }

    private var slotsByKey: [String: CodeSlot] {
        var d: [String: CodeSlot] = [:]
        for l in project.lessons { for t in l.lines { for s in t.slots { d["\(l.id).\(s.id)"] = s } } }
        return d
    }

    var body: some View {
        let p = project
        ZStack(alignment: .bottom) {
            VStack(spacing: 10) {
                CodeEditorView(lines: p.render(), currentLesson: current?.id, errorLine: error?.line,
                               selectedSlot: editing) { key in
                    Haptics.tap()
                    editing = key
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: 10) {
                    Text(hint(p))
                        .font(.kid(14, .bold))
                        .foregroundStyle(Palette.ink.opacity(0.8))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Button { run(p) } label: {
                        Label("Run", systemImage: "play.fill")
                            .font(.kid(19, .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .frame(height: 50)
                            .background(Capsule().fill(p.missingSlots.isEmpty ? Palette.green : Color.gray)
                                .shadow(color: Color(hex: 0x239A5C), radius: 0, x: 0, y: 4))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Run your code")
                }

                outputView
                    .frame(maxHeight: .infinity)
            }

            if let key = editing, let slot = slotsByKey[key] {
                Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { editing = nil }
                SlotPickerView(slot: slot, current: save.values[key], resolve: { resolve($0) }) { choice in
                    store.setCodeValue(key, choice)
                    editing = nil
                    // web pages update right away; Python waits for ▶ Run (that's how coders test)
                    if track == .web && ran { DispatchQueue.main.async { run(project) } }
                } onClose: { editing = nil }
                .padding(.bottom, 8)
            }

            if let toast {
                MessageBubble(text: toast).padding(.bottom, 90)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: editing)
        .animation(.spring(), value: toast)
        .onAppear {
            // a finished project shows its result straight away
            if current == nil, p.missingSlots.isEmpty { run(p, quiet: true) }
        }
    }

    @ViewBuilder
    private var outputView: some View {
        switch track {
        case .web:
            if ran {
                WebPreviewView(html: webHTML)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.ink.opacity(0.15), lineWidth: 2))
                    .overlay(alignment: .topTrailing) {
                        Text("🌐 your page").font(.kid(12, .black)).padding(6)
                            .background(Capsule().fill(.white.opacity(0.9))).padding(8)
                    }
            } else {
                placeholder("Press ▶ Run to see your web page!")
            }
        case .python:
            ConsoleView(lines: output, error: error, ran: ran)
        case .games:
            if let game, error == nil {
                CodeGameStageView(program: game,
                                  onMessage: { text in showToast(text); Narrator.shared.say(text) },
                                  onError: { e in error = e })
                    .id(gameNonce)
            } else if let error {
                ConsoleView(lines: [], error: error, ran: true)
            } else {
                placeholder("Press ▶ Run to start your game!")
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(hex: 0xF3F1FA))
            .overlay(Text(text).font(.kid(17, .bold)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding())
    }

    private func hint(_ p: CodeProject) -> String {
        if !p.missingSlots.isEmpty { return "Tap the yellow ? blanks to fill in your code." }
        if !ran { return "All filled in! Press ▶ Run." }
        if error != nil { return "Oops, a bug! 🐞 Change a blank and run again." }
        switch track {
        case .web: return "That's your web page! Tap any part of your code to change it."
        case .python: return "Your program ran! Try changing a blank and run it again."
        case .games: return game?.hasTapEvent == true ? "Tap the game to jump!" : "Your game is running!"
        }
    }

    private func resolve(_ choice: String) -> String {
        CodeCurriculum.resolve(choice, kid: store.profile?.name ?? "Friend", buddy: store.character.name, buddyID: store.character.id)
    }

    private func run(_ p: CodeProject, quiet: Bool = false) {
        guard p.missingSlots.isEmpty else {
            Haptics.bump(.oops)
            showToast("Fill in every yellow blank first!")
            if let first = p.missingSlots.first { editing = first }
            return
        }
        if !quiet { Haptics.tap(.pop) }
        error = nil
        switch track {
        case .web:
            webHTML = CodeLabAssets.previewHTML(p.source, buddyID: store.character.id, theme: store.theme)
            ran = true
            onRanOK()
        case .python:
            let py = MiniPython()
            do {
                try py.run(p.source)
                output = py.output
                ran = true
                if !quiet, let first = output.first { Narrator.shared.say(output.count > 1 ? first + ". " + output[1] : first) }
                onRanOK()
            } catch let e as PyError {
                output = py.output
                error = e
                ran = true
            } catch {}
        case .games:
            let g = GameProgram(validHeroes: Set(Roster.all.map(\.id)))
            do {
                try g.load(p.source)
                game = g
                gameNonce += 1
                ran = true
                onRanOK()
            } catch let e as PyError {
                game = nil
                error = e
                ran = true
            } catch {}
        }
    }

    private func showToast(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { if toast == text { toast = nil } }
    }
}
