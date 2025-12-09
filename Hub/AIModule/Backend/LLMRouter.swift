//
//  LLMRouter.swift
//  Hub
//
//  Routes requests to different LLM providers (OpenAI, Anthropic, Ollama, Local)
//

import Foundation

// MARK: - LLM Router

actor LLMRouter {
    private var providers: [AIBackendConfig.AIProviderType: LLMProvider] = [:]
    
    init() {
        providers[.openAI] = OpenAIProvider()
        providers[.anthropic] = AnthropicProvider()
        providers[.ollama] = OllamaProvider()
        providers[.local] = LocalLLMProvider()
        providers[.bedrock] = BedrockProvider()
    }
    
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse {
        guard let provider = providers[config.provider] else {
            throw AIBackendError.providerNotFound(config.provider.rawValue)
        }
        return try await provider.complete(prompt: prompt, config: config)
    }
    
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let provider = providers[config.provider] else {
                    continuation.finish(throwing: AIBackendError.providerNotFound(config.provider.rawValue))
                    return
                }
                
                do {
                    let stream = try await provider.streamComplete(prompt: prompt, config: config)
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
}

// MARK: - LLM Provider Protocol

protocol LLMProvider {
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AsyncThrowingStream<StreamChunk, Error>
}

// MARK: - OpenAI Provider

final class OpenAIProvider: LLMProvider {
    private let baseURL = "https://api.openai.com/v1"
    
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse {
        guard let apiKey = config.apiKey else {
            throw AIBackendError.missingAPIKey
        }
        
        let url = URL(string: "\(config.baseURL ?? baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OpenAIChatRequest(
            model: config.model,
            messages: prompt.messages.map { OpenAIMessage(role: $0.role, content: $0.content) },
            temperature: config.temperature,
            max_tokens: config.maxTokens,
            tools: prompt.tools?.map { $0.toOpenAITool() },
            stream: false
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIBackendError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIBackendError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        let result = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        return AIResponse(
            content: result.choices.first?.message.content ?? "",
            toolCalls: result.choices.first?.message.tool_calls?.map { $0.toToolCall() },
            tokensUsed: result.usage?.total_tokens ?? 0,
            model: result.model,
            finishReason: result.choices.first?.finish_reason
        )
    }
    
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        guard let apiKey = config.apiKey else {
            throw AIBackendError.missingAPIKey
        }
        
        let url = URL(string: "\(config.baseURL ?? baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OpenAIChatRequest(
            model: config.model,
            messages: prompt.messages.map { OpenAIMessage(role: $0.role, content: $0.content) },
            temperature: config.temperature,
            max_tokens: config.maxTokens,
            tools: nil,
            stream: true
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIBackendError.invalidResponse)
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: "), line != "data: [DONE]" {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: data),
                               let content = chunk.choices.first?.delta.content {
                                continuation.yield(StreamChunk(content: content, isComplete: false))
                            }
                        }
                    }
                    
                    continuation.yield(StreamChunk(content: "", isComplete: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Anthropic Provider

final class AnthropicProvider: LLMProvider {
    private let baseURL = "https://api.anthropic.com/v1"
    
    func complete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AIResponse {
        guard let apiKey = config.apiKey else {
            throw AIBackendError.missingAPIKey
        }
        
        let url = URL(string: "\(config.baseURL ?? baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemMessage = prompt.messages.first { $0.role == "system" }?.content ?? ""
        let userMessages = prompt.messages.filter { $0.role != "system" }
        
        let body = AnthropicRequest(
            model: config.model.contains("claude") ? config.model : "claude-3-5-sonnet-20241022",
            max_tokens: config.maxTokens,
            system: systemMessage,
            messages: userMessages.map { AnthropicMessage(role: $0.role, content: $0.content) },
            tools: prompt.tools?.map { $0.toAnthropicTool() }
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIBackendError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: errorBody)
        }
        
        let result = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        
        let content = result.content.compactMap { block -> String? in
            if case .text(let text) = block { return text }
            return nil
        }.joined()
        
        let toolCalls = result.content.compactMap { block -> ToolCall? in
            if case .tool_use(let id, let name, let input) = block {
                return ToolCall(id: id, name: name, arguments: input)
            }
            return nil
        }
        
        return AIResponse(
            content: content,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls,
            tokensUsed: result.usage.input_tokens + result.usage.output_tokens,
            model: result.model,
            finishReason: result.stop_reason
        )
    }
    
    func streamComplete(prompt: LLMPrompt, config: AIBackendConfig) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        guard let apiKey = config.apiKey else {
            throw AIBackendError.missingAPIKey
        }
        
        let url = URL(string: "\(config.baseURL ?? baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemMessage = prompt.messages.first { $0.role == "system" }?.content ?? ""
        let userMessages = prompt.messages.filter { $0.role != "system" }
        
        let body = AnthropicRequest(
            model: config.model.contains("claude") ? config.model : "claude-3-5-sonnet-20241022",
            max_tokens: config.maxTokens,
            system: systemMessage,
            messages: userMessages.map { AnthropicMessage(role: $0.role, content: $0.content) },
            tools: nil,
            stream: true
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                               let event = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: data) {
                                if let delta = event.delta?.text {
                                    continuation.yield(StreamChunk(content: delta, isComplete: false))
                                }
                            }
                        }
                    }
                    
                    continuation.yield(StreamChunk(content: "", isComplete: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
