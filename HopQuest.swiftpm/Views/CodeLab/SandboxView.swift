import SwiftUI

/// Free Build: the child's own project from scratch. They add code blocks from lessons they've finished,
/// fill the blanks, move and indent lines, and run whatever they make.
struct SandboxView: View {
    @EnvironmentObject var store: GameStore
    let track: CodeTrack
    var onClose: () -> Void

    @StateObject private var runner = CodeRunner()
    @State private var selected: String?
    @State private var editing: String?
    @State private var showPalette = false
    @State private var toast: String?
    /// The project before the last line was deleted (for Undo).
    @State private var undoLines: [SandboxLine]?

    private var codeLab: CodeLabSave { store.profile?.codeLab ?? CodeLabSave() }
    private var lines: [SandboxLine] { codeLab.sandbox.lines(for: track) }
    private var tint: Color { Color(hex: track.colorHex) }

    private var program: SandboxProgram {
        var p = SandboxProgram(track: track, lines: lines)
        p.kid = store.profile?.name ?? "Friend"
        p.buddy = store.character.name
        p.buddyID = store.character.id
        return p
    }

    var body: some View {
        let p = program
        ZStack(alignment: .bottom) {
            Color(hex: 0xFAF8FF).ignoresSafeArea()
            VStack(spacing: 10) {
                header(p)
                editor(p)
                    .frame(maxHeight: .infinity)
                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        showPalette = true
                    } label: {
                        Label("Add a block", systemImage: "plus.circle.fill")
                            .font(.kid(17, .black)).foregroundStyle(.white)
                            .padding(.horizontal, 16).frame(height: 46)
                            .background(Capsule().fill(tint))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(lines.count >= Sandbox.maxLines)
                    Text("\(lines.count)/\(Sandbox.maxLines) lines")
                        .font(.kid(13, .bold)).foregroundStyle(.secondary)
                    Spacer()
                    if let previous = undoLines {
                        Button {
                            Haptics.tap()
                            store.editSandbox { sb in sb.lines[track.rawValue] = previous }
                            undoLines = nil
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .font(.kid(15, .black)).foregroundStyle(.white)
                                .padding(.horizontal, 14).frame(height: 46)
                                .background(Capsule().fill(Palette.purple))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Undo, put the line back")
                    }
                }
                CodeOutputView(track: track, runner: runner,
                               onMessage: { text in showToast(text); Narrator.shared.say(text) })
                    .frame(maxHeight: .infinity)
            }
            .padding(14)

            if showPalette {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { showPalette = false }
                BlockPaletteView(track: track, save: codeLab, kid: p.kid, buddy: p.buddy, buddyID: p.buddyID) { block in
                    add(block)
                    showPalette = false
                } onClose: { showPalette = false }
                .padding(.bottom, 8)
            }

            if let key = editing, let parsed = Sandbox.parse(key: key),
               let line = lines.first(where: { $0.id == parsed.line }),
               let slot = p.slots(for: line).first(where: { $0.id == parsed.slot }) {
                Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { editing = nil }
                SlotPickerView(slot: slot, current: line.values[slot.id],
                               resolve: { CodeCurriculum.resolve($0, kid: p.kid, buddy: p.buddy, buddyID: p.buddyID) }) { choice in
                    setValue(line: line.id, slot: slot.id, choice)
                    editing = nil
                } onClose: { editing = nil }
                .padding(.bottom, 8)
            }

            if let toast {
                MessageBubble(text: toast).padding(.bottom, 90)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: editing)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showPalette)
        .animation(.spring(), value: toast)
        .onAppear {
            Narrator.shared.say(lines.isEmpty
                ? "Free Build! Add blocks you've learned and make anything you like."
                : "Welcome back to your Free Build project!")
        }
    }

    // MARK: Header

