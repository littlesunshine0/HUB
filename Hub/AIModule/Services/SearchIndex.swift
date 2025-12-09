//
//  SearchIndex.swift
//  Hub
//
//  Created for Offline Assistant Module - Task 8
//  Extended search index with assistant-specific features
//  Builds on OptimizedSearchIndex from HubModuleUpdate_2
//

import Foundation

// MARK: - Search Result

/// Represents a search result with relevance scoring for the assistant module
/// Internal to avoid conflicts with KnowledgeStorageService.SearchResult
struct AssistantSearchResult: Identifiable, Equatable {
    let id: String
    let entry: OfflineKnowledgeEntry
    let score: Double
    let matchedTerms: Set<String>
    let matchedEntities: [Entity]
    
    init(
        id: String,
        entry: OfflineKnowledgeEntry,
        score: Double,
        matchedTerms: Set<String> = [],
        matchedEntities: [Entity] = []
    ) {
        self.id = id
        self.entry = entry
        self.score = score
        self.matchedTerms = matchedTerms
        self.matchedEntities = matchedEntities
    }
}

// MARK: - Search Index

/// High-performance search index for the Offline Assistant Module
/// Extends OptimizedSearchIndex with entity-based search and advanced filtering
actor SearchIndex {
    
    // MARK: - Properties
    
    /// Core optimized search index for term-based search
    private let optimizedIndex: OptimizedSearchIndex
    
    /// Entity index: entity type -> entity value -> set of entry IDs
    private var entityIndex: [String: [String: Set<String>]] = [:]
    
    /// Domain index: domain ID -> set of entry IDs
    private var domainIndex: [String: Set<String>] = [:]
    
    /// Date index: sorted array of (timestamp, entry ID) for range queries
    private var dateIndex: [(date: Date, id: String)] = []
    
    /// Entry cache for quick access
    private var entryCache: [String: OfflineKnowledgeEntry] = [:]
    
    /// LRU cache for frequently accessed entries
    private var lruCache: LRUCache<String, OfflineKnowledgeEntry>
    
    /// Statistics
    private var totalIndexedEntries: Int = 0
    
    // MARK: - Initialization
    
    init(cacheSize: Int = 100) {
        self.optimizedIndex = OptimizedSearchIndex()
        self.lruCache = LRUCache(capacity: cacheSize)
    }
    
    // MARK: - Indexing Methods
    
    /// Index a knowledge entry
    /// - Parameter entry: The entry to index
    func indexEntry(_ entry: OfflineKnowledgeEntry) async {
        // Extract terms for full-text search
        let terms = extractTerms(from: entry)
        
        // Add to optimized index
        await optimizedIndex.addEntry(
            id: entry.id,
            terms: terms,
            timestamp: entry.timestamp,
            domainId: entry.domainId
        )
        
        // Index entities
        if let entities = entry.mappedData.extractedEntities {
            for entity in entities {
                entityIndex[entity.type, default: [:]][entity.value, default: []].insert(entry.id)
            }
        }
        
        // Index by domain
        domainIndex[entry.domainId, default: []].insert(entry.id)
        
        // Index by date
        dateIndex.append((date: entry.timestamp, id: entry.id))
        dateIndex.sort { $0.date < $1.date }
        
        // Cache entry
        entryCache[entry.id] = entry
        lruCache.set(entry.id, value: entry)
        
        totalIndexedEntries += 1
    }
    
    /// Remove an entry from the index
    /// - Parameter entry: The entry to remove
    func removeEntry(_ entry: OfflineKnowledgeEntry) async {
        let terms = extractTerms(from: entry)
        
        // Remove from optimized index
        await optimizedIndex.removeEntry(id: entry.id, terms: terms)
        
        // Remove from entity index
        if let entities = entry.mappedData.extractedEntities {
            for entity in entities {
                if var valueMap = entityIndex[entity.type] {
                    valueMap[entity.value]?.remove(entry.id)
                    if valueMap[entity.value]?.isEmpty == true {
                        valueMap.removeValue(forKey: entity.value)
                    }
                    entityIndex[entity.type] = valueMap
                }
            }
        }
        
        // Remove from domain index
        domainIndex[entry.domainId]?.remove(entry.id)
        
        // Remove from date index
        dateIndex.removeAll { $0.id == entry.id }
        
        // Remove from caches
        entryCache.removeValue(forKey: entry.id)
        lruCache.remove(entry.id)
        
        totalIndexedEntries -= 1
    }
    
    /// Clear the entire index
    func clear() async {
        await optimizedIndex.clear()
        entityIndex.removeAll()
        domainIndex.removeAll()
        dateIndex.removeAll()
        entryCache.removeAll()
        lruCache.clear()
        totalIndexedEntries = 0
    }
    
    /// Rebuild index from entries
    /// - Parameter entries: Array of entries to index
    func rebuildIndex(from entries: [OfflineKnowledgeEntry]) async {
        await clear()
        
        for entry in entries {
            await indexEntry(entry)
        }
    }
}

