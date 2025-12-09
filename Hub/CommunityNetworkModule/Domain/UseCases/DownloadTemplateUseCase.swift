import Foundation
import Combine

// MARK: - Download Template Use Case

class DownloadTemplateUseCase {
    private let cloudService: CloudKitService
    
    init(cloudService: CloudKitService) {
        self.cloudService = cloudService
    }
    
    @MainActor
    convenience init() {
        self.init(cloudService: .shared)
    }
    
    func execute(cloudTemplate: CloudTemplate) async throws -> TemplateModel {
        // Convert cloud template to local template
        let template = cloudTemplate.toHubTemplateModel()
        
        // Increment download count
        try await cloudService.incrementDownloadCount(templateID: cloudTemplate.templateID.uuidString)
        
        return template
    }
}
