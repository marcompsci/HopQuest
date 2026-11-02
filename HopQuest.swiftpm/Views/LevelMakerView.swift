import SwiftUI

/// Star Hop Level Maker (v8.6): put stars, puff clouds and a spring on the board, pick a sky, then play it.
struct LevelMakerView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var editing: CustomHopLevel?
    @State private var tool: CustomHopLevel.Tool = .star
    @State private var playing: CustomHopLevel?
    @State private var tip: String?
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            if let playing {
                StarHopPlayView(onBack: { self.playing = nil }, custom: playing)
                    .transition(.opacity)
            } else if let level = editing {
                editor(level)
            } else {
                list
            }
        }
        .animation(Motion.present, value: editing?.id)
        .animation(Motion.present, value: playing?.id)
        .onAppear { Narrator.shared.say("Level Maker! Make your own Star Hop level, then play it.") }
    }

    // MARK: My levels

    private var list: some View {
        let saved = store.profile?.levelMaker.levels ?? []
        return ZStack {
            LinearGradient(colors: [Color(hex: 0xEDE7FF), Color(hex: 0xFFF6FB)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                        Spacer()
                        Text(L10n.tr("Level Maker")).font(.kid(26, .black)).foregroundStyle(Palette.ink)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }
                    BigButton(title: "Make a new level", color: Palette.purple) {
                        guard var p = store.profile else { return }
                        if p.levelMaker.levels.count >= CustomHopLevel.maxSaved {
                            Narrator.shared.say("You have six levels. Open one to change it, or delete one first.")
                            return
                        }
                        let fresh = p.levelMaker.newLevel()
                        store.profile = p
                        tool = .star
                        editing = fresh
                    }
                    ForEach(saved) { lv in
                        HStack(spacing: 12) {
                            MiniBoard(level: lv).frame(width: 110, height: 62)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lv.name).font(.kid(18, .black)).foregroundStyle(Palette.ink)
                                Text("\(lv.stars.count) ⭐ · \(lv.clouds.count) ☁️").font(.kid(13, .semibold)).foregroundStyle(Palette.ink.opacity(0.6))
                            }
                            Spacer()
                            Button { Haptics.tap(); playing = lv } label: {
                                Image(systemName: "play.fill").font(.system(size: 18, weight: .black)).foregroundStyle(.white)
                                    .frame(width: 46, height: 46).background(Circle().fill(Palette.green))
                            }
                            .buttonStyle(BouncyButtonStyle()).accessibilityLabel("Play \(lv.name)")
                            Button { Haptics.tap(); tool = .star; editing = lv } label: {
                                Image(systemName: "pencil").font(.system(size: 18, weight: .black)).foregroundStyle(Palette.purple)
                                    .frame(width: 46, height: 46).background(Circle().fill(.white))
                            }
                            .buttonStyle(BouncyButtonStyle()).accessibilityLabel("Change \(lv.name)")
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.85)))
                    }
                    if saved.isEmpty {
                        Text("Your levels show up here. You can keep six.").font(.kid(15, .semibold)).foregroundStyle(Palette.ink.opacity(0.6))
                    }
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
    }

    // MARK: Editor

    private func editor(_ level: CustomHopLevel) -> some View {
        let theme = CustomHopLevel.themes[level.theme]
        return ZStack {
            HopSky(level: theme).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    CircleIconButton(systemName: "xmark", label: "Close without saving") { editing = nil }
                    if store.profile?.levelMaker.levels.contains(where: { $0.id == level.id }) == true {
                        CircleIconButton(systemName: "trash", label: "Delete this level") { confirmDelete = true }
                    }
                    Spacer()
                    Text(level.name).font(.kid(22, .black)).foregroundStyle(theme.night ? .white : Palette.ink)
                    Spacer()
                    Button { save(level) } label: {
                        Text(L10n.tr("Save")).font(.kid(16, .black)).foregroundStyle(.white)
                            .padding(.horizontal, 16).frame(height: 44).background(Capsule().fill(Palette.green))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(!level.canPlay).opacity(level.canPlay ? 1 : 0.5)
                }
                // the board: tap a square to use the tool
                GeometryReader { geo in
                    let cw = geo.size.width / CGFloat(StarHop.columns)
                    let rh = (geo.size.height - 16) / CGFloat(StarHop.rows)
                    ZStack(alignment: .topLeading) {
                        Rectangle().fill(Color(hop: theme.grass)).frame(height: 8).offset(y: geo.size.height - 16)
                        Rectangle().fill(Color(hop: theme.soil)).frame(height: 8).offset(y: geo.size.height - 8)
                        ForEach(0..<(StarHop.columns * StarHop.rows), id: \.self) { cell in
                            let c = cell % StarHop.columns, r = cell / StarHop.columns
                            Button { use(at: cell) } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                    square(level, cell: cell, unit: min(cw, rh))
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: cw - 4, height: rh - 4)
                            .position(x: (CGFloat(c) + 0.5) * cw, y: geo.size.height - 16 - (CGFloat(r) + 0.5) * rh)
                            .accessibilityLabel(squareLabel(level, cell: cell))
                        }
                    }
                }
                .frame(height: 260)
                if let tip {
                    Text(L10n.tr(tip)).font(.kid(14, .bold)).foregroundStyle(Palette.ink).padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.9))).transition(.opacity)
                }
                // tools
                HStack(spacing: 10) {
                    ForEach(CustomHopLevel.Tool.allCases, id: \.self) { t in
                        Button { Haptics.tap(); tool = t } label: {
                            VStack(spacing: 2) {
                                toolIcon(t).frame(width: 34, height: 30)
                                Text(toolName(t)).font(.kid(12, .black)).foregroundStyle(Palette.ink)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tool == t ? Palette.purple : .clear, lineWidth: 3))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("\(toolName(t))\(tool == t ? ", selected" : "")")
                    }
                }
                // skies
                HStack(spacing: 8) {
                    ForEach(Array(CustomHopLevel.themes.enumerated()), id: \.offset) { i, t in
                        Button { editing?.theme = i } label: {
                            Circle().fill(LinearGradient(colors: [Color(hop: t.skyTop), Color(hop: t.grass)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(level.theme == i ? Palette.purple : .white, lineWidth: level.theme == i ? 3 : 1.5))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("\(HopWords.tr(t.title, L10n.isSpanish)) sky")
                        .accessibilityAddTraits(level.theme == i ? .isSelected : [])
                    }
                }
                BigButton(title: "Play it!", color: Palette.purple) {
                    guard level.canPlay else { flash("Put at least one star on the board."); return }
                    // try it out without saving: closing without saving really leaves nothing behind
                    playing = level
                }
                .opacity(level.canPlay ? 1 : 0.5)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .animation(.easeOut(duration: 0.2), value: tip)
        .confirmationDialog("Delete \(level.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.profile?.levelMaker.delete(level.id)
                editing = nil
            }
        }
    }

    private func use(at cell: Int) {
        guard var lv = editing else { return }
        let result = lv.apply(tool, at: cell)
        if result.ok { Haptics.tap(); editing = lv }
        if let why = result.why { flash(why) } else if result.ok { tip = nil }
    }

    private func flash(_ text: String) {
        tip = text
        Narrator.shared.say(text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { if tip == text { tip = nil } }
    }

    private func save(_ level: CustomHopLevel, close: Bool = true) {
        guard level.canPlay, var p = store.profile else { return }
        p.levelMaker.save(level)
        store.profile = p
        if close { editing = nil }
    }

    @ViewBuilder private func square(_ level: CustomHopLevel, cell: Int, unit: CGFloat) -> some View {
        if cell == CustomHopLevel.startCell {
            CharacterBadge(character: store.character, size: unit * 0.7)
        }
        switch level.thing(at: cell) {
        case .star: ArtImage("goal_star").frame(width: unit * 0.6, height: unit * 0.6)
        case .cloud: PuffCloud(night: CustomHopLevel.themes[level.theme].night).frame(width: unit * 0.85, height: unit * 0.6)
        case .spring: SpringPad(squashed: false).frame(width: unit * 0.6, height: unit * 0.32)
        default: EmptyView()
        }
    }

    private func squareLabel(_ level: CustomHopLevel, cell: Int) -> String {
        let c = cell % StarHop.columns + 1, r = cell / StarHop.columns
        let height = r == 0 ? "ground" : r == 1 ? "middle" : "top"
        let what: String
        if cell == CustomHopLevel.startCell { what = "your buddy starts here" }
        else {
            switch level.thing(at: cell) {
            case .star: what = "star"
            case .cloud: what = "cloud"
            case .spring: what = "spring"
            default: what = "empty"
            }
        }
        return "Column \(c), \(height): \(what)"
    }

    private func toolName(_ t: CustomHopLevel.Tool) -> String {
        switch t {
        case .star: return L10n.isSpanish ? "Estrella" : "Star"
        case .cloud: return L10n.isSpanish ? "Nube" : "Cloud"
        case .spring: return L10n.isSpanish ? "Resorte" : "Spring"
        case .erase: return L10n.isSpanish ? "Borrar" : "Eraser"
        }
    }

    @ViewBuilder private func toolIcon(_ t: CustomHopLevel.Tool) -> some View {
        switch t {
        case .star: ArtImage("goal_star")
        case .cloud: PuffCloud(night: false)
        case .spring: SpringPad(squashed: false).frame(width: 30, height: 16)
        case .erase: Image(systemName: "eraser.fill").font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.red)
        }
    }
}

