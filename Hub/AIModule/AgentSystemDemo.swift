//
//  AgentSystemDemo.swift
//  Hub
//
//  Comprehensive demo showcasing all agent system capabilities
//

import SwiftUI
import Combine

// MARK: - Demo Coordinator

@MainActor
public class AgentSystemDemo: ObservableObject {
    private let agentSystem = RoleBasedAgentSystem.shared
    private let consensus = AgentConsensusSystem()
    private let learning = AgentLearningSystem()
    private let integration = AgentIntegrationHub()
    
    @Published public var demoResults: [DemoResult] = []
    @Published public var isRunning = false
    @Published public var currentDemo: String = ""
    
    public init() {
        // Add specialized agents
        agentSystem.addSpecializedAgents()
    }
    
    // MARK: - Run All Demos
    
    public func runAllDemos() async {
        isRunning = true
        demoResults.removeAll()
        
        await demo1_IdeaGeneration()
        await demo2_CodeReview()
        await demo3_VotingConsensus()
        await demo4_MultiRoundVoting()
        await demo5_AgentLearning()
        await demo6_TeamComposition()
        await demo7_HubIntegration()
        await demo8_KnowledgeSharing()
        
        isRunning = false
        currentDemo = "Complete!"
    }
    
    // MARK: - Demo 1: Idea Generation
    
