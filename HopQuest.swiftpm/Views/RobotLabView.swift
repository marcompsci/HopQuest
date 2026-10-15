import SwiftUI

/// Robot Lab: build a robot part by part (each part explained like you're 10),
/// then "code" it with arrow commands to reach the star.
/// All art is original (ArtSource/make_robot.py) and matches the buddy characters' style.
struct RobotLabView: View {
    var onExit: () -> Void
    var onComplete: (Int) -> Void
    /// Finish the chapter and jump straight into Code Club.
    var onCodeClub: ((Int) -> Void)? = nil

    enum Part: Int, CaseIterable, Identifiable {
        case chassis, battery, motors, wheels, sensors, brain
        var id: Int { rawValue }

        /// Icon shown on the part card and lesson card.
        var icon: String { "part_\(key)" }
        /// Layer that snaps onto the robot.
        var layer: String { "robot_\(key)" }

        private var key: String {
            switch self {
            case .chassis: return "chassis"
            case .battery: return "battery"
            case .motors: return "motors"
            case .wheels: return "wheels"
            case .sensors: return "sensors"
            case .brain: return "brain"
            }
        }

        var title: String {
            switch self {
            case .chassis: return "Chassis"
            case .battery: return "Battery"
            case .motors: return "Motors"
            case .wheels: return "Wheels"
            case .sensors: return "Sensors"
            case .brain: return "Brain Chip"
            }
        }

        var color: Color {
            switch self {
            case .chassis: return Color(hex: 0x8FD3F4)
            case .battery: return Color(hex: 0x34C77B)
            case .motors: return Color(hex: 0x7C4DFF)
            case .wheels: return Color(hex: 0xFFD93D)
            case .sensors: return Color(hex: 0x5EE6FF)
            case .brain: return Color(hex: 0xFF7FC4)
            }
        }

        var lesson: String {
            switch self {
            case .chassis:
                return "The chassis is the robot's skeleton. It holds every other part in place, just like your bones hold you up."
            case .battery:
                return "The battery stores energy. Robots can't eat sandwiches, so they \"eat\" electricity instead!"
            case .motors:
                return "Motors turn electricity into spinning. They're the robot's muscles."
            case .wheels:
                return "Wheels turn the motor's spin into rolling. Bigger wheels travel farther with each spin!"
            case .sensors:
                return "Sensors are the robot's eyes and ears. This one sends out sound and listens for the echo to find walls — like a bat!"
            case .brain:
                return "The brain is a tiny computer called a microcontroller. It reads the sensors and tells the motors what to do, by following code people write."
            }
        }

        var hint: String {
            switch self {
            case .chassis: return "Every robot starts with a chassis — something to hold all the parts!"
            case .battery: return "The robot needs energy first. What stores energy?"
            case .motors: return "Now it has power. What turns power into movement?"
            case .wheels: return "The motors spin… what turns spinning into rolling?"
            case .sensors: return "It can move! But how will it notice where things are?"
            case .brain: return "Last part: something to think and make decisions!"
            }
        }
    }

    enum Cmd: String, Identifiable {
        case forward, left, right
        var id: String { rawValue }
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

    struct Cell: Hashable { var x: Int; var y: Int }

    private enum Phase { case build, code, done }

    @State private var phase: Phase = .build
    @State private var built: [Part] = []
    @State private var tray: [Part] = Part.allCases.shuffled()
    @State private var lesson: Part?
    @State private var hint: String?
    @State private var buildMistakes = 0
    @State private var wrongPart: Part?
    @State private var shake: CGFloat = 0
    @State private var pop = false

    @State private var program: [Cmd] = []
    @State private var robot = Cell(x: 0, y: 4)
    @State private var dir = 0            // 0 up, 1 right, 2 down, 3 left
    @State private var angle: Double = 0
    @State private var trail: [Cell] = []
    @State private var running = false
    @State private var activeStep: Int?
    @State private var codeMessage: String?
    @State private var codeMistakes = 0
    @State private var starBounce = false

