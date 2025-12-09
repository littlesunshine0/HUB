//
//  AgentConsensusSystem.swift
//  Hub
//
//  Voting and consensus mechanisms for agent collaboration
//

import Foundation
import Combine

// MARK: - Consensus System

@MainActor
public class AgentConsensusSystem: ObservableObject {
    private let agentSystem = RoleBasedAgentSystem.shared
    
    @Published public var activeVotes: [VotingSession] = []
    @Published public var completedVotes: [VotingSession] = []
    
    // MARK: - Voting Sessions
    
    /// Start a voting session for a proposal
    public func startVoting(for proposal: AgentProposal, voters: [AIAgent]) async -> VotingSession {
        let session = VotingSession(
            id: UUID(),
            proposal: proposal,
            voters: voters,
            votes: [],
            startTime: Date(),
            status: .active
        )
        
        activeVotes.append(session)
        
        // Collect votes from agents
        await collectVotes(for: session)
        
        return session
    }
    
    /// Collect votes from all agents
    private func collectVotes(for session: VotingSession) async {
        guard let index = activeVotes.firstIndex(where: { $0.id == session.id }) else { return }
        
        for agent in session.voters {
            let vote = await agent.vote(on: session.proposal)
            activeVotes[index].votes.append(vote)
        }
        
        // Calculate result
        let result = calculateConsensus(for: activeVotes[index])
        activeVotes[index].result = result
        activeVotes[index].status = .completed
        activeVotes[index].endTime = Date()
        
        // Move to completed
        completedVotes.append(activeVotes[index])
        activeVotes.remove(at: index)
    }
    
    /// Calculate consensus from votes
    private func calculateConsensus(for session: VotingSession) -> ConsensusResult {
        let approvals = session.votes.filter { $0.vote == .approve }.count
        let rejections = session.votes.filter { $0.vote == .reject }.count
        let abstentions = session.votes.filter { $0.vote == .abstain }.count
        
        let totalVotes = session.votes.count
        let approvalRate = Double(approvals) / Double(totalVotes)
        
        let decision: ConsensusDecision
        if approvalRate >= 0.75 {
            decision = .strongConsensus
        } else if approvalRate >= 0.6 {
            decision = .consensus
        } else if approvalRate >= 0.5 {
            decision = .weakConsensus
        } else {
            decision = .noConsensus
        }
        
        return ConsensusResult(
            decision: decision,
            approvals: approvals,
            rejections: rejections,
            abstentions: abstentions,
            approvalRate: approvalRate,
            summary: generateConsensusSummary(decision: decision, approvalRate: approvalRate)
        )
    }
    
    private func generateConsensusSummary(decision: ConsensusDecision, approvalRate: Double) -> String {
        switch decision {
        case .strongConsensus:
            return "Strong consensus reached (\(Int(approvalRate * 100))% approval). Proceed with implementation."
        case .consensus:
            return "Consensus reached (\(Int(approvalRate * 100))% approval). Consider addressing concerns before proceeding."
        case .weakConsensus:
            return "Weak consensus (\(Int(approvalRate * 100))% approval). Significant concerns remain."
        case .noConsensus:
            return "No consensus (\(Int(approvalRate * 100))% approval). Proposal needs revision."
        }
    }
    
    // MARK: - Weighted Voting
    
    /// Start weighted voting where agent expertise affects vote weight
    public func startWeightedVoting(for proposal: AgentProposal, voters: [AIAgent]) async -> WeightedVotingSession {
        let session = WeightedVotingSession(
            id: UUID(),
            proposal: proposal,
            voters: voters,
            weightedVotes: [],
            startTime: Date(),
            status: .active
        )
        
        // Collect weighted votes
        var weightedVotes: [WeightedVote] = []
        
        for agent in voters {
            let vote = await agent.vote(on: proposal)
            let weight = calculateVoteWeight(agent: agent, proposal: proposal)
            
            weightedVotes.append(WeightedVote(
                agent: agent,
                vote: vote,
                weight: weight,
                rationale: vote.comment ?? ""
            ))
        }
        
        let result = calculateWeightedConsensus(votes: weightedVotes)
        
        return WeightedVotingSession(
            id: session.id,
            proposal: proposal,
            voters: voters,
            weightedVotes: weightedVotes,
            startTime: session.startTime,
            endTime: Date(),
            status: .completed,
            result: result
        )
    }
    
