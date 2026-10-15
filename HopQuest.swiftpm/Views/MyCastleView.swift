import SwiftUI

/// My Castle: a cozy room kids decorate with furniture bought with stars, where their buddies hang out.
/// Buddies can be given snacks and toys, but they never get hungry or sad; there's no guilt mechanic.
struct MyCastleView: View {
    var onBack: () -> Void

    @EnvironmentObject var store: GameStore

    @State private var selected: UUID?
    @State private var dragging: [UUID: CGSize] = [:]
    @State private var panel: Panel?
    @State private var snack: String?
    @State private var walkerX: [String: CGFloat] = [:]
    @State private var walkerFacing: [String: CGFloat] = [:]
    @State private var happy: String?
    @State private var hearts: [Heart] = []
    @State private var message: String?

    private let walkTimer = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    enum Panel { case shop, guests }

    struct Heart: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let symbol: String
    }

    static let wallpapers: [(top: UInt32, bottom: UInt32, name: String)] = [
        (0xFFE4F3, 0xFFC9E6, "Bubblegum"), (0xD8F7FF, 0xB5E6FF, "Sky"), (0xE9D5FF, 0xD2B8FF, "Lavender"),
        (0xFFF4C2, 0xFFE29A, "Sunshine"), (0xD9F7D8, 0xB7E4A1, "Mint"), (0x2E3A8C, 0x5B4BC9, "Starry night")
    ]

    static let catalog: [(id: String, name: String)] = [
        ("decor_rug", "Comfy rug"), ("decor_plant", "Leafy plant"), ("decor_lamp", "Sunny lamp"),
        ("decor_painting", "Mountain painting"), ("decor_balloons", "Party balloons"), ("decor_beanbag", "Bean bag"),
        ("decor_toybox", "Toy box"), ("decor_banner", "Star banner"), ("decor_bookshelf", "Bookshelf"),
        ("decor_cake", "Birthday cake"), ("decor_bed", "Cozy bed"), ("decor_aquarium", "Fish tank"),
        ("decor_telescope", "Telescope"), ("decor_rocket", "Toy rocket"), ("decor_piano", "Piano"),
        ("decor_trophy", "Gold trophy")
    ]

    private static let wallItems: Set<String> = ["decor_painting", "decor_banner"]
    private static let snacks: [(id: String, name: String)] = [("snack_apple", "apple"), ("snack_cookie", "cookie"), ("snack_ball", "ball")]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF3ECFF), Color(hex: 0xFFF4E0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 10) {
                header
                if let message {
                    MessageBubble(text: message)
                        .transition(.opacity)
                }
                room
                if selected != nil { selectionBar } else { snackBar }
                bottomButtons
            }
            .padding(.top, 6)
            .padding(.bottom, 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: message)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selected)

            if let panel {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture { self.panel = nil }
                VStack {
                    Spacer()
                    Group {
                        switch panel {
                        case .shop: shop
                        case .guests: guests
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: panel)
        .onAppear {
            say(store.profile?.decorPlaced.isEmpty ?? true
                ? "Welcome to your castle! Tap Decorate to add furniture. Buddies love visitors!"
                : "Welcome home! Your buddies missed you.")
        }
        .onReceive(walkTimer) { _ in wander() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "house.fill", label: "Back to map", action: onBack)
            Spacer()
            ArtImage("castle_\(store.theme.rawValue)").frame(width: 40, height: 42)
            Text("My Castle").font(.kid(28, .black)).foregroundStyle(Palette.purple)
            Spacer()
            HStack(spacing: 4) {
                ArtImage("goal_star").frame(width: 24, height: 24)
                Text("\(store.profile?.stars ?? 0)").contentTransition(.numericText())
            }
            .font(.kid(20, .black))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Capsule().fill(.white.opacity(0.92)))
            .accessibilityLabel("\(store.profile?.stars ?? 0) stars to spend")
        }
        .padding(.horizontal, 14)
    }

    // MARK: Room

    private var wall: (top: Color, bottom: Color) {
        let w = Self.wallpapers[(store.profile?.wallpaper ?? 0) % Self.wallpapers.count]
        return (Color(hex: w.top), Color(hex: w.bottom))
    }

    private var room: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorTop = h * 0.5
            ZStack(alignment: .topLeading) {
                // wall
                LinearGradient(colors: [wall.top, wall.bottom], startPoint: .top, endPoint: .bottom)
                    .frame(width: w, height: floorTop + 4)
                if store.profile?.wallpaper == 5 {
                    ForEach(0..<14, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat(8 + (i * 7) % 10)))
                            .foregroundStyle(.white.opacity(0.7))
                            .position(x: w * CGFloat((i * 37) % 100) / 100, y: floorTop * CGFloat((i * 53) % 90 + 5) / 100)
                    }
                }
                ArtImage("room_window")
                    .frame(width: w * 0.26, height: w * 0.26 * 1.1)
                    .position(x: w * 0.5, y: floorTop * 0.47)
                // floor
                ArtImage("room_floor")
                    .scaledToFill()
                    .frame(width: w, height: h - floorTop)
                    .clipped()
                    .offset(y: floorTop)

                // furniture, back to front
                ForEach(sortedPlacements) { item in
                    decor(item, w: w, h: h)
                }

                // buddies
                ForEach(Array(residents.enumerated()), id: \.element.id) { i, c in
                    buddy(c, index: i, w: w, h: h)
                }

                ForEach(hearts) { heart in
                    Text(heart.symbol)
                        .font(.system(size: 26))
                        .position(x: heart.x, y: heart.y)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
                        .allowsHitTesting(false)
                }
            }
            .frame(width: w, height: h)
            .contentShape(Rectangle())
            .onTapGesture { selected = nil }
        }
        .aspectRatio(0.92, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Palette.ink, lineWidth: 4))
        .padding(.horizontal, 14)
    }

    private var sortedPlacements: [DecorPlacement] {
        (store.profile?.decorPlaced ?? []).sorted { a, b in
            // rugs always lie flat at the back; everything else sorts by how far forward it is
            let ra = a.item == "decor_rug" ? -1 : a.y
            let rb = b.item == "decor_rug" ? -1 : b.y
            return ra < rb
        }
    }

    private func decor(_ item: DecorPlacement, w: CGFloat, h: CGFloat) -> some View {
        let isWall = Self.wallItems.contains(item.item)
        let scale = isWall ? 0.95 : 0.75 + 0.45 * CGFloat(item.y)
        let size = w * 0.3 * scale
        let drag = dragging[item.id] ?? .zero
        let isSelected = selected == item.id
        return ArtImage(item.item)
            .frame(width: size, height: size)
            .scaleEffect(x: item.flipped ? -1 : 1, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color(hex: 0xFFB020) : .clear, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
            )
            .scaleEffect(drag == .zero ? 1 : 1.08)
            // anchor at the bottom center (where it touches the floor)
            .position(x: CGFloat(item.x) * w + drag.width, y: CGFloat(item.y) * h - size * 0.46 + drag.height)
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { v in
                        selected = item.id
                        dragging[item.id] = v.translation
                    }
                    .onEnded { v in
                        dragging[item.id] = nil
                        move(item.id, by: v.translation, w: w, h: h, isWall: isWall)
                    }
            )
            .onTapGesture {
                Haptics.tap()
                selected = isSelected ? nil : item.id
            }
            .accessibilityLabel(Self.catalog.first { $0.id == item.item }?.name ?? "Decoration")
            .accessibilityHint("Drag to move it around the room")
    }

    private func move(_ id: UUID, by t: CGSize, w: CGFloat, h: CGFloat, isWall: Bool) {
        guard var p = store.profile, let i = p.decorPlaced.firstIndex(where: { $0.id == id }) else { return }
        var x = p.decorPlaced[i].x + Double(t.width / w)
        var y = p.decorPlaced[i].y + Double(t.height / h)
        x = min(max(x, 0.08), 0.92)
        y = isWall ? min(max(y, 0.18), 0.5) : min(max(y, 0.56), 0.97)
        p.decorPlaced[i].x = x
        p.decorPlaced[i].y = y
        store.profile = p
        SoundFX.shared.play(.pop, volume: 0.5)
    }

    // MARK: Buddies

    /// Your buddy plus up to three invited guests.
    private var residents: [GameCharacter] {
        let guests = (store.profile?.castleGuests ?? []).map { Roster.character(id: $0) }.filter { $0.id != store.character.id }
        return [store.character] + guests.prefix(3)
    }

    private func buddy(_ c: GameCharacter, index: Int, w: CGFloat, h: CGFloat) -> some View {
        let lanes: [CGFloat] = [0.9, 0.78, 0.84, 0.72]
        let y = lanes[index % lanes.count]
        let x = walkerX[c.id] ?? [0.3, 0.7, 0.5, 0.2][index % 4]
        let size = w * (0.2 + 0.08 * (y - 0.7) / 0.2)
        let isHappy = happy == c.id
        return CharacterBadge(character: c, size: size, animated: true)
            .scaleEffect(x: walkerFacing[c.id] ?? 1, y: 1)
            .offset(y: isHappy ? -size * 0.25 : 0)
            .position(x: x * w, y: y * h - size * 0.5)
            .animation(.easeInOut(duration: 2.2), value: walkerX[c.id])
            .animation(.spring(response: 0.25, dampingFraction: 0.4), value: isHappy)
            .onTapGesture { tapBuddy(c, at: CGPoint(x: x * w, y: y * h - size)) }
            .accessibilityLabel(snack == nil ? "\(c.name). Tap to say hi." : "Give \(c.name) the \(snackName)")
    }

    private var snackName: String { Self.snacks.first { $0.id == snack }?.name ?? "treat" }

    private func wander() {
        guard panel == nil else { return }
        for (i, c) in residents.enumerated() where Int.random(in: 0..<3) != 0 || walkerX[c.id] == nil {
            let current = walkerX[c.id] ?? [0.3, 0.7, 0.5, 0.2][i % 4]
            let next = min(max(current + CGFloat.random(in: -0.25...0.25), 0.12), 0.88)
            walkerFacing[c.id] = next < current ? -1 : 1
            walkerX[c.id] = next
        }
    }

    private func tapBuddy(_ c: GameCharacter, at p: CGPoint) {
        if let snack {
            let name = Self.snacks.first { $0.id == snack }?.name ?? "treat"
            let line = name == "ball"
                ? "\(c.name) loves playing catch! Whee!"
                : "Yum! \(c.name) loves the \(name)! Thank you for sharing."
            pop(at: p, symbols: name == "ball" ? ["⚽️", "✨", "💜"] : ["💖", "😋", "💖"])
            Haptics.success(.chime)
            say(line)
            self.snack = nil
        } else {
            pop(at: p, symbols: ["💜", "✨"])
            Haptics.tap(.pop)
            say("Hi! I'm \(c.name). \(c.fact)")
        }
        happy = c.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { if happy == c.id { happy = nil } }
    }

    private func pop(at p: CGPoint, symbols: [String]) {
        for (i, s) in symbols.enumerated() {
            let heart = Heart(x: p.x + CGFloat(i - symbols.count / 2) * 26, y: p.y - CGFloat(i % 2) * 14, symbol: s)
            withAnimation(.spring()) { hearts.append(heart) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeOut(duration: 0.5)) { hearts.removeAll { $0.id == heart.id } }
            }
        }
    }

    // MARK: Bars

    private var snackBar: some View {
        HStack(spacing: 10) {
            Text(snack == nil ? "Treats:" : "Tap a buddy!")
                .font(.kid(15, .black))
                .foregroundStyle(Palette.ink)
            ForEach(Self.snacks, id: \.id) { s in
                Button {
                    Haptics.tap()
                    snack = snack == s.id ? nil : s.id
                } label: {
                    ArtImage(s.id)
                        .frame(width: 40, height: 40)
                        .padding(6)
                        .background(Circle().fill(snack == s.id ? Color(hex: 0xFFF4C2) : .white))
                        .overlay(Circle().stroke(snack == s.id ? Color(hex: 0xFFB020) : .clear, lineWidth: 3))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Give a \(s.name)")
            }
            Spacer(minLength: 0)
            Button {
                Haptics.tap()
                guard var p = store.profile else { return }
                p.wallpaper = (p.wallpaper + 1) % Self.wallpapers.count
                store.profile = p
                say("New walls: \(Self.wallpapers[p.wallpaper].name)!")
            } label: {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(LinearGradient(colors: [wall.top, wall.bottom], startPoint: .top, endPoint: .bottom)))
                    .overlay(Circle().stroke(Palette.ink, lineWidth: 3))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Change wall color")
        }
        .padding(.horizontal, 16)
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Text("Move it by dragging").font(.kid(14, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
            Spacer()
            smallButton("arrow.left.and.right.righttriangle.left.righttriangle.right.fill", "Flip") {
                edit { $0.flipped.toggle() }
            }
            smallButton("tray.and.arrow.down.fill", "Put away") {
                guard var p = store.profile, let id = selected else { return }
                p.decorPlaced.removeAll { $0.id == id }
                store.profile = p
                selected = nil
            }
            smallButton("checkmark", "Done") { selected = nil }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }

    private func smallButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold))
                Text(label).font(.kid(11, .heavy))
            }
            .foregroundStyle(Palette.ink)
            .frame(width: 64, height: 54)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func edit(_ change: (inout DecorPlacement) -> Void) {
        guard var p = store.profile, let id = selected, let i = p.decorPlaced.firstIndex(where: { $0.id == id }) else { return }
        change(&p.decorPlaced[i])
        store.profile = p
    }

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            BigButton(title: "Decorate 🛋️", color: Color(hex: 0xFF9F45)) { panel = .shop }
            BigButton(title: "Invite 💌", color: Palette.purple) { panel = .guests }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Shop

    private var shop: some View {
        VStack(spacing: 12) {
            panelHeader("Decorate", subtitle: "Spend stars on furniture. Tap one you own to add it to your room!")
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(Self.catalog, id: \.id) { item in
                        shopCard(item.id, name: item.name)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .frame(maxHeight: 430)
        }
        .padding(.top, 16)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.white).ignoresSafeArea(edges: .bottom))
    }

    private func shopCard(_ id: String, name: String) -> some View {
        let owned = store.profile?.decorOwned.contains(id) ?? false
        let price = GameStore.decorPrices[id] ?? 5
        let canAfford = (store.profile?.stars ?? 0) >= price
        return Button {
            if owned {
                place(id)
            } else if store.buyDecor(id) {
                Haptics.success(.fanfare)
                say("You got the \(name.lowercased())! Tap it again to put it in your room.")
            } else {
                Haptics.bump(.oops)
                say("You need \(price - (store.profile?.stars ?? 0)) more stars. Play a level to earn them!")
            }
        } label: {
            VStack(spacing: 4) {
                ArtImage(id).frame(width: 70, height: 70)
                Text(name).font(.kid(12, .bold)).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
                if owned {
                    Text("Place").font(.kid(13, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 3)
                        .background(Capsule().fill(Palette.green))
                } else {
                    HStack(spacing: 2) {
                        ArtImage("goal_star").frame(width: 16, height: 16)
                        Text("\(price)").font(.kid(14, .black))
                    }
                    .foregroundStyle(canAfford ? Palette.ink : Palette.ink.opacity(0.4))
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: canAfford ? 0xFFF4C2 : 0xEFEFF4)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xF7F3FF)))
            .opacity(owned || canAfford ? 1 : 0.7)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(owned ? "\(name). Tap to place it." : "\(name), \(price) stars")
    }

    private func place(_ id: String) {
        guard var p = store.profile else { return }
        guard p.decorPlaced.count < 24 else {
            say("Your room is full! Put something away first.")
            return
        }
        let isWall = Self.wallItems.contains(id)
        let item = DecorPlacement(item: id, x: Double.random(in: 0.25...0.75), y: isWall ? 0.36 : Double.random(in: 0.6...0.9))
        p.decorPlaced.append(item)
        store.profile = p
        panel = nil
        selected = item.id
        Haptics.success(.pop)
        say("Drag it anywhere you like!")
    }

    // MARK: Guests

    private var guests: some View {
        let owned = Roster.all.filter { store.ownedStickers.contains($0.id) && $0.id != store.character.id }
        let invited = Set(store.profile?.castleGuests ?? [])
        return VStack(spacing: 12) {
            panelHeader("Invite buddies", subtitle: owned.isEmpty
                        ? "Open sticker packs to meet new buddies, then invite them over!"
                        : "Pick up to 3 buddies from your Sticker Book to hang out.")
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 12)], spacing: 12) {
                    ForEach(owned) { c in
                        Button {
                            toggleGuest(c.id)
                        } label: {
                            VStack(spacing: 2) {
                                CharacterBadge(character: c, size: 62)
                                Text(c.name).font(.kid(11, .bold)).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 18).fill(invited.contains(c.id) ? Color(hex: 0xFFF4C2) : Color(hex: 0xF7F3FF)))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(invited.contains(c.id) ? Color(hex: 0xFFB020) : .clear, lineWidth: 3))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel(invited.contains(c.id) ? "\(c.name), invited" : "Invite \(c.name)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .frame(maxHeight: 380)
        }
        .padding(.top, 16)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.white).ignoresSafeArea(edges: .bottom))
    }

    private func toggleGuest(_ id: String) {
        guard var p = store.profile else { return }
        Haptics.tap()
        if let i = p.castleGuests.firstIndex(of: id) {
            p.castleGuests.remove(at: i)
        } else {
            if p.castleGuests.count >= 3 { p.castleGuests.removeFirst() }
            p.castleGuests.append(id)
            say("\(Roster.character(id: id).name) is coming over!")
        }
        store.profile = p
    }

    private func panelHeader(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title).font(.kid(26, .black)).foregroundStyle(Palette.purple)
                Spacer()
                Button { panel = nil } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundStyle(Palette.ink.opacity(0.3))
                }
                .accessibilityLabel("Close")
            }
            Text(subtitle).font(.kid(14, .medium)).foregroundStyle(Palette.ink.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
    }

    private func say(_ text: String) {
        message = text
        Narrator.shared.say(text)
        let shown = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            if message == shown { message = nil }
        }
    }
}
