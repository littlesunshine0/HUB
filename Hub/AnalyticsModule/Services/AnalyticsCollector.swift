//
import SwiftUI

//  AnalyticsCollector.swift
//  Hub
//
//  Main service for collecting and tracking analytics events
//

import Foundation
import SwiftData
import Combine

/// Main analytics collector service
@MainActor
class AnalyticsCollector: ObservableObject {
    @Published private(set) var isEnabled: Bool = true
    @Published private(set) var eventCount: Int = 0
    
    private let storageService: AnalyticsStorageService
    private let sessionManager: AnalyticsSessionManager
    private var eventQueue: [AnalyticsEvent] = []
    private let batchSize = 50
    private var flushTask: Task<Void, Never>?
    
    private static var _shared: AnalyticsCollector?
    
    static func shared(modelContainer: ModelContainer) -> AnalyticsCollector {
        if _shared == nil {
            _shared = AnalyticsCollector(modelContainer: modelContainer)
        }
        return _shared!
    }
    
    private init(modelContainer: ModelContainer) {
        self.storageService = AnalyticsStorageService(modelContainer: modelContainer)
        self.sessionManager = AnalyticsSessionManager.shared
        
        // Start periodic flush
        startPeriodicFlush()
    }
    
    deinit {
        flushTask?.cancel()
    }
    
    // MARK: - Event Tracking
    
    /// Track an analytics event
    func trackEvent(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        eventQueue.append(event)
        eventCount += 1
        sessionManager.incrementEventCount()
        
        // Flush if batch size reached
        if eventQueue.count >= batchSize {
            Task {
                await flush()
            }
        }
    }
    
    /// Track event using builder
    func trackEvent(
        type: EventType,
        userId: UUID? = nil,
        itemId: UUID? = nil,
        duration: TimeInterval? = nil,
        metadata: [String: Any] = [:]
    ) {
        let session = sessionManager.getCurrentSession(userId: userId)
        let event = AnalyticsEventBuilder(type: type, sessionId: session.id)
            .withUser(userId ?? session.userId ?? UUID())
            .withItem(itemId ?? UUID())
            .withDuration(duration ?? 0)
            .withMetadata(metadata)
            .build()
        
        trackEvent(event)
    }
    
    /// Track template view
    func trackTemplateView(templateId: UUID, userId: UUID? = nil) {
        trackEvent(
            type: .templateView,
            userId: userId,
            itemId: templateId,
            metadata: [EventMetadata.templateId: templateId.uuidString]
        )
    }
    
    /// Track template download
    func trackTemplateDownload(templateId: UUID, userId: UUID? = nil) {
        trackEvent(
            type: .templateDownload,
            userId: userId,
            itemId: templateId,
            metadata: [EventMetadata.templateId: templateId.uuidString]
        )
    }
    
    /// Track template usage
    func trackTemplateUsage(templateId: UUID, duration: TimeInterval, userId: UUID? = nil) {
        trackEvent(
            type: .templateUsage,
            userId: userId,
            itemId: templateId,
            duration: duration,
            metadata: [
                EventMetadata.templateId: templateId.uuidString,
                EventMetadata.duration: duration
            ]
        )
    }
    
    /// Track search query
    func trackSearch(query: String, resultsCount: Int, userId: UUID? = nil) {
        trackEvent(
            type: .searchQuery,
            userId: userId,
            metadata: [
                EventMetadata.searchQuery: query,
                "results_count": resultsCount
            ]
        )
    }
    
    /// Track purchase
    func trackPurchase(itemId: UUID, amount: Decimal, currency: String, userId: UUID? = nil) {
        trackEvent(
            type: .purchaseCompleted,
            userId: userId,
            itemId: itemId,
            metadata: [
                EventMetadata.amount: amount,
                EventMetadata.currency: currency
            ]
        )
    }
    
    /// Track subscription event
    func trackSubscription(tier: String, type: EventType, userId: UUID? = nil) {
        trackEvent(
            type: type,
            userId: userId,
            metadata: [EventMetadata.tier: tier]
        )
    }
    