    /// Calculate vote weight based on agent expertise
    private func calculateVoteWeight(agent: AIAgent, proposal: AgentProposal) -> Double {
        var weight = 1.0
        
        // Increase weight if agent has relevant expertise
        let proposalKeywords = (proposal.title + " " + proposal.description).lowercased()
        let relevantExpertise = agent.expertise.filter { expertise in
            proposalKeywords.contains(expertise.lowercased())
        }
        
        weight += Double(relevantExpertise.count) * 0.2
        
        // Role-specific weights
        switch proposal.type {
        case .security:
            if agent.role == .securityEngineer {
                weight *= 1.5
            }
        case .design:
            if agent.role == .designer {
                weight *= 1.5
            }
        case .feature, .improvement:
            if agent.role == .productManager {
                weight *= 1.3
            }
        default:
            break
        }
        
        return min(weight, 2.0) // Cap at 2x weight
    }
    
    private func calculateWeightedConsensus(votes: [WeightedVote]) -> WeightedConsensusResult {
        let totalWeight = votes.reduce(0.0) { $0 + $1.weight }
        let approvalWeight = votes.filter { $0.vote.vote == .approve }.reduce(0.0) { $0 + $1.weight }
        let rejectionWeight = votes.filter { $0.vote.vote == .reject }.reduce(0.0) { $0 + $1.weight }
        
        let weightedApprovalRate = approvalWeight / totalWeight
        
        let decision: ConsensusDecision
        if weightedApprovalRate >= 0.75 {
            decision = .strongConsensus
        } else if weightedApprovalRate >= 0.6 {
            decision = .consensus
        } else if weightedApprovalRate >= 0.5 {
            decision = .weakConsensus
        } else {
            decision = .noConsensus
        }
        
        return WeightedConsensusResult(
            decision: decision,
            totalWeight: totalWeight,
            approvalWeight: approvalWeight,
            rejectionWeight: rejectionWeight,
            weightedApprovalRate: weightedApprovalRate,
            topConcerns: extractTopConcerns(from: votes)
        )
    }
    
    private func extractTopConcerns(from votes: [WeightedVote]) -> [String] {
        votes
            .filter { $0.vote.vote == .reject || $0.vote.vote == .abstain }
            .sorted { $0.weight > $1.weight }
            .prefix(3)
            .compactMap { $0.vote.comment }
    }
    
    // MARK: - Multi-Round Voting
    
    /// Conduct multi-round voting with discussion between rounds
    public func conductMultiRoundVoting(for proposal: AgentProposal, voters: [AIAgent], maxRounds: Int = 3) async -> MultiRoundVotingResult {
        var rounds: [VotingRound] = []
        var currentProposal = proposal
        
        for roundNumber in 1...maxRounds {
            // Voting round
            let session = await startVoting(for: currentProposal, voters: voters)
            
            guard let result = session.result else { continue }
            
            let round = VotingRound(
                number: roundNumber,
                proposal: currentProposal,
                result: result,
                discussions: []
            )
            
            rounds.append(round)
            
            // Check if consensus reached
            if result.decision == .strongConsensus || result.decision == .consensus {
                break
            }
            
            // If not final round, allow agents to discuss and revise
            if roundNumber < maxRounds {
                let discussions = await conductDiscussion(about: currentProposal, concerns: result, voters: voters)
                rounds[roundNumber - 1].discussions = discussions
                
                // Revise proposal based on feedback
                currentProposal = reviseProposal(currentProposal, based: discussions)
            }
        }
        
        return MultiRoundVotingResult(
            originalProposal: proposal,
            finalProposal: currentProposal,
            rounds: rounds,
            finalDecision: rounds.last?.result.decision ?? .noConsensus
        )
    }
    
    private func conductDiscussion(about proposal: AgentProposal, concerns: ConsensusResult, voters: [AIAgent]) async -> [AgentDiscussion] {
        var discussions: [AgentDiscussion] = []
        
        // Agents who rejected discuss their concerns
        for agent in voters.prefix(3) {
            discussions.append(AgentDiscussion(
                agent: agent,
                concern: "Consider addressing \(agent.role.rawValue) perspective",
                suggestion: "Improve \(agent.expertise.first ?? "implementation")"
            ))
        }
        
        return discussions
    }
    