    private let gridSize = 5
    private let start = Cell(x: 0, y: 4)
    private let goal = Cell(x: 3, y: 1)
    private let maxSteps = 10

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE0F2FF), Color(hex: 0xF3ECFF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 10) {
                header
                switch phase {
                case .build: buildPhase
                case .code: codePhase
                case .done: donePhase
                }
            }
            .padding(.top, 6)

            if let lesson {
                Color.black.opacity(0.35).ignoresSafeArea()
                lessonCard(lesson)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: lesson)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase)
        .onAppear { Narrator.shared.say(Self.buildIntro) }
        .onDisappear { Narrator.shared.stop() }
        .onChange(of: lesson) { _, part in
            if let part { Narrator.shared.say("\(part.title)! \(part.lesson)") }
        }
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .build: Narrator.shared.say(Self.buildIntro)
            case .code: Narrator.shared.say(Self.codeIntro)
            case .done: Narrator.shared.say(Self.doneText)
            }
        }
    }

    private static let buildIntro = "Build your robot! Tap the part that goes next."
    private static let codeIntro = "Robots follow instructions one step at a time. That list of steps is called code! Tap the arrows to add steps, then press Run to get the robot to the star."
    private static let doneText = "You're a robot engineer! You built a robot and wrote its code. Real engineers do exactly that!"

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "house.fill", label: "Back to map", action: onExit)
            Spacer()
            HStack(spacing: 6) {
                ArtImage("part_chassis").frame(width: 34, height: 34)
                Text("Robot Lab").font(.kid(26, .black)).foregroundStyle(Palette.ink)
            }
            Spacer()
            stepBadge
        }
        .padding(.horizontal, 14)
    }

    /// 1 Build · 2 Code progress pill.
    private var stepBadge: some View {
        let step = phase == .build ? 1 : 2
        return HStack(spacing: 4) {
            ForEach(1...2, id: \.self) { i in
                Circle()
                    .fill(i <= step ? Palette.purple : Palette.ink.opacity(0.15))
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 48, height: 48)
        .accessibilityLabel(step == 1 ? "Step 1 of 2: build" : "Step 2 of 2: code")
    }

    // MARK: Build

    private var buildPhase: some View {
        VStack(spacing: 12) {
            Text(hint ?? "Tap the part that goes next!")
                .font(.kid(17, .bold))
                .foregroundStyle(hint == nil ? Palette.ink.opacity(0.8) : Palette.purple)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .animation(.easeInOut, value: hint)

            workbench

            HStack(spacing: 6) {
                ForEach(Part.allCases) { part in
                    Capsule()
                        .fill(built.contains(part) ? part.color : Palette.ink.opacity(0.12))
                        .frame(height: 8)
                }
            }
            .padding(.horizontal, 40)
            .animation(.spring(), value: built)
            .accessibilityLabel("Parts: \(built.count) of \(Part.allCases.count)")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(tray) { part in
                    partCard(part)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tray)
            Spacer(minLength: 0)
        }
    }

    /// Blueprint paper with a wooden bench; the robot assembles on top.
    private var workbench: some View {
        ZStack(alignment: .bottom) {
            BlueprintBackground()
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color(hex: 0xB9D3F5), lineWidth: 3))
            // bench top
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color(hex: 0xD9A066), Color(hex: 0xA0673B)], startPoint: .top, endPoint: .bottom))
                .frame(height: 22)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.ink.opacity(0.35), lineWidth: 2))
                .padding(.horizontal, 22)
                .padding(.bottom, 14)
            RobotDrawing(built: Set(built), size: 210, happy: built.count == Part.allCases.count)
                .scaleEffect(pop ? 1.06 : 1, anchor: .bottom)
                .padding(.bottom, 26)
        }
        .frame(height: 270)
        .padding(.horizontal, 16)
    }

    private func partCard(_ part: Part) -> some View {
        Button { add(part) } label: {
            VStack(spacing: 2) {
                ArtImage(part.icon)
                    .frame(width: 70, height: 70)
                Text(part.title)
                    .font(.kid(14, .heavy))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
                    .shadow(color: part.color.opacity(0.55), radius: 0, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(part.color.opacity(0.6), lineWidth: 2)
            )
            .modifier(Shake(animatableData: wrongPart == part ? shake : 0))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Add \(part.title)")
    }

    private func add(_ part: Part) {
        let next = Part.allCases[built.count]
        if part == next {
            Haptics.success(.correct)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                built.append(part)
                tray.removeAll { $0 == part }
            }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pop = false }
            }
            hint = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { lesson = part }
        } else {
            Haptics.bump(.oops)
            buildMistakes += 1
            wrongPart = part
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
            hint = "Hmm, not yet! \(next.hint)"
            Narrator.shared.say("Hmm, not yet! \(next.hint)")
        }
    }

    private func lessonCard(_ part: Part) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                Color.clear.frame(width: 44, height: 44)
                Spacer()
                ZStack {
                    Circle().fill(part.color.opacity(0.25)).frame(width: 130, height: 130)
                    ArtImage(part.icon).frame(width: 104, height: 104)
                }
                Spacer()
                SpeakButton { Narrator.shared.say("\(part.title)! \(part.lesson)") }
            }
            Text(part.title).font(.kid(28, .black)).foregroundStyle(Palette.purple)
            Text(part.lesson)
                .font(.kid(19, .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            BigButton(title: built.count == Part.allCases.count ? "Robot complete! ➜" : "Got it! ➜", color: Palette.green) {
                lesson = nil
                if built.count == Part.allCases.count {
                    phase = .code
                }
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(part.color, lineWidth: 4))
        .padding(24)
    }

    // MARK: Code

    private var codePhase: some View {
        VStack(spacing: 10) {
            Text(codeMessage ?? "Write the code to get your robot to the star!")
                .font(.kid(16, .bold))
                .foregroundStyle(codeMessage == nil ? Palette.ink.opacity(0.85) : Palette.purple)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)

            grid

            programStrip

            HStack(spacing: 10) {
                ForEach([Cmd.left, .forward, .right]) { cmd in
                    Button {
                        guard !running, program.count < maxSteps else { return }
                        Haptics.tap(.pop)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { program.append(cmd) }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: cmd.icon).font(.system(size: 26, weight: .black))
                            Text(cmd.label).font(.kid(12, .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 96, height: 66)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cmd.color)
                            .shadow(color: cmd.color.opacity(0.6), radius: 0, x: 0, y: 5))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Add step: \(cmd.label)")
                }
            }

            HStack(spacing: 12) {
                BigButton(title: "Clear", color: Color(hex: 0x9AA0AE)) {
                    guard !running else { return }
                    withAnimation { program.removeAll() }
                    resetRobot()
                }
                BigButton(title: running ? "Running…" : "Run ▶", color: Palette.green) { runProgram() }
            }
            .padding(.horizontal, 22)
            Spacer(minLength: 0)
        }
    }

    private var programStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if program.isEmpty {
                        Text("Your code goes here")
                            .font(.kid(14, .semibold))
                            .foregroundStyle(Palette.ink.opacity(0.45))
                            .padding(.horizontal, 14)
                    }
                    ForEach(Array(program.enumerated()), id: \.offset) { index, cmd in
                        Button {
                            guard !running else { return }
                            withAnimation { _ = program.remove(at: index) }
                        } label: {
                            VStack(spacing: 0) {
                                Text("\(index + 1)").font(.kid(10, .black)).foregroundStyle(.white.opacity(0.85))
                                Image(systemName: cmd.icon).font(.system(size: 17, weight: .black)).foregroundStyle(.white)
                            }
                            .frame(width: 44, height: 46)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(cmd.color))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(hex: 0xFFD93D), lineWidth: activeStep == index ? 4 : 0))
                            .scaleEffect(activeStep == index ? 1.12 : 1)
                        }
                        .id(index)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Step \(index + 1): \(cmd.label). Tap to remove.")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            .frame(height: 60)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.8)))
            .padding(.horizontal, 16)
            .onChange(of: program.count) { _, n in
                if n > 0 { withAnimation { proxy.scrollTo(n - 1) } }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: activeStep)
        }
    }

    private var grid: some View {
        let cellSize: CGFloat = 56
        let gap: CGFloat = 5
        return ZStack(alignment: .topLeading) {
            VStack(spacing: gap) {
                ForEach(0..<gridSize, id: \.self) { y in
                    HStack(spacing: gap) {
                        ForEach(0..<gridSize, id: \.self) { x in
                            let visited = trail.contains(Cell(x: x, y: y))
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill((x + y) % 2 == 0 ? Color(hex: 0xF6F0FF) : Color(hex: 0xEADFFF))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.9), lineWidth: 2))
                                .overlay {
                                    if visited {
                                        Circle().fill(Palette.purple.opacity(0.35)).frame(width: 12, height: 12)
                                    }
                                }
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            // goal star
            ArtImage("goal_star")
                .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                .scaleEffect(starBounce ? 1.08 : 0.94)
                .frame(width: cellSize, height: cellSize)
                .offset(x: CGFloat(goal.x) * (cellSize + gap), y: CGFloat(goal.y) * (cellSize + gap))
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { starBounce = true }
                }
            // robot (stays upright; the arrow shows which way it faces)
            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(hex: 0xFFB020))
                    .offset(y: -cellSize * 0.5)
                    .rotationEffect(.degrees(angle))
                ArtImage("robot_full")
                    .frame(width: cellSize * 0.86, height: cellSize * 0.94)
            }
            .frame(width: cellSize, height: cellSize)
            .offset(x: CGFloat(robot.x) * (cellSize + gap), y: CGFloat(robot.y) * (cellSize + gap))
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: robot)
            .animation(.easeInOut(duration: 0.3), value: angle)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: 0xC9B8F5))
                .shadow(color: Color(hex: 0x9B86E0), radius: 0, x: 0, y: 6)
        )
    }

    private func resetRobot() {
        robot = start
        dir = 0
        angle = 0
        trail = [start]
        activeStep = nil
        codeMessage = nil
    }

    private func runProgram() {
        guard !running, !program.isEmpty else { return }
        resetRobot()
        running = true
        let steps = program
        Task { @MainActor in
            for (i, cmd) in steps.enumerated() {
                activeStep = i
                try? await Task.sleep(nanoseconds: 480_000_000)
                switch cmd {
                case .forward:
                    let moves = [(0, -1), (1, 0), (0, 1), (-1, 0)]
                    let next = Cell(x: robot.x + moves[dir].0, y: robot.y + moves[dir].1)
                    guard (0..<gridSize).contains(next.x), (0..<gridSize).contains(next.y) else {
                        Haptics.bump()
                        codeMistakes += 1
                        codeMessage = "Bonk! The robot bumped the wall. Check step \(i + 1)! 🧐"
                        Narrator.shared.say("Bonk! The robot bumped the wall. Check step \(i + 1)!")
                        running = false
                        return
                    }
                    SoundFX.shared.play(.hop, volume: 0.6)
                    robot = next
                    trail.append(next)
                case .left:
                    SoundFX.shared.play(.tap)
                    dir = (dir + 3) % 4
                    angle -= 90
                case .right:
                    SoundFX.shared.play(.tap)
                    dir = (dir + 1) % 4
                    angle += 90
                }
                if robot == goal { break }
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            running = false
            activeStep = nil
            if robot == goal {
                Haptics.success(.fanfare)
                phase = .done
            } else {
                codeMistakes += 1
                codeMessage = "So close! The robot stopped before the star. Add or change a step."
                Narrator.shared.say("So close! The robot stopped before the star. Add or change a step.")
            }
        }
    }

    // MARK: Done

    private var donePhase: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFFF4C2), .clear], center: .center, startRadius: 10, endRadius: 150))
                    .frame(width: 300, height: 300)
                RobotDrawing(built: Set(Part.allCases), size: 220, happy: true, dancing: true)
            }
            HStack(spacing: 8) {
                ArtImage("goal_star").frame(width: 36, height: 36)
                Text("Robot Engineer!")
                    .font(.kid(30, .black))
                    .foregroundStyle(Palette.purple)
                ArtImage("goal_star").frame(width: 36, height: 36)
            }
            Text("You built a robot AND wrote its code. Real engineers do exactly that!")
                .font(.kid(18, .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            let stars = 1 + (buildMistakes == 0 ? 1 : 0) + (codeMistakes == 0 ? 1 : 0)
            if let onCodeClub {
                BigButton(title: "More coding: Code Club 🤖", color: Palette.purple) { onCodeClub(stars) }
                    .padding(.horizontal, 24)
            }
            BigButton(title: "Fly to the next adventure 🎈", color: Palette.green) {
                onComplete(stars)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

/// Light blueprint paper with a grid.
struct BlueprintBackground: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xEAF4FF)))
            var minor = Path()
            var x: CGFloat = 0
            while x < size.width { minor.move(to: CGPoint(x: x, y: 0)); minor.addLine(to: CGPoint(x: x, y: size.height)); x += 14 }
            var y: CGFloat = 0
            while y < size.height { minor.move(to: CGPoint(x: 0, y: y)); minor.addLine(to: CGPoint(x: size.width, y: y)); y += 14 }
            ctx.stroke(minor, with: .color(Color(hex: 0xC9DFFA).opacity(0.6)), lineWidth: 1)
            var major = Path()
            x = 0
            while x < size.width { major.move(to: CGPoint(x: x, y: 0)); major.addLine(to: CGPoint(x: x, y: size.height)); x += 70 }
            y = 0
            while y < size.height { major.move(to: CGPoint(x: 0, y: y)); major.addLine(to: CGPoint(x: size.width, y: y)); y += 70 }
            ctx.stroke(major, with: .color(Color(hex: 0xA9C9F2).opacity(0.8)), lineWidth: 1.5)
        }
        .accessibilityHidden(true)
    }
}

