import SwiftUI
import SpriteKit

/// Pick a Bubble Kart cup.
struct KartSelectView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void
    var onStart: (Chapter) -> Void

    @AppStorage("hopquest.kart.autogas") private var autoGas = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFE4F3), Color(hex: 0xD8F7FF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        CircleIconButton(systemName: "house.fill", label: "Back to map", action: onBack)
                        Spacer()
                        SpeakButton { Narrator.shared.say(intro) }
                    }
                    HStack(spacing: 6) {
                        ArtImage("icon_kart").frame(width: 64, height: 64)
                        Text("Bubble Kart")
                            .font(.kid(36, .black))
                            .foregroundStyle(Palette.purple)
                    }
                    HStack(spacing: 10) {
                        CharacterBadge(character: store.character, size: 56)
                        Text("No crashes here — bumps just float you in a bubble!")
                            .font(.kid(16, .semibold))
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))

                    ForEach(Chapters.kartCups) { cup in
                        cupCard(cup)
                    }

                    Toggle(isOn: $autoGas) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-gas").font(.kid(18, .black)).foregroundStyle(Palette.ink)
                            Text("The kart drives itself forward. You just steer!")
                                .font(.kid(13, .medium)).foregroundStyle(Palette.ink.opacity(0.7))
                        }
                    }
                    .tint(Palette.green)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))

                    howTo
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .onAppear { Narrator.shared.say(intro) }
    }

    private var intro: String {
        "Bubble Kart! Pick a race. Grab question boxes for items, and drive through the right answer at Math Gates for a super boost!"
    }

    private func cupCard(_ cup: Chapter) -> some View {
        let best = store.profile?.kartBest[cup.id]
        let medal = best.map { ["🥇", "🥈", "🥉", "🏁"][min($0, 4) - 1] }
        let level = cup.difficulty < 0.3 ? "Easy" : cup.difficulty < 0.7 ? "Medium" : "Tricky"
        return Button {
            Haptics.tap()
            onStart(cup)
        } label: {
            HStack(spacing: 14) {
                Text(cup.icon).font(.system(size: 42))
                VStack(alignment: .leading, spacing: 4) {
                    Text(cup.title).font(.kid(22, .black)).foregroundStyle(.white)
                    Text("\(level) · 3 laps").font(.kid(14, .bold)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                if let medal {
                    Text(medal).font(.system(size: 34)).accessibilityLabel("Best finish")
                }
                Image(systemName: "play.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(cupColor(cup))
                .shadow(color: cupColor(cup).opacity(0.45), radius: 0, x: 0, y: 6))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(cup.title), \(level)")
    }

    private func cupColor(_ cup: Chapter) -> Color {
        switch cup.id {
        case 202: return Color(hex: 0xFF7FC4)
        case 203: return Color(hex: 0x6C7BD9)
        default: return Color(hex: 0x34C77B)
        }
    }

    private var howTo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to race").font(.kid(17, .black)).foregroundStyle(Palette.ink)
            row("⬅️➡️", "Tap the arrows to change lanes.")
            artRow("item_box", "Drive through ? boxes to get an item.")
            artRow("item_shield", "Bubble Shield blocks one bump.")
            artRow("item_carrot", "Carrot Boost makes you zoom.")
            artRow("item_jelly", "Jelly Pad drops behind you — racers bounce on it.")
            row("🧠", "Math Gates: drive through the right answer for a super boost!")
            row("🟤", "Steer around mud puddles.")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))
    }

    private func artRow(_ art: String, _ text: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ArtImage(art).frame(width: 32, height: 32).frame(width: 36, alignment: .leading)
            Text(text).font(.kid(14, .medium)).foregroundStyle(Palette.ink.opacity(0.85))
        }
    }

    private func row(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).frame(width: 36, alignment: .leading)
            Text(text).font(.kid(14, .medium)).foregroundStyle(Palette.ink.opacity(0.85))
        }
    }
}

/// The race itself plus the podium at the end.
struct KartGameView: View {
    let chapter: Chapter
    /// Two players on one phone: the second racer's buddy.
    var partner: GameCharacter? = nil
    var onExit: () -> Void
    /// (stars, place, raceAgain)
    var onFinish: (Int, Int, Bool) -> Void

