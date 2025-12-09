//
//  RoleBasedAgentSystem.swift
//  Hub
//
//  Multi-agent collaboration system where AI agents with different roles
//  propose ideas, review work, and contribute based on their expertise
//

import Foundation
import Combine

// MARK: - AI Agent System

@MainActor
public class RoleBasedAgentSystem: ObservableObject {
    public static let shared = RoleBasedAgentSystem()
    
    @Published public var agents: [AIAgent] = []
    @Published public var activeConversations: [AgentConversation] = []
    @Published public var proposals: [AgentProposal] = []
    @Published public var reviews: [AgentReview] = []
    
    private init() {
        initializeAgents()
    }
    
    // MARK: - Agent Initialization
    
    private func initializeAgents() {
        agents = [
            // Design Team
            AIAgent(
                id: UUID(),
                name: "Luna",
                role: .designer,
                specialty: "UI/UX Design & Visual Systems",
                personality: .creative,
                expertise: ["color theory", "typography", "accessibility", "user flows"]
            ),
            
            AIAgent(
                id: UUID(),
                name: "Kai",
                role: .technicalArtist,
                specialty: "VFX, Shaders & Technical Art",
                personality: .analytical,
                expertise: ["particle systems", "shaders", "lighting", "optimization"]
            ),
            
            // Engineering Team
            AIAgent(
                id: UUID(),
                name: "Alex",
                role: .developer,
                specialty: "Swift & iOS Development",
                personality: .pragmatic,
                expertise: ["SwiftUI", "architecture", "performance", "testing"]
            ),
            
            AIAgent(
                id: UUID(),
                name: "Morgan",
                role: .backendEngineer,
                specialty: "Backend & API Development",
                personality: .systematic,
                expertise: ["APIs", "databases", "scalability", "security"]
            ),
            
            // Security & Quality
            AIAgent(
                id: UUID(),
                name: "Sage",
                role: .securityEngineer,
                specialty: "Security & Authentication",
                personality: .cautious,
                expertise: ["auth flows", "encryption", "vulnerabilities", "compliance"]
            ),
            
            AIAgent(
                id: UUID(),
                name: "Quinn",
                role: .qaEngineer,
                specialty: "Quality Assurance & Testing",
                personality: .meticulous,
                expertise: ["test automation", "edge cases", "regression", "accessibility"]
            ),
            
            // Product & Analysis
            AIAgent(
                id: UUID(),
                name: "River",
                role: .productManager,
                specialty: "Product Strategy & User Experience",
                personality: .visionary,
                expertise: ["user needs", "roadmaps", "metrics", "prioritization"]
            ),
            
            AIAgent(
                id: UUID(),
                name: "Data",
                role: .dataScientist,
                specialty: "Analytics & Machine Learning",
                personality: .curious,
                expertise: ["statistics", "ML", "forecasting", "experimentation"]
            ),
            
            // Game Design
            AIAgent(
                id: UUID(),
                name: "Phoenix",
                role: .gameDesigner,
                specialty: "Game Systems & Economy",
                personality: .creative,
                expertise: ["game loops", "progression", "balance", "monetization"]
            ),
            
            AIAgent(
                id: UUID(),
                name: "Echo",
                role: .economyDesigner,
                specialty: "Virtual Economy & Monetization",
                personality: .analytical,
                expertise: ["sinks/sources", "pricing", "LTV", "balance"]
            ),
            
            // Documentation & Community
            AIAgent(
                id: UUID(),
                name: "Scribe",
                role: .technicalWriter,
                specialty: "Documentation & Knowledge",
                personality: .clear,
                expertise: ["documentation", "tutorials", "API docs", "clarity"]
            ),
            
            AIAgent(
                id: UUID(),
                name: "Harmony",
                role: .communityManager,
                specialty: "Community & User Engagement",
                personality: .empathetic,
                expertise: ["community", "feedback", "engagement", "support"]
            )
        ]
    }
    
    // MARK: - Collaborative Workflows
    
    /// Request ideas from all relevant agents for a given task
    public func requestIdeas(for task: String, context: String) async -> [AgentProposal] {
        var proposals: [AgentProposal] = []
        
        // Determine which agents should contribute
        let relevantAgents = agents.filter { agent in
            agent.isRelevantFor(task: task, context: context)
        }
        
        // Each agent proposes their ideas
        for agent in relevantAgents {
            if let proposal = await agent.proposeIdea(for: task, context: context) {
                proposals.append(proposal)
            }
        }
        
        self.proposals.append(contentsOf: proposals)
        return proposals
    }
    