/// A little picture of a made level, for the list.
struct MiniBoard: View {
    let level: CustomHopLevel
    var body: some View {
        let t = CustomHopLevel.themes[level.theme]
        GeometryReader { g in
            let cw = g.size.width / CGFloat(StarHop.columns), rh = (g.size.height - 6) / CGFloat(StarHop.rows)
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hop: t.skyTop), Color(hop: t.skyBottom)], startPoint: .top, endPoint: .bottom)
                Rectangle().fill(Color(hop: t.grass)).frame(height: 6).offset(y: g.size.height - 6)
                ForEach(0..<(StarHop.columns * StarHop.rows), id: \.self) { cell in
                    let c = cell % StarHop.columns, r = cell / StarHop.columns
                    Group {
                        switch level.thing(at: cell) {
                        case .star: Image(systemName: "star.fill").foregroundStyle(Color(hop: 0xFFC83D))
                        case .cloud: Image(systemName: "cloud.fill").foregroundStyle(.white)
                        case .spring: Image(systemName: "arrow.up.circle.fill").foregroundStyle(Palette.red)
                        default: EmptyView()
                        }
                    }
                    .font(.system(size: min(cw, rh) * 0.7))
                    .position(x: (CGFloat(c) + 0.5) * cw, y: g.size.height - 6 - (CGFloat(r) + 0.5) * rh)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }
}
