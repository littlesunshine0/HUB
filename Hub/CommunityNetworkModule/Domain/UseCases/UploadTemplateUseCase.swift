import Foundation

// MARK: - Upload Template Use Case

class UploadTemplateUseCase {
    private let cloudService: CloudKitService
    
    init(cloudService: CloudKitService) {
        self.cloudService = cloudService
    }
    
    @MainActor
    convenience init() {
        self.init(cloudService: .shared)
    }
    
    func execute(template: TemplateModel) async throws {
        try await cloudService.uploadTemplate(template)
    }
}
