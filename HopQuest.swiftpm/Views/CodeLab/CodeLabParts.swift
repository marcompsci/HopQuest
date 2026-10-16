import SwiftUI
import WebKit

// MARK: - Colors

enum CodeTheme {
    static let background = Color(hex: 0x1E1B2E)
    static let gutter = Color(hex: 0x6B6784)
    static let currentLine = Color(hex: 0xFFD24D, opacity: 0.12)
    static let errorLine = Color(hex: 0xFF5A5F, opacity: 0.25)

    static func color(_ k: CodeProject.TokenKind) -> Color {
        switch k {
        case .plain: return Color(hex: 0xE8E6F0)
        case .keyword: return Color(hex: 0xC792EA)
        case .string: return Color(hex: 0xA5E075)
        case .number: return Color(hex: 0xF78C6C)
        case .tag: return Color(hex: 0x82AAFF)
        case .attribute: return Color(hex: 0xFFCB6B)
        case .property: return Color(hex: 0x89DDFF)
        case .comment: return Color(hex: 0x6B6784)
        case .punctuation: return Color(hex: 0xBFC7D5)
        }
    }

    /// Named CSS colors used in the lessons, for swatches.
    static let cssColors: [String: UInt32] = [
        "lightblue": 0xADD8E6, "pink": 0xFFC0CB, "lightyellow": 0xFFFFE0, "palegreen": 0x98FB98, "lavender": 0xE6E6FA,
        "purple": 0x800080, "crimson": 0xDC143C, "darkorange": 0xFF8C00, "teal": 0x008080, "navy": 0x000080,
        "gold": 0xFFD700, "hotpink": 0xFF69B4, "mediumpurple": 0x9370DB, "tomato": 0xFF6347,
        "mediumseagreen": 0x3CB371, "royalblue": 0x4169E1, "orchid": 0xDA70D6, "white": 0xFFFFFF,
    ]
}

// MARK: - Editor

/// Real code with colors. Yellow chips are blanks: tap one to choose what goes there.
struct CodeEditorView: View {
    let lines: [CodeProject.Line]
    let currentLesson: String?
    let errorLine: Int?
    let selectedSlot: String?
    var onTapSlot: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(lines) { line in
                        row(line).id(line.id)
                    }
                }
                .padding(.vertical, 10)
                .padding(.trailing, 16)
            }
            .onAppear {
                if let firstNew = lines.first(where: { $0.lessonID == currentLesson && currentLesson != nil }) {
                    proxy.scrollTo(firstNew.id, anchor: .center)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(CodeTheme.background))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your code")
    }

    private func row(_ line: CodeProject.Line) -> some View {
        CodeLineView(line: line, selectedSlot: selectedSlot, onTapSlot: onTapSlot)
            .background(
                RoundedRectangle(cornerRadius: 6).fill(
                    errorLine == line.number ? CodeTheme.errorLine
                    : (line.lessonID != nil && line.lessonID == currentLesson ? CodeTheme.currentLine : .clear))
            )
    }
}

/// One line of code: line number, indent, colored code and tappable blanks.
struct CodeLineView: View {
    let line: CodeProject.Line
    let selectedSlot: String?
    var onTapSlot: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("\(line.number)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(CodeTheme.gutter)
                .frame(width: 30, alignment: .trailing)
                .padding(.trailing, 10)
            Text(String(repeating: " ", count: line.indent * 4))
                .font(.system(size: 16, design: .monospaced))
            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, seg in
                segment(seg)
            }
        }
        .frame(minHeight: line.segments.contains { if case .slot = $0 { return true }; return false } ? 44 : 30)
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func segment(_ seg: CodeProject.Segment) -> some View {
        switch seg {
        case .code(let text, let kind):
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(CodeTheme.color(kind))
                .fixedSize()
        case .slot(let key, let value, let kind):
            Button { onTapSlot(key) } label: {
                HStack(spacing: 4) {
                    if kind == .color, let v = value, let hex = CodeTheme.cssColors[v] {
                        Circle().fill(Color(hex: hex)).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                    }
                    Text(value ?? "  ?  ")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(value == nil ? Palette.ink : Color(hex: 0x1E1B2E))
                        .fixedSize()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(value == nil ? Color(hex: 0xFFD24D) : Color(hex: 0xBDF3C8)))
                .overlay(RoundedRectangle(cornerRadius: 7)
                    .stroke(selectedSlot == key ? Color.white : .clear, lineWidth: 2))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel(value.map { "Blank filled with \($0). Tap to change." } ?? "Empty blank. Tap to choose.")
        }
    }
}

