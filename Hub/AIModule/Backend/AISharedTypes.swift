//
//  AISharedTypes.swift
//  Hub
//
//  Shared types for AI module integration
//

import Foundation

// MARK: - AI Context

/// Context information for AI operations
public struct AIContext: Sendable {
    public var currentFile: FileContext?
    public var selectedText: String?
    public var projectPath: String?
    public var recentFiles: [String]
    public var activeModule: String?
    public var projectContext: ProjectContext?
    
    public init(
        currentFile: FileContext? = nil,
        selectedText: String? = nil,
        projectPath: String? = nil,
        recentFiles: [String] = [],
        activeModule: String? = nil,
        projectContext: ProjectContext? = nil
    ) {
        self.currentFile = currentFile
        self.selectedText = selectedText
        self.projectPath = projectPath
        self.recentFiles = recentFiles
        self.activeModule = activeModule
        self.projectContext = projectContext
    }
    
    public struct FileContext: Sendable {
        public let path: String
        public let language: String
        public let content: String?
        
        public init(path: String, language: String, content: String? = nil) {
            self.path = path
            self.language = language
            self.content = content
        }
    }
    
    public struct ProjectContext: Sendable {
        public let name: String
        public let type: String
        public let frameworks: [String]
        
        public init(name: String, type: String, frameworks: [String] = []) {
            self.name = name
            self.type = type
            self.frameworks = frameworks
        }
    }
}

// MARK: - AI Action

/// Actions that can be executed by the AI assistant
public enum AIAction: Sendable {
    case generateCode(description: String, language: String)
    case editFile(path: String, changes: String)
    case createFile(path: String, content: String)
    case runCommand(command: String)
    case explain(topic: String)
    case refactor(code: String, style: String)
}

// MARK: - AI Action Result

/// Result of an AI action execution
public enum AIActionResult: Sendable {
    case success(message: String)
    case failure(error: String)
    case pending(taskId: String)
    
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    public var message: String {
        switch self {
        case .success(let msg): return msg
        case .failure(let err): return err
        case .pending(let id): return "Task pending: \(id)"
        }
    }
}

// MARK: - Chat Turn

/// Represents a single turn in a conversation
public struct ChatTurn: @unchecked Sendable {
    public let role: String
    public let content: String
    public let timestamp: Date
    public var toolCalls: [ToolCall]?
    public var toolResults: [ToolResult]?
    
    public init(role: String, content: String, timestamp: Date = Date(), toolCalls: [ToolCall]? = nil, toolResults: [ToolResult]? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCalls = toolCalls
        self.toolResults = toolResults
    }
}

// MARK: - AI Attachment

/// Attachment for AI context
public struct AIAttachment: Identifiable, Sendable {
    public let id: UUID
    public let type: AttachmentType
    public let data: Data
    public let name: String
    
    public init(id: UUID = UUID(), type: AttachmentType, data: Data, name: String) {
        self.id = id
        self.type = type
        self.data = data
        self.name = name
    }
    
    public enum AttachmentType: Sendable {
        case image
        case file
        case code
        case document
        case url
    }
}

// MARK: - Enriched Context

/// Enriched context for AI processing
public struct EnrichedContext: @unchecked Sendable {
    public var originalContext: AIContext?
    public var fileContent: String?
    public var fileLanguage: String?
    public var filePath: String?
    public var selectedCode: String?
    public var selectionAnalysis: CodeAnalysis?
    public var projectName: String?
    public var projectType: String?
    public var frameworks: [String]
    public var imageAnalyses: [ImageAnalysis]
    public var attachedFiles: [AttachedFile]
    public var codeSnippets: [String]
    public var urlContents: [URLContent]
    public var detectedIntent: UserIntent
    public var entities: [ExtractedEntity]
    public var ragDocuments: [String]
    public var metadata: [String: Any]
    
