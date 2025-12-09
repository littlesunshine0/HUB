//
//  RAGEngine.swift
//  Hub
//
//  Retrieval-Augmented Generation engine with vector store
//

import Foundation

// MARK: - RAG Engine

actor RAGEngine {
    private var vectorStore: VectorStore
    private let embeddingService: EmbeddingService
    private let chunker: DocumentChunker
    private var indexedDocuments: [String: IndexedDocument] = [:]
    
    init() {
        self.vectorStore = InMemoryVectorStore()
        self.embeddingService = EmbeddingService()
        self.chunker = DocumentChunker()
    }
    
    // MARK: - Document Indexing
    
    func indexDocument(_ document: RAGDocument) async throws {
        // Chunk the document
        let chunks = chunker.chunk(document.content, metadata: document.metadata)
        
        // Generate embeddings
        let texts = chunks.map { $0.text }
        let embeddings = try await embeddingService.embedBatch(texts)
        
        // Store in vector store
        for (chunk, embedding) in zip(chunks, embeddings) {
            let vectorDoc = VectorDocument(
                id: UUID().uuidString,
                documentId: document.id,
                text: chunk.text,
                embedding: embedding,
                metadata: chunk.metadata
            )
            await vectorStore.insert(vectorDoc)
        }
        
        indexedDocuments[document.id] = IndexedDocument(
            id: document.id,
            chunkCount: chunks.count,
            indexedAt: Date()
        )
    }
    
    func indexDocuments(_ documents: [RAGDocument]) async throws {
        for document in documents {
            try await indexDocument(document)
        }
    }
    
    func indexCodebase(at path: String) async throws {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: path)
        
        let codeExtensions = ["swift", "ts", "tsx", "js", "jsx", "py", "go", "rs", "java", "kt"]
        
        while let file = enumerator?.nextObject() as? String {
            let ext = (file as NSString).pathExtension
            guard codeExtensions.contains(ext) else { continue }
            
            let fullPath = (path as NSString).appendingPathComponent(file)
            guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else { continue }
            
            let document = RAGDocument(
                id: fullPath,
                content: content,
                metadata: VectorDocumentMetadata(
                    source: fullPath,
                    type: .code,
                    language: ext,
                    title: file
                )
            )
            
            try await indexDocument(document)
        }
    }
    
    // MARK: - Retrieval
    
    func retrieve(query: String, topK: Int = 5, filter: RetrievalFilter? = nil) async -> [RAGDocument] {
        do {
            let queryEmbedding = try await embeddingService.embed(query)
            let results = await vectorStore.search(queryEmbedding, topK: topK, filter: filter)
            
            return results.map { result in
                RAGDocument(
                    id: result.documentId,
                    content: result.text,
                    metadata: result.metadata,
                    score: result.score
                )
            }
        } catch {
            return []
        }
    }
    
    func retrieveWithReranking(query: String, topK: Int = 5) async -> [RAGDocument] {
        // First pass: retrieve more candidates
        let candidates = await retrieve(query: query, topK: topK * 3)
        
        // Rerank using cross-encoder style scoring
        let reranked = await rerank(query: query, documents: candidates)
        
        return Array(reranked.prefix(topK))
    }
    
    private func rerank(query: String, documents: [RAGDocument]) async -> [RAGDocument] {
        // Simple keyword-based reranking
        // In production, would use a cross-encoder model
        
        let queryTerms = Set(query.lowercased().split(separator: " ").map(String.init))
        
        var scored: [(RAGDocument, Double)] = []
        
        for doc in documents {
            let docTerms = Set(doc.content.lowercased().split(separator: " ").map(String.init))
            let overlap = queryTerms.intersection(docTerms).count
            let score = (doc.score ?? 0) + Double(overlap) * 0.1
            scored.append((doc, score))
        }
        
        return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
    }
    
    // MARK: - Hybrid Search
    
    func hybridSearch(query: String, topK: Int = 5) async -> [RAGDocument] {
        // Combine semantic and keyword search
        let semanticResults = await retrieve(query: query, topK: topK)
        let keywordResults = await keywordSearch(query: query, topK: topK)
        
        // Reciprocal Rank Fusion
        var scores: [String: Double] = [:]
        let k = 60.0 // RRF constant
        
        for (rank, doc) in semanticResults.enumerated() {
            scores[doc.id, default: 0] += 1.0 / (k + Double(rank + 1))
        }
        
        for (rank, doc) in keywordResults.enumerated() {
            scores[doc.id, default: 0] += 1.0 / (k + Double(rank + 1))
        }
        
        // Combine and sort
        let allDocs = Dictionary(grouping: semanticResults + keywordResults) { $0.id }
            .compactMapValues { $0.first }
        
        let sorted = scores.sorted { $0.value > $1.value }
            .prefix(topK)
            .compactMap { allDocs[$0.key] }
        
        return Array(sorted)
    }
    
    private func keywordSearch(query: String, topK: Int) async -> [RAGDocument] {
        let terms = query.lowercased().split(separator: " ").map(String.init)
        return await vectorStore.keywordSearch(terms: terms, topK: topK).map { result in
            RAGDocument(
                id: result.documentId,
                content: result.text,
                metadata: result.metadata,
                score: result.score
            )
        }
    }
    
    // MARK: - Management
    
    func removeDocument(_ id: String) async {
        await vectorStore.remove(documentId: id)
        indexedDocuments.removeValue(forKey: id)
    }
    
    func clear() async {
        await vectorStore.clear()
        indexedDocuments.removeAll()
    }
    
    func stats() async -> RAGStats {
        let storeStats = await vectorStore.stats()
        return RAGStats(
            documentCount: indexedDocuments.count,
            chunkCount: storeStats.vectorCount,
            indexSize: storeStats.memoryUsage
        )
    }
}

