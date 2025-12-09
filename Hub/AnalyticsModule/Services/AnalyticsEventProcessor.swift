//
import SwiftUI

//  AnalyticsEventProcessor.swift
//  Hub
//
//  Event processing pipeline for analytics events
//

import Foundation
import SwiftData

/// Actor responsible for processing analytics events in real-time
actor AnalyticsEventProcessor {
    private let storageService: AnalyticsStorageService
    private let aggregator: AnalyticsAggregator
    private var processingQueue: [AnalyticsEvent] = []
    private var isProcessing = false
    
    init(modelContainer: ModelContainer) {
        self.storageService = AnalyticsStorageService(modelContainer: modelContainer)
        self.aggregator = AnalyticsAggregator(modelContainer: modelContainer)
    }
    
    // MARK: - Event Processing
    
    /// Process a single analytics event
    func processEvent(_ event: AnalyticsEvent) async throws {
        // Add to processing queue
        processingQueue.append(event)
        
        // Start processing if not already running
        if !isProcessing {
            try await processQueue()
        }
    }
    
    /// Process multiple events in batch
    func processEvents(_ events: [AnalyticsEvent]) async throws {
        // Add to processing queue
        processingQueue.append(contentsOf: events)
        
        // Start processing if not already running
        if !isProcessing {
            try await processQueue()
        }
    }
    
    /// Process the event queue
    private func processQueue() async throws {
        guard !processingQueue.isEmpty else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Process events in batches
        let batchSize = 100
        while !processingQueue.isEmpty {
            let batch = Array(processingQueue.prefix(batchSize))
            processingQueue.removeFirst(min(batchSize, processingQueue.count))
            
            // Process each event
            for event in batch {
                try await processSingleEvent(event)
            }
            
            // Update aggregates for this batch
            try await aggregator.updateAggregates(for: batch)
        }
    }
    
    /// Process a single event
    private func processSingleEvent(_ event: AnalyticsEvent) async throws {
        // Validate event
        guard validateEvent(event) else {
            print("Invalid event: \(event.id)")
            return
        }
        
        // Enrich event with additional data
        let enrichedEvent = enrichEvent(event)
        
        // Store event
        try await storageService.storeEvent(enrichedEvent)
        
        // Mark as processed
        try await storageService.markEventsAsProcessed([enrichedEvent.id])
        
        // Trigger real-time processing
        await processRealTime(enrichedEvent)
    }
    
    // MARK: - Event Validation
    
    /// Validate event data
    private func validateEvent(_ event: AnalyticsEvent) -> Bool {
        // Check required fields
        guard !event.type.isEmpty else { return false }
        guard event.timestamp <= Date() else { return false }
        
        // Validate event type
        guard EventType(rawValue: event.type) != nil else { return false }
        
        return true
    }
    
    // MARK: - Event Enrichment
    
    /// Enrich event with additional context
    private func enrichEvent(_ event: AnalyticsEvent) -> AnalyticsEvent {
        // Add processing timestamp
        var metadata = event.getMetadata()
        metadata["processed_at"] = Date().timeIntervalSince1970
        
        // Add derived fields based on event type
        if let eventType = event.getEventType() {
            switch eventType {
            case .templateView, .templateDownload, .templateUsage:
                metadata["category"] = "template"
            case .searchQuery, .searchResultClick:
                metadata["category"] = "search"
            case .purchaseInitiated, .purchaseCompleted, .purchaseFailed:
                metadata["category"] = "revenue"
            case .subscriptionStarted, .subscriptionRenewed, .subscriptionCanceled:
                metadata["category"] = "subscription"
            case .errorOccurred, .crashReported:
                metadata["category"] = "error"
            default:
                metadata["category"] = "general"
            }
        }
        
        // Create enriched event
        return AnalyticsEvent(
            id: event.id,
            type: event.getEventType() ?? .pageView,
            userId: event.userId,
            itemId: event.itemId,
            sessionId: event.sessionId,
            timestamp: event.timestamp,
            duration: event.duration,
            metadata: metadata,
            processed: true
        )
    }
    
    // MARK: - Real-time Processing
    
    /// Process event in real-time for immediate insights
    private func processRealTime(_ event: AnalyticsEvent) async {
        guard let eventType = event.getEventType() else { return }
        
        switch eventType {
        case .errorOccurred, .crashReported:
            await handleErrorEvent(event)
        case .purchaseCompleted:
            await handlePurchaseEvent(event)
        case .feedbackSubmitted:
            await handleFeedbackEvent(event)
        case .performanceMetric:
            await handlePerformanceEvent(event)
        default:
            break
        }
    }
    
    /// Handle error events
    private func handleErrorEvent(_ event: AnalyticsEvent) async {
        let metadata = event.getMetadata()
        let errorMessage = metadata[EventMetadata.errorMessage] as? String ?? "Unknown error"
        
        print("⚠️ Error detected: \(errorMessage)")
        
        // TODO: Trigger alert if error rate exceeds threshold
        // TODO: Create incident report
    }
    
    /// Handle purchase events
    private func handlePurchaseEvent(_ event: AnalyticsEvent) async {
        let metadata = event.getMetadata()
        let amount = metadata[EventMetadata.amount] as? Decimal ?? 0
        
        print("💰 Purchase completed: \(amount)")
        
        // TODO: Update revenue metrics
        // TODO: Trigger thank you notification
    }
    
    /// Handle feedback events
    private func handleFeedbackEvent(_ event: AnalyticsEvent) async {
        let metadata = event.getMetadata()
        let rating = metadata[EventMetadata.rating] as? Int ?? 0
        
        print("⭐️ Feedback received: \(rating) stars")
        
        // TODO: Analyze sentiment
        // TODO: Trigger follow-up if low rating
    }
    
    /// Handle performance events
    private func handlePerformanceEvent(_ event: AnalyticsEvent) async {
        let metadata = event.getMetadata()
        let metricName = metadata[EventMetadata.performanceMetricName] as? String ?? ""
        let value = metadata[EventMetadata.performanceMetricValue] as? Double ?? 0
        
        print("📊 Performance metric: \(metricName) = \(value)")
        
        // TODO: Check against thresholds
        // TODO: Trigger alert if performance degrades
    }
    
    // MARK: - Queue Management
    
    /// Get current queue size
    func getQueueSize() -> Int {
        return processingQueue.count
    }
    
    /// Clear the processing queue
    func clearQueue() {
        processingQueue.removeAll()
    }
}

