import Foundation

// MARK: - Discover Peers Use Case

class DiscoverPeersUseCase {
    private let multipeerService: MultipeerService
    
    init(multipeerService: MultipeerService) {
        self.multipeerService = multipeerService
    }
    
    @MainActor
    convenience init() {
        self.init(multipeerService: .shared)
    }
    
    func startDiscovery() {
        multipeerService.startBrowsing()
        multipeerService.startAdvertising()
    }
    
    func stopDiscovery() {
        multipeerService.stopBrowsing()
        multipeerService.stopAdvertising()
    }
}
