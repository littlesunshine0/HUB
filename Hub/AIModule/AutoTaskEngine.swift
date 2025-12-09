//
//  AutoTaskEngine.swift
//  Hub
//
//  Auto-task creation and assignment engine with SLA rules and telemetry
//

import Foundation
import Combine

// MARK: - Auto Task Engine

@MainActor
public class AutoTaskEngine: ObservableObject {
    private let agentSystem = RoleBasedAgentSystem.shared
    private let learning = AgentLearningSystem()
    
    @Published public var tasks: [AutoTask] = []
    @Published public var assignments: [TaskAssignment] = []
    @Published public var telemetry: TaskTelemetry = TaskTelemetry()
    
    // MARK: - Task Creation
    
    /// Automatically create task from context
    public func createTask(
        title: String,
        description: String,
        type: TaskType,
        priority: TaskPriority,
        context: TaskContext
    ) -> AutoTask {
        let task = AutoTask(
            id: UUID(),
            title: title,
            description: description,
            type: type,
            priority: priority,
            context: context,
            createdAt: Date(),
            sla: calculateSLA(priority: priority, type: type),
            status: .pending
        )
        
        tasks.append(task)
        telemetry.tasksCreated += 1
        
        return task
    }
    
    /// Auto-assign task to best agent
    public func autoAssignTask(_ task: AutoTask) async -> TaskAssignment {
        let recommendations = learning.recommendAgents(
            for: task.title,
            context: task.description
        )
        
        let weights = calculateAssignmentWeights(
            task: task,
            recommendations: recommendations
        )
        
        guard let bestAgent = weights.first?.agent else {
            fatalError("No suitable agent found")
        }
        
        let assignment = TaskAssignment(
            id: UUID(),
            task: task,
            agent: bestAgent,
            assignedAt: Date(),
            weight: weights.first!.weight,
            slaDeadline: Date().addingTimeInterval(task.sla),
            status: .assigned
        )
        
        assignments.append(assignment)
        telemetry.tasksAssigned += 1
        
        // Update task status
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].status = .assigned
            tasks[index].assignedAgent = bestAgent
        }
        
        return assignment
    }
    
    // MARK: - Assignment Weights
    
    private func calculateAssignmentWeights(
        task: AutoTask,
        recommendations: [AgentRecommendation]
    ) -> [AgentWeight] {
        var weights: [AgentWeight] = []
        
        for recommendation in recommendations {
            var weight = recommendation.score
            
            // Priority multiplier
            switch task.priority {
            case .critical:
                weight *= 1.5
            case .high:
                weight *= 1.3
            case .medium:
                weight *= 1.0
            case .low:
                weight *= 0.8
            }
            
            // Type-specific weights
            weight *= typeWeight(agent: recommendation.agent, taskType: task.type)
            
            // Workload adjustment
            let currentWorkload = assignments.filter {
                $0.agent.id == recommendation.agent.id && $0.status == .assigned
            }.count
            weight *= max(0.5, 1.0 - (Double(currentWorkload) * 0.1))
            
            weights.append(AgentWeight(
                agent: recommendation.agent,
                weight: weight,
                rationale: recommendation.rationale
            ))
        }
        
        return weights.sorted { $0.weight > $1.weight }
    }
    
    private func typeWeight(agent: AIAgent, taskType: TaskType) -> Double {
        switch taskType {
        case .article:
            return agent.role == .technicalWriter ? 1.5 : 1.0
        case .poem:
            return agent.personality == .creative ? 1.4 : 1.0
        case .lyrics:
            return agent.name == "Sonic" || agent.personality == .creative ? 1.4 : 1.0
        case .beats:
            return agent.name == "Sonic" ? 1.5 : 1.0
        case .cartoon:
            return agent.role == .designer || agent.role == .technicalArtist ? 1.4 : 1.0
        case .code:
            return agent.role == .developer ? 1.5 : 1.0
        case .design:
            return agent.role == .designer ? 1.5 : 1.0
        case .security:
            return agent.role == .securityEngineer ? 1.5 : 1.0
        case .testing:
            return agent.role == .qaEngineer ? 1.5 : 1.0
        }
    }
    
    // MARK: - SLA Calculation
    
    private func calculateSLA(priority: TaskPriority, type: TaskType) -> TimeInterval {
        let baseSLA: TimeInterval
        
        switch priority {
        case .critical:
            baseSLA = 3600 // 1 hour
        case .high:
            baseSLA = 14400 // 4 hours
        case .medium:
            baseSLA = 86400 // 24 hours
        case .low:
            baseSLA = 259200 // 3 days
        }
        
        // Type multiplier
        let typeMultiplier: Double
        switch type {
        case .article, .poem, .lyrics:
            typeMultiplier = 1.5 // Creative work takes longer
        case .beats, .cartoon:
            typeMultiplier = 2.0 // Complex creative work
        case .code, .design:
            typeMultiplier = 1.2
        case .security, .testing:
            typeMultiplier = 1.0
        }
        
        return baseSLA * typeMultiplier
    }
    
    // MARK: - Task Completion
    
    public func completeTask(_ assignment: TaskAssignment, quality: Double) {
        guard let assignmentIndex = assignments.firstIndex(where: { $0.id == assignment.id }) else { return }
        
        assignments[assignmentIndex].status = .completed
        assignments[assignmentIndex].completedAt = Date()
        assignments[assignmentIndex].quality = quality
        
        // Update task
        if let taskIndex = tasks.firstIndex(where: { $0.id == assignment.task.id }) {
            tasks[taskIndex].status = .completed
        }
        
        // Update agent skills
        learning.updateAgentSkills(
            agent: assignment.agent,
            task: assignment.task.type.rawValue,
            performance: quality
        )
        
        // Update telemetry
        telemetry.tasksCompleted += 1
        
        let duration = Date().timeIntervalSince(assignment.assignedAt)
        let metSLA = duration <= assignment.task.sla
        
        if metSLA {
            telemetry.slasMet += 1
        } else {
            telemetry.slasBreached += 1
        }
        
        telemetry.averageCompletionTime = (telemetry.averageCompletionTime * Double(telemetry.tasksCompleted - 1) + duration) / Double(telemetry.tasksCompleted)
        telemetry.averageQuality = (telemetry.averageQuality * Double(telemetry.tasksCompleted - 1) + quality) / Double(telemetry.tasksCompleted)
    }
    
    // MARK: - Analytics
    
    public func getTaskAnalytics() -> TaskAnalytics {
        let pendingTasks = tasks.filter { $0.status == .pending }.count
        let assignedTasks = tasks.filter { $0.status == .assigned }.count
        let completedTasks = tasks.filter { $0.status == .completed }.count
        
        let slaCompliance = telemetry.tasksCompleted > 0 ?
            Double(telemetry.slasMet) / Double(telemetry.tasksCompleted) : 0.0
        
        return TaskAnalytics(
            totalTasks: tasks.count,
            pendingTasks: pendingTasks,
            assignedTasks: assignedTasks,
            completedTasks: completedTasks,
            slaCompliance: slaCompliance,
            averageCompletionTime: telemetry.averageCompletionTime,
            averageQuality: telemetry.averageQuality
        )
    }
}

