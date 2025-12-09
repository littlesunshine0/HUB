//
//  AIAssistantIntegration.swift
//  Hub
//
//  Integration layer connecting AI backend to the chat UI
//

import SwiftUI
import Combine

// MARK: - AI Assistant Integration Service

@MainActor
final class AIAssistantIntegrationService: ObservableObject, AIAssistantBrowserIntegrating {
    
    // MARK: - Published Properties
    
    @Published var aiSuggestions: [AISuggestion] = []
    @Published var showAIPanel: Bool = false
    @Published var isConnected: Bool = false
    @Published var currentProvider: String = "Local"
    @Published var tokensUsed: Int = 0
    @Published var lastError: String?
    
    // MARK: - Backend Services
    
    private let backend: AIBackendService
    private let ragEngine: RAGEngine
    private var conversationHistory: [ChatTurn] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    var config: AIBackendConfig {
        get { backend.config }
        set { backend.config = newValue }
    }
    
    // MARK: - Initialization
    
    init() {
        self.backend = AIBackendService.shared
        self.ragEngine = RAGEngine()
        
        setupBindings()
        generateInitialSuggestions()
    }
    
    private func setupBindings() {
        backend.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        backend.$tokensUsed
            .receive(on: DispatchQueue.main)
            .assign(to: &$tokensUsed)
    }
    
    // MARK: - AIAssistantBrowserIntegrating Protocol
    
    func askAI(query: String) async -> (message: String, canGenerate: Bool) {
        do {
            let response = try await backend.chat(
                message: query,
                context: nil,
                history: conversationHistory
            )
            
            // Update history
            conversationHistory.append(ChatTurn(role: "user", content: query, timestamp: Date()))
            conversationHistory.append(ChatTurn(role: "assistant", content: response.content, timestamp: Date()))
            
            // Determine if response suggests generation
            let canGenerate = response.content.lowercased().contains("generate") ||
                              response.content.lowercased().contains("create") ||
                              response.toolCalls?.contains { $0.name == "generate_code" } == true
            
            return (response.content, canGenerate)
        } catch {
            lastError = error.localizedDescription
            return ("Sorry, I encountered an error: \(error.localizedDescription)", false)
        }
    }
    
