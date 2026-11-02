import SwiftUI

/// Sticker Scenes (v8.7): put your collected buddy stickers into a picture. Drag to move; tap one for bigger,
/// smaller, flip, to the front or away. Scenes stay on this device.
struct StickerScenesView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void

    @State private var scene: StickerScene?
    @State private var selected: Int?
    @State private var dragStart: [Int: CGPoint] = [:]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF3E0), Color(hex: 0xFFE1EC)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if let scene { editor(scene) } else { list }
        }
        .animation(Motion.present, value: scene?.id)
        .onAppear { Narrator.shared.say("Sticker Scenes! Put your buddies into a picture.") }
    }

    // MARK: Saved scenes

    private var list: some View {
        let saved = store.profile?.scenes.scenes ?? []
        return ScrollView {
            VStack(spacing: 14) {
                HStack {
                    CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                    Spacer()
                    Text(L10n.tr("Sticker Scenes")).font(.kid(26, .black)).foregroundStyle(Palette.ink)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                BigButton(title: "Make a new picture", color: Color(hex: 0xFF7A59)) {
                    guard var p = store.profile else { return }
                    let fresh = p.scenes.newScene()
                    store.profile = p
                    selected = nil
                    scene = fresh
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(saved) { s in
                        Button { selected = nil; scene = s } label: {
                            SceneCanvas(scene: s, selected: nil, interactive: false, onDrag: { _, _ in }, onDragEnd: { _ in }, onTap: { _ in })
                                .aspectRatio(4 / 3, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("A picture with \(s.placed.count) stickers. Open it.")
                    }
                }
                if saved.isEmpty {
                    Text("Your pictures show up here. You can keep six.").font(.kid(15, .semibold)).foregroundStyle(Palette.ink.opacity(0.6))
                }
            }
            .padding(.horizontal, 18).padding(.top, 8)
        }
    }

    // MARK: Making a picture

    private func editor(_ s: StickerScene) -> some View {
        VStack(spacing: 10) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "Close without saving") { scene = nil }
                Spacer()
                Button {
                    guard var p = store.profile, let scene else { return }
                    p.scenes.save(scene)
                    store.profile = p
                    Haptics.success()
                    self.scene = nil
                } label: {
                    Text(L10n.tr("Save")).font(.kid(16, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 18).frame(height: 44).background(Capsule().fill(Palette.green))
                }
                .buttonStyle(BouncyButtonStyle())
            }
            SceneCanvas(scene: s, selected: selected, interactive: true,
                        onDrag: { id, p in self.scene?.move(id, x: p.x, y: p.y); selected = id },
                        onDragEnd: { id in self.scene?.raise(id) },
                        onTap: { id in Haptics.tap(); selected = selected == id ? nil : id })
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.ink.opacity(0.15), lineWidth: 2))
            if let id = selected, s.placed.contains(where: { $0.id == id }) {
                HStack(spacing: 10) {
                    tool("minus.magnifyingglass", "Smaller") { scene?.resize(id, by: 0.8) }
                    tool("plus.magnifyingglass", "Bigger") { scene?.resize(id, by: 1.25) }
                    tool("arrow.left.and.right.righttriangle.left.righttriangle.right.fill", "Flip") { scene?.flip(id) }
                    tool("square.3.layers.3d.top.filled", "To the front") { scene?.raise(id) }
                    tool("trash.fill", "Take away") { scene?.remove(id); selected = nil }
                }
            } else {
                // backdrops
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(StickerScene.backdrops, id: \.self) { b in
                            Button { scene?.backdrop = b } label: {
                                Backdrop(name: b).frame(width: 64, height: 48).clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(s.backdrop == b ? Palette.purple : .white, lineWidth: s.backdrop == b ? 3 : 1.5))
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .accessibilityLabel("\(b) background\(s.backdrop == b ? ", chosen" : "")")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            // sticker tray: every buddy you've collected
            Text(s.placed.count >= StickerScene.maxStickers ? "That's a full picture!" : "Tap a buddy to add it").font(.kid(13, .bold))
                .foregroundStyle(Palette.ink.opacity(0.6))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Roster.all.filter { store.ownedStickers.contains($0.id) }) { c in
                        Button {
                            if let id = scene?.add(c.id) { Haptics.tap(); selected = id }
                        } label: {
                            CharacterBadge(character: c, size: 52)
                                .frame(width: 64, height: 66)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Add \(c.name)")
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.top, 8)
    }

    private func tool(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            Image(systemName: icon).font(.system(size: 19, weight: .bold)).foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }
}

/// The picture: a backdrop with stickers on it.
struct SceneCanvas: View {
    @EnvironmentObject var store: GameStore
    let scene: StickerScene
    let selected: Int?
    let interactive: Bool
    var onDrag: (Int, CGPoint) -> Void
    var onDragEnd: (Int) -> Void
    var onTap: (Int) -> Void

    var body: some View {
        GeometryReader { g in
            ZStack {
                Backdrop(name: scene.backdrop)
                ForEach(scene.placed) { p in
                    let size = min(g.size.width, g.size.height) * 0.26 * p.scale
                    let c = Roster.character(id: p.characterID)
                    CharacterBadge(character: c, size: size)
                        .scaleEffect(x: p.flipped ? -1 : 1, y: 1)
                        .padding(4)
                        .background(Circle().stroke(Palette.purple, style: StrokeStyle(lineWidth: 3, dash: [6, 4])).opacity(selected == p.id ? 1 : 0))
                        .position(x: p.x * g.size.width, y: p.y * g.size.height)
                        .gesture(DragGesture(minimumDistance: 4)
                            .onChanged { v in onDrag(p.id, CGPoint(x: v.location.x / g.size.width, y: v.location.y / g.size.height)) }
                            .onEnded { _ in onDragEnd(p.id) }, including: interactive ? .all : .none)
                        .onTapGesture { if interactive { onTap(p.id) } }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(c.name)
                        .accessibilityHint(interactive ? "Swipe up or down to move it" : "")
                        .accessibilityActions {
                            if interactive {
                                Button("Move left") { onDrag(p.id, CGPoint(x: p.x - 0.1, y: p.y)) }
                                Button("Move right") { onDrag(p.id, CGPoint(x: p.x + 0.1, y: p.y)) }
                                Button("Move up") { onDrag(p.id, CGPoint(x: p.x, y: p.y - 0.1)) }
                                Button("Move down") { onDrag(p.id, CGPoint(x: p.x, y: p.y + 0.1)) }
                            }
                        }
                }
            }
        }
    }
}

/// The backgrounds, drawn with shapes and emoji.
struct Backdrop: View {
    let name: String
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                switch name {
                case "beach":
                    LinearGradient(colors: [Color(hex: 0x9FDCF5), Color(hex: 0xD8F3FF)], startPoint: .top, endPoint: .bottom)
                    Rectangle().fill(Color(hex: 0x3EA6E0)).frame(height: h * 0.18).position(x: w / 2, y: h * 0.62)
                    Rectangle().fill(Color(hex: 0xF2D58A)).frame(height: h * 0.32).position(x: w / 2, y: h * 0.86)
                    Text("☀️").font(.system(size: h * 0.16)).position(x: w * 0.85, y: h * 0.15)
                    Text("🌴").font(.system(size: h * 0.26)).position(x: w * 0.12, y: h * 0.66)
                case "space":
                    Color(hex: 0x1E2457)
                    ForEach(0..<24, id: \.self) { i in
                        Circle().fill(.white.opacity(0.8)).frame(width: 2.5, height: 2.5)
                            .position(x: w * CGFloat((i * 37 + 11) % 100) / 100, y: h * CGFloat((i * 53 + 7) % 100) / 100)
                    }
                    Text("🪐").font(.system(size: h * 0.2)).position(x: w * 0.82, y: h * 0.2)
                    Text("🌙").font(.system(size: h * 0.13)).position(x: w * 0.15, y: h * 0.15)
                    Ellipse().fill(Color(hex: 0x8A93A6)).frame(width: w * 1.4, height: h * 0.4).position(x: w / 2, y: h * 1.02)
                case "castle":
                    LinearGradient(colors: [Color(hex: 0xFFB3C7), Color(hex: 0xC9F0FF)], startPoint: .top, endPoint: .bottom)
                    Text("🏰").font(.system(size: h * 0.45)).position(x: w * 0.5, y: h * 0.48)
                    Rectangle().fill(Color(hex: 0x6FD08C)).frame(height: h * 0.22).position(x: w / 2, y: h * 0.89)
                case "ocean":
                    LinearGradient(colors: [Color(hex: 0x58B7E8), Color(hex: 0x1B4F8C)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<8, id: \.self) { i in
                        Circle().stroke(.white.opacity(0.5), lineWidth: 1.5).frame(width: CGFloat(6 + i % 3 * 4))
                            .position(x: w * CGFloat((i * 29 + 13) % 100) / 100, y: h * CGFloat((i * 41 + 9) % 80) / 100)
                    }
                    Text("🪸").font(.system(size: h * 0.2)).position(x: w * 0.15, y: h * 0.85)
                    Text("🐚").font(.system(size: h * 0.1)).position(x: w * 0.85, y: h * 0.9)
                case "city":
                    LinearGradient(colors: [Color(hex: 0xFFD6A5), Color(hex: 0xFFF1E0)], startPoint: .top, endPoint: .bottom)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<7, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3).fill([Color(hex: 0x8E7CC3), Color(hex: 0x6FA8DC), Color(hex: 0xF6B26B)][i % 3])
                                .frame(width: w / 9, height: h * CGFloat([0.45, 0.6, 0.35, 0.7, 0.5, 0.4, 0.55][i]))
                        }
                    }
                    .frame(width: w, height: h * 0.8, alignment: .bottom).position(x: w / 2, y: h * 0.48)
                    Rectangle().fill(Color(hex: 0x9AA0A6)).frame(height: h * 0.14).position(x: w / 2, y: h * 0.93)
                default: // meadow
                    LinearGradient(colors: [Color(hex: 0xBFE3FF), Color(hex: 0xEEF8FF)], startPoint: .top, endPoint: .bottom)
                    Ellipse().fill(Color(hex: 0x59C46B)).frame(width: w * 1.5, height: h * 0.6).position(x: w * 0.5, y: h * 1.0)
                    Text("☀️").font(.system(size: h * 0.16)).position(x: w * 0.85, y: h * 0.15)
                    Text("🌼").font(.system(size: h * 0.09)).position(x: w * 0.15, y: h * 0.82)
                    Text("🌷").font(.system(size: h * 0.09)).position(x: w * 0.75, y: h * 0.88)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
