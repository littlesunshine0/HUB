//
//  AgentLearningSystem.swift
//  Hub
//
//  Agent learning and memory capabilities
//

import Foundation
import Combine

// MARK: - Learning System

@MainActor
public class AgentLearningSystem: ObservableObject {
    private let agentSystem = RoleBasedAgentSystem.shared
    
    @Published public var agentMemories: [UUID: AgentMemory] = [:]
    @Published public var learningEvents: [LearningEvent] = []
    @Published public var knowledgeBase: AgentKnowledgeBase = AgentKnowledgeBase()
    
    // MARK: - Memory Management
    
    /// Record an interaction for agent learning
    public func recordInteraction(_ interaction: AgentInteraction) {
        // Update agent memory
        for agent in interaction.participants {
            var memory = agentMemories[agent.id] ?? AgentMemory(agentId: agent.id)
            memory.interactions.append(interaction)
            memory.lastUpdated = Date()
            agentMemories[agent.id] = memory
        }
        
        // Extract learning from interaction
        extractLearning(from: interaction)
    }
    
    /// Extract learning insights from interaction
    private func extractLearning(from interaction: AgentInteraction) {
        let learningEvent = LearningEvent(
            id: UUID(),
            timestamp: Date(),
            type: determineLearningType(interaction),
            agents: interaction.participants,
            insight: extractInsight(from: interaction),
            confidence: 0.8
        )
        
        learningEvents.append(learningEvent)
        
        // Update knowledge base
        updateKnowledgeBase(with: learningEvent)
    }
    
    private func determineLearningType(_ interaction: AgentInteraction) -> LearningType {
        switch interaction.type {
        case .codeReview:
            return .patternRecognition
        case .brainstorming:
            return .ideaGeneration
        case .problemSolving:
            return .problemSolving
        case .collaboration:
            return .collaboration
        }
    }
    
    private func extractInsight(from interaction: AgentInteraction) -> String {
        switch interaction.outcome {
        case .success:
            return "Successful collaboration pattern: \(interaction.participants.map { $0.role.rawValue }.joined(separator: " + "))"
        case .needsImprovement:
            return "Identified area for improvement in \(interaction.type.rawValue)"
        case .failed:
            return "Learning opportunity: avoid \(interaction.type.rawValue) approach"
        }
    }
    
    private func updateKnowledgeBase(with event: LearningEvent) {
        knowledgeBase.totalLearningEvents += 1
        
        // Update patterns
        let pattern = CollaborationPattern(
            agents: event.agents.map { $0.role },
            context: event.type.rawValue,
            successRate: event.confidence,
            usageCount: 1
        )
        
        if let existingIndex = knowledgeBase.patterns.firstIndex(where: {
            $0.agents == pattern.agents && $0.context == pattern.context
        }) {
            knowledgeBase.patterns[existingIndex].usageCount += 1
            knowledgeBase.patterns[existingIndex].successRate =
                (knowledgeBase.patterns[existingIndex].successRate + pattern.successRate) / 2
        } else {
            knowledgeBase.patterns.append(pattern)
        }
        
        // Update best practices
        if event.confidence > 0.7 {
            let bestPractice = BestPractice(
                title: event.insight,
                description: "Learned from \(event.agents.count) agent collaboration",
                category: event.type.rawValue,
                effectiveness: event.confidence,
                learnedFrom: event.agents
            )
            knowledgeBase.bestPractices.append(bestPractice)
        }
    }
    
    // MARK: - Agent Skill Development
    
    /// Track agent skill improvement over time
    public func updateAgentSkills(agent: AIAgent, task: String, performance: Double) {
        var memory = agentMemories[agent.id] ?? AgentMemory(agentId: agent.id)
        
        // Update skill level
        let skill = task.lowercased()
        let currentLevel = memory.skillLevels[skill] ?? 0.5
        let newLevel = (currentLevel * 0.8) + (performance * 0.2) // Weighted average
        
        memory.skillLevels[skill] = min(newLevel, 1.0)
        memory.totalTasksCompleted += 1
        memory.lastUpdated = Date()
        
        agentMemories[agent.id] = memory
        
        // Record learning event
        let event = LearningEvent(
            id: UUID(),
            timestamp: Date(),
            type: .skillDevelopment,
            agents: [agent],
            insight: "\(agent.name) improved \(skill) skill to \(String(format: "%.1f%%", newLevel * 100))",
            confidence: newLevel
        )
        
        learningEvents.append(event)
    }
    
