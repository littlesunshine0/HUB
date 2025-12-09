//
//  VectorStore.swift
//  Hub
//
//  Vector storage with similarity search
//

import Foundation
import Accelerate

// MARK: - Vector Store Protocol

protocol VectorStore {
    func insert(_ document: VectorDocument) async
    func insertBatch(_ documents: [VectorDocument]) async
    func search(_ query: [Float], topK: Int, filter: RetrievalFilter?) async -> [VectorSearchResult]
    func keywordSearch(terms: [String], topK: Int) async -> [VectorSearchResult]
    func remove(documentId: String) async
    func clear() async
    func stats() async -> VectorStoreStats
}

// MARK: - In-Memory Vector Store

actor InMemoryVectorStore: VectorStore {
    private var documents: [String: VectorDocument] = [:]
    private var embeddings: [[Float]] = []
    private var documentIds: [String] = []
    private var invertedIndex: [String: Set<String>] = [:] // term -> document IDs
    
    func insert(_ document: VectorDocument) async {
        documents[document.id] = document
        embeddings.append(document.embedding)
        documentIds.append(document.id)
        
        // Update inverted index
        let terms = tokenize(document.text)
        for term in terms {
            invertedIndex[term, default: []].insert(document.id)
        }
    }
    
    func insertBatch(_ docs: [VectorDocument]) async {
        for doc in docs {
            await insert(doc)
        }
    }
    
    func search(_ query: [Float], topK: Int, filter: RetrievalFilter?) async -> [VectorSearchResult] {
        guard !embeddings.isEmpty else { return [] }
        
        var scores: [(String, Float)] = []
        
        for (index, embedding) in embeddings.enumerated() {
            let docId = documentIds[index]
            guard let doc = documents[docId] else { continue }
            
            // Apply filter
            if let filter = filter {
                if let sourceFilter = filter.source, doc.metadata.source != sourceFilter {
                    continue
                }
                if let typeFilter = filter.type, doc.metadata.type != typeFilter {
                    continue
                }
                if let languageFilter = filter.language, doc.metadata.language != languageFilter {
                    continue
                }
            }
            
            let score = cosineSimilarity(query, embedding)
            scores.append((docId, score))
        }
        
        let topResults = scores.sorted { $0.1 > $1.1 }.prefix(topK)
        
        return topResults.compactMap { (docId, score) -> VectorSearchResult? in
            guard let doc = documents[docId] else { return nil }
            return VectorSearchResult(
                documentId: doc.documentId,
                text: doc.text,
                metadata: doc.metadata,
                score: Double(score)
            )
        }
    }
    
    func keywordSearch(terms: [String], topK: Int) async -> [VectorSearchResult] {
        var docScores: [String: Int] = [:]
        
        for term in terms {
            let normalizedTerm = term.lowercased()
            if let matchingDocs = invertedIndex[normalizedTerm] {
                for docId in matchingDocs {
                    docScores[docId, default: 0] += 1
                }
            }
        }
        
        let sorted = docScores.sorted { $0.value > $1.value }.prefix(topK)
        
        return sorted.compactMap { (docId, score) -> VectorSearchResult? in
            guard let doc = documents[docId] else { return nil }
            return VectorSearchResult(
                documentId: doc.documentId,
                text: doc.text,
                metadata: doc.metadata,
                score: Double(score) / Double(terms.count)
            )
        }
    }
    
    func remove(documentId: String) async {
        let toRemove = documents.filter { $0.value.documentId == documentId }.map { $0.key }
        
        for id in toRemove {
            if let doc = documents[id] {
                // Remove from inverted index
                let terms = tokenize(doc.text)
                for term in terms {
                    invertedIndex[term]?.remove(id)
                }
            }
            
            documents.removeValue(forKey: id)
            if let index = documentIds.firstIndex(of: id) {
                documentIds.remove(at: index)
                embeddings.remove(at: index)
            }
        }
    }
    
    func clear() async {
        documents.removeAll()
        embeddings.removeAll()
        documentIds.removeAll()
        invertedIndex.removeAll()
    }
    
    func stats() async -> VectorStoreStats {
        let memoryUsage = embeddings.reduce(0) { $0 + $1.count * MemoryLayout<Float>.size }
        return VectorStoreStats(
            vectorCount: embeddings.count,
            memoryUsage: memoryUsage,
            dimensions: embeddings.first?.count ?? 0
        )
    }
    
    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
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

// MARK: - Persistent Vector Store

actor PersistentVectorStore: VectorStore {
    private let fileURL: URL
    private var inMemory: InMemoryVectorStore
    
    init(path: String? = nil) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = URL(fileURLWithPath: path ?? documentsPath.appendingPathComponent("vector_store.json").path)
        self.inMemory = InMemoryVectorStore()
        
        Task {
            await load()
        }
    }
    
    func insert(_ document: VectorDocument) async {
        await inMemory.insert(document)
        await save()
    }
    
    func insertBatch(_ documents: [VectorDocument]) async {
        await inMemory.insertBatch(documents)
        await save()
    }
    
    func search(_ query: [Float], topK: Int, filter: RetrievalFilter?) async -> [VectorSearchResult] {
        await inMemory.search(query, topK: topK, filter: filter)
    }
    
    func keywordSearch(terms: [String], topK: Int) async -> [VectorSearchResult] {
        await inMemory.keywordSearch(terms: terms, topK: topK)
    }
    
    func remove(documentId: String) async {
        await inMemory.remove(documentId: documentId)
        await save()
    }
    
    func clear() async {
        await inMemory.clear()
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func stats() async -> VectorStoreStats {
        await inMemory.stats()
    }
    
    private func save() async {
        // Serialize and save to disk
        // Implementation would encode documents to JSON/binary
    }
    
    private func load() async {
        // Load from disk
        // Implementation would decode documents from JSON/binary
    }
}

// MARK: - Models
// Note: VectorDocumentMetadata and VectorDocumentType are defined in AISharedTypes.swift

struct VectorDocument: Codable {
    let id: String
    let documentId: String
    let text: String
    let embedding: [Float]
    let metadata: VectorDocumentMetadata
    
    enum CodingKeys: String, CodingKey {
        case id, documentId, text, embedding, metadata
    }
}

struct VectorSearchResult {
    let documentId: String
    let text: String
    let metadata: VectorDocumentMetadata
    let score: Double
}

struct VectorStoreStats {
    let vectorCount: Int
    let memoryUsage: Int
    let dimensions: Int
}

struct RetrievalFilter {
    var source: String?
    var type: VectorDocumentType?
    var language: String?
    var minScore: Double?
}
