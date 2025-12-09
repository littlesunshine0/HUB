//
//  AIAchievementTracker.swift
//  Hub
//
//  Tracks AI-related achievements for gamification
//

import Foundation
import SwiftData
import Combine

@MainActor
public class AIAchievementTracker: ObservableObject {
    
    private let achievementService: AchievementService
    private var userID: String
    
    // Track AI usage statistics
    @Published public var aiQueriesCount: Int = 0
    @Published public var codeGenerationsCount: Int = 0
    @Published public var aiHubsCreatedCount: Int = 0
    
    // MARK: - Initialization
    
    public init(achievementService: AchievementService, userID: String) {
        self.achievementService = achievementService
        self.userID = userID
    }
    
    // MARK: - AI Query Tracking
    
    public func trackAIQuery() {
        aiQueriesCount += 1
        
        // First AI query
        if aiQueriesCount == 1 {
            try? achievementService.grant(id: "firstAIQuery", for: userID)
        }
        
        // 10 AI queries
        if aiQueriesCount == 10 {
            try? achievementService.grant(id: "aiExplorer", for: userID)
        }
        
        // 50 AI queries
        if aiQueriesCount == 50 {
            try? achievementService.grant(id: "aiPowerUser", for: userID)
        }
        
        // 100 AI queries
        if aiQueriesCount == 100 {
            try? achievementService.grant(id: "aiMaster", for: userID)
        }
    }
    
    // MARK: - Code Generation Tracking
    
    public func trackCodeGeneration(success: Bool) {
        if success {
            codeGenerationsCount += 1
            
            // First successful code generation
            if codeGenerationsCount == 1 {
                try? achievementService.grant(id: "firstCodeGen", for: userID)
            }
            
            // 5 code generations
            if codeGenerationsCount == 5 {
                try? achievementService.grant(id: "codeGenerator", for: userID)
            }
            
            // 25 code generations
            if codeGenerationsCount == 25 {
                try? achievementService.grant(id: "codeWizard", for: userID)
            }
            
            // 100 code generations
            if codeGenerationsCount == 100 {
                try? achievementService.grant(id: "codeMaster", for: userID)
            }
        }
    }
    
    // MARK: - AI Hub Creation Tracking
    
    public func trackAIHubCreation() {
        aiHubsCreatedCount += 1
        
        // First AI-generated hub
        if aiHubsCreatedCount == 1 {
            try? achievementService.grant(id: "firstAIHub", for: userID)
        }
        
        // 5 AI hubs
        if aiHubsCreatedCount == 5 {
            try? achievementService.grant(id: "aiHubCreator", for: userID)
        }
        
        // 20 AI hubs
        if aiHubsCreatedCount == 20 {
            try? achievementService.grant(id: "aiHubMaster", for: userID)
        }
    }
    
    // MARK: - Special AI Achievements
    
    public func trackAIAssistantUsage(context: String) {
        // Track using AI in different contexts
        switch context {
        case "browser":
            try? achievementService.grant(id: "aiBrowserHelper", for: userID)
        case "template":
            try? achievementService.grant(id: "aiTemplateHelper", for: userID)
        case "component":
            try? achievementService.grant(id: "aiComponentHelper", for: userID)
        case "collaboration":
            try? achievementService.grant(id: "aiCollaborator", for: userID)
        default:
            break
        }
    }
    
    public func trackNaturalLanguageGeneration() {
        try? achievementService.grant(id: "naturalLanguageWizard", for: userID)
    }
    
    public func trackMultiScreenGeneration() {
        try? achievementService.grant(id: "multiScreenArchitect", for: userID)
    }
    
    public func trackAdvancedFeatureGeneration(feature: String) {
        switch feature {
        case "navigation":
            try? achievementService.grant(id: "navigationExpert", for: userID)
        case "tabBar":
            try? achievementService.grant(id: "tabBarMaster", for: userID)
        case "presentation":
            try? achievementService.grant(id: "presentationPro", for: userID)
        default:
            break
        }
    }
}

// MARK: - AI Achievement Definitions Extension

