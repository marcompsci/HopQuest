import SwiftUI

// Hop Village 2.6: today's season, weather and festival, the festival notice board, and decorating your house.

/// Pixel art drawn crisp (no blur), for the house layers.
private struct PixelImage: View {
    let name: String
    var body: some View {
        if let img = ArtLibrary.image(name) {
            Image(uiImage: img).resizable().interpolation(.none).scaledToFit()
        } else {
            Color.clear
        }
    }
}

/// "🍂 Autumn · 🌧️ Rainy · 🎃 Harvest Fair" under the top bar. Tap to open the notice board.
struct VillageTodayPill: View {
    let day: VillageDay
    let festival: Festival
    let seasonsOn: Bool
    var onTap: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            HStack(spacing: 6) {
                if seasonsOn {
                    Text("\(day.season.icon) \(day.season.title)")
                    Text("·").opacity(0.5)
                    Text("\(day.weather.icon) \(day.weather.title)")
                    Text("·").opacity(0.5)
                }
                Text("\(festival.icon) \(festival.title)")
            }
            .font(.kid(13, .black))
            .foregroundStyle(Palette.ink)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 12).frame(minHeight: 44)
            .background(Capsule().fill(.regularMaterial).shadow(color: .black.opacity(0.12), radius: 8, y: 3))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(seasonsOn
            ? "Today: \(day.season.title), \(day.weather.title). Festival: \(festival.title). Tap for the notice board."
            : "Festival: \(festival.title). Tap for the notice board.")
    }
}