    @EnvironmentObject var store: GameStore
    @StateObject private var hud = KartHUD()
    @State private var scene: KartScene?
    @AppStorage("hopquest.kart.autogas") private var autoGas = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: 0x8FD86E).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }

                VStack(spacing: 8) {
                    topBar
                    if let message = hud.message {
                        MessageBubble(text: message)
                    }
                    Spacer()
                    controls
                }
                .padding(.top, 6)
                .padding(.bottom, 14)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hud.message)

                if let count = hud.countdown {
                    Text(count)
                        .font(.kid(96, .black))
                        .foregroundStyle(.white)
                        .shadow(color: Palette.purple, radius: 0, x: 4, y: 6)
                        .id(count)
                        .transition(.scale(scale: 2).combined(with: .opacity))
                }

                if hud.finished {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    podium
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hud.countdown)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: hud.finished)
            .onAppear {
                guard scene == nil, geo.size.width > 0 else { return }
                let s = KartScene(size: geo.size, chapter: chapter, character: store.character, partner: partner, theme: store.theme, hud: hud)
                s.autoGas = autoGas
                scene = s
            }
            .onDisappear { Narrator.shared.stop() }
        }
    }

    /// The team's best finish (two players), or the player's.
    private var bestPlace: Int {
        partner == nil ? hud.finalPlace : min(max(hud.finalPlace, 1), max(hud.finalPlace2, 1))
    }

    private var stars: Int {
        let placeStars = [3, 2, 1, 1][max(1, min(bestPlace, 4)) - 1]
        // two players share the math gates, so the bonus is capped to keep stars fair
        return placeStars + (partner == nil ? hud.mathRight : min(hud.mathRight, 4))
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            CircleIconButton(systemName: "house.fill", label: "Leave race", action: onExit)
            if partner != nil {
                pill("⭐ " + placeText(hud.place))
                pill("💜 " + placeText(hud.place2))
            } else {
                pill(placeText(hud.place), big: true)
            }
            pill("Lap \(hud.lap)/\(hud.laps)")
            pill("🧠 \(hud.mathRight)")
            Spacer()
        }
        .padding(.horizontal, 14)
    }

    private func placeText(_ p: Int) -> String {
        ["1st", "2nd", "3rd", "4th"][max(1, min(p, 4)) - 1]
    }

    private func pill(_ text: String, big: Bool = false) -> some View {
        Text(text)
            .font(.kid(big ? 22 : 16, .black))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Capsule().fill(.white.opacity(0.92)))
            .contentTransition(.numericText())
    }

    @ViewBuilder
    private var controls: some View {
        if partner != nil { twoPlayerControls } else { soloControls }
    }

    /// One cluster per player: ⭐ on the left, 💜 on the right. Gas is automatic.
    private var twoPlayerControls: some View {
        HStack(alignment: .bottom) {
            seatCluster(0)
            Spacer(minLength: 8)
            seatCluster(1)
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func seatCluster(_ seat: Int) -> some View {
        let item = seat == 0 ? hud.item : hud.item2
        return VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(seat == 0 ? "⭐" : "💜").font(.system(size: 22))
                Button { scene?.useItem(seat: seat) } label: {
                    ArtImage(item?.art ?? "item_box")
                        .frame(width: 34, height: 34)
                        .opacity(item == nil ? 0.55 : 1)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(item == nil ? Color.gray.opacity(0.6) : Color(hex: 0xFFB020)))
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(item == nil)
                .accessibilityLabel((seat == 0 ? "Star player: " : "Heart player: ") + (item.map { "use \($0.title)" } ?? "no item yet"))
            }
            HStack(spacing: 8) {
                laneButton("arrowtriangle.left.fill", dir: -1, seat: seat, size: 58)
                laneButton("arrowtriangle.right.fill", dir: 1, seat: seat, size: 58)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: seat == 0 ? 0xFFD93D : 0xB983FF).opacity(0.35)))
    }

    private var soloControls: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                itemButton
                HStack(spacing: 10) {
                    laneButton("arrowtriangle.left.fill", dir: -1)
                    laneButton("arrowtriangle.right.fill", dir: 1)
                }
            }
            Spacer(minLength: 0)
            // real-car layout: brake on the left, gas on the far right
            HStack(alignment: .bottom, spacing: 12) {
                Pedal(kind: .brake, compact: true) { scene?.brake = $0 > 0.5 }
                if !autoGas {
                    Pedal(kind: .gas, compact: true) { scene?.gas = $0 > 0.5 }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func laneButton(_ icon: String, dir: Int, seat: Int = 0, size: CGFloat = 68) -> some View {
        Button { scene?.steer(dir, seat: seat) } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.44, weight: .black))
                .foregroundStyle(Palette.ink)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.92)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel((partner == nil ? "" : seat == 0 ? "Star player: " : "Heart player: ") + (dir < 0 ? "move left" : "move right"))
    }

    private var itemButton: some View {
        Button { scene?.useItem() } label: {
            VStack(spacing: 0) {
                ArtImage(hud.item?.art ?? "item_box")
                    .frame(width: 46, height: 46)
                    .opacity(hud.item == nil ? 0.55 : 1)
                Text("ITEM").font(.kid(12, .black)).foregroundStyle(.white)
            }
            .frame(width: 84, height: 84)
            .background(Circle().fill(hud.item == nil ? Color.gray.opacity(0.6) : Color(hex: 0xFFB020)))
            .overlay(Circle().stroke(.white, lineWidth: 3))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(hud.item == nil)
        .accessibilityLabel(hud.item.map { "Use \($0.title)" } ?? "No item yet")
    }

    private var podium: some View {
        VStack(spacing: 14) {
            Text(partner != nil ? (bestPlace == 1 ? "🏆 Team win!" : "🏁 Race complete!") : (hud.finalPlace == 1 ? "🏆 You won!" : "🏁 Race complete!"))
                .font(.kid(32, .black))
                .foregroundStyle(Palette.purple)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach([1, 0, 2], id: \.self) { i in
                    if i < hud.podium.count {
                        step(hud.podium[i], place: i + 1)
                    }
                }
            }
            HStack(spacing: 16) {
                Label("\(hud.mathRight) Math Gates", systemImage: "brain.head.profile")
                Text("⭐ +\(stars)")
            }
            .font(.kid(17, .bold))
            .foregroundStyle(Palette.ink)
            HStack(spacing: 12) {
                BigButton(title: "Race again 🔁", color: Palette.purple) {
                    onFinish(stars, bestPlace, true)
                }
                BigButton(title: "Done 🎈", color: Palette.green) {
                    onFinish(stars, bestPlace, false)
                }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(20)
        .onAppear {
            if partner != nil {
                Narrator.shared.say("Star player finished \(placeText(hud.finalPlace)), heart player finished \(placeText(hud.finalPlace2))! Together you got \(hud.mathRight) math gates right and earned \(stars) stars!")
            } else {
                let place = placeText(hud.finalPlace)
                Narrator.shared.say("You finished \(place)! You got \(hud.mathRight) math gates right and earned \(stars) stars!")
            }
        }
    }

    private func step(_ c: GameCharacter, place: Int) -> some View {
        let heights: [CGFloat] = [96, 68, 48]
        let isMe = c.id == store.character.id
        let isPartner = c.id == partner?.id
        return VStack(spacing: 6) {
            CharacterBadge(character: c, size: place == 1 ? 70 : 56)
                .overlay(alignment: .top) {
                    if isMe { Text("⭐").offset(y: -14) } else if isPartner { Text("💜").offset(y: -14) }
                }
            Text(["🥇", "🥈", "🥉"][place - 1])
                .font(.system(size: 26))
                .frame(width: 84, height: heights[place - 1])
                .background(RoundedRectangle(cornerRadius: 12).fill(isMe ? Color(hex: 0xFFD93D) : isPartner ? Color(hex: 0xD9C2FF) : Color(hex: 0xE9D5FF)))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(placeText(place)): \(c.name)")
    }
}