    public init(
        originalContext: AIContext? = nil,
        fileContent: String? = nil,
        fileLanguage: String? = nil,
        filePath: String? = nil,
        selectedCode: String? = nil,
        selectionAnalysis: CodeAnalysis? = nil,
        projectName: String? = nil,
        projectType: String? = nil,
        frameworks: [String] = [],
        imageAnalyses: [ImageAnalysis] = [],
        attachedFiles: [AttachedFile] = [],
        codeSnippets: [String] = [],
        urlContents: [URLContent] = [],
        detectedIntent: UserIntent = .general,
        entities: [ExtractedEntity] = [],
        ragDocuments: [String] = [],
        metadata: [String: Any] = [:]
    ) {
        self.originalContext = originalContext
        self.fileContent = fileContent
        self.fileLanguage = fileLanguage
        self.filePath = filePath
        self.selectedCode = selectedCode
        self.selectionAnalysis = selectionAnalysis
        self.projectName = projectName
        self.projectType = projectType
        self.frameworks = frameworks
        self.imageAnalyses = imageAnalyses
        self.attachedFiles = attachedFiles
        self.codeSnippets = codeSnippets
        self.urlContents = urlContents
        self.detectedIntent = detectedIntent
        self.entities = entities
        self.ragDocuments = ragDocuments
        self.metadata = metadata
    }
}

// MARK: - AI Response

/// Response from AI backend
public struct AIResponse: @unchecked Sendable {
    public let content: String
    public let toolCalls: [ToolCall]?
    public let tokensUsed: Int
    public let model: String
    public let finishReason: String?
    
    public init(
        content: String,
        toolCalls: [ToolCall]? = nil,
        tokensUsed: Int = 0,
        model: String = "unknown",
        finishReason: String? = nil
    ) {
        self.content = content
        self.toolCalls = toolCalls
        self.tokensUsed = tokensUsed
        self.model = model
        self.finishReason = finishReason
    }
}

// MARK: - Tool Call

/// Represents a tool call from the AI
public struct ToolCall: Identifiable, @unchecked Sendable {
    public let id: String
    public let name: String
    public let arguments: [String: Any]
    
    public init(id: String = UUID().uuidString, name: String, arguments: [String: Any]) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

// MARK: - Stream Chunk

/// Chunk of streaming response
public struct StreamChunk: @unchecked Sendable {
    public let content: String
    public let isComplete: Bool
    public var toolCall: ToolCall?
    
    public init(content: String, isComplete: Bool = false, toolCall: ToolCall? = nil) {
        self.content = content
        self.isComplete = isComplete
        self.toolCall = toolCall
    }
}

// MARK: - Code Analysis

/// Analysis result for code snippets
public struct CodeAnalysis: Sendable {
    public let language: String
    public let complexity: Int
    public let patterns: [String]
    public let issues: [String]
    
    public init(language: String, complexity: Int, patterns: [String], issues: [String]) {
        self.language = language
        self.complexity = complexity
        self.patterns = patterns
        self.issues = issues
    }
}

// MARK: - Image Analysis

/// Analysis result for images
public struct ImageAnalysis: Sendable {
    public let description: String
    public let objects: [String]
    public let text: String?
    
    public init(description: String, objects: [String], text: String?) {
        self.description = description
        self.objects = objects
        self.text = text
    }
}

// MARK: - URL Content

/// Content fetched from a URL
public struct URLContent: Sendable {
    public let url: String
    public let content: String
    
    public init(url: String, content: String) {
        self.url = url
        self.content = content
    }
}

// MARK: - Attached File

/// File attached to AI context
public struct AttachedFile: Sendable {
    public let name: String
    public let content: String
    
    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }
}

// MARK: - User Intent

/// Detected user intent from message
public enum UserIntent: String, Sendable {
    case generate
    case explain
    case debug
    case refactor
    case search
    case test
    case document
    case general
}

// MARK: - Extracted Entity

/// Entity extracted from text
public struct ExtractedEntity: @unchecked Sendable {
    public let text: String
    public let type: String
    public let range: Range<String.Index>
    
