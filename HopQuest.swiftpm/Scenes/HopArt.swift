import SpriteKit
import UIKit

/// Painted, cached row textures for the hop levels.
enum HopArt {
    enum Edge: String { case dash, curb }

    private static var cache: [String: SKTexture] = [:]

    private static func texture(_ key: String, size: CGSize, draw: (CGContext, CGSize) -> Void) -> SKTexture {
        if let t = cache[key] { return t }
        let image = UIGraphicsImageRenderer(size: size).image { ctx in draw(ctx.cgContext, size) }
        let t = SKTexture(image: image)
        cache[key] = t
        return t
    }

    static func grass(width: CGFloat, cell: CGFloat, light: Bool) -> SKTexture {
        texture("grass-\(Int(width))-\(Int(cell))-\(light)", size: CGSize(width: width, height: cell)) { ctx, size in
            var rng = SeededRandom(seed: light ? 11 : 23)
            UIColor(hex: light ? 0x9BE07A : 0x8CD46B).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            // checker tint by column so the grid reads clearly for hopping
            let cols = Int(size.width / cell) + 1
            for c in 0..<cols where c % 2 == 0 {
                UIColor(white: 1, alpha: 0.05).setFill()
                ctx.fill(CGRect(x: CGFloat(c) * cell, y: 0, width: cell, height: size.height))
            }
            for _ in 0..<Int(size.width / 9) {
                let x = rng.next(0, size.width), y = rng.next(4, size.height - 4)
                UIColor(hex: light ? 0x7CCB5B : 0x72C252).setStroke()
                ctx.setLineWidth(1.6)
                ctx.move(to: CGPoint(x: x, y: y + 4))
                ctx.addLine(to: CGPoint(x: x - 2, y: y - 2))
                ctx.move(to: CGPoint(x: x + 2, y: y + 4))
                ctx.addLine(to: CGPoint(x: x + 4, y: y - 1))
                ctx.strokePath()
            }
            // soft shadow line at the bottom edge so rows feel stacked
            UIColor(white: 0, alpha: 0.06).setFill()
            ctx.fill(CGRect(x: 0, y: size.height - 3, width: size.width, height: 3))
        }
    }

