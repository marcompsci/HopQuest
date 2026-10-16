import Foundation
import GameKit
import UIKit

/// Online play through Apple's Game Center: friends (invited from Apple's own friend picker) or anyone
/// (Game Center matchmaking). Game Center handles sign-in and respects Screen Time's multiplayer limits.
/// HopQuest sends only positions, buddy choices and duel answers; the nickname is the buddy's name.
///
/// Note: Game Center must be turned on for the app (the Game Center capability in an Xcode project, plus
/// App Store Connect). Until then sign-in fails and this shows a friendly message instead.
final class GameCenterTransport: NSObject, VillageTransport {
    enum Kind { case friends, anyone }

    var onData: ((Data, String) -> Void)?
    var onPeerFound: ((String) -> Void)?
    var onPeerLost: ((String) -> Void)?
    var onStatus: ((String) -> Void)?

    private let kind: Kind
    private var match: GKMatch?
    private var stopped = false

    init(kind: Kind) {
        self.kind = kind
        super.init()
    }

    func start() {
        stopped = false
        onStatus?("Signing in to Game Center…")
        let local = GKLocalPlayer.local
        if local.isAuthenticated {
            ready()
            return
        }
        local.authenticateHandler = { [weak self] viewController, error in
            guard let self, !self.stopped else { return }
            if let viewController {
                TopViewController.find()?.present(viewController, animated: true)
                return
            }
            if error != nil || !GKLocalPlayer.local.isAuthenticated {
                self.onStatus?("Game Center isn't set up for HopQuest yet, so online play is off. Nearby play still works!")
                return
            }
            self.ready()
        }
    }

    private func ready() {
        let local = GKLocalPlayer.local
        if local.isMultiplayerGamingRestricted {
            onStatus?("Online play is turned off in Screen Time.")
            return
        }
        local.register(self)
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        switch kind {
        case .friends:
            onStatus?("Invite a Game Center friend!")
            guard let picker = GKMatchmakerViewController(matchRequest: request) else { return }
            picker.matchmakerDelegate = self
            TopViewController.find()?.present(picker, animated: true)
        case .anyone:
            onStatus?("Finding players…")
            GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
                DispatchQueue.main.async {
                    guard let self, !self.stopped else { return }
                    if let match { self.use(match) } else {
                        self.onStatus?("Couldn't find players right now. Try again in a bit!")
                    }
                }
            }
        }
    }

    private func use(_ m: GKMatch) {
        match = m
        m.delegate = self
        onStatus?(m.players.isEmpty ? "Waiting for players…" : "\(m.players.count) online friend\(m.players.count == 1 ? "" : "s") here")
        for p in m.players { onPeerFound?(p.gamePlayerID) }
    }

    func stop() {
        stopped = true
        GKMatchmaker.shared().cancel()
        match?.disconnect()
        match = nil
        GKLocalPlayer.local.unregisterAllListeners()
    }

    func broadcast(_ data: Data, reliable: Bool) {
        guard let match, !match.players.isEmpty else { return }
        try? match.sendData(toAllPlayers: data, with: reliable ? .reliable : .unreliable)
    }
}

extension GameCenterTransport: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        let id = player.gamePlayerID
        DispatchQueue.main.async { self.onData?(data, id) }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        let id = player.gamePlayerID
        DispatchQueue.main.async {
            switch state {
            case .connected: self.onPeerFound?(id)
            case .disconnected: self.onPeerLost?(id)
            default: break
            }
            self.onStatus?(match.players.isEmpty ? "Waiting for players…" : "\(match.players.count) online here")
        }
    }
}

extension GameCenterTransport: GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        onStatus?("No friends invited yet.")
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        onStatus?("Couldn't reach Game Center right now.")
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        use(match)
    }
}

extension GameCenterTransport: GKLocalPlayerListener {
    /// A Game Center friend invited us: show Apple's screen to join.
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        guard kind == .friends, let picker = GKMatchmakerViewController(invite: invite) else { return }
        picker.matchmakerDelegate = self
        DispatchQueue.main.async { TopViewController.find()?.present(picker, animated: true) }
    }
}
