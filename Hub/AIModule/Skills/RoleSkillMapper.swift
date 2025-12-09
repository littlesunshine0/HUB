//
//  RoleSkillMapper.swift
//  Hub
//
//  Maps user roles to relevant skills and provides skill-based recommendations
//

import Foundation
import Combine

@MainActor
public class RoleSkillMapper: ObservableObject {
    public static let shared = RoleSkillMapper()
    
    private let learningSystem = AgentLearningSystem()
    private let agentSystem = RoleBasedAgentSystem.shared
    
    @Published public var roleSkillMap: [UserRole: [SkillType]] = [:]
    @Published public var skillSynergies: [SkillSynergy] = []
    
    private init() {
        buildRoleSkillMap()
    }
    
    // MARK: - Role-Skill Mapping
    
    private func buildRoleSkillMap() {
        roleSkillMap = [
            .developer: [
                .architecture, .performance, .testing,
                .networking, .dataPersistence
            ],
            .designer: [
                .uiDesign, .uxResearch, .accessibility
            ],
            .securityEngineer: [
                .security, .authentication, .authorization,
                .cryptography
            ],
            .productManager: [
                .productManagement, .uxResearch
            ],
            .qaEngineer: [
                .testing, .accessibility, .performance
            ],
            .devOps: [
                .networking, .performance, .security
            ],
            .architect: [
                .architecture, .performance, .security
            ],
            .contentCreator: [
                .uiDesign, .uxResearch
            ]
        ]
    }
    
    
    // MARK: - Public API
    
    /// Get skills relevant to a specific role
    public func getRelevantSkills(for role: UserRole) -> [SkillType] {
        return roleSkillMap[role] ?? []
    }
    
    /// Suggest AI agents that can help with role-specific tasks
    public func suggestAgents(for role: UserRole, task: String) -> [AIAgent] {
        let relevantSkills = getRelevantSkills(for: role)
        let skillKeywords = relevantSkills.map { $0.rawValue.lowercased() }
        
        return agentSystem.agents.filter { agent in
            agent.expertise.contains { expertise in
                skillKeywords.contains { $0.contains(expertise) } ||
                task.lowercased().contains(expertise)
            }
        }
    }
    
    /// Identify skills that user should develop for their role
    public func identifySkillGaps(
        role: UserRole,
        currentSkills: [Skill]
    ) -> [SkillType] {
        let requiredSkills = Set(getRelevantSkills(for: role))
        let currentSkillTypes = Set(currentSkills.map { $0.type })
        return Array(requiredSkills.subtracting(currentSkillTypes))
    }
    
    /// Get recommended skill level for role
    public func getRecommendedLevel(
        skill: SkillType,
        for role: UserRole
    ) -> Double {
        let roleSkills = getRelevantSkills(for: role)
        
        if roleSkills.contains(skill) {
            // Core skills should be at least intermediate
            return 0.6
        } else {
            // Related skills can be basic
            return 0.3
        }
    }
    
    /// Find roles that would benefit from a specific skill
    public func findRolesForSkill(_ skill: SkillType) -> [UserRole] {
        return roleSkillMap.filter { $0.value.contains(skill) }.map { $0.key }
    }
    
    /// Calculate role compatibility based on skills
    public func calculateRoleCompatibility(
        currentSkills: [Skill],
        targetRole: UserRole
    ) -> Double {
        let requiredSkills = getRelevantSkills(for: targetRole)
        let currentSkillTypes = currentSkills.map { $0.type }
        
        let matchingSkills = requiredSkills.filter { currentSkillTypes.contains($0) }
        let matchPercentage = Double(matchingSkills.count) / Double(requiredSkills.count)
        
        // Factor in skill levels
        let avgLevel = currentSkills
            .filter { requiredSkills.contains($0.type) }
            .map { $0.level.value }
            .reduce(0, +) / Double(max(matchingSkills.count, 1))
        
        return (matchPercentage * 0.6) + (avgLevel * 0.4)
    }
}

// MARK: - Skill Synergy

public struct SkillSynergy: Identifiable, Codable, Hashable {
    public let id: UUID
    public let skill1: SkillType
    public let skill2: SkillType
    public var synergyBonus: Double // 1.0 = no bonus, 2.0 = 2x effectiveness
    public let context: String
    public var evidenceCount: Int
    public var lastObserved: Date
    
    public init(
        id: UUID = UUID(),
        skill1: SkillType,
        skill2: SkillType,
        synergyBonus: Double,
        context: String,
        evidenceCount: Int = 1,
        lastObserved: Date = Date()
    ) {
        self.id = id
        self.skill1 = skill1
        self.skill2 = skill2
        self.synergyBonus = synergyBonus
        self.context = context
        self.evidenceCount = evidenceCount
        self.lastObserved = lastObserved
    }
}
