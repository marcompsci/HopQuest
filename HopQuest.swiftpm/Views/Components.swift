import SwiftUI
import UIKit

// MARK: - Colors

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

enum Palette {
    static let purple = Color(hex: 0x7C4DFF)
    static let ink = Color(hex: 0x2B1B3D)
    static let green = Color(hex: 0x34C77B)
    static let red = Color(hex: 0xFF5A5F)
}

extension Font {
    /// HopQuest's rounded font. It grows with the iPhone's Text Size setting (up to a quarter bigger,
    /// so screens built for small phones still fit).
    static func kid(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: KidType.scaled(size), weight: weight, design: .rounded)
    }
}

/// Text sizes that follow the iPhone's Text Size setting, capped so layouts keep fitting.
enum KidType {
    static let maxGrowth: CGFloat = 1.25

    static func scaled(_ size: CGFloat) -> CGFloat {
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: size)
        return min(max(scaled, size), size * maxGrowth)
    }
}

/// Grown-ups' "Left-handed controls": joysticks and arrows on the right, action buttons on the left.
enum Handedness {
    static let key = "hopquest.lefthanded"
}

/// iPad (v3.8): HopQuest's screens are made for a tall phone, so on an iPad the game sits in a tall play area
/// in the middle (in portrait or landscape) with a soft backdrop around it. Every game then plays exactly as it
/// does on a phone, just bigger. On iPhone this does nothing.
struct TabletFrame: ViewModifier {
    var sky: [Color]
    /// Height / width of the play area (phones are about 2.1; a little squarer uses more of the iPad).
    static let aspect: CGFloat = 1.6

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    func body(content: Content) -> some View {
        if isPad {
            GeometryReader { geo in
                let fullHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                let width = min(geo.size.width, fullHeight / Self.aspect)
                ZStack {
                    if width < geo.size.width - 1 {
                        TabletBackdrop(sky: sky).ignoresSafeArea()
                    }
                    content
                        .frame(width: width)
                        .mask { Rectangle().ignoresSafeArea() }
                        .shadow(color: .black.opacity(width < geo.size.width - 1 ? 0.25 : 0), radius: 18)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        } else {
            content
        }
    }
}

/// The soft sky around the play area on an iPad.
private struct TabletBackdrop: View {
    var sky: [Color]
    var body: some View {
        ZStack {
            LinearGradient(colors: sky, startPoint: .top, endPoint: .bottom)
            Color.white.opacity(0.25)
            GeometryReader { geo in
                ForEach(0..<8, id: \.self) { i in
                    Text(["☁️", "⭐", "🎈", "☁️", "🌼", "⭐", "☁️", "🎈"][i])
                        .font(.system(size: 54))
                        .opacity(0.35)
                        .position(x: geo.size.width * (i % 2 == 0 ? 0.08 : 0.92),
                                  y: geo.size.height * (0.1 + CGFloat(i) * 0.11))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Haptics

/// Haptics plus a matching sound. Pass a different `Sfx` (or nil for silence) where it fits better.
enum Haptics {
    static func tap(_ sound: Sfx? = .tap) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let sound { SoundFX.shared.play(sound) }
    }
    static func bump(_ sound: Sfx? = .boing) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if let sound { SoundFX.shared.play(sound) }
    }
    static func success(_ sound: Sfx? = .chime) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if let sound { SoundFX.shared.play(sound) }
    }
}

// MARK: - Buttons

/// Every tappable card and button: it sinks the instant a finger lands (on touch-down, not on release),
/// then settles back without wobbling. A small press (96%) reads as physical; a big wobble reads as a toy.
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressedLabel(configuration: configuration)
    }

    private struct PressedLabel: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
                .brightness(configuration.isPressed ? -0.03 : 0)
                .animation(configuration.isPressed ? Motion.press : Motion.release, value: configuration.isPressed)
        }
    }
}

struct BigButton: View {
    let title: String
    var color: Color = Palette.purple
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(.kid(22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(color)
                        .shadow(color: color.opacity(0.45), radius: 0, x: 0, y: 6)
                )
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// A button that reports press/release — used for GO and BRAKE pedals.
struct HoldButton: View {
    let title: String
    let color: Color
    var onChange: (Bool) -> Void
    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.kid(20, .black))
            .foregroundStyle(.white)
            .frame(width: 92, height: 92)
            .background(Circle().fill(color).shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: pressed ? 2 : 6))
            .scaleEffect(pressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            Haptics.tap()
                            onChange(true)
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        onChange(false)
                    }
            )
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
    }
}

struct CircleIconButton: View {
    let systemName: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.white.opacity(0.92)))
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }
}

/// Small 🔊 button that reads something again.
struct SpeakButton: View {
    var label = "Read it again"
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.purple)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(hex: 0xF3ECFF)))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct CapeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.25, y: 0))
        p.addLine(to: CGPoint(x: rect.width * 0.75, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 0.85))
        p.closeSubpath()
        return p
    }
}

struct Shake: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}

// MARK: - Characters

struct BunnyView: View {
    let size: CGFloat
    private let body1 = Color(hex: 0x9B6BDF)
    private let light = Color(hex: 0xD9C2FF)
    private let pink = Color(hex: 0xFF9ECF)

