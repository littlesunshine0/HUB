import Foundation

// MARK: - Clear Build Cache Use Case

public class ClearBuildCacheUseCase {
    private let builderService: HubBuilderService
    private let notificationService: AppNotificationService
    
    // MARK: - Initializer
    
    public init(
        builderService: HubBuilderService,
        notificationService: AppNotificationService
    ) {
        self.builderService = builderService
        self.notificationService = notificationService
    }
    
    @MainActor
    public convenience init() {
        self.init(builderService: .shared, notificationService: .shared)
    }
    
    // MARK: - Execute
    
    /// Executes the clear build cache operation
    @MainActor
    func execute() async throws -> ClearCacheResult {
        // Get size before clearing
        let sizeBefore = try builderService.getBuildsDirectorySize()
        
        // Clear the cache
        try builderService.clearBuildsDirectory()
        
        // Get size after (should be 0 or minimal)
        let sizeAfter = try builderService.getBuildsDirectorySize()
        let freedSpace = sizeBefore - sizeAfter
        
        // Create result
        let result = ClearCacheResult(
            success: true,
            freedBytes: freedSpace,
            itemsCleared: 0 // Could be enhanced to track this
        )
        
        // Show notification
        let freedMB = Double(freedSpace) / 1_048_576.0
        notificationService.showBanner(
            message: String(format: "Cleared %.1f MB from build cache", freedMB),
            level: .success
        )
        
        return result
    }
}

// MARK: - Result Model

public struct ClearCacheResult {
    let success: Bool
    let freedBytes: Int64
    let itemsCleared: Int
    
    var freedMegabytes: Double {
        Double(freedBytes) / 1_048_576.0
    }
    
    var freedGigabytes: Double {
        Double(freedBytes) / 1_073_741_824.0
    }
    
    var formattedSize: String {
        if freedGigabytes >= 1.0 {
            return String(format: "%.2f GB", freedGigabytes)
        } else {
            return String(format: "%.1f MB", freedMegabytes)
        }
    }
}
