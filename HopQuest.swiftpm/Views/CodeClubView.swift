import SwiftUI

// Code Club: program the robot to reach the star. Robot Lab 2 adds sensors (Repeat until ⭐, If blocked … else)
// and the Machine Workshop (gears, levers and pulleys). The robot's language lives in Models/RobotCode.swift.

extension RobotCmd {
    var icon: String {
        switch self {
        case .forward: return "arrow.up"
        case .left: return "arrow.turn.up.left"
        case .right: return "arrow.turn.up.right"
        }
    }

    var label: String {
        switch self {
        case .forward: return "Forward"
        case .left: return "Turn left"
        case .right: return "Turn right"
        }
    }

    var color: Color {
        switch self {
        case .forward: return Color(hex: 0x34C77B)
        case .left: return Color(hex: 0x4D96FF)
        case .right: return Color(hex: 0xFF7A59)
        }
    }
}

private enum ClubColors {
    static let loop = Color(hex: 0xFFF4C2)
    static let loopEdge = Color(hex: 0xFFB020)
    static let sensor = Color(hex: 0xD6F5EF)
    static let sensorEdge = Color(hex: 0x1FA58A)
    static let active = Color(hex: 0xFFD93D)
}

// MARK: - Picker

struct CodeClubView: View {
    @EnvironmentObject var store: GameStore
    /// Team Robot Code: a kid and a grown-up take turns adding blocks (pair programming).
    var team: Bool = false
    var onBack: () -> Void
    var onEarn: (Int) -> Void

    private enum Open: Equatable {
        case code(CodeChallenge)
        case machine(MachinePuzzle)
        var key: Int {
            switch self {
            case .code(let c): return c.id
            case .machine(let m): return m.id
            }
        }
    }

    @State private var open: Open?

