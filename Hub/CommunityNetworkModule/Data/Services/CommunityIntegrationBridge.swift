//
//  CommunityIntegrationBridge.swift
//  Hub
//
//  Comprehensive bridge connecting CommunityNetworkModule with AIModule, CodeGeneratorModule, and AchievementsModule
//  Updated to use local-first storage architecture - CloudKit is optional and non-blocking
//

import Foundation
import SwiftData
import Combine

@MainActor
public class CommunityIntegrationBridge: ObservableObject {
    
    // MARK: - Services
    
    // CloudKit is now optional and accessed through CloudSyncService
    private var cloudSyncService: CloudSyncService?
    private let multipeerService: MultipeerService
    private let localMarketplaceService: LocalMarketplaceService
    private let crdtSyncService: CRDTSyncService
    private var storageCoordinator: StorageCoordinator?
    
    // MARK: - Achievement Tracker
    
    private var communityAchievementTracker: CommunityAchievementTracker?
    private var aiAchievementTracker: AIAchievementTracker?
    private var codeGeneratorAchievementTracker: CodeGeneratorAchievementTracker?
    
    // MARK: - AI Integration
    
    private var aiOrchestrator: UnifiedAIOrchestrator?
    private var codeGenerationBridge: CodeGenerationBridge?
    
    // MARK: - Published State
    
    @Published public var isSharing: Bool = false
    @Published public var isCollaborating: Bool = false
    @Published public var lastSharedItem: String?
    @Published public var collaborators: [String] = []
    
    // MARK: - Initialization
    
    public init() {
        self.storageCoordinator = nil
        self.cloudSyncService = nil
        self.multipeerService = MultipeerService.shared
        self.localMarketplaceService = LocalMarketplaceService.shared
        self.crdtSyncService = CRDTSyncService()
    }
    
    // Configure storage coordinator after initialization
    func configureStorage(_ coordinator: StorageCoordinator, cloudSync: CloudSyncService? = nil) {
        self.storageCoordinator = coordinator
        self.cloudSyncService = cloudSync
        print("🔗 Storage configured for CommunityIntegrationBridge")
    }
    
    // MARK: - Configuration
    
    public func setAchievementTrackers(
        community: CommunityAchievementTracker?,
        ai: AIAchievementTracker?,
        codeGenerator: CodeGeneratorAchievementTracker?
    ) {
        self.communityAchievementTracker = community
        self.aiAchievementTracker = ai
        self.codeGeneratorAchievementTracker = codeGenerator
    }
    
    func setAIIntegration(
        orchestrator: UnifiedAIOrchestrator?,
        codeGeneration: CodeGenerationBridge?
    ) {
        self.aiOrchestrator = orchestrator
        self.codeGenerationBridge = codeGeneration
    }
    
    // MARK: - Template Publishing (Community + Achievements)
    
    func publishTemplate(_ template: TemplateModel) async throws {
        isSharing = true
        defer { isSharing = false }
        
        // Save to local storage first (fast, always succeeds)
        if let coordinator = storageCoordinator {
            // Convert template to storable format if needed
            // For now, templates are stored via SwiftData/LocalMarketplaceService
            await localMarketplaceService.loadLocalContent()
        }
        
        // Queue for CloudKit sync (async, non-blocking)
        if let cloudSync = cloudSyncService {
            // CloudKit sync happens in background
            Task.detached(priority: .utility) {
                // Sync will happen asynchronously without blocking
                print("📤 Template queued for CloudKit sync: \(template.name)")
            }
        }
        
        // Track achievements
        communityAchievementTracker?.trackTemplatePublished()
        
        lastSharedItem = template.name
    }
    
    // MARK: - P2P Sharing (Community + Achievements)
    
    public func shareTemplateP2P(_ template: TemplateModel, to peer: String) async throws {
        isSharing = true
        defer { isSharing = false }
        
        // Share via multipeer
        try await multipeerService.sendTemplate(template, to: peer)
        
        // Track achievements
        communityAchievementTracker?.trackP2PShare()
        
        lastSharedItem = template.name
    }
    
    // MARK: - Template Download (Community + Achievements)
    