// MARK: - Document Chunker

struct DocumentChunker {
    let chunkSize: Int = 512
    let chunkOverlap: Int = 50
    
    func chunk(_ text: String, metadata: VectorDocumentMetadata) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        
        // For code, chunk by functions/classes
        if metadata.type == .code {
            chunks = chunkCode(text, metadata: metadata)
        } else {
            chunks = chunkText(text, metadata: metadata)
        }
        
        return chunks
    }
    
    private func chunkText(_ text: String, metadata: VectorDocumentMetadata) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
        
        var currentChunk = ""
        var chunkIndex = 0
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            if currentChunk.count + trimmed.count > chunkSize {
                if !currentChunk.isEmpty {
                    chunks.append(DocumentChunk(
                        text: currentChunk,
                        metadata: metadata.with(chunkIndex: chunkIndex)
                    ))
                    chunkIndex += 1
                    
                    // Keep overlap
                    let words = currentChunk.split(separator: " ")
                    currentChunk = words.suffix(chunkOverlap / 5).joined(separator: " ")
                }
            }
            
            currentChunk += (currentChunk.isEmpty ? "" : " ") + trimmed
        }
        
        if !currentChunk.isEmpty {
            chunks.append(DocumentChunk(
                text: currentChunk,
                metadata: metadata.with(chunkIndex: chunkIndex)
            ))
        }
        
        return chunks
    }
    
    private func chunkCode(_ code: String, metadata: VectorDocumentMetadata) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        
        // Simple function/class detection
        let patterns = [
            #"(func\s+\w+[^{]*\{[^}]*\})"#,
            #"(class\s+\w+[^{]*\{[^}]*\})"#,
            #"(struct\s+\w+[^{]*\{[^}]*\})"#,
            #"(enum\s+\w+[^{]*\{[^}]*\})"#
        ]
        
        var usedRanges: [Range<String.Index>] = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
                let range = NSRange(code.startIndex..., in: code)
                let matches = regex.matches(in: code, range: range)
                
                for match in matches {
                    if let matchRange = Range(match.range, in: code) {
                        let overlaps = usedRanges.contains { $0.overlaps(matchRange) }
                        if !overlaps {
                            let text = String(code[matchRange])
                            chunks.append(DocumentChunk(
                                text: text,
                                metadata: metadata.with(chunkIndex: chunks.count)
                            ))
                            usedRanges.append(matchRange)
                        }
                    }
                }
            }
        }
        
        // If no functions found, fall back to text chunking
        if chunks.isEmpty {
            return chunkText(code, metadata: metadata)
        }
        
        return chunks
    }
}