/// The robot, assembled from illustrated layers. Missing parts show as a dashed outline;
/// new parts drop in with a bounce, gears spin and the antenna glows once the parts are on.
struct RobotDrawing: View {
    let built: Set<RobotLabView.Part>
    var size: CGFloat = 220
    var happy = false
    var dancing = false

    @State private var spin = false
    @State private var glow = false
    @State private var bob = false

    /// Back-to-front drawing order (not the build order).
    private static let order: [RobotLabView.Part] = [.wheels, .chassis, .motors, .battery, .sensors, .brain]
    private static let gearCenters: [CGPoint] = [CGPoint(x: 112, y: 326), CGPoint(x: 288, y: 326)]

    var body: some View {
        let w = size
        let h = size * 460 / 420
        ZStack {
            ArtImage("robot_ghost")
            ForEach(Self.order) { part in
                if built.contains(part) {
                    ArtImage(part.layer)
                        .transition(.asymmetric(
                            insertion: .offset(y: -h * 0.25).combined(with: .scale(scale: 1.3)).combined(with: .opacity),
                            removal: .opacity))
                }
            }
            if built.contains(.motors) {
                ForEach(0..<2, id: \.self) { i in
                    let c = Self.gearCenters[i]
                    ArtImage("robot_gear")
                        .frame(width: w * 44 / 420, height: w * 44 / 420)
                        .rotationEffect(.degrees(spin ? (i == 0 ? 360 : -360) : 0))
                        .position(x: w * (c.x + 10) / 420, y: h * (c.y + 10) / 460)
                        .transition(.opacity)
                }
            }
            if built.contains(.brain) {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFF7FC4).opacity(0.9), .clear], center: .center,
                                         startRadius: 1, endRadius: w * 0.06))
                    .frame(width: w * 0.12, height: w * 0.12)
                    .opacity(glow ? 1 : 0.2)
                    .position(x: w * (200 + 10) / 420, y: h * (14 + 10) / 460)
                    .allowsHitTesting(false)
            }
            if happy {
                ArtImage("robot_smile").transition(.opacity)
            }
        }
        .frame(width: w, height: h)
        .rotationEffect(.degrees(dancing ? (bob ? 4 : -4) : 0), anchor: .bottom)
        .offset(y: dancing && bob ? -10 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: built)
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { glow = true }
            if dancing {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { bob = true }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Robot with \(built.count) of 6 parts")
    }
}
