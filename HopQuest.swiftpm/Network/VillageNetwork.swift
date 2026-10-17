import Foundation
import UIKit

/// Something that moves bytes between phones. Nearby (MultipeerConnectivity) and Game Center both fit this.
/// Callbacks always arrive on the main thread.
protocol VillageTransport: AnyObject {
    var onData: ((Data, String) -> Void)? { get set }
    var onPeerFound: ((String) -> Void)? { get set }
    var onPeerLost: ((String) -> Void)? { get set }
    var onStatus: ((String) -> Void)? { get set }
    func start()
    func stop()
    func broadcast(_ data: Data, reliable: Bool)
}

/// Live play in Hop Village: other players' buddies walking around, and Brain Duels.
/// There is no chat and no free text: phones only exchange positions, buddy choices, short cleaned nicknames,
/// duel questions and answer choices. Used only on the main thread (like GameStore).
final class VillageNetwork: ObservableObject {
    struct PeerSummary: Identifiable, Equatable {
        let id: String
        let nick: String
        let characterID: String
    }

    struct IncomingInvite: Equatable {
        let invite: DuelInvite
        let nick: String
    }

    @Published private(set) var status = ""
    @Published private(set) var roster: [PeerSummary] = []
    @Published var incoming: IncomingInvite?
    @Published private(set) var duel: BrainDuel?
    @Published private(set) var opponentNick = ""
    @Published var notice: String?
    @Published private(set) var waitingFor: String?

    /// Smoothed positions for the scene (not @Published: it changes every frame).
    private(set) var peers: [String: RemotePeer] = [:]

    let myKey: String = "hq" + String(UUID().uuidString.prefix(8)).lowercased().filter { $0.isLetter || $0.isNumber }
    private(set) var mode: VillagePlayMode = .off
    private var transport: VillageTransport?
    private var hello: PeerHello?
    private var transportKeys: [String: String] = [:]      // transport peer id → player key
    private var lastMove: PeerMove?
    private var lastMoveTime = 0.0
    private var lastHelloTime = 0.0
    private var outgoing: DuelInvite?
    private var outgoingTime = 0.0
    private var finishedReported = false
    private let validCharacters = Set(Roster.all.map(\.id))
    private let mapSize = (w: VillageMap.shared.width, h: VillageMap.shared.height)

    /// Builds the five questions when this phone hosts a duel.
    var makeQuestions: (() -> [DuelQuestion])?
    /// Called once when a duel finishes, to give stars.
    var onDuelFinished: ((BrainDuel) -> Void)?

    private var now: Double { ProcessInfo.processInfo.systemUptime }

    var isOn: Bool { transport != nil }

    // MARK: Start / stop

    /// `nick` is always the buddy's name (never the child's), in every mode.
    func start(mode: VillagePlayMode, nick: String, characterID: String) {
        guard mode != self.mode || transport == nil else { updateHello(nick: nick, characterID: characterID); return }
        stop()
        self.mode = mode
        hello = PeerHello(key: myKey, nick: VillageNetMessage.cleanNick(nick), characterID: characterID,
                          version: VillageNetMessage.protocolVersion)
        let t: VillageTransport
        switch mode {
        case .off:
            status = ""
            return
        case .nearby:
            t = NearbyTransport(peerName: myKey)
        case .friends:
            t = GameCenterTransport(kind: .friends)
        }
        t.onData = { [weak self] data, from in self?.received(data, from: from) }
        t.onPeerFound = { [weak self] _ in self?.sendHello() }
        t.onPeerLost = { [weak self] id in self?.lost(transportID: id) }
        t.onStatus = { [weak self] text in self?.status = text }
        transport = t
        t.start()
    }

    func stop() {
        if let hello { send(.leave(hello.key), reliable: true) }
        transport?.stop()
        transport = nil
        mode = .off
        peers = [:]
        transportKeys = [:]
        roster = []
        incoming = nil
        duel = nil
        outgoing = nil
        waitingFor = nil
        status = ""
    }

    func updateHello(nick: String, characterID: String) {
        hello = PeerHello(key: myKey, nick: VillageNetMessage.cleanNick(nick), characterID: characterID,
                          version: VillageNetMessage.protocolVersion)
        sendHello()
    }

    // MARK: Every frame

    /// Sends our position about 8 times a second (only when it changed), and a hello every 4 seconds.
    func publish(position: VPoint, facing: Facing, moving: Bool) {
        guard isOn, let hello else { return }
        let t = now
        if t - lastHelloTime > 4 { sendHello() }
        let move = PeerMove(key: hello.key, x: (position.x * 100).rounded() / 100, y: (position.y * 100).rounded() / 100,
                            facing: facing, moving: moving)
        guard move != lastMove, t - lastMoveTime > 0.12 else { return }
        lastMove = move
        lastMoveTime = t
        send(.move(move), reliable: false)
    }

    /// Glides other players' buddies and forgets anyone silent for 12 seconds.
    func advancePeers(dt: Double) {
        guard !peers.isEmpty else {
            checkInviteTimeout()
            return
        }
        let t = now
        var gone: [String] = []
        for key in peers.keys {
            peers[key]?.advance(dt: dt)
            if let p = peers[key], t - p.lastHeard > 12 { gone.append(key) }
        }
        for key in gone { remove(key) }
        checkInviteTimeout()
    }

