import SwiftUI

// MARK: - Pedals

/// A car pedal. Gas is tall and narrow; brake is wider and shorter — like a real car.
/// Pressing tilts the pedal down; `onChange` reports 0...1.
struct Pedal: View {
    enum Kind { case gas, brake }
    let kind: Kind
    var compact: Bool = false
    var onChange: (CGFloat) -> Void

    @State private var pressed = false

    private var size: CGSize {
        let s: CGFloat = compact ? 0.8 : 1
        return kind == .gas ? CGSize(width: 66 * s, height: 128 * s) : CGSize(width: 96 * s, height: 92 * s)
    }

    private var accent: Color {
        kind == .gas ? Palette.green : Palette.red
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // metal frame
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0xE4E7EE), Color(hex: 0x9AA0AE)],
                                         startPoint: .top, endPoint: .bottom))
                // rubber pad with grip ridges
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x3A3D47), Color(hex: 0x23252C)],
                                         startPoint: .top, endPoint: .bottom))
                    .padding(6)
                VStack(spacing: size.height * (kind == .gas ? 0.065 : 0.08)) {
                    ForEach(0..<(kind == .gas ? 9 : 6), id: \.self) { _ in
                        Capsule()
                            .fill(Color.white.opacity(0.13))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 16)
                // colored stripe so kids can tell them apart at a glance
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(height: 6)
                    .padding(.horizontal, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 10)
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: .black.opacity(pressed ? 0.15 : 0.35), radius: pressed ? 2 : 6, x: 0, y: pressed ? 1 : 6)
            .rotation3DEffect(.degrees(pressed ? 24 : 0), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
            .scaleEffect(pressed ? 0.95 : 1, anchor: .bottom)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            Haptics.tap()
                            onChange(1)
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        onChange(0)
                    }
            )

            Text(kind == .gas ? "GAS" : "BRAKE")
                .font(.kid(13, .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(Capsule().fill(accent))
        }
        .accessibilityElement()
        .accessibilityLabel(kind == .gas ? "Gas pedal" : "Brake pedal")
        .accessibilityHint("Press and hold")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Steering wheel

/// Drag around the wheel to turn it. Lets go and it springs back to center.
/// Reports -1 (full left) ... 1 (full right).
struct SteeringWheel: View {
    var diameter: CGFloat = 150
    var onChange: (CGFloat) -> Void

    @State private var angle: Double = 0          // degrees, clamped to ±120
    @State private var startAngle: Double?
    @State private var startTouchAngle: Double = 0
    private let maxAngle: Double = 120

    var body: some View {
        wheelArt
            .rotationEffect(.degrees(angle))
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .gesture(drag)
            .accessibilityElement()
            .accessibilityLabel("Steering wheel")
            .accessibilityAdjustableAction { dir in
                let step: CGFloat = dir == .increment ? 0.5 : -0.5
                onChange(step)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onChange(0) }
            }
    }

    private var wheelArt: some View {
        ZStack {
            // rim
            Circle()
                .stroke(LinearGradient(colors: [Color(hex: 0x4A4E5A), Color(hex: 0x1E2027)], startPoint: .top, endPoint: .bottom),
                        lineWidth: diameter * 0.13)
            // grip bumps
            ForEach(0..<16, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: diameter * 0.03, height: diameter * 0.09)
                    .offset(y: -diameter * 0.435)
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
            // spokes
            ForEach([90.0, 210.0, 330.0], id: \.self) { a in
                Capsule()
                    .fill(Color(hex: 0x2F323B))
                    .frame(width: diameter * 0.1, height: diameter * 0.42)
                    .offset(y: diameter * 0.2)
                    .rotationEffect(.degrees(a - 90))
            }
            // hub
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x7C4DFF), Color(hex: 0x4B2BB8)], center: .topLeading,
                                     startRadius: 2, endRadius: diameter * 0.2))
                .frame(width: diameter * 0.32, height: diameter * 0.32)
                .overlay(Text("⭐").font(.system(size: diameter * 0.13)))
            // top marker so you can see how far it's turned
            Capsule()
                .fill(Color(hex: 0xFFD93D))
                .frame(width: diameter * 0.06, height: diameter * 0.12)
                .offset(y: -diameter * 0.435)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 5)
    }

    private var drag: some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let c = CGPoint(x: diameter / 2, y: diameter / 2)
                    let touch = atan2(value.location.y - c.y, value.location.x - c.x) * 180 / .pi
                    if startAngle == nil {
                        startAngle = angle
                        startTouchAngle = touch
                    }
                    var delta = touch - startTouchAngle
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    let next = max(-maxAngle, min(maxAngle, (startAngle ?? 0) + delta))
                    angle = next
                    // keep tracking smoothly past the ±180 seam
                    startTouchAngle = touch
                    startAngle = next
                    onChange(CGFloat(next / maxAngle))
                }
                .onEnded { _ in
                    startAngle = nil
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { angle = 0 }
                    onChange(0)
                }
    }
}

