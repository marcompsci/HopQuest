import SwiftUI

/// Drag-to-walk stick. Reports a vector with dx right, dy down, length 0...1.
struct VillageJoystick: View {
    var onChange: (CGVector) -> Void
    @State private var knob: CGSize = .zero
    private let radius: CGFloat = 54
    private var box: CGFloat { radius * 2 + 24 }

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.22))
                .overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 3))
                .frame(width: radius * 2, height: radius * 2)
            Image(systemName: "chevron.compact.up").offset(y: -radius + 14)
            Image(systemName: "chevron.compact.down").offset(y: radius - 14)
            Image(systemName: "chevron.compact.left").offset(x: -radius + 14)
            Image(systemName: "chevron.compact.right").offset(x: radius - 14)
            Circle()
                .fill(.white)
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(Palette.ink.opacity(0.15), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                .offset(knob)
        }
        .font(.system(size: 18, weight: .heavy))
        .foregroundStyle(.white.opacity(0.85))
        .frame(width: box, height: box)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = value.location.x - box / 2
                    let dy = value.location.y - box / 2
                    let len = max(1, hypot(dx, dy))
                    let k = min(1, radius / len)
                    knob = CGSize(width: dx * k, height: dy * k)
                    onChange(CGVector(dx: knob.width / radius, dy: knob.height / radius))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { knob = .zero }
                    onChange(.zero)
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Walking stick")
        .accessibilityHint("Drag to walk. You can also tap anywhere in the village to walk there.")
    }
}

/// The big round button: talk, go in, hop into a portal — or just hop for fun.
struct VillageActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .black))
                Text(title)
                    .font(.kid(14, .black))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .frame(width: 104, height: 104)
            .background(Circle().fill(color).shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 5))
            .overlay(Circle().stroke(.white, lineWidth: 4))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(title)
    }
}

/// Top bar: back to the map, your buddy, your stars, and the grown-ups' gear.
struct VillageTopBar: View {
    let character: GameCharacter
    let stars: Int
    var onMap: () -> Void
    var onBuddy: () -> Void
    var onParent: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onMap) {
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .font(.kid(16, .black))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Capsule().fill(.white.opacity(0.92)))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Back to the world map")

            Button(action: onBuddy) {
                CharacterBadge(character: character, size: 44)
                    .background(Circle().fill(.white.opacity(0.92)))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Change your buddy")

            Spacer()

            HStack(spacing: 4) {
                ArtImage("goal_star").frame(width: 22, height: 22)
                Text("\(stars)")
            }
            .font(.kid(18, .black))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Capsule().fill(.white.opacity(0.92)))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(stars) stars")

            CircleIconButton(systemName: "gearshape.fill", label: "Grown-ups", action: onParent)
        }
        .padding(.horizontal, 14)
    }
}

/// The place name that slides in as you walk into a new part of the village.
struct VillageRegionBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.kid(20, .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Capsule().fill(Palette.purple.opacity(0.92)).shadow(color: Color(hex: 0x5B32D6), radius: 0, x: 0, y: 4))
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityAddTraits(.isHeader)
    }
}