    public init(text: String, type: String, range: Range<String.Index>) {
        self.text = text
        self.type = type
        self.range = range
    }
}

// MARK: - Tool Result

/// Result from tool execution
public struct ToolResult: Sendable {
    public let toolCallId: String
    public let success: Bool
    public let output: String?
    public let error: String?
    
    public init(toolCallId: String, success: Bool, output: String?, error: String? = nil) {
        self.toolCallId = toolCallId
        self.success = success
        self.output = output
        self.error = error
    }
}

// MARK: - AI Backend Error

/// Errors from AI backend
public enum AIBackendError: Error, LocalizedError, Sendable {
    case networkError(String)
    case apiError(statusCode: Int, message: String)
    case rateLimited
    case invalidResponse
    case contextTooLarge
    case contextTooLong
    case modelNotAvailable(String)
    case authenticationFailed
    case providerNotFound(String)
    case missingAPIKey
    case embeddingFailed
    case ollamaNotRunning
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .rateLimited: return "Rate limited - please try again later"
        case .invalidResponse: return "Invalid response from AI"
        case .contextTooLarge: return "Context too large for model"
        case .contextTooLong: return "Context exceeds maximum length"
        case .modelNotAvailable(let model): return "Model not available: \(model)"
        case .authenticationFailed: return "Authentication failed"
        case .providerNotFound(let name): return "AI provider not found: \(name)"
        case .missingAPIKey: return "API key is required"
        case .embeddingFailed: return "Failed to generate embeddings"
        case .ollamaNotRunning: return "Ollama is not running. Start it with 'ollama serve'"
        }
    }
}

// MARK: - RAG Document

/// Document from RAG retrieval
public struct RAGDocument: Identifiable, Sendable {
    public let id: String
    public let content: String
    public let metadata: VectorDocumentMetadata
    public var score: Double?
    
    public init(id: String, content: String, metadata: VectorDocumentMetadata, score: Double? = nil) {
        self.id = id
        self.content = content
        self.metadata = metadata
        self.score = score
    }
}

// MARK: - Vector Document Metadata

/// Metadata for vector store documents
public struct VectorDocumentMetadata: Codable, Sendable {
    public let source: String
    public let type: VectorDocumentType
    public let language: String?
    public let title: String?
    public var chunkIndex: Int?
    
    public init(source: String, type: VectorDocumentType, language: String? = nil, title: String? = nil, chunkIndex: Int? = nil) {
        self.source = source
        self.type = type
        self.language = language
        self.title = title
        self.chunkIndex = chunkIndex
    }
    
    public func with(chunkIndex: Int) -> VectorDocumentMetadata {
        var copy = self
        copy.chunkIndex = chunkIndex
        return copy
    }
}

public enum VectorDocumentType: String, Codable, Sendable {
    case code
    case documentation
    case markdown
    case text
    case config
}

// MARK: - Tool Definition

/// Definition of an available tool
public struct ToolDefinition: Sendable {
    public let name: String
    public let description: String
    public let parameters: [ToolParameter]
    
    public init(name: String, description: String, parameters: [ToolParameter]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

// MARK: - Tool Parameter

/// Parameter for a tool
public struct ToolParameter: Codable, Sendable {
    public let name: String
    public let type: String
    public let description: String
    public let required: Bool
    public let enumValues: [String]?
    
    public init(name: String, type: String, description: String, required: Bool = true, enumValues: [String]? = nil) {
        self.name = name
        self.type = type
        self.description = description
        self.required = required
        self.enumValues = enumValues
    }
}

// MARK: - LLM Message

/// Message for LLM prompt
public struct LLMMessage: Sendable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - LLM Prompt

/// Prompt for LLM
public struct LLMPrompt: Sendable {
    public let messages: [LLMMessage]
    public let tools: [ToolDefinition]?
    
    public init(messages: [LLMMessage], tools: [ToolDefinition]? = nil) {
        self.messages = messages
        self.tools = tools
    }
}
