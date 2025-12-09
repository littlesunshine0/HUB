//
//  DeduplicationService.swift
//  Hub
//
//  Created for Offline Assistant Module - Task 5
//  Service for identifying and merging duplicate knowledge entries
//

import Foundation
import CommonCrypto

// MARK: - Deduplication Errors

/// Errors that can occur during deduplication operations
enum DeduplicationError: Error, LocalizedError {
    case hashCalculationFailed(String)
    case mergeFailed(String)
    case invalidEntry(String)
    
    var errorDescription: String? {
        switch self {
        case .hashCalculationFailed(let reason):
            return "Failed to calculate content hash: \(reason)"
        case .mergeFailed(let reason):
            return "Failed to merge entries: \(reason)"
        case .invalidEntry(let reason):
            return "Invalid entry: \(reason)"
        }
    }
}

// MARK: - Duplicate Group

/// Represents a group of duplicate entries
struct DuplicateGroup {
    /// The canonical (kept) entry
    let canonical: OfflineKnowledgeEntry
    
    /// Duplicate entries to be merged or removed
    let duplicates: [OfflineKnowledgeEntry]
    
    /// Content hash shared by all entries in this group
    let contentHash: String
    
    /// Total number of entries in the group
    var totalCount: Int {
        return 1 + duplicates.count
    }
}

// MARK: - Deduplication Statistics

/// Statistics about a deduplication operation
struct DeduplicationStatistics {
    /// Total number of entries processed
    let totalProcessed: Int
    
    /// Number of duplicate groups found
    let duplicateGroupsFound: Int
    
    /// Total number of duplicate entries found
    let totalDuplicates: Int
    
    /// Number of entries merged
    let entriesMerged: Int
    
    /// Number of entries removed
    let entriesRemoved: Int
    
    /// Estimated space saved (in bytes)
    let estimatedSpaceSaved: Int64
    
    /// Processing time in seconds
    let processingTime: TimeInterval
}

// MARK: - Deduplication Service

/// Service for identifying and merging duplicate knowledge entries
/// Provides content hash calculation, duplicate detection, and intelligent merging
class DeduplicationService {
    
    // MARK: - Properties
    
    /// Cache of content hashes for performance
    private var hashCache: [String: String] = [:]
    
    /// Lock for thread-safe hash cache access
    private let cacheLock = NSLock()
    
    // MARK: - Initialization
    
    init() {
        // Initialize service
    }
    
    // MARK: - Content Hash Calculation
    
    /// Calculate SHA-256 content hash for an entry
    /// Uses a canonical representation of the entry's content for consistent hashing
    /// - Parameter entry: The entry to hash
    /// - Returns: SHA-256 hash string
    func calculateContentHash(_ entry: OfflineKnowledgeEntry) -> String {
        // Check cache first
        cacheLock.lock()
        if let cachedHash = hashCache[entry.id] {
            cacheLock.unlock()
            return cachedHash
        }
        cacheLock.unlock()
        
        // Create canonical content representation for hashing
        // Include: domainId, originalSubmission, content, and type
        let canonicalContent = [
            entry.domainId,
            entry.originalSubmission,
            entry.mappedData.content ?? "",
            entry.mappedData.type.rawValue
        ].joined(separator: "|")
        
        guard let data = canonicalContent.data(using: .utf8) else {
            return ""
        }
        
        // Calculate SHA-256 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        
        // Cache the result
        cacheLock.lock()
        hashCache[entry.id] = hashString
        cacheLock.unlock()
        
        return hashString
    }
    
    /// Calculate content hashes for multiple entries in batch
    /// - Parameter entries: Array of entries to hash
    /// - Returns: Dictionary mapping entry ID to content hash
    func calculateContentHashes(_ entries: [OfflineKnowledgeEntry]) -> [String: String] {
        var hashes: [String: String] = [:]
        
        for entry in entries {
            let hash = calculateContentHash(entry)
            if !hash.isEmpty {
                hashes[entry.id] = hash
            }
        }
        
        return hashes
    }
    
    // MARK: - Duplicate Detection
    
    /// Find duplicate entries by content hash
    /// - Parameter entries: Array of entries to check
    /// - Returns: Array of duplicate groups
    func findDuplicatesByContentHash(in entries: [OfflineKnowledgeEntry]) -> [DuplicateGroup] {
        // Build hash index
        var hashToEntries: [String: [OfflineKnowledgeEntry]] = [:]
        
        for entry in entries {
            let hash = calculateContentHash(entry)
            if !hash.isEmpty {
                hashToEntries[hash, default: []].append(entry)
            }
        }
        
        // Find groups with duplicates
        var duplicateGroups: [DuplicateGroup] = []
        
        for (hash, groupEntries) in hashToEntries where groupEntries.count > 1 {
            // Sort by timestamp to identify canonical entry (oldest)
            let sortedEntries = groupEntries.sorted { $0.timestamp < $1.timestamp }
            
            guard let canonical = sortedEntries.first else { continue }
            let duplicates = Array(sortedEntries.dropFirst())
            
            let group = DuplicateGroup(
                canonical: canonical,
                duplicates: duplicates,
                contentHash: hash
            )
            
            duplicateGroups.append(group)
        }
        
        return duplicateGroups
    }
    