    static func path(width: CGFloat, cell: CGFloat) -> SKTexture {
        texture("path-\(Int(width))-\(Int(cell))", size: CGSize(width: width, height: cell)) { ctx, size in
            var rng = SeededRandom(seed: 5)
            UIColor(hex: 0xF3D99B).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for _ in 0..<Int(size.width / 6) {
                let x = rng.next(0, size.width), y = rng.next(3, size.height - 3)
                let r = rng.next(1.5, 4)
                UIColor(hex: rng.next(0, 1) > 0.5 ? 0xE2C27F : 0xFFF0C8).setFill()
                UIBezierPath(ovalIn: CGRect(x: x, y: y, width: r * 1.4, height: r)).fill()
            }
            UIColor(hex: 0xD9B86A).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: 3))
            ctx.fill(CGRect(x: 0, y: size.height - 3, width: size.width, height: 3))
        }
    }

    /// `top`/`bottom` are in screen terms (top = toward the castle).
    static func road(width: CGFloat, cell: CGFloat, top: Edge, bottom: Edge) -> SKTexture {
        texture("road-\(Int(width))-\(Int(cell))-\(top.rawValue)-\(bottom.rawValue)", size: CGSize(width: width, height: cell)) { ctx, size in
            var rng = SeededRandom(seed: 31)
            UIColor(hex: 0x4A505E).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for _ in 0..<Int(size.width * size.height / 70) {
                let x = rng.next(0, size.width), y = rng.next(0, size.height)
                let s = rng.next(1, 2.4)
                UIColor(white: rng.next(0, 1) > 0.5 ? 1 : 0, alpha: 0.07).setFill()
                ctx.fill(CGRect(x: x, y: y, width: s, height: s))
            }
            // UIKit y=0 is the TOP of the image, which is the top of the row on screen.
            for (edge, y) in [(top, CGFloat(0)), (bottom, size.height)] {
                switch edge {
                case .curb:
                    UIColor(hex: 0xEDEFF3).setFill()
                    ctx.fill(CGRect(x: 0, y: y == 0 ? 0 : size.height - 5, width: size.width, height: 5))
                    UIColor(hex: 0xB9BDC8).setFill()
                    var x: CGFloat = 0
                    while x < size.width {
                        ctx.fill(CGRect(x: x, y: y == 0 ? 0 : size.height - 5, width: 1.5, height: 5))
                        x += 22
                    }
                case .dash:
                    UIColor(white: 1, alpha: 0.8).setFill()
                    var x: CGFloat = cell * 0.2
                    while x < size.width {
                        ctx.fill(CGRect(x: x, y: y == 0 ? 0 : size.height - 2, width: cell * 0.5, height: 2))
                        x += cell
                    }
                }
            }
        }
    }

    static func water(width: CGFloat, cell: CGFloat, frame: Int) -> SKTexture {
        texture("water-\(Int(width))-\(Int(cell))-\(frame)", size: CGSize(width: width, height: cell)) { ctx, size in
            let cs = [UIColor(hex: 0x6ED3F7).cgColor, UIColor(hex: 0x3FB4E8).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cs, locations: [0, 1]) {
                ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            var rng = SeededRandom(seed: 77)
            UIColor(white: 1, alpha: 0.45).setStroke()
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            let shift = CGFloat(frame) * cell * 0.25
            for _ in 0..<Int(size.width / 26) {
                let x = rng.next(0, size.width) + shift
                let y = rng.next(6, size.height - 6) + (frame == 1 ? 2 : 0)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addQuadCurve(to: CGPoint(x: x + 14, y: y), control: CGPoint(x: x + 7, y: y - 4))
                ctx.strokePath()
            }
            UIColor(white: 1, alpha: 0.25).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: 3))
        }
    }

    static func log(length: CGFloat, height: CGFloat) -> SKTexture {
        let size = CGSize(width: length + 8, height: height + 10)
        return texture("log-\(Int(length))-\(Int(height))", size: size) { ctx, _ in
            let body = CGRect(x: 4, y: 4, width: length, height: height)
            let shape = UIBezierPath(roundedRect: body, cornerRadius: height * 0.45)
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 4, color: UIColor(hex: 0x1E5E7A, alpha: 0.5).cgColor)
            UIColor(hex: 0xA0673B).setFill()
            shape.fill()
            ctx.restoreGState()
            ctx.saveGState()
            shape.addClip()
            let cs = [UIColor(white: 1, alpha: 0.2).cgColor, UIColor(white: 0, alpha: 0).cgColor, UIColor(white: 0, alpha: 0.25).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cs, locations: [0, 0.45, 1]) {
                ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: body.minY), end: CGPoint(x: 0, y: body.maxY), options: [])
            }
            var rng = SeededRandom(seed: UInt64(length))
            UIColor(hex: 0x6E4325, alpha: 0.7).setStroke()
            ctx.setLineWidth(1.5)
            for _ in 0..<Int(length / 14) {
                let x = rng.next(body.minX + 12, body.maxX - 24), y = rng.next(body.minY + 4, body.maxY - 4)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addLine(to: CGPoint(x: x + rng.next(10, 22), y: y))
                ctx.strokePath()
            }
            ctx.restoreGState()
            // cut end with rings
            let end = CGRect(x: body.maxX - height * 0.5, y: body.minY + 1, width: height * 0.45, height: height - 2)
            UIColor(hex: 0xE3B07A).setFill()
            UIBezierPath(ovalIn: end).fill()
            UIColor(hex: 0xB9814F).setStroke()
            UIBezierPath(ovalIn: end.insetBy(dx: end.width * 0.22, dy: end.height * 0.22)).stroke()
            UIColor(hex: 0x6E4325).setStroke()
            shape.lineWidth = 1.5
            shape.stroke()
        }
    }

    // MARK: Side-view vehicles (hop roads)

    enum SideKind: String { case car, bus, truck }

    /// Painted side-view vehicle facing RIGHT. Size is the body box; texture adds a little padding.
    static func sideVehicle(_ kind: SideKind, color: UIColor, size body: CGSize) -> SKTexture {
        let pad: CGFloat = 4
        let full = CGSize(width: body.width + pad * 2, height: body.height + pad * 2)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "side-\(kind.rawValue)-\(Int(body.width))x\(Int(body.height))-\(Int(r * 255))-\(Int(g * 255))-\(Int(b * 255))"
        return texture(key, size: full) { ctx, _ in
            let w = body.width, h = body.height
            let x0 = pad, y0 = pad
            let wheelR = h * 0.17
            let bodyTop = y0 + h * (kind == .car ? 0.38 : 0.08)
            let bodyBottom = y0 + h - wheelR * 1.1
            let ink = UIColor(white: 0, alpha: 0.35)

            // ground shadow
            UIColor(white: 0, alpha: 0.22).setFill()
            UIBezierPath(ovalIn: CGRect(x: x0 + w * 0.05, y: y0 + h - wheelR * 0.7, width: w * 0.9, height: wheelR * 0.9)).fill()

            // body shapes
            let main: UIBezierPath
            switch kind {
            case .car:
                let cabin = UIBezierPath()
                cabin.move(to: CGPoint(x: x0 + w * 0.18, y: bodyTop + 2))
                cabin.addQuadCurve(to: CGPoint(x: x0 + w * 0.3, y: y0 + h * 0.06), controlPoint: CGPoint(x: x0 + w * 0.2, y: y0 + h * 0.1))
                cabin.addLine(to: CGPoint(x: x0 + w * 0.62, y: y0 + h * 0.06))
                cabin.addQuadCurve(to: CGPoint(x: x0 + w * 0.8, y: bodyTop + 2), controlPoint: CGPoint(x: x0 + w * 0.74, y: y0 + h * 0.08))
                cabin.close()
                color.setFill(); cabin.fill()
                ink.setStroke(); cabin.lineWidth = 1.5; cabin.stroke()
                main = UIBezierPath(roundedRect: CGRect(x: x0, y: bodyTop, width: w, height: bodyBottom - bodyTop), cornerRadius: h * 0.16)
            case .bus, .truck:
                main = UIBezierPath(roundedRect: CGRect(x: x0, y: bodyTop, width: w, height: bodyBottom - bodyTop), cornerRadius: h * 0.12)
            }
            color.setFill(); main.fill()
            // shading: light top, darker bottom
            ctx.saveGState()
            main.addClip()
            let cs = [UIColor(white: 1, alpha: 0.25).cgColor, UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 0, alpha: 0.22).cgColor] as CFArray
            if let gr = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cs, locations: [0, 0.45, 1]) {
                ctx.drawLinearGradient(gr, start: CGPoint(x: 0, y: bodyTop), end: CGPoint(x: 0, y: bodyBottom), options: [])
            }
            ctx.restoreGState()
            ink.setStroke(); main.lineWidth = 1.5; main.stroke()

            let glass = UIColor(hex: 0xBFE6FF)
            switch kind {
            case .car:
                // two windows in the cabin
                glass.setFill()
                UIBezierPath(roundedRect: CGRect(x: x0 + w * 0.27, y: y0 + h * 0.12, width: w * 0.18, height: h * 0.24), cornerRadius: 4).fill()
                UIBezierPath(roundedRect: CGRect(x: x0 + w * 0.49, y: y0 + h * 0.12, width: w * 0.2, height: h * 0.24), cornerRadius: 4).fill()
                // friendly eyes on the front window
                UIColor(hex: 0x2B1B3D).setFill()
                for dx in [0.56, 0.64] {
                    UIBezierPath(ovalIn: CGRect(x: x0 + w * CGFloat(dx), y: y0 + h * 0.18, width: h * 0.09, height: h * 0.12)).fill()
                }
                // door line + handle
                ink.setStroke(); ctx.setLineWidth(1.2)
                ctx.move(to: CGPoint(x: x0 + w * 0.48, y: bodyTop + 3)); ctx.addLine(to: CGPoint(x: x0 + w * 0.48, y: bodyBottom - 3)); ctx.strokePath()
                UIColor(white: 1, alpha: 0.6).setFill()
                ctx.fill(CGRect(x: x0 + w * 0.52, y: bodyTop + h * 0.08, width: w * 0.06, height: 2.5))
            case .bus:
                glass.setFill()
                let n = 4
                for i in 0..<n {
                    let wx = x0 + w * 0.08 + CGFloat(i) * w * 0.19
                    UIBezierPath(roundedRect: CGRect(x: wx, y: bodyTop + h * 0.08, width: w * 0.15, height: h * 0.26), cornerRadius: 3).fill()
                }
                UIColor(hex: 0x2B1B3D).setFill()
                ctx.fill(CGRect(x: x0 + 2, y: bodyTop + h * 0.42, width: w - 4, height: 3))
                let text = NSAttributedString(string: "SCHOOL BUS", attributes: [
                    .font: UIFont.systemFont(ofSize: max(6, h * 0.13), weight: .black),
                    .foregroundColor: UIColor(hex: 0x2B1B3D)])
                let ts = text.size()
                text.draw(at: CGPoint(x: x0 + w * 0.5 - ts.width / 2, y: bodyTop + h * 0.47))
            case .truck:
                // cab at the front, cargo box behind
                UIColor(white: 1, alpha: 0.85).setFill()
                UIBezierPath(roundedRect: CGRect(x: x0 + 2, y: bodyTop + 2, width: w * 0.66, height: bodyBottom - bodyTop - 4), cornerRadius: 4).fill()
                UIColor(hex: 0xFF7A59).setFill()
                ctx.fill(CGRect(x: x0 + w * 0.08, y: bodyTop + h * 0.3, width: w * 0.5, height: h * 0.12))
                glass.setFill()
                UIBezierPath(roundedRect: CGRect(x: x0 + w * 0.76, y: bodyTop + h * 0.08, width: w * 0.17, height: h * 0.26), cornerRadius: 3).fill()
            }

            // headlight (front = right) and tail light
            UIColor(hex: 0xFFF3A0).setFill()
            UIBezierPath(roundedRect: CGRect(x: x0 + w - 6, y: bodyTop + (bodyBottom - bodyTop) * 0.35, width: 5, height: 6), cornerRadius: 2).fill()
            UIColor(hex: 0xE63946).setFill()
            UIBezierPath(roundedRect: CGRect(x: x0 + 1, y: bodyTop + (bodyBottom - bodyTop) * 0.35, width: 4, height: 6), cornerRadius: 2).fill()

            // wheels with hubcaps
            for fx in (kind == .car ? [0.22, 0.78] : [0.17, 0.42, 0.82]) {
                let c = CGPoint(x: x0 + w * CGFloat(fx), y: y0 + h - wheelR)
                UIColor(hex: 0x23232B).setFill()
                UIBezierPath(ovalIn: CGRect(x: c.x - wheelR, y: c.y - wheelR, width: wheelR * 2, height: wheelR * 2)).fill()
                UIColor(hex: 0xC9CED8).setFill()
                UIBezierPath(ovalIn: CGRect(x: c.x - wheelR * 0.45, y: c.y - wheelR * 0.45, width: wheelR * 0.9, height: wheelR * 0.9)).fill()
            }
        }
    }

    // MARK: Lily pad

    static var lilyPad: SKTexture {
        texture("lilypad", size: CGSize(width: 64, height: 56)) { ctx, _ in
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 3, color: UIColor(hex: 0x1E5E7A, alpha: 0.5).cgColor)
            let pad = UIBezierPath()
            let c = CGPoint(x: 32, y: 28)
            pad.move(to: c)
            pad.addArc(withCenter: c, radius: 26, startAngle: -.pi / 2 + 0.35, endAngle: -.pi / 2 - 0.35 + 2 * .pi, clockwise: true)
            pad.close()
            UIColor(hex: 0x3FA34D).setFill()
            pad.fill()
            ctx.restoreGState()
            UIColor(hex: 0x5CC46A).setStroke()
            ctx.setLineWidth(1.5)
            for a in stride(from: 0.0, to: 2 * Double.pi, by: Double.pi / 4) where abs(a - 3 * Double.pi / 2) > 0.4 {
                ctx.move(to: c)
                ctx.addLine(to: CGPoint(x: c.x + 20 * CGFloat(cos(a)), y: c.y + 20 * CGFloat(sin(a))))
            }
            ctx.strokePath()
            // flower
            UIColor(hex: 0xFFB3DA).setFill()
            for i in 0..<5 {
                let a = CGFloat(i) / 5 * 2 * .pi
                UIBezierPath(ovalIn: CGRect(x: 42 + 6 * cos(a) - 4, y: 36 + 6 * sin(a) - 4, width: 8, height: 8)).fill()
            }
            UIColor(hex: 0xFFE066).setFill()
            UIBezierPath(ovalIn: CGRect(x: 39, y: 33, width: 6, height: 6)).fill()
        }
    }
}