    private func demo1_IdeaGeneration() async {
        currentDemo = "Demo 1: Idea Generation"
        
        let proposals = await agentSystem.requestIdeas(
            for: "authentication system",
            context: "mobile app with biometric support"
        )
        
        let result = DemoResult(
            demoTitle: "💡 Idea Generation",
            description: "Multiple agents propose ideas from their expertise",
            details: [
                "Task: Design authentication system",
                "Agents participated: \(proposals.count)",
                "Proposals generated:",
                proposals.map { "  • \($0.agent.name) (\($0.agent.role.rawValue)): \($0.title)" }.joined(separator: "\n")
            ],
            demoStatus: true,
            demoInsight: "Each agent contributed unique perspective based on their role"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 2: Code Review
    
    private func demo2_CodeReview() async {
        currentDemo = "Demo 2: Multi-Agent Code Review"
        
        let sampleCode = """
        func authenticate(username: String, password: String) async throws {
            let hashedPassword = password.sha256()
            try await authService.login(username, hashedPassword)
        }
        """
        
        let reviews = await agentSystem.requestReview(code: sampleCode, type: .security)
        
        let avgRating = reviews.map(\.rating).reduce(0, +) / Double(reviews.count)
        
        let result = DemoResult(
            demoTitle: "🔍 Code Review",
            description: "Agents review code from different perspectives",
            details: [
                "Code reviewed: Authentication function",
                "Reviewers: \(reviews.count) agents",
                "Average rating: \(String(format: "%.1f", avgRating))/5.0",
                "Reviews:",
                reviews.map { review in
                    "  • \(review.agent.name): \(String(format: "%.1f", review.rating))⭐️ - \(review.comments.first ?? "")"
                }.joined(separator: "\n")
            ],
            demoStatus: true,
            demoInsight: "Multi-perspective review catches issues single reviewer might miss"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 3: Voting & Consensus
    
    private func demo3_VotingConsensus() async {
        currentDemo = "Demo 3: Weighted Voting"
        
        let proposal = AgentProposal(
            id: UUID(),
            agent: agentSystem.agents.first!,
            type: .security,
            title: "Implement 2FA",
            details: "Add two-factor authentication for enhanced security",
            rationale: "Reduces account compromise risk by 99%",
            priority: .high,
            estimatedEffort: 3600,
            timestamp: Date()
        )
        
        let session = await consensus.startWeightedVoting(
            for: proposal,
            voters: Array(agentSystem.agents.prefix(8))
        )
        
        let result = DemoResult(
            demoTitle: "🗳️ Weighted Voting",
            description: "Expert opinions carry more weight",
            details: [
                "Proposal: \(proposal.title)",
                "Voters: \(session.voters.count) agents",
                "Decision: \(session.result?.decision.description ?? "Pending")",
                "Weighted Approval: \(String(format: "%.1f%%", (session.result?.weightedApprovalRate ?? 0) * 100))",
                "Vote breakdown:",
                session.weightedVotes.map { vote in
                    "  • \(vote.agent.name) (\(vote.agent.role.rawValue)): \(vote.vote.vote.rawValue) [weight: \(String(format: "%.1f", vote.weight))]"
                }.joined(separator: "\n")
            ],
            demoStatus: session.result?.decision == .strongConsensus || session.result?.decision == .consensus,
            demoInsight: "Security engineer's vote weighted 1.5x on security proposals"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 4: Multi-Round Voting
    
    private func demo4_MultiRoundVoting() async {
        currentDemo = "Demo 4: Multi-Round Voting"
        
        let proposal = AgentProposal(
            id: UUID(),
            agent: agentSystem.agents.first!,
            type: .feature,
            title: "Add Social Sharing",
            details: "Allow users to share achievements on social media",
            rationale: "Increase user engagement and viral growth",
            priority: .medium,
            estimatedEffort: 7200,
            timestamp: Date()
        )
        
        let multiRoundResult = await consensus.conductMultiRoundVoting(
            for: proposal,
            voters: Array(agentSystem.agents.prefix(6)),
            maxRounds: 3
        )
        
        let result = DemoResult(
            demoTitle: "🔄 Multi-Round Voting",
            description: "Iterative improvement through discussion",
            details: [
                "Original Proposal: \(proposal.title)",
                "Rounds conducted: \(multiRoundResult.rounds.count)",
                "Final decision: \(multiRoundResult.finalDecision.description)",
                "Converged: \(multiRoundResult.converged ? "Yes" : "No")",
                "Improvement: \(multiRoundResult.improvementSummary)",
                "Round details:",
                multiRoundResult.rounds.map { round in
                    "  Round \(round.number): \(round.result.decision.description) (\(String(format: "%.0f%%", round.result.approvalRate * 100)) approval)"
                }.joined(separator: "\n")
            ],
            demoStatus: multiRoundResult.converged,
            demoInsight: "Proposal improved through agent discussions between rounds"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 5: Agent Learning
    
    private func demo5_AgentLearning() async {
        currentDemo = "Demo 5: Agent Learning"
        
        guard let securityAgent = agentSystem.agents.first(where: { $0.role == .securityEngineer }) else { return }
        
        // Simulate learning
        learning.updateAgentSkills(agent: securityAgent, task: "security audit", performance: 0.9)
        learning.updateAgentSkills(agent: securityAgent, task: "encryption", performance: 0.85)
        learning.updateAgentSkills(agent: securityAgent, task: "authentication", performance: 0.95)
        
        let analytics = learning.getAgentAnalytics(for: securityAgent)
        
        let result = DemoResult(
            demoTitle: "🧠 Agent Learning",
            description: "Agents improve skills through experience",
            details: [
                "Agent: \(securityAgent.name) (\(securityAgent.role.rawValue))",
                "Total interactions: \(analytics.totalInteractions)",
                "Average performance: \(String(format: "%.1f%%", analytics.averagePerformance * 100))",
                "Top skills:",
                analytics.topSkills.map { "  • \($0.skill): \(String(format: "%.1f%%", $0.level * 100))" }.joined(separator: "\n"),
                "Collaboration score: \(String(format: "%.1f%%", analytics.collaborationScore * 100))"
            ],
            demoStatus: true,
            demoInsight: "Skills improve with weighted average: (current × 0.8) + (performance × 0.2)"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 6: Team Composition
    
    private func demo6_TeamComposition() async {
        currentDemo = "Demo 6: Team Composition"
        
        let team = learning.suggestTeamComposition(for: "AR feature development")
        
        let result = DemoResult(
            demoTitle: "👥 Team Composition",
            description: "AI suggests optimal team based on learned patterns",
            details: [
                "Task: AR feature development",
                "Recommended team size: \(team.recommendedAgents.count)",
                "Expected success rate: \(String(format: "%.1f%%", team.expectedSuccessRate * 100))",
                "Based on: \(team.basedOnPatterns) similar patterns",
                "Team members:",
                team.recommendedAgents.map { "  • \($0.name) (\($0.role.rawValue)) - \($0.specialty)" }.joined(separator: "\n"),
                "Rationale: \(team.rationale)"
            ],
            demoStatus: true,
            demoInsight: "Team composition optimized based on historical success patterns"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 7: Hub Integration
    
    private func demo7_HubIntegration() async {
        currentDemo = "Demo 7: Hub Integration"
        
        let sampleCode = """
        VStack {
            Text("Hello").foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            Button("Action") { }.padding(24)
        }
        """
        
        let validation = await integration.validateDesignSystemUsage(in: sampleCode)
        
        let result = DemoResult(
            demoTitle: "🔗 Hub Integration",
            description: "Agents validate design system compliance",
            details: [
                "Validation by: \(validation.agent.name)",
                "Compliance score: \(String(format: "%.1f%%", validation.complianceScore * 100))",
                "Issues found: \(validation.issues.count)",
                validation.issues.map { "  • [\($0.severity)] \($0.description)" }.joined(separator: "\n"),
                "Suggestions:",
                validation.suggestions.map { "  • \($0)" }.joined(separator: "\n")
            ],
            demoStatus: validation.complianceScore > 0.7,
            demoInsight: "Agents help maintain design system consistency"
        )
        
        demoResults.append(result)
    }
    
    // MARK: - Demo 8: Knowledge Sharing
    
    private func demo8_KnowledgeSharing() async {
        currentDemo = "Demo 8: Knowledge Sharing"
        
        guard let expertAgent = agentSystem.agent(named: "Bolt"),
              let learnerAgent = agentSystem.agent(named: "Alex") else { return }
        
        // Set up expert skills
        learning.updateAgentSkills(agent: expertAgent, task: "performance optimization", performance: 0.95)
        
        // Before knowledge transfer
        let beforeAnalytics = learning.getAgentAnalytics(for: learnerAgent)
        let beforeSkill = beforeAnalytics.topSkills.first(where: { $0.skill == "performance optimization" })?.level ?? 0.0
        
        // Transfer knowledge
        learning.shareKnowledge(from: expertAgent, to: learnerAgent, topic: "performance optimization")
        
        // After knowledge transfer
        let afterAnalytics = learning.getAgentAnalytics(for: learnerAgent)
        let afterSkill = afterAnalytics.topSkills.first(where: { $0.skill == "performance optimization" })?.level ?? 0.0
        
        let result = DemoResult(
            demoTitle: "🤝 Knowledge Sharing",
            description: "Agents learn from each other",
            details: [
                "Expert: \(expertAgent.name) (\(expertAgent.specialty))",
                "Learner: \(learnerAgent.name) (\(learnerAgent.specialty))",
                "Topic: Performance Optimization",
                "Before transfer: \(String(format: "%.1f%%", beforeSkill * 100))",
                "After transfer: \(String(format: "%.1f%%", afterSkill * 100))",
                "Improvement: +\(String(format: "%.1f%%", (afterSkill - beforeSkill) * 100))",
                "Transfer rate: 30% of expert's skill level"
            ],
            demoStatus: afterSkill > beforeSkill,
            demoInsight: "Knowledge transfer enables rapid skill development across team"
        )
        
        demoResults.append(result)
    }
}

// MARK: - Demo Result

public struct DemoResult: Identifiable, Hashable {
    public let id: UUID
    public let demoTitle: String
    public let description: String
    public let details: [String]
    public let demoStatus: Bool
    public let demoInsight: String

    public init(
        id: UUID = UUID(),
        demoTitle: String,
        description: String,
        details: [String],
        demoStatus: Bool,
        demoInsight: String
    ) {
        self.id = id
        self.demoTitle = demoTitle
        self.description = description
        self.details = details
        self.demoStatus = demoStatus
        self.demoInsight = demoInsight
    }
}

// MARK: - Demo UI

public struct AgentSystemDemoView: View {
    @StateObject private var demo = AgentSystemDemo()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Run Demo Button
                    runDemoButton
                    
                    // Current Demo
                    if demo.isRunning {
                        currentDemoSection
                    }
                    
                    // Results
                    if !demo.demoResults.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Agent System Demo")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Multi-Agent System Demo")
                .font(.title)
                .bold()
            
            Text("See all capabilities in action")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var runDemoButton: some View {
        Button(action: {
            Task {
                await demo.runAllDemos()
            }
        }) {
            HStack {
                if demo.isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "play.circle.fill")
                }
                Text(demo.isRunning ? "Running Demos..." : "Run All Demos")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(demo.isRunning ? Color.gray : Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(demo.isRunning)
    }
    
    private var currentDemoSection: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(demo.currentDemo)
                .font(.headline)
                .foregroundColor(.secondary)
        }
#if os(iOS) || os(tvOS)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
#else
        .padding()
        .background(Color.secondary)
#endif
        .cornerRadius(12)
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Demo Results")
                .font(.headline)
            
            ForEach(demo.demoResults) { result in
                DemoResultCard(result: result)
            }
        }
    }
}

struct DemoResultCard: View {
    let result: DemoResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: result.demoStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.demoStatus ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.demoTitle)
                        .font(.headline)
                    Text(result.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            // Expanded Details
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(result.details, id: \.self) { detail in
                        Text(detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(result.demoInsight)
                        .font(.caption)
                        .italic()
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Consensus Decision Extension

extension ConsensusDecision {
    var description: String {
        switch self {
        case .strongConsensus: return "Strong Consensus"
        case .consensus: return "Consensus"
        case .weakConsensus: return "Weak Consensus"
        case .noConsensus: return "No Consensus"
        }
    }
}

