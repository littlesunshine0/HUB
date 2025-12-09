//
//  CodeGeneratorAchievementTracker.swift
//  Hub
//
//  Tracks code generation achievements
//

import Foundation
import SwiftData
import Combine
@MainActor
public class CodeGeneratorAchievementTracker: ObservableObject {
    
    private let achievementService: AchievementService
    private var userID: String
    
    // Track code generation statistics
    @Published public var appsBuiltCount: Int = 0
    @Published public var visualAppsCount: Int = 0
    @Published public var multiScreenAppsCount: Int = 0
    @Published public var advancedFeaturesUsed: Set<String> = []
    
    // MARK: - Initialization
    
    public init(achievementService: AchievementService, userID: String) {
        self.achievementService = achievementService
        self.userID = userID
    }
    
    // MARK: - App Building Tracking
    
    public func trackAppBuilt(isVisual: Bool = false, screenCount: Int = 1) {
        appsBuiltCount += 1
        
        if isVisual {
            visualAppsCount += 1
        }
        
        if screenCount > 1 {
            multiScreenAppsCount += 1
        }
        
        // First build
        if appsBuiltCount == 1 {
            try? achievementService.grant(id: "firstBuild", for: userID)
        }
        
        // 10 builds
        if appsBuiltCount == 10 {
            try? achievementService.grant(id: "build10", for: userID)
        }
        
        // 50 builds
        if appsBuiltCount == 50 {
            try? achievementService.grant(id: "build50", for: userID)
        }
        
        // 100 builds
        if appsBuiltCount == 100 {
            try? achievementService.grant(id: "build100", for: userID)
        }
        
        // Visual app achievements
        if visualAppsCount == 1 {
            try? achievementService.grant(id: "firstVisualApp", for: userID)
        }
        
        if visualAppsCount == 10 {
            try? achievementService.grant(id: "visualAppMaster", for: userID)
        }
        
        // Multi-screen achievements
        if multiScreenAppsCount == 1 {
            try? achievementService.grant(id: "multiScreenPioneer", for: userID)
        }
        
        if multiScreenAppsCount == 10 {
            try? achievementService.grant(id: "multiScreenExpert", for: userID)
        }
    }
    
    // MARK: - Advanced Features Tracking
    
    public func trackAdvancedFeature(_ feature: String) {
        advancedFeaturesUsed.insert(feature)
        
        switch feature {
        case "navigation":
            try? achievementService.grant(id: "navigationMaster", for: userID)
        case "tabBar":
            try? achievementService.grant(id: "tabBarArchitect", for: userID)
        case "sheets":
            try? achievementService.grant(id: "modalExpert", for: userID)
        case "alerts":
            try? achievementService.grant(id: "alertMaster", for: userID)
        case "animations":
            try? achievementService.grant(id: "animationWizard", for: userID)
        default:
            break
        }
        
        // All advanced features
        if advancedFeaturesUsed.count >= 5 {
            try? achievementService.grant(id: "advancedDeveloper", for: userID)
        }
    }
    
    // MARK: - Build Quality Tracking
    
    public func trackSuccessfulBuild(buildTime: TimeInterval) {
        // Speed achievements
        if buildTime < 30 {
            try? achievementService.grant(id: "speedRunner", for: userID)
        }
        
        if buildTime < 10 {
            try? achievementService.grant(id: "lightningBuilder", for: userID)
        }
    }
    
    public func trackPerfectBuild() {
        try? achievementService.grant(id: "perfectionist", for: userID)
    }
    
    // MARK: - Time-Based Achievements
    
    public func trackBuildTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Night owl (midnight to 6 AM)
        if hour >= 0 && hour < 6 {
            try? achievementService.grant(id: "nightOwl", for: userID)
        }
        