// MARK: - Choosing what goes in a blank

struct SlotPickerView: View {
    let slot: CodeSlot
    let current: String?
    let resolve: (String) -> String
    var onPick: (String) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Pick \(slot.prompt)")
                    .font(.kid(19, .black)).foregroundStyle(Palette.ink)
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            }
            let columns = [GridItem(.adaptive(minimum: slot.kind == .text ? 260 : 110), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(slot.choices, id: \.self) { raw in
                    let shown = resolve(raw)
                    Button {
                        Haptics.tap()
                        onPick(raw)
                    } label: {
                        HStack(spacing: 8) {
                            if slot.kind == .color, let hex = CodeTheme.cssColors[shown] {
                                Circle().fill(Color(hex: hex)).frame(width: 22, height: 22)
                                    .overlay(Circle().stroke(Palette.ink.opacity(0.2), lineWidth: 2))
                            }
                            Text(shown)
                                .font(.system(size: 16, weight: .bold, design: slot.kind == .text ? .rounded : .monospaced))
                                .foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            if current == raw { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.green) }
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 50)
                        .background(RoundedRectangle(cornerRadius: 14).fill(current == raw ? Color(hex: 0xDDF7E5) : Color(hex: 0xF3F1FA)))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Web page preview

/// Shows the child's real HTML in a web view. JavaScript is off and links don't go anywhere: it's a safe
/// preview of their own page, with nothing loaded from the internet.
struct WebPreviewView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .white
        view.scrollView.bounces = true
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html else { return }
        context.coordinator.lastHTML = html
        view.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML = ""

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // only the page itself; nothing navigates away
            decisionHandler(action.navigationType == .other ? .allow : .cancel)
        }
    }
}

/// Swaps the picture names in the child's HTML for the real pictures (embedded, so nothing loads from the internet).
enum CodeLabAssets {
    private static var cache: [String: String] = [:]

    private static func dataURI(_ assetName: String) -> String {
        if let c = cache[assetName] { return c }
        guard let img = ArtLibrary.image(assetName), let data = img.pngData() else { return "" }
        let uri = "data:image/png;base64," + data.base64EncodedString()
        cache[assetName] = uri
        return uri
    }

    static func previewHTML(_ html: String, buddyID: String, theme: CastleTheme) -> String {
        var out = html
        let pics = ["buddy.png": "buddy3d_\(buddyID)", "castle.png": "castle_\(theme.rawValue)", "star.png": "goal_star"]
        for (file, asset) in pics where out.contains("src=\"\(file)\"") {
            out = out.replacingOccurrences(of: "src=\"\(file)\"", with: "src=\"\(dataURI(asset))\"")
        }
        // a friendly default font and comfortable margins, added outside the child's own code
        let base = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><style>body{font-family:-apple-system,'SF Pro Rounded',sans-serif;margin:16px;}</style>"
        return out.replacingOccurrences(of: "<head>", with: "<head>" + base)
    }
}

// MARK: - Python output

struct ConsoleView: View {
    let lines: [String]
    let error: PyError?
    let ran: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: 0xFF5F57)).frame(width: 10, height: 10)
                    Circle().fill(Color(hex: 0xFEBC2E)).frame(width: 10, height: 10)
                    Circle().fill(Color(hex: 0x28C840)).frame(width: 10, height: 10)
                    Text("Output").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(CodeTheme.gutter)
                }
                if !ran {
                    Text("Press ▶ Run to see what your code does!")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CodeTheme.gutter)
                }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xE8E6F0))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let error {
                    Text("🐞 \(error.description)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFF8A8E))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x111019)))
        .accessibilityElement(children: .combine)
    }
}
