import Foundation
import SwiftUI
import Combine

/// Tracks hub usage for achievement unlocking
/// This service monitors when users open and use hubs
/// and grants achievements based on usage milestones
@MainActor
public class HubAchievementTracker: ObservableObject {
    private let achievementService: AchievementService
    private var hubLaunches: [String: Set<HubTemplate>] = [:]
    private var hubInstalls: [String: Set<HubTemplate>] = [:]
    
    public init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }
    
    /// Tracks when a hub is launched/opened
    /// - Parameters:
    ///   - hubTemplate: The template type of the hub that was launched
    ///   - userID: The ID of the user who launched the hub
    public func trackHubLaunched(hubTemplate: HubTemplate, userID: String) async {
        // Add to hub launches set
        hubLaunches[userID, default: []].insert(hubTemplate)
        
        // Check for Hub Explorer achievement (5 different hubs)
        let launchCount = hubLaunches[userID]?.count ?? 0
        if launchCount >= 5 {
            try? achievementService.grant(id: "hubExplorer", for: userID)
        }
        
        // Check for Power User achievement (12+ hubs)
        // Count all available hub templates
        let allHubsCount = HubTemplate.allCases.count
        if launchCount >= min(12, allHubsCount) {
            try? achievementService.grant(id: "hubPowerUser", for: userID)
        }
    }
    
    /// Tracks when a hub is installed/created
    /// - Parameters:
    ///   - hubTemplate: The template type of the hub that was installed
    ///   - userID: The ID of the user who installed the hub
    public func trackHubInstalled(hubTemplate: HubTemplate, userID: String) async {
        // Add to hub installs set
        hubInstalls[userID, default: []].insert(hubTemplate)
        
        // Check for Tool Collector achievement (all available hubs)
        let installCount = hubInstalls[userID]?.count ?? 0
        let allHubsCount = HubTemplate.allCases.count
        
        if installCount >= allHubsCount {
            try? achievementService.grant(id: "toolCollector", for: userID)
        }
    }
    
    /// Tracks when a hub is opened (convenience method that tracks both launch and install)
    /// - Parameters:
    ///   - hubTemplate: The template type of the hub that was opened
    ///   - userID: The ID of the user who opened the hub
    ///   - isNewInstall: Whether this is a new installation or just opening an existing hub
    public func trackHubOpened(hubTemplate: HubTemplate, userID: String, isNewInstall: Bool = false) async {
        // Always track launch
        await trackHubLaunched(hubTemplate: hubTemplate, userID: userID)
        
        // Track install if it's a new installation
        if isNewInstall {
            await trackHubInstalled(hubTemplate: hubTemplate, userID: userID)
        }
    }
    
    /// Gets the number of unique hubs launched by a user
    /// - Parameter userID: The ID of the user
    /// - Returns: The count of unique hubs launched
    public func getLaunchedHubsCount(for userID: String) -> Int {
        return hubLaunches[userID]?.count ?? 0
    }
    
    /// Gets the number of unique hubs installed by a user
    /// - Parameter userID: The ID of the user
    /// - Returns: The count of unique hubs installed
    public func getInstalledHubsCount(for userID: String) -> Int {
        return hubInstalls[userID]?.count ?? 0
    }
}
