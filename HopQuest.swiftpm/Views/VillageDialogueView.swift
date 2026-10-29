import SwiftUI

/// One page of a village conversation: who's talking, what they say, and the answers the child can pick.
struct VillageDialogue: Identifiable {
    struct Choice: Identifiable {
        let id = UUID()
        let title: String
        var primary = true
        let action: () -> Void
    }
    let id = UUID()
    let speaker: GameCharacter
    let text: String
    let choices: [Choice]
}

/// Speech card along the bottom of the screen, with the speaker's portrait and big answer buttons.
struct VillageDialogueView: View {
    let dialogue: VillageDialogue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                CharacterBadge(character: dialogue.speaker, size: 64)
                    .background(Circle().fill(dialogue.speaker.color.opacity(0.35)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(dialogue.speaker.name)
                        .font(.kid(15, .black))
                        .foregroundStyle(Palette.purple)
                    Text(dialogue.text)
                        .font(.kid(19, .bold))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                SpeakButton { Narrator.shared.say(dialogue.text) }
            }
            HStack(spacing: 10) {
                ForEach(dialogue.choices) { choice in
                    Button {
                        Haptics.tap()
                        choice.action()
                    } label: {
                        Text(choice.title)
                            .font(.kid(17, .black))
                            .foregroundStyle(choice.primary ? .white : Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 18)
                                .fill(choice.primary ? Palette.green : Color(hex: 0xEDEFF3))
                                .shadow(color: choice.primary ? Color(hex: 0x239A5C) : Color(hex: 0xC9CDD6), radius: 0, x: 0, y: 4))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white)
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Palette.ink.opacity(0.08), lineWidth: 2))
        .padding(.horizontal, 14)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }
}

/// Driving Academy front desk: pick a lesson. Locked lessons show what to finish first.
struct VillageChapterPicker: View {
    let title: String
    let chapters: [Chapter]
    let state: (Chapter) -> ChapterState
    var onPick: (Chapter) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(title).font(.kid(24, .black)).foregroundStyle(Palette.ink)
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            }
            ForEach(chapters) { chapter in
                let s = state(chapter)
                Button {
                    Haptics.tap()
                    onPick(chapter)
                } label: {
                    HStack(spacing: 12) {
                        Text(chapter.icon).font(.system(size: 34))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chapter.title).font(.kid(19, .black))
                            Text(s == .locked ? "Opens later in your adventure" : s == .done ? "Done! Play again" : "Ready!")
                                .font(.kid(14, .bold)).opacity(0.75)
                        }
                        Spacer()
                        Image(systemName: s == .locked ? "lock.fill" : "play.fill").font(.title2)
                    }
                    .foregroundStyle(s == .locked ? Color.gray : Palette.ink)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 20).fill(s == .locked ? Color(hex: 0xF1F2F5) : Color(hex: 0xFFF4C2)))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(s == .locked)
                .accessibilityLabel("\(chapter.title), \(s == .locked ? "locked" : "ready to play")")
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 20)
        .transition(.panel)
    }
}