/// The notice board: what today is like, and every festival. Kids can celebrate any festival, any time.
struct FestivalBoardView: View {
    let day: VillageDay
    let current: Festival
    let missions: MissionSave
    let seasonsOn: Bool
    var maxHeight: CGFloat = 480
    var onPick: (Festival) -> Void
    var onGoToHost: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notice Board").font(.kid(24, .black)).displayTracking(24).foregroundStyle(Palette.ink)
                    Text("\(FestivalMissions.all.filter { missions.status($0) == .done }.count) of \(Festival.allCases.count) festivals celebrated")
                        .font(.kid(14, .bold)).foregroundStyle(Palette.purple)
                }
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            }
            ScrollView {
                VStack(spacing: 10) {
                    if seasonsOn { todayCard }
                    ForEach(Festival.allCases, id: \.self) { f in row(f) }
                }
            }
            .frame(maxHeight: min(480, max(260, maxHeight)))
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 16)
        .transition(.panel)
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today: \(day.season.icon) \(day.season.title), \(day.weather.icon) \(day.weather.title.lowercased())")
                .font(.kid(16, .black)).foregroundStyle(Palette.ink)
            Text(day.season.fact).font(.kid(14, .bold)).foregroundStyle(Palette.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Narrator.shared.say("Today is a \(day.weather.title.lowercased()) \(day.season.title.lowercased()) day. \(day.season.fact) \(day.weather.lines[0])")
            } label: {
                Label("Read it to me", systemImage: "speaker.wave.2.fill").font(.kid(14, .black))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xFFF4C2)))
    }

    private func row(_ f: Festival) -> some View {
        let mission = FestivalMissions.mission(for: f)
        let status = mission.map { missions.status($0) } ?? .new
        let isCurrent = f == current
        let thisWeek = f == day.weekFestival
        return HStack(spacing: 12) {
            Text(f.icon).font(.system(size: 30))
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color(hex: 0xF3F1FA)))
            VStack(alignment: .leading, spacing: 2) {
                Text(f.title).font(.kid(17, .black)).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if thisWeek {
                    Text("this week").font(.kid(11, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Palette.purple))
                }
                Text(status == .done ? "Celebrated! \(f.houseReward.icon)" : "Your house gets: \(f.houseReward.icon)")
                    .font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            if isCurrent {
                Button {
                    Haptics.tap()
                    onGoToHost()
                } label: {
                    Text(status == .done ? "Party! 🎉" : "Go!")
                        .font(.kid(15, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(minHeight: 44)
                        .background(Capsule().fill(Palette.green))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Go to Gemma for the \(f.title)")
            } else {
                Button {
                    Haptics.tap(.pop)
                    onPick(f)
                } label: {
                    Text("Celebrate")
                        .font(.kid(14, .black)).foregroundStyle(Palette.purple)
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .background(Capsule().stroke(Palette.purple, lineWidth: 2))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Celebrate the \(f.title) instead")
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18).fill(isCurrent ? Color(hex: 0xDDF7E5) : Color(hex: 0xFAF8FF)))
    }
}

/// Decorate your house: wall, roof and door colors, and decorations (more come from festivals).
struct HomeDecorView: View {
    let style: HomeStyle
    let unlocked: [HomeExtra]
    let ownerName: String
    var maxHeight: CGFloat = 560
    var onChange: (HomeStyle) -> Void
    var onClose: () -> Void

    private static let wallSwatches: [UInt32] = [0xFFF3DC, 0xFFD6E8, 0xC8F2DD, 0xCDE8FF]
    private static let roofSwatches: [UInt32] = [0xFF6B6B, 0x4D96FF, 0xB983FF, 0x479B3A]
    private static let doorSwatches: [UInt32] = [0xB57A45, 0xD94A57, 0xE0A92E, 0x2F6FD1]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(ownerName)'s House").font(.kid(24, .black)).displayTracking(24).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Done", action: onClose)
            }
            ScrollView {
                VStack(spacing: 14) {
                    preview
                    swatchRow("Walls", Self.wallSwatches, selected: style.wall, names: HomeStyle.wallColors) { v in
                        var s = style; s.wall = v; onChange(s)
                    }
                    swatchRow("Roof", Self.roofSwatches, selected: style.roof, names: HomeStyle.roofColors) { v in
                        var s = style; s.roof = v; onChange(s)
                    }
                    swatchRow("Door", Self.doorSwatches, selected: style.door, names: HomeStyle.doorColors) { v in
                        var s = style; s.door = v; onChange(s)
                    }
                    decorations
                }
            }
            .frame(maxHeight: min(560, max(300, maxHeight)))
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 16)
        .transition(.panel)
    }

    private var preview: some View {
        ZStack {
            ForEach(style.layers, id: \.self) { PixelImage(name: $0) }
        }
        .frame(width: 160, height: 196)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0x93D962)))
        .animation(.spring(response: 0.3), value: style)
        .accessibilityLabel("Your house: \(HomeStyle.wallColors[style.wall]) walls, \(HomeStyle.roofColors[style.roof]) roof, \(HomeStyle.doorColors[style.door]) door, \(style.extras.count) decorations")
    }

    private func swatchRow(_ title: String, _ colors: [UInt32], selected: Int, names: [String], pick: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.kid(16, .black)).foregroundStyle(Palette.ink).frame(width: 60, alignment: .leading)
            ForEach(colors.indices, id: \.self) { i in
                Button {
                    Haptics.tap(.pop)
                    pick(i)
                } label: {
                    Circle().fill(Color(hex: colors[i]))
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(Palette.ink.opacity(0.25), lineWidth: 2))
                        .overlay(Circle().stroke(Palette.purple, lineWidth: i == selected ? 4 : 0).padding(-4))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("\(title): \(names[i])\(i == selected ? ", chosen" : "")")
            }
            Spacer(minLength: 0)
        }
    }

    private var decorations: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Decorations").font(.kid(16, .black)).foregroundStyle(Palette.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(HomeExtra.allCases, id: \.self) { e in
                    let open = unlocked.contains(e)
                    let on = style.extras.contains(e)
                    Button {
                        guard open else {
                            Haptics.bump(.oops)
                            if let f = e.festival { Narrator.shared.say("Celebrate the \(f.title) to get this for your house!") }
                            return
                        }
                        Haptics.tap(.pop)
                        var s = style
                        if on { s.extras.remove(e) } else { s.extras.insert(e) }
                        onChange(s)
                    } label: {
                        VStack(spacing: 2) {
                            Text(open ? e.icon : "🔒").font(.system(size: 26))
                            Text(e.title).font(.kid(12, .black)).foregroundStyle(Palette.ink)
                                .lineLimit(1).minimumScaleFactor(0.7)
                            if !open, let f = e.festival {
                                Text(f.title).font(.kid(10, .bold)).foregroundStyle(.secondary)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .background(RoundedRectangle(cornerRadius: 14).fill(on ? Color(hex: 0xDDF7E5) : Color(hex: 0xF3F1FA)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Palette.green : .clear, lineWidth: 3))
                        .opacity(open ? 1 : 0.6)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel(open ? "\(e.title), \(on ? "on" : "off")" : "\(e.title), locked. Celebrate the \(e.festival?.title ?? "festival") to get it.")
                }
            }
        }
    }
}