    /// Find duplicate entries by source URL
    /// Useful for detecting entries from the same source
    /// - Parameter entries: Array of entries to check
    /// - Returns: Dictionary mapping source URL to array of entries
    func findDuplicatesBySourceURL(in entries: [OfflineKnowledgeEntry]) -> [String: [OfflineKnowledgeEntry]] {
        var urlToEntries: [String: [OfflineKnowledgeEntry]] = [:]
        
        for entry in entries {
            // Check metadata for source URL
            if let sourceURL = entry.metadata?["sourceURL"] {
                urlToEntries[sourceURL, default: []].append(entry)
            }
        }
        
        // Filter to only URLs with duplicates
        return urlToEntries.filter { $0.value.count > 1 }
    }
    
    /// Find all duplicates using both content hash and source URL
    /// - Parameter entries: Array of entries to check
    /// - Returns: Array of duplicate groups
    func findAllDuplicates(in entries: [OfflineKnowledgeEntry]) -> [DuplicateGroup] {
        // Primary detection by content hash
        var groups = findDuplicatesByContentHash(in: entries)
        
        // Secondary detection by source URL for entries not already in groups
        let groupedEntryIds = Set(groups.flatMap { [$0.canonical.id] + $0.duplicates.map { $0.id } })
        let ungroupedEntries = entries.filter { !groupedEntryIds.contains($0.id) }
        
        let urlDuplicates = findDuplicatesBySourceURL(in: ungroupedEntries)
        
        for (_, urlEntries) in urlDuplicates where urlEntries.count > 1 {
            let sortedEntries = urlEntries.sorted { $0.timestamp < $1.timestamp }
            
            guard let canonical = sortedEntries.first else { continue }
            let duplicates = Array(sortedEntries.dropFirst())
            
            // Use content hash of canonical entry
            let hash = calculateContentHash(canonical)
            
            let group = DuplicateGroup(
                canonical: canonical,
                duplicates: duplicates,
                contentHash: hash
            )
            
            groups.append(group)
        }
        
        return groups
    }
    
    // MARK: - Merge Logic
    
