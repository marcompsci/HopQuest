import SwiftUI

// MARK: - Challenge board

/// The challenges, with "Take me there" so kids can walk straight to each building.
struct VillageChallengeBoard: View {
    let progress: ChallengeProgress
    let isOpen: (VillageChallenge) -> Bool
    var onGo: (BuildingKind) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Village Challenges").font(.kid(24, .black)).foregroundStyle(Palette.ink)
                    Text(progress.allDone ? "All done! Your castle is open! 🏰"
                                          : "Finish all \(ChallengeProgress.total) to open your castle")
                        .font(.kid(14, .bold)).foregroundStyle(Palette.purple)
                }
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            }
            ProgressView(value: Double(progress.doneCount), total: Double(ChallengeProgress.total))
                .tint(Palette.green)
                .scaleEffect(x: 1, y: 2.4)
                .padding(.vertical, 4)
                .accessibilityLabel("\(progress.doneCount) of \(ChallengeProgress.total) challenges done")
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(VillageChallenge.allCases, id: \.self) { c in
                        row(c)
                    }
                }
            }
            .frame(maxHeight: 430)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 16)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private func row(_ c: VillageChallenge) -> some View {
        let done = c.isDone(progress)
        let open = isOpen(c)
        return HStack(spacing: 12) {
            Text(c.icon).font(.system(size: 30))
                .frame(width: 44, height: 44)
                .background(Circle().fill(done ? Color(hex: 0xFFE9A8) : Color(hex: 0xF1F2F5)))
            VStack(alignment: .leading, spacing: 1) {
                Text(c.title).font(.kid(17, .black)).foregroundStyle(Palette.ink)
                Text(done ? "Done! ⭐" : (open ? c.goal : "Opens later in your adventure"))
                    .font(.kid(13, .bold)).foregroundStyle(done ? Palette.green : .secondary)
            }
            Spacer()
            if done {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Palette.green)
            } else if open {
                Button {
                    Haptics.tap()
                    onGo(c.building)
                } label: {
                    Text("Go!").font(.kid(15, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Capsule().fill(Palette.purple))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Walk to \(c.title)")
            } else {
                Image(systemName: "lock.fill").foregroundStyle(.gray)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xFAFAFC)))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Castle opening

struct CastleOpenView: View {
    let theme: CastleTheme
    let name: String
    var onGo: () -> Void

    @State private var pop = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🎉 You did it, \(name)! 🎉").font(.kid(26, .black)).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                CastleView(theme: theme, width: 220)
                    .scaleEffect(pop ? 1 : 0.6)
                Text("Every challenge is done.\nYour castle is open!")
                    .font(.kid(20, .bold)).foregroundStyle(.white).multilineTextAlignment(.center)
                BigButton(title: "Go to my castle", color: Palette.purple, action: onGo)
                    .padding(.horizontal, 30)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { pop = true }
            Haptics.success(.fanfare)
            Narrator.shared.say("You did it, \(name)! Every challenge is done. Your castle is open!")
        }
    }
}

// MARK: - Live play

/// Small capsule showing who's here (nearby or online).
struct LivePlayPill: View {
    let status: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: count > 0 ? "person.2.fill" : "antenna.radiowaves.left.and.right")
            Text(count > 0 ? "\(count) friend\(count == 1 ? "" : "s") in the village · walk up to duel!" : status)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .font(.kid(13, .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(Color(hex: 0x4D96FF).opacity(0.92)))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }
}

struct DuelInviteCard: View {
    let nick: String
    var onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("⚔️🧠").font(.system(size: 44))
            Text("\(nick) wants a Brain Duel!").font(.kid(22, .black)).foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text("5 questions about the games you've played. Fast answers score extra!")
                .font(.kid(15, .bold)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button { onAnswer(false) } label: {
                    Text("Not now").font(.kid(18, .black)).foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xEDEFF3)))
                }
                Button { onAnswer(true) } label: {
                    Text("Let's duel!").font(.kid(18, .black)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.green))
                }
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 22)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .onAppear { Narrator.shared.say("\(nick) wants a Brain Duel!") }
    }
}

/// A Brain Duel in progress: one question at a time with a timer, then the results.
struct BrainDuelView: View {
    @ObservedObject var network: VillageNetwork
    /// Stars actually given for this duel (after the daily cap), set by the parent when the duel finishes.
    let starsGiven: Int?
    var onClose: () -> Void

    @State private var shownIndex = -1
    @State private var startedAt = Date()
    @State private var secondsLeft = BrainDuel.secondsPerQuestion
    @State private var picked: Int?
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var me: String { network.myKey }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            if let duel = network.duel {
                VStack(spacing: 14) {
                    header(duel)
                    if duel.isFinished {
                        results(duel)
                    } else if duel.answered(me) < duel.setup.questions.count {
                        question(duel, index: duel.answered(me))
                    } else {
                        VStack(spacing: 10) {
                            ProgressView().scaleEffect(1.5)
                            Text("Waiting for \(network.opponentNick)…").font(.kid(19, .black)).foregroundStyle(Palette.ink)
                        }
                        .padding(.vertical, 30)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
                .padding(.horizontal, 16)
            }
        }
        .onReceive(tick) { _ in
            guard let duel = network.duel, !duel.isFinished, duel.answered(me) < duel.setup.questions.count, picked == nil else { return }
            secondsLeft -= 1
            if secondsLeft <= 0 { submit(-1, index: duel.answered(me)) }
        }
    }

