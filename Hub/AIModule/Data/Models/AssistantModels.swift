//
//  AssistantModels.swift
//  Hub
//
//  Core models for the Offline Assistant Module
//  Integrates with existing HubModuleUpdate_2 models
//

import Foundation

// MARK: - Assistant Status

/// Represents the operational state of the assistant
enum AssistantStatus: Equatable {
    case initializing
    case ready
    case processing
    case error(String)
    case offline
}

// MARK: - Conversation Topic

/// Categories for conversation routing
enum ConversationTopic: String, Codable {
    case general
    case cardValuation
    case marketAdvice
    case collectionStrategy
    case authentication
    case grading
}

// MARK: - Message Sender

/// Identifies who sent a message (compatible with existing MessageRole)
enum MessageSender: String, Codable {
    case user
    case assistant
    
    /// Convert to MessageRole from HubModuleUpdate_2
    var toMessageRole: MessageRole {
        switch self {
        case .user: return .user
        case .assistant: return .assistant
        }
    }
    
    /// Create from MessageRole
    init(from role: MessageRole) {
        switch role {
        case .user: self = .user
        case .assistant: self = .assistant
        case .system: self = .assistant // Map system to assistant
        }
    }
}

// MARK: - Message Type

/// Categories of messages for specialized rendering
enum MessageType: String, Codable {
    case text
    case cardRecommendation
    case marketAlert
    case insight
    case action
}

// MARK: - Suggestion Models

/// Actionable suggestion for the user from the assistant
struct AssistantSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let category: AssistantSuggestionCategory
    let priority: Priority
    let actionable: Bool
    var estimatedImpact: String?
    var relatedEntryId: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: AssistantSuggestionCategory,
        priority: Priority,
        actionable: Bool = true,
        estimatedImpact: String? = nil,
        relatedEntryId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.actionable = actionable
        self.estimatedImpact = estimatedImpact
        self.relatedEntryId = relatedEntryId
    }
}

enum AssistantSuggestionCategory: String, Codable {
    case buying
    case selling
    case grading
    case organizing
    case learning
}

enum Priority: String, Codable {
    case low
    case medium
    case high
    case urgent
}

// MARK: - Learning Insights

/// AI-generated insights about user behavior and patterns
struct LearningInsight: Identifiable, Codable, Equatable {
    let id: UUID
    let category: InsightCategory
    let title: String
    let description: String
    let confidence: Double
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        category: InsightCategory,
        title: String,
        description: String,
        confidence: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

enum InsightCategory: String, Codable {
    case userPreference
    case marketPattern
    case behaviorTrend
    case collectionGap
}

// MARK: - Search Models

/// Filter options for knowledge base search
enum SearchFilter: Equatable {
    case domain(String)
    case contentType(String)
    case dateRange(from: Date, to: Date)
    case entityType(String)
}

// Note: EntityType is defined in EntityExtractor.swift as static constants
// We don't redefine it here to avoid conflicts

// Note: DiagnosticsSnapshot, BackoffMetrics, and DiagnosticError are defined in DiagnosticsModels.swift
// We don't redefine them here to avoid conflicts
