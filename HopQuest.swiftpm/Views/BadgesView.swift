import SwiftUI

extension GameStore {
    var badgeInput: BadgeInput {
        guard let p = profile else { return BadgeInput() }
        return BadgeInput(lifetimeStars: p.lifetimeStars,
                          finishedAreas: Set(learningAreas.filter(\.finished).map(\.id)),
                          postcards: p.world.postcards.count,
                          lettersWritten: p.writing.written.count,
                          storiesMade: p.storyMaker.made,
                          chaptersDone: p.completedChapters,
                          biggestIsland: (0...2).map { fortIsland($0).count }.max() ?? 0,
                          dashFinished: p.quick.bestStars > 0,
                          codePuzzles: CodeChallenge.all.filter { p.codeBest[$0.id] != nil }.count,
                          stickers: ownedStickers.count)
    }
}

/// Every badge: earned ones in color, the rest showing how to earn them.
struct BadgesView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var open: Badge?

    var body: some View {
        let input = store.badgeInput
        let earned = Set(Badges.earned(input).map(\.id))
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF8E7), Color(hex: 0xFFE9C2)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                        Spacer()
                        Text("Badges").font(.kid(28, .black)).displayTracking(28).foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(earned.count)/\(Badges.all.count)").font(.kid(16, .black)).monospacedDigit()
                            .foregroundStyle(Palette.ink.opacity(0.7))
                            .frame(width: 56, height: 44)
                            .background(Capsule().fill(.regularMaterial))
                            .accessibilityLabel("\(earned.count) of \(Badges.all.count) badges")
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
                        ForEach(Badges.all) { b in
                            badge(b, got: earned.contains(b.id))
                        }
                    }
                    Text("Badges never go away once you earn them.")
                        .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.55)).padding(.bottom, 20)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
            if let b = open {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { open = nil }
                VStack(spacing: 12) {
                    medal(b, got: earned.contains(b.id), size: 110)
                    Text(b.title).font(.kid(24, .black)).displayTracking(24)
                    Text(earned.contains(b.id) ? "You earned this badge!" : b.how)
                        .font(.kid(17, .semibold)).foregroundStyle(Palette.ink.opacity(0.75)).multilineTextAlignment(.center)
                    BigButton(title: "Done", color: Palette.purple) { open = nil }
                }
                .foregroundStyle(Palette.ink)
                .padding(22)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
                .padding(.horizontal, 30)
                .transition(.panel)
                .onAppear { Narrator.shared.say("\(b.title). \(earned.contains(b.id) ? "You earned this badge!" : b.how)") }
            }
        }
        .animation(Motion.present, value: open?.id)
        .onAppear { Narrator.shared.say("Your badges! Tap one to see how to earn it.") }
        .onDisappear { Narrator.shared.stop() }
    }

    private func badge(_ b: Badge, got: Bool) -> some View {
        Button { Haptics.tap(); open = b } label: {
            VStack(spacing: 6) {
                medal(b, got: got, size: 70)
                Text(b.title).font(.kid(13, .black)).foregroundStyle(Palette.ink.opacity(got ? 1 : 0.5))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(b.title), \(got ? "earned" : "not yet. \(b.how)")")
    }

    private func medal(_ b: Badge, got: Bool, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(got ? Color(hex: b.colorHex) : Color(hex: 0xE4E1EA))
            Circle().stroke(got ? Color(hex: 0xFFD93D) : Color(hex: 0xC9C4D3), lineWidth: size * 0.07)
            Image(systemName: got ? b.symbol : "lock.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(got ? .white : Color(hex: 0xA39DB0))
        }
        .frame(width: size, height: size)
        .shadow(color: Palette.ink.opacity(got ? 0.18 : 0), radius: 0, x: 0, y: 4)
    }
}
