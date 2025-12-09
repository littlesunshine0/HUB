import Foundation
import SwiftUI
import Combine

/// Tracks component and pattern usage for achievement unlocking
/// This service monitors when users add components and patterns to the visual editor
/// and grants achievements based on usage milestones
@MainActor
public class ComponentAchievementTracker: ObservableObject {
    private let achievementService: AchievementService
    private var uniqueComponentUsage: [String: Set<ComponentType>] = [:]
    private var patternUsage: [String: Set<DesignPattern>] = [:]
    private var patternCategoryUsage: [String: Set<PatternCategory>] = [:]
    
    public init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }
    
    /// Tracks when a component is added to the canvas
    /// - Parameters:
    ///   - type: The type of component that was added
    ///   - userID: The ID of the user who added the component
    public func trackComponentAdded(type: ComponentType, userID: String) async {
        // Add to unique usage set
        uniqueComponentUsage[userID, default: []].insert(type)
        
        // Check for Component King achievement (10 unique component types)
        let uniqueCount = uniqueComponentUsage[userID]?.count ?? 0
        if uniqueCount >= 10 {
            try? achievementService.grant(id: "componentKing", for: userID)
        }
    }
    
    /// Tracks when a pattern is added to the canvas
    /// - Parameters:
    ///   - pattern: The pattern that was added
    ///   - userID: The ID of the user who added the pattern
    public func trackPatternAdded(pattern: DesignPattern, userID: String) async {
        // Check if this is the first time using this pattern (before adding to set)
        let hadPatternBefore = patternUsage[userID]?.contains(pattern) ?? false
        
        // Add to pattern usage set
        patternUsage[userID, default: []].insert(pattern)
        
        // Track pattern category
        let category = pattern.category
        patternCategoryUsage[userID, default: []].insert(category)
        
        // Check for pattern-specific achievements
        if pattern == .card && !hadPatternBefore {
            // Grant Card Constructor achievement on first card usage
            try? achievementService.grant(id: "cardConstructor", for: userID)
        }
        
        // Check for category-specific achievements
        let userPatterns = patternUsage[userID] ?? []
        
        // Social Butterfly: Use all social patterns
        let socialPatterns: Set<DesignPattern> = [.commentCell, .feedCard, .userProfile, .notification, .mediaPlayer]
        if socialPatterns.isSubset(of: userPatterns) {
            try? achievementService.grant(id: "socialButterfly", for: userID)
        }
        
        // Form Master: Use all form patterns
        let formPatterns: Set<DesignPattern> = [.loginForm, .registrationForm, .dateTimePicker, .dropdownMenu, .multiSelect, .ratingInput]
        if formPatterns.isSubset(of: userPatterns) {
            try? achievementService.grant(id: "formMaster", for: userID)
        }
        
        // Dashboard Pro: Use all dashboard patterns
        let dashboardPatterns: Set<DesignPattern> = [.chartCard, .metricGrid, .progressBar, .timeline, .kpiDashboard, .filterBar]
        if dashboardPatterns.isSubset(of: userPatterns) {
            try? achievementService.grant(id: "dashboardPro", for: userID)
        }
        
        // UI Completionist: Use all patterns (20+ patterns)
        let allPatterns = Set(DesignPattern.allCases)
        if allPatterns.isSubset(of: userPatterns) {
            try? achievementService.grant(id: "uiCompletionist", for: userID)
        }
        
        // Pattern Explorer: Use 5 different pattern categories
        let categoriesUsed = patternCategoryUsage[userID]?.count ?? 0
        if categoriesUsed >= 5 {
            try? achievementService.grant(id: "patternExplorer", for: userID)
        }
    }
}
