import SwiftUI

/// A hat, drawn with shapes so it scales cleanly (v7.5).
struct HatView: View {
    let kind: HatKind

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                switch kind {
                case .none:
                    EmptyView()
                case .party:
                    HatShape.cone.fill(LinearGradient(colors: [Color(hex: 0xFF6B9A), Color(hex: 0xB983FF)], startPoint: .top, endPoint: .bottom))
                        .overlay(HatShape.cone.stroke(Palette.ink, lineWidth: 2.5))
                        .frame(width: w * 0.55, height: h)
                    Circle().fill(Color(hex: 0xFFD93D)).overlay(Circle().stroke(Palette.ink, lineWidth: 2)).frame(width: w * 0.16).offset(y: -h * 0.92)
                case .cap:
                    Capsule().fill(Color(hex: 0x3E7BFA)).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)).frame(width: w * 0.95, height: h * 0.2).offset(x: w * 0.12)
                    HatShape.dome.fill(Color(hex: 0x3E7BFA)).overlay(HatShape.dome.stroke(Palette.ink, lineWidth: 2.5)).frame(width: w * 0.72, height: h * 0.7).offset(y: -h * 0.12)
                case .flower:
                    HStack(spacing: -w * 0.04) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "camera.macro").font(.system(size: w * 0.2, weight: .bold))
                                .foregroundStyle([Color(hex: 0xFF6B9A), Color(hex: 0xFFD93D), Color(hex: 0xB983FF), Color(hex: 0xFF9F45), Color(hex: 0x5FC86A)][i])
                                .offset(y: i == 2 ? -h * 0.15 : (i == 1 || i == 3 ? -h * 0.08 : 0))
                        }
                    }
                    .frame(width: w, height: h * 0.6)
                case .beanie:
                    HatShape.dome.fill(Color(hex: 0xFF5A5F)).overlay(HatShape.dome.stroke(Palette.ink, lineWidth: 2.5)).frame(width: w * 0.8, height: h * 0.72)
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xFFF1E6)).overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.ink, lineWidth: 2.5))
                        .frame(width: w * 0.84, height: h * 0.2)
                    Circle().fill(.white).overlay(Circle().stroke(Palette.ink, lineWidth: 2)).frame(width: w * 0.2).offset(y: -h * 0.66)
                case .crown:
                    HatShape.crown.fill(LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xF5B400)], startPoint: .top, endPoint: .bottom))
                        .overlay(HatShape.crown.stroke(Palette.ink, lineWidth: 2.5))
                        .frame(width: w * 0.78, height: h * 0.75)
                    Circle().fill(Color(hex: 0xFF5A5F)).frame(width: w * 0.1).offset(y: -h * 0.22)
                case .wizard:
                    HatShape.cone.fill(Color(hex: 0x5B4BC4)).overlay(HatShape.cone.stroke(Palette.ink, lineWidth: 2.5)).frame(width: w * 0.62, height: h)
                    Capsule().fill(Color(hex: 0x5B4BC4)).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)).frame(width: w, height: h * 0.18)
                    Image(systemName: "star.fill").font(.system(size: w * 0.15)).foregroundStyle(Color(hex: 0xFFD93D)).offset(y: -h * 0.42)
                case .topHat:
                    RoundedRectangle(cornerRadius: 3).fill(Palette.ink).frame(width: w * 0.56, height: h * 0.85).offset(y: -h * 0.08)
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xFF5A5F)).frame(width: w * 0.56, height: h * 0.14).offset(y: -h * 0.16)
                    Capsule().fill(Palette.ink).frame(width: w * 0.95, height: h * 0.16)
                case .astronaut:
                    Circle().fill(.white.opacity(0.35)).overlay(Circle().stroke(.white, lineWidth: 4)).overlay(Circle().stroke(Palette.ink, lineWidth: 2))
                        .frame(width: w * 1.1, height: w * 1.1).offset(y: w * 0.45)
                }
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

