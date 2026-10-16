import Foundation

// Free Build: a blank project where the child makes their own web page, Python program or game.
// Instead of typing, they add code blocks they've learned in lessons, fill the blanks, move lines up and down,
// and push Python lines in or out (indenting is part of the lesson: get it wrong and Python says so, kindly).

/// One kind of line the child can add, unlocked by finishing the lesson it comes from.
struct SandboxBlock: Identifiable, Equatable {
    /// "python4.0" = the first line of lesson python4.
    let id: String
    let track: CodeTrack
    let lessonID: String
    let template: CodeLineTemplate

    var lesson: CodeLesson? { CodeCurriculum.lesson(lessonID) }
}

/// A line in a Free Build project.
struct SandboxLine: Codable, Equatable, Identifiable {
    /// Stable id for this line ("L7"); slot keys hang off it.
    var id: String
    var blockID: String
    /// Python only: how far the line is pushed in (0–3). Web lines go where their section says.
    var indent: Int
    /// Chosen values, by slot id.
    var values: [String: String] = [:]
}

/// Everything Free Build remembers, per track.
struct SandboxSave: Codable, Equatable {
    var lines: [String: [SandboxLine]] = [:]
    /// Counter for new line ids, so ids never repeat.
    var nextID = 1

    init() {}

    enum CodingKeys: String, CodingKey { case lines, nextID }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lines = (try? c.decodeIfPresent([String: [SandboxLine]].self, forKey: .lines)) ?? [:]
        nextID = (try? c.decodeIfPresent(Int.self, forKey: .nextID)) ?? 1
    }

    func lines(for track: CodeTrack) -> [SandboxLine] { lines[track.rawValue] ?? [] }
}

enum Sandbox {
    static let maxLines = 40
    static let maxIndent = 3

    /// Every block in a track, in lesson order.
    static func blocks(for track: CodeTrack) -> [SandboxBlock] {
        CodeCurriculum.lessons(for: track).flatMap { lesson in
            lesson.lines.enumerated().map { i, t in
                SandboxBlock(id: "\(lesson.id).\(i)", track: track, lessonID: lesson.id, template: t)
            }
        }
    }

    static func block(_ id: String) -> SandboxBlock? {
        guard let lessonID = id.split(separator: ".").first.map(String.init),
              let lesson = CodeCurriculum.lesson(lessonID) else { return nil }
        return blocks(for: lesson.track).first { $0.id == id }
    }

    /// Blocks the child can use: those from lessons they've finished.
    static func unlockedBlocks(for track: CodeTrack, save: CodeLabSave) -> [SandboxBlock] {
        blocks(for: track).filter { save.completed.contains($0.lessonID) }
    }

    /// Free Build opens once the first lesson of the track is done.
    static func isOpen(_ track: CodeTrack, save: CodeLabSave) -> Bool {
        CodeCurriculum.lessons(for: track).first.map { save.completed.contains($0.id) } ?? false
    }

    // MARK: Editing (pure functions, so they're easy to test)

    /// Adds a block after `index` (or at the end). New lines start with the block's own indent.
    static func adding(_ block: SandboxBlock, to lines: [SandboxLine], after index: Int?, save: inout SandboxSave) -> [SandboxLine] {
        guard lines.count < maxLines else { return lines }
        var out = lines
        // a line added under "for …:" or "def …:" starts pushed in one more step, like a real editor does
        var indent = block.template.indent
        if block.track != .web, let i = index, out.indices.contains(i) {
            let above = out[i]
            let aboveText = Sandbox.block(above.blockID)?.template.text ?? ""
            indent = aboveText.hasSuffix(":") ? above.indent + 1 : above.indent
        }
        let line = SandboxLine(id: "L\(save.nextID)", blockID: block.id, indent: min(indent, maxIndent))
        save.nextID += 1
        let at = index.map { min($0 + 1, out.count) } ?? out.count
        out.insert(line, at: at)
        return out
    }

    /// Moves a line up (-1) or down (+1). Web lines only trade places with lines in the same section
    /// (style with style, page with page), so every tap visibly moves something.
    static func moving(_ lines: [SandboxLine], from index: Int, by delta: Int) -> [SandboxLine] {
        guard lines.indices.contains(index), delta != 0 else { return lines }
        let group = section(of: lines[index])
        var to = index + (delta > 0 ? 1 : -1)
        while lines.indices.contains(to), section(of: lines[to]) != group { to += delta > 0 ? 1 : -1 }
        guard lines.indices.contains(to) else { return lines }
        var out = lines
        out.swapAt(index, to)
        return out
    }

