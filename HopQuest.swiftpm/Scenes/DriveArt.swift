import SpriteKit
import UIKit

/// Painted textures for the driving levels (road, cars, trees, houses, coins, glows).
/// Drawn once with Core Graphics and cached, so the scene stays fast and smooth.
enum DriveArt {

    enum CarKind: String {
        case car, van, bus

        /// Design size in points (front of the vehicle at the top).
        var design: CGSize {
            switch self {
            case .car: return CGSize(width: 64, height: 116)
            case .van: return CGSize(width: 66, height: 128)
            case .bus: return CGSize(width: 70, height: 196)
            }
        }
    }

    private static var cache: [String: SKTexture] = [:]

    private static func texture(_ key: String, size: CGSize, draw: (CGContext, CGSize) -> Void) -> SKTexture {
        if let t = cache[key] { return t }
        let image = UIGraphicsImageRenderer(size: size).image { ctx in draw(ctx.cgContext, size) }
        let t = SKTexture(image: image)
        t.filteringMode = .linear
        cache[key] = t
        return t
    }

    private static func hex(_ c: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private static func blend(_ c: UIColor, with other: UIColor, _ t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: 1)
    }

    // MARK: Road

    /// One repeating piece of road: grass, sidewalks, curbs, asphalt, edge lines and lane dashes.
    /// Height is a multiple of the 100-pt dash period so pieces line up seamlessly.
    static func roadSegment(width: CGFloat, height: CGFloat, roadLeft: CGFloat, roadWidth: CGFloat, lanes: Int) -> SKTexture {
        let key = "road-\(Int(width))-\(Int(height))-\(Int(roadLeft))-\(lanes)"
        return texture(key, size: CGSize(width: width, height: height)) { ctx, size in
            var rng = SeededRandom(seed: 42)

            // grass with mowing stripes
            for i in 0..<Int(size.height / 50) + 1 {
                UIColor(hex: i % 2 == 0 ? 0x8FD86E : 0x86D065).setFill()
                ctx.fill(CGRect(x: 0, y: CGFloat(i) * 50, width: size.width, height: 50))
            }
            for _ in 0..<40 {
                let x = rng.next(0, size.width), y = rng.next(0, size.height)
                UIColor(hex: 0x6FBF4F, alpha: 0.6).setFill()
                ctx.fill(CGRect(x: x, y: y, width: 2, height: 5))
            }

            let roadRight = roadLeft + roadWidth
            let curbW: CGFloat = 5
            let walkW: CGFloat = max(8, min(22, roadLeft - curbW - 6))

            // sidewalks with tile seams
            for side in [0, 1] {
                let x = side == 0 ? roadLeft - curbW - walkW : roadRight + curbW
                UIColor(hex: 0xD9DCE3).setFill()
                ctx.fill(CGRect(x: x, y: 0, width: walkW, height: size.height))
                UIColor(hex: 0xB9BDC8).setFill()
                var y: CGFloat = 0
                while y < size.height {
                    ctx.fill(CGRect(x: x, y: y, width: walkW, height: 1.5))
                    y += 26
                }
                // curb
                UIColor(hex: 0xF2F3F6).setFill()
                ctx.fill(CGRect(x: side == 0 ? roadLeft - curbW : roadRight, y: 0, width: curbW, height: size.height))
            }

            // asphalt with a little texture
            UIColor(hex: 0x4A505E).setFill()
            ctx.fill(CGRect(x: roadLeft, y: 0, width: roadWidth, height: size.height))
            for _ in 0..<Int(roadWidth * size.height / 900) {
                let x = rng.next(roadLeft, roadRight), y = rng.next(0, size.height)
                let s = rng.next(1, 2.6)
                UIColor(white: rng.next(0, 1) > 0.5 ? 1 : 0, alpha: 0.07).setFill()
                ctx.fill(CGRect(x: x, y: y, width: s, height: s))
            }
            // a couple of tar seams
            UIColor(hex: 0x3B404C, alpha: 0.8).setStroke()
            ctx.setLineWidth(1.5)
            for _ in 0..<3 {
                let x = rng.next(roadLeft + 20, roadRight - 20), y = rng.next(0, size.height - 60)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addCurve(to: CGPoint(x: x + rng.next(-20, 20), y: y + 50),
                             control1: CGPoint(x: x + 14, y: y + 14), control2: CGPoint(x: x - 12, y: y + 30))
                ctx.strokePath()
            }

            // solid edge lines
            UIColor(white: 1, alpha: 0.9).setFill()
            ctx.fill(CGRect(x: roadLeft + 6, y: 0, width: 4, height: size.height))
            ctx.fill(CGRect(x: roadRight - 10, y: 0, width: 4, height: size.height))

            // lane dashes (period 100)
            let laneW = roadWidth / CGFloat(lanes)
            for k in 1..<lanes {
                let x = roadLeft + laneW * CGFloat(k) - 2.5
                var y: CGFloat = 0
                while y < size.height {
                    let dash = UIBezierPath(roundedRect: CGRect(x: x, y: y + 30, width: 5, height: 40), cornerRadius: 2)
                    UIColor(white: 1, alpha: 0.85).setFill()
                    dash.fill()
                    y += 100
                }
            }
        }
    }

