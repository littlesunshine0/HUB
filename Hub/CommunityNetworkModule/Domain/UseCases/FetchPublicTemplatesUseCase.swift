import Foundation
import Combine

// MARK: - Fetch Public Templates Use Case

class FetchPublicTemplatesUseCase {
    private let cloudService: CloudKitService
    
    init(cloudService: CloudKitService) {
        self.cloudService = cloudService
    }
    
    @MainActor
    convenience init() {
        self.init(cloudService: .shared)
    }
    
    func execute(limit: Int = 50) async throws -> [CloudTemplate] {
        return try await cloudService.fetchPublicTemplates(limit: limit)
    }
}
