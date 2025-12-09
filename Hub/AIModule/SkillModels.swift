import Foundation

public enum SkillType: String, Codable, CaseIterable, Sendable {
    case security
    case performance
    case uiDesign
    case uxResearch
    case networking
    case dataPersistence
    case testing
    case accessibility
    case productManagement
    case architecture
    case authentication
    case authorization
    case cryptography
    case other
}

public enum SkillStatus: String, Codable, CaseIterable, Sendable {
    case proposed
    case learning
    case practicing
    case proficient
    case expert
    case deprecated
}

public enum SkillPriority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    case critical
}

public struct SkillLevel: Codable, Hashable, Sendable {
    // 0.0 to 1.0 normalized level
    public var value: Double
    // Optional human-readable label (e.g., Beginner, Intermediate, Advanced)
    public var label: String?

    public init(value: Double, label: String? = nil) {
        self.value = min(max(value, 0.0), 1.0)
        self.label = label
    }
}

public struct SkillKnowledge: Codable, Hashable, Sendable {
    // Evidence supporting the skill knowledge (e.g., notes, links, sources)
    public var evidence: [String]
    // Topics/keywords associated with this knowledge
    public var topics: [String]
    // Last refreshed date for knowledge recency
    public var lastUpdated: Date

    public init(evidence: [String] = [], topics: [String] = [], lastUpdated: Date = Date()) {
        self.evidence = evidence
        self.topics = topics
        self.lastUpdated = lastUpdated
    }
}

public struct Skill: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var type: SkillType
    public var status: SkillStatus
    public var priority: SkillPriority
    public var level: SkillLevel
    public var knowledge: SkillKnowledge
    public var ownerAgentID: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        type: SkillType,
        status: SkillStatus = .learning,
        priority: SkillPriority = .medium,
        level: SkillLevel = SkillLevel(value: 0.0, label: "Beginner"),
        knowledge: SkillKnowledge = SkillKnowledge(),
        ownerAgentID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.priority = priority
        self.level = level
        self.knowledge = knowledge
        self.ownerAgentID = ownerAgentID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension SkillLevel {
    var normalized: Double { value }
    var percentageString: String { String(format: "%.1f%%", value * 100) }
}

public extension Skill {
    mutating func updateLevel(to newValue: Double, label: String? = nil) {
        level = SkillLevel(value: newValue, label: label ?? level.label)
        updatedAt = Date()
    }

    mutating func addKnowledgeEvidence(_ newEvidence: String) {
        var k = knowledge
        k.evidence.append(newEvidence)
        k.lastUpdated = Date()
        knowledge = k
        updatedAt = Date()
    }

    mutating func addKnowledgeTopic(_ topic: String) {
        var k = knowledge
        if !k.topics.contains(topic) {
            k.topics.append(topic)
        }
        k.lastUpdated = Date()
        knowledge = k
        updatedAt = Date()
    }
}