// Note: LRUCache is defined in HubModuleUpdate_2/Data/Services/CacheManager.swift
// We use that implementation to avoid duplication

// MARK: - Term Extraction

extension SearchIndex {
    
    /// Extract searchable terms from a knowledge entry
    /// - Parameter entry: The entry to extract terms from
    /// - Returns: Set of normalized search terms
    private func extractTerms(from entry: OfflineKnowledgeEntry) -> Set<String> {
        var terms = Set<String>()
        
        // Extract from original submission
        terms.formUnion(tokenize(entry.originalSubmission))
        
        // Extract from content
        if let content = entry.mappedData.content {
            terms.formUnion(tokenize(content))
        }
        
        // Extract from entities
        if let entities = entry.mappedData.extractedEntities {
            for entity in entities {
                terms.formUnion(tokenize(entity.value))
                
                // Add entity type as a term for type-based search
                terms.insert("entity:\(entity.type)")
            }
        }
        
        // Extract from metadata
        if let metadata = entry.metadata {
            for (key, value) in metadata {
                terms.formUnion(tokenize(value))
                terms.insert("meta:\(key)")
            }
        }
        
        // Add domain as a term
        terms.insert("domain:\(entry.domainId)")
        
        // Add status as a term
        terms.insert("status:\(entry.status.rawValue)")
        
        // Add type as a term
        terms.insert("type:\(entry.mappedData.type.rawValue)")
        
        return terms
    }
    
    /// Tokenize text into normalized search terms
    /// - Parameter text: The text to tokenize
    /// - Returns: Set of normalized tokens
    private func tokenize(_ text: String) -> Set<String> {
        var tokens = Set<String>()
        
        // Convert to lowercase
        let lowercased = text.lowercased()
        
        // Split on whitespace and punctuation
        let components = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            
            // Skip very short tokens and common stop words
            if trimmed.count >= 2 && !isStopWord(trimmed) {
                tokens.insert(trimmed)
            }
        }
        
        return tokens
    }
    
    /// Check if a word is a common stop word
    /// - Parameter word: The word to check
    /// - Returns: True if the word is a stop word
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "be",
            "been", "being", "have", "has", "had", "do", "does", "did", "will",
            "would", "should", "could", "may", "might", "must", "can", "this",
            "that", "these", "those", "it", "its", "they", "them", "their"
        ]
        
        return stopWords.contains(word)
    }
}

// MARK: - Batch Indexing

extension SearchIndex {
    
    /// Index multiple entries in batch for better performance
    /// - Parameters:
    ///   - entries: Array of entries to index
    ///   - progressHandler: Optional callback for progress updates
    func indexBatch(
        _ entries: [OfflineKnowledgeEntry],
        progressHandler: ((Double) -> Void)? = nil
    ) async {
        let total = entries.count
        
        for (index, entry) in entries.enumerated() {
            await indexEntry(entry)
            
            // Report progress every 100 entries
            if index % 100 == 0 {
                let progress = Double(index) / Double(total)
                progressHandler?(progress)
            }
        }
        
        progressHandler?(1.0)
    }
    
    /// Update an existing entry in the index
    /// - Parameters:
    ///   - oldEntry: The old entry to remove
    ///   - newEntry: The new entry to add
    func updateEntry(old oldEntry: OfflineKnowledgeEntry, new newEntry: OfflineKnowledgeEntry) async {
        await removeEntry(oldEntry)
        await indexEntry(newEntry)
    }
}

// MARK: - Statistics

extension SearchIndex {
    
