import SwiftUI

/// A Code Club puzzle: get the robot to the star on a 6×6 grid.
struct CodeChallenge: Identifiable {
    typealias Cell = RobotLabView.Cell

    let id: Int
    let title: String
    /// The idea this puzzle teaches, read aloud when it opens.
    let lesson: String
    let start: Cell
    /// 0 up, 1 right, 2 down, 3 left
    let dir: Int
    let goal: Cell
    let rocks: Set<Cell>
    let gears: Set<Cell>
    /// When true, the robot must pick up every gear before the star counts.
    let needsGears: Bool
    /// Bonus star for solving it with this many blocks or fewer.
    let blockLimit: Int

    static let size = 6

    static let all: [CodeChallenge] = [
        CodeChallenge(id: 401, title: "Loop Launch",
                      lesson: "Meet the Repeat block! It runs the steps inside it again and again. Coders call that a loop. Can you reach the star with just two blocks?",
                      start: Cell(x: 0, y: 5), dir: 0, goal: Cell(x: 0, y: 0),
                      rocks: [], gears: [], needsGears: false, blockLimit: 2),
        CodeChallenge(id: 402, title: "Corner Turn",
                      lesson: "Use a loop to go up, turn, then another loop to go across. Grab the gears on the way for a bonus star!",
                      start: Cell(x: 0, y: 5), dir: 0, goal: Cell(x: 4, y: 1),
                      rocks: [Cell(x: 2, y: 3), Cell(x: 3, y: 4)], gears: [Cell(x: 0, y: 2), Cell(x: 3, y: 1)],
                      needsGears: false, blockLimit: 5),
        CodeChallenge(id: 403, title: "Staircase",
                      lesson: "See a pattern? Forward, turn left, forward, turn right... and again! Put the whole pattern inside one Repeat block.",
                      start: Cell(x: 0, y: 5), dir: 1, goal: Cell(x: 3, y: 2),
                      rocks: [Cell(x: 2, y: 5), Cell(x: 0, y: 3), Cell(x: 3, y: 4)], gears: [Cell(x: 1, y: 4), Cell(x: 3, y: 3)],
                      needsGears: false, blockLimit: 5),
        CodeChallenge(id: 404, title: "Rock Garden",
                      lesson: "Rocks are in the way! Plan a path around them. Engineers call planning steps an algorithm.",
                      start: Cell(x: 0, y: 2), dir: 1, goal: Cell(x: 5, y: 2),
                      rocks: [Cell(x: 2, y: 2), Cell(x: 3, y: 2), Cell(x: 2, y: 1), Cell(x: 3, y: 1)],
                      gears: [Cell(x: 1, y: 3), Cell(x: 4, y: 3)], needsGears: false, blockLimit: 10),
        CodeChallenge(id: 405, title: "Square Dance",
                      lesson: "Collect all three gears and come back to the star. Hint: a square has four sides that are all the same!",
                      start: Cell(x: 1, y: 4), dir: 0, goal: Cell(x: 1, y: 4),
                      rocks: [Cell(x: 2, y: 2), Cell(x: 3, y: 3)],
                      gears: [Cell(x: 1, y: 1), Cell(x: 4, y: 1), Cell(x: 4, y: 4)], needsGears: true, blockLimit: 5)
    ]
}

/// One block in the kid's program: a single step, or a Repeat loop with steps inside.
struct CodeBlock: Identifiable, Equatable {
    let id = UUID()
    var cmd: RobotLabView.Cmd?
    var times = 2
    var body: [RobotLabView.Cmd] = []

    var isLoop: Bool { cmd == nil }
    /// Each step counts as one block, a loop counts as one plus what's inside it.
    var pieces: Int { isLoop ? 1 + body.count : 1 }
}

// MARK: - Picker

struct CodeClubView: View {
    @EnvironmentObject var store: GameStore
    var onBack: () -> Void
    var onEarn: (Int) -> Void

    @State private var playing: CodeChallenge?