    private func header(_ p: SandboxProgram) -> some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            VStack(alignment: .leading, spacing: 0) {
                Text("🧪 Free Build").font(.kid(13, .bold)).foregroundStyle(tint)
                Text("\(track.icon) \(track.title)").font(.kid(20, .black)).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            Button { run(p) } label: {
                Label("Run", systemImage: "play.fill")
                    .font(.kid(18, .black)).foregroundStyle(.white)
                    .padding(.horizontal, 18).frame(height: 46)
                    .background(Capsule().fill(!lines.isEmpty && p.missingSlots.isEmpty ? Palette.green : Color.gray))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Run your code")
        }
    }

    // MARK: Editor

    private func editor(_ p: SandboxProgram) -> some View {
        let rows = p.rows()
        return ScrollView([.vertical, .horizontal], showsIndicators: true) {
            VStack(alignment: .leading, spacing: 2) {
                if lines.isEmpty {
                    Text("Your project is empty.\nTap “Add a block” to start building!")
                        .font(.kid(16, .bold)).foregroundStyle(Color(hex: 0xBFC7D5))
                        .padding(16)
                }
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        CodeLineView(line: row.line, selectedSlot: editing) { key in
                            Haptics.tap()
                            editing = key
                        }
                        .background(RoundedRectangle(cornerRadius: 6).fill(
                            runner.error?.line == row.line.number ? CodeTheme.errorLine
                            : (row.lineID != nil && row.lineID == selected ? CodeTheme.currentLine : .clear)))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard let id = row.lineID else { return }
                            selected = selected == id ? nil : id
                        }
                        .accessibilityAddTraits(row.lineID != nil ? .isButton : [])
                        if let id = row.lineID, id == selected { lineTools(id) }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.trailing, 16)
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(CodeTheme.background))
    }

    /// Move, indent and delete buttons under the selected line.
    private func lineTools(_ id: String) -> some View {
        let index = lines.firstIndex { $0.id == id } ?? 0
        return HStack(spacing: 8) {
            toolButton("arrow.up", "Move up") { change { Sandbox.moving($0, from: index, by: -1) } }
            toolButton("arrow.down", "Move down") { change { Sandbox.moving($0, from: index, by: 1) } }
            if track != .web {
                toolButton("decrease.indent", "Push left") { change { Sandbox.indenting($0, at: index, by: -1) } }
                toolButton("increase.indent", "Push right") { change { Sandbox.indenting($0, at: index, by: 1) } }
            }
            toolButton("trash", "Delete line", color: Color(hex: 0xFF8A8E)) {
                undoLines = lines
                change { Sandbox.removing($0, at: index) }
                selected = nil
                showToast("Line deleted. Tap Undo to bring it back.")
            }
        }
        .padding(.leading, 46)
        .padding(.bottom, 6)
    }

    private func toolButton(_ icon: String, _ label: String, color: Color = .white, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.14)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }

    // MARK: Changes

    private func change(_ f: ([SandboxLine]) -> [SandboxLine]) {
        store.editSandbox { sb in sb.lines[track.rawValue] = f(sb.lines(for: track)) }
        if track == .web, runner.ran { DispatchQueue.main.async { run(program, quiet: true) } }
    }

    private func add(_ block: SandboxBlock) {
        let after = selected.flatMap { id in lines.firstIndex { $0.id == id } }
        var newID: String?
        store.editSandbox { sb in
            let before = sb.lines(for: track)
            let updated = Sandbox.adding(block, to: before, after: after, save: &sb)
            sb.lines[track.rawValue] = updated
            newID = updated.first { l in !before.contains { $0.id == l.id } }?.id
        }
        selected = newID
        // open the first blank of the new line right away
        if let id = newID, let first = block.template.slots.first {
            editing = Sandbox.key(line: id, slot: first.id)
        }
    }

    private func setValue(line: String, slot: String, _ value: String) {
        change { ls in
            ls.map { l in
                guard l.id == line else { return l }
                var copy = l
                copy.values[slot] = value
                return copy
            }
        }
    }

    private func run(_ p: SandboxProgram, quiet: Bool = false) {
        guard !lines.isEmpty else {
            showToast("Add a block first!")
            return
        }
        guard p.missingSlots.isEmpty else {
            Haptics.bump(.oops)
            showToast("Fill in every yellow blank first!")
            editing = p.missingSlots.first
            return
        }
        if !quiet { Haptics.tap(.pop) }
        let ok = runner.run(track: track, source: p.source, buddyID: store.character.id, theme: store.theme, speak: !quiet)
        undoLines = nil
        if !ok, !quiet {
            Haptics.bump(.oops)
            let hint = runner.error.map { Self.friendly($0) } ?? "Check the red line."
            showToast("A bug! 🐞 " + hint)
        }
    }

    /// Plain-words help for the bugs kids make most in Free Build (moving lines in and out).
    static func friendly(_ e: PyError) -> String {
        let m = e.message
        if m.contains("too many spaces") {
            return "Line \(e.line) is pushed too far right. Tap it, then tap ⬅ to move it left."
        }
        if m.contains("need to be pushed in") {
            return "The line after line \(e.line) should move right. Tap it, then tap ➡."
        }
        if m.contains("indented in a way") {
            return "Line \(e.line) is in the wrong spot. Try moving it left ⬅ or right ➡."
        }
        return "Check line \(e.line), the red one."
    }

    private func showToast(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { if toast == text { toast = nil } }
    }
}

