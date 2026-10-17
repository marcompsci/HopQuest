import SwiftUI

/// Your garden beside the house: plant seeds, water them once a day, and pick them when they're ready.
/// Plants never wilt, so there's nothing to miss. Also where you pick your pet.
struct GardenView: View {
    let garden: GardenSave
    let today: String
    var maxHeight: CGFloat = 560
    var onPlant: (Int, PlantKind) -> Void
    var onWater: (Int) -> Void
    var onHarvest: (Int) -> Void
    var onPet: (PetKind?) -> Void
    var onClose: () -> Void

    @State private var choosingBed: Int?

    private static let stageIcons = ["🌰", "🌱", "🌿"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🌻 My Garden").font(.kid(24, .black)).foregroundStyle(Palette.ink)
                    Text("\(PlantKind.allCases.filter { (garden.harvested[$0.rawValue] ?? 0) > 0 }.count) of \(PlantKind.allCases.count) plants grown")
                        .font(.kid(14, .bold)).foregroundStyle(Palette.purple)
                }
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Done", action: onClose)
            }
            ScrollView {
                VStack(spacing: 14) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(0..<GardenSave.plotCount, id: \.self) { bed($0) }
                    }
                    if let i = choosingBed {
                        seedPicker(i)
                    }
                    Text("Plants grow a little every day, and faster when you water them (once a day). They never wilt, so take your time!")
                        .font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    pets
                }
            }
            .frame(maxHeight: min(560, max(300, maxHeight)))
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 16)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    @ViewBuilder
    private func bed(_ i: Int) -> some View {
        let plot = garden.plots[i]
        let stage = garden.stage(i, today: today)
        VStack(spacing: 4) {
            if let plot, let stage {
                Text(stage >= GardenSave.ripeStage ? plot.kind.emoji : Self.stageIcons[min(stage, 2)])
                    .font(.system(size: 34))
                Text(plot.kind.title).font(.kid(12, .black)).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
                if stage >= GardenSave.ripeStage {
                    bedButton("Pick! 🧺", Palette.green) { onHarvest(i) }
                } else if garden.wateredToday(i, today: today) {
                    Text("Watered ✓").font(.kid(12, .black)).foregroundStyle(Color(hex: 0x2F6FD1))
                        .frame(minHeight: 44)
                } else {
                    bedButton("Water 💧", Color(hex: 0x4D96FF)) { onWater(i) }
                }
            } else {
                Text("🟫").font(.system(size: 34))
                Text("Empty").font(.kid(12, .black)).foregroundStyle(Palette.ink.opacity(0.6))
                bedButton(choosingBed == i ? "Pick a seed" : "Plant 🌱", Color(hex: 0xB57A45)) {
                    choosingBed = choosingBed == i ? nil : i
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 16).fill(choosingBed == i ? Color(hex: 0xFFF1D6) : Color(hex: 0xF3F1FA)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibility(i, plot: plot, stage: stage))
    }

    private func accessibility(_ i: Int, plot: GardenPlot?, stage: Int?) -> String {
        guard let plot, let stage else { return "Bed \(i + 1), empty" }
        if stage >= GardenSave.ripeStage { return "Bed \(i + 1): \(plot.kind.title), ready to pick" }
        let left = garden.daysLeft(i, today: today) ?? 0
        return "Bed \(i + 1): \(plot.kind.title), growing. Ready in \(left) day\(left == 1 ? "" : "s"), sooner with water"
    }

    private func bedButton(_ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title).font(.kid(13, .black)).foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 8).frame(maxWidth: .infinity, minHeight: 44)
                .background(Capsule().fill(color))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func seedPicker(_ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What should grow in bed \(i + 1)?").font(.kid(16, .black)).foregroundStyle(Palette.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(PlantKind.allCases) { k in
                    Button {
                        Haptics.tap(.pop)
                        choosingBed = nil
                        onPlant(i, k)
                    } label: {
                        VStack(spacing: 2) {
                            Text(k.emoji).font(.system(size: 28))
                            Text(k.title).font(.kid(12, .black)).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0xDDF7E5)))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Plant a \(k.title)")
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xFFF8EC)))
    }

    private var pets: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your pet").font(.kid(18, .black)).foregroundStyle(Palette.ink)
            Text("Your pet walks with your buddy around the village. Tap it to say hi!")
                .font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(PetKind.allCases) { k in
                    let open = garden.isUnlocked(k)
                    let on = garden.pet == k
                    Button {
                        guard open else {
                            Haptics.bump(.oops)
                            Narrator.shared.say("\(k.howToGet ?? "") to get \(k.name) the \(k.title.lowercased())!")
                            return
                        }
                        Haptics.tap(.pop)
                        onPet(on ? nil : k)
                    } label: {
                        VStack(spacing: 2) {
                            Text(open ? k.emoji : "🔒").font(.system(size: 28))
                            Text(open ? k.name : k.title).font(.kid(12, .black)).foregroundStyle(Palette.ink)
                            if !open, let how = k.howToGet {
                                Text(how).font(.kid(10, .bold)).foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 74)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 14).fill(on ? Color(hex: 0xDDF7E5) : Color(hex: 0xF3F1FA)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Palette.green : .clear, lineWidth: 3))
                        .opacity(open ? 1 : 0.6)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel(open ? "\(k.name) the \(k.title.lowercased())\(on ? ", walking with you. Tap to leave at home" : "")"
                                             : "\(k.title), locked. \(k.howToGet ?? "")")
                }
            }
        }
    }
}