    /// Get index statistics
    /// - Returns: Dictionary of statistics
    func statistics() async -> [String: Any] {
        let optimizedStats = await optimizedIndex.statistics()
        
        return [
            "totalEntries": totalIndexedEntries,
            "termCount": optimizedStats.terms,
            "avgTermsPerEntry": optimizedStats.avgTermsPerEntry,
            "entityTypeCount": entityIndex.count,
            "domainCount": domainIndex.count,
            "cacheSize": entryCache.count,
            "dateIndexSize": dateIndex.count
        ]
    }
    
    /// Check if the index is healthy
    /// - Returns: True if all indices are consistent
    func isHealthy() async -> Bool {
        // Check optimized index health
        let optimizedHealthy = await optimizedIndex.isHealthy()
        
        // Check consistency between indices
        let entityEntries = Set(entityIndex.values.flatMap { $0.values.flatMap { $0 } })
        let domainEntries = Set(domainIndex.values.flatMap { $0 })
        let dateEntries = Set(dateIndex.map { $0.id })
        let cachedEntries = Set(entryCache.keys)
        
        // All indices should have the same entries
        let allMatch = entityEntries.isSubset(of: cachedEntries) &&
                       domainEntries.isSubset(of: cachedEntries) &&
                       dateEntries == cachedEntries
        
        return optimizedHealthy && allMatch
    }
    
    /// Get the number of indexed entries
    /// - Returns: Total number of entries in the index
    func count() -> Int {
        return totalIndexedEntries
    }
}


// MARK: - Search Methods

extension SearchIndex {
    
    /// Search for entries matching the query with optional filters
    /// - Parameters:
    ///   - query: The search query string
    ///   - filters: Optional array of search filters
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of search results sorted by relevance
    func search(
        query: String,
        filters: [SearchFilter] = [],
        limit: Int = 100
    ) async -> [AssistantSearchResult] {
        // Extract query terms
        let queryTerms = tokenize(query)
        
        guard !queryTerms.isEmpty else {
            return []
        }
        
        // Get initial results from optimized index
        let scoredResults = await optimizedIndex.search(queryTerms: queryTerms, limit: limit * 2)
        
        // Convert to AssistantSearchResult objects
        var results: [AssistantSearchResult] = []
        
        for (id, score) in scoredResults {
            // Get entry from cache
            guard let entry = getEntry(id: id) else { continue }
            
            // Apply filters
            if !matchesFilters(entry: entry, filters: filters) {
                continue
            }
            
            // Find matched terms and entities
            let matchedTerms = findMatchedTerms(entry: entry, queryTerms: queryTerms)
            let matchedEntities = findMatchedEntities(entry: entry, queryTerms: queryTerms)
            
            // Boost score based on entity matches
            var adjustedScore = score
            if !matchedEntities.isEmpty {
                adjustedScore *= 1.5 // 50% boost for entity matches
            }
            
            let res: AssistantSearchResult = await MainActor.run {
                AssistantSearchResult(
                    id: id,
                    entry: entry,
                    score: adjustedScore,
                    matchedTerms: matchedTerms,
                    matchedEntities: matchedEntities
                )
            }
            results.append(res)
        }
        
        // Sort by adjusted score and limit
        results.sort { $0.score > $1.score }
        return Array(results.prefix(limit))
    }
    
    /// Fast prefix search for autocomplete
    /// - Parameters:
    ///   - prefix: The prefix to search for
    ///   - limit: Maximum number of suggestions
    /// - Returns: Array of matching terms
    func prefixSearch(prefix: String, limit: Int = 20) async -> [String] {
        return await optimizedIndex.prefixSearch(prefix: prefix, limit: limit)
    }
    
    /// Get entries by domain
    /// - Parameter domainId: The domain identifier
    /// - Returns: Array of entries in the domain
    func entriesByDomain(_ domainId: String) -> [OfflineKnowledgeEntry] {
        guard let entryIds = domainIndex[domainId] else {
            return []
        }
        
        return entryIds.compactMap { getEntry(id: $0) }
    }
    
    /// Get entries within a date range
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of entries within the date range
    func entriesInDateRange(from: Date, to: Date) -> [OfflineKnowledgeEntry] {
        // Binary search for start index
        let startIndex = dateIndex.firstIndex { $0.date >= from } ?? dateIndex.endIndex
        
        // Collect entries until end date
        var results: [OfflineKnowledgeEntry] = []
        
        for i in startIndex..<dateIndex.count {
            let item = dateIndex[i]
            
            if item.date > to {
                break
            }
            
            if let entry = getEntry(id: item.id) {
                results.append(entry)
            }
        }
        
        return results
    }
    