    /// Request code review from relevant agents
    public func requestReview(code: String, type: CodeType) async -> [AgentReview] {
        var reviews: [AgentReview] = []
        
        let reviewers = agents.filter { agent in
            agent.canReview(codeType: type)
        }
        
        for agent in reviewers {
            if let review = await agent.reviewCode(code, type: type) {
                reviews.append(review)
            }
        }
        
        self.reviews.append(contentsOf: reviews)
        return reviews
    }
    
    /// Start a multi-agent conversation about a topic
    public func startConversation(topic: String, participants: [AIAgent]) -> AgentConversation {
        let conversation = AgentConversation(
            id: UUID(),
            topic: topic,
            participants: participants,
            messages: [],
            startTime: Date()
        )
        
        activeConversations.append(conversation)
        return conversation
    }
    
    /// Agent proposes a task to be done
    public func proposeTask(from agent: AIAgent, task: AutomatedTask, rationale: String) {
        let proposal = AgentProposal(
            id: UUID(),
            agent: agent,
            type: .task,
            title: task.name,
            details: task.details,
            rationale: rationale,
            priority: task.priority,
            estimatedEffort: task.estimatedDuration,
            timestamp: Date()
        )
        
        proposals.append(proposal)
    }
}

// MARK: - AI Agent

public struct AIAgent: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let role: AgentRole
    public let specialty: String
    public let personality: AgentPersonality
    public let expertise: [String]
    
    // MARK: - Agent Capabilities
    
    public func isRelevantFor(task: String, context: String) -> Bool {
        let taskLower = task.lowercased()
        let contextLower = context.lowercased()
        
        // Check if any expertise keywords match
        return expertise.contains { keyword in
            taskLower.contains(keyword) || contextLower.contains(keyword)
        }
    }
    
    public func canReview(codeType: CodeType) -> Bool {
        switch role {
        case .developer:
            return [.swift, .architecture, .general].contains(codeType)
        case .designer:
            return [.ui, .designSystem].contains(codeType)
        case .securityEngineer:
            return [.authentication, .security, .encryption].contains(codeType)
        case .qaEngineer:
            return [.tests, .general].contains(codeType)
        case .backendEngineer:
            return [.api, .database, .backend].contains(codeType)
        default:
            return false
        }
    }
    
    public func proposeIdea(for task: String, context: String) async -> AgentProposal? {
        // Simulate agent thinking and proposing
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let idea = generateIdea(for: task, context: context)
        
        return AgentProposal(
            id: UUID(),
            agent: self,
            type: .idea,
            title: idea.title,
            details: idea.details,
            rationale: idea.rationale,
            priority: .medium,
            estimatedEffort: 300,
            timestamp: Date()
        )
    }
    
    public func reviewCode(_ code: String, type: CodeType) async -> AgentReview? {
        // Simulate code review
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let feedback = generateReview(code: code, type: type)
        
        return AgentReview(
            id: UUID(),
            agent: self,
            codeType: type,
            rating: feedback.rating,
            comments: feedback.comments,
            suggestions: feedback.suggestions,
            timestamp: Date()
        )
    }
    
    // MARK: - Idea Generation
    
    private func generateIdea(for task: String, context: String) -> (title: String, details: String, rationale: String) {
        switch role {
        case .designer:
            return (
                title: "Enhance Visual Hierarchy",
                details: "Add color gradients and elevation to improve depth perception",
                rationale: "Based on design system best practices, adding subtle gradients and shadows will improve visual hierarchy and user engagement"
            )
            
        case .technicalArtist:
            return (
                title: "Optimize VFX Performance",
                details: "Implement particle pooling and LOD system for effects",
                rationale: "Current particle systems could benefit from object pooling to reduce memory allocations and improve frame rate"
            )
            
        case .developer:
            return (
                title: "Refactor for Testability",
                details: "Extract business logic into testable view models",
                rationale: "Separating concerns will make the code more maintainable and easier to test"
            )
            
        case .securityEngineer:
            return (
                title: "Add Rate Limiting",
                details: "Implement rate limiting on authentication endpoints",
                rationale: "Prevent brute force attacks by limiting login attempts per IP/user"
            )
            
        case .qaEngineer:
            return (
                title: "Add Edge Case Tests",
                details: "Create tests for boundary conditions and error states",
                rationale: "Current test coverage is missing edge cases that could cause production issues"
            )
            
        case .productManager:
            return (
                title: "Add User Onboarding",
                details: "Create guided tour for first-time users",
                rationale: "Analytics show 40% drop-off in first session - onboarding could improve retention"
            )
            
        case .dataScientist:
            return (
                title: "Implement A/B Testing",
                details: "Add experimentation framework for feature testing",
                rationale: "Data-driven decisions require proper A/B testing infrastructure"
            )
            
        case .economyDesigner:
            return (
                title: "Balance Currency Sinks",
                details: "Add more meaningful ways to spend virtual currency",
                rationale: "Economy simulation shows currency accumulation without enough sinks"
            )
            
        default:
            return (
                title: "Improvement Suggestion",
                details: "Consider enhancements based on role expertise",
                rationale: "General improvement recommendation"
            )
        }
    }
    
    // MARK: - Code Review
    
    private func generateReview(code: String, type: CodeType) -> (rating: Double, comments: [String], suggestions: [String]) {
        var comments: [String] = []
        var suggestions: [String] = []
        var rating = 4.0
        
        switch role {
        case .designer:
            comments.append("✅ Color choices align with design system")
            comments.append("⚠️ Consider adding more spacing for better readability")
            suggestions.append("Use SpacingTokens.large instead of hardcoded 24")
            suggestions.append("Add elevation shadows for depth")
            rating = 3.5
            
        case .securityEngineer:
            comments.append("✅ Input validation looks good")
            comments.append("❌ Missing rate limiting on authentication")
            comments.append("⚠️ Consider adding encryption for sensitive data")
            suggestions.append("Add rate limiting: max 5 attempts per 15 minutes")
            suggestions.append("Encrypt tokens before storage")
            rating = 3.0
            
        case .qaEngineer:
            comments.append("✅ Happy path is well covered")
            comments.append("❌ Missing error handling for network failures")
            comments.append("⚠️ Edge cases not tested")
            suggestions.append("Add tests for empty inputs")
            suggestions.append("Test network timeout scenarios")
            rating = 3.5
            
        case .developer:
            comments.append("✅ Code structure is clean")
            comments.append("✅ Good use of async/await")
            comments.append("⚠️ Consider extracting magic numbers to constants")
            suggestions.append("Extract timeout values to configuration")
            suggestions.append("Add inline documentation for complex logic")
            rating = 4.0
            
        default:
            comments.append("✅ Looks good overall")
            rating = 4.0
        }
        
        return (rating, comments, suggestions)
    }
}

