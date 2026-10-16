import Foundation
import MultipeerConnectivity

/// Nearby play: phones in the same room find each other over Wi-Fi or Bluetooth (no internet, no accounts).
/// The visible peer name is a random code, never the child's name; connections are encrypted.
final class NearbyTransport: NSObject, VillageTransport {
    static let serviceType = "hopq-village"
    static let maxPeers = 7

    var onData: ((Data, String) -> Void)?
    var onPeerFound: ((String) -> Void)?
    var onPeerLost: ((String) -> Void)?
    var onStatus: ((String) -> Void)?

    private let me: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    init(peerName: String) {
        me = MCPeerID(displayName: peerName)
        session = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: me, discoveryInfo: ["v": "\(VillageNetMessage.protocolVersion)"],
                                               serviceType: Self.serviceType)
        browser = MCNearbyServiceBrowser(peer: me, serviceType: Self.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        onStatus?("Looking for friends nearby…")
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    func broadcast(_ data: Data, reliable: Bool) {
        let peers = session.connectedPeers
        guard !peers.isEmpty else { return }
        try? session.send(data, toPeers: peers, with: reliable ? .reliable : .unreliable)
    }

    private func main(_ work: @escaping () -> Void) { DispatchQueue.main.async(execute: work) }

    private func updateStatus() {
        let n = session.connectedPeers.count
        let text = n == 0 ? "Looking for friends nearby…" : (n == 1 ? "1 friend nearby" : "\(n) friends nearby")
        main { self.onStatus?(text) }
    }
}

extension NearbyTransport: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let id = peerID.displayName
        switch state {
        case .connected: main { self.onPeerFound?(id) }
        case .notConnected: main { self.onPeerLost?(id) }
        default: break
        }
        updateStatus()
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let id = peerID.displayName
        main { self.onData?(data, id) }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension NearbyTransport: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let ok = session.connectedPeers.count < Self.maxPeers
        invitationHandler(ok, ok ? session : nil)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        main { self.onStatus?("Nearby play needs Local Network. A grown-up can turn it on in Settings › HopQuest.") }
    }
}

extension NearbyTransport: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard info?["v"] == "\(VillageNetMessage.protocolVersion)",
              !session.connectedPeers.contains(peerID),
              session.connectedPeers.count < Self.maxPeers,
              me.displayName < peerID.displayName else { return }      // only one side sends the invite
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        main { self.onStatus?("Nearby play needs Local Network. A grown-up can turn it on in Settings › HopQuest.") }
    }
}
