//
import SwiftUI

//  AnalyticsEvent.swift
//  Hub
//
//  Analytics event models for the Autonomous Marketplace System
//

import Foundation
import SwiftData

/// Core analytics event model for tracking user interactions and system events
@Model
class AnalyticsEvent {
    @Attribute(.unique) var id: UUID
    var type: String // EventType raw value
    var userId: UUID?
    var itemId: UUID?
    var sessionId: UUID
    var timestamp: Date
    var duration: TimeInterval?
    var metadata: Data // JSON encoded metadata
    var processed: Bool
    
    init(
        id: UUID = UUID(),
        type: EventType,
        userId: UUID? = nil,
        itemId: UUID? = nil,
        sessionId: UUID,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        metadata: [String: Any] = [:],
        processed: Bool = false
    ) {
        self.id = id
        self.type = type.rawValue
        self.userId = userId
        self.itemId = itemId
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.duration = duration
        self.processed = processed
        
        // Encode metadata to Data
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata) {
            self.metadata = jsonData
        } else {
            self.metadata = Data()
        }
    }
    
    /// Decode metadata from Data
    func getMetadata() -> [String: Any] {
        guard !metadata.isEmpty else { return [:] }
        return (try? JSONSerialization.jsonObject(with: metadata) as? [String: Any]) ?? [:]
    }
    
    /// Get the event type
    func getEventType() -> EventType? {
        return EventType(rawValue: type)
    }
}

/// Types of analytics events that can be tracked
enum EventType: String, Codable, CaseIterable {
    // Template events
    case templateView = "template_view"
    case templateDownload = "template_download"
    case templateUsage = "template_usage"
    case templateCustomization = "template_customization"
    case templatePublish = "template_publish"
    
    // Component events
    case componentUsage = "component_usage"
    case componentCustomization = "component_customization"
    
    // Search events
    case searchQuery = "search_query"
    case searchResultClick = "search_result_click"
    
    // Purchase events
    case purchaseInitiated = "purchase_initiated"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    
    // Subscription events
    case subscriptionStarted = "subscription_started"
    case subscriptionRenewed = "subscription_renewed"
    case subscriptionCanceled = "subscription_canceled"
    case subscriptionUpgraded = "subscription_upgraded"
    case subscriptionDowngraded = "subscription_downgraded"
    
    // Feedback events
    case feedbackSubmitted = "feedback_submitted"
    case ratingGiven = "rating_given"
    case reviewWritten = "review_written"
    case bugReported = "bug_reported"
    case featureRequested = "feature_requested"
    
    // User behavior events
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case pageView = "page_view"
    case buttonClick = "button_click"
    case formSubmitted = "form_submitted"
    
    // Build events
    case buildStarted = "build_started"
    case buildCompleted = "build_completed"
    case buildFailed = "build_failed"
    
    // Error events
    case errorOccurred = "error_occurred"
    case crashReported = "crash_reported"
    
    // Performance events
    case performanceMetric = "performance_metric"
    case loadTimeRecorded = "load_time_recorded"
    
    // AI events
    case aiAssistanceUsed = "ai_assistance_used"
    case aiSuggestionAccepted = "ai_suggestion_accepted"
    case aiSuggestionRejected = "ai_suggestion_rejected"
    
    // Community events
    case contentShared = "content_shared"
    case contentLiked = "content_liked"
    case contentCommented = "content_commented"
    case userFollowed = "user_followed"
}

/// Event metadata builder for type-safe metadata construction
struct EventMetadata {
    private var data: [String: Any] = [:]
    
    mutating func set(_ key: String, value: Any) {
        data[key] = value
    }
    
    func build() -> [String: Any] {
        return data
    }
    
    // Common metadata keys
    static let templateId = "template_id"
    static let componentId = "component_id"
    static let searchQuery = "search_query"
    static let amount = "amount"
    static let currency = "currency"
    static let tier = "tier"
    static let rating = "rating"
    static let comment = "comment"
    static let errorMessage = "error_message"
    static let errorCode = "error_code"
    static let duration = "duration"
    static let screenName = "screen_name"
    static let buttonName = "button_name"
    static let buildType = "build_type"
    static let performanceMetricName = "metric_name"
    static let performanceMetricValue = "metric_value"
}

/// Analytics event builder for convenient event creation
struct AnalyticsEventBuilder {
    private var type: EventType
    private var userId: UUID?
    private var itemId: UUID?
    private var sessionId: UUID
    private var duration: TimeInterval?
    private var metadata: [String: Any] = [:]
    
    init(type: EventType, sessionId: UUID) {
        self.type = type
        self.sessionId = sessionId
    }
    
    func withUser(_ userId: UUID) -> AnalyticsEventBuilder {
        var builder = self
        builder.userId = userId
        return builder
    }
    
    func withItem(_ itemId: UUID) -> AnalyticsEventBuilder {
        var builder = self
        builder.itemId = itemId
        return builder
    }
    
    func withDuration(_ duration: TimeInterval) -> AnalyticsEventBuilder {
        var builder = self
        builder.duration = duration
        return builder
    }
    
    func withMetadata(_ key: String, value: Any) -> AnalyticsEventBuilder {
        var builder = self
        builder.metadata[key] = value
        return builder
    }
    
    func withMetadata(_ metadata: [String: Any]) -> AnalyticsEventBuilder {
        var builder = self
        builder.metadata.merge(metadata) { _, new in new }
        return builder
    }
    
    func build() -> AnalyticsEvent {
        return AnalyticsEvent(
            type: type,
            userId: userId,
            itemId: itemId,
            sessionId: sessionId,
            duration: duration,
            metadata: metadata
        )
    }
}
