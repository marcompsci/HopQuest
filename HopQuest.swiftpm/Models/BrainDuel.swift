import Foundation

// Brain Duels: two live players answer the same five questions; correct answers score, quick ones score a bit more.
// Everything here is plain Foundation so it can be tested anywhere.

/// One duel question, small enough to send between phones.
struct DuelQuestion: Codable, Equatable {
    var subject: String
    var prompt: String
    var choices: [String]
    var answer: Int
}

struct DuelAnswer: Codable, Equatable {
    var duelID: String
    var player: String
    var index: Int
    var choice: Int        // -1 = ran out of time
    var ms: Int
}

struct DuelSetup: Codable, Equatable {
    var duelID: String
    var players: [String]
    var questions: [DuelQuestion]
}

struct BrainDuel: Equatable {
    static let questionCount = 5
    static let secondsPerQuestion = 20
    let setup: DuelSetup
    private(set) var answers: [String: [Int: DuelAnswer]] = [:]

    init(setup: DuelSetup) { self.setup = setup }

    /// Records an answer. Ignores duplicates, strangers and out-of-range values.
    @discardableResult
    mutating func record(_ a: DuelAnswer) -> Bool {
        guard a.duelID == setup.duelID, setup.players.contains(a.player),
              setup.questions.indices.contains(a.index), answers[a.player]?[a.index] == nil else { return false }
        var clean = a
        clean.choice = (-1..<setup.questions[a.index].choices.count).contains(a.choice) ? a.choice : -1
        clean.ms = min(max(0, a.ms), Self.secondsPerQuestion * 1000)
        answers[a.player, default: [:]][a.index] = clean
        return true
    }

    func answered(_ player: String) -> Int { answers[player]?.count ?? 0 }

    /// 10 for a right answer, plus up to 5 for answering fast (within 5 seconds).
    static func points(correct: Bool, ms: Int) -> Int {
        guard correct else { return 0 }
        return 10 + max(0, 5 - ms / 1000)
    }

    func score(_ player: String) -> Int {
        (answers[player] ?? [:]).values.reduce(0) { sum, a in
            sum + Self.points(correct: a.choice == setup.questions[a.index].answer, ms: a.ms)
        }
    }

    func correctCount(_ player: String) -> Int {
        (answers[player] ?? [:]).values.filter { $0.choice == setup.questions[$0.index].answer }.count
    }

    var isFinished: Bool { setup.players.allSatisfy { answered($0) == setup.questions.count } }

    /// Winners (more than one means a tie).
    var winners: [String] {
        let best = setup.players.map(score).max() ?? 0
        return setup.players.filter { score($0) == best }
    }

    /// Stars for a finished duel: winning gives 2, a tie gives each player 1, a good try gives 1.
    func stars(for player: String) -> Int {
        guard isFinished, setup.players.contains(player) else { return 0 }
        if winners.count > 1 { return 1 }
        return winners.first == player ? 2 : 1
    }
}

// MARK: - Messages between phones

/// Hello from a player: who they are in the village. Never carries anything personal beyond a short nickname.
struct PeerHello: Codable, Equatable {
    var key: String
    var nick: String
    var characterID: String
    var version: Int
}

struct PeerMove: Codable, Equatable {
    var key: String
    var x: Double
    var y: Double
    var facing: Facing
    var moving: Bool
}

struct DuelInvite: Codable, Equatable {
    var duelID: String
    var from: String
    var to: String
}

struct DuelReply: Codable, Equatable {
    var duelID: String
    var from: String
    var accepted: Bool
}

/// Everything phones say to each other. There is no chat and no free text.
enum VillageNetMessage: Codable, Equatable {
    case hello(PeerHello)
    case move(PeerMove)
    case invite(DuelInvite)
    case reply(DuelReply)
    case start(DuelSetup)
    case answer(DuelAnswer)
    case leave(String)

    static let maxBytes = 16_000
    static let protocolVersion = 1

    func encoded() -> Data? { try? JSONEncoder().encode(self) }

    /// Decodes and cleans a message from another phone. Returns nil for anything malformed or out of bounds.
    static func decode(_ data: Data, validCharacters: Set<String>, mapSize: (w: Int, h: Int)) -> VillageNetMessage? {
        guard data.count <= maxBytes, let m = try? JSONDecoder().decode(VillageNetMessage.self, from: data) else { return nil }
        func key(_ k: String) -> String? { (1...24).contains(k.count) && k.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" } ? k : nil }
        switch m {
        case .hello(var h):
            guard let k = key(h.key), validCharacters.contains(h.characterID) else { return nil }
            h.key = k
            h.nick = cleanNick(h.nick)
            return .hello(h)
        case .move(var mv):
            guard key(mv.key) != nil, mv.x.isFinite, mv.y.isFinite else { return nil }
            mv.x = min(max(0, mv.x), Double(mapSize.w))
            mv.y = min(max(0, mv.y), Double(mapSize.h))
            return .move(mv)
        case .invite(let i):
            guard key(i.duelID) != nil, key(i.from) != nil, key(i.to) != nil else { return nil }
            return m
        case .reply(let r):
            guard key(r.duelID) != nil, key(r.from) != nil else { return nil }
            return m
        case .start(var s):
            guard key(s.duelID) != nil, s.players.count == 2, s.players.allSatisfy({ key($0) != nil }),
                  s.questions.count == BrainDuel.questionCount else { return nil }
            for i in s.questions.indices {
                var q = s.questions[i]
                guard (2...4).contains(q.choices.count), q.choices.indices.contains(q.answer) else { return nil }
                q.prompt = String(q.prompt.prefix(200))
                q.choices = q.choices.map { String($0.prefix(60)) }
                q.subject = String(q.subject.prefix(20))
                s.questions[i] = q
            }
            return .start(s)
        case .answer(let a):
            guard key(a.duelID) != nil, key(a.player) != nil else { return nil }
            return m
        case .leave(let k):
            return key(k) == nil ? nil : m
        }
    }

    /// Letters, numbers and spaces only, at most 12 characters.
    static func cleanNick(_ s: String) -> String {
        let kept = s.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let trimmed = String(kept.prefix(12)).trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Buddy" : trimmed
    }
}

/// Another live player's buddy, smoothed between network updates.
struct RemotePeer: Equatable {
    var key: String
    var nick: String
    var characterID: String
    var target: VPoint
    var shown: VPoint
    var facing: Facing = .south
    var moving = false
    var stride: Double = 0
    var lastHeard: Double = 0

    init(hello: PeerHello, at p: VPoint) {
        key = hello.key
        nick = hello.nick
        characterID = hello.characterID
        target = p
        shown = p
    }

    mutating func apply(_ m: PeerMove, now: Double) {
        let jump = VPoint(m.x, m.y).distance(to: shown) > 6
        target = VPoint(m.x, m.y)
        if jump { shown = target }        // a door or a long gap: snap rather than slide through walls
        facing = m.facing
        moving = m.moving
        lastHeard = now
    }

    /// Glides toward the last known spot (frame-rate independent).
    mutating func advance(dt: Double) {
        let d = target - shown
        let k = 1 - exp(-10 * dt)
        let step = d * k
        shown = shown + step
        stride += step.length
    }
}
