import SwiftUI
import MultipeerConnectivity
import Combine

// MARK: - Local Sharing ViewModel

@MainActor
class LocalSharingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTemplate: TemplateModel?
    @Published var showingTemplatePicker = false
    @Published var showingReceivedTemplates = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let multipeerService: MultipeerService
    private let sendTemplateUseCase: SendTemplateP2PUseCase
    private let discoverPeersUseCase: DiscoverPeersUseCase
    
    // MARK: - Computed Properties
    var peerID: MCPeerID {
        multipeerService.peerID
    }
    
    var isAdvertising: Bool {
        get { multipeerService.isAdvertising }
        set {
            if newValue {
                multipeerService.startAdvertising()
            } else {
                multipeerService.stopAdvertising()
            }
        }
    }
    
    var isBrowsing: Bool {
        get { multipeerService.isBrowsing }
        set {
            if newValue {
                multipeerService.startBrowsing()
            } else {
                multipeerService.stopBrowsing()
            }
        }
    }
    
    var connectedPeers: [MCPeerID] {
        multipeerService.connectedPeers
    }
    
    var nearbyPeers: [MCPeerID] {
        multipeerService.nearbyPeers
    }
    
    var receivedTemplates: [TemplateModel] {
        multipeerService.receivedTemplates
    }
    
    var statusMessage: String? {
        multipeerService.statusMessage
    }
    
    var hasConnectedPeers: Bool {
        !connectedPeers.isEmpty
    }
    
    var hasReceivedTemplates: Bool {
        !receivedTemplates.isEmpty
    }
    
    // MARK: - Initialization
    init(
        multipeerService: MultipeerService,
        sendTemplateUseCase: SendTemplateP2PUseCase,
        discoverPeersUseCase: DiscoverPeersUseCase
    ) {
        self.multipeerService = multipeerService
        self.sendTemplateUseCase = sendTemplateUseCase
        self.discoverPeersUseCase = discoverPeersUseCase
    }
    
    @MainActor
    convenience init() {
        self.init(
            multipeerService: .shared,
            sendTemplateUseCase: SendTemplateP2PUseCase(),
            discoverPeersUseCase: DiscoverPeersUseCase()
        )
    }
    
    // MARK: - Public Methods
    func startDiscovery() {
        discoverPeersUseCase.startDiscovery()
    }
    
    func stopDiscovery() {
        discoverPeersUseCase.stopDiscovery()
    }
    
    func invitePeer(_ peer: MCPeerID) {
        multipeerService.invitePeer(peer)
    }
    
    func sendTemplate(_ template: TemplateModel, to peer: MCPeerID?) async {
        do {
            if let peer = peer {
                try await sendTemplateUseCase.execute(template: template, to: peer)
            } else {
                try await multipeerService.sendTemplateToAll(template)
            }
        } catch {
            errorMessage = "Failed to send: \(error.localizedDescription)"
        }
    }
    
    func importReceivedTemplate(_ template: TemplateModel, templateManager: TemplateManager) {
        templateManager.createTemplate(template)
        multipeerService.receivedTemplates.removeAll { $0.id == template.id }
    }
    
    func clearReceivedTemplates() {
        multipeerService.receivedTemplates.removeAll()
    }
    
    func showTemplatePicker() {
        showingTemplatePicker = true
    }
    
    func hideTemplatePicker() {
        showingTemplatePicker = false
    }
    
    func showReceivedTemplates() {
        showingReceivedTemplates = true
    }
    
    func hideReceivedTemplates() {
        showingReceivedTemplates = false
    }
    
    func cleanup() {
        multipeerService.cleanup()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