    var body: some View {
        ZStack {
            ear.rotationEffect(.degrees(-12)).offset(x: -size * 0.15, y: -size * 0.36)
            ear.rotationEffect(.degrees(12)).offset(x: size * 0.15, y: -size * 0.36)
            Circle()
                .fill(body1)
                .overlay(Circle().stroke(.white, lineWidth: size * 0.04))
                .frame(width: size * 0.74, height: size * 0.74)
                .offset(y: size * 0.04)
            HStack(spacing: size * 0.2) { eye; eye }
                .offset(y: -size * 0.01)
            HStack(spacing: size * 0.32) {
                Circle().fill(pink.opacity(0.55)).frame(width: size * 0.1)
                Circle().fill(pink.opacity(0.55)).frame(width: size * 0.1)
            }
            .offset(y: size * 0.12)
            Ellipse().fill(pink).frame(width: size * 0.1, height: size * 0.07).offset(y: size * 0.1)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var ear: some View {
        Capsule()
            .fill(body1)
            .overlay(Capsule().fill(light).padding(size * 0.05))
            .overlay(Capsule().stroke(.white, lineWidth: size * 0.03))
            .frame(width: size * 0.2, height: size * 0.46)
    }

    private var eye: some View {
        Circle()
            .fill(Palette.ink)
            .frame(width: size * 0.11)
            .overlay(Circle().fill(.white).frame(width: size * 0.035).offset(x: size * 0.02, y: -size * 0.02))
    }
}

/// Loads any illustrated image from the asset catalog by name (cached).
enum ArtLibrary {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        let img = UIImage(named: name, in: .module, with: nil) ?? UIImage(named: name)
        if let img { cache[name] = img }
        return img
    }
}

/// SwiftUI view for an illustrated asset; shows nothing if the art is missing.
struct ArtImage: View {
    let name: String
    init(_ name: String) { self.name = name }

    var body: some View {
        if let img = ArtLibrary.image(name) {
            Image(uiImage: img).resizable().interpolation(.high).scaledToFit()
        } else {
            Color.clear
        }
    }
}

/// Loads the illustrated character art from the asset catalog (Assets.xcassets/char_<id>).
enum CharacterArt {
    private static var cache: [String: UIImage] = [:]

    static func image(_ character: GameCharacter) -> UIImage? {
        let name = "char_\(character.id)"
        if let hit = cache[name] { return hit }
        let img = UIImage(named: name, in: .module, with: nil) ?? UIImage(named: name)
        if let img { cache[name] = img }
        return img
    }
}

/// A character shown full-body. The art is a bit taller than wide (420 x 460),
/// so the view is `size` wide and ~1.1 x `size` tall.
struct CharacterBadge: View {
    let character: GameCharacter
    var size: CGFloat = 64
    /// Gentle idle bounce, for big hero shots.
    var animated: Bool = false

    @State private var bounce = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if let img = CharacterArt.image(character) {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size * 1.1)
                    .scaleEffect(x: bounce ? 0.97 : 1, y: bounce ? 1.04 : 1, anchor: .bottom)
            } else {
                // Fallback if the art is missing.
                Circle()
                    .fill(character.color)
                    .overlay(Circle().stroke(.white, lineWidth: max(2, size * 0.05)))
                    .frame(width: size * 0.84, height: size * 0.84)
                    .overlay(Text(character.emoji).font(.system(size: size * 0.5)))
                    .frame(width: size, height: size * 1.1)
            }
        }
        .frame(width: size, height: size * 1.1)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { bounce = true }
        }
        .accessibilityElement()
        .accessibilityLabel(character.name)
    }
}

// MARK: - Castle, clouds, balloon

struct CastleView: View {
    let theme: CastleTheme
    var width: CGFloat = 160

    var body: some View {
        // illustrated castle (ArtSource/make_world.py); canvas is 460 x 480 with the ground near the bottom
        ArtImage("castle_\(theme.rawValue)")
            .frame(width: width * 1.15, height: width * 1.2)
            .frame(width: width, height: width * 1.05, alignment: .bottom)
            .accessibilityLabel(theme.title)
    }
}

struct CloudView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Circle().frame(width: h * 0.9).offset(x: -w * 0.22, y: h * 0.1)
                Circle().frame(width: h * 1.1).offset(x: 0, y: -h * 0.05)
                Circle().frame(width: h * 0.85).offset(x: w * 0.24, y: h * 0.12)
                Capsule().frame(width: w * 0.9, height: h * 0.5).offset(y: h * 0.25)
            }
            .frame(width: w, height: h)
            .foregroundStyle(.white.opacity(0.92))
        }
        .accessibilityHidden(true)
    }
}

struct BalloonView: View {
    let theme: CastleTheme
    let character: GameCharacter
    var size: CGFloat = 120

    var body: some View {
        let w = size * 1.16
        let h = w * 380 / 220
        let rider = w * 0.34
        ZStack {
            ArtImage("balloon_\(theme.rawValue)")
            CharacterBadge(character: character, size: rider)
                .position(x: w / 2, y: h * 340 / 380 - rider * 0.5)
            ArtImage("balloon_front")
        }
        .frame(width: w, height: h)
        .accessibilityElement()
        .accessibilityLabel("\(character.name) in a hot air balloon")
    }
}

// MARK: - HUD pieces

struct GameTopBar: View {
    var onExit: () -> Void
    var progress: Double
    var stars: Int
    var extra: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "house.fill", label: "Back to map", action: onExit)
            ProgressView(value: min(max(progress, 0), 1))
                .tint(Color(hex: 0xFF7FC4))
                .scaleEffect(x: 1, y: 2.2)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Capsule().fill(.white.opacity(0.9)))
                .accessibilityLabel("Progress")
            pill("⭐ \(stars)")
            if let extra { pill(extra) }
        }
        .padding(.horizontal, 14)
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.kid(17))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Capsule().fill(.white.opacity(0.92)))
    }
}

struct MessageBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.kid(18, .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
    }
}
