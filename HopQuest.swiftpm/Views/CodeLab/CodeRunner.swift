import SwiftUI

/// Runs a child's code and keeps what it made: a web page, Python output, or a playable game.
/// Shared by lessons, remixing and Free Build so they all behave the same.
@MainActor
final class CodeRunner: ObservableObject {
    @Published var output: [String] = []
    @Published var error: PyError?
    @Published var ran = false
    @Published var webHTML = ""
    @Published var game: GameProgram?
    @Published var gameNonce = 0

    /// Runs `source`. Returns true when it ran without a bug.
    @discardableResult
    func run(track: CodeTrack, source: String, buddyID: String, theme: CastleTheme, speak: Bool) -> Bool {
        error = nil
        switch track {
        case .web:
            webHTML = CodeLabAssets.previewHTML(source, buddyID: buddyID, theme: theme)
            ran = true
            return true
        case .python:
            let py = MiniPython()
            do {
                try py.run(source)
                output = py.output
                ran = true
                if speak, let first = output.first { Narrator.shared.say(output.count > 1 ? first + ". " + output[1] : first) }
                return true
            } catch let e as PyError {
                output = py.output
                error = e
                ran = true
            } catch {}
            return false
        case .games:
            let g = GameProgram(validHeroes: Set(Roster.all.map(\.id)))
            do {
                try g.load(source)
                game = g
                gameNonce += 1
                ran = true
                return true
            } catch let e as PyError {
                game = nil
                error = e
                ran = true
            } catch {}
            return false
        }
    }

    func reset() {
        output = []
        error = nil
        ran = false
        webHTML = ""
        game = nil
    }
}

/// What the code made, under the editor.
struct CodeOutputView: View {
    let track: CodeTrack
    @ObservedObject var runner: CodeRunner
    var onMessage: (String) -> Void = { _ in }

    var body: some View {
        switch track {
        case .web:
            if runner.ran {
                WebPreviewView(html: runner.webHTML)
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
            ConsoleView(lines: runner.output, error: runner.error, ran: runner.ran)
        case .games:
            if let game = runner.game, runner.error == nil {
                CodeGameStageView(program: game,
                                  onMessage: onMessage,
                                  onError: { e in runner.error = e })
                    .id(runner.gameNonce)
            } else if let error = runner.error {
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
}
