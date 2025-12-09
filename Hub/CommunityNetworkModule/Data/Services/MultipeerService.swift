import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Multipeer Service for Local Template Sharing

@MainActor
class MultipeerService: NSObject, ObservableObject {
    static let shared = MultipeerService()
    
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var nearbyPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedTemplates: [TemplateModel] = []
    @Published var transferProgress: [String: Double] = [:] // [peerID: progress]
    @Published var statusMessage: String?
    
    private(set) var peerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let serviceType = "hub-templates" // Must be 15 chars or less, lowercase, no special chars
    
    private override init() {
        // Create a unique peer ID for this device
        let deviceName = Host.current().localizedName ?? "Unknown Device"
        peerID = MCPeerID(displayName: deviceName)
        
        // Create session
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        session.delegate = self
    }
    
    // MARK: - Advertising (Make this device discoverable)
    
    func startAdvertising() {
        guard !isAdvertising else { return }
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isAdvertising = true
        statusMessage = "📡 Advertising as '\(peerID.displayName)'"
        print("Started advertising as: \(peerID.displayName)")
    }
    
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
        statusMessage = nil
        print("Stopped advertising")
    }
    
    // MARK: - Browsing (Discover nearby devices)
    
    func startBrowsing() {
        guard !isBrowsing else { return }
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isBrowsing = true
        statusMessage = "🔍 Searching for nearby devices..."
        print("Started browsing for peers")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        nearbyPeers.removeAll()
        statusMessage = nil
        print("Stopped browsing")
    }
    
    // MARK: - Connection Management
    
    func invitePeer(_ peer: MCPeerID) {
        guard let browser = browser else { return }
        
        statusMessage = "📤 Inviting '\(peer.displayName)'..."
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        print("Invited peer: \(peer.displayName)")
    }
    
    func disconnect() {
        session.disconnect()
        connectedPeers.removeAll()
        statusMessage = "Disconnected"
        print("Disconnected from all peers")
    }
    
    // MARK: - Template Sharing
    
    func sendTemplate(_ template: TemplateModel, to peer: MCPeerID) async throws {
        guard connectedPeers.contains(peer) else {
            throw NSError(domain: "MultipeerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Peer not connected"])
        }
        
        statusMessage = "📤 Sending template to '\(peer.displayName)'..."
        
        // Encode template to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(template)
        
        // Send data
        try session.send(data, toPeers: [peer], with: .reliable)
        
        statusMessage = "✅ Template sent to '\(peer.displayName)'"
        print("Sent template '\(template.name)' to \(peer.displayName)")
    }
    
    func sendTemplateToAll(_ template: TemplateModel) async throws {
        guard !connectedPeers.isEmpty else {
            throw NSError(domain: "MultipeerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No peers connected"])
        }
        
        statusMessage = "📤 Broadcasting template to \(connectedPeers.count) peer(s)..."
        
        // Encode template to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(template)
        
        // Send to all connected peers
        try session.send(data, toPeers: connectedPeers, with: .reliable)
        
        statusMessage = "✅ Template sent to \(connectedPeers.count) peer(s)"
        print("Broadcast template '\(template.name)' to \(connectedPeers.count) peers")
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopAdvertising()
        stopBrowsing()
        disconnect()
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if !connectedPeers.contains(peerID) {
                    connectedPeers.append(peerID)
                }
                statusMessage = "✅ Connected to '\(peerID.displayName)'"
                print("Connected to peer: \(peerID.displayName)")
                
            case .connecting:
                statusMessage = "🔄 Connecting to '\(peerID.displayName)'..."
                print("Connecting to peer: \(peerID.displayName)")
                
            case .notConnected:
                connectedPeers.removeAll { $0 == peerID }
                statusMessage = "❌ Disconnected from '\(peerID.displayName)'"
                print("Disconnected from peer: \(peerID.displayName)")
                
            @unknown default:
                print("Unknown session state")
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                // Decode received template
                let decoder = JSONDecoder()
                let template = try decoder.decode(TemplateModel.self, from: data)
                
                // Add to received templates
                receivedTemplates.append(template)
                
                statusMessage = "📥 Received template '\(template.name)' from '\(peerID.displayName)'"
                print("Received template '\(template.name)' from \(peerID.displayName)")
            } catch {
                statusMessage = "❌ Failed to receive template: \(error.localizedDescription)"
                print("Failed to decode template: \(error)")
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used for template sharing
    }
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Task { @MainActor in
            statusMessage = "📥 Receiving '\(resourceName)' from '\(peerID.displayName)'..."
        }
    }
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Task { @MainActor in
            if let error = error {
                statusMessage = "❌ Failed to receive resource: \(error.localizedDescription)"
            } else {
                statusMessage = "✅ Received '\(resourceName)' from '\(peerID.displayName)'"
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            statusMessage = "📨 Invitation from '\(peerID.displayName)'"
            print("Received invitation from: \(peerID.displayName)")
            
            // Auto-accept invitations (you could add a confirmation dialog here)
            invitationHandler(true, session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            if !nearbyPeers.contains(peerID) {
                nearbyPeers.append(peerID)
                statusMessage = "👋 Found '\(peerID.displayName)'"
                print("Found peer: \(peerID.displayName)")
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            nearbyPeers.removeAll { $0 == peerID }
            statusMessage = "👋 Lost '\(peerID.displayName)'"
            print("Lost peer: \(peerID.displayName)")
        }
    }
}