    private let intro = "Welcome to Code Club! Program your robot to reach the star. Each puzzle teaches a new coding idea."

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE0F2FF), Color(hex: 0xF3ECFF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let playing {
                CodeChallengeView(challenge: playing,
                                  onBack: { self.playing = nil },
                                  onSolved: { stars in
                                      // only improvements earn stars, so replays can't farm them
                                      let before = store.profile?.codeBest[playing.id] ?? 0
                                      onEarn(max(0, stars - before))
                                      store.recordCode(challenge: playing.id, stars: stars)
                                  },
                                  onNext: { next in self.playing = next })
                    .id(playing.id)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                list
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: playing?.id)
        .onAppear { Narrator.shared.say(intro) }
        .onDisappear { Narrator.shared.stop() }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    CircleIconButton(systemName: "house.fill", label: "Back to map", action: onBack)
                    Spacer()
                    SpeakButton { Narrator.shared.say(intro) }
                }
                HStack(spacing: 8) {
                    ArtImage("icon_code").frame(width: 66, height: 66)
                    Text("Code Club")
                        .font(.kid(36, .black))
                        .foregroundStyle(Palette.purple)
                }
                HStack(spacing: 12) {
                    ArtImage("robot_full").frame(width: 56, height: 62)
                    Text("Robots follow code one step at a time. Can you write the shortest code?")
                        .font(.kid(16, .semibold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.85)))

                ForEach(Array(CodeChallenge.all.enumerated()), id: \.element.id) { i, c in
                    card(c, index: i)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
    }

    private func unlocked(_ index: Int) -> Bool {
        index == 0 || store.profile?.codeBest[CodeChallenge.all[index - 1].id] != nil
    }

    private func card(_ c: CodeChallenge, index: Int) -> some View {
        let best = store.profile?.codeBest[c.id] ?? 0
        let open = unlocked(index)
        let colors: [UInt32] = [0x34C77B, 0x4D96FF, 0xFFB020, 0xFF7A59, 0xB983FF]
        let color = Color(hex: colors[index % colors.count])
        return Button {
            guard open else {
                Haptics.bump(.oops)
                Narrator.shared.say("Finish the puzzle before this one to open it!")
                return
            }
            Haptics.tap()
            playing = c
        } label: {
            HStack(spacing: 14) {
                Text("\(index + 1)")
                    .font(.kid(26, .black))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white))
                VStack(alignment: .leading, spacing: 3) {
                    Text(c.title).font(.kid(21, .black)).foregroundStyle(.white)
                    Text(index == 0 ? "Loops" : index == 2 ? "Patterns" : index == 3 ? "Planning" : index == 4 ? "Shapes + loops" : "Loops + turns")
                        .font(.kid(13, .bold)).foregroundStyle(.white.opacity(0.9))
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
        .accessibilityLabel(open ? "Puzzle \(index + 1): \(c.title), \(best) stars" : "Puzzle \(index + 1) is locked")
    }
}

// MARK: - One puzzle

struct CodeChallengeView: View {
    typealias Cmd = RobotLabView.Cmd
    typealias Cell = RobotLabView.Cell

    let challenge: CodeChallenge
    var onBack: () -> Void
    var onSolved: (Int) -> Void
    var onNext: (CodeChallenge) -> Void

    @State private var program: [CodeBlock] = []
    @State private var openLoop: UUID?
    @State private var robot: Cell
    @State private var dir: Int
    @State private var angle: Double
    @State private var trail: [Cell] = []
    @State private var gotGears: Set<Cell> = []
    @State private var running = false
    @State private var activeBlock: UUID?
    @State private var activeInner: Int?
    @State private var message: String?
    @State private var mistakes = 0
    @State private var solvedStars: Int?
    @State private var starBounce = false
    @State private var gearSpin = false

    private let maxPieces = 14

    init(challenge: CodeChallenge, onBack: @escaping () -> Void, onSolved: @escaping (Int) -> Void, onNext: @escaping (CodeChallenge) -> Void) {
        self.challenge = challenge
        self.onBack = onBack
        self.onSolved = onSolved
        self.onNext = onNext
        _robot = State(initialValue: challenge.start)
        _dir = State(initialValue: challenge.dir)
        _angle = State(initialValue: Double(challenge.dir) * 90)
    }