// MARK: - Agent Role

public enum AgentRole: String, Codable {
    case designer = "Designer"
    case technicalArtist = "Technical Artist"
    case developer = "Developer"
    case backendEngineer = "Backend Engineer"
    case securityEngineer = "Security Engineer"
    case qaEngineer = "QA Engineer"
    case productManager = "Product Manager"
    case dataScientist = "Data Scientist"
    case gameDesigner = "Game Designer"
    case economyDesigner = "Economy Designer"
    case technicalWriter = "Technical Writer"
    case communityManager = "Community Manager"
    case devOps = "DevOps"
    case architect = "Architect"
}

// MARK: - Agent Personality

public enum AgentPersonality: String, Codable {
    case creative = "Creative"
    case analytical = "Analytical"
    case pragmatic = "Pragmatic"
    case systematic = "Systematic"
    case cautious = "Cautious"
    case meticulous = "Meticulous"
    case visionary = "Visionary"
    case curious = "Curious"
    case empathetic = "Empathetic"
    case clear = "Clear"
    
    public var traits: [String] {
        switch self {
        case .creative:
            return ["innovative", "visual", "experimental", "artistic"]
        case .analytical:
            return ["data-driven", "logical", "precise", "methodical"]
        case .pragmatic:
            return ["practical", "efficient", "results-oriented", "realistic"]
        case .systematic:
            return ["organized", "structured", "thorough", "consistent"]
        case .cautious:
            return ["careful", "risk-aware", "thorough", "defensive"]
        case .meticulous:
            return ["detail-oriented", "thorough", "precise", "quality-focused"]
        case .visionary:
            return ["strategic", "forward-thinking", "innovative", "big-picture"]
        case .curious:
            return ["exploratory", "questioning", "learning", "experimental"]
        case .empathetic:
            return ["user-focused", "understanding", "supportive", "communicative"]
        case .clear:
            return ["concise", "organized", "educational", "accessible"]
        }
    }
}

// MARK: - Agent Proposal

public struct AgentProposal: Identifiable, Codable {
    public let id: UUID
    public let agent: AIAgent
    public let type: ProposalType
    public let title: String
    public var details: String
    public let rationale: String
    public let priority: TaskPriority
    public let estimatedEffort: TimeInterval
    public let timestamp: Date
    public var votes: [AgentVote] = []
    public var status: ProposalStatus = .pending
    
    public var description: String {
        return details
    }
    
