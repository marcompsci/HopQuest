import SwiftUI

/// Story text whose words light up one by one as the narrator reads them (Read with Me, v8.1).
struct ReadAlongText: View {
    let text: String
    var font: Font = .kid(20, .bold)
    var color: Color = Palette.ink
    var highlight: Color = Color(hex: 0xFFE27A)

    @ObservedObject private var reader = ReadAlong.shared

    var body: some View {
        Text(attributed)
            .font(font)
            .foregroundStyle(color)
            .animation(.easeOut(duration: 0.12), value: reader.word)
            .accessibilityLabel(text)
    }

    private var attributed: AttributedString {
        var a = AttributedString(text)
        guard let w = reader.word, let r = ReadAlongMath.displayRange(display: text, source: reader.source, spoken: w),
              let lo = AttributedString.Index(r.lowerBound, within: a), let hi = AttributedString.Index(r.upperBound, within: a) else { return a }
        a[lo..<hi].backgroundColor = highlight
        a[lo..<hi].underlineStyle = .single
        return a
    }
}