    private let intro = "Welcome to Code Club! Program your robot to reach the star. Each puzzle teaches a new coding idea. Then visit the Machine Workshop to build with gears, levers and pulleys!"

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE0F2FF), Color(hex: 0xF3ECFF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            switch open {
            case .code(let c):
                CodeChallengeView(challenge: c, team: team,
                                  onBack: { open = nil },
                                  onSolved: { stars in award(c.id, stars) },
                                  onNext: { next in open = .code(next) })
                    .id(c.id)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .machine(let m):
                MachineWorkshopView(puzzle: m,
                                    onBack: { open = nil },
                                    onSolved: { stars in award(m.id, stars) },
                                    onNext: { next in open = .machine(next) })
                    .id(m.id)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case nil:
                list.transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: open?.key)
        .onAppear { Narrator.shared.say(intro) }
        .onDisappear { Narrator.shared.stop() }
    }

    /// Only improvements earn stars, so replays can't farm them.
    private func award(_ id: Int, _ stars: Int) {
        let before = store.profile?.codeBest[id] ?? 0
        onEarn(max(0, stars - before))
        store.recordCode(challenge: id, stars: stars)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    CircleIconButton(systemName: "house.fill", label: "Back", action: onBack)
                    Spacer()
                    SpeakButton { Narrator.shared.say(intro) }
                }
                HStack(spacing: 8) {
                    ArtImage("icon_code").frame(width: 66, height: 66)
                    Text(team ? "Team Robot Code" : "Code Club")
                        .font(.kid(team ? 30 : 36, .black))
                        .foregroundStyle(Palette.purple)
                }
                if team {
                    Text("⭐ and 💜 take turns adding one block each. Real coders do this too: it's called pair programming!")
                        .font(.kid(15, .bold)).foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 12) {
                    ArtImage("robot_full").frame(width: 56, height: 62)
                    Text("Robots follow code one step at a time. Can you write the shortest code?")
                        .font(.kid(16, .semibold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))

                sectionTitle("🤖 Robot code")
                ForEach(Array(CodeChallenge.all.enumerated()), id: \.element.id) { i, c in
                    let isOpen = i == 0 || store.profile?.codeBest[CodeChallenge.all[i - 1].id] != nil
                    card(number: i + 1, title: c.title, topic: c.sensors ? "📡 " + c.topic : c.topic,
                         best: store.profile?.codeBest[c.id] ?? 0, open: isOpen, colorIndex: i) { open = .code(c) }
                }

                sectionTitle("⚙️ Machine Workshop")
                Text("Simple machines help people lift and move heavy things. Build with gears, levers and pulleys!")
                    .font(.kid(15, .semibold)).foregroundStyle(Palette.ink.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(MachinePuzzle.all.enumerated()), id: \.element.id) { i, m in
                    let isOpen = i == 0 || store.profile?.codeBest[MachinePuzzle.all[i - 1].id] != nil
                    card(number: i + 1, title: m.title, topic: Self.topic(m),
                         best: store.profile?.codeBest[m.id] ?? 0, open: isOpen, colorIndex: i + 2) { open = .machine(m) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
    }

    private static func topic(_ m: MachinePuzzle) -> String {
        switch m.kind {
        case .gears: return "Gears"
        case .lever: return "Levers"
        case .pulley: return "Pulleys"
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.kid(22, .black)).foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    private func card(number: Int, title: String, topic: String, best: Int, open: Bool, colorIndex: Int,
                      action: @escaping () -> Void) -> some View {
        let colors: [UInt32] = [0x34C77B, 0x4D96FF, 0xFFB020, 0xFF7A59, 0xB983FF, 0x1FA58A]
        let color = Color(hex: colors[colorIndex % colors.count])
        return Button {
            guard open else {
                Haptics.bump(.oops)
                Narrator.shared.say("Finish the puzzle before this one to open it!")
                return
            }
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Text("\(number)")
                    .font(.kid(26, .black))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.kid(21, .black)).foregroundStyle(.white)
                    Text(topic).font(.kid(13, .bold)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                if open {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { s in
                            ArtImage("goal_star").frame(width: 22, height: 22).opacity(s < best ? 1 : 0.3)
                        }
                    }
                } else {
                    ArtImage("level_lock").frame(width: 34, height: 34)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(open ? color : Color.gray.opacity(0.45))
                .shadow(color: (open ? color : .gray).opacity(0.6), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(open ? "Puzzle \(number): \(title), \(best) stars" : "Puzzle \(number) is locked")
    }
}

// MARK: - One robot puzzle

struct CodeChallengeView: View {
    let challenge: CodeChallenge
    /// Pair programming: players take turns adding blocks.
    var team = false
    var onBack: () -> Void
    var onSolved: (Int) -> Void
    var onNext: (CodeChallenge) -> Void

    @State private var program: [RobotBlock] = []
    /// Open containers, outermost first: new blocks go into the last one.
    @State private var cursor: [UUID] = []
    /// True when new blocks go into the open If's "else" part.
    @State private var inElse = false
    @State private var mapIndex = 0
    @State private var mapResults: [Bool?]
    @State private var robot: RobotCell
    @State private var angle: Double
    @State private var trail: [RobotCell] = []
    @State private var gotGears: Set<RobotCell> = []
    @State private var running = false
    @State private var active: Set<UUID> = []
    @State private var sensed: Bool?
    @State private var message: String?
    @State private var mistakes = 0
    @State private var solvedStars: Int?
    @State private var starBounce = false
    @State private var gearSpin = false
    /// Team mode: whose turn it is (0 ⭐, 1 💜), and who added each block.
    @State private var turn = 0
    @State private var owners: [UUID: Int] = [:]
    /// The running program's animation, so leaving the puzzle stops it (and it can't award stars afterwards).
    @State private var runTask: Task<Void, Never>?
    /// The program before the last block was removed (for Undo).
    @State private var undoProgram: [RobotBlock]?

    private let maxPieces = 14

    init(challenge: CodeChallenge, team: Bool = false, onBack: @escaping () -> Void, onSolved: @escaping (Int) -> Void, onNext: @escaping (CodeChallenge) -> Void) {
        self.challenge = challenge
        self.team = team
        self.onBack = onBack
        self.onSolved = onSolved
        self.onNext = onNext
        let first = challenge.maps[0]
        _robot = State(initialValue: first.start)
        _angle = State(initialValue: Double(first.dir) * 90)
        _mapResults = State(initialValue: Array(repeating: nil, count: challenge.maps.count))
    }

    private var world: RobotWorld { challenge.maps[mapIndex] }
    private var pieces: Int { program.pieces }
    private var openBlock: RobotBlock? { cursor.last.flatMap { program.find($0) } }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    header
                    Text(message ?? challenge.lesson)
                        .font(.kid(15, .bold))
                        .foregroundStyle(message == nil ? Palette.ink.opacity(0.85) : Palette.purple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 54)
                        .animation(.easeInOut, value: message)
                    if challenge.maps.count > 1 { mapTabs }
                    grid
                    programStrip
                    palette
                    HStack(spacing: 12) {
                        BigButton(title: "Clear", color: Color(hex: 0x9AA0AE)) {
                            guard !running else { return }
                            withAnimation { program.removeAll(); cursor = []; inElse = false; owners = [:]; turn = 0 }
                            reset(map: 0)
                            mapResults = Array(repeating: nil, count: challenge.maps.count)
                        }
                        BigButton(title: running ? "Running…" : "Run ▶", color: Palette.green) { run() }
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.top, 6)
                .padding(.bottom, 16)
            }

            if let stars = solvedStars {
                Color.black.opacity(0.4).ignoresSafeArea()
                solvedCard(stars)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: solvedStars)
        .onAppear {
            trail = [world.start]
            Narrator.shared.say(challenge.lesson + (team ? " Team tip: take turns adding blocks, and talk it over before you press Run!" : ""))
        }
        .onDisappear {
            runTask?.cancel()
            Narrator.shared.stop()
        }
    }

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", label: "Back to puzzles", action: onBack)
            Spacer()
            VStack(spacing: 2) {
                Text(challenge.title).font(.kid(24, .black)).foregroundStyle(Palette.ink)
                if team {
                    Text(turn == 0 ? "⭐'s turn to add a block" : "💜's turn to add a block")
                        .font(.kid(13, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(turn == 0 ? Color(hex: 0xE0A800) : Palette.purple))
                        .contentTransition(.opacity)
                        .accessibilityLabel(turn == 0 ? "Star player's turn" : "Heart player's turn")
                }
            }
            .animation(.easeInOut, value: turn)
            Spacer()
            VStack(spacing: 0) {
                Text("\(pieces)/\(challenge.blockLimit)")
                    .font(.kid(17, .black))
                    .foregroundStyle(pieces <= challenge.blockLimit ? Palette.green : Color(hex: 0xFF7A59))
                    .contentTransition(.numericText())
                Text("blocks").font(.kid(10, .bold)).foregroundStyle(Palette.ink.opacity(0.6))
            }
            .frame(width: 56, height: 48)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.9)))
            .accessibilityLabel("\(pieces) blocks used. Aim for \(challenge.blockLimit) or fewer.")
        }
        .padding(.horizontal, 14)
    }

    // MARK: Maps

    private var mapTabs: some View {
        VStack(spacing: 4) {
        Text("One program, \(challenge.maps.count) maps:").font(.kid(13, .bold)).foregroundStyle(Palette.ink.opacity(0.7))
        HStack(spacing: 8) {
            ForEach(challenge.maps.indices, id: \.self) { i in
                Button {
                    guard !running else { return }
                    Haptics.tap()
                    reset(map: i)
                } label: {
                    HStack(spacing: 3) {
                        Text("Map \(i + 1)").font(.kid(14, .black))
                        if let r = mapResults[i] { Text(r ? "✓" : "✗").font(.kid(14, .black)) }
                    }
                    .foregroundStyle(i == mapIndex ? .white : Palette.ink)
                    .padding(.horizontal, 14).frame(minHeight: 44)
                    .background(Capsule().fill(i == mapIndex ? Palette.purple : .white.opacity(0.9)))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Map \(i + 1)\(mapResults[i] == true ? ", solved" : mapResults[i] == false ? ", not solved yet" : "")")
            }
        }
        }
        .padding(.horizontal, 14)
    }

    // MARK: Grid

    private var grid: some View {
        let n = CodeChallenge.size
        let cell: CGFloat = challenge.maps.count > 1 ? 46 : 50
        let gap: CGFloat = 4
        let step = cell + gap
        let w = world
        return ZStack(alignment: .topLeading) {
            VStack(spacing: gap) {
                ForEach(0..<n, id: \.self) { y in
                    HStack(spacing: gap) {
                        ForEach(0..<n, id: \.self) { x in
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill((x + y) % 2 == 0 ? Color(hex: 0xF6F0FF) : Color(hex: 0xEADFFF))
                                .overlay {
                                    if trail.contains(RobotCell(x: x, y: y)) {
                                        Circle().fill(Palette.purple.opacity(0.35)).frame(width: 10, height: 10)
                                    }
                                }
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            ForEach(Array(w.rocks), id: \.self) { r in
                ArtImage("code_rock")
                    .frame(width: cell * 0.9, height: cell * 0.9)
                    .frame(width: cell, height: cell)
                    .offset(x: CGFloat(r.x) * step, y: CGFloat(r.y) * step)
                    .accessibilityLabel("Rock")
            }
            ForEach(Array(w.gears.subtracting(gotGears)), id: \.self) { g in
                ArtImage("robot_gear")
                    .frame(width: cell * 0.62, height: cell * 0.62)
                    .rotationEffect(.degrees(gearSpin ? 360 : 0))
                    .frame(width: cell, height: cell)
                    .offset(x: CGFloat(g.x) * step, y: CGFloat(g.y) * step)
                    .transition(.scale(scale: 1.8).combined(with: .opacity))
                    .accessibilityLabel("Gear")
            }
            ArtImage("goal_star")
                .frame(width: cell * 0.85, height: cell * 0.85)
                .scaleEffect(starBounce ? 1.08 : 0.92)
                .opacity(challenge.needsGears && gotGears.count < w.gears.count ? 0.45 : 1)
                .frame(width: cell, height: cell)
                .offset(x: CGFloat(w.goal.x) * step, y: CGFloat(w.goal.y) * step)
            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color(hex: 0xFFB020))
                    .offset(y: -cell * 0.52)
                    .rotationEffect(.degrees(angle))
                ArtImage("robot_full")
                    .frame(width: cell * 0.84, height: cell * 0.92)
                if let s = sensed {
                    // the sensor's answer pops up over the robot
                    Text(s ? "🧱!" : "👀✓")
                        .font(.kid(13, .black))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(.white))
                        .offset(y: -cell * 0.62)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel(s ? "Blocked" : "The way is clear")
                }
            }
            .frame(width: cell, height: cell)
            .offset(x: CGFloat(robot.x) * step, y: CGFloat(robot.y) * step)
            .animation(.spring(response: 0.33, dampingFraction: 0.65), value: robot)
            .animation(.easeInOut(duration: 0.28), value: angle)
            .animation(.spring(response: 0.25), value: sensed)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: 0xC9B8F5))
                .shadow(color: Color(hex: 0x9B86E0), radius: 0, x: 0, y: 6)
        )
        .animation(.spring(), value: gotGears)
        .animation(.easeInOut(duration: 0.25), value: mapIndex)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { starBounce = true }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { gearSpin = true }
        }
    }

    // MARK: Program

    private var programStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if program.isEmpty {
                        Text("Your code goes here")
                            .font(.kid(14, .semibold))
                            .foregroundStyle(Palette.ink.opacity(0.45))
                            .padding(.horizontal, 12)
                    }
                    ForEach(program) { block in
                        RobotBlockChip(block: block, active: active, cursor: cursor, inElse: inElse, actions: chipActions, owners: owners)
                    }
                    Color.clear.frame(width: 1).id("end")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .overlay(alignment: .topTrailing) {
                if let previous = undoProgram {
                    Button {
                        Haptics.tap()
                        withAnimation(.spring()) { program = previous; undoProgram = nil; cursor = []; inElse = false }
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .font(.kid(14, .black)).foregroundStyle(.white)
                            .padding(.horizontal, 12).frame(minHeight: 44)
                            .background(Capsule().fill(Palette.purple))
                    }
                    .offset(y: -30)
                    .transition(.scale.combined(with: .opacity))
                    .task(id: previous.count) {
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        withAnimation { undoProgram = nil }
                    }
                    .accessibilityLabel("Undo, put the block back")
                }
            }
            .frame(minHeight: 70)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.85)))
            .padding(.horizontal, 14)
            .onChange(of: pieces) { _, _ in withAnimation { proxy.scrollTo("end") } }
        }
    }

    private var chipActions: RobotBlockChip.Actions {
        RobotBlockChip.Actions(
            remove: { id in
                guard !running else { return }
                Haptics.tap()
                undoProgram = program
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { _ = program.remove(id) }
                if let i = cursor.firstIndex(of: id) { cursor = Array(cursor.prefix(i)); inElse = false }
            },
            cycleTimes: { id in
                guard !running else { return }
                Haptics.tap(.pop)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    _ = program.update(id) { b in
                        if case .repeatTimes(let n) = b.kind { b.kind = .repeatTimes(n >= 5 ? 2 : n + 1) }
                    }
                }
            },
            open: { id in
                guard !running else { return }
                Haptics.tap()
                cursor = path(to: id)
                inElse = false
            })
    }

    /// The containers to open so that `id` is the innermost one.
    private func path(to id: UUID) -> [UUID] {
        for b in program {
            if b.id == id { return [id] }
            if b.body.contains(where: { $0.id == id }) || b.elseBody.contains(where: { $0.id == id }) { return [b.id, id] }
        }
        return []
    }

    private var palette: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(RobotCmd.allCases.sorted { order($0) < order($1) }, id: \.self) { cmd in
                    Button { insert(.step(cmd)) } label: {
                        VStack(spacing: 2) {
                            Image(systemName: cmd.icon).font(.system(size: 22, weight: .black))
                            Text(cmd.label).font(.kid(11, .heavy)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cmd.color)
                            .shadow(color: cmd.color.opacity(0.6), radius: 0, x: 0, y: 5))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel(cursor.isEmpty ? "Add step: \(cmd.label)" : "Add inside the open block: \(cmd.label)")
                }
            }
            HStack(spacing: 8) {
                ForEach(controls, id: \.title) { c in
                    Button {
                        guard !running else { return }
                        Haptics.tap(.pop)
                        c.action()
                    } label: {
                        Text(c.title)
                            .font(.kid(14, .black))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.fill)
                                .shadow(color: c.edge.opacity(0.7), radius: 0, x: 0, y: 4))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.edge, lineWidth: c.outlined ? 3 : 0))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel(c.spoken)
                }
            }
        }
        .padding(.horizontal, 14)
    }

    private func order(_ c: RobotCmd) -> Int { c == .left ? 0 : c == .forward ? 1 : 2 }

    private struct Control {
        let title: String
        let spoken: String
        let fill: Color
        let edge: Color
        var outlined = false
        let action: () -> Void
    }

    /// Container buttons change with what's open: start a block, switch to else, or finish it.
    private var controls: [Control] {
        var out: [Control] = []
        let loopFill = Color(hex: 0xFFD93D)
        if let open = openBlock {
            if challenge.sensors && open.isLoop {
                out.append(Control(title: "If blocked 🧱", spoken: "Add an If blocked block inside the loop",
                                   fill: ClubColors.sensor, edge: ClubColors.sensorEdge) { insertContainer(RobotBlock(.ifBlocked)) })
            }
            if open.isIf && !inElse {
                out.append(Control(title: "Otherwise ➜", spoken: "Else: now add what to do when the way is clear",
                                   fill: ClubColors.sensor, edge: ClubColors.sensorEdge, outlined: true) {
                    inElse = true
                    say("Now add what the robot does when the way is clear.")
                })
            }
            out.append(Control(title: open.isIf ? "Done with If ✓" : "Done with loop ✓", spoken: open.isIf ? "Finish the If block" : "Finish the repeat block",
                               fill: open.isIf ? ClubColors.sensor : ClubColors.loop,
                               edge: open.isIf ? ClubColors.sensorEdge : ClubColors.loopEdge, outlined: true) { closeInnermost() })
        } else {
            out.append(Control(title: "Repeat ×", spoken: "Add a repeat block", fill: loopFill, edge: Color(hex: 0xE0A800)) {
                insertContainer(RobotBlock(.repeatTimes(2)))
                say("Now add the steps to repeat. Tap times two to change how many times.")
            })
            if challenge.sensors {
                out.append(Control(title: "Until ⭐", spoken: "Add a repeat until star block", fill: loopFill, edge: Color(hex: 0xE0A800)) {
                    insertContainer(RobotBlock(.repeatUntilGoal))
                    say("The steps inside will repeat until the robot is on the star.")
                })
                out.append(Control(title: "If blocked 🧱", spoken: "Add an If blocked block",
                                   fill: ClubColors.sensor, edge: ClubColors.sensorEdge) {
                    insertContainer(RobotBlock(.ifBlocked))
                    say("Add what the robot does if a rock or wall is ahead. Then tap Otherwise.")
                })
            }
        }
        return out
    }

    private func say(_ text: String) {
        message = text
        Narrator.shared.say(text)
    }

    private func insert(_ block: RobotBlock) {
        guard !running else { return }
        guard pieces + block.pieces <= maxPieces else {
            say("That's a lot of blocks! Can a Repeat block make it shorter?")
            return
        }
        Haptics.tap(.pop)
        if team {
            owners[block.id] = turn
            turn = 1 - turn
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let open = cursor.last {
                _ = program.update(open) { c in
                    if c.isIf && inElse { c.elseBody.append(block) } else { c.body.append(block) }
                }
            } else {
                program.append(block)
            }
        }
    }

    private func insertContainer(_ block: RobotBlock) {
        let before = pieces
        insert(block)
        guard pieces > before else { return }
        cursor.append(block.id)
        inElse = false
    }

    /// Finishes the innermost open block. An empty one does nothing, so it's dropped.
    private func closeInnermost() {
        guard let id = cursor.popLast() else { return }
        inElse = false
        if let b = program.find(id), b.body.isEmpty && b.elseBody.isEmpty {
            withAnimation { _ = program.remove(id) }
        }
        message = nil
    }

    // MARK: Running

    private func reset(map: Int) {
        mapIndex = map
        let w = challenge.maps[map]
        robot = w.start
        angle = Double(w.dir) * 90
        trail = [w.start]
        gotGears = []
        active = []
        sensed = nil
        message = nil
    }

    private func run() {
        guard !running, !program.isEmpty else { return }
        cursor = []
        inElse = false
        program = program.withoutEmptyContainers()
        guard !program.isEmpty else { return }
        running = true
        let traces = challenge.runAll(program)
        mapResults = Array(repeating: nil, count: challenge.maps.count)
        undoProgram = nil
        runTask = Task { @MainActor in
            for (i, trace) in traces.enumerated() {
                reset(map: i)
                guard await pause(250_000_000) else { return }
                for step in trace.steps {
                    active = Set(step.path)
                    guard await pause(380_000_000) else { return }
                    sensed = nil
                    switch step.event {
                    case .moved(let gear):
                        SoundFX.shared.play(.hop, volume: 0.6)
                        robot = step.robot
                        trail.append(step.robot)
                        if gear {
                            gotGears.insert(step.robot)
                            Haptics.success(.coin)
                        }
                    case .turned(let cmd):
                        SoundFX.shared.play(.tap)
                        angle += cmd == .left ? -90 : 90
                    case .sensed(let blocked):
                        SoundFX.shared.play(.beep, volume: 0.4)
                        sensed = blocked
                    case .bonked:
                        Haptics.bump()
                    }
                }
                guard await pause(300_000_000) else { return }
                sensed = nil
                mapResults[i] = trace.solved
                if !trace.solved {
                    running = false
                    active = []
                    mistakes += 1
                    let prefix = challenge.maps.count > 1 ? "Map \(i + 1): " : ""
                    say(prefix + Self.explain(trace.outcome))
                    return
                }
                if i + 1 < traces.count {
                    SoundFX.shared.play(.chime)
                    guard await pause(450_000_000) else { return }
                }
            }
            guard !Task.isCancelled else { return }
            running = false
            active = []
            finish(gears: traces.first?.gears ?? [])
        }
    }

    /// Waits; false if the child left the puzzle meanwhile.
    private func pause(_ ns: UInt64) async -> Bool {
        try? await Task.sleep(nanoseconds: ns)
        return !Task.isCancelled
    }

    private static func explain(_ outcome: RobotTrace.Outcome) -> String {
        switch outcome {
        case .reachedGoal: return "You did it!"
        case .bonkedWall: return "Bonk! The robot bumped the wall. Look at the highlighted block!"
        case .bonkedRock: return "Bonk! A rock is in the way. Find a path around it!"
        case .stoppedShort: return "So close! The robot stopped before the star. Add or change a block."
        case .passedGoal: return "Zoomed past the star! The robot has to stop ON it. Can a sensor block help?"
        case .missingGears: return "You made it back, but some gears are still out there. Collect them all!"
        case .wentInCircles: return "The robot is going around in circles! Check which way it turns."
        }
    }

    private func finish(gears: Set<RobotCell>) {
        var stars = 1
        if pieces <= challenge.blockLimit { stars += 1 }
        let bonusGears = challenge.maps.count == 1 && !challenge.needsGears && !challenge.maps[0].gears.isEmpty
        if bonusGears {
            if gears.count == challenge.maps[0].gears.count { stars += 1 }
        } else if mistakes == 0 {
            stars += 1
        }
        Haptics.success(.fanfare)
        solvedStars = stars
        onSolved(stars)
    }

    private func solvedCard(_ stars: Int) -> some View {
        let next = CodeChallenge.all.firstIndex { $0.id == challenge.id }.flatMap { i in
            i + 1 < CodeChallenge.all.count ? CodeChallenge.all[i + 1] : nil
        }
        let bonusGears = challenge.maps.count == 1 && !challenge.needsGears && !challenge.maps[0].gears.isEmpty
        return VStack(spacing: 14) {
            RobotDrawing(built: Set(RobotLabView.Part.allCases), size: 130, happy: true, dancing: true)
            Text("Code complete!").font(.kid(30, .black)).foregroundStyle(Palette.purple)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    ArtImage("goal_star").frame(width: 40, height: 40).opacity(i < stars ? 1 : 0.25)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                tick(true, challenge.maps.count > 1 ? "Solved all \(challenge.maps.count) maps" : "Reached the star")
                tick(pieces <= challenge.blockLimit, "Used \(pieces) blocks (goal: \(challenge.blockLimit) or fewer)")
                if bonusGears {
                    tick(gotGears.count == challenge.maps[0].gears.count, "Collected every gear")
                } else {
                    tick(mistakes == 0, "Worked on the first try")
                }
            }
            HStack(spacing: 12) {
                BigButton(title: "Try again", color: Palette.purple) {
                    solvedStars = nil
                    mistakes = 0
                    reset(map: 0)
                    mapResults = Array(repeating: nil, count: challenge.maps.count)
                }
                if let next {
                    BigButton(title: "Next ➜", color: Palette.green) { onNext(next) }
                } else {
                    BigButton(title: "Done 🎉", color: Palette.green) { onBack() }
                }
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
        .padding(18)
        .onAppear {
            Narrator.shared.say(stars == 3 ? "Perfect code! Three stars!" : "Your code works! You earned \(stars) stars. Can you make it even shorter?")
        }
    }

    private func tick(_ ok: Bool, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(ok ? Palette.green : Palette.ink.opacity(0.3))
            Text(text).font(.kid(15, .semibold)).foregroundStyle(Palette.ink)
        }
    }
}