    // MARK: Brain Duels

    func challenge(_ key: String) {
        guard isOn, duel == nil, outgoing == nil, incoming == nil, let me = hello?.key, let peer = peers[key] else { return }
        let invite = DuelInvite(duelID: "d" + String(UUID().uuidString.prefix(8)).filter { $0.isLetter || $0.isNumber },
                                from: me, to: key)
        outgoing = invite
        outgoingTime = now
        waitingFor = peer.nick
        send(.invite(invite), reliable: true)
    }

    func respond(accept: Bool) {
        guard let inc = incoming, let me = hello?.key else { return }
        incoming = nil
        send(.reply(DuelReply(duelID: inc.invite.duelID, from: me, accepted: accept)), reliable: true)
        if accept { opponentNick = inc.nick }
    }

    func answer(index: Int, choice: Int, ms: Int) {
        guard var d = duel, let me = hello?.key else { return }
        let a = DuelAnswer(duelID: d.setup.duelID, player: me, index: index, choice: choice, ms: ms)
        if d.record(a) {
            duel = d
            send(.answer(a), reliable: true)
            reportIfFinished()
        }
    }

    /// Close the results (or leave a duel early).
    func endDuel() {
        duel = nil
        finishedReported = false
    }

    // MARK: Receiving

    private func received(_ data: Data, from transportID: String) {
        guard let msg = VillageNetMessage.decode(data, validCharacters: validCharacters, mapSize: mapSize) else { return }
        let t = now
        switch msg {
        case .hello(let h):
            guard h.key != hello?.key else { return }
            transportKeys[transportID] = h.key
            if var p = peers[h.key] {
                p.nick = h.nick
                p.characterID = h.characterID
                p.lastHeard = t
                peers[h.key] = p
            } else {
                var p = RemotePeer(hello: h, at: VillageMap.shared.spawn.center)
                p.lastHeard = t
                peers[h.key] = p
                if peers.count == 1 { sendHello() }   // make sure they know us too
            }
            refreshRoster()
        case .move(let m):
            guard m.key != hello?.key, peers[m.key] != nil else { return }
            peers[m.key]?.apply(m, now: t)
        case .invite(let inv):
            guard inv.to == hello?.key, let from = peers[inv.from] else { return }
            if duel != nil || incoming != nil || outgoing != nil {
                send(.reply(DuelReply(duelID: inv.duelID, from: hello?.key ?? "", accepted: false)), reliable: true)
                return
            }
            incoming = IncomingInvite(invite: inv, nick: from.nick)
        case .reply(let r):
            guard let out = outgoing, r.duelID == out.duelID, r.from == out.to else { return }
            outgoing = nil
            waitingFor = nil
            if r.accepted, let me = hello?.key, let qs = makeQuestions?(), qs.count == BrainDuel.questionCount {
                let setup = DuelSetup(duelID: out.duelID, players: [me, out.to], questions: qs)
                opponentNick = peers[out.to]?.nick ?? "your friend"
                finishedReported = false
                duel = BrainDuel(setup: setup)
                send(.start(setup), reliable: true)
            } else {
                notice = "\(peers[out.to]?.nick ?? "They") can't duel right now. Try again later!"
            }
        case .start(let setup):
            guard let me = hello?.key, setup.players.contains(me), duel == nil else { return }
            finishedReported = false
            duel = BrainDuel(setup: setup)
        case .answer(let a):
            guard var d = duel, a.player != hello?.key else { return }
            if d.record(a) {
                duel = d
                reportIfFinished()
            }
        case .leave(let key):
            remove(key)
        }
    }

    private func reportIfFinished() {
        guard let d = duel, d.isFinished, !finishedReported else { return }
        finishedReported = true
        onDuelFinished?(d)
    }

    private func lost(transportID: String) {
        if let key = transportKeys.removeValue(forKey: transportID) { remove(key) }
    }

    private func remove(_ key: String) {
        guard peers.removeValue(forKey: key) != nil else { return }
        if let d = duel, d.setup.players.contains(key), !d.isFinished {
            duel = nil
            notice = "Your duel buddy left the village. No worries!"
        }
        if incoming?.invite.from == key { incoming = nil }
        if outgoing?.to == key { outgoing = nil; waitingFor = nil }
        refreshRoster()
    }

    private func checkInviteTimeout() {
        if let out = outgoing, now - outgoingTime > 15 {
            outgoing = nil
            waitingFor = nil
            notice = "\(peers[out.to]?.nick ?? "They") didn't answer. Try again later!"
        }
    }

    private func refreshRoster() {
        roster = peers.values.sorted { $0.nick < $1.nick }.map { PeerSummary(id: $0.key, nick: $0.nick, characterID: $0.characterID) }
    }

    private func sendHello() {
        guard let hello else { return }
        lastHelloTime = now
        send(.hello(hello), reliable: true)
        if let lastMove { send(.move(lastMove), reliable: true) }
    }

    private func send(_ msg: VillageNetMessage, reliable: Bool) {
        guard let transport, let data = msg.encoded() else { return }
        transport.broadcast(data, reliable: reliable)
    }
}

/// The view controller to present system screens (Game Center sign-in, friend picker) from.
enum TopViewController {
    static func find() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first
        var top = window?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}
