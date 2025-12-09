import Foundation
import SwiftUI

// MARK: - Visual Workflow
struct VisualWorkflow: Identifiable, Codable {
    let id: UUID
    var name: String
    var nodes: [WorkflowNode]
    var connections: [WorkflowConnection]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String = "New Workflow", nodes: [WorkflowNode] = [], connections: [WorkflowConnection] = []) {
        self.id = id
        self.name = name
        self.nodes = nodes
        self.connections = connections
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Workflow Node
struct WorkflowNode: Identifiable, Codable, Equatable {
    let id: UUID
    var type: WorkflowNodeType
    var name: String
    var description: String
    var position: CGPoint
    var parameters: [String: String]
    
    init(id: UUID = UUID(), type: WorkflowNodeType, name: String, description: String = "", position: CGPoint = .zero, parameters: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.position = position
        self.parameters = parameters
    }
}

// MARK: - Node Type
enum WorkflowNodeType: String, Codable, CaseIterable {
    // Triggers
    case schedule = "schedule"
    case webhook = "webhook"
    case dataChange = "dataChange"
    case userAction = "userAction"
    
    // Actions
    case sendEmail = "sendEmail"
    case sendSMS = "sendSMS"
    case createRecord = "createRecord"
    case updateRecord = "updateRecord"
    case apiCall = "apiCall"
    case notification = "notification"
    
    // Logic
    case condition = "condition"
    case loop = "loop"
    case delay = "delay"
    case transform = "transform"
    
    var displayName: String {
        switch self {
        case .schedule: return "Schedule"
        case .webhook: return "Webhook"
        case .dataChange: return "Data Change"
        case .userAction: return "User Action"
        case .sendEmail: return "Send Email"
        case .sendSMS: return "Send SMS"
        case .createRecord: return "Create Record"
        case .updateRecord: return "Update Record"
        case .apiCall: return "API Call"
        case .notification: return "Notification"
        case .condition: return "Condition"
        case .loop: return "Loop"
        case .delay: return "Delay"
        case .transform: return "Transform"
        }
    }
    
    var icon: String {
        switch self {
        case .schedule: return "clock"
        case .webhook: return "link"
        case .dataChange: return "cylinder"
        case .userAction: return "hand.tap"
        case .sendEmail: return "envelope"
        case .sendSMS: return "message"
        case .createRecord: return "plus.circle"
        case .updateRecord: return "pencil.circle"
        case .apiCall: return "network"
        case .notification: return "bell"
        case .condition: return "arrow.triangle.branch"
        case .loop: return "arrow.clockwise"
        case .delay: return "timer"
        case .transform: return "wand.and.stars"
        }
    }
    
    static var triggers: [WorkflowNodeType] {
        [.schedule, .webhook, .dataChange, .userAction]
    }
    
    static var actions: [WorkflowNodeType] {
        [.sendEmail, .sendSMS, .createRecord, .updateRecord, .apiCall, .notification]
    }
    
    static var logic: [WorkflowNodeType] {
        [.condition, .loop, .delay, .transform]
    }
}

// MARK: - Connection
struct WorkflowConnection: Identifiable, Codable {
    let id: UUID
    let fromNodeId: UUID
    let toNodeId: UUID
    var condition: String?
    
    init(id: UUID = UUID(), fromNodeId: UUID, toNodeId: UUID, condition: String? = nil) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.condition = condition
    }
}

// MARK: - CGPoint Codable Extension
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
