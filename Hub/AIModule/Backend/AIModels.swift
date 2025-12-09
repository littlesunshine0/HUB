//
//  AIModels.swift
//  Hub
//
//  Core data models for the AI backend - API-specific models
//  Note: Common types are defined in AISharedTypes.swift
//

import Foundation

// MARK: - Tool Definition Extensions

extension ToolDefinition {
    func toOpenAITool() -> OpenAITool {
        OpenAITool(
            type: "function",
            function: OpenAIFunction(
                name: name,
                description: description,
                parameters: OpenAIParameters(
                    type: "object",
                    properties: Dictionary(uniqueKeysWithValues: parameters.map { param in
                        (param.name, OpenAIProperty(
                            type: param.type,
                            description: param.description,
                            enum_values: param.enumValues
                        ))
                    }),
                    required: parameters.filter { $0.required }.map { $0.name }
                )
            )
        )
    }
    
    func toAnthropicTool() -> AnthropicTool {
        AnthropicTool(
            name: name,
            description: description,
            input_schema: AnthropicInputSchema(
                type: "object",
                properties: Dictionary(uniqueKeysWithValues: parameters.map { param in
                    (param.name, AnthropicProperty(
                        type: param.type,
                        description: param.description
                    ))
                }),
                required: parameters.filter { $0.required }.map { $0.name }
            )
        )
    }
}

// MARK: - Document Models

// Note: DocumentMetadata and DocumentType are also defined in FrameworkDocumentationCrawler.swift
// Using AI-specific versions here for the AI backend
struct AIDocumentMetadata: Codable {
    let source: String
    let type: AIDocumentType
    let language: String?
    let title: String?
    var chunkIndex: Int?
    
    func with(chunkIndex: Int) -> AIDocumentMetadata {
        var copy = self
        copy.chunkIndex = chunkIndex
        return copy
    }
}

enum AIDocumentType: String, Codable {
    case code
    case documentation
    case markdown
    case text
    case config
}

struct DocumentChunk {
    let text: String
    let metadata: VectorDocumentMetadata
}

struct IndexedDocument {
    let id: String
    let chunkCount: Int
    let indexedAt: Date
}

struct RAGStats {
    let documentCount: Int
    let chunkCount: Int
    let indexSize: Int
}

// MARK: - OpenAI API Models

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int
    let tools: [OpenAITool]?
    let stream: Bool
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAITool: Codable {
    let type: String
    let function: OpenAIFunction
}

struct OpenAIFunction: Codable {
    let name: String
    let description: String
    let parameters: OpenAIParameters
}

struct OpenAIParameters: Codable {
    let type: String
    let properties: [String: OpenAIProperty]
    let required: [String]
}

struct OpenAIProperty: Codable {
    let type: String
    let description: String
    let enum_values: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type, description
        case enum_values = "enum"
    }
}

struct OpenAIChatResponse: Codable {
    let id: String
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let message: OpenAIResponseMessage
    let finish_reason: String?
}

struct OpenAIResponseMessage: Codable {
    let role: String
    let content: String?
    let tool_calls: [OpenAIToolCall]?
}

struct OpenAIToolCall: Codable {
    let id: String
    let type: String
    let function: OpenAIFunctionCall
    
    func toToolCall() -> ToolCall {
        let args = (try? JSONSerialization.jsonObject(with: Data(function.arguments.utf8))) as? [String: Any] ?? [:]
        return ToolCall(id: id, name: function.name, arguments: args)
    }
}

struct OpenAIFunctionCall: Codable {
    let name: String
    let arguments: String
}

struct OpenAIUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct OpenAIStreamChunk: Codable {
    let choices: [OpenAIStreamChoice]
}

struct OpenAIStreamChoice: Codable {
    let delta: OpenAIStreamDelta
}

struct OpenAIStreamDelta: Codable {
    let content: String?
}

// MARK: - Anthropic API Models

struct AnthropicRequest: Codable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [AnthropicMessage]
    let tools: [AnthropicTool]?
    var stream: Bool = false
}

struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

struct AnthropicTool: Codable {
    let name: String
    let description: String
    let input_schema: AnthropicInputSchema
}

struct AnthropicInputSchema: Codable {
    let type: String
    let properties: [String: AnthropicProperty]
    let required: [String]
}

struct AnthropicProperty: Codable {
    let type: String
    let description: String
}

struct AnthropicResponse: Codable {
    let id: String
    let model: String
    let content: [AnthropicContentBlock]
    let stop_reason: String?
    let usage: AnthropicUsage
}

enum AnthropicContentBlock: Codable {
    case text(String)
    case tool_use(id: String, name: String, input: [String: Any])
    
    enum CodingKeys: String, CodingKey {
        case type, text, id, name, input
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "tool_use":
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            // Simplified - would need proper Any decoding
            self = .tool_use(id: id, name: name, input: [:])
        default:
            self = .text("")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .tool_use(let id, let name, _):
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
        }
    }
}

struct AnthropicUsage: Codable {
    let input_tokens: Int
    let output_tokens: Int
}

struct AnthropicStreamEvent: Codable {
    let type: String
    let delta: AnthropicDelta?
}

struct AnthropicDelta: Codable {
    let type: String?
    let text: String?
}
