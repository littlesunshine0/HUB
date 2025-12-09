//
//  StatsTypes.swift
//  Hub
//
//  Shared statistics types used across the app
//

import Foundation

// MARK: - Hub Usage Stats

/// Statistics about hub usage
public struct HubUsageStats: Sendable {
    public var launchCount: Int
    public var lastLaunchedAt: Date
    public var totalEditTime: TimeInterval
    public var buildCount: Int
    public var daysSinceCreation: Int
    public var daysSinceLastUpdate: Int
    
    public init(
        launchCount: Int = 0,
        lastLaunchedAt: Date = Date(),
        totalEditTime: TimeInterval = 0,
        buildCount: Int = 0,
        daysSinceCreation: Int = 0,
        daysSinceLastUpdate: Int = 0
    ) {
        self.launchCount = launchCount
        self.lastLaunchedAt = lastLaunchedAt
        self.totalEditTime = totalEditTime
        self.buildCount = buildCount
        self.daysSinceCreation = daysSinceCreation
        self.daysSinceLastUpdate = daysSinceLastUpdate
    }
}

// MARK: - Content Stats

/// Statistics about seeded content
public struct ContentStats: Sendable {
    public let totalTemplates: Int
    public let totalHubs: Int
    public let totalModules: Int
    public let totalComponents: Int
    public let totalBlueprints: Int
    
    public init(
        totalTemplates: Int = 0,
        totalHubs: Int = 0,
        totalModules: Int = 0,
        totalComponents: Int = 0,
        totalBlueprints: Int = 0
    ) {
        self.totalTemplates = totalTemplates
        self.totalHubs = totalHubs
        self.totalModules = totalModules
        self.totalComponents = totalComponents
        self.totalBlueprints = totalBlueprints
    }
}

// MARK: - Achievement Stats

/// Statistics about achievement progress
public struct AchievementStats: Sendable {
    public let total: Int
    public let unlocked: Int
    public let progressPercentage: Double
    public let aiQueriesCount: Int
    public let codeGenerationsCount: Int
    public let appsBuiltCount: Int
    public let templatesPublished: Int
    public let collaborationSessions: Int
    
    public init(
        total: Int = 0,
        unlocked: Int = 0,
        progressPercentage: Double = 0,
        aiQueriesCount: Int = 0,
        codeGenerationsCount: Int = 0,
        appsBuiltCount: Int = 0,
        templatesPublished: Int = 0,
        collaborationSessions: Int = 0
    ) {
        self.total = total
        self.unlocked = unlocked
        self.progressPercentage = progressPercentage
        self.aiQueriesCount = aiQueriesCount
        self.codeGenerationsCount = codeGenerationsCount
        self.appsBuiltCount = appsBuiltCount
        self.templatesPublished = templatesPublished
        self.collaborationSessions = collaborationSessions
    }
}