    // MARK: - Recommendation Engine
    
    /// Recommend best agents for a task based on learning
    public func recommendAgents(for task: String, context: String) -> [AgentRecommendation] {
        var recommendations: [AgentRecommendation] = []
        
        for agent in agentSystem.agents {
            let score = calculateAgentScore(agent: agent, task: task, context: context)
            
            if score > 0.3 {
                recommendations.append(AgentRecommendation(
                    agent: agent,
                    score: score,
                    rationale: generateRationale(agent: agent, score: score)
                ))
            }
        }
        
        return recommendations.sorted { $0.score > $1.score }
    }
    
    private func calculateAgentScore(agent: AIAgent, task: String, context: String) -> Double {
        var score = 0.0
        
        // Base score from expertise match
        let taskLower = task.lowercased()
        let contextLower = context.lowercased()
        
        for expertise in agent.expertise {
            if taskLower.contains(expertise) || contextLower.contains(expertise) {
                score += 0.2
            }
        }
        
        // Bonus from learned skills
        if let memory = agentMemories[agent.id] {
            for (skill, level) in memory.skillLevels {
                if taskLower.contains(skill) || contextLower.contains(skill) {
                    score += level * 0.3
                }
            }
            
            // Experience bonus
            let experienceBonus = min(Double(memory.totalTasksCompleted) / 100.0, 0.2)
            score += experienceBonus
        }
        
        return min(score, 1.0)
    }
    
    private func generateRationale(agent: AIAgent, score: Double) -> String {
        if score > 0.8 {
            return "Highly recommended - Expert in this area with proven track record"
        } else if score > 0.6 {
            return "Recommended - Strong relevant experience"
        } else if score > 0.4 {
            return "Suitable - Has relevant skills"
        } else {
            return "Can contribute - Some relevant expertise"
        }
    }
    
    // MARK: - Pattern Recognition
    
    /// Identify successful collaboration patterns
    public func identifySuccessfulPatterns() -> [CollaborationPattern] {
        knowledgeBase.patterns
            .filter { $0.successRate > 0.7 && $0.usageCount > 2 }
            .sorted { $0.successRate > $1.successRate }
    }
    
    /// Suggest optimal team composition for a task
    public func suggestTeamComposition(for task: String) -> TeamComposition {
        let recommendations = recommendAgents(for: task, context: "")
        let topAgents = Array(recommendations.prefix(5).map { $0.agent })
        
        // Find successful patterns with similar roles
        let roleSet = Set(topAgents.map { $0.role })
        let matchingPatterns = knowledgeBase.patterns.filter { pattern in
            let patternRoles = Set(pattern.agents)
            return !patternRoles.isDisjoint(with: roleSet)
        }
        
        let avgSuccessRate = matchingPatterns.isEmpty ? 0.5 :
            matchingPatterns.map { $0.successRate }.reduce(0, +) / Double(matchingPatterns.count)
        
        return TeamComposition(
            task: task,
            recommendedAgents: topAgents,
            expectedSuccessRate: avgSuccessRate,
            basedOnPatterns: matchingPatterns.count,
            rationale: "Team composition based on \(matchingPatterns.count) similar successful collaborations"
        )
    }
    
    // MARK: - Knowledge Sharing
    
    /// Share knowledge between agents
    public func shareKnowledge(from source: AIAgent, to target: AIAgent, topic: String) {
        guard let sourceMemory = agentMemories[source.id] else { return }
        
        var targetMemory = agentMemories[target.id] ?? AgentMemory(agentId: target.id)
        
        // Transfer relevant skills
        if let skillLevel = sourceMemory.skillLevels[topic.lowercased()] {
            let currentLevel = targetMemory.skillLevels[topic.lowercased()] ?? 0.0
            let transferredLevel = (currentLevel + skillLevel * 0.3) / 1.3 // Partial transfer
            targetMemory.skillLevels[topic.lowercased()] = min(transferredLevel, 1.0)
        }
        
        targetMemory.lastUpdated = Date()
        agentMemories[target.id] = targetMemory
        
        // Record knowledge transfer
        let event = LearningEvent(
            id: UUID(),
            timestamp: Date(),
            type: .knowledgeTransfer,
            agents: [source, target],
            insight: "\(source.name) shared \(topic) knowledge with \(target.name)",
            confidence: 0.7
        )
        
        learningEvents.append(event)
    }
    