    /// Merge duplicate entries into a single canonical entry
    /// Preserves metadata from all entries and keeps the most complete content
    /// - Parameters:
    ///   - existing: The existing (canonical) entry
    ///   - new: The new (duplicate) entry to merge
    /// - Returns: Merged entry
    func merge(existing: OfflineKnowledgeEntry, new: OfflineKnowledgeEntry) -> OfflineKnowledgeEntry {
        // Keep the entry with the earliest timestamp as the base
        let base = existing.timestamp <= new.timestamp ? existing : new
        let other = existing.timestamp <= new.timestamp ? new : existing
        
        // Merge metadata
        var mergedMetadata = base.metadata ?? [:]
        
        // Add metadata from other entry
        if let otherMetadata = other.metadata {
            for (key, value) in otherMetadata {
                // Preserve existing values, but add new ones
                if mergedMetadata[key] == nil {
                    mergedMetadata[key] = value
                } else if key == "tags" {
                    // Merge tags
                    let existingTags = Set(mergedMetadata[key]?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [])
                    let newTags = Set(value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                    let allTags = existingTags.union(newTags)
                    mergedMetadata[key] = allTags.sorted().joined(separator: ", ")
                } else if key == "sourceURL" {
                    // Keep both source URLs if different
                    if mergedMetadata[key] != value {
                        mergedMetadata["alternateSourceURL"] = value
                    }
                }
            }
        }
        
        // Add merge tracking metadata
        mergedMetadata["mergedFrom"] = other.id
        mergedMetadata["mergedAt"] = ISO8601DateFormatter().string(from: Date())
        
        // Choose the richer content
        let chosenMappedData = chooseBetterMappedData(base.mappedData, other.mappedData)
        
        // Create merged entry
        return OfflineKnowledgeEntry(
            id: base.id,
            domainId: base.domainId,
            originalSubmission: base.originalSubmission,
            mappedData: chosenMappedData,
            schemaVersion: max(base.schemaVersion, other.schemaVersion),
            timestamp: base.timestamp, // Keep earliest timestamp
            status: chooseBetterStatus(base.status, other.status),
            metadata: mergedMetadata
        )
    }
    
    /// Merge multiple duplicate entries into a single canonical entry
    /// - Parameter group: Duplicate group to merge
    /// - Returns: Merged entry
    func mergeGroup(_ group: DuplicateGroup) -> OfflineKnowledgeEntry {
        var merged = group.canonical
        
        for duplicate in group.duplicates {
            merged = merge(existing: merged, new: duplicate)
        }
        
        return merged
    }
    
    /// Merge all duplicate groups
    /// - Parameter groups: Array of duplicate groups
    /// - Returns: Array of merged entries
    func mergeAllGroups(_ groups: [DuplicateGroup]) -> [OfflineKnowledgeEntry] {
        return groups.map { mergeGroup($0) }
    }
    
    // MARK: - Metadata Preservation
    
    /// Choose the better mapped data between two entries
    /// Prefers entries with parsed JSON, more entities, and no errors
    /// - Parameters:
    ///   - data1: First mapped data
    ///   - data2: Second mapped data
    /// - Returns: The better mapped data
    private func chooseBetterMappedData(_ data1: MappedData, _ data2: MappedData) -> MappedData {
        // Prefer data without errors
        if data1.error == nil && data2.error != nil {
            return data1
        } else if data1.error != nil && data2.error == nil {
            return data2
        }
        
        // Prefer data with parsed JSON
        if data1.parsedJson != nil && data2.parsedJson == nil {
            return data1
        } else if data1.parsedJson == nil && data2.parsedJson != nil {
            return data2
        }
        
        // Prefer data with more entities
        let entities1Count = data1.extractedEntities?.count ?? 0
        let entities2Count = data2.extractedEntities?.count ?? 0
        
        if entities1Count > entities2Count {
            return data1
        } else if entities2Count > entities1Count {
            return data2
        }
        
        // Prefer data with more content
        let content1Length = data1.content?.count ?? 0
        let content2Length = data2.content?.count ?? 0
        
        return content1Length >= content2Length ? data1 : data2
    }
    
    /// Choose the better status between two entries
    /// Prefers success over other statuses
    /// - Parameters:
    ///   - status1: First status
    ///   - status2: Second status
    /// - Returns: The better status
    private func chooseBetterStatus(_ status1: ImportStatus, _ status2: ImportStatus) -> ImportStatus {
        // Prefer success
        if status1 == .success {
            return status1
        } else if status2 == .success {
            return status2
        }
        
        // Prefer processing over pending or failed
        if status1 == .processing {
            return status1
        } else if status2 == .processing {
            return status2
        }
        
        // Prefer pending over failed
        if status1 == .pending {
            return status1
        } else if status2 == .pending {
            return status2
        }
        
        // Default to first status
        return status1
    }
    
    // MARK: - Deduplication Operations
    
    /// Perform complete deduplication on a set of entries
    /// - Parameter entries: Array of entries to deduplicate
    /// - Returns: Deduplication statistics
    func deduplicate(_ entries: [OfflineKnowledgeEntry]) -> (merged: [OfflineKnowledgeEntry], statistics: DeduplicationStatistics) {
        let startTime = Date()
        
        // Find all duplicates
        let duplicateGroups = findAllDuplicates(in: entries)
        
        // Merge duplicate groups
        let mergedEntries = mergeAllGroups(duplicateGroups)
        
        // Calculate statistics
        let totalDuplicates = duplicateGroups.reduce(0) { $0 + $1.duplicates.count }
        let estimatedSpaceSaved = Int64(totalDuplicates * 1024) // Rough estimate: 1KB per entry
        
        let statistics = DeduplicationStatistics(
            totalProcessed: entries.count,
            duplicateGroupsFound: duplicateGroups.count,
            totalDuplicates: totalDuplicates,
            entriesMerged: mergedEntries.count,
            entriesRemoved: totalDuplicates,
            estimatedSpaceSaved: estimatedSpaceSaved,
            processingTime: Date().timeIntervalSince(startTime)
        )
        
        return (mergedEntries, statistics)
    }
    
    // MARK: - Cache Management
    
    /// Clear the content hash cache
    func clearCache() {
        cacheLock.lock()
        hashCache.removeAll()
        cacheLock.unlock()
    }
    
    /// Get cache statistics
    /// - Returns: Dictionary with cache statistics
    func cacheStatistics() -> [String: Any] {
        cacheLock.lock()
        let count = hashCache.count
        cacheLock.unlock()
        
        return [
            "cachedHashes": count,
            "cacheMemoryEstimate": count * 64 // Rough estimate: 64 bytes per entry
        ]
    }
}

// MARK: - Extension for KnowledgeStorageService Integration

extension OfflineKnowledgeEntry {
    /// Get content hash for this entry
    /// - Parameter service: Deduplication service to use
    /// - Returns: Content hash string
    func contentHash(using service: DeduplicationService) -> String {
        return service.calculateContentHash(self)
    }
}