        // Early bird (6 AM to 9 AM)
        if hour >= 6 && hour < 9 {
            try? achievementService.grant(id: "earlyBird", for: userID)
        }
    }
    
    // MARK: - Customization Tracking
    
    public func trackCustomization(type: String) {
        switch type {
        case "colors":
            try? achievementService.grant(id: "firstCustomization", for: userID)
        case "icon":
            try? achievementService.grant(id: "uploadIcon", for: userID)
        case "assets":
            try? achievementService.grant(id: "addAssets", for: userID)
        case "branding":
            try? achievementService.grant(id: "brandingExpert", for: userID)
        default:
            break
        }
    }
    
    // MARK: - Component Usage Tracking
    
    public func trackComponentUsage(componentTypes: Set<String>) {
        if componentTypes.count >= 10 {
            try? achievementService.grant(id: "componentKing", for: userID)
        }
        
        if componentTypes.contains("Card") {
            try? achievementService.grant(id: "cardConstructor", for: userID)
        }
    }
}

// MARK: - Code Generator Achievement Definitions Extension

extension AchievementLibrary {
    public static let codeGeneratorAchievements: [String: AchievementDefinition] = [
        // Visual App Achievements
        "firstVisualApp": AchievementDefinition(
            id: "firstVisualApp",
            name: "Visual Pioneer",
            description: "Build your first visual app",
            icon: "square.grid.2x2",
            category: .building,
            rarity: .common
        ),
        "visualAppMaster": AchievementDefinition(
            id: "visualAppMaster",
            name: "Visual Master",
            description: "Build 10 visual apps",
            icon: "square.grid.3x3.fill",
            category: .building,
            rarity: .rare
        ),
        
        // Multi-Screen Achievements
        "multiScreenPioneer": AchievementDefinition(
            id: "multiScreenPioneer",
            name: "Multi-Screen Pioneer",
            description: "Build your first multi-screen app",
            icon: "rectangle.3.group",
            category: .building,
            rarity: .uncommon
        ),
        "multiScreenExpert": AchievementDefinition(
            id: "multiScreenExpert",
            name: "Multi-Screen Expert",
            description: "Build 10 multi-screen apps",
            icon: "square.stack.3d.up.fill",
            category: .building,
            rarity: .rare
        ),
        
        // Advanced Feature Achievements
        "navigationMaster": AchievementDefinition(
            id: "navigationMaster",
            name: "Navigation Master",
            description: "Use navigation in your app",
            icon: "arrow.triangle.turn.up.right.diamond.fill",
            category: .building,
            rarity: .uncommon
        ),
        "tabBarArchitect": AchievementDefinition(
            id: "tabBarArchitect",
            name: "Tab Bar Architect",
            description: "Build an app with tab bar navigation",
            icon: "square.split.bottomrightquarter.fill",
            category: .building,
            rarity: .uncommon
        ),
        "modalExpert": AchievementDefinition(
            id: "modalExpert",
            name: "Modal Expert",
            description: "Use sheets and modals in your app",
            icon: "rectangle.portrait.on.rectangle.portrait.fill",
            category: .building,
            rarity: .uncommon
        ),
        "alertMaster": AchievementDefinition(
            id: "alertMaster",
            name: "Alert Master",
            description: "Use alerts and dialogs",
            icon: "exclamationmark.triangle.fill",
            category: .building,
            rarity: .common
        ),
        "animationWizard": AchievementDefinition(
            id: "animationWizard",
            name: "Animation Wizard",
            description: "Add animations to your app",
            icon: "wand.and.stars",
            category: .building,
            rarity: .rare
        ),
        "advancedDeveloper": AchievementDefinition(
            id: "advancedDeveloper",
            name: "Advanced Developer",
            description: "Use 5 or more advanced features",
            icon: "star.circle.fill",
            category: .building,
            rarity: .epic
        ),
        
        // Speed Achievements
        "lightningBuilder": AchievementDefinition(
            id: "lightningBuilder",
            name: "Lightning Builder",
            description: "Build an app in under 10 seconds",
            icon: "bolt.fill",
            category: .building,
            rarity: .epic
        ),
        
        // Branding Achievements
        "brandingExpert": AchievementDefinition(
            id: "brandingExpert",
            name: "Branding Expert",
            description: "Customize app branding",
            icon: "paintpalette.fill",
            category: .customization,
            rarity: .uncommon
        )
    ]
}
