//
//  CommunityAchievementTracker.swift
//  Hub
//
//  Tracks community and sharing achievements
//

import Foundation
import SwiftData
import Combine

@MainActor
public class CommunityAchievementTracker: ObservableObject {
    
    private let achievementService: AchievementService
    private var userID: String
    
    // Track community statistics
    @Published public var templatesPublishedCount: Int = 0
    @Published public var templatesSharedP2PCount: Int = 0
    @Published public var templatesDownloadedCount: Int = 0
    @Published public var collaborationSessionsCount: Int = 0
    @Published public var crdtSyncsCount: Int = 0
    
    // MARK: - Initialization
    
    public init(achievementService: AchievementService, userID: String) {
        self.achievementService = achievementService
        self.userID = userID
    }
    
    // MARK: - Publishing Tracking
    
    public func trackTemplatePublished() {
        templatesPublishedCount += 1
        
        // First publish
        if templatesPublishedCount == 1 {
            try? achievementService.grant(id: "firstPublish", for: userID)
        }
        
        // 10 publishes
        if templatesPublishedCount == 10 {
            try? achievementService.grant(id: "publish10", for: userID)
        }
        
        // 50 publishes
        if templatesPublishedCount == 50 {
            try? achievementService.grant(id: "contentCreator", for: userID)
        }
    }
    
    // MARK: - P2P Sharing Tracking
    
    public func trackP2PShare() {
        templatesSharedP2PCount += 1
        
        // First P2P share
        if templatesSharedP2PCount == 1 {
            try? achievementService.grant(id: "firstShare", for: userID)
        }
        
        // 10 P2P shares
        if templatesSharedP2PCount == 10 {
            try? achievementService.grant(id: "p2pExpert", for: userID)
        }
    }
    
    // MARK: - Download Tracking
    
    public func trackTemplateDownloaded() {
        templatesDownloadedCount += 1
        
        // First download
        if templatesDownloadedCount == 1 {
            try? achievementService.grant(id: "firstImport", for: userID)
        }
        
        // 25 downloads
        if templatesDownloadedCount == 25 {
            try? achievementService.grant(id: "templateCollector", for: userID)
        }
    }
    
    // MARK: - Collaboration Tracking
    
    public func trackCollaborationSession() {
        collaborationSessionsCount += 1
        
        // First collaboration
        if collaborationSessionsCount == 1 {
            try? achievementService.grant(id: "firstCollaboration", for: userID)
        }
        
        // 10 collaborations
        if collaborationSessionsCount == 10 {
            try? achievementService.grant(id: "teamPlayer", for: userID)
        }
        
        // 50 collaborations
        if collaborationSessionsCount == 50 {
            try? achievementService.grant(id: "collaborationMaster", for: userID)
        }
    }
    
    // MARK: - CRDT Sync Tracking
    
    public func trackCRDTSync() {
        crdtSyncsCount += 1
        
        // First CRDT sync
        if crdtSyncsCount == 1 {
            try? achievementService.grant(id: "realtimePioneer", for: userID)
        }
        
        // 100 syncs
        if crdtSyncsCount == 100 {
            try? achievementService.grant(id: "syncMaster", for: userID)
        }
    }
    
    // MARK: - Special Community Achievements
    
    public func trackMarketplaceExploration() {
        try? achievementService.grant(id: "marketplaceExplorer", for: userID)
    }
    
    public func trackPopularTemplate(downloads: Int) {
        if downloads >= 100 {
            try? achievementService.grant(id: "popularCreator", for: userID)
        }
        
        if downloads >= 1000 {
            try? achievementService.grant(id: "viralCreator", for: userID)
        }
    }
    
    public func trackCommunityContribution() {
        try? achievementService.grant(id: "communityHero", for: userID)
    }
}

// MARK: - Community Achievement Definitions Extension

extension AchievementLibrary {
    public static let communityAchievements: [String: AchievementDefinition] = [
        // Publishing Achievements
        "contentCreator": AchievementDefinition(
            id: "contentCreator",
            name: "Content Creator",
            description: "Publish 50 templates to the marketplace",
            icon: "star.fill",
            category: .sharing,
            rarity: .epic
        ),
        
        // P2P Achievements
        "p2pExpert": AchievementDefinition(
            id: "p2pExpert",
            name: "P2P Expert",
            description: "Share 10 templates via peer-to-peer",
            icon: "antenna.radiowaves.left.and.right.circle.fill",
            category: .sharing,
            rarity: .uncommon
        ),
        
        // Download Achievements
        "templateCollector": AchievementDefinition(
            id: "templateCollector",
            name: "Template Collector",
            description: "Download 25 templates from the marketplace",
            icon: "tray.and.arrow.down.fill",
            category: .templates,
            rarity: .uncommon
        ),
        
        // Collaboration Achievements
        "firstCollaboration": AchievementDefinition(
            id: "firstCollaboration",
            name: "First Collaboration",
            description: "Join your first collaboration session",
            icon: "person.2.circle.fill",
            category: .sharing,
            rarity: .common
        ),
        "teamPlayer": AchievementDefinition(
            id: "teamPlayer",
            name: "Team Player",
            description: "Participate in 10 collaboration sessions",
            icon: "person.3.fill",
            category: .sharing,
            rarity: .uncommon
        ),
        "collaborationMaster": AchievementDefinition(
            id: "collaborationMaster",
            name: "Collaboration Master",
            description: "Participate in 50 collaboration sessions",
            icon: "person.3.sequence.fill",
            category: .sharing,
            rarity: .rare
        ),
        
        // CRDT Sync Achievements
        "realtimePioneer": AchievementDefinition(
            id: "realtimePioneer",
            name: "Real-Time Pioneer",
            description: "Use CRDT sync for the first time",
            icon: "arrow.triangle.2.circlepath.circle.fill",
            category: .sharing,
            rarity: .uncommon
        ),
        "syncMaster": AchievementDefinition(
            id: "syncMaster",
            name: "Sync Master",
            description: "Complete 100 CRDT syncs",
            icon: "arrow.clockwise.circle.fill",
            category: .sharing,
            rarity: .rare
        ),
        
        // Marketplace Achievements
        "marketplaceExplorer": AchievementDefinition(
            id: "marketplaceExplorer",
            name: "Marketplace Explorer",
            description: "Browse the community marketplace",
            icon: "storefront.fill",
            category: .general,
            rarity: .common
        ),
        "popularCreator": AchievementDefinition(
            id: "popularCreator",
            name: "Popular Creator",
            description: "Have a template downloaded 100 times",
            icon: "flame.fill",
            category: .sharing,
            rarity: .epic
        ),
        "viralCreator": AchievementDefinition(
            id: "viralCreator",
            name: "Viral Creator",
            description: "Have a template downloaded 1000 times",
            icon: "sparkles",
            category: .sharing,
            rarity: .legendary
        ),
        
        // Community Contribution
        "communityHero": AchievementDefinition(
            id: "communityHero",
            name: "Community Hero",
            description: "Make significant contributions to the community",
            icon: "heart.circle.fill",
            category: .sharing,
            rarity: .legendary
        )
    ]
}