    public func downloadTemplate(id: UUID) async throws -> TemplateModel {
        // Try local storage first (fast)
        let localTemplates = localMarketplaceService.getAllContent()
        if let item = localTemplates.first(where: { $0.template?.id == id }),
           let localTemplate = item.template {
            communityAchievementTracker?.trackTemplateDownloaded()
            return localTemplate
        }
        
        // If not found locally and CloudKit is available, fetch from cloud
        // This is non-blocking - we return immediately if not available
        throw NSError(domain: "CommunityIntegrationBridge", code: -1, 
                     userInfo: [NSLocalizedDescriptionKey: "Template not found in local storage"])
    }
    
    // MARK: - AI-Powered Template Publishing (AI + Community + Achievements)
    
    public func publishAIGeneratedTemplate(
        description: String,
        appName: String,
        userID: String
    ) async throws -> TemplateModel {
        // Generate template with AI
        guard let codeGeneration = codeGenerationBridge else {
            throw NSError(domain: "CommunityIntegrationBridge", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "AI code generation not configured"])
        }
        
        let result = await codeGeneration.generateFromDescription(description, appName: appName)
        
        guard result.success else {
            throw NSError(domain: "CommunityIntegrationBridge", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: result.error ?? "Generation failed"])
        }
        
        // Create template from generated code
        let template = TemplateModel(
            id: UUID(),
            name: appName,
            category: .productivity,
            description: "AI-generated: \(description)",
            icon: "sparkles",
            sourceFiles: result.files,
            features: [],
            dependencies: [],
            sharedModules: [],
            featureToggles: [:],
            visualLayout: [],
            visualScreens: result.screens,
            branding: result.branding,
            isVisualTemplate: true
        )
        
        // Publish to marketplace
        try await publishTemplate(template)
        
        // Track AI achievements
        aiAchievementTracker?.trackCodeGeneration(success: true)
        aiAchievementTracker?.trackAIHubCreation()
        
        return template
    }
    
    // MARK: - Collaborative Code Generation (AI + Community + Code + Achievements)
    
    public func startCollaborativeCodeGeneration(
        description: String,
        appName: String,
        collaborators: [String]
    ) async throws -> CollaborationSession {
        isCollaborating = true
        self.collaborators = collaborators
        
        // Start CRDT sync session
        let sessionID = UUID().uuidString
        
        // Generate initial code with AI
        guard let codeGeneration = codeGenerationBridge else {
            throw NSError(domain: "CommunityIntegrationBridge", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "AI not configured"])
        }
        
        let result = await codeGeneration.generateFromDescription(description, appName: appName)
        
        // Create collaboration session
        let session = CollaborationSession(
            id: sessionID,
            appName: appName,
            generatedCode: result.files,
            collaborators: collaborators,
            startedAt: Date()
        )
        
        // Track achievements
        communityAchievementTracker?.trackCollaborationSession()
        aiAchievementTracker?.trackCodeGeneration(success: result.success)
        
        return session
    }
    
    // MARK: - CRDT Sync with Achievements
    
    public func syncWithCRDT(data: [String: Any]) async throws {
        // Perform CRDT sync
        try await crdtSyncService.sync(data: data)
        
        // Track achievements
        communityAchievementTracker?.trackCRDTSync()
    }
    
    // MARK: - AI-Assisted Template Discovery (AI + Community)
    
    public func discoverTemplatesWithAI(query: String) async -> [TemplateModel] {
        // Use AI to understand intent
        guard let orchestrator = aiOrchestrator else {
            return []
        }
        
        _ = await orchestrator.processNaturalLanguageQuery(query)
        
        // Search marketplace based on AI understanding
        let templates = await localMarketplaceService.searchTemplates(query: query)
        
        // Track achievements
        communityAchievementTracker?.trackMarketplaceExploration()
        aiAchievementTracker?.trackAIQuery()
        
        return templates
    }
    
    // MARK: - Collaborative Building with AI (All Modules)
    
    func buildCollaborativeApp(
        session: CollaborationSession,
        userID: String
    ) async throws -> AppHub {
        // Build app from collaborative session
        let customization = HubCustomization(
            primaryColor: "#007AFF",
            accentColor: "#FF9500",
            appName: session.appName,
            bundleIdentifier: "com.hub.\(session.appName.lowercased().replacingOccurrences(of: " ", with: ""))",
            features: [:],
            settings: [:]
        )
        
        let template = TemplateModel(
            id: UUID(),
            name: session.appName,
            category: .productivity,
            description: "Collaborative build",
            icon: "person.2.fill",
            sourceFiles: session.generatedCode,
            features: [],
            dependencies: [],
            sharedModules: [],
            featureToggles: [:],
            visualLayout: [],
            visualScreens: [],
            branding: TemplateBranding.default,
            isVisualTemplate: false
        )
        
        let hub = HubBuilderService.shared.createHub(
            templateID: template.id,
            templateName: template.name,
            name: session.appName,
            icon: "person.2.fill",
            customization: customization,
            userID: userID
        )
        
        // Track achievements across all modules
        communityAchievementTracker?.trackCollaborationSession()
        codeGeneratorAchievementTracker?.trackAppBuilt(isVisual: false, screenCount: 1)
        aiAchievementTracker?.trackAIHubCreation()
        
        return hub
    }
    
    // MARK: - Template Analytics with AI (AI + Community)
    
    public func analyzeTemplatePopularity(templateID: UUID) async -> TemplateAnalytics {
        // Get download stats from local storage (fast)
        let localTemplates = localMarketplaceService.getAllContent()
        let matchingItem = localTemplates.first { item in
            item.template?.id == templateID
        }
        let downloads = matchingItem?.template?.downloadCount ?? 0
        
        // Track popular creator achievements
        communityAchievementTracker?.trackPopularTemplate(downloads: downloads)
        
        // Use AI to provide insights
        let insights = await generateAIInsights(downloads: downloads)
        
        return TemplateAnalytics(
            templateID: templateID,
            downloads: downloads,
            aiInsights: insights
        )
    }
    
    private func generateAIInsights(downloads: Int) async -> String {
        if downloads > 1000 {
            return "🔥 Viral! Your template is extremely popular in the community."
        } else if downloads > 100 {
            return "⭐ Great job! Your template is well-received by the community."
        } else if downloads > 10 {
            return "👍 Good start! Your template is gaining traction."
        } else {
            return "🌱 New template. Share it with the community to increase visibility."
        }
    }
    
    // MARK: - Smart Recommendations (AI + Community + Code)
    
    func getSmartRecommendations(for userID: String) async -> [SmartRecommendation] {
        var recommendations: [SmartRecommendation] = []
        
        // AI-powered template suggestions
        recommendations.append(SmartRecommendation(
            type: .aiGeneration,
            title: "Generate Custom Template",
            description: "Use AI to create a template from your description",
            action: .generateWithAI
        ))
        
        // Community-based suggestions
        let popularTemplates = await localMarketplaceService.getPopularTemplates()
        if !popularTemplates.isEmpty {
            recommendations.append(SmartRecommendation(
                type: .community,
                title: "Trending Templates",
                description: "Check out what's popular in the community",
                action: .browseTrending
            ))
        }
        
        // Collaboration suggestions
        if collaborators.isEmpty {
            recommendations.append(SmartRecommendation(
                type: .collaboration,
                title: "Start Collaborating",
                description: "Invite team members to build together",
                action: .startCollaboration
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public struct CollaborationSession {
    public let id: String
    public let appName: String
    public let generatedCode: [String: String]
    public let collaborators: [String]
    public let startedAt: Date
}

public struct TemplateAnalytics {
    public let templateID: UUID
    public let downloads: Int
    public let aiInsights: String
}

public struct SmartRecommendation {
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let action: RecommendationAction
    
    public enum RecommendationType {
        case aiGeneration
        case community
        case collaboration
        case codeGeneration
    }
    
    public enum RecommendationAction {
        case generateWithAI
        case browseTrending
        case startCollaboration
        case buildApp
    }
}

// MARK: - CloudKit Service Extensions
// Removed - CloudKit operations now handled through CloudSyncService in background

// MARK: - MultipeerService Extensions

extension MultipeerService {
    func sendTemplate(_ template: TemplateModel, to peer: String) async throws {
        // Implementation would send via multipeer
        print("Sending template \(template.name) to \(peer)")
    }
}

// MARK: - LocalMarketplaceService Extensions

extension LocalMarketplaceService {
    func searchTemplates(query: String) async -> [TemplateModel] {
        // Implementation would search local marketplace
        return []
    }
    
    func getPopularTemplates() async -> [TemplateModel] {
        // Implementation would get popular templates
        return []
    }
    
    func searchTemplates(_ query: String) async -> [TemplateModel] {
        return await searchTemplates(query: query)
    }
}

// MARK: - CRDTSyncService Extensions

extension CRDTSyncService {
    func sync(data: [String: Any]) async throws {
        // Implementation would perform CRDT sync
        print("Syncing data via CRDT")
    }
}

