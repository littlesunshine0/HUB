import Foundation
import MultipeerConnectivity

// MARK: - Send Template P2P Use Case

class SendTemplateP2PUseCase {
    private let multipeerService: MultipeerService
    
    init(multipeerService: MultipeerService) {
        self.multipeerService = multipeerService
    }
    
    @MainActor
    convenience init() {
        self.init(multipeerService: .shared)
    }
    
    func execute(template: TemplateModel, to peer: MCPeerID) async throws {
        try await multipeerService.sendTemplate(template, to: peer)
    }
}
