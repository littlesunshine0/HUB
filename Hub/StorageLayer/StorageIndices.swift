//
//  StorageIndices.swift
//  Hub
//
//  Storage indices actor for local-first database architecture
//  Provides thread-safe index management with corruption detection and recovery
//

import Foundation
import Combine
/// Actor providing thread-safe index management for storage operations
/// Implements search, entity, and tag indices with automatic corruption detection
actor StorageIndices {
    
    // MARK: - Properties
    
    /// Search index mapping terms to entry IDs
    private var searchIndex: [String: Set<String>] = [:]
    
    /// Entity index mapping entity types to entry IDs
    private var entityIndex: [String: Set<String>] = [:]
    
    /// Tag index mapping tags to entry IDs
    private var tagIndex: [String: Set<String>] = [:]
    
    /// Reference to all stored entries for validation
    private var allEntryIds: Set<String> = []
    
    // MARK: - Initialization
    
    init() {
        // Initialize with empty indices
    }
    
    // MARK: - Index Update Operations
    
    /// Update indices for a new or modified entry
    /// - Parameters:
    ///   - item: The new or modified item to index
    ///   - oldItem: The previous version of the item (nil if new)
    /// - Throws: LocalStorageError if update fails
    func update<T: Storable>(for item: T, removing oldItem: T?) async throws {
        // Remove old item from indices if it exists
        if let old = oldItem {
            await remove(old)
        }
        
        // Add new item to indices
        await add(item)
    }
    
    /// Add an item to all indices
    /// - Parameter item: The item to add
    private func add<T: Storable>(_ item: T) async {
        // Add to entry ID tracking
        allEntryIds.insert(item.id)
        
        // Add to search index
        let searchTerms = extractSearchTerms(from: item)
        for term in searchTerms {
            searchIndex[term, default: Set()].insert(item.id)
        }
        
        // Add to entity index
        let entityTypes = extractEntityTypes(from: item)
        for entityType in entityTypes {
            entityIndex[entityType, default: Set()].insert(item.id)
        }
        
        // Add to tag index
        let tags = extractTags(from: item)
        for tag in tags {
            tagIndex[tag.lowercased(), default: Set()].insert(item.id)
        }
    }
    
    /// Remove an item from all indices
    /// - Parameter item: The item to remove
    private func remove<T: Storable>(_ item: T) async {
        // Remove from entry ID tracking
        allEntryIds.remove(item.id)
        
        // Remove from search index
        let searchTerms = extractSearchTerms(from: item)
        for term in searchTerms {
            if var ids = searchIndex[term] {
                ids.remove(item.id)
                if ids.isEmpty {
                    searchIndex.removeValue(forKey: term)
                } else {
                    searchIndex[term] = ids
                }
            }
        }
        
        // Remove from entity index
        let entityTypes = extractEntityTypes(from: item)
        for entityType in entityTypes {
            if var ids = entityIndex[entityType] {
                ids.remove(item.id)
                if ids.isEmpty {
                    entityIndex.removeValue(forKey: entityType)
                } else {
                    entityIndex[entityType] = ids
                }
            }
        }
        
        // Remove from tag index
        let tags = extractTags(from: item)
        for tag in tags {
            let lowercasedTag = tag.lowercased()
            if var ids = tagIndex[lowercasedTag] {
                ids.remove(item.id)
                if ids.isEmpty {
                    tagIndex.removeValue(forKey: lowercasedTag)
                } else {
                    tagIndex[lowercasedTag] = ids
                }
            }
        }
    }
    
    // MARK: - Search Operations
    
    /// Search for entries matching a query
    /// - Parameter query: Search query string
    /// - Returns: Set of entry IDs matching the query
    func search(query: String) async -> Set<String> {
        // Check for corruption before searching
        if !isHealthy() {
            print("⚠️ Index corruption detected during search. Rebuilding indices...")
            // Note: Rebuild should be called by the caller with access to all entries
            // We return empty set here to avoid returning corrupted results
            return Set()
        }
        
        let terms = extractTermsFromQuery(query)
        var matchingIds = Set<String>()
        
        for term in terms {
            if let ids = searchIndex[term.lowercased()] {
                matchingIds.formUnion(ids)
            }
        }
        
        return matchingIds
    }
    
    /// Search entries by entity type
    /// - Parameter entityType: The entity type to search for
    /// - Returns: Set of entry IDs with the specified entity type
    func searchByEntity(type entityType: String) async -> Set<String> {
        return entityIndex[entityType] ?? Set()
    }
    
    /// Search entries by tag
    /// - Parameter tag: The tag to search for
    /// - Returns: Set of entry IDs with the specified tag
    func searchByTag(_ tag: String) async -> Set<String> {
        return tagIndex[tag.lowercased()] ?? Set()
    }
    
    /// Get all unique entity types in the index
    /// - Returns: Array of entity type strings
    func getAllEntityTypes() async -> [String] {
        return Array(entityIndex.keys).sorted()
    }
    
    /// Get all unique tags in the index
    /// - Returns: Array of tag strings
    func getAllTags() async -> [String] {
        return Array(tagIndex.keys).sorted()
    }
    
    // MARK: - Health Checking
    
    /// Check if indices are healthy and consistent
    /// - Returns: True if all indexed IDs exist in the entry set
    func isHealthy() -> Bool {
        // Verify all indexed IDs exist in allEntryIds
        for ids in searchIndex.values {
            for id in ids {
                if !allEntryIds.contains(id) {
                    return false
                }
            }
        }
        
        for ids in entityIndex.values {
            for id in ids {
                if !allEntryIds.contains(id) {
                    return false
                }
            }
        }
        
        for ids in tagIndex.values {
            for id in ids {
                if !allEntryIds.contains(id) {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Detect corrupted entries in indices
    /// - Returns: Set of entry IDs that are in indices but not in storage
    func detectCorruption() async -> Set<String> {
        var corruptedIds = Set<String>()
        
        // Check search index
        for ids in searchIndex.values {
            for id in ids {
                if !allEntryIds.contains(id) {
                    corruptedIds.insert(id)
                }
            }
        }
        
        // Check entity index
        for ids in entityIndex.values {
            for id in ids {
                if !allEntryIds.contains(id) {
                    corruptedIds.insert(id)
                }
            }
        }
        
        // Check tag index
        for ids in tagIndex.values {
            for id in ids {
                if !allEntryIds.contains(id) {
                    corruptedIds.insert(id)
                }
            }
        }
        
        return corruptedIds
    }
    
    /// Clean up corrupted index entries
    /// - Parameter corruptedIds: Set of IDs to remove from indices
    func cleanupCorruption(_ corruptedIds: Set<String>) async {
        // Remove from search index
        for (term, var ids) in searchIndex {
            let originalCount = ids.count
            ids.subtract(corruptedIds)
            if ids.isEmpty {
                searchIndex.removeValue(forKey: term)
            } else if ids.count != originalCount {
                searchIndex[term] = ids
            }
        }
        
        // Remove from entity index
        for (entityType, var ids) in entityIndex {
            let originalCount = ids.count
            ids.subtract(corruptedIds)
            if ids.isEmpty {
                entityIndex.removeValue(forKey: entityType)
            } else if ids.count != originalCount {
                entityIndex[entityType] = ids
            }
        }
        
        // Remove from tag index
        for (tag, var ids) in tagIndex {
            let originalCount = ids.count
            ids.subtract(corruptedIds)
            if ids.isEmpty {
                tagIndex.removeValue(forKey: tag)
            } else if ids.count != originalCount {
                tagIndex[tag] = ids
            }
        }
    }
    
    // MARK: - Index Rebuild
    
    /// Rebuild all indices from a collection of entries
    /// - Parameter entries: All entries to index
    func rebuild<T: Storable>(from entries: [T]) async {
        // Clear existing indices
        searchIndex.removeAll()
        entityIndex.removeAll()
        tagIndex.removeAll()
        allEntryIds.removeAll()
        
        // Rebuild from all entries
        for entry in entries {
            await add(entry)
        }
    }
    
    /// Clear all indices
    func clear() async {
        searchIndex.removeAll()
        entityIndex.removeAll()
        tagIndex.removeAll()
        allEntryIds.removeAll()
    }
    
    // MARK: - Statistics
    
    /// Get index statistics
    /// - Returns: Dictionary with index metrics
    func statistics() async -> [String: Any] {
        var searchIndexedEntries = Set<String>()
        for ids in searchIndex.values {
            searchIndexedEntries.formUnion(ids)
        }
        
        var entityIndexedEntries = Set<String>()
        for ids in entityIndex.values {
            entityIndexedEntries.formUnion(ids)
        }
        
        var tagIndexedEntries = Set<String>()
        for ids in tagIndex.values {
            tagIndexedEntries.formUnion(ids)
        }
        
        let totalSearchTerms = searchIndex.values.reduce(0) { $0 + $1.count }
        let avgTermsPerEntry = searchIndexedEntries.isEmpty ? 0.0 : Double(totalSearchTerms) / Double(searchIndexedEntries.count)
        
        return [
            "totalEntries": allEntryIds.count,
            "searchIndexTermCount": searchIndex.count,
            "searchIndexedEntryCount": searchIndexedEntries.count,
            "entityTypeCount": entityIndex.count,
            "entityIndexedEntryCount": entityIndexedEntries.count,
            "tagCount": tagIndex.count,
            "tagIndexedEntryCount": tagIndexedEntries.count,
            "averageTermsPerEntry": avgTermsPerEntry,
            "isHealthy": isHealthy()
        ]
    }
    
    // MARK: - Private Helpers
    
    /// Extract search terms from a Storable item
    /// - Parameter item: The item to extract terms from
    /// - Returns: Set of search terms
    private func extractSearchTerms<T: Storable>(from item: T) -> Set<String> {
        // For generic Storable, we can only use the ID
        // Subclasses can override this for more sophisticated extraction
        let idTerms = extractTermsFromQuery(item.id)
        return idTerms
    }
    
    /// Extract entity types from a Storable item
    /// - Parameter item: The item to extract entity types from
    /// - Returns: Set of entity types
    private func extractEntityTypes<T: Storable>(from item: T) -> Set<String> {
        // Default implementation returns empty set
        // Specific implementations can override for their types
        return Set()
    }
    
    /// Extract tags from a Storable item
    /// - Parameter item: The item to extract tags from
    /// - Returns: Set of tags
    private func extractTags<T: Storable>(from item: T) -> Set<String> {
        // Default implementation returns empty set
        // Specific implementations can override for their types
        return Set()
    }
    
    /// Extract search terms from a query string
    /// - Parameter query: The query string
    /// - Returns: Set of search terms
    private func extractTermsFromQuery(_ query: String) -> Set<String> {
        let words = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 } // Ignore very short words
        return Set(words)
    }
}

// MARK: - OfflineKnowledgeEntry Extension

extension StorageIndices {
    
    /// Specialized extraction for OfflineKnowledgeEntry
    private func extractSearchTerms(from entry: OfflineKnowledgeEntry) -> Set<String> {
        var terms = extractTermsFromQuery(entry.originalSubmission)
        
        if let content = entry.mappedData.content {
            terms.formUnion(extractTermsFromQuery(content))
        }
        
        return terms
    }
    
    /// Specialized entity extraction for OfflineKnowledgeEntry
    private func extractEntityTypes(from entry: OfflineKnowledgeEntry) -> Set<String> {
        guard let entities = entry.mappedData.extractedEntities else {
            return Set()
        }
        
        return Set(entities.map { $0.type })
    }
    
    /// Specialized tag extraction for OfflineKnowledgeEntry
    private func extractTags(from entry: OfflineKnowledgeEntry) -> Set<String> {
        return Set(entry.tags)
    }
}
