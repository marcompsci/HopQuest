import SwiftUI

// Shared pieces for the village learning places (Reading Nook, Math Market): the game picker card,
// big answer buttons, a progress row and the end-of-game card.

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

/// One game in a learning place's list.
struct LearnGameCard: View {
    let icon: String
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
                Text(icon).font(.system(size: 36))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.white.opacity(0.25)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.kid(20, .black)).lineLimit(1).minimumScaleFactor(0.7)
                    Text(blurb).font(.kid(13, .bold)).opacity(0.9)
                        .lineLimit(2).minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                StarRow(stars: stars, size: 15)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 22).fill(color)
                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 5))
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

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(font)
                .foregroundStyle(state == .plain ? Palette.ink : .white)
                .lineLimit(2).minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 70)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 20)
                    .fill(state == .right ? Palette.green : state == .wrong ? Color(hex: 0xC9C3D6) : .white)
                    .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4))
                .modifier(Shake(animatableData: state == .wrong ? 1 : 0))
                .animation(.default, value: state == .wrong)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(state == .wrong)
    }
}

/// ● ● ○ ○ ○: how far through the rounds.
struct RoundDots: View {
    let done: Int
    let total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle().fill(i < done ? Palette.green : .white.opacity(0.7)).frame(width: 14, height: 14)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(min(done + 1, total)) of \(total)")
    }
}

/// The end of a game: stars, new stars earned, and what next.
struct LearnDoneCard: View {
    let title: String
    let stars: Int
    let earned: Int
    let firstTry: Int
    let total: Int
    var onAgain: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("🎉").font(.system(size: 60)).accessibilityHidden(true)
            Text("\(title) done!").font(.kid(28, .black)).foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            StarRow(stars: stars, size: 34)
            Text("\(firstTry) of \(total) right on the first try")
                .font(.kid(16, .bold)).foregroundStyle(Palette.ink.opacity(0.8))
            if earned > 0 {
                Text("+\(earned) ⭐ new best!").font(.kid(20, .black)).foregroundStyle(Palette.green)
            }
            BigButton(title: "Play again", color: Palette.green, action: onAgain)
            BigButton(title: "Pick another game", color: Palette.purple, action: onBack)
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white).shadow(color: .black.opacity(0.2), radius: 12, y: 6))
        .padding(.horizontal, 20)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}