/// The blocks a child can add, grouped by the lesson that taught them. Unfinished lessons show as locked.
struct BlockPaletteView: View {
    let track: CodeTrack
    let save: CodeLabSave
    let kid: String
    let buddy: String
    let buddyID: String
    var onPick: (SandboxBlock) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Add a block").font(.kid(20, .black)).foregroundStyle(Palette.ink)
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(CodeCurriculum.lessons(for: track)) { lesson in
                        lessonGroup(lesson)
                    }
                }
            }
            .frame(maxHeight: 420)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private func lessonGroup(_ lesson: CodeLesson) -> some View {
        let open = save.completed.contains(lesson.id)
        VStack(alignment: .leading, spacing: 6) {
            Text(open ? "Lesson \(lesson.number) · \(lesson.title)" : "🔒 Lesson \(lesson.number) · \(lesson.title)")
                .font(.kid(14, .black))
                .foregroundStyle(open ? Color(hex: track.colorHex) : .secondary)
            if open {
                ForEach(Sandbox.blocks(for: track).filter { $0.lessonID == lesson.id }) { block in
                    Button {
                        Haptics.tap()
                        onPick(block)
                    } label: {
                        CodeLineView(line: preview(block), selectedSlot: nil, onTapSlot: { _ in onPick(block) })
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 10).fill(CodeTheme.background))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Add the line: \(block.template.text.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: ""))")
                }
            } else {
                Text("Finish this lesson to unlock its blocks.")
                    .font(.kid(13, .bold)).foregroundStyle(.secondary)
            }
        }
    }

    /// How a block looks before it's added: its code with empty blanks.
    private func preview(_ block: SandboxBlock) -> CodeProject.Line {
        // web blocks are drawn with web colors, without the page scaffolding around them
        if track == .web {
            let colorer = CodeProject(track: .web, lessons: [], values: [:])
            var segs: [CodeProject.Segment] = []
            var rest = Substring(block.template.text)
            while let open = rest.range(of: "[["), let close = rest[open.upperBound...].range(of: "]]") {
                segs += colorer.highlight(String(rest[..<open.lowerBound]))
                segs.append(.slot(key: "preview", value: nil, kind: .text))
                rest = rest[close.upperBound...]
            }
            segs += colorer.highlight(String(rest))
            return CodeProject.Line(id: block.id, number: 1, indent: 0, segments: segs, lessonID: nil)
        }
        var p = SandboxProgram(track: track, lines: [SandboxLine(id: "preview", blockID: block.id, indent: 0)])
        p.kid = kid
        p.buddy = buddy
        p.buddyID = buddyID
        return p.rows().first?.line ?? CodeProject.Line(id: block.id, number: 1, indent: 0, segments: [], lessonID: nil)
    }
}
