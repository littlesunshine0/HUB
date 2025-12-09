//
//  LLMProviders.swift
//  Hub
//
//  Additional LLM providers: Ollama, Local, Bedrock
//

import Foundation

// MARK: - Ollama Provider (Local LLMs)

final class OllamaProvider: LLMProvider {
    private let baseURL = "http://localhost:11434"
    
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse {
        let url = URL(string: "\(config.baseURL ?? baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OllamaRequest(
            model: config.model,
            messages: prompt.messages.map { OllamaMessage(role: $0.role, content: $0.content) },
            stream: false,
            options: OllamaOptions(temperature: config.temperature, num_predict: config.maxTokens)
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIBackendError.ollamaNotRunning
        }
        
        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
        
        return AIResponse(
            content: result.message.content,
            toolCalls: nil,
            tokensUsed: result.eval_count ?? 0,
            model: result.model,
            finishReason: result.done ? "stop" : nil
        )
    }
    
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        let url = URL(string: "\(config.baseURL ?? baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OllamaRequest(
            model: config.model,
            messages: prompt.messages.map { OllamaMessage(role: $0.role, content: $0.content) },
            stream: true,
            options: OllamaOptions(temperature: config.temperature, num_predict: config.maxTokens)
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    
                    for try await line in bytes.lines {
                        if let data = line.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(OllamaStreamChunk.self, from: data) {
                            continuation.yield(StreamChunk(content: chunk.message.content, isComplete: chunk.done))
                            if chunk.done {
                                break
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func listModels() async throws -> [String] {
        let url = URL(string: "\(baseURL)/api/tags")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
        return result.models.map { $0.name }
    }
}

// MARK: - Local LLM Provider (On-device inference)

final class LocalLLMProvider: LLMProvider {
    private var modelLoaded = false
    
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse {
        // Local inference using Core ML or similar
        // This is a placeholder - would integrate with llama.cpp, MLX, or Core ML
        
        let combinedPrompt = prompt.messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        
        // Simulate local inference
        let response = await simulateLocalInference(prompt: combinedPrompt)
        
        return AIResponse(
            content: response,
            toolCalls: nil,
            tokensUsed: response.split(separator: " ").count,
            model: "local-\(config.model)",
            finishReason: "stop"
        )
    }
    
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let combinedPrompt = prompt.messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
                let response = await simulateLocalInference(prompt: combinedPrompt)
                
                // Simulate streaming
                for word in response.split(separator: " ") {
                    continuation.yield(StreamChunk(content: String(word) + " ", isComplete: false))
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                
                continuation.yield(StreamChunk(content: "", isComplete: true))
                continuation.finish()
            }
        }
    }
    
    private func simulateLocalInference(prompt: String) async -> String {
        // Placeholder for actual local inference
        // Would use llama.cpp Swift bindings, MLX, or Core ML
        
        let lowercased = prompt.lowercased()
        
        if lowercased.contains("generate") || lowercased.contains("create") {
            return """
            I can help you generate that. Here's a starter implementation:
            
            ```swift
            struct GeneratedView: View {
                var body: some View {
                    VStack {
                        Text("Generated Content")
                    }
                }
            }
            ```
            
            Would you like me to expand on this?
            """
        } else if lowercased.contains("explain") {
            return """
            Let me explain that concept:
            
            This pattern is commonly used in SwiftUI development to separate concerns and improve testability. The key components are:
            
            1. **Model** - Data structures
            2. **View** - UI presentation
            3. **ViewModel** - Business logic bridge
            
            This approach makes your code more maintainable and easier to test.
            """
        } else if lowercased.contains("fix") || lowercased.contains("error") {
            return """
            I see the issue. Here's how to fix it:
            
            The error is likely caused by a missing return type or incorrect syntax. Try:
            
            ```swift
            // Before (incorrect)
            func example() {
                return value
            }
            
            // After (correct)
            func example() -> String {
                return value
            }
            ```
            
            Make sure all your function signatures include proper return types.
            """
        }
        
        return "I understand your request. How can I help you further with your development task?"
    }
}

// MARK: - AWS Bedrock Provider

final class BedrockProvider: LLMProvider {
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse {
        // AWS Bedrock integration
        // Would use AWS SDK for Swift
        
        guard let apiKey = config.apiKey else {
            throw AIBackendError.missingAPIKey
        }
        
        // Placeholder - would use actual Bedrock API
        let url = URL(string: "https://bedrock-runtime.us-east-1.amazonaws.com/model/\(config.model)/invoke")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // AWS Signature V4 would be required here
        // This is simplified for demonstration
        
        let body: [String: Any] = [
            "prompt": prompt.messages.map { $0.content }.joined(separator: "\n"),
            "max_tokens_to_sample": config.maxTokens,
            "temperature": config.temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // For now, fall back to local
        return try await LocalLLMProvider().complete(prompt: prompt, config: config)
    }
    
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        // Fall back to local for now
        return try await LocalLLMProvider().streamComplete(prompt: prompt, config: config)
    }
}

// MARK: - Ollama Models

struct OllamaRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let options: OllamaOptions?
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct OllamaOptions: Codable {
    let temperature: Double?
    let num_predict: Int?
}

struct OllamaResponse: Codable {
    let model: String
    let message: OllamaMessage
    let done: Bool
    let eval_count: Int?
}

struct OllamaStreamChunk: Codable {
    let model: String
    let message: OllamaMessage
    let done: Bool
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
    let size: Int64?
    let digest: String?
}