    /// Track feedback
    func trackFeedback(rating: Int, comment: String?, itemId: UUID? = nil, userId: UUID? = nil) {
        var metadata: [String: Any] = [EventMetadata.rating: rating]
        if let comment = comment {
            metadata[EventMetadata.comment] = comment
        }
        
        trackEvent(
            type: .feedbackSubmitted,
            userId: userId,
            itemId: itemId,
            metadata: metadata
        )
    }
    
    /// Track error
    func trackError(message: String, code: String? = nil, userId: UUID? = nil) {
        var metadata: [String: Any] = [EventMetadata.errorMessage: message]
        if let code = code {
            metadata[EventMetadata.errorCode] = code
        }
        
        trackEvent(
            type: .errorOccurred,
            userId: userId,
            metadata: metadata
        )
    }
    
    /// Track performance metric
    func trackPerformance(metricName: String, value: Double, userId: UUID? = nil) {
        trackEvent(
            type: .performanceMetric,
            userId: userId,
            metadata: [
                EventMetadata.performanceMetricName: metricName,
                EventMetadata.performanceMetricValue: value
            ]
        )
    }
    
    /// Track page view
    func trackPageView(screenName: String, userId: UUID? = nil) {
        trackEvent(
            type: .pageView,
            userId: userId,
            metadata: [EventMetadata.screenName: screenName]
        )
    }
    
    /// Track button click
    func trackButtonClick(buttonName: String, screenName: String, userId: UUID? = nil) {
        trackEvent(
            type: .buttonClick,
            userId: userId,
            metadata: [
                EventMetadata.buttonName: buttonName,
                EventMetadata.screenName: screenName
            ]
        )
    }
    
    // MARK: - Session Management
    
    /// Start a new analytics session
    func startSession(userId: UUID? = nil) {
        let session = sessionManager.startSession(userId: userId)
        
        trackEvent(
            type: .sessionStarted,
            userId: userId,
            metadata: [
                "device_info": session.deviceInfo,
                "app_version": session.appVersion,
                "os_version": session.osVersion
            ]
        )
    }
    
    /// End current session
    func endSession() {
        sessionManager.endSession()
        
        if let session = sessionManager.currentSession {
            trackEvent(
                type: .sessionEnded,
                userId: session.userId,
                duration: session.currentDuration,
                metadata: [
                    "event_count": session.eventCount,
                    "duration": session.currentDuration
                ]
            )
        }
        
        Task {
            await flush()
        }
    }
    
    // MARK: - Batch Processing
    
    /// Flush queued events to storage
    func flush() async {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToFlush = eventQueue
        eventQueue.removeAll()
        
        do {
            try await storageService.storeEvents(eventsToFlush)
        } catch {
            print("Failed to flush analytics events: \(error)")
            // Re-queue failed events
            eventQueue.append(contentsOf: eventsToFlush)
        }
    }
    
    /// Start periodic flush timer
    private func startPeriodicFlush() {
        flushTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                await flush()
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Enable or disable analytics collection
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        
        if !enabled {
            // Flush remaining events before disabling
            Task {
                await flush()
            }
        }
    }
    
    /// Get current session
    func getCurrentSession() -> AnalyticsSession? {
        return sessionManager.currentSession
    }
}

/// Analytics collector extensions for SwiftUI
extension AnalyticsCollector {
    /// Track view appearance
    func trackViewAppear(_ viewName: String, userId: UUID? = nil) {
        trackPageView(screenName: viewName, userId: userId)
    }
    
    /// Track view disappearance
    func trackViewDisappear(_ viewName: String, duration: TimeInterval, userId: UUID? = nil) {
        trackEvent(
            type: .pageView,
            userId: userId,
            duration: duration,
            metadata: [
                EventMetadata.screenName: viewName,
                EventMetadata.duration: duration,
                "action": "disappear"
            ]
        )
    }
}
