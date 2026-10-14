import SwiftUI

/// Sticker Book: collect every buddy. Every few stars earns a sticker pack;
/// opening one reveals a new buddy with a fun fact read aloud.
struct StickerBookView: View {
    var onBack: () -> Void

    @EnvironmentObject var store: GameStore
    @State private var reveal: GameCharacter?
    @State private var flipped = false
    @State private var detail: GameCharacter?
    @State private var packWiggle = false

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF4E0), Color(hex: 0xF3ECFF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    packCard
                    ForEach(CharacterFamily.allCases) { family in
                        section(family)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }

            if let reveal {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .onTapGesture { closeReveal() }
                revealCard(reveal)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else if let detail {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture { self.detail = nil }
                detailCard(detail)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: reveal?.id)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: detail?.id)
        .onAppear {
            Narrator.shared.say(store.packsAvailable > 0
                ? "Your Sticker Book! You have a sticker pack to open!"
                : "Your Sticker Book! Earn stars to get sticker packs.")
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { packWiggle = true }
        }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                CircleIconButton(systemName: "house.fill", label: "Back to map", action: onBack)
                Spacer()
                SpeakButton { Narrator.shared.say("You have \(store.ownedStickers.count) of \(Roster.all.count) stickers.") }
            }
            HStack(spacing: 8) {
                ArtImage("icon_stickers").frame(width: 58, height: 58)
                Text("Sticker Book")
                    .font(.kid(34, .black))
                    .foregroundStyle(Palette.purple)
            }
            let owned = store.ownedStickers.count
            let total = Roster.all.count
            VStack(spacing: 4) {
                Text("\(owned) of \(total) buddies")
                    .font(.kid(16, .bold))
                    .foregroundStyle(Palette.ink)
                Capsule()
                    .fill(Palette.ink.opacity(0.1))
                    .frame(height: 12)
                    .overlay(alignment: .leading) {
                        GeometryReader { g in
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: 0xFF7FC4), Palette.purple], startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * CGFloat(owned) / CGFloat(total))
                        }
                    }
                    .padding(.horizontal, 30)
            }
        }
    }

    private var packCard: some View {
        let packs = store.packsAvailable
        return Group {
            if packs > 0 {
                Button(action: openPack) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [Color(hex: 0xFFD93D), Color(hex: 0xFF9F45)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 64, height: 82)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink, lineWidth: 3))
                            ArtImage("goal_star").frame(width: 40, height: 40)
                        }
                        .rotationEffect(.degrees(packWiggle ? -6 : 6))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(packs == 1 ? "Open your sticker pack!" : "Open a sticker pack! (\(packs))")
                                .font(.kid(20, .black))
                                .foregroundStyle(.white)
                            Text("Tap to find out who's inside!")
                                .font(.kid(14, .bold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Palette.purple).shadow(color: Color(hex: 0x5B32D6), radius: 0, x: 0, y: 5))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Open a sticker pack")
            } else if store.ownedStickers.count < Roster.all.count {
                HStack(spacing: 10) {
                    ArtImage("goal_star").frame(width: 34, height: 34)
                    Text("Earn **\(store.starsToNextPack) more star\(store.starsToNextPack == 1 ? "" : "s")** for your next sticker pack!")
                        .font(.kid(16, .medium))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))
            } else {
                Text("🏆 You collected every buddy! Amazing!")
                    .font(.kid(18, .black))
                    .foregroundStyle(Palette.purple)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))
            }
        }
    }

    private func section(_ family: CharacterFamily) -> some View {
        let list = Roster.all.filter { $0.family == family }
        let owned = store.ownedStickers
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(family.rawValue).font(.kid(20)).foregroundStyle(Palette.ink)
                Spacer()
                Text("\(list.filter { owned.contains($0.id) }.count)/\(list.count)")
                    .font(.kid(15, .bold))
                    .foregroundStyle(Palette.purple)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(list.enumerated()), id: \.element.id) { i, c in
                    if owned.contains(c.id) {
                        Button {
                            Haptics.tap()
                            detail = c
                            Narrator.shared.say("\(c.name)! \(c.fact)")
                        } label: {
                            sticker(c, tilt: i)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel(c.name)
                    } else {
                        ArtImage("sticker_locked")
                            .frame(width: 80, height: 80)
                            .frame(maxWidth: .infinity)
                            .frame(height: 112)
                            .accessibilityLabel("A buddy you haven't found yet")
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.6)))
    }

    /// A die-cut sticker: thick white border, soft colored backing, a tiny tilt.
    private func sticker(_ c: GameCharacter, tilt: Int, size: CGFloat = 84) -> some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 3)
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(c.color.opacity(0.45))
                    .padding(size * 0.07)
                CharacterBadge(character: c, size: size * 0.8)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees([-5, 4, -2, 6, -4, 3][tilt % 6]))
            Text(c.name)
                .font(.kid(11, .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Opening a pack

    private func openPack() {
        guard let c = store.openPack() else { return }
        Haptics.success(.fanfare)
        flipped = false
        reveal = c
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { flipped = true }
            Haptics.success(.star)
            Narrator.shared.say("You got \(c.name)! \(c.fact)")
        }
    }

    private func closeReveal() {
        guard flipped else { return }
        reveal = nil
    }

    private func revealCard(_ c: GameCharacter) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // back of the card: the pack
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(colors: [Color(hex: 0xFFD93D), Color(hex: 0xFF9F45)], startPoint: .top, endPoint: .bottom))
                    .overlay(ArtImage("goal_star").frame(width: 110, height: 110))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Palette.ink, lineWidth: 4))
                    .opacity(flipped ? 0 : 1)
                // front: the new sticker
                VStack(spacing: 8) {
                    Text("NEW STICKER!")
                        .font(.kid(18, .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 5)
                        .background(Capsule().fill(Color(hex: 0xFF7FC4)))
                    sticker(c, tilt: 1, size: 170)
                    Text(c.fact)
                        .font(.kid(16, .medium))
                        .foregroundStyle(Palette.ink.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 30).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(c.color, lineWidth: 5))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 1 : 0)
            }
            .frame(width: 290, height: 400)
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            if flipped {
                BigButton(title: store.packsAvailable > 0 ? "Next pack ➜" : "Stick it in! ✨", color: Palette.green) {
                    if store.packsAvailable > 0 {
                        reveal = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openPack() }
                    } else {
                        reveal = nil
                    }
                }
                .frame(width: 290)
                .transition(.opacity)
            }
        }
    }

    private func detailCard(_ c: GameCharacter) -> some View {
        VStack(spacing: 10) {
            CharacterBadge(character: c, size: 150, animated: true)
            Text(c.name).font(.kid(28, .black)).foregroundStyle(Palette.ink)
            Text(c.family.rawValue)
                .font(.kid(14, .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(Palette.purple))
            Text("Fun fact: \(c.fact)")
                .font(.kid(17, .medium))
                .foregroundStyle(Palette.ink.opacity(0.85))
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                BigButton(title: "Play as \(c.name.split(separator: " ").first.map(String.init) ?? c.name)", color: Palette.purple) {
                    store.profile?.characterID = c.id
                    Haptics.success(.chime)
                    Narrator.shared.say("\(c.name) is your buddy now!")
                    detail = nil
                }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(26)
    }
}