    public enum ProposalType: String, Codable {
        case feature = "Feature"
        case improvement = "Improvement"
        case bugFix = "Bug Fix"
        case refactor = "Refactor"
        case task = "Task"
        case idea = "Idea"
        case design = "Design"
        case security = "Security"
    }
    
    public enum ProposalStatus: String, Codable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case implemented = "Implemented"
    }
}

// MARK: - Agent Review

public struct AgentReview: Identifiable, Codable {
    public let id: UUID
    public let agent: AIAgent
    public let codeType: CodeType
    public let rating: Double // 1.0 - 5.0
    public let comments: [String]
    public let suggestions: [String]
    public let timestamp: Date
    public var approved: Bool {
        rating >= 3.5
    }
}

// MARK: - Agent Conversation

public struct AgentConversation: Identifiable, Codable {
    public let id: UUID
    public let topic: String
    public let participants: [AIAgent]
    public var messages: [AgentMessage]
    public let startTime: Date
    public var endTime: Date?
    
    public mutating func addMessage(from agent: AIAgent, content: String) {
        let message = AgentMessage(
            id: UUID(),
            agent: agent,
            content: content,
            timestamp: Date()
        )
        messages.append(message)
    }
}

public struct AgentMessage: Identifiable, Codable {
    public let id: UUID
    public let agent: AIAgent
    public let content: String
    public let timestamp: Date
}

// MARK: - Agent Vote

public struct AgentVote: Codable {
    public let agent: AIAgent
    public let vote: VoteType
    public let comment: String?
    
    public enum VoteType: String, Codable {
        case approve = "Approve"
        case reject = "Reject"
        case abstain = "Abstain"
    }
}

// MARK: - Code Type

public enum CodeType: String, Codable {
    case swift = "Swift"
    case ui = "UI"
    case architecture = "Architecture"
    case authentication = "Authentication"
    case security = "Security"
    case encryption = "Encryption"
    case tests = "Tests"
    case api = "API"
    case database = "Database"
    case backend = "Backend"
    case designSystem = "Design System"
    case general = "General"
}

// MARK: - Agent Collaboration Examples

extension RoleBasedAgentSystem {
    
    /// Example: Design Review Session
    public func conductDesignReview(design: String) async -> DesignReviewResult {
        let designerAgent = agents.first { $0.role == .designer }!
        let qaAgent = agents.first { $0.role == .qaEngineer }!
        let pmAgent = agents.first { $0.role == .productManager }!
        
        var conversation = startConversation(
            topic: "Design Review: \(design)",
            participants: [designerAgent, qaAgent, pmAgent]
        )
        
        // Designer reviews visual aspects
        conversation.addMessage(
            from: designerAgent,
            content: "The color contrast meets WCAG AA standards. I suggest adding more spacing between elements for better readability."
        )
        
        // QA reviews accessibility
        conversation.addMessage(
            from: qaAgent,
            content: "Accessibility looks good, but we should add keyboard navigation support and screen reader labels."
        )
        
        // PM reviews user value
        conversation.addMessage(
            from: pmAgent,
            content: "This aligns with our user research. The simplified flow should improve conversion by 15-20%."
        )
        
        return DesignReviewResult(
            conversation: conversation,
            approved: true,
            actionItems: [
                "Add keyboard navigation",
                "Increase spacing between elements",
                "Add screen reader labels"
            ]
        )
    }
    
    /// Example: Feature Brainstorming
    public func brainstormFeature(feature: String) async -> [AgentProposal] {
        return await requestIdeas(for: feature, context: "New feature brainstorming")
    }
    
    /// Example: Security Audit
    public func conductSecurityAudit(code: String) async -> SecurityAuditResult {
        let securityAgent = agents.first { $0.role == .securityEngineer }!
        let backendAgent = agents.first { $0.role == .backendEngineer }!
        
        let securityReview = await securityAgent.reviewCode(code, type: .security)
        let backendReview = await backendAgent.reviewCode(code, type: .backend)
        
        let issues = (securityReview?.comments ?? []) + (backendReview?.comments ?? [])
        let recommendations = (securityReview?.suggestions ?? []) + (backendReview?.suggestions ?? [])
        
        return SecurityAuditResult(
            passed: securityReview?.approved ?? false,
            issues: issues.filter { $0.contains("❌") || $0.contains("⚠️") },
            recommendations: recommendations
        )
    }
}

// MARK: - Result Types

public struct DesignReviewResult {
    public let conversation: AgentConversation
    public let approved: Bool
    public let actionItems: [String]
}

public struct SecurityAuditResult {
    public let passed: Bool
    public let issues: [String]
    public let recommendations: [String]
}