    private var pieces: Int { program.reduce(0) { $0 + $1.pieces } }

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                header
                Text(message ?? challenge.lesson)
                    .font(.kid(15, .bold))
                    .foregroundStyle(message == nil ? Palette.ink.opacity(0.85) : Palette.purple)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 60)
                    .animation(.easeInOut, value: message)
                grid
                programStrip
                palette
                HStack(spacing: 12) {
                    BigButton(title: "Clear", color: Color(hex: 0x9AA0AE)) {
                        guard !running else { return }
                        withAnimation { program.removeAll(); openLoop = nil }
                        reset()
                    }
                    BigButton(title: running ? "Running…" : "Run ▶", color: Palette.green) { run() }
                }
                .padding(.horizontal, 22)
                Spacer(minLength: 0)
            }
            .padding(.top, 6)

            if let stars = solvedStars {
                Color.black.opacity(0.4).ignoresSafeArea()
                solvedCard(stars)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: solvedStars)
        .onAppear {
            trail = [challenge.start]
            Narrator.shared.say(challenge.lesson)
        }
    }

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", label: "Back to puzzles", action: onBack)
            Spacer()
            Text(challenge.title).font(.kid(24, .black)).foregroundStyle(Palette.ink)
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

    // MARK: Grid

    private var grid: some View {
        let n = CodeChallenge.size
        let cell: CGFloat = 50
        let gap: CGFloat = 4
        let step = cell + gap
        return ZStack(alignment: .topLeading) {
            VStack(spacing: gap) {
                ForEach(0..<n, id: \.self) { y in
                    HStack(spacing: gap) {
                        ForEach(0..<n, id: \.self) { x in
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill((x + y) % 2 == 0 ? Color(hex: 0xF6F0FF) : Color(hex: 0xEADFFF))
                                .overlay {
                                    if trail.contains(Cell(x: x, y: y)) {
                                        Circle().fill(Palette.purple.opacity(0.35)).frame(width: 10, height: 10)
                                    }
                                }
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            ForEach(Array(challenge.rocks), id: \.self) { r in
                ArtImage("code_rock")
                    .frame(width: cell * 0.9, height: cell * 0.9)
                    .frame(width: cell, height: cell)
                    .offset(x: CGFloat(r.x) * step, y: CGFloat(r.y) * step)
                    .accessibilityLabel("Rock")
            }
            ForEach(Array(challenge.gears.subtracting(gotGears)), id: \.self) { g in
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
                .opacity(challenge.needsGears && gotGears.count < challenge.gears.count ? 0.45 : 1)
                .frame(width: cell, height: cell)
                .offset(x: CGFloat(challenge.goal.x) * step, y: CGFloat(challenge.goal.y) * step)
            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color(hex: 0xFFB020))
                    .offset(y: -cell * 0.52)
                    .rotationEffect(.degrees(angle))
                ArtImage("robot_full")
                    .frame(width: cell * 0.84, height: cell * 0.92)
            }
            .frame(width: cell, height: cell)
            .offset(x: CGFloat(robot.x) * step, y: CGFloat(robot.y) * step)
            .animation(.spring(response: 0.33, dampingFraction: 0.65), value: robot)
            .animation(.easeInOut(duration: 0.28), value: angle)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: 0xC9B8F5))
                .shadow(color: Color(hex: 0x9B86E0), radius: 0, x: 0, y: 6)
        )
        .animation(.spring(), value: gotGears)
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
                        if block.isLoop {
                            loopChip(block)
                        } else if let cmd = block.cmd {
                            stepChip(cmd, active: activeBlock == block.id) {
                                guard !running else { return }
                                withAnimation { program.removeAll { $0.id == block.id } }
                            }
                            .accessibilityLabel("\(cmd.label). Tap to remove.")
                        }
                    }
                    Color.clear.frame(width: 1).id("end")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 70)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.85)))
            .padding(.horizontal, 14)
            .onChange(of: pieces) { _, _ in withAnimation { proxy.scrollTo("end") } }
        }
    }

    private func stepChip(_ cmd: Cmd, active: Bool, small: Bool = false, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Image(systemName: cmd.icon)
                .font(.system(size: small ? 14 : 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: small ? 34 : 42, height: small ? 34 : 46)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(cmd.color))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color(hex: 0xFFD93D), lineWidth: active ? 4 : 0))
                .scaleEffect(active ? 1.12 : 1)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func loopChip(_ block: CodeBlock) -> some View {
        let isOpen = openLoop == block.id
        let isActive = activeBlock == block.id
        return HStack(spacing: 5) {
            Button {
                guard !running else { return }
                Haptics.tap(.pop)
                update(block.id) { $0.times = $0.times >= 5 ? 2 : $0.times + 1 }
            } label: {
                VStack(spacing: 0) {
                    ArtImage("icon_loop").frame(width: 22, height: 22)
                    Text("×\(block.times)").font(.kid(14, .black)).foregroundStyle(Palette.ink)
                }
                .frame(width: 42, height: 50)
            }
            .accessibilityLabel("Repeat \(block.times) times. Tap to change.")
            ForEach(Array(block.body.enumerated()), id: \.offset) { i, cmd in
                stepChip(cmd, active: isActive && activeInner == i, small: true) {
                    guard !running else { return }
                    update(block.id) { _ = $0.body.remove(at: i) }
                }
                .accessibilityLabel("Inside repeat: \(cmd.label). Tap to remove.")
            }
            if isOpen {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .foregroundStyle(Color(hex: 0xFFB020))
                    .frame(width: 30, height: 34)
            }
            Button {
                guard !running else { return }
                withAnimation {
                    program.removeAll { $0.id == block.id }
                    if openLoop == block.id { openLoop = nil }
                }
            } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(Palette.ink.opacity(0.35))
            }
            .accessibilityLabel("Delete this repeat block")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: 0xFFF4C2)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isActive ? Color(hex: 0xFFD93D) : Color(hex: 0xFFB020), lineWidth: isActive ? 4 : 2))
        .transition(.scale.combined(with: .opacity))
    }

    private func update(_ id: UUID, _ change: (inout CodeBlock) -> Void) {
        guard let i = program.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { change(&program[i]) }
    }

    private var palette: some View {
        HStack(spacing: 8) {
            ForEach([Cmd.left, .forward, .right]) { cmd in
                Button { add(cmd) } label: {
                    VStack(spacing: 2) {
                        Image(systemName: cmd.icon).font(.system(size: 22, weight: .black))
                        Text(cmd.label).font(.kid(11, .heavy)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cmd.color)
                        .shadow(color: cmd.color.opacity(0.6), radius: 0, x: 0, y: 5))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(openLoop == nil ? "Add step: \(cmd.label)" : "Add inside repeat: \(cmd.label)")
            }
            Button(action: toggleLoop) {
                VStack(spacing: 2) {
                    ArtImage("icon_loop").frame(width: 26, height: 26)
                    Text(openLoop == nil ? "Repeat" : "End repeat").font(.kid(11, .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                }
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: openLoop == nil ? 0xFFD93D : 0xFFF4C2))
                    .shadow(color: Color(hex: 0xE0A800).opacity(0.7), radius: 0, x: 0, y: 5))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xFFB020), lineWidth: openLoop == nil ? 0 : 3))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel(openLoop == nil ? "Add a repeat block" : "Finish the repeat block")
        }
        .padding(.horizontal, 14)
    }

    private func add(_ cmd: Cmd) {
        guard !running else { return }
        guard pieces < maxPieces else {
            message = "That's a lot of blocks! Can a Repeat block make it shorter?"
            Narrator.shared.say(message ?? "")
            return
        }
        Haptics.tap(.pop)
        if let id = openLoop {
            update(id) { $0.body.append(cmd) }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { program.append(CodeBlock(cmd: cmd)) }
        }
    }

    private func toggleLoop() {
        guard !running else { return }
        Haptics.tap(.pop)
        if let id = openLoop {
            openLoop = nil
            // an empty loop does nothing, so drop it
            if program.first(where: { $0.id == id })?.body.isEmpty == true {
                withAnimation { program.removeAll { $0.id == id } }
            }
        } else {
            guard pieces < maxPieces else { return }
            let loop = CodeBlock(cmd: nil)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { program.append(loop) }
            openLoop = loop.id
            message = "Now add the steps to repeat. Tap ×2 to change how many times. Tap End repeat when you're done."
            Narrator.shared.say("Now add the steps to repeat. Tap times two to change how many times.")
        }
    }

    // MARK: Running

    private func reset() {
        robot = challenge.start
        dir = challenge.dir
        angle = Double(challenge.dir) * 90
        trail = [challenge.start]
        gotGears = []
        activeBlock = nil
        activeInner = nil
        message = nil
    }

    private var solved: Bool {
        robot == challenge.goal && (!challenge.needsGears || gotGears.count == challenge.gears.count)
    }

    private func run() {
        guard !running, !program.isEmpty else { return }
        openLoop = nil
        program.removeAll { $0.isLoop && $0.body.isEmpty }
        reset()
        running = true
        let steps = flatten(program)
        Task { @MainActor in
            for (cmd, blockID, inner) in steps {
                activeBlock = blockID
                activeInner = inner
                try? await Task.sleep(nanoseconds: 420_000_000)
                switch cmd {
                case .forward:
                    let moves = [(0, -1), (1, 0), (0, 1), (-1, 0)]
                    let next = Cell(x: robot.x + moves[dir].0, y: robot.y + moves[dir].1)
                    let n = CodeChallenge.size
                    guard (0..<n).contains(next.x), (0..<n).contains(next.y) else {
                        fail("Bonk! The robot bumped the wall. Look at the highlighted block!")
                        return
                    }
                    guard !challenge.rocks.contains(next) else {
                        fail("Bonk! A rock is in the way. Find a path around it!")
                        return
                    }
                    SoundFX.shared.play(.hop, volume: 0.6)
                    robot = next
                    trail.append(next)
                    if challenge.gears.contains(next) && !gotGears.contains(next) {
                        gotGears.insert(next)
                        Haptics.success(.coin)
                    }
                case .left:
                    SoundFX.shared.play(.tap)
                    dir = (dir + 3) % 4
                    angle -= 90
                case .right:
                    SoundFX.shared.play(.tap)
                    dir = (dir + 1) % 4
                    angle += 90
                }
                if solved { break }
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            running = false
            activeBlock = nil
            activeInner = nil
            if solved {
                finish()
            } else if robot == challenge.goal && challenge.needsGears {
                mistakes += 1
                message = "You made it back, but some gears are still out there. Collect them all!"
                Narrator.shared.say(message ?? "")
            } else {
                mistakes += 1
                message = "So close! The robot stopped before the star. Add or change a block."
                Narrator.shared.say(message ?? "")
            }
        }
    }

    /// The program as single steps: (command, block id, index inside a loop).
    private func flatten(_ blocks: [CodeBlock]) -> [(Cmd, UUID, Int?)] {
        var steps: [(Cmd, UUID, Int?)] = []
        for b in blocks {
            if let c = b.cmd {
                steps.append((c, b.id, nil))
            } else {
                for _ in 0..<b.times {
                    for (i, c) in b.body.enumerated() { steps.append((c, b.id, i)) }
                }
            }
        }
        return steps
    }

    private func fail(_ text: String) {
        Haptics.bump()
        mistakes += 1
        message = text
        Narrator.shared.say(text)
        running = false
    }

    private func finish() {
        var stars = 1
        if pieces <= challenge.blockLimit { stars += 1 }
        if challenge.gears.isEmpty || challenge.needsGears {
            if mistakes == 0 { stars += 1 }
        } else if gotGears.count == challenge.gears.count {
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
        return VStack(spacing: 14) {
            RobotDrawing(built: Set(RobotLabView.Part.allCases), size: 130, happy: true, dancing: true)
            Text("Code complete!").font(.kid(30, .black)).foregroundStyle(Palette.purple)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    ArtImage("goal_star").frame(width: 40, height: 40).opacity(i < stars ? 1 : 0.25)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                tick(true, "Reached the star")
                tick(pieces <= challenge.blockLimit, "Used \(pieces) blocks (goal: \(challenge.blockLimit) or fewer)")
                if !challenge.gears.isEmpty && !challenge.needsGears {
                    tick(gotGears.count == challenge.gears.count, "Collected every gear")
                } else {
                    tick(mistakes == 0, "Worked on the first try")
                }
            }
            HStack(spacing: 12) {
                BigButton(title: "Try again", color: Palette.purple) {
                    solvedStars = nil
                    mistakes = 0
                    reset()
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