// MARK: - A block in the program strip

/// Draws one block. Loops and ifs draw the blocks inside them, so this view nests.
struct RobotBlockChip: View {
    struct Actions {
        var remove: (UUID) -> Void
        var cycleTimes: (UUID) -> Void
        var open: (UUID) -> Void
    }

    let block: RobotBlock
    let active: Set<UUID>
    let cursor: [UUID]
    let inElse: Bool
    let actions: Actions
    /// Team mode: who added each block (0 ⭐, 1 💜).
    var owners: [UUID: Int] = [:]
    var small = false

    private var isActive: Bool { active.contains(block.id) }
    private var isOpen: Bool { cursor.last == block.id }

    var body: some View {
        switch block.kind {
        case .step(let cmd):
            Button { actions.remove(block.id) } label: {
                Image(systemName: cmd.icon)
                    .font(.system(size: small ? 14 : 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: small ? 38 : 42, height: small ? 40 : 46)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(cmd.color))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(ClubColors.active, lineWidth: isActive ? 4 : 0))
                    .scaleEffect(isActive ? 1.12 : 1)
                    .overlay(alignment: .topTrailing) { ownerBadge }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel("\(cmd.label)\(ownerSpoken). Tap to remove.")
        case .repeatTimes, .repeatUntilGoal:
            container(fill: ClubColors.loop, edge: ClubColors.loopEdge) {
                loopHeader
                children(block.body, openHere: isOpen)
            }
        case .ifBlocked:
            container(fill: ClubColors.sensor, edge: ClubColors.sensorEdge) {
                Button { actions.open(block.id) } label: {
                    VStack(spacing: 0) {
                        Text("if").font(.kid(12, .black))
                        Text("🧱").font(.system(size: 16))
                    }
                    .foregroundStyle(ClubColors.sensorEdge)
                    .frame(width: 44, height: 46)
                }
                .accessibilityLabel("If blocked. Tap to add blocks inside.")
                children(block.body, openHere: isOpen && !inElse)
                Text("else").font(.kid(12, .black)).foregroundStyle(ClubColors.sensorEdge)
                    .padding(.horizontal, 2)
                children(block.elseBody, openHere: isOpen && inElse)
            }
        }
    }

