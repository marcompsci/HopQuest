import SwiftUI

// Star Hop's drawings, shared by the home-screen widget and the in-app Star Hop (v7.4).

/// HopQuest's ink color.
let hopInk = Color(hop: 0x2B1B3D)

extension Color {
    init(hop hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// The level's sky, behind the whole widget.
struct HopSky: View {
    let level: HopLevel
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hop: level.skyTop), Color(hop: level.skyBottom)], startPoint: .top, endPoint: .bottom)
            if level.night {
                // a few twinkles and a moon
                GeometryReader { geo in
                    ForEach(0..<9, id: \.self) { i in
                        Circle().fill(.white.opacity(i % 3 == 0 ? 0.9 : 0.55))
                            .frame(width: i % 3 == 0 ? 3 : 2, height: i % 3 == 0 ? 3 : 2)
                            .position(x: geo.size.width * CGFloat((i * 37 + 11) % 100) / 100,
                                      y: geo.size.height * CGFloat((i * 53 + 7) % 60) / 100)
                    }
                    Image(systemName: "moon.fill").font(.system(size: 18)).foregroundStyle(Color(hop: 0xFFF1B8))
                        .position(x: geo.size.width - 22, y: 20)
                }
            }
        }
    }
}

/// A shiny soap bubble: the shield pickup, and the shield around the buddy.
struct Bubble: View {
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.white.opacity(0.05), Color(hop: 0x9FDFFF).opacity(0.45)],
                                         center: .center, startRadius: 0, endRadius: 30))
            Circle().stroke(LinearGradient(colors: [Color(hop: 0xFF9DE2), Color(hop: 0x7FD6FF), Color(hop: 0xB6F5A8)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            GeometryReader { g in
                Capsule().fill(.white.opacity(0.9))
                    .frame(width: g.size.width * 0.18, height: g.size.width * 0.32)
                    .rotationEffect(.degrees(35))
                    .position(x: g.size.width * 0.3, y: g.size.height * 0.3)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A red spring pad set into the ground.
struct SpringPad: View {
    let squashed: Bool
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, hgt = g.size.height
            VStack(spacing: 0) {
                Capsule().fill(Color(hop: 0xFF5A5F)).frame(width: w, height: hgt * 0.32)
                    .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 1))
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule().stroke(Color(hop: 0x6B6F80), lineWidth: 1.6)
                            .frame(width: w * 0.55, height: hgt * 0.16)
                            .offset(y: CGFloat(i - 1) * hgt * (squashed ? 0.08 : 0.16))
                    }
                }
                .frame(height: hgt * 0.68)
            }
            .frame(width: w, height: hgt, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// A friendly puff cloud with sleepy eyes.
struct PuffCloud: View {
    let night: Bool
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Image(systemName: "cloud.fill").resizable().scaledToFit()
                    .foregroundStyle(night ? Color(hop: 0xC9C3E6) : .white)
                    .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 2)
                HStack(spacing: w * 0.14) {
                    Capsule().fill(hopInk).frame(width: w * 0.07, height: w * 0.1)
                    Capsule().fill(hopInk).frame(width: w * 0.07, height: w * 0.1)
                }
                .offset(y: w * 0.06)
                Capsule().fill(Color(hop: 0xFF9DB3).opacity(0.7)).frame(width: w * 0.1, height: w * 0.05)
                    .offset(x: -w * 0.2, y: w * 0.13)
                Capsule().fill(Color(hop: 0xFF9DB3).opacity(0.7)).frame(width: w * 0.1, height: w * 0.05)
                    .offset(x: w * 0.2, y: w * 0.13)
            }
            .frame(width: w, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }
}

