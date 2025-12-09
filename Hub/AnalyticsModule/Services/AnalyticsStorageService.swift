//
import SwiftUI

//  AnalyticsStorageService.swift
//  Hub
//
//  Storage service for analytics events using SwiftData and CloudKit
//

import Foundation
import SwiftData
import CloudKit

/// Service for storing and retrieving analytics events
actor AnalyticsStorageService {
    private let modelContainer: ModelContainer
    private let cloudKitSync: AnalyticsCloudKitSync
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.cloudKitSync = AnalyticsCloudKitSync()
    }
    
    // MARK: - Event Storage
    
    /// Store a single analytics event
    func storeEvent(_ event: AnalyticsEvent) async throws {
        let context = ModelContext(modelContainer)
        context.insert(event)
        try context.save()
        
        // Sync to CloudKit if enabled
        await cloudKitSync.syncEvent(event)
    }
    
    /// Store multiple analytics events in batch
    func storeEvents(_ events: [AnalyticsEvent]) async throws {
        let context = ModelContext(modelContainer)
        for event in events {
            context.insert(event)
        }
        try context.save()
        
        // Sync to CloudKit if enabled
        await cloudKitSync.syncEvents(events)
    }
    
    /// Fetch events by criteria
    func fetchEvents(
        userId: UUID? = nil,
        itemId: UUID? = nil,
        sessionId: UUID? = nil,
        eventType: EventType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int? = nil
    ) async throws -> [AnalyticsEvent] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<AnalyticsEvent>()
        
        // Build predicate
        var predicates: [Predicate<AnalyticsEvent>] = []
        
        if let userId = userId {
            predicates.append(#Predicate { $0.userId == userId })
        }
        
        if let itemId = itemId {
            predicates.append(#Predicate { $0.itemId == itemId })
        }
        
        if let sessionId = sessionId {
            predicates.append(#Predicate { $0.sessionId == sessionId })
        }
        
        if let eventType = eventType {
            let typeString = eventType.rawValue
            predicates.append(#Predicate { $0.type == typeString })
        }
        
        if let startDate = startDate {
            predicates.append(#Predicate { $0.timestamp >= startDate })
        }
        
        if let endDate = endDate {
            predicates.append(#Predicate { $0.timestamp <= endDate })
        }
        
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(into: predicates[0]) { result, predicate in
                result = #Predicate { event in
                    predicates.allSatisfy { $0.evaluate(event) }
                }
            }
        }
        
        // Sort by timestamp descending
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        
        // Apply limit
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try context.fetch(descriptor)
    }
    
    /// Mark events as processed
    func markEventsAsProcessed(_ eventIds: [UUID]) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { event in
                eventIds.contains(event.id)
            }
        )
        
        let events = try context.fetch(descriptor)
        for event in events {
            event.processed = true
        }
        try context.save()
    }
    
    /// Delete old events (data retention)
    func deleteEventsOlderThan(_ date: Date) async throws -> Int {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.timestamp < date }
        )
        
        let events = try context.fetch(descriptor)
        let count = events.count
        
        for event in events {
            context.delete(event)
        }
        try context.save()
        
        return count
    }
    
    // MARK: - Session Storage
    
    /// Store analytics session
    func storeSession(_ session: AnalyticsSession) async throws {
        let context = ModelContext(modelContainer)
        context.insert(session)
        try context.save()
    }
    
    /// Fetch sessions
    func fetchSessions(
        userId: UUID? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        activeOnly: Bool = false
    ) async throws -> [AnalyticsSession] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<AnalyticsSession>()
        
        var predicates: [Predicate<AnalyticsSession>] = []
        
        if let userId = userId {
            predicates.append(#Predicate { $0.userId == userId })
        }
        
        if let startDate = startDate {
            predicates.append(#Predicate { $0.startTime >= startDate })
        }
        
        if let endDate = endDate {
            predicates.append(#Predicate { $0.startTime <= endDate })
        }
        
        if activeOnly {
            predicates.append(#Predicate { $0.isActive == true })
        }
        
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(into: predicates[0]) { result, predicate in
                result = #Predicate { session in
                    predicates.allSatisfy { $0.evaluate(session) }
                }
            }
        }
        
        descriptor.sortBy = [SortDescriptor(\.startTime, order: .reverse)]
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Aggregate Storage
    
    /// Store daily analytics
    func storeDailyAnalytics(_ analytics: DailyAnalytics) async throws {
        let context = ModelContext(modelContainer)
        context.insert(analytics)
        try context.save()
    }
    
    /// Fetch daily analytics
    func fetchDailyAnalytics(startDate: Date, endDate: Date) async throws -> [DailyAnalytics] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DailyAnalytics>(
            predicate: #Predicate { analytics in
                analytics.date >= startDate && analytics.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Store or update template analytics
    func storeTemplateAnalytics(_ analytics: MarketplaceTemplateAnalytics) async throws {
        let context = ModelContext(modelContainer)
        
        // Check if analytics already exists
        let templateId = analytics.templateId
        let descriptor = FetchDescriptor<MarketplaceTemplateAnalytics>(
            predicate: #Predicate { $0.templateId == templateId }
        )
        
        if let existing = try context.fetch(descriptor).first {
            // Update existing
            existing.views = analytics.views
            existing.downloads = analytics.downloads
            existing.usageTime = analytics.usageTime
            existing.customizations = analytics.customizations
            existing.publishes = analytics.publishes
            existing.rating = analytics.rating
            existing.reviewCount = analytics.reviewCount
            existing.revenue = analytics.revenue
            existing.lastUpdated = Date()
        } else {
            // Insert new
            context.insert(analytics)
        }
        
        try context.save()
    }
    
    /// Fetch template analytics
    func fetchTemplateAnalytics(templateId: UUID) async throws -> MarketplaceTemplateAnalytics? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<MarketplaceTemplateAnalytics>(
            predicate: #Predicate { $0.templateId == templateId }
        )
        
        return try context.fetch(descriptor).first
    }
    
    /// Store or update user analytics
    func storeUserAnalytics(_ analytics: UserAnalytics) async throws {
        let context = ModelContext(modelContainer)
        
        // Check if analytics already exists
        let userId = analytics.userId
        let descriptor = FetchDescriptor<UserAnalytics>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let existing = try context.fetch(descriptor).first {
            // Update existing
            existing.totalSessions = analytics.totalSessions
            existing.totalEvents = analytics.totalEvents
            existing.totalUsageTime = analytics.totalUsageTime
            existing.templatesViewed = analytics.templatesViewed
            existing.templatesDownloaded = analytics.templatesDownloaded
            existing.templatesPublished = analytics.templatesPublished
            existing.searchesPerformed = analytics.searchesPerformed
            existing.feedbackSubmitted = analytics.feedbackSubmitted
            existing.lastActive = analytics.lastActive
            existing.subscriptionTier = analytics.subscriptionTier
            existing.lifetimeValue = analytics.lifetimeValue
        } else {
            // Insert new
            context.insert(analytics)
        }
        
        try context.save()
    }
    
    /// Fetch user analytics
    func fetchUserAnalytics(userId: UUID) async throws -> UserAnalytics? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<UserAnalytics>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Performance Metrics
    
    /// Store performance metric
    func storePerformanceMetric(_ metric: AnalyticsPerformanceMetrics) async throws {
        let context = ModelContext(modelContainer)
        context.insert(metric)
        try context.save()
    }
    
    /// Fetch performance metrics
    func fetchPerformanceMetrics(
        metricName: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [AnalyticsPerformanceMetrics] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AnalyticsPerformanceMetrics>(
            predicate: #Predicate { metric in
                metric.metricName == metricName &&
                metric.timestamp >= startDate &&
                metric.timestamp <= endDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
}

/// CloudKit sync service for analytics
actor AnalyticsCloudKitSync {
    private let container: CKContainer?
    private let database: CKDatabase?
    private var syncEnabled = false // Disabled by default to avoid CloudKit exceptions
    
    init() {
        // CloudKit disabled by default - requires proper entitlements and configuration
        // To enable: Add CloudKit capability in Xcode and call setSyncEnabled(true)
        self.container = nil
        self.database = nil
        print("ℹ️ AnalyticsCloudKitSync initialized (CloudKit disabled - requires entitlements)")
    }
    
    /// Sync single event to CloudKit
    func syncEvent(_ event: AnalyticsEvent) async {
        guard syncEnabled, let database = database else { return }
        
        let record = CKRecord(recordType: "AnalyticsEvent")
        record["id"] = event.id.uuidString
        record["type"] = event.type
        record["userId"] = event.userId?.uuidString
        record["itemId"] = event.itemId?.uuidString
        record["sessionId"] = event.sessionId.uuidString
        record["timestamp"] = event.timestamp
        record["duration"] = event.duration ?? 0
        record["metadata"] = event.metadata
        record["processed"] = event.processed ? 1 : 0
        
        do {
            _ = try await database.save(record)
        } catch {
            print("Failed to sync event to CloudKit: \(error)")
        }
    }
    
    /// Sync multiple events to CloudKit
    func syncEvents(_ events: [AnalyticsEvent]) async {
        guard syncEnabled, let database = database else { return }
        
        let records = events.map { event -> CKRecord in
            let record = CKRecord(recordType: "AnalyticsEvent")
            record["id"] = event.id.uuidString
            record["type"] = event.type
            record["userId"] = event.userId?.uuidString
            record["itemId"] = event.itemId?.uuidString
            record["sessionId"] = event.sessionId.uuidString
            record["timestamp"] = event.timestamp
            record["duration"] = event.duration ?? 0
            record["metadata"] = event.metadata
            record["processed"] = event.processed ? 1 : 0
            return record
        }
        
        // Batch save
        do {
            _ = try await database.modifyRecords(saving: records, deleting: [])
        } catch {
            print("Failed to sync events to CloudKit: \(error)")
        }
    }
    
    /// Enable or disable CloudKit sync
    func setSyncEnabled(_ enabled: Bool) {
        syncEnabled = enabled
    }
}