    @ViewBuilder
    private var loopHeader: some View {
        if case .repeatTimes(let n) = block.kind {
            Button { if isOpen { actions.cycleTimes(block.id) } else { actions.open(block.id); actions.cycleTimes(block.id) } } label: {
                VStack(spacing: 0) {
                    ArtImage("icon_loop").frame(width: 22, height: 22)
                    Text("×\(n)").font(.kid(14, .black)).foregroundStyle(Palette.ink)
                }
                .frame(width: 42, height: 50)
            }
            .accessibilityLabel("Repeat \(n) times. Tap to change.")
        } else {
            Button { actions.open(block.id) } label: {
                VStack(spacing: 0) {
                    ArtImage("icon_loop").frame(width: 22, height: 22)
                    Text("until ⭐").font(.kid(11, .black)).foregroundStyle(Palette.ink)
                }
                .frame(width: 48, height: 50)
            }
            .accessibilityLabel("Repeat until on the star. Tap to add blocks inside.")
        }
    }

    @ViewBuilder
    private var ownerBadge: some View {
        if let who = owners[block.id] {
            Text(who == 0 ? "⭐" : "💜").font(.system(size: 11)).offset(x: 4, y: -4)
        }
    }

    private var ownerSpoken: String {
        guard let who = owners[block.id] else { return "" }
        return who == 0 ? ", added by the star player" : ", added by the heart player"
    }

    private func children(_ blocks: [RobotBlock], openHere: Bool) -> some View {
        HStack(spacing: 5) {
            ForEach(blocks) { b in
                AnyView(RobotBlockChip(block: b, active: active, cursor: cursor, inElse: inElse, actions: actions, owners: owners, small: true))
            }
            if openHere {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .foregroundStyle(ClubColors.loopEdge)
                    .frame(width: 30, height: 34)
                    .accessibilityLabel("New blocks go here")
            }
        }
    }

    private func container<Content: View>(fill: Color, edge: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 5) {
            content()
            Button { actions.remove(block.id) } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundStyle(Palette.ink.opacity(0.4))
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Delete this block")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .overlay(alignment: .topLeading) { ownerBadge.offset(x: -4, y: -4) }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isActive ? ClubColors.active : edge, lineWidth: isActive || isOpen ? 4 : 2))
        .transition(.scale.combined(with: .opacity))
    }
}
