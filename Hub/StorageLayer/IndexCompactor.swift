//
//  IndexCompactor.swift
//  Hub
//
//  Index compaction for optimizing memory usage and search performance
//  Removes redundant entries and optimizes index structure
//

import Foundation

/// Index compactor for optimizing storage indices
actor IndexCompactor {
    
    // MARK: - Compaction Statistics
    
    struct CompactionStats: Sendable {
        let startTime: Date
        let endTime: Date
        let entriesBeforeCompaction: Int
        let entriesAfterCompaction: Int
        let termsBeforeCompaction: Int
        let termsAfterCompaction: Int
        let bytesReclaimed: Int
        
        var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
        
        var compressionRatio: Double {
            guard entriesBeforeCompaction > 0 else { return 0.0 }
            return Double(entriesAfterCompaction) / Double(entriesBeforeCompaction)
        }
    }
    
    // MARK: - Properties
    
    /// Minimum term frequency to keep in index (terms appearing less are removed)
    private let minTermFrequency: Int
    
    /// Maximum terms per entry (longer entries are truncated)
    private let maxTermsPerEntry: Int
    
    /// Stop words to exclude from index
    private let stopWords: Set<String>
    
    /// Last compaction time
    private var lastCompactionTime: Date?
    
    /// Total compactions performed
    private var totalCompactions: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize index compactor
    /// - Parameters:
    ///   - minTermFrequency: Minimum frequency to keep terms (default: 1)
    ///   - maxTermsPerEntry: Maximum terms per entry (default: 100)
    init(
        minTermFrequency: Int = 1,
        maxTermsPerEntry: Int = 100
    ) {
        self.minTermFrequency = max(1, minTermFrequency)
        self.maxTermsPerEntry = max(10, maxTermsPerEntry)
        
        // Common English stop words
        self.stopWords = Set([
            "the", "and", "for", "are", "but", "not", "you", "all",
            "can", "her", "was", "one", "our", "out", "day", "get",
            "has", "him", "his", "how", "its", "may", "new", "now",
            "old", "see", "two", "who", "boy", "did", "car", "let",
            "put", "say", "she", "too", "use"
        ])
    }
    
    // MARK: - Compaction Operations
    
    /// Compact a search index by removing low-frequency terms and stop words
    /// - Parameter searchIndex: The search index to compact
    /// - Returns: Compacted search index and statistics
    func compactSearchIndex(
        _ searchIndex: [String: Set<String>]
    ) -> (compacted: [String: Set<String>], stats: CompactionStats) {
        let startTime = Date()
        let entriesBefore = searchIndex.values.reduce(0) { $0 + $1.count }
        let termsBefore = searchIndex.count
        
        var compacted: [String: Set<String>] = [:]
        
        // Calculate term frequencies
        var termFrequencies: [String: Int] = [:]
        for (term, ids) in searchIndex {
            termFrequencies[term] = ids.count
        }
        
        // Filter terms
        for (term, ids) in searchIndex {
            // Skip stop words
            if stopWords.contains(term.lowercased()) {
                continue
            }
            
            // Skip low-frequency terms
            if let frequency = termFrequencies[term], frequency < minTermFrequency {
                continue
            }
            
            // Skip very short terms (likely noise)
            if term.count < 3 {
                continue
            }
            
            compacted[term] = ids
        }
        
        let entriesAfter = compacted.values.reduce(0) { $0 + $1.count }
        let termsAfter = compacted.count
        
        // Estimate bytes reclaimed (rough approximation)
        let bytesReclaimed = (termsBefore - termsAfter) * 50 + (entriesBefore - entriesAfter) * 36
        
        let stats = CompactionStats(
            startTime: startTime,
            endTime: Date(),
            entriesBeforeCompaction: entriesBefore,
            entriesAfterCompaction: entriesAfter,
            termsBeforeCompaction: termsBefore,
            termsAfterCompaction: termsAfter,
            bytesReclaimed: bytesReclaimed
        )
        
        lastCompactionTime = Date()
        totalCompactions += 1
        
        return (compacted, stats)
    }
    
    /// Compact an entity index by removing empty entries
    /// - Parameter entityIndex: The entity index to compact
    /// - Returns: Compacted entity index
    func compactEntityIndex(
        _ entityIndex: [String: Set<String>]
    ) -> [String: Set<String>] {
        var compacted: [String: Set<String>] = [:]
        
        for (entityType, ids) in entityIndex {
            // Only keep non-empty entries
            if !ids.isEmpty {
                compacted[entityType] = ids
            }
        }
        
        return compacted
    }
    
    /// Compact a tag index by normalizing and deduplicating tags
    /// - Parameter tagIndex: The tag index to compact
    /// - Returns: Compacted tag index
    func compactTagIndex(
        _ tagIndex: [String: Set<String>]
    ) -> [String: Set<String>] {
        var compacted: [String: Set<String>] = [:]
        
        for (tag, ids) in tagIndex {
            // Normalize tag (lowercase, trim whitespace)
            let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Skip empty tags
            if normalizedTag.isEmpty {
                continue
            }
            
            // Merge with existing normalized tag if present
            if var existingIds = compacted[normalizedTag] {
                existingIds.formUnion(ids)
                compacted[normalizedTag] = existingIds
            } else {
                compacted[normalizedTag] = ids
            }
        }
        
        return compacted
    }
    
    /// Perform full compaction on all indices
    /// - Parameters:
    ///   - searchIndex: Search index to compact
    ///   - entityIndex: Entity index to compact
    ///   - tagIndex: Tag index to compact
    /// - Returns: Tuple of compacted indices and statistics
    func compactAll(
        searchIndex: [String: Set<String>],
        entityIndex: [String: Set<String>],
        tagIndex: [String: Set<String>]
    ) -> (
        searchIndex: [String: Set<String>],
        entityIndex: [String: Set<String>],
        tagIndex: [String: Set<String>],
        stats: CompactionStats
    ) {
        let (compactedSearch, stats) = compactSearchIndex(searchIndex)
        let compactedEntity = compactEntityIndex(entityIndex)
        let compactedTag = compactTagIndex(tagIndex)
        
        return (compactedSearch, compactedEntity, compactedTag, stats)
    }
    
    // MARK: - Statistics
    
    /// Get compaction statistics
    /// - Returns: Dictionary with compaction metrics
    func getStatistics() -> [String: Any] {
        return [
            "totalCompactions": totalCompactions,
            "lastCompactionTime": lastCompactionTime?.description ?? "never",
            "minTermFrequency": minTermFrequency,
            "maxTermsPerEntry": maxTermsPerEntry,
            "stopWordsCount": stopWords.count
        ]
    }
    
    /// Check if compaction is recommended
    /// - Parameters:
    ///   - indexSize: Current size of indices
    ///   - timeSinceLastCompaction: Time since last compaction
    /// - Returns: True if compaction is recommended
    func shouldCompact(indexSize: Int, timeSinceLastCompaction: TimeInterval?) -> Bool {
        // Compact if index is large (>10000 terms)
        if indexSize > 10000 {
            return true
        }
        
        // Compact if it's been a while (>1 hour)
        if let timeSince = timeSinceLastCompaction, timeSince > 3600 {
            return true
        }
        
        // Compact if never compacted and index has some size
        if lastCompactionTime == nil && indexSize > 1000 {
            return true
        }
        
        return false
    }
}