    // MARK: - Performance Analytics
    
    /// Get agent performance analytics
    public func getAgentAnalytics(for agent: AIAgent) -> AgentAnalytics {
        guard let memory = agentMemories[agent.id] else {
            return AgentAnalytics(
                agent: agent,
                totalInteractions: 0,
                averagePerformance: 0.5,
                topSkills: [],
                improvementAreas: [],
                collaborationScore: 0.5
            )
        }
        
        let topSkills = memory.skillLevels
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { SkillRating(skill: $0.key, level: $0.value) }
        
        let improvementAreas = memory.skillLevels
            .filter { $0.value < 0.6 }
            .sorted { $0.value < $1.value }
            .prefix(3)
            .map { SkillRating(skill: $0.key, level: $0.value) }
        
        let avgPerformance = memory.skillLevels.values.reduce(0, +) / Double(max(memory.skillLevels.count, 1))
        
        return AgentAnalytics(
            agent: agent,
            totalInteractions: memory.interactions.count,
            averagePerformance: avgPerformance,
            topSkills: topSkills,
            improvementAreas: improvementAreas,
            collaborationScore: calculateCollaborationScore(memory: memory)
        )
    }
    
    private func calculateCollaborationScore(memory: AgentMemory) -> Double {
        let collaborationCount = memory.interactions.filter {
            $0.type == .collaboration
        }.count
        
        return min(Double(collaborationCount) / 20.0, 1.0)
    }
}

// MARK: - Learning Models

public struct AgentMemory {
    public let agentId: UUID
    public var interactions: [AgentInteraction] = []
    public var skillLevels: [String: Double] = [:] // skill -> proficiency (0-1)
    public var totalTasksCompleted: Int = 0
    public var lastUpdated: Date = Date()
}

public struct AgentInteraction {
    public let id: UUID
    public let type: InteractionType
    public let participants: [AIAgent]
    public let timestamp: Date
    public let outcome: InteractionOutcome
    
    public enum InteractionType: String, Codable {
        case codeReview = "Code Review"
        case brainstorming = "Brainstorming"
        case problemSolving = "Problem Solving"
        case collaboration = "Collaboration"
    }
    
    public enum InteractionOutcome {
        case success
        case needsImprovement
        case failed
    }
}

public struct LearningEvent: Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let type: LearningType
    public let agents: [AIAgent]
    public let insight: String
    public let confidence: Double
}

public enum LearningType: String {
    case patternRecognition = "Pattern Recognition"
    case ideaGeneration = "Idea Generation"
    case problemSolving = "Problem Solving"
    case collaboration = "Collaboration"
    case skillDevelopment = "Skill Development"
    case knowledgeTransfer = "Knowledge Transfer"
}

public struct AgentKnowledgeBase {
    public var patterns: [CollaborationPattern] = []
    public var bestPractices: [BestPractice] = []
    public var totalLearningEvents: Int = 0
}

public struct CollaborationPattern {
    public let agents: [AgentRole]
    public let context: String
    public var successRate: Double
    public var usageCount: Int
}

public struct BestPractice {
    public let title: String
    public let description: String
    public let category: String
    public let effectiveness: Double
    public let learnedFrom: [AIAgent]
}

public struct AgentRecommendation {
    public let agent: AIAgent
    public let score: Double
    public let rationale: String
}

public struct TeamComposition {
    public let task: String
    public let recommendedAgents: [AIAgent]
    public let expectedSuccessRate: Double
    public let basedOnPatterns: Int
    public let rationale: String
}

public struct AgentAnalytics {
    public let agent: AIAgent
    public let totalInteractions: Int
    public let averagePerformance: Double
    public let topSkills: [SkillRating]
    public let improvementAreas: [SkillRating]
    public let collaborationScore: Double
}

public struct SkillRating {
    public let skill: String
    public let level: Double
}