// MARK: - Blinkers

struct BlinkerButton: View {
    let dir: Int          // -1 left, 1 right
    @Binding var blinker: Int
    @State private var flash = false

    private var on: Bool { blinker == dir }

    var body: some View {
        Button {
            Haptics.tap()
            blinker = on ? 0 : dir
        } label: {
            Image(systemName: dir < 0 ? "arrowshape.left.fill" : "arrowshape.right.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(on && flash ? Color(hex: 0x2B1B3D) : (on ? Color(hex: 0xFFA41B) : Color(hex: 0x7A7F8C)))
                .frame(width: 56, height: 44)
                .background(RoundedRectangle(cornerRadius: 14).fill(on && flash ? Color(hex: 0xFFA41B) : .white.opacity(0.92)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Color(hex: 0xFFA41B) : .clear, lineWidth: 3))
        }
        .buttonStyle(BouncyButtonStyle())
        .onReceive(Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()) { _ in
            flash = on ? !flash : false
        }
        .accessibilityLabel(dir < 0 ? "Left blinker" : "Right blinker")
        .accessibilityValue(on ? "On" : "Off")
    }
}

// MARK: - Speedometer dial

struct SpeedDial: View {
    let mph: Int
    var limit: Int?
    var maxMph: Double = 60
    var size: CGFloat = 96

    private var over: Bool {
        if let limit { return mph > limit + 5 }
        return false
    }

    var body: some View {
        let frac = min(Double(mph) / maxMph, 1)
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x3A3D47), Color(hex: 0x1E2027)], center: .center,
                                     startRadius: 2, endRadius: size * 0.6))
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 3)
                .padding(2)
            // arc track from -135° to +135°
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
                .rotationEffect(.degrees(135))
                .padding(size * 0.12)
            Circle()
                .trim(from: 0, to: 0.75 * frac)
                .stroke(AngularGradient(colors: [Palette.green, Color(hex: 0xFFD93D), Palette.red], center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
                .rotationEffect(.degrees(135))
                .padding(size * 0.12)
            // limit tick
            if let limit {
                Capsule()
                    .fill(Color(hex: 0xFFD93D))
                    .frame(width: 4, height: size * 0.14)
                    .offset(y: -size * 0.38)
                    .rotationEffect(.degrees(-135 + 270 * min(Double(limit) / maxMph, 1)))
            }
            // needle
            Capsule()
                .fill(over ? Palette.red : Color(hex: 0xFF7A59))
                .frame(width: 4, height: size * 0.34)
                .offset(y: -size * 0.17)
                .rotationEffect(.degrees(-135 + 270 * frac))
                .animation(.interpolatingSpring(stiffness: 120, damping: 14), value: mph)
            Circle().fill(Color.white).frame(width: size * 0.1, height: size * 0.1)
            VStack(spacing: -2) {
                Text("\(mph)")
                    .font(.kid(size * 0.2, .black))
                    .foregroundStyle(over ? Palette.red : .white)
                    .contentTransition(.numericText())
                Text("MPH").font(.kid(size * 0.09, .bold)).foregroundStyle(.white.opacity(0.7))
            }
            .offset(y: size * 0.24)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
        .accessibilityElement()
        .accessibilityLabel("Speed \(mph) miles per hour")
    }
}

/// Little road strip that shows how far you are from the finish.
struct RoadProgress: View {
    let progress: Double
    let character: GameCharacter

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x4A505E))
                Capsule()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(height: 0.5)
                    .padding(.horizontal, 10)
                Text("🏁").font(.system(size: 16)).frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 4)
                CharacterBadge(character: character, size: 26)
                    .offset(x: (g.size.width - 32) * min(max(progress, 0), 1), y: -4)
                    .animation(.linear(duration: 0.2), value: progress)
            }
        }
        .frame(height: 30)
        .accessibilityElement()
        .accessibilityLabel("Trip progress \(Int(progress * 100)) percent")
    }
}

/// Gold coin icon matching the in-game coins.
struct CoinIcon: View {
    var size: CGFloat = 20
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xE09B12))
            Circle().fill(Color(hex: 0xFFD447)).padding(size * 0.1)
            Image(systemName: "star.fill").font(.system(size: size * 0.45, weight: .black)).foregroundStyle(Color(hex: 0xFFF3B0))
        }
        .frame(width: size, height: size)
    }
}
