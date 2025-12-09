//
//  UserProfile.swift
//  Hub
//
//  User profile and preference models for personalized assistance
//

import Foundation

// MARK: - User Profile

/// Complete user profile for personalized assistance
struct UserProfile: Codable, Equatable {
    var preferences: CollectionPreferences
    var behavior: BehaviorPattern
    var goals: [CollectionGoal]
    var expertise: ExpertiseLevel
    var communicationStyle: CommunicationStyle
    
    init(
        preferences: CollectionPreferences = CollectionPreferences(),
        behavior: BehaviorPattern = BehaviorPattern(),
        goals: [CollectionGoal] = [],
        expertise: ExpertiseLevel = .beginner,
        communicationStyle: CommunicationStyle = .friendly
    ) {
        self.preferences = preferences
        self.behavior = behavior
        self.goals = goals
        self.expertise = expertise
        self.communicationStyle = communicationStyle
    }
}

// MARK: - Collection Preferences

/// User preferences for collection management
struct CollectionPreferences: Codable, Equatable {
    var riskTolerance: RiskTolerance
    var investmentHorizon: InvestmentHorizon
    var purchaseFrequency: PurchaseFrequency
    
    init(
        riskTolerance: RiskTolerance = .moderate,
        investmentHorizon: InvestmentHorizon = .medium,
        purchaseFrequency: PurchaseFrequency = .monthly
    ) {
        self.riskTolerance = riskTolerance
        self.investmentHorizon = investmentHorizon
        self.purchaseFrequency = purchaseFrequency
    }
}

enum RiskTolerance: String, Codable {
    case conservative
    case moderate
    case aggressive
}

enum InvestmentHorizon: String, Codable {
    case short
    case medium
    case long
}

enum PurchaseFrequency: String, Codable {
    case daily
    case weekly
    case monthly
    case quarterly
    case rarely
}

// MARK: - Behavior Pattern

/// Tracked user behavior patterns
struct BehaviorPattern: Codable, Equatable {
    var queryFrequency: Double
    var preferredTopics: [ConversationTopic]
    var averageSessionLength: TimeInterval
    
    init(
        queryFrequency: Double = 0.0,
        preferredTopics: [ConversationTopic] = [],
        averageSessionLength: TimeInterval = 0.0
    ) {
        self.queryFrequency = queryFrequency
        self.preferredTopics = preferredTopics
        self.averageSessionLength = averageSessionLength
    }
}

// MARK: - Collection Goal

/// User-defined collection goals
struct CollectionGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var type: GoalType
    var target: String
    var progress: Double
    
    init(
        id: UUID = UUID(),
        type: GoalType,
        target: String,
        progress: Double = 0.0
    ) {
        self.id = id
        self.type = type
        self.target = target
        self.progress = progress
    }
}

enum GoalType: String, Codable {
    case cardCount
    case totalValue
    case specificCard
    case completeSet
    case gradeImprovement
}

// MARK: - Expertise Level

enum ExpertiseLevel: String, Codable {
    case beginner
    case intermediate
    case advanced
    case expert
}

// MARK: - Communication Style

enum CommunicationStyle: String, Codable {
    case formal
    case friendly
    case casual
    case technical
}

// MARK: - Personality Traits

/// Assistant personality configuration
struct PersonalityTraits: Codable, Equatable {
    var name: String
    var personality: String
    var expertise: [String]
    var communicationStyle: CommunicationStyle
    
    init(
        name: String = "Assistant",
        personality: String = "helpful and knowledgeable",
        expertise: [String] = [],
        communicationStyle: CommunicationStyle = .friendly
    ) {
        self.name = name
        self.personality = personality
        self.expertise = expertise
        self.communicationStyle = communicationStyle
    }
}
