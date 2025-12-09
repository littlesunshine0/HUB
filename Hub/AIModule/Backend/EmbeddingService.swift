//
//  EmbeddingService.swift
//  Hub
//
//  Vector embeddings for semantic search and RAG
//

import Foundation
import NaturalLanguage
import Accelerate

// MARK: - Embedding Service

actor EmbeddingService {
    private var cache: [String: [Float]] = [:]
    private let cacheLimit = 10000
    private var provider: EmbeddingProvider = LocalEmbeddingProvider()
    
    func setProvider(_ type: AIBackendConfig.AIProviderType, apiKey: String? = nil) {
        switch type {
        case .openAI:
            provider = OpenAIEmbeddingProvider(apiKey: apiKey ?? "")
        case .local, .ollama:
            provider = LocalEmbeddingProvider()
        default:
            provider = LocalEmbeddingProvider()
        }
    }
    
    func embed(_ text: String) async throws -> [Float] {
        // Check cache
        if let cached = cache[text] {
            return cached
        }
        
        let embedding = try await provider.embed(text)
        
        // Cache management
        if cache.count >= cacheLimit {
            cache.removeAll()
        }
        cache[text] = embedding
        
        return embedding
    }
    
    func embedBatch(_ texts: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        
        // Check cache first
        var uncached: [(Int, String)] = []
        for (index, text) in texts.enumerated() {
            if let cached = cache[text] {
                results.append(cached)
            } else {
                uncached.append((index, text))
                results.append([])
            }
        }
        
        // Embed uncached
        if !uncached.isEmpty {
            let uncachedTexts = uncached.map { $0.1 }
            let embeddings = try await provider.embedBatch(uncachedTexts)
            
            for (i, (originalIndex, text)) in uncached.enumerated() {
                results[originalIndex] = embeddings[i]
                cache[text] = embeddings[i]
            }
        }
        
        return results
    }
    
    func similarity(_ a: [Float], _ b: [Float]) -> Float {
        cosineSimilarity(a, b)
    }
    
    func findSimilar(query: [Float], candidates: [[Float]], topK: Int) -> [(index: Int, score: Float)] {
        var scores: [(Int, Float)] = []
        
        for (index, candidate) in candidates.enumerated() {
            let score = cosineSimilarity(query, candidate)
            scores.append((index, score))
        }
        
        return scores.sorted { $0.1 > $1.1 }.prefix(topK).map { $0 }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_dotpr(a, 1, a, 1, &normA, vDSP_Length(a.count))
        vDSP_dotpr(b, 1, b, 1, &normB, vDSP_Length(b.count))
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
}

// MARK: - Embedding Provider Protocol

protocol EmbeddingProvider {
    func embed(_ text: String) async throws -> [Float]
    func embedBatch(_ texts: [String]) async throws -> [[Float]]
}

// MARK: - Local Embedding Provider (NLEmbedding)

final class LocalEmbeddingProvider: EmbeddingProvider {
    private let embedding: NLEmbedding?
    private let dimension = 512
    
    init() {
        embedding = NLEmbedding.wordEmbedding(for: .english)
    }
    
    func embed(_ text: String) async throws -> [Float] {
        // Use sentence embedding approach
        let words = text.lowercased().split(separator: " ").map(String.init)
        var vectors: [[Float]] = []
        
        for word in words {
            if let embedding = embedding,
               let vector = embedding.vector(for: word) {
                vectors.append(vector.map { Float($0) })
            }
        }
        
        // Average pooling
        if vectors.isEmpty {
            return Array(repeating: 0, count: dimension)
        }
        
        var result = Array(repeating: Float(0), count: vectors[0].count)
        for vector in vectors {
            for (i, v) in vector.enumerated() {
                result[i] += v
            }
        }
        
        let count = Float(vectors.count)
        return result.map { $0 / count }
    }
    
    func embedBatch(_ texts: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in texts {
            results.append(try await embed(text))
        }
        return results
    }
}

// MARK: - OpenAI Embedding Provider

final class OpenAIEmbeddingProvider: EmbeddingProvider {
    private let apiKey: String
    private let model = "text-embedding-3-small"
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func embed(_ text: String) async throws -> [Float] {
        let embeddings = try await embedBatch([text])
        return embeddings.first ?? []
    }
    
    func embedBatch(_ texts: [String]) async throws -> [[Float]] {
        let url = URL(string: "\(baseURL)/embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OpenAIEmbeddingRequest(
            model: model,
            input: texts
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIBackendError.embeddingFailed
        }
        
        let result = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: data)
        return result.data.sorted { $0.index < $1.index }.map { $0.embedding.map { Float($0) } }
    }
}

// MARK: - OpenAI Embedding Models

struct OpenAIEmbeddingRequest: Codable {
    let model: String
    let input: [String]
}

struct OpenAIEmbeddingResponse: Codable {
    let data: [EmbeddingData]
    let usage: EmbeddingUsage
}

struct EmbeddingData: Codable {
    let index: Int
    let embedding: [Double]
}

struct EmbeddingUsage: Codable {
    let prompt_tokens: Int
    let total_tokens: Int
}