    /// Get an entry by ID (with caching)
    /// - Parameter id: The entry ID
    /// - Returns: The entry if found
    private func getEntry(id: String) -> OfflineKnowledgeEntry? {
        // Check LRU cache first
        if let cached = lruCache.get(id) {
            return cached
        }
        
        // Check main cache
        if let entry = entryCache[id] {
            lruCache.set(id, value: entry)
            return entry
        }
        
        return nil
    }
}

// MARK: - Filter Matching

extension SearchIndex {
    
    /// Check if an entry matches all filters
    /// - Parameters:
    ///   - entry: The entry to check
    ///   - filters: Array of filters to apply
    /// - Returns: True if the entry matches all filters
    private func matchesFilters(entry: OfflineKnowledgeEntry, filters: [SearchFilter]) -> Bool {
        for filter in filters {
            if !matchesFilter(entry: entry, filter: filter) {
                return false
            }
        }
        return true
    }
    
    /// Check if an entry matches a single filter
    /// - Parameters:
    ///   - entry: The entry to check
    ///   - filter: The filter to apply
    /// - Returns: True if the entry matches the filter
    private func matchesFilter(entry: OfflineKnowledgeEntry, filter: SearchFilter) -> Bool {
        switch filter {
        case .domain(let domainId):
            return entry.domainId == domainId
            
        case .contentType(let type):
            return entry.mappedData.type.rawValue == type
            
        case .dateRange(let from, let to):
            return entry.timestamp >= from && entry.timestamp <= to
            
        case .entityType(let entityType):
            guard let entities = entry.mappedData.extractedEntities else {
                return false
            }
            return entities.contains { $0.type == entityType }
        }
    }
    
    /// Find terms that matched in the entry
    /// - Parameters:
    ///   - entry: The entry to check
    ///   - queryTerms: The query terms
    /// - Returns: Set of matched terms
    private func findMatchedTerms(entry: OfflineKnowledgeEntry, queryTerms: Set<String>) -> Set<String> {
        let entryTerms = extractTerms(from: entry)
        return queryTerms.intersection(entryTerms)
    }
    
    /// Find entities that matched in the entry
    /// - Parameters:
    ///   - entry: The entry to check
    ///   - queryTerms: The query terms
    /// - Returns: Array of matched entities
    private func findMatchedEntities(entry: OfflineKnowledgeEntry, queryTerms: Set<String>) -> [Entity] {
        guard let entities = entry.mappedData.extractedEntities else {
            return []
        }
        
        var matched: [Entity] = []
        
        for entity in entities {
            let entityTerms = tokenize(entity.value)
            if !queryTerms.intersection(entityTerms).isEmpty {
                matched.append(entity)
            }
        }
        
        return matched
    }
}


// MARK: - Entity-Based Search

extension SearchIndex {
    
    /// Search for entries by entity type and value
    /// - Parameters:
    ///   - entityType: The type of entity to search for
    ///   - value: The entity value to match
    /// - Returns: Array of entries containing the specified entity
    func searchByEntity(type entityType: String, value: String) -> [OfflineKnowledgeEntry] {
        guard let valueMap = entityIndex[entityType],
              let entryIds = valueMap[value] else {
            return []
        }
        
        return entryIds.compactMap { getEntry(id: $0) }
    }
    
    /// Search for entries by entity type (any value)
    /// - Parameter entityType: The type of entity to search for
    /// - Returns: Array of entries containing any entity of the specified type
    func searchByEntityType(_ entityType: String) -> [OfflineKnowledgeEntry] {
        guard let valueMap = entityIndex[entityType] else {
            return []
        }
        
        let allIds = Set(valueMap.values.flatMap { $0 })
        return allIds.compactMap { getEntry(id: $0) }
    }
    
    /// Get all entity values for a given type
    /// - Parameter entityType: The entity type
    /// - Returns: Array of unique entity values
    func entityValues(forType entityType: String) -> [String] {
        guard let valueMap = entityIndex[entityType] else {
            return []
        }
        
        return Array(valueMap.keys).sorted()
    }
    
    /// Get all entity types in the index
    /// - Returns: Array of entity type names
    func allEntityTypes() -> [String] {
        return Array(entityIndex.keys).sorted()
    }
    