    // MARK: Vehicles

    static func vehicle(_ kind: CarKind, color: UIColor) -> SKTexture {
        let d = kind.design
        let pad: CGFloat = 8
        let size = CGSize(width: d.width + pad * 2, height: d.height + pad * 2)
        return texture("veh-\(kind.rawValue)-\(hex(color))", size: size) { ctx, _ in
            let body = CGRect(x: pad, y: pad, width: d.width, height: d.height)
            let w = body.width, h = body.height
            let tire = UIColor(hex: 0x23232B)

            // tires peeking out
            tire.setFill()
            let tireH: CGFloat = kind == .bus ? 26 : 22
            for (fx, fy) in [(0.0, 0.16), (1.0, 0.16), (0.0, 0.76), (1.0, 0.76)] as [(CGFloat, CGFloat)] {
                let r = CGRect(x: body.minX + fx * w - (fx == 0 ? 3 : 7), y: body.minY + fy * h, width: 10, height: tireH)
                UIBezierPath(roundedRect: r, cornerRadius: 3).fill()
            }

            let radius: CGFloat = kind == .bus ? 12 : w * 0.34
            let shape = UIBezierPath(roundedRect: body, cornerRadius: radius)

            // soft drop shadow + paint
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 2, height: 5), blur: 6, color: UIColor(white: 0, alpha: 0.38).cgColor)
            color.setFill()
            shape.fill()
            ctx.restoreGState()

