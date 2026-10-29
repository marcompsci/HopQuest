import SwiftUI

// Shared pieces for the learning places (Reading Nook, Math Market, Science Lab, Music Maker): the header with
// its host buddy, the game cards, big answer buttons, a progress row and the end-of-game card.

/// ⭐⭐☆
struct StarRow: View {
    let stars: Int
    var size: CGFloat = 18
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(i < stars ? Color(hex: 0xFFC21A) : Palette.ink.opacity(0.25))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) of 3 stars")
    }
}

/// The top of a learning place: its host buddy (real game art, not an emoji), the place's name, a line from
/// the host, and the stars earned so far. One layout for every place, so they read as one app.
struct PlaceHeader: View {
    let host: GameCharacter
    let title: String
    let line: String
    let stars: Int
    let maxStars: Int
    let accent: Color
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundStyle(Color(hex: 0xFFC21A))
                    Text("\(stars) of \(maxStars)").monospacedDigit()
                }
                .font(.kid(15, .heavy))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 12).frame(minHeight: 44)
                .background(Capsule().fill(.regularMaterial))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stars) of \(maxStars) stars")
            }
            HStack(alignment: .bottom, spacing: 12) {
                CharacterBadge(character: host, size: 92, animated: true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.kid(32, .black)).displayTracking(32).foregroundStyle(accent)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(line)
                        .font(.kid(15, .semibold)).foregroundStyle(Palette.ink.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(SpeechBubble().fill(.white))
                }
                .padding(.bottom, 8)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// A rounded bubble with a little tail on the left, pointing at the host.
struct SpeechBubble: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(roundedRect: r, cornerRadius: 14)
        p.move(to: CGPoint(x: r.minX + 2, y: r.maxY - 18))
        p.addLine(to: CGPoint(x: r.minX - 8, y: r.maxY - 6))
        p.addLine(to: CGPoint(x: r.minX + 12, y: r.maxY - 6))
        p.closeSubpath()
        return p
    }
}

/// One game in a learning place's list: a white card with the place's accent on the symbol, so a list of five
/// reads as one calm group instead of five competing colors.
struct LearnGameCard: View {
    let symbol: String
    let title: String
    let blurb: String
    let stars: Int
    let color: Color
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.kid(19, .black)).displayTracking(19).foregroundStyle(Palette.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(blurb).font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.62))
                        .lineLimit(2).minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 8) {
                    StarRow(stars: stars, size: 13)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Palette.ink.opacity(0.3))
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
                .shadow(color: Palette.ink.opacity(0.12), radius: 0, x: 0, y: 4))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(title). \(blurb). Best: \(stars) of 3 stars")
    }
}

/// A big answer button. Turns green when right, and shakes when it isn't.
struct AnswerButton: View {
    let text: String
    var font: Font = .kid(30, .black)
    var state: Mark = .plain
    var action: () -> Void

    enum Mark { case plain, right, wrong }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // a shape as well as a color, for kids who see colors differently
                if state == .right { Image(systemName: "checkmark.circle.fill").font(.system(size: 24, weight: .black)) }
                if state == .wrong { Image(systemName: "xmark").font(.system(size: 18, weight: .black)) }
                Text(text)
            }
                .font(font)
                .foregroundStyle(state == .plain ? Palette.ink : .white)
                .lineLimit(2).minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 70)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 20)
                    .fill(state == .right ? Palette.green : state == .wrong ? Color(hex: 0xC9C3D6) : .white)
                    .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4))
                .modifier(Shake(animatableData: state == .wrong && !reduceMotion ? 1 : 0))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: state == .wrong)
                .animation(Motion.snappy, value: state == .right)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(state == .wrong)
        .accessibilityValue(state == .right ? "Correct" : state == .wrong ? "Not this one" : "")
    }
}

/// ● ● ○ ○ ○: how far through the rounds.
struct RoundDots: View {
    let done: Int
    let total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule().fill(i < done ? Palette.green : Palette.ink.opacity(0.12))
                    .frame(width: i == done ? 28 : 14, height: 10)
            }
        }
        .animation(Motion.standard, value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(min(done + 1, total)) of \(total)")
    }
}

/// The end of a game: the host cheers, the stars land one by one, then what next.
struct LearnDoneCard: View {
    let title: String
    let stars: Int
    let earned: Int
    let firstTry: Int
    let total: Int
    var host: GameCharacter? = nil
    var onAgain: () -> Void
    var onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0

    var body: some View {
        VStack(spacing: 14) {
            if let host {
                CharacterBadge(character: host, size: 96, animated: true).accessibilityHidden(true)
            }
            Text("\(title) done!").font(.kid(28, .black)).displayTracking(28).foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(i < stars ? Color(hex: 0xFFC21A) : Palette.ink.opacity(0.2))
                        .scaleEffect(i < shown || reduceMotion ? 1 : 0.4)
                        .opacity(i < shown || reduceMotion || i >= stars ? 1 : 0)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(stars) of 3 stars")
            Text("\(firstTry) of \(total) right on the first try")
                .font(.kid(16, .semibold)).foregroundStyle(Palette.ink.opacity(0.7)).monospacedDigit()
            if earned > 0 {
                Label("\(earned) new \(earned == 1 ? "star" : "stars")", systemImage: "sparkles")
                    .font(.kid(18, .black)).foregroundStyle(Palette.green)
            }
            BigButton(title: "Play again", color: Palette.green, action: onAgain)
            BigButton(title: "Pick another game", color: Palette.purple, action: onBack)
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white)
            .shadow(color: .black.opacity(0.18), radius: 16, y: 8))
        .padding(.horizontal, 20)
        .transition(.panel)
        .onAppear {
            // stars land one after another: the reward is the moment that earns a bounce
            for i in 0..<stars {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.18) {
                    withAnimation(Motion.celebrate) { shown = i + 1 }
                }
            }
        }
    }
}
