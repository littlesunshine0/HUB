import Foundation
import Combine

// MARK: - Search Public Templates Use Case

class SearchPublicTemplatesUseCase {
    private let cloudService: CloudKitService
    
    init(cloudService: CloudKitService) {
        self.cloudService = cloudService
    }
    
    @MainActor
    convenience init() {
        self.init(cloudService: .shared)
    }
    
    func execute(query: String) async throws -> [CloudTemplate] {
        guard !query.isEmpty else {
            return []
        }
        return try await cloudService.searchTemplates(query: query)
    }
}