    func askAIStreaming(query: String, context: AIContext?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = backend.chatStreaming(
                        message: query,
                        context: context,
                        history: conversationHistory
                    )
                    
                    var fullResponse = ""
                    
                    for try await chunk in stream {
                        fullResponse += chunk.content
                        continuation.yield(chunk.content)
                        
                        if chunk.isComplete {
                            break
                        }
                    }
                    
                    // Update history
                    await MainActor.run {
                        conversationHistory.append(ChatTurn(role: "user", content: query, timestamp: Date()))
                        conversationHistory.append(ChatTurn(role: "assistant", content: fullResponse, timestamp: Date()))
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func executeAction(_ action: AIAction) async throws -> AIActionResult {
        switch action {
        case .generateCode(let description, let language):
            let response = try await backend.chat(
                message: "Generate \(language) code: \(description)",
                context: nil,
                history: []
            )
            return .success(message: response.content)
            
        case .editFile(let path, let changes):
            // Would integrate with file system
            return .success(message: "Edited \(path)")
            
        case .createFile(let path, let content):
            let url = URL(fileURLWithPath: path)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return .success(message: "Created \(path)")
            
        case .runCommand(let command):
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return .success(message: output)
            
        case .explain(let topic):
            let response = try await backend.chat(
                message: "Explain: \(topic)",
                context: nil,
                history: []
            )
            return .success(message: response.content)
            
        case .refactor(let code, let style):
            let response = try await backend.chat(
                message: "Refactor this code with \(style) style:\n\(code)",
                context: nil,
                history: []
            )
            return .success(message: response.content)
        }
    }
    
    // MARK: - Suggestions
    
    private func generateInitialSuggestions() {
        aiSuggestions = [
            AISuggestion(
                title: "Generate a SwiftUI view",
                description: "Create a new view component",
                action: .generateCode(description: "SwiftUI view", appName: "MyApp")
            ),
            AISuggestion(
                title: "Explain this code",
                description: "Get a detailed explanation",
                action: .explainFramework("SwiftUI")
            ),
            AISuggestion(
                title: "Find templates",
                description: "Browse available templates",
                action: .navigateTo(.templates)
            ),
            AISuggestion(
                title: "Debug an issue",
                description: "Help fix errors",
                action: .explainFramework("debugging")
            ),
            AISuggestion(
                title: "Optimize performance",
                description: "Improve code efficiency",
                action: .explainFramework("performance")
            )
        ]
    }
    
    func updateSuggestions(for context: AIContext) {
        var suggestions: [AISuggestion] = []
        
        // Context-aware suggestions
        if let file = context.currentFile {
            suggestions.append(AISuggestion(
                title: "Explain \(file.path.components(separatedBy: "/").last ?? "file")",
                description: "Understand this \(file.language) file",
                action: .explainFramework(file.language)
            ))
            
            suggestions.append(AISuggestion(
                title: "Find issues in this file",
                description: "Analyze for potential problems",
                action: .explainFramework("code review")
            ))
        }
        
        if context.selectedText != nil {
            suggestions.insert(AISuggestion(
                title: "Explain selected code",
                description: "Understand the selection",
                action: .explainFramework("selection")
            ), at: 0)
            
            suggestions.append(AISuggestion(
                title: "Refactor selection",
                description: "Improve the selected code",
                action: .generateCode(description: "refactor", appName: "")
            ))
        }
        
        // Add default suggestions
        suggestions.append(contentsOf: [
            AISuggestion(
                title: "Generate code",
                description: "Create new code from description",
                action: .generateCode(description: "", appName: "")
            ),
            AISuggestion(
                title: "Search codebase",
                description: "Find code patterns",
                action: .navigateTo(.search)
            )
        ])
        
        aiSuggestions = suggestions
    }
    
    // MARK: - RAG Integration
    
    func indexProject(at path: String) async throws {
        try await ragEngine.indexCodebase(at: path)
    }
    
    func searchCodebase(query: String) async -> [RAGDocument] {
        await ragEngine.hybridSearch(query: query, topK: 10)
    }
    
    // MARK: - Configuration
    
    func configure(provider: AIBackendConfig.AIProviderType, apiKey: String? = nil) {
        var newConfig = config
        newConfig.provider = provider
        newConfig.apiKey = apiKey
        config = newConfig
        currentProvider = provider.rawValue
    }
    
    func setModel(_ model: String) {
        var newConfig = config
        newConfig.model = model
        config = newConfig
    }
    
    // MARK: - History Management
    
    func clearHistory() {
        conversationHistory.removeAll()
    }
    
    func exportHistory() -> String {
        conversationHistory.map { turn in
            "[\(turn.role)] \(turn.content)"
        }.joined(separator: "\n\n")
    }
}

// MARK: - AISuggestion Model (if not defined elsewhere)

struct AISuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let action: SuggestionAction
    
    enum SuggestionAction {
        case generateCode(description: String, appName: String)
        case navigateTo(NavigationDestination)
        case explainFramework(String)
        case search(String)
    }
    
    enum NavigationDestination {
        case templates
        case search
        case settings
        case help
    }
}

// MARK: - Preview Provider

#if DEBUG
final class PreviewAIIntegrationService: AIAssistantBrowserIntegrating {
    @Published var aiSuggestions: [AISuggestion] = [
        AISuggestion(title: "Generate a todo app", description: "Create a starter", action: .generateCode(description: "todo", appName: "Todo")),
        AISuggestion(title: "Explain SwiftUI", description: "Learn the basics", action: .explainFramework("SwiftUI"))
    ]
    @Published var showAIPanel: Bool = false
    
    func askAI(query: String) async -> (message: String, canGenerate: Bool) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return ("Here's my response to: \(query)", query.lowercased().contains("generate"))
    }
    
    func askAIStreaming(query: String, context: AIContext?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let response = "I'll help you with that. Here's a detailed response..."
                for char in response {
                    continuation.yield(String(char))
                    try? await Task.sleep(nanoseconds: 20_000_000)
                }
                continuation.finish()
            }
        }
    }
    
    func executeAction(_ action: AIAction) async throws -> AIActionResult {
        .success(message: "Action completed")
    }
}
#endif
