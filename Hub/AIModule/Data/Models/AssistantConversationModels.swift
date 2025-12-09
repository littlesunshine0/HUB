//
//  ConversationModels.swift
//  Hub
//
//  Conversation models for the Offline Assistant Module
//  Extends base conversation models with assistant-specific features
//

import Foundation

// Note: Base Conversation and Message models are defined in:
// Hub/HubComponents/HubModuleUpdate_2/Domain/Conversation/ConversationModels.swift
// This file extends those models with assistant-specific features

// MARK: - Message Attachment

/// Attachments that can be included with messages
enum MessageAttachment: Codable, Equatable {
    case code(String)
    case link(URL)
    case image(Data)
    case chart(ChartData)
    
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "code":
            let value = try container.decode(String.self, forKey: .value)
            self = .code(value)
        case "link":
            let value = try container.decode(URL.self, forKey: .value)
            self = .link(value)
        case "image":
            let value = try container.decode(Data.self, forKey: .value)
            self = .image(value)
        case "chart":
            let value = try container.decode(ChartData.self, forKey: .value)
            self = .chart(value)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown attachment type: \(type)"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .code(let value):
            try container.encode("code", forKey: .type)
            try container.encode(value, forKey: .value)
        case .link(let value):
            try container.encode("link", forKey: .type)
            try container.encode(value, forKey: .value)
        case .image(let value):
            try container.encode("image", forKey: .type)
            try container.encode(value, forKey: .value)
        case .chart(let value):
            try container.encode("chart", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - Chart Data

/// Data for chart attachments
struct ChartData: Codable, Equatable {
    let type: ChartType
    let data: [DataPoint]
    let title: String?
    
    enum ChartType: String, Codable {
        case line, bar, pie, scatter
    }
    
    struct DataPoint: Codable, Equatable {
        let label: String
        let value: Double
    }
}

// MARK: - Assistant Message

/// Extended message model with attachments for assistant conversations
struct AssistantMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let sender: MessageSender
    let timestamp: Date
    let type: MessageType
    var attachments: [MessageAttachment]
    
    init(
        id: UUID = UUID(),
        content: String,
        sender: MessageSender,
        timestamp: Date = Date(),
        type: MessageType = .text,
        attachments: [MessageAttachment] = []
    ) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.type = type
        self.attachments = attachments
    }
}

// MARK: - Assistant Conversation

/// Extended conversation model with topic and assistant-specific features
struct AssistantConversation: Identifiable, Codable, Equatable {
    let id: UUID
    var messages: [AssistantMessage]
    var startedAt: Date
    var lastMessageAt: Date
    var topic: ConversationTopic
    
    init(
        id: UUID = UUID(),
        messages: [AssistantMessage] = [],
        startedAt: Date = Date(),
        lastMessageAt: Date = Date(),
        topic: ConversationTopic = .general
    ) {
        self.id = id
        self.messages = messages
        self.startedAt = startedAt
        self.lastMessageAt = lastMessageAt
        self.topic = topic
    }
    
    /// Add a message to the conversation
    mutating func addMessage(_ message: AssistantMessage) {
        messages.append(message)
        lastMessageAt = message.timestamp
    }
    
    /// Get recent messages for context
    func getRecentMessages(limit: Int = 10) -> [AssistantMessage] {
        return Array(messages.suffix(limit))
    }
}