    /// Search for code snippets by language
    /// - Parameter language: The programming language
    /// - Returns: Array of entries containing code in the specified language
    func searchCodeByLanguage(_ language: String) -> [OfflineKnowledgeEntry] {
        let codeEntries = searchByEntityType("codeSnippet")
        
        return codeEntries.filter { entry in
            guard let entities = entry.mappedData.extractedEntities else {
                return false
            }
            
            return entities.contains { entity in
                entity.type == "codeSnippet" &&
                entity.metadata?["language"] == language
            }
        }
    }
    
    /// Search for entries containing specific Swift symbols
    /// - Parameters:
    ///   - symbolType: The type of symbol (function, class, struct, enum, variable)
    ///   - name: Optional name to match
    /// - Returns: Array of entries containing the specified symbols
    func searchSwiftSymbols(type symbolType: String, name: String? = nil) -> [OfflineKnowledgeEntry] {
        if let name = name {
            return searchByEntity(type: symbolType, value: name)
        } else {
            return searchByEntityType(symbolType)
        }
    }
    
    /// Search for entries containing links to a specific domain
    /// - Parameter domain: The domain to search for (e.g., "github.com")
    /// - Returns: Array of entries containing links to the domain
    func searchByLinkDomain(_ domain: String) -> [OfflineKnowledgeEntry] {
        let linkEntries = searchByEntityType("link")
        
        return linkEntries.filter { entry in
            guard let entities = entry.mappedData.extractedEntities else {
                return false
            }
            
            return entities.contains { entity in
                entity.type == "link" &&
                entity.value.contains(domain)
            }
        }
    }
    
    /// Search for entries by tag
    /// - Parameter tag: The tag to search for
    /// - Returns: Array of entries with the specified tag
    func searchByTag(_ tag: String) -> [OfflineKnowledgeEntry] {
        return searchByEntity(type: "tag", value: tag)
    }
    
    /// Get all tags in the index
    /// - Returns: Array of unique tags sorted alphabetically
    func allTags() -> [String] {
        return entityValues(forType: "tag")
    }
    
    /// Advanced entity search with multiple criteria
    /// - Parameters:
    ///   - entityTypes: Array of entity types to match (OR logic)
    ///   - values: Optional array of values to match
    ///   - limit: Maximum number of results
    /// - Returns: Array of search results
    func advancedEntitySearch(
        entityTypes: [String],
        values: [String]? = nil,
        limit: Int = 100
    ) async -> [AssistantSearchResult] {
        var matchedIds = Set<String>()
        var entityMatches: [String: [Entity]] = [:]
        
        // Collect entries matching any of the entity types
        for entityType in entityTypes {
            if let values = values {
                // Match specific values
                for value in values {
                    if let valueMap = entityIndex[entityType],
                       let ids = valueMap[value] {
                        for id in ids {
                            matchedIds.insert(id)
                            
                            // Track which entities matched
                            if let entry = getEntry(id: id),
                               let entities = entry.mappedData.extractedEntities {
                                let matched = entities.filter {
                                    $0.type == entityType && $0.value == value
                                }
                                entityMatches[id, default: []].append(contentsOf: matched)
                            }
                        }
                    }
                }
            } else {
                // Match any value for this type
                if let valueMap = entityIndex[entityType] {
                    for (value, ids) in valueMap {
                        for id in ids {
                            matchedIds.insert(id)
                            
                            // Track which entities matched
                            if let entry = getEntry(id: id),
                               let entities = entry.mappedData.extractedEntities {
                                let matched = entities.filter {
                                    $0.type == entityType && $0.value == value
                                }
                                entityMatches[id, default: []].append(contentsOf: matched)
                            }
                        }
                    }
                }
            }
        }
        
        // Convert to AssistantSearchResult objects with scoring
        var results: [AssistantSearchResult] = []
        
        for id in matchedIds {
            guard let entry = getEntry(id: id) else { continue }
            
            let matchedEntities = entityMatches[id] ?? []
            
            // Score based on number of entity matches
            let score = Double(matchedEntities.count)
            
            let res = AssistantSearchResult(
                id: id,
                entry: entry,
                score: score,
                matchedTerms: [],
                matchedEntities: matchedEntities
            )
            results.append(res)
        }
        
        // Sort by score and limit
        results.sort { $0.score > $1.score }
        return Array(results.prefix(limit))
    }
}

// MARK: - Helper Extensions
// Note: JSONValue.getString() extension is defined in HubModuleUpdate_2/Data/Models/JSONValue.swift


