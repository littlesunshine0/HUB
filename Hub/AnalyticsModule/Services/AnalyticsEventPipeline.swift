//
//  AnalyticsEventPipeline.swift
//  Hub
//
//  Complete analytics event collection and processing pipeline
//

import Foundation
import SwiftData
import Combine

/// Main analytics event pipeline that coordinates collection, processing, and storage
@MainActor
class AnalyticsEventPipeline: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var eventsProcessed: Int = 0
    @Published private(set) var eventsQueued: Int = 0
    @Published private(set) var processingRate: Double = 0 // events per second
    
    private let collector: AnalyticsCollector
    private let processor: AnalyticsEventProcessor
    private let aggregator: AnalyticsAggregator
    private let modelContainer: ModelContainer
    
    private var processingTask: Task<Void, Never>?
    private var metricsTask: Task<Void, Never>?
    private var lastProcessedCount: Int = 0
    private var lastMetricsUpdate: Date = Date()
    
    private static var _shared: AnalyticsEventPipeline?
    
    static func shared(modelContainer: ModelContainer) -> AnalyticsEventPipeline {
        if _shared == nil {
            _shared = AnalyticsEventPipeline(modelContainer: modelContainer)
        }
        return _shared!
    }
    
    private init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.collector = AnalyticsCollector.shared(modelContainer: modelContainer)
        self.processor = AnalyticsEventProcessor(modelContainer: modelContainer)
        self.aggregator = AnalyticsAggregator(modelContainer: modelContainer)
    }
    
    // MARK: - Pipeline Control
    
    /// Start the analytics pipeline
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        startProcessingLoop()
        startMetricsCollection()
    }
    
    /// Stop the analytics pipeline
    func stop() async {
        isRunning = false
        
        // Cancel tasks
        processingTask?.cancel()
        metricsTask?.cancel()
        
        // Flush remaining events
        await collector.flush()
    }
    
    /// Pause the analytics pipeline
    func pause() {
        isRunning = false
        processingTask?.cancel()
        metricsTask?.cancel()
    }
    
    /// Resume the analytics pipeline
    func resume() {
        guard !isRunning else { return }
        start()
    }
    
    // MARK: - Event Collection
    
    /// Collect and process an analytics event
    func collectEvent(_ event: AnalyticsEvent) {
        // Add to collector
        collector.trackEvent(event)
        eventsQueued += 1
    }
    
    /// Collect and process multiple events
    func collectEvents(_ events: [AnalyticsEvent]) {
        for event in events {
            collector.trackEvent(event)
        }
        eventsQueued += events.count
    }
    
    /// Collect event using builder pattern
    func collectEvent(
        type: EventType,
        userId: UUID? = nil,
        itemId: UUID? = nil,
        duration: TimeInterval? = nil,
        metadata: [String: Any] = [:]
    ) {
        collector.trackEvent(
            type: type,
            userId: userId,
            itemId: itemId,
            duration: duration,
            metadata: metadata
        )
        eventsQueued += 1
    }
    
    // MARK: - Processing Loop
    
    /// Start the event processing loop
    private func startProcessingLoop() {
        processingTask = Task {
            while !Task.isCancelled && isRunning {
                // Flush collector to get events
                await collector.flush()
                
                // Process events from storage
                await processStoredEvents()
                
                // Wait before next iteration
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }
    
    /// Process events from storage
    private func processStoredEvents() async {
        do {
            // Fetch unprocessed events
            let storageService = AnalyticsStorageService(modelContainer: modelContainer)
            let events = try await storageService.fetchEvents(limit: 100)
            let unprocessedEvents = events.filter { !$0.processed }
            
            guard !unprocessedEvents.isEmpty else { return }
            
            // Process events
            try await processor.processEvents(unprocessedEvents)
            
            // Update metrics
            eventsProcessed += unprocessedEvents.count
            eventsQueued = max(0, eventsQueued - unprocessedEvents.count)
            
        } catch {
            print("Error processing stored events: \(error)")
        }
    }
    
    // MARK: - Metrics Collection
    
    /// Start metrics collection
    private func startMetricsCollection() {
        metricsTask = Task {
            while !Task.isCancelled && isRunning {
                await updateMetrics()
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            }
        }
    }
    
    /// Update pipeline metrics
    private func updateMetrics() async {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastMetricsUpdate)
        
        guard timeDelta > 0 else { return }
        
        // Calculate processing rate
        let eventsDelta = eventsProcessed - lastProcessedCount
        processingRate = Double(eventsDelta) / timeDelta
        
        // Update tracking variables
        lastProcessedCount = eventsProcessed
        lastMetricsUpdate = now
        
        // Get queue size from processor
        let queueSize = await processor.getQueueSize()
        eventsQueued = queueSize
    }
    
    // MARK: - Pipeline Status
    
    /// Get pipeline status
    func getStatus() -> PipelineStatus {
        return PipelineStatus(
            isRunning: isRunning,
            eventsProcessed: eventsProcessed,
            eventsQueued: eventsQueued,
            processingRate: processingRate,
            collectorEnabled: collector.isEnabled
        )
    }
    
    /// Get pipeline health
    func getHealth() async -> PipelineHealth {
        let queueSize = await processor.getQueueSize()
        let isHealthy = isRunning && queueSize < 1000
        let status: HealthStatus = isHealthy ? .healthy : (queueSize > 5000 ? .critical : .degraded)
        
        return PipelineHealth(
            status: status,
            queueSize: queueSize,
            processingRate: processingRate,
            lastUpdate: Date()
        )
    }
    
    // MARK: - Aggregation
    
    /// Trigger manual aggregation
    func triggerAggregation() async throws {
        let storageService = AnalyticsStorageService(modelContainer: modelContainer)
        let events = try await storageService.fetchEvents(limit: 1000)
        try await aggregator.updateAggregates(for: events)
    }
    
    /// Get daily analytics
    func getDailyAnalytics(startDate: Date, endDate: Date) async throws -> [DailyAnalytics] {
        return try await aggregator.getDailyAnalytics(startDate: startDate, endDate: endDate)
    }
    
    /// Get template analytics
    func getTemplateAnalytics(templateId: UUID) async throws -> MarketplaceTemplateAnalytics? {
        return try await aggregator.getTemplateAnalytics(templateId: templateId)
    }
    
    /// Get user analytics
    func getUserAnalytics(userId: UUID) async throws -> UserAnalytics? {
        return try await aggregator.getUserAnalytics(userId: userId)
    }
}

// MARK: - Supporting Types

/// Pipeline status information
struct PipelineStatus {
    let isRunning: Bool
    let eventsProcessed: Int
    let eventsQueued: Int
    let processingRate: Double
    let collectorEnabled: Bool
}

/// Pipeline health information
struct PipelineHealth {
    let status: HealthStatus
    let queueSize: Int
    let processingRate: Double
    let lastUpdate: Date
}

/// Health status levels
enum HealthStatus: String {
    case healthy = "Healthy"
    case degraded = "Degraded"
    case critical = "Critical"
    case stopped = "Stopped"
}