    private func header(_ duel: BrainDuel) -> some View {
        let opp = duel.setup.players.first { $0 != me } ?? ""
        return HStack {
            scoreChip("You", duel.score(me), Palette.purple)
            Spacer()
            Text("⚔️").font(.system(size: 30))
            Spacer()
            scoreChip(network.opponentNick, duel.score(opp), Color(hex: 0xFF7A59))
        }
    }

    private func scoreChip(_ name: String, _ score: Int, _ color: Color) -> some View {
        VStack(spacing: 0) {
            Text(name).font(.kid(14, .black)).lineLimit(1)
            Text("\(score)").font(.kid(26, .black))
        }
        .foregroundStyle(.white)
        .frame(width: 110, height: 64)
        .background(RoundedRectangle(cornerRadius: 18).fill(color))
    }

    @ViewBuilder
    private func question(_ duel: BrainDuel, index: Int) -> some View {
        let q = duel.setup.questions[index]
        VStack(spacing: 12) {
            HStack {
                Text("Question \(index + 1) of \(duel.setup.questions.count)").font(.kid(14, .bold)).foregroundStyle(.secondary)
                Spacer()
                Label("\(secondsLeft)", systemImage: "timer").font(.kid(16, .black))
                    .foregroundStyle(secondsLeft <= 5 ? Palette.red : Palette.ink)
            }
            Text(q.prompt).font(.kid(21, .black)).foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                Button { submit(i, index: index) } label: {
                    Text(choice).font(.kid(19, .black)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: [0x4D96FF, 0xFF7A59, 0x34C77B, 0xB983FF][i % 4]))
                            .opacity(picked == nil || picked == i ? 1 : 0.4))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(picked != nil)
            }
        }
        .onAppear { prepare(index, q) }
        .onChange(of: index) { _, newIndex in prepare(newIndex, duel.setup.questions[newIndex]) }
    }

    private func prepare(_ index: Int, _ q: DuelQuestion) {
        guard shownIndex != index else { return }
        shownIndex = index
        picked = nil
        startedAt = Date()
        secondsLeft = BrainDuel.secondsPerQuestion
        Narrator.shared.say(q.prompt)
    }

    private func submit(_ choice: Int, index: Int) {
        guard picked == nil else { return }
        picked = choice
        let ms = Int(Date().timeIntervalSince(startedAt) * 1000)
        if let duel = network.duel, choice >= 0 {
            if choice == duel.setup.questions[index].answer { Haptics.success(.correct) } else { Haptics.bump(.oops) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            network.answer(index: index, choice: choice, ms: ms)
            picked = nil
        }
    }

    private func results(_ duel: BrainDuel) -> some View {
        let won = duel.winners == [me]
        let tie = duel.winners.count > 1
        let title = tie ? "It's a tie! 🤝" : (won ? "You won! 🏆" : "Good game! 🌟")
        return VStack(spacing: 12) {
            Text(title).font(.kid(28, .black)).foregroundStyle(Palette.ink)
            Text("You got \(duel.correctCount(me)) of \(duel.setup.questions.count) right.")
                .font(.kid(17, .bold)).foregroundStyle(.secondary)
            if let starsGiven {
                Text(starsGiven > 0 ? "+\(starsGiven) star\(starsGiven == 1 ? "" : "s") ⭐" : "You've earned all of today's duel stars. Great playing!")
                    .font(.kid(18, .black)).foregroundStyle(Palette.purple).multilineTextAlignment(.center)
            }
            BigButton(title: "Back to the village", color: Palette.green, action: onClose)
        }
        .onAppear { Narrator.shared.say(title) }
    }
}

// MARK: - Missions

struct MissionLogView: View {
    let save: MissionSave
    /// Villager missions plus the festivals that are on, started or done.
    let missions: [MissionDef]
    let giverName: (String) -> String
    var onGo: (MissionDef) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Missions 📜").font(.kid(24, .black)).foregroundStyle(Palette.ink)
                    Text("\(missions.filter { save.status($0) == .done }.count) of \(missions.count) done").font(.kid(14, .bold)).foregroundStyle(Palette.purple)
                }
                Spacer()
                CircleIconButton(systemName: "xmark", label: "Close", action: onClose)
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(missions) { m in row(m) }
                }
            }
            .frame(maxHeight: 460)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white).shadow(color: .black.opacity(0.25), radius: 14, y: 6))
        .padding(.horizontal, 16)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private func row(_ m: MissionDef) -> some View {
        let status = save.status(m)
        let giver = giverName(m.giver)
        let text: String
        switch status {
        case .new: text = "Talk to \(giver) to start"
        case .active(let step):
            let progress = save.collectedCount(m).map { " (\($0.have)/\($0.need))" } ?? ""
            text = m.steps[step].hint + progress
        case .readyToTurnIn: text = "Done! Go back to \(giver) for \(m.reward) stars"
        case .done: text = "Finished ⭐"
        }
        return HStack(spacing: 12) {
            Text(m.icon).font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Circle().fill(status == .done ? Color(hex: 0xFFE9A8) : Color(hex: 0xF1F2F5)))
            VStack(alignment: .leading, spacing: 1) {
                Text(m.title).font(.kid(17, .black)).foregroundStyle(Palette.ink)
                Text(text).font(.kid(13, .bold)).foregroundStyle(status == .done ? Palette.green : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if status == .done {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Palette.green)
            } else {
                Button {
                    Haptics.tap()
                    onGo(m)
                } label: {
                    Text("Go!").font(.kid(15, .black)).foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Capsule().fill(Palette.purple))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Walk toward \(m.title)")
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xFAFAFC)))
        .accessibilityElement(children: .combine)
    }
}