    private static func section(of line: SandboxLine) -> CodeSection {
        guard let b = block(line.blockID) else { return .main }
        return b.track == .web ? (b.template.section == .style ? .style : .body) : .main
    }

    static func indenting(_ lines: [SandboxLine], at index: Int, by delta: Int) -> [SandboxLine] {
        guard lines.indices.contains(index) else { return lines }
        var out = lines
        out[index].indent = min(max(out[index].indent + delta, 0), maxIndent)
        return out
    }

    static func removing(_ lines: [SandboxLine], at index: Int) -> [SandboxLine] {
        guard lines.indices.contains(index) else { return lines }
        var out = lines
        out.remove(at: index)
        return out
    }

    /// Slot keys look like "sb.L7.title".
    static func key(line: String, slot: String) -> String { "sb.\(line).\(slot)" }

    static func parse(key: String) -> (line: String, slot: String)? {
        let parts = key.split(separator: ".", maxSplits: 2).map(String.init)
        guard parts.count == 3, parts[0] == "sb" else { return nil }
        return (parts[1], parts[2])
    }
}

/// Turns Free Build lines into code: colored lines for the editor, and runnable source.
struct SandboxProgram {
    struct Row: Identifiable, Equatable {
        let id: String
        /// The SandboxLine this row shows (nil = HTML scaffolding the child doesn't edit).
        let lineID: String?
        let line: CodeProject.Line
    }

    let track: CodeTrack
    let lines: [SandboxLine]
    var kid = "Friend"
    var buddy = "Buddy"
    var buddyID = "lavender"

    private var colorer: CodeProject { CodeProject(track: track, lessons: [], values: [:]) }

    func slots(for line: SandboxLine) -> [CodeSlot] { Sandbox.block(line.blockID)?.template.slots ?? [] }

    var missingSlots: [String] {
        lines.flatMap { line in slots(for: line).filter { line.values[$0.id] == nil }.map { Sandbox.key(line: line.id, slot: $0.id) } }
    }

    func rows() -> [Row] {
        var raw: [(lineID: String?, indent: Int, text: String, slots: [CodeSlot], values: [String: String])] = []
        func scaffold(_ text: String, _ indent: Int) { raw.append((nil, indent, text, [], [:])) }
        func add(_ l: SandboxLine, indent: Int) {
            guard let b = Sandbox.block(l.blockID) else { return }
            raw.append((l.id, indent, b.template.text, b.template.slots, l.values))
        }
        if track == .web {
            scaffold("<!DOCTYPE html>", 0)
            scaffold("<html>", 0)
            scaffold("<head>", 0)
            scaffold("<style>", 1)
            for l in lines where Sandbox.block(l.blockID)?.template.section == .style { add(l, indent: 2) }
            scaffold("</style>", 1)
            scaffold("</head>", 0)
            scaffold("<body>", 0)
            for l in lines where Sandbox.block(l.blockID)?.template.section != .style { add(l, indent: 1) }
            scaffold("</body>", 0)
            scaffold("</html>", 0)
        } else {
            for l in lines { add(l, indent: l.indent) }
        }

        let c = colorer
        return raw.enumerated().map { i, r in
            var segs: [CodeProject.Segment] = []
            var rest = Substring(r.text)
            while let open = rest.range(of: "[["), let close = rest[open.upperBound...].range(of: "]]") {
                let slotID = String(rest[open.upperBound..<close.lowerBound])
                segs += c.highlight(String(rest[..<open.lowerBound]))
                if let slot = r.slots.first(where: { $0.id == slotID }), let lineID = r.lineID {
                    let shown = r.values[slotID].map { CodeCurriculum.resolve($0, kid: kid, buddy: buddy, buddyID: buddyID) }
                    segs.append(.slot(key: Sandbox.key(line: lineID, slot: slotID), value: shown, kind: slot.kind))
                } else {
                    segs += c.highlight(String(rest[open.lowerBound..<close.upperBound]))
                }
                rest = rest[close.upperBound...]
            }
            segs += c.highlight(String(rest))
            let line = CodeProject.Line(id: "\(i)", number: i + 1, indent: r.indent, segments: segs, lessonID: nil)
            return Row(id: r.lineID ?? "scaffold\(i)", lineID: r.lineID, line: line)
        }
    }

    var source: String {
        rows().map { row in
            String(repeating: track == .web ? "  " : "    ", count: row.line.indent) + row.line.segments.map { seg -> String in
                switch seg {
                case .code(let s, _): return s
                case .slot(_, let v, _): return v ?? ""
                }
            }.joined()
        }.joined(separator: "\n")
    }
}
