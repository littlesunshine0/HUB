//
import SwiftUI

//  AnalyticsAggregates.swift
//  Hub
//
//  Aggregate analytics models for insights and reporting
//

import Foundation
import SwiftData

/// Daily analytics aggregates
@Model
class DailyAnalytics {
    @Attribute(.unique) var id: UUID
    var date: Date
    var activeUsers: Int
    var newUsers: Int
    var sessions: Int
    var events: Int
    var revenue: Decimal
    var averageSessionDuration: TimeInterval
    var topTemplates: [String] // JSON array of template IDs
    var topSearches: [String] // JSON array of search queries
    var errorCount: Int
    var crashCount: Int
    
    init(
        id: UUID = UUID(),
        date: Date,
        activeUsers: Int = 0,
        newUsers: Int = 0,
        sessions: Int = 0,
        events: Int = 0,
        revenue: Decimal = 0,
        averageSessionDuration: TimeInterval = 0,
        topTemplates: [String] = [],
        topSearches: [String] = [],
        errorCount: Int = 0,
        crashCount: Int = 0
    ) {
        self.id = id
        self.date = date
        self.activeUsers = activeUsers
        self.newUsers = newUsers
        self.sessions = sessions
        self.events = events
        self.revenue = revenue
        self.averageSessionDuration = averageSessionDuration
        self.topTemplates = topTemplates
        self.topSearches = topSearches
        self.errorCount = errorCount
        self.crashCount = crashCount
    }
}

/// Template analytics for marketplace
@Model
class MarketplaceTemplateAnalytics {
    @Attribute(.unique) var id: UUID
    var templateId: UUID
    var views: Int
    var downloads: Int
    var usageTime: TimeInterval
    var customizations: Int
    var publishes: Int
    var rating: Double
    var reviewCount: Int
    var revenue: Decimal
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        templateId: UUID,
        views: Int = 0,
        downloads: Int = 0,
        usageTime: TimeInterval = 0,
        customizations: Int = 0,
        publishes: Int = 0,
        rating: Double = 0,
        reviewCount: Int = 0,
        revenue: Decimal = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.views = views
        self.downloads = downloads
        self.usageTime = usageTime
        self.customizations = customizations
        self.publishes = publishes
        self.rating = rating
        self.reviewCount = reviewCount
        self.revenue = revenue
        self.lastUpdated = lastUpdated
    }
    
    /// Calculate engagement score (0-100)
    var engagementScore: Double {
        let viewWeight = 1.0
        let downloadWeight = 5.0
        let usageWeight = 0.01 // per second
        let customizationWeight = 3.0
        let publishWeight = 10.0
        
        let score = (Double(views) * viewWeight) +
                   (Double(downloads) * downloadWeight) +
                   (usageTime * usageWeight) +
                   (Double(customizations) * customizationWeight) +
                   (Double(publishes) * publishWeight)
        
        return min(score / 100.0, 100.0)
    }
}

/// User analytics
@Model
class UserAnalytics {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var totalSessions: Int
    var totalEvents: Int
    var totalUsageTime: TimeInterval
    var templatesViewed: Int
    var templatesDownloaded: Int
    var templatesPublished: Int
    var searchesPerformed: Int
    var feedbackSubmitted: Int
    var lastActive: Date
    var firstSeen: Date
    var subscriptionTier: String
    var lifetimeValue: Decimal
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        totalSessions: Int = 0,
        totalEvents: Int = 0,
        totalUsageTime: TimeInterval = 0,
        templatesViewed: Int = 0,
        templatesDownloaded: Int = 0,
        templatesPublished: Int = 0,
        searchesPerformed: Int = 0,
        feedbackSubmitted: Int = 0,
        lastActive: Date = Date(),
        firstSeen: Date = Date(),
        subscriptionTier: String = "free",
        lifetimeValue: Decimal = 0
    ) {
        self.id = id
        self.userId = userId
        self.totalSessions = totalSessions
        self.totalEvents = totalEvents
        self.totalUsageTime = totalUsageTime
        self.templatesViewed = templatesViewed
        self.templatesDownloaded = templatesDownloaded
        self.templatesPublished = templatesPublished
        self.searchesPerformed = searchesPerformed
        self.feedbackSubmitted = feedbackSubmitted
        self.lastActive = lastActive
        self.firstSeen = firstSeen
        self.subscriptionTier = subscriptionTier
        self.lifetimeValue = lifetimeValue
    }
    
    /// Calculate user engagement level
    var engagementLevel: EngagementLevel {
        let daysSinceFirstSeen = Date().timeIntervalSince(firstSeen) / 86400
        guard daysSinceFirstSeen > 0 else { return .new }
        
        let eventsPerDay = Double(totalEvents) / daysSinceFirstSeen
        
        if eventsPerDay > 50 {
            return .powerUser
        } else if eventsPerDay > 20 {
            return .active
        } else if eventsPerDay > 5 {
            return .moderate
        } else if eventsPerDay > 1 {
            return .casual
        } else {
            return .dormant
        }
    }
    
    /// Check if user is at risk of churning
    var isChurnRisk: Bool {
        let daysSinceActive = Date().timeIntervalSince(lastActive) / 86400
        return daysSinceActive > 14 && engagementLevel != .powerUser
    }
}

/// User engagement levels
enum EngagementLevel: String, Codable {
    case new = "new"
    case casual = "casual"
    case moderate = "moderate"
    case active = "active"
    case powerUser = "power_user"
    case dormant = "dormant"
}

/// Search analytics
@Model
class SearchAnalytics {
    @Attribute(.unique) var id: UUID
    var query: String
    var count: Int
    var resultsFound: Int
    var clickThroughRate: Double
    var lastSearched: Date
    
    init(
        id: UUID = UUID(),
        query: String,
        count: Int = 1,
        resultsFound: Int = 0,
        clickThroughRate: Double = 0,
        lastSearched: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.count = count
        self.resultsFound = resultsFound
        self.clickThroughRate = clickThroughRate
        self.lastSearched = lastSearched
    }
}

/// Performance metrics for analytics
@Model
class AnalyticsPerformanceMetrics {
    @Attribute(.unique) var id: UUID
    var metricName: String
    var value: Double
    var timestamp: Date
    var context: String // JSON encoded context
    
    init(
        id: UUID = UUID(),
        metricName: String,
        value: Double,
        timestamp: Date = Date(),
        context: String = "{}"
    ) {
        self.id = id
        self.metricName = metricName
        self.value = value
        self.timestamp = timestamp
        self.context = context
    }
}

/// Common performance metric names
enum PerformanceMetricName: String {
    case appLaunchTime = "app_launch_time"
    case templateLoadTime = "template_load_time"
    case searchResponseTime = "search_response_time"
    case buildTime = "build_time"
    case memoryUsage = "memory_usage"
    case cpuUsage = "cpu_usage"
    case networkLatency = "network_latency"
    case databaseQueryTime = "database_query_time"
}
