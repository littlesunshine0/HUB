import Foundation
import SwiftUI
import Combine

/// Tracks template creation and publishing for achievement unlocking
/// This service monitors when users create and publish templates
/// and grants achievements based on usage milestones
@MainActor
public class TemplateAchievementTracker: ObservableObject {
    private let achievementService: AchievementService
    private var templateCreationCount: [String: Int] = [:]
    private var templateCategoriesUsed: [String: Set<HubCategory>] = [:]
    private var publishedTemplates: [String: Set<String>] = [:]
    
    public init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }
    
    /// Tracks when a template is created
    /// - Parameters:
    ///   - templateID: The ID of the template that was created
    ///   - category: The category of the template
    ///   - userID: The ID of the user who created the template
    public func trackTemplateCreated(templateID: String, category: HubCategory, userID: String) async {
        // Increment creation count
        templateCreationCount[userID, default: 0] += 1
        
        // Track category usage
        templateCategoriesUsed[userID, default: []].insert(category)
        
        let creationCount = templateCreationCount[userID] ?? 0
        let categoriesUsed = templateCategoriesUsed[userID]?.count ?? 0
        
        // Grant Template Author achievement on first template
        if creationCount == 1 {
            try? achievementService.grant(id: "templateAuthor", for: userID)
        }
        
        // Grant Template Curator achievement at 10 templates
        if creationCount >= 10 {
            try? achievementService.grant(id: "templateCurator", for: userID)
        }
        
        // Grant Industry Expert achievement when using 3+ categories
        if categoriesUsed >= 3 {
            try? achievementService.grant(id: "industryExpert", for: userID)
        }
    }
    
    /// Tracks when a template is published to the marketplace
    /// - Parameters:
    ///   - templateID: The ID of the template that was published
    ///   - userID: The ID of the user who published the template
    public func trackTemplatePublished(templateID: String, userID: String) async {
        // Check if this is the first time publishing this template
        let hadPublishedBefore = publishedTemplates[userID]?.contains(templateID) ?? false
        
        // Add to published templates set
        publishedTemplates[userID, default: []].insert(templateID)
        
        // Grant Template Publisher achievement on first publish
        if !hadPublishedBefore && (publishedTemplates[userID]?.count ?? 0) == 1 {
            try? achievementService.grant(id: "templatePublisher", for: userID)
        }
    }
    
    /// Resets tracking data for a specific user (useful for testing)
    /// - Parameter userID: The ID of the user whose data should be reset
    public func resetTracking(for userID: String) {
        templateCreationCount.removeValue(forKey: userID)
        templateCategoriesUsed.removeValue(forKey: userID)
        publishedTemplates.removeValue(forKey: userID)
    }
    
    /// Gets the current template creation count for a user
    /// - Parameter userID: The ID of the user
    /// - Returns: The number of templates created by the user
    public func getCreationCount(for userID: String) -> Int {
        return templateCreationCount[userID] ?? 0
    }
    
    /// Gets the number of categories used by a user
    /// - Parameter userID: The ID of the user
    /// - Returns: The number of unique categories used
    public func getCategoriesUsedCount(for userID: String) -> Int {
        return templateCategoriesUsed[userID]?.count ?? 0
    }
    
    /// Gets the number of templates published by a user
    /// - Parameter userID: The ID of the user
    /// - Returns: The number of templates published
    public func getPublishedCount(for userID: String) -> Int {
        return publishedTemplates[userID]?.count ?? 0
    }
}
