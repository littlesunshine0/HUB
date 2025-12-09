//
import SwiftUI

//  AnalyticsAggregator.swift
//  Hub
//
//  Service for aggregating analytics events into insights
//

import Foundation
import SwiftData

/// Actor responsible for aggregating analytics events
actor AnalyticsAggregator {
    private let modelContainer: ModelContainer
    private let storageService: AnalyticsStorageService
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.storageService = AnalyticsStorageService(modelContainer: modelContainer)
    }
    
    // MARK: - Aggregate Updates
    
    /// Update aggregates based on processed events
    func updateAggregates(for events: [AnalyticsEvent]) async throws {
        // Group events by date
        let eventsByDate = Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.timestamp)
        }
        
        // Update daily analytics for each date
        for (date, dateEvents) in eventsByDate {
            try await updateDailyAnalytics(for: date, events: dateEvents)
        }
        
        // Update template analytics
        try await updateTemplateAnalytics(for: events)
        
        // Update user analytics
        try await updateUserAnalytics(for: events)
        
        // Update search analytics
        try await updateSearchAnalytics(for: events)
    }
    
    // MARK: - Daily Analytics
    
    /// Update daily analytics for a specific date
    private func updateDailyAnalytics(for date: Date, events: [AnalyticsEvent]) async throws {
        let context = ModelContext(modelContainer)
        
        // Fetch or create daily analytics
        let descriptor = FetchDescriptor<DailyAnalytics>(
            predicate: #Predicate { $0.date == date }
        )
        
        let dailyAnalytics: DailyAnalytics
        if let existing = try context.fetch(descriptor).first {
            dailyAnalytics = existing
        } else {
            dailyAnalytics = DailyAnalytics(date: date)
            context.insert(dailyAnalytics)
        }
        
        // Update metrics
        dailyAnalytics.events += events.count
        
        // Count unique users
        let uniqueUsers = Set(events.compactMap { $0.userId })
        dailyAnalytics.activeUsers = uniqueUsers.count
        
        // Count sessions
        let uniqueSessions = Set(events.map { $0.sessionId })
        dailyAnalytics.sessions = uniqueSessions.count
        
        // Calculate revenue
        let purchaseEvents = events.filter { $0.type == EventType.purchaseCompleted.rawValue }
        let revenue = purchaseEvents.compactMap { event -> Decimal? in
            guard let amount = event.getMetadata()[EventMetadata.amount] as? Decimal else { return nil }
            return amount
        }.reduce(0, +)
        dailyAnalytics.revenue += revenue
        
        // Count errors
        let errorEvents = events.filter { 
            $0.type == EventType.errorOccurred.rawValue || 
            $0.type == EventType.crashReported.rawValue 
        }
        dailyAnalytics.errorCount += errorEvents.filter { $0.type == EventType.errorOccurred.rawValue }.count
        dailyAnalytics.crashCount += errorEvents.filter { $0.type == EventType.crashReported.rawValue }.count
        
        // Update top templates
        let templateEvents = events.filter { 
            $0.type == EventType.templateView.rawValue ||
            $0.type == EventType.templateDownload.rawValue
        }
        let templateCounts = Dictionary(grouping: templateEvents) { $0.itemId?.uuidString ?? "" }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
        dailyAnalytics.topTemplates = Array(templateCounts)
        
        // Update top searches
        let searchEvents = events.filter { $0.type == EventType.searchQuery.rawValue }
        let searchCounts = Dictionary(grouping: searchEvents) { event -> String in
            event.getMetadata()[EventMetadata.searchQuery] as? String ?? ""
        }
        .mapValues { $0.count }
        .sorted { $0.value > $1.value }
        .prefix(10)
        .map { $0.key }
        dailyAnalytics.topSearches = Array(searchCounts)
        
        try context.save()
    }
    
    // MARK: - Template Analytics
    
    /// Update template analytics based on events
    private func updateTemplateAnalytics(for events: [AnalyticsEvent]) async throws {
        // Group events by template
        let templateEvents = events.filter { $0.itemId != nil }
        let eventsByTemplate = Dictionary(grouping: templateEvents) { $0.itemId! }
        
        for (templateId, templateEvents) in eventsByTemplate {
            try await updateSingleTemplateAnalytics(templateId: templateId, events: templateEvents)
        }
    }
    
    /// Update analytics for a single template
    private func updateSingleTemplateAnalytics(templateId: UUID, events: [AnalyticsEvent]) async throws {
        let context = ModelContext(modelContainer)
        
        // Fetch or create template analytics
        let descriptor = FetchDescriptor<MarketplaceTemplateAnalytics>(
            predicate: #Predicate { $0.templateId == templateId }
        )
        
        let analytics: MarketplaceTemplateAnalytics
        if let existing = try context.fetch(descriptor).first {
            analytics = existing
        } else {
            analytics = MarketplaceTemplateAnalytics(templateId: templateId)
            context.insert(analytics)
        }
        
        // Update metrics
        for event in events {
            guard let eventType = event.getEventType() else { continue }
            
            switch eventType {
            case .templateView:
                analytics.views += 1
            case .templateDownload:
                analytics.downloads += 1
            case .templateUsage:
                analytics.usageTime += event.duration ?? 0
            case .templateCustomization:
                analytics.customizations += 1
            case .templatePublish:
                analytics.publishes += 1
            case .purchaseCompleted:
                if let amount = event.getMetadata()[EventMetadata.amount] as? Decimal {
                    analytics.revenue += amount
                }
            case .ratingGiven, .reviewWritten:
                if let rating = event.getMetadata()[EventMetadata.rating] as? Double {
                    // Update average rating
                    let totalRating = analytics.rating * Double(analytics.reviewCount)
                    analytics.reviewCount += 1
                    analytics.rating = (totalRating + rating) / Double(analytics.reviewCount)
                }
            default:
                break
            }
        }
        
        analytics.lastUpdated = Date()
        try context.save()
    }
    
    // MARK: - User Analytics
    
    /// Update user analytics based on events
    private func updateUserAnalytics(for events: [AnalyticsEvent]) async throws {
        // Group events by user
        let userEvents = events.filter { $0.userId != nil }
        let eventsByUser = Dictionary(grouping: userEvents) { $0.userId! }
        
        for (userId, userEvents) in eventsByUser {
            try await updateSingleUserAnalytics(userId: userId, events: userEvents)
        }
    }
    
    /// Update analytics for a single user
    private func updateSingleUserAnalytics(userId: UUID, events: [AnalyticsEvent]) async throws {
        let context = ModelContext(modelContainer)
        
        // Fetch or create user analytics
        let descriptor = FetchDescriptor<UserAnalytics>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        let analytics: UserAnalytics
        if let existing = try context.fetch(descriptor).first {
            analytics = existing
        } else {
            analytics = UserAnalytics(userId: userId)
            context.insert(analytics)
        }
        
        // Update metrics
        analytics.totalEvents += events.count
        
        // Count unique sessions
        let uniqueSessions = Set(events.map { $0.sessionId })
        analytics.totalSessions += uniqueSessions.count
        
        // Calculate total usage time
        let usageTime = events.compactMap { $0.duration }.reduce(0, +)
        analytics.totalUsageTime += usageTime
        
        // Count specific event types
        for event in events {
            guard let eventType = event.getEventType() else { continue }
            
            switch eventType {
            case .templateView:
                analytics.templatesViewed += 1
            case .templateDownload:
                analytics.templatesDownloaded += 1
            case .templatePublish:
                analytics.templatesPublished += 1
            case .searchQuery:
                analytics.searchesPerformed += 1
            case .feedbackSubmitted, .ratingGiven, .reviewWritten:
                analytics.feedbackSubmitted += 1
            case .purchaseCompleted:
                if let amount = event.getMetadata()[EventMetadata.amount] as? Decimal {
                    analytics.lifetimeValue += amount
                }
            case .subscriptionStarted, .subscriptionUpgraded:
                if let tier = event.getMetadata()[EventMetadata.tier] as? String {
                    analytics.subscriptionTier = tier
                }
            default:
                break
            }
        }
        
        analytics.lastActive = Date()
        try context.save()
    }
    
    // MARK: - Search Analytics
    
    /// Update search analytics based on events
    private func updateSearchAnalytics(for events: [AnalyticsEvent]) async throws {
        let searchEvents = events.filter { $0.type == EventType.searchQuery.rawValue }
        
        for event in searchEvents {
            guard let query = event.getMetadata()[EventMetadata.searchQuery] as? String else { continue }
            try await updateSingleSearchAnalytics(query: query, event: event)
        }
    }
    
    /// Update analytics for a single search query
    private func updateSingleSearchAnalytics(query: String, event: AnalyticsEvent) async throws {
        let context = ModelContext(modelContainer)
        
        // Fetch or create search analytics
        let descriptor = FetchDescriptor<SearchAnalytics>(
            predicate: #Predicate { $0.query == query }
        )
        
        let analytics: SearchAnalytics
        if let existing = try context.fetch(descriptor).first {
            analytics = existing
        } else {
            analytics = SearchAnalytics(query: query)
            context.insert(analytics)
        }
        
        // Update metrics
        analytics.count += 1
        analytics.lastSearched = Date()
        
        if let resultsCount = event.getMetadata()["results_count"] as? Int {
            analytics.resultsFound = resultsCount
        }
        
        try context.save()
    }
    
    // MARK: - Aggregate Queries
    
    /// Get daily analytics for a date range
    func getDailyAnalytics(startDate: Date, endDate: Date) async throws -> [DailyAnalytics] {
        return try await storageService.fetchDailyAnalytics(startDate: startDate, endDate: endDate)
    }
    
    /// Get template analytics
    func getTemplateAnalytics(templateId: UUID) async throws -> MarketplaceTemplateAnalytics? {
        return try await storageService.fetchTemplateAnalytics(templateId: templateId)
    }
    
    /// Get user analytics
    func getUserAnalytics(userId: UUID) async throws -> UserAnalytics? {
        return try await storageService.fetchUserAnalytics(userId: userId)
    }
}

