//
//  AIBackendService.swift
//  Hub
//
//  Complete AI Backend with LLM integration, RAG, embeddings, tool execution
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - AI Backend Configuration

struct AIBackendConfig {
    var provider: AIProviderType = .local
    var model: String = "gpt-4"
    var temperature: Double = 0.7
    var maxTokens: Int = 4096
    var apiKey: String?
    var baseURL: String?
    var embeddingModel: String = "text-embedding-3-small"
    var enableRAG: Bool = true
    var enableTools: Bool = true
    var enableStreaming: Bool = true
    var contextWindowSize: Int = 128000
    
    enum AIProviderType: String, CaseIterable {
        case openAI = "OpenAI"
        case anthropic = "Anthropic"
        case ollama = "Ollama"
        case local = "Local"
        case bedrock = "AWS Bedrock"
    }
}

// MARK: - Main Backend Service

@MainActor
final class AIBackendService: ObservableObject {
    static let shared = AIBackendService()
    
    @Published var config: AIBackendConfig = AIBackendConfig()
    @Published var isProcessing = false
    @Published var currentModel: String = "local"
    @Published var tokensUsed: Int = 0
    @Published var lastError: AIBackendError?
    
    private let llmRouter: LLMRouter
    private let embeddingService: EmbeddingService
    private let ragEngine: RAGEngine
    private let toolExecutor: ToolExecutor
    private let contextManager: ContextWindowManager
    private let promptEngine: PromptEngine
    private let responseParser: ResponseParser
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.llmRouter = LLMRouter()
        self.embeddingService = EmbeddingService()
        self.ragEngine = RAGEngine()
        self.toolExecutor = ToolExecutor()
        self.contextManager = ContextWindowManager()
        self.promptEngine = PromptEngine()
        self.responseParser = ResponseParser()
    }
    
    // MARK: - Main Chat Interface
    
    func chat(
        message: String,
        context: AIContext?,
        history: [ChatTurn],
        attachments: [AIAttachment] = []
    ) async throws -> AIResponse {
        isProcessing = true
        defer { isProcessing = false }
        
        // Build context
        let enrichedContext = await buildEnrichedContext(message: message, context: context, attachments: attachments)
        
        // RAG retrieval if enabled
        var ragContext: [RAGDocument] = []
        if config.enableRAG {
            ragContext = await ragEngine.retrieve(query: message, topK: 5)
        }
        
        // Build prompt
        let tools = config.enableTools ? await toolExecutor.availableTools : []
        let prompt = promptEngine.buildPrompt(
            message: message,
            context: enrichedContext,
            history: history,
            ragDocuments: ragContext,
            tools: tools
        )
        
        // Route to LLM
        let llmResponse = try await llmRouter.complete(
            prompt: prompt,
            config: config
        )
        
        // Parse response for tool calls
        let parsed = responseParser.parse(llmResponse)
        
        // Execute tools if needed
        var finalResponse = parsed
        if let toolCalls = parsed.toolCalls, !toolCalls.isEmpty {
            let toolResults = await executeTools(toolCalls)
            finalResponse = try await handleToolResults(
                originalMessage: message,
                toolResults: toolResults,
                context: enrichedContext
            )
        }
        
        tokensUsed += finalResponse.tokensUsed
        return finalResponse
    }
    
    // MARK: - Streaming Chat
    
    func chatStreaming(
        message: String,
        context: AIContext?,
        history: [ChatTurn]
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let enrichedContext = await buildEnrichedContext(message: message, context: context, attachments: [])
                    
                    var ragContext: [RAGDocument] = []
                    if config.enableRAG {
                        ragContext = await ragEngine.retrieve(query: message, topK: 5)
                    }
                    
                    let tools = self.config.enableTools ? await self.toolExecutor.availableTools : []
                    let prompt = self.promptEngine.buildPrompt(
                        message: message,
                        context: enrichedContext,
                        history: history,
                        ragDocuments: ragContext,
                        tools: tools
                    )
                    
                    let stream = await self.llmRouter.streamComplete(prompt: prompt, config: self.config)
                    
                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Context Building
    
    private func buildEnrichedContext(
        message: String,
        context: AIContext?,
        attachments: [AIAttachment]
    ) async -> EnrichedContext {
        var enriched = EnrichedContext()
        
        // Base context
        enriched.originalContext = context
        
        // File context
        if let fileContext = context?.currentFile {
            enriched.fileContent = await loadFileContent(fileContext.path)
            enriched.fileLanguage = fileContext.language
            enriched.filePath = fileContext.path
        }
        
        // Selection context
        if let selection = context?.selectedText, !selection.isEmpty {
            enriched.selectedCode = selection
            enriched.selectionAnalysis = analyzeCode(selection)
        }
        
        // Project context
        if let project = context?.projectContext {
            enriched.projectName = project.name
            enriched.projectType = project.type
            enriched.frameworks = project.frameworks
        }
        
        // Process attachments
        for attachment in attachments {
            switch attachment.type {
            case .image:
                if let analysis = await analyzeImage(attachment.data) {
                    enriched.imageAnalyses.append(analysis)
                }
            case .file, .document:
                enriched.attachedFiles.append(AttachedFile(
                    name: attachment.name,
                    content: String(data: attachment.data, encoding: .utf8) ?? ""
                ))
            case .code:
                enriched.codeSnippets.append(String(data: attachment.data, encoding: .utf8) ?? "")
            case .url:
                if let urlContent = await fetchURLContent(attachment.data) {
                    enriched.urlContents.append(urlContent)
                }
            }
        }
        
        // Intent detection
        enriched.detectedIntent = detectIntent(message)
        
        // Entity extraction
        enriched.entities = extractEntities(message)
        
        return enriched
    }
    
    private func loadFileContent(_ path: String) async -> String? {
        let url = URL(fileURLWithPath: path)
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    private func analyzeCode(_ code: String) -> CodeAnalysis {
        CodeAnalysis(
            language: detectLanguage(code),
            complexity: estimateComplexity(code),
            patterns: detectPatterns(code),
            issues: detectIssues(code)
        )
    }
    
    private func analyzeImage(_ data: Data) async -> ImageAnalysis? {
        // Vision analysis placeholder - would integrate with Vision framework or API
        return ImageAnalysis(description: "Image attachment", objects: [], text: nil)
    }
    
    private func fetchURLContent(_ data: Data) async -> URLContent? {
        guard let urlString = String(data: data, encoding: .utf8),
              let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let content = String(data: data, encoding: .utf8) ?? ""
            return URLContent(url: urlString, content: content.prefix(10000).description)
        } catch {
            return nil
        }
    }
    
    private func detectIntent(_ message: String) -> UserIntent {
        let lowercased = message.lowercased()
        
        if lowercased.contains("generate") || lowercased.contains("create") || lowercased.contains("build") {
            return .generate
        } else if lowercased.contains("explain") || lowercased.contains("what is") || lowercased.contains("how does") {
            return .explain
        } else if lowercased.contains("fix") || lowercased.contains("debug") || lowercased.contains("error") {
            return .debug
        } else if lowercased.contains("refactor") || lowercased.contains("improve") || lowercased.contains("optimize") {
            return .refactor
        } else if lowercased.contains("find") || lowercased.contains("search") || lowercased.contains("where") {
            return .search
        } else if lowercased.contains("test") {
            return .test
        } else if lowercased.contains("document") {
            return .document
        }
        return .general
    }
    
    private func extractEntities(_ text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                entities.append(ExtractedEntity(
                    text: String(text[range]),
                    type: tag.rawValue,
                    range: range
                ))
            }
            return true
        }
        
        // Code-specific entities
        let codePatterns = [
            ("function", #"\b(func|function|def)\s+(\w+)"#),
            ("class", #"\b(class|struct|enum)\s+(\w+)"#),
            ("variable", #"\b(let|var|const)\s+(\w+)"#),
            ("import", #"\b(import|require|include)\s+[\"']?(\w+)"#)
        ]
        
        for (type, pattern) in codePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                for match in regex.matches(in: text, range: range) {
                    if let matchRange = Range(match.range(at: 2), in: text) {
                        entities.append(ExtractedEntity(
                            text: String(text[matchRange]),
                            type: type,
                            range: matchRange
                        ))
                    }
                }
            }
        }
        
        return entities
    }
    
    private func detectLanguage(_ code: String) -> String {
        if code.contains("func ") && code.contains("var ") { return "swift" }
        if code.contains("function") && code.contains("const") { return "javascript" }
        if code.contains("def ") && code.contains(":") { return "python" }
        if code.contains("fn ") && code.contains("let mut") { return "rust" }
        if code.contains("func ") && code.contains("package") { return "go" }
        return "unknown"
    }
    
    private func estimateComplexity(_ code: String) -> Int {
        var complexity = 1
        let patterns = ["if ", "else ", "for ", "while ", "switch ", "case ", "catch ", "&&", "||"]
        for pattern in patterns {
            complexity += code.components(separatedBy: pattern).count - 1
        }
        return complexity
    }
    
    private func detectPatterns(_ code: String) -> [String] {
        var patterns: [String] = []
        if code.contains("@Observable") || code.contains("ObservableObject") { patterns.append("MVVM") }
        if code.contains("protocol") && code.contains("extension") { patterns.append("Protocol-Oriented") }
        if code.contains("async") && code.contains("await") { patterns.append("Async/Await") }
        if code.contains("Combine") || code.contains("Publisher") { patterns.append("Reactive") }
        return patterns
    }
    
    private func detectIssues(_ code: String) -> [String] {
        var issues: [String] = []
        if code.contains("force unwrap") || code.contains("!") { issues.append("Force unwrapping detected") }
        if code.contains("try!") { issues.append("Force try detected") }
        if code.count > 500 { issues.append("Function may be too long") }
        return issues
    }
    
    // MARK: - Tool Execution
    
    private func executeTools(_ toolCalls: [ToolCall]) async -> [ToolResult] {
        var results: [ToolResult] = []
        
        for call in toolCalls {
            let result = await toolExecutor.execute(call)
            results.append(result)
        }
        
        return results
    }
    
    private func handleToolResults(
        originalMessage: String,
        toolResults: [ToolResult],
        context: EnrichedContext
    ) async throws -> AIResponse {
        // Build follow-up prompt with tool results
        let followUpPrompt = promptEngine.buildToolResultPrompt(
            originalMessage: originalMessage,
            toolResults: toolResults,
            context: context
        )
        
        return try await llmRouter.complete(prompt: followUpPrompt, config: config)
    }
}
