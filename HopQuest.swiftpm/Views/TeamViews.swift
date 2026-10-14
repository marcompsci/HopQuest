import SwiftUI

/// Grown-up & Me: pick the grown-up's buddy and a team game. Everyone plays on one device.
struct TeamSetupView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void
    var onStart: (Chapter) -> Void

    @State private var pickingBuddy = false

    private var kidName: String { store.profile?.name ?? "Kid" }

    var body: some View {
        ZStack {
            LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        CircleIconButton(systemName: "house.fill", label: "Back to map", action: onBack)
                        Spacer()
                        SpeakButton { Narrator.shared.say(intro) }
                    }

                    Text("Grown-up & Me")
                        .font(.kid(34, .black))
                        .foregroundStyle(Palette.purple)
                    Text("Play together on one device!")
                        .font(.kid(18, .semibold))
                        .foregroundStyle(Palette.ink)

                    team

                    modeCard(chapter: Chapters.teamHop,
                             emoji: "🐾🐾",
                             title: "Team Hop",
                             text: "Hop side by side to the castle. The left side of the screen moves \(kidName). The right side moves the grown-up. Stay within 5 hops of each other — teams stick together!",
                             color: Color(hex: 0x34C77B))

                    modeCard(chapter: Chapters.teamDrive,
                             emoji: "🚙",
                             title: "Team Drive",
                             text: "The grown-up turns the steering wheel. \(kidName) works the gas and brake pedals — and stops for every red light and stop sign!",
                             color: Color(hex: 0x4D96FF))

                    grownUpTips
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .sheet(isPresented: $pickingBuddy) {
            CharacterSelectView(theme: store.theme, initialID: store.coopCharacter.id, buttonTitle: "This is me!") { picked in
                store.profile?.coopCharacterID = picked.id
                pickingBuddy = false
            }
            .background(LinearGradient(colors: store.theme.sky, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
        .onAppear { Narrator.shared.say(intro) }
    }

    private var intro: String {
        "Grown-up and me! Play together on one device. Pick Team Hop or Team Drive."
    }

    private var team: some View {
        HStack(spacing: 14) {
            player(store.character, name: kidName, tag: "⭐", side: "Left side", action: nil)
            Text("+").font(.kid(30, .black)).foregroundStyle(Palette.ink.opacity(0.5))
            player(store.coopCharacter, name: "Grown-up", tag: "💜", side: "Right side") { pickingBuddy = true }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.85)))
    }

    private func player(_ c: GameCharacter, name: String, tag: String, side: String, action: (() -> Void)?) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                CharacterBadge(character: c, size: 76)
                Text(tag).font(.system(size: 20))
            }
            Text(name).font(.kid(17, .black)).foregroundStyle(Palette.ink)
            Text(side).font(.kid(12, .bold)).foregroundStyle(Palette.ink.opacity(0.6))
            if let action {
                Button("Change", action: action)
                    .font(.kid(13, .bold))
                    .foregroundStyle(Palette.purple)
                    .accessibilityLabel("Change the grown-up's character")
            } else {
                Text(" ").font(.kid(13, .bold))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func modeCard(chapter: Chapter, emoji: String, title: String, text: String, color: Color) -> some View {
        Button {
            Haptics.tap()
            onStart(chapter)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(emoji).font(.system(size: 34))
                    Text(title).font(.kid(24, .black)).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "play.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
                }
                Text(text)
                    .font(.kid(15, .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(color)
                .shadow(color: color.opacity(0.45), radius: 0, x: 0, y: 6))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(title). \(text)")
    }

    private var grownUpTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips for grown-ups").font(.kid(17, .black)).foregroundStyle(Palette.ink)
            tipRow("🧠", "At Brain Gates, let your child answer first. Help with a hint, not the answer.")
            tipRow("🚦", "In Team Drive, ask \"what does this sign mean?\" before you reach it.")
            tipRow("🎉", "Cheer for the bumps too — they're part of the fun, never a fail.")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.85)))
    }

    private func tipRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon)
            Text(text).font(.kid(14, .medium)).foregroundStyle(Palette.ink.opacity(0.85))
        }
    }
}