// MARK: - Models

public struct AutoTask: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: TaskType
    public let priority: TaskPriority
    public let context: TaskContext
    public let createdAt: Date
    public let sla: TimeInterval
    public var status: TaskStatus
    public var assignedAgent: AIAgent?
}

public enum TaskType: String, Codable {
    case article = "Article"
    case poem = "Poem"
    case lyrics = "Lyrics"
    case beats = "Beats"
    case cartoon = "Cartoon"
    case code = "Code"
    case design = "Design"
    case security = "Security"
    case testing = "Testing"
}

public enum TaskStatus: String, Codable {
    case pending = "Pending"
    case assigned = "Assigned"
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
}

public struct TaskContext: Codable {
    public let domain: String
    public let requirements: [String]
    public let constraints: [String]
    public let metadata: [String: String]
    
    public init(domain: String, requirements: [String], constraints: [String], metadata: [String: String] = [:]) {
        self.domain = domain
        self.requirements = requirements
        self.constraints = constraints
        self.metadata = metadata
    }
}

public struct TaskAssignment: Identifiable, Codable {
    public let id: UUID
    public let task: AutoTask
    public let agent: AIAgent
    public let assignedAt: Date
    public let weight: Double
    public let slaDeadline: Date
    public var status: TaskStatus
    public var completedAt: Date?
    public var quality: Double?
}

public struct AgentWeight {
    public let agent: AIAgent
    public let weight: Double
    public let rationale: String
}

public struct TaskTelemetry {
    public var tasksCreated: Int = 0
    public var tasksAssigned: Int = 0
    public var tasksCompleted: Int = 0
    public var slasMet: Int = 0
    public var slasBreached: Int = 0
    public var averageCompletionTime: TimeInterval = 0
    public var averageQuality: Double = 0
}

public struct TaskAnalytics {
    public let totalTasks: Int
    public let pendingTasks: Int
    public let assignedTasks: Int
    public let completedTasks: Int
    public let slaCompliance: Double
    public let averageCompletionTime: TimeInterval
    public let averageQuality: Double
}
