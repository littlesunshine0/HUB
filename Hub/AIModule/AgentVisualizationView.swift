//
//  AgentVisualizationView.swift
//  Hub
//
//  UI to visualize agent interactions and collaboration
//

import SwiftUI

// MARK: - Agent Collaboration Dashboard

public struct AgentCollaborationDashboard: View {
    @StateObject private var agentSystem = RoleBasedAgentSystem.shared
    @State private var selectedAgent: AIAgent?
    @State private var selectedConversation: AgentConversation?
    @State private var showingScenarioTester = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Agent Grid
                    agentGridSection
                    
                    // Active Conversations
                    if !agentSystem.activeConversations.isEmpty {
                        conversationsSection
                    }
                    
                    // Recent Proposals
                    if !agentSystem.proposals.isEmpty {
                        proposalsSection
                    }
                    
                    // Recent Reviews
                    if !agentSystem.reviews.isEmpty {
                        reviewsSection
                    }
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("AI Agent System")
            .sheet(item: $selectedAgent) { agent in
                AgentDetailView(agent: agent)
            }
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
            .sheet(isPresented: $showingScenarioTester) {
                AgentScenarioTestView()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Multi-Agent Collaboration")
                .font(.title)
                .bold()
            
            Text("\(agentSystem.agents.count) specialized AI agents working together")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                AgentStatBadge(
                    icon: "lightbulb.fill",
                    value: "\(agentSystem.proposals.count)",
                    label: "Proposals"
                )
                AgentStatBadge(
                    icon: "doc.text.magnifyingglass",
                    value: "\(agentSystem.reviews.count)",
                    label: "Reviews"
                )
                AgentStatBadge(
                    icon: "bubble.left.and.bubble.right.fill",
                    value: "\(agentSystem.activeConversations.count)",
                    label: "Conversations"
                )
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // MARK: - Agent Grid
    
    private var agentGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Agents")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(agentSystem.agents) { agent in
                    AgentCard(agent: agent)
                        .onTapGesture {
                            selectedAgent = agent
                        }
                }
            }
        }
    }
    
    // MARK: - Conversations Section
    
    private var conversationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Conversations")
                .font(.headline)
            
            ForEach(agentSystem.activeConversations) { conversation in
                ConversationCard(conversation: conversation)
                    .onTapGesture {
                        selectedConversation = conversation
                    }
            }
        }
    }
    
    // MARK: - Proposals Section
    
    private var proposalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Proposals")
                .font(.headline)
            
            ForEach(agentSystem.proposals.prefix(5)) { proposal in
                ProposalCard(proposal: proposal)
            }
        }
    }
    
    // MARK: - Reviews Section
    
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Reviews")
                .font(.headline)
            
            ForEach(agentSystem.reviews.prefix(5)) { review in
                ReviewCard(review: review)
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showingScenarioTester = true
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Run Scenario Tests")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    _ = await agentSystem.brainstormFeature(feature: "New Feature")
                }
            }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Brainstorm Ideas")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Agent Card

struct AgentCard: View {
    let agent: AIAgent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(roleColor(agent.role))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(agent.name.prefix(1))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.headline)
                    Text(agent.role.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(agent.specialty)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Expertise tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(agent.expertise.prefix(3), id: \.self) { skill in
                        Text(skill)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func roleColor(_ role: AgentRole) -> Color {
        switch role {
        case .designer, .technicalArtist:
            return .purple
        case .developer, .backendEngineer:
            return .blue
        case .securityEngineer:
            return .red
        case .qaEngineer:
            return .green
        case .productManager, .dataScientist:
            return .orange
        case .gameDesigner, .economyDesigner:
            return .pink
        case .technicalWriter, .communityManager:
            return .teal
        case .devOps, .architect:
            return .indigo
        }
    }
}

// MARK: - Conversation Card

struct ConversationCard: View {
    let conversation: AgentConversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
                Text(conversation.topic)
                    .font(.headline)
            }
            
            Text("\(conversation.participants.count) participants • \(conversation.messages.count) messages")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Participant avatars
            HStack(spacing: -8) {
                ForEach(conversation.participants.prefix(5)) { participant in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(participant.name.prefix(1))
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Proposal Card

struct ProposalCard: View {
    let proposal: AgentProposal
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: proposalIcon)
                .font(.title2)
                .foregroundColor(proposalColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(proposal.title)
                    .font(.headline)
                
                Text(proposal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("by \(proposal.agent.name)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(proposal.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(proposalColor.opacity(0.1))
                        .foregroundColor(proposalColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var proposalIcon: String {
        switch proposal.type {
        case .feature: return "star.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .bugFix: return "ant.fill"
        case .refactor: return "arrow.triangle.2.circlepath"
        case .task: return "checkmark.circle.fill"
        case .idea: return "lightbulb.fill"
        case .design: return "paintbrush.fill"
        case .security: return "shield.fill"
        }
    }
    
    private var proposalColor: Color {
        switch proposal.type {
        case .feature: return .blue
        case .improvement: return .green
        case .bugFix: return .red
        case .refactor: return .orange
        case .task: return .purple
        case .idea: return .yellow
        case .design: return .pink
        case .security: return .red
        }
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let review: AgentReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.blue)
                
                Text("\(review.agent.name)'s Review")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(review.codeType.rawValue)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
            
            if !review.comments.isEmpty {
                Text(review.comments.first ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Stat Badge

public struct AgentStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    public var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(PlatformColorPalette.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Agent Detail View

struct AgentDetailView: View {
    let agent: AIAgent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Agent Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(agent.name.prefix(1))
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                        
                        Text(agent.name)
                            .font(.title)
                            .bold()
                        
                        Text(agent.role.rawValue)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(agent.specialty)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // Personality
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Personality")
                            .font(.headline)
                        
                        Text(agent.personality.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                        
                        Text("Traits: \(agent.personality.traits.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Expertise
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expertise")
                            .font(.headline)
                        
                        AgentFlowLayout(spacing: 8) {
                            ForEach(agent.expertise, id: \.self) { skill in
                                Text(skill)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Agent Profile")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - Conversation Detail View

struct ConversationDetailView: View {
    let conversation: AgentConversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            .navigationTitle(conversation.topic)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

struct MessageBubble: View {
    let message: AgentMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(message.agent.name.prefix(1))
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.agent.name)
                    .font(.caption)
                    .bold()
                
                Text(message.content)
                    .font(.body)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(PlatformColorPalette.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout

public struct AgentFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