extension AchievementLibrary {
    public static let aiAchievements: [String: AchievementDefinition] = [
        // AI Query Achievements
        "firstAIQuery": AchievementDefinition(
            id: "firstAIQuery",
            name: "AI Curious",
            description: "Ask your first AI question",
            icon: "brain",
            category: .general,
            rarity: .common
        ),
        "aiExplorer": AchievementDefinition(
            id: "aiExplorer",
            name: "AI Explorer",
            description: "Ask 10 AI questions",
            icon: "brain.head.profile",
            category: .general,
            rarity: .uncommon
        ),
        "aiPowerUser": AchievementDefinition(
            id: "aiPowerUser",
            name: "AI Power User",
            description: "Ask 50 AI questions",
            icon: "sparkles",
            category: .general,
            rarity: .rare
        ),
        "aiMaster": AchievementDefinition(
            id: "aiMaster",
            name: "AI Master",
            description: "Ask 100 AI questions",
            icon: "wand.and.stars",
            category: .general,
            rarity: .epic
        ),
        
        // Code Generation Achievements
        "firstCodeGen": AchievementDefinition(
            id: "firstCodeGen",
            name: "Code Creator",
            description: "Generate your first code with AI",
            icon: "chevron.left.forwardslash.chevron.right",
            category: .building,
            rarity: .common
        ),
        "codeGenerator": AchievementDefinition(
            id: "codeGenerator",
            name: "Code Generator",
            description: "Generate 5 apps with AI",
            icon: "cpu",
            category: .building,
            rarity: .uncommon
        ),
        "codeWizard": AchievementDefinition(
            id: "codeWizard",
            name: "Code Wizard",
            description: "Generate 25 apps with AI",
            icon: "wand.and.stars.inverse",
            category: .building,
            rarity: .rare
        ),
        "codeMaster": AchievementDefinition(
            id: "codeMaster",
            name: "Code Master",
            description: "Generate 100 apps with AI",
            icon: "crown.fill",
            category: .building,
            rarity: .legendary
        ),
        
        // AI Hub Creation Achievements
        "firstAIHub": AchievementDefinition(
            id: "firstAIHub",
            name: "AI Hub Pioneer",
            description: "Create your first AI-generated hub",
            icon: "sparkle",
            category: .building,
            rarity: .uncommon
        ),
        "aiHubCreator": AchievementDefinition(
            id: "aiHubCreator",
            name: "AI Hub Creator",
            description: "Create 5 AI-generated hubs",
            icon: "square.stack.3d.up.fill",
            category: .building,
            rarity: .rare
        ),
        "aiHubMaster": AchievementDefinition(
            id: "aiHubMaster",
            name: "AI Hub Master",
            description: "Create 20 AI-generated hubs",
            icon: "building.columns.fill",
            category: .building,
            rarity: .epic
        ),
        
        // Context-Specific AI Achievements
        "aiBrowserHelper": AchievementDefinition(
            id: "aiBrowserHelper",
            name: "Browser Assistant",
            description: "Use AI in the browser",
            icon: "safari",
            category: .general,
            rarity: .common
        ),
        "aiTemplateHelper": AchievementDefinition(
            id: "aiTemplateHelper",
            name: "Template Assistant",
            description: "Use AI for template suggestions",
            icon: "doc.text.magnifyingglass",
            category: .templates,
            rarity: .common
        ),
        "aiComponentHelper": AchievementDefinition(
            id: "aiComponentHelper",
            name: "Component Assistant",
            description: "Use AI for component generation",
            icon: "square.on.square",
            category: .building,
            rarity: .common
        ),
        "aiCollaborator": AchievementDefinition(
            id: "aiCollaborator",
            name: "AI Collaborator",
            description: "Use AI for collaboration features",
            icon: "person.2.badge.gearshape",
            category: .sharing,
            rarity: .uncommon
        ),
        
        // Advanced AI Achievements
        "naturalLanguageWizard": AchievementDefinition(
            id: "naturalLanguageWizard",
            name: "Natural Language Wizard",
            description: "Generate an app from natural language",
            icon: "text.bubble",
            category: .building,
            rarity: .rare
        ),
        "multiScreenArchitect": AchievementDefinition(
            id: "multiScreenArchitect",
            name: "Multi-Screen Architect",
            description: "Generate a multi-screen app with AI",
            icon: "rectangle.3.group",
            category: .building,
            rarity: .rare
        ),
        "navigationExpert": AchievementDefinition(
            id: "navigationExpert",
            name: "Navigation Expert",
            description: "Generate an app with navigation",
            icon: "arrow.triangle.turn.up.right.diamond",
            category: .building,
            rarity: .uncommon
        ),
        "tabBarMaster": AchievementDefinition(
            id: "tabBarMaster",
            name: "Tab Bar Master",
            description: "Generate an app with tab bar",
            icon: "square.split.bottomrightquarter",
            category: .building,
            rarity: .uncommon
        ),
        "presentationPro": AchievementDefinition(
            id: "presentationPro",
            name: "Presentation Pro",
            description: "Generate an app with sheets and modals",
            icon: "rectangle.portrait.on.rectangle.portrait",
            category: .building,
            rarity: .uncommon
        ),
        
        // Special AI Achievements
        "aiTeacher": AchievementDefinition(
            id: "aiTeacher",
            name: "AI Teacher",
            description: "Learn a new concept from AI",
            icon: "graduationcap",
            category: .general,
            rarity: .uncommon
        ),
        "aiOptimizer": AchievementDefinition(
            id: "aiOptimizer",
            name: "AI Optimizer",
            description: "Use AI to optimize your hub",
            icon: "speedometer",
            category: .building,
            rarity: .rare
        ),
        "aiTroubleshooter": AchievementDefinition(
            id: "aiTroubleshooter",
            name: "AI Troubleshooter",
            description: "Fix an issue with AI help",
            icon: "wrench.and.screwdriver",
            category: .general,
            rarity: .uncommon
        )
    ]
}