private enum HatShape: Shape {
    case cone, dome, crown
    func path(in r: CGRect) -> Path {
        var p = Path()
        switch self {
        case .cone:
            p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        case .dome:
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY), control1: CGPoint(x: r.minX, y: r.minY - r.height * 0.2), control2: CGPoint(x: r.maxX, y: r.minY - r.height * 0.2))
            p.closeSubpath()
        case .crown:
            let pts: [(CGFloat, CGFloat)] = [(0, 1), (0, 0.15), (0.25, 0.55), (0.5, 0), (0.75, 0.55), (1, 0.15), (1, 1)]
            p.move(to: CGPoint(x: r.minX + pts[0].0 * r.width, y: r.minY + pts[0].1 * r.height))
            for q in pts.dropFirst() { p.addLine(to: CGPoint(x: r.minX + q.0 * r.width, y: r.minY + q.1 * r.height)) }
            p.closeSubpath()
        }
        return p
    }
}

/// The buddy wearing its hat.
struct BuddyAvatar: View {
    let character: GameCharacter
    let hat: HatKind
    var size: CGFloat = 64

    var body: some View {
        CharacterBadge(character: character, size: size)
            .overlay(alignment: .top) {
                if hat != .none {
                    HatView(kind: hat)
                        .frame(width: size * 0.62, height: size * 0.42)
                        .offset(y: -size * (hat == .astronaut ? 0.02 : 0.2))
                }
            }
    }
}

/// The hat shelf on the Badges screen: earn badges, unlock hats, tap one to wear it.
struct HatShelf: View {
    @EnvironmentObject var store: GameStore
    let badges: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.tr("Buddy hats")).font(.kid(20, .black)).foregroundStyle(Palette.ink)
                Spacer()
                if let next = HatKind.next(badges: badges) {
                    Text(L10n.tr("\(next.more) more \(next.more == 1 ? "badge" : "badges") for the \(next.hat.title)"))
                        .font(.kid(12, .semibold)).foregroundStyle(Palette.ink.opacity(0.6)).multilineTextAlignment(.trailing)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HatKind.allCases) { hat in
                        let open = hat.unlocked(badges: badges)
                        let wearing = (store.profile?.hat ?? .none) == hat
                        Button {
                            guard open else { return }
                            Haptics.tap()
                            store.profile?.hat = hat
                            Narrator.shared.say(hat == .none ? "No hat." : "\(hat.title)!")
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    if hat == .none {
                                        Image(systemName: "nosign").font(.system(size: 26, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.4))
                                    } else {
                                        HatView(kind: hat).frame(width: 52, height: 40).opacity(open ? 1 : 0.25)
                                    }
                                    if !open {
                                        Image(systemName: "lock.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.55))
                                    }
                                }
                                .frame(width: 68, height: 60)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(wearing ? Palette.purple : .clear, lineWidth: 3))
                                Text(open ? hat.title : "\(hat.badgesNeeded) 🏅").font(.kid(11, .bold)).foregroundStyle(Palette.ink.opacity(open ? 0.85 : 0.5))
                                    .lineLimit(1).minimumScaleFactor(0.7).frame(width: 70)
                            }
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("\(hat.title)\(wearing ? ", wearing" : "")\(open ? "" : ", needs \(hat.badgesNeeded) badges")")
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.7)))
    }
}

extension GameStore {
    /// Places on the menu (v9.9): false when a grown-up took this learning place off the menu.
    func placeShown(_ id: String) -> Bool { !(profile?.hiddenPlaces.contains(id) ?? false) }

    /// The learning places that have a tile on the menu (Code Club lives inside Coding Lab).
    var menuPlaceAreas: [LearningArea] { learningAreas.filter { $0.id != "code" } }

    /// Shows or hides a learning place on the menu. The last place shown can't be hidden.
    func setPlaceShown(_ id: String, _ shown: Bool) {
        guard profile != nil else { return }
        let all = menuPlaceAreas.map(\.id)
        profile?.hiddenPlaces = MenuPlaces.setShown(shown, id: id, hidden: profile?.hiddenPlaces ?? [], all: all)
    }

    /// Surprise Me (v7.4): a learning place with a game not finished yet.
    func surprisePlace() -> String? {
        var g = SystemRandomNumberGenerator()
        let areas = learningAreas.filter { placeShown($0.id) }.map { (id: $0.id, bests: $0.skills.map(\.best)) }
        let pick = SurpriseMe.pick(areas: areas, last: profile?.lastSurprise, using: &g)
        if let pick { profile?.lastSurprise = pick }
        return pick
    }
}