    private func reviseProposal(_ proposal: AgentProposal, based discussions: [AgentDiscussion]) -> AgentProposal {
        var revised = proposal
        
        // Incorporate feedback
        let suggestions = discussions.map { $0.suggestion }.joined(separator: "; ")
        revised.details += "\n\nRevisions: \(suggestions)"
        
        return revised
    }
}

// MARK: - Agent Voting Extension

extension AIAgent {
    func vote(on proposal: AgentProposal) async -> AgentVote {
        // Simulate thinking time
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Determine vote based on role and expertise
        let isRelevant = expertise.contains { keyword in
            proposal.title.lowercased().contains(keyword) ||
            proposal.description.lowercased().contains(keyword)
        }
        
        var voteType: AgentVote.VoteType
        var comment: String?
        
        if isRelevant {
            // Role-specific voting logic
            switch role {
            case .securityEngineer:
                if proposal.type == .security || proposal.description.lowercased().contains("security") {
                    voteType = .approve
                    comment = "Security considerations are well addressed"
                } else {
                    voteType = .abstain
                    comment = "Need more security details"
                }
                
            case .designer:
                if proposal.type == .design || proposal.description.lowercased().contains("ui") {
                    voteType = .approve
                    comment = "Design approach looks solid"
                } else {
                    voteType = .abstain
                    comment = "Limited design input needed"
                }
                
            case .qaEngineer:
                voteType = .approve
                comment = "Testable and well-defined"
                
            default:
                voteType = .approve
                comment = "Looks good from \(role.rawValue) perspective"
            }
        } else {
            voteType = .abstain
            comment = "Outside my area of expertise"
        }
        
        return AgentVote(agent: self, vote: voteType, comment: comment)
    }
}

// MARK: - Voting Models

public struct VotingSession: Identifiable {
    public let id: UUID
    public let proposal: AgentProposal
    public let voters: [AIAgent]
    public var votes: [AgentVote]
    public let startTime: Date
    public var endTime: Date?
    public var status: VotingStatus
    public var result: ConsensusResult?
    
    public enum VotingStatus {
        case active, completed, cancelled
    }
}

public struct ConsensusResult {
    public let decision: ConsensusDecision
    public let approvals: Int
    public let rejections: Int
    public let abstentions: Int
    public let approvalRate: Double
    public let summary: String
}

public enum ConsensusDecision {
    case strongConsensus  // 75%+
    case consensus        // 60-74%
    case weakConsensus    // 50-59%
    case noConsensus      // <50%
}

public struct WeightedVote {
    public let agent: AIAgent
    public let vote: AgentVote
    public let weight: Double
    public let rationale: String
}

public struct WeightedVotingSession: Identifiable {
    public let id: UUID
    public let proposal: AgentProposal
    public let voters: [AIAgent]
    public var weightedVotes: [WeightedVote]
    public let startTime: Date
    public var endTime: Date?
    public var status: VotingSession.VotingStatus
    public var result: WeightedConsensusResult?
}

public struct WeightedConsensusResult {
    public let decision: ConsensusDecision
    public let totalWeight: Double
    public let approvalWeight: Double
    public let rejectionWeight: Double
    public let weightedApprovalRate: Double
    public let topConcerns: [String]
}

public struct VotingRound {
    public let number: Int
    public let proposal: AgentProposal
    public let result: ConsensusResult
    public var discussions: [AgentDiscussion]
}

public struct AgentDiscussion {
    public let agent: AIAgent
    public let concern: String
    public let suggestion: String
}

public struct MultiRoundVotingResult {
    public let originalProposal: AgentProposal
    public let finalProposal: AgentProposal
    public let rounds: [VotingRound]
    public let finalDecision: ConsensusDecision
    
    public var converged: Bool {
        finalDecision == .strongConsensus || finalDecision == .consensus
    }
    
    public var improvementSummary: String {
        let changes = rounds.count - 1
        return changes > 0 ? "Proposal improved through \(changes) revision(s)" : "Approved in first round"
    }
}