            // rounded body shading: dark edges, bright center
            ctx.saveGState()
            shape.addClip()
            let colors = [UIColor(white: 0, alpha: 0.28), UIColor(white: 0, alpha: 0), UIColor(white: 1, alpha: 0.22),
                          UIColor(white: 0, alpha: 0), UIColor(white: 0, alpha: 0.28)].map { $0.cgColor } as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.22, 0.5, 0.78, 1]) {
                ctx.drawLinearGradient(g, start: CGPoint(x: body.minX, y: 0), end: CGPoint(x: body.maxX, y: 0), options: [])
            }
            ctx.restoreGState()

            UIColor(white: 0, alpha: 0.35).setStroke()
            shape.lineWidth = 1.5
            shape.stroke()

            let glassTop = UIColor(hex: 0x24325C), glassBottom = UIColor(hex: 0x6F94D6)

            func glass(_ path: UIBezierPath, flip: Bool = false) {
                ctx.saveGState()
                path.addClip()
                let cs = [glassTop.cgColor, glassBottom.cgColor] as CFArray
                if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cs, locations: [0, 1]) {
                    let b = path.bounds
                    ctx.drawLinearGradient(g, start: CGPoint(x: b.minX, y: flip ? b.maxY : b.minY),
                                           end: CGPoint(x: b.maxX, y: flip ? b.minY : b.maxY), options: [])
                }
                // reflection
                UIColor(white: 1, alpha: 0.28).setFill()
                let b = path.bounds
                let refl = UIBezierPath()
                refl.move(to: CGPoint(x: b.minX + b.width * 0.15, y: b.maxY))
                refl.addLine(to: CGPoint(x: b.minX + b.width * 0.35, y: b.minY))
                refl.addLine(to: CGPoint(x: b.minX + b.width * 0.5, y: b.minY))
                refl.addLine(to: CGPoint(x: b.minX + b.width * 0.3, y: b.maxY))
                refl.close()
                refl.fill()
                ctx.restoreGState()
            }

            func trapezoid(top: CGFloat, bottom: CGFloat, topInset: CGFloat, bottomInset: CGFloat) -> UIBezierPath {
                let p = UIBezierPath()
                p.move(to: CGPoint(x: body.minX + topInset, y: body.minY + top))
                p.addLine(to: CGPoint(x: body.maxX - topInset, y: body.minY + top))
                p.addLine(to: CGPoint(x: body.maxX - bottomInset, y: body.minY + bottom))
                p.addLine(to: CGPoint(x: body.minX + bottomInset, y: body.minY + bottom))
                p.close()
                return p
            }

            switch kind {
            case .car, .van:
                let vanShift: CGFloat = kind == .van ? -0.08 : 0
                // hood crease
                UIColor(white: 1, alpha: 0.18).setStroke()
                ctx.setLineWidth(1.2)
                ctx.move(to: CGPoint(x: body.midX - w * 0.14, y: body.minY + h * 0.06))
                ctx.addLine(to: CGPoint(x: body.midX - w * 0.1, y: body.minY + h * (0.22 + vanShift)))
                ctx.move(to: CGPoint(x: body.midX + w * 0.14, y: body.minY + h * 0.06))
                ctx.addLine(to: CGPoint(x: body.midX + w * 0.1, y: body.minY + h * (0.22 + vanShift)))
                ctx.strokePath()
                // windshield
                glass(trapezoid(top: h * (0.24 + vanShift), bottom: h * (0.39 + vanShift), topInset: w * 0.17, bottomInset: w * 0.09))
                // roof
                let roof = CGRect(x: body.minX + w * 0.11, y: body.minY + h * (0.39 + vanShift),
                                  width: w * 0.78, height: h * (kind == .van ? 0.48 : 0.31))
                blend(color, with: .white, 0.14).setFill()
                UIBezierPath(roundedRect: roof, cornerRadius: 7).fill()
                UIColor(white: 0, alpha: 0.15).setStroke()
                UIBezierPath(roundedRect: roof, cornerRadius: 7).stroke()
                // rear window
                glass(trapezoid(top: h * (kind == .van ? 0.87 : 0.70), bottom: h * (kind == .van ? 0.93 : 0.82),
                                topInset: w * 0.1, bottomInset: w * 0.17), flip: true)
                // mirrors
                color.setFill()
                UIBezierPath(ovalIn: CGRect(x: body.minX - 5, y: body.minY + h * 0.3, width: 9, height: 6)).fill()
                UIBezierPath(ovalIn: CGRect(x: body.maxX - 4, y: body.minY + h * 0.3, width: 9, height: 6)).fill()

            case .bus:
                // roof hatches and side windows
                UIColor(hex: 0x2B1B3D, alpha: 0.85).setFill()
                for i in 0..<7 {
                    let y = body.minY + h * 0.18 + CGFloat(i) * h * 0.105
                    ctx.fill(CGRect(x: body.minX + 3, y: y, width: 7, height: h * 0.075))
                    ctx.fill(CGRect(x: body.maxX - 10, y: y, width: 7, height: h * 0.075))
                }
                glass(trapezoid(top: h * 0.04, bottom: h * 0.13, topInset: w * 0.12, bottomInset: w * 0.08))
                UIColor(white: 1, alpha: 0.35).setFill()
                ctx.fill(CGRect(x: body.minX + w * 0.32, y: body.minY + h * 0.3, width: w * 0.36, height: h * 0.1))
                ctx.fill(CGRect(x: body.minX + w * 0.32, y: body.minY + h * 0.62, width: w * 0.36, height: h * 0.1))
                UIColor(hex: 0x2B1B3D).setFill()
                ctx.fill(CGRect(x: body.minX, y: body.minY + h * 0.5, width: w, height: 3))
                let text = NSAttributedString(string: "SCHOOL", attributes: [
                    .font: UIFont.systemFont(ofSize: 10, weight: .black),
                    .foregroundColor: UIColor(hex: 0x2B1B3D)
                ])
                let ts = text.size()
                text.draw(at: CGPoint(x: body.midX - ts.width / 2, y: body.minY + h * 0.44 - ts.height / 2))
            }

            // headlights and tail lights
            UIColor(hex: 0xFFF6C2).setFill()
            UIBezierPath(roundedRect: CGRect(x: body.minX + 6, y: body.minY + 2, width: 12, height: 6), cornerRadius: 3).fill()
            UIBezierPath(roundedRect: CGRect(x: body.maxX - 18, y: body.minY + 2, width: 12, height: 6), cornerRadius: 3).fill()
            UIColor(hex: 0x9E1F1F).setFill()
            UIBezierPath(roundedRect: CGRect(x: body.minX + 6, y: body.maxY - 7, width: 11, height: 5), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: body.maxX - 17, y: body.maxY - 7, width: 11, height: 5), cornerRadius: 2).fill()
        }
    }

    /// Size of a vehicle sprite for a given body width (keeps the texture's proportions, including padding).
    static func vehicleSize(_ kind: CarKind, bodyWidth: CGFloat) -> CGSize {
        let d = kind.design
        let scale = bodyWidth / d.width
        return CGSize(width: (d.width + 16) * scale, height: (d.height + 16) * scale)
    }

    /// Soft round glow (for lights).
    static func glow(_ color: UIColor) -> SKTexture {
        texture("glow-\(hex(color))", size: CGSize(width: 64, height: 64)) { ctx, size in
            let cs = [color.withAlphaComponent(1).cgColor, color.withAlphaComponent(0.45).cgColor, color.withAlphaComponent(0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cs, locations: [0, 0.35, 1]) {
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
            }
        }
    }

    // MARK: Scenery

    static var tree: SKTexture {
        texture("tree", size: CGSize(width: 90, height: 90)) { ctx, _ in
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 4, height: 6), blur: 6, color: UIColor(white: 0, alpha: 0.3).cgColor)
            UIColor(hex: 0x2F8F46).setFill()
            for (x, y, r) in [(45.0, 45.0, 36.0), (30, 34, 22), (60, 36, 22), (36, 60, 22), (60, 58, 20)] as [(CGFloat, CGFloat, CGFloat)] {
                UIBezierPath(ovalIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)).fill()
            }
            ctx.restoreGState()
            UIColor(hex: 0x45AA5A).setFill()
            for (x, y, r) in [(38.0, 36.0, 18.0), (56, 42, 14), (44, 56, 13)] as [(CGFloat, CGFloat, CGFloat)] {
                UIBezierPath(ovalIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)).fill()
            }
            UIColor(hex: 0x7DD08A, alpha: 0.8).setFill()
            UIBezierPath(ovalIn: CGRect(x: 26, y: 24, width: 16, height: 11)).fill()
        }
    }

    static var bush: SKTexture {
        texture("bush", size: CGSize(width: 50, height: 40)) { ctx, _ in
            ctx.setShadow(offset: CGSize(width: 2, height: 4), blur: 4, color: UIColor(white: 0, alpha: 0.25).cgColor)
            UIColor(hex: 0x3FA34D).setFill()
            for (x, y, r) in [(16.0, 22.0, 12.0), (28, 16, 13), (36, 24, 11)] as [(CGFloat, CGFloat, CGFloat)] {
                UIBezierPath(ovalIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)).fill()
            }
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            for (x, y) in [(14.0, 18.0), (30, 12), (36, 24)] as [(CGFloat, CGFloat)] {
                UIColor(hex: [0xFF7FC4, 0xFFD93D, 0xFFFFFF][Int(x) % 3]).setFill()
                UIBezierPath(ovalIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)).fill()
            }
        }
    }

    static func house(roof: UIColor) -> SKTexture {
        texture("house-\(hex(roof))", size: CGSize(width: 80, height: 76)) { ctx, _ in
            let r = CGRect(x: 8, y: 8, width: 62, height: 58)
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 4, height: 6), blur: 6, color: UIColor(white: 0, alpha: 0.3).cgColor)
            roof.setFill()
            UIBezierPath(roundedRect: r, cornerRadius: 4).fill()
            ctx.restoreGState()
            blend(roof, with: .black, 0.18).setFill()
            ctx.fill(CGRect(x: r.minX, y: r.minY, width: r.width / 2, height: r.height))
            UIColor(white: 1, alpha: 0.5).setFill()
            ctx.fill(CGRect(x: r.midX - 1.5, y: r.minY, width: 3, height: r.height))
            UIColor(hex: 0xB0B6C3).setFill()
            ctx.fill(CGRect(x: r.maxX - 18, y: r.minY + 8, width: 10, height: 12))
        }
    }

    static var coin: SKTexture {
        texture("coin", size: CGSize(width: 48, height: 48)) { ctx, _ in
            ctx.setShadow(offset: CGSize(width: 1, height: 3), blur: 3, color: UIColor(white: 0, alpha: 0.3).cgColor)
            UIColor(hex: 0xE09B12).setFill()
            UIBezierPath(ovalIn: CGRect(x: 4, y: 4, width: 40, height: 40)).fill()
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            UIColor(hex: 0xFFD447).setFill()
            UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 32, height: 32)).fill()
            let star = UIBezierPath()
            for i in 0..<10 {
                let rr: CGFloat = i % 2 == 0 ? 11 : 5
                let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                let p = CGPoint(x: 24 + rr * cos(a), y: 24 + rr * sin(a))
                if i == 0 { star.move(to: p) } else { star.addLine(to: p) }
            }
            star.close()
            UIColor(hex: 0xFFF3B0).setFill()
            star.fill()
            UIColor(white: 1, alpha: 0.6).setFill()
            UIBezierPath(ovalIn: CGRect(x: 13, y: 11, width: 9, height: 6)).fill()
        }
    }
}

/// Tiny deterministic random generator so the road texture is the same every time.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let v = CGFloat((state >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF)
        return lo + (hi - lo) * v
    }
}
