//
//  KnowledgeStorageServiceExtension.swift
//  Hub
//
//  Extension to KnowledgeStorageService for Offline Assistant Module
//  Adds methods for content hash-based deduplication, batch operations, and incremental persistence
//

import Foundation

// MARK: - Knowledge Storage Service Extension for Offline Assistant

@MainActor extension KnowledgeStorageService {
    
    // MARK: - Content Hash-Based Operations
    
    /// Fetch an entry by its content hash for deduplication
    /// - Parameter contentHash: The SHA-256 hash of the entry content
    /// - Returns: The matching entry if found, nil otherwise
    func fetchEntry(byContentHash contentHash: String) async -> OfflineKnowledgeEntry? {
        // Search through all entries to find one with matching content hash
        guard let allEntries = try? await fetchAll() else {
            return nil
        }
        
        for entry in allEntries {
            let entryHash = await calculateContentHash(for: entry)
            if entryHash == contentHash {
                return entry
            }
        }
        
        return nil
    }
    
    /// Calculate content hash for an entry
    /// - Parameter entry: The entry to hash
    /// - Returns: SHA-256 hash of the entry's content
    func calculateContentHash(for entry: OfflineKnowledgeEntry) async -> String {
        let content = entry.originalSubmission + (entry.mappedData.content ?? "")
        return content.sha256Hash()
    }
    
    // MARK: - Update Operations
    
    /// Update an existing entry (for merging duplicates)
    /// - Parameter entry: The entry to update
    /// - Throws: Error if update fails
    func update(_ entry: OfflineKnowledgeEntry) async throws {
        // Verify entry exists by fetching all and checking
        let allEntries = try await fetchAll()
        guard allEntries.contains(where: { $0.id == entry.id }) else {
            throw NSError(domain: "KnowledgeStorage", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Entry not found: \(entry.id)"
            ])
        }
        
        // Use existing save method which handles updates
        try await save(entry)
    }
    
    // MARK: - Batch Save Operations with Progress
    
    /// Save multiple entries in batches with progress reporting
    /// Optimized for large dataset imports with incremental persistence
    /// - Parameters:
    ///   - entries: Array of entries to save
    ///   - batchSize: Number of entries to process per batch (default: 100)
    ///   - progressHandler: Closure called with progress (0.0 to 1.0)
    /// - Returns: Tuple of (successful IDs, failed entries with errors)
    func saveBatchWithProgress(
        _ entries: [OfflineKnowledgeEntry],
        batchSize: Int = 100,
        progressHandler: @escaping (Double) -> Void
    ) async -> (successful: [String], failed: [String: Error]) {
        var successfulIds: [String] = []
        var errors: [String: Error] = [:]
        
        let totalCount = entries.count
        var processedCount = 0
        
        // Process entries in batches
        for batchStart in stride(from: 0, to: totalCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalCount)
            let batch = Array(entries[batchStart..<batchEnd])
            
            // Process batch
            for entry in batch {
                do {
                    try await save(entry)
                    successfulIds.append(entry.id)
                } catch {
                    errors[entry.id] = error
                }
                
                processedCount += 1
                
                // Report progress
                let progress = Double(processedCount) / Double(totalCount)
                progressHandler(progress)
            }
            
            // Yield to allow other tasks to run between batches
            await Task.yield()
        }
        
        return (successfulIds, errors)
    }
    
    /// Save multiple entries with incremental persistence for large datasets
    /// Persists to disk after each batch to prevent memory issues
    /// - Parameters:
    ///   - entries: Array of entries to save
    ///   - batchSize: Number of entries to persist per batch (default: 50)
    ///   - progressHandler: Closure called with progress (0.0 to 1.0)
    /// - Returns: Tuple of (successful IDs, failed entries with errors)
    func saveBatchIncremental(
        _ entries: [OfflineKnowledgeEntry],
        batchSize: Int = 50,
        progressHandler: @escaping (Double) -> Void
    ) async -> (successful: [String], failed: [String: Error]) {
        var successfulIds: [String] = []
        var errors: [String: Error] = [:]
        
        let totalCount = entries.count
        var processedCount = 0
        
        // Process entries in batches with immediate persistence
        for batchStart in stride(from: 0, to: totalCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalCount)
            let batch = Array(entries[batchStart..<batchEnd])
            
            // Save each entry in the batch
            for entry in batch {
                do {
                    // Use the existing save method which handles validation, entities, and persistence
                    try await save(entry)
                    successfulIds.append(entry.id)
                } catch {
                    errors[entry.id] = error
                }
                
                processedCount += 1
            }
            
            // Report progress
            let progress = Double(processedCount) / Double(totalCount)
            progressHandler(progress)
            
            // Yield to allow other tasks to run between batches
            await Task.yield()
        }
        
        return (successfulIds, errors)
    }
    
    // MARK: - Bulk Operations
    
    /// Save multiple entries with validation and deduplication
    /// - Parameters:
    ///   - entries: Array of entries to save
    ///   - deduplicateByHash: Whether to check for duplicates by content hash
    ///   - progressHandler: Optional progress callback
    /// - Returns: Import result with statistics
    func saveBulk(
        _ entries: [OfflineKnowledgeEntry],
        deduplicateByHash: Bool = true,
        progressHandler: ((Double) -> Void)? = nil
    ) async -> BulkImportResult {
        var imported = 0
        var deduplicated = 0
        var updated = 0
        var failed = 0
        var errors: [String: Error] = [:]
        
        let totalCount = entries.count
        var processedCount = 0
        
        for entry in entries {
            do {
                // Check for duplicates by content hash if enabled
                if deduplicateByHash {
                    let contentHash = await calculateContentHash(for: entry)
                    
                    if let existing = await fetchEntry(byContentHash: contentHash) {
                        // Duplicate found - merge and update
                        let merged = await mergeEntries(existing: existing, new: entry)
                        try await update(merged)
                        deduplicated += 1
                        updated += 1
                    } else {
                        // New entry
                        try await save(entry)
                        imported += 1
                    }
                } else {
                    // No deduplication - just save
                    try await save(entry)
                    imported += 1
                }
                
            } catch {
                failed += 1
                errors[entry.id] = error
            }
            
            processedCount += 1
            progressHandler?(Double(processedCount) / Double(totalCount))
        }
        
        return BulkImportResult(
            imported: imported,
            deduplicated: deduplicated,
            updated: updated,
            failed: failed,
            errors: errors
        )
    }
    
    // MARK: - Helper Methods
    
    /// Merge two entries, keeping the most recent data
    /// - Parameters:
    ///   - existing: The existing entry in storage
    ///   - new: The new entry being imported
    /// - Returns: Merged entry with combined metadata
    func mergeEntries(
        existing: OfflineKnowledgeEntry,
        new: OfflineKnowledgeEntry
    ) async -> OfflineKnowledgeEntry {
        // Keep the most recent entry as base
        let mostRecent = new.timestamp > existing.timestamp ? new : existing
        
        // Merge metadata
        var mergedMetadata = existing.metadata ?? [:]
        if let newMetadata = new.metadata {
            mergedMetadata.merge(newMetadata) { _, new in new }
        }
        
        // Merge tags
        let existingTags = Set(existing.tags)
        let newTags = Set(new.tags)
        let allTags = existingTags.union(newTags)
        
        if !allTags.isEmpty {
            mergedMetadata["tags"] = allTags.joined(separator: ", ")
        }
        
        // Create merged entry
        return OfflineKnowledgeEntry(
            id: existing.id, // Keep original ID
            domainId: mostRecent.domainId,
            originalSubmission: mostRecent.originalSubmission,
            mappedData: mostRecent.mappedData,
            schemaVersion: max(existing.schemaVersion, new.schemaVersion),
            timestamp: max(existing.timestamp, new.timestamp),
            status: mostRecent.status,
            metadata: mergedMetadata.isEmpty ? nil : mergedMetadata
        )
    }
}

// MARK: - Bulk Import Result

/// Result of a bulk import operation
struct BulkImportResult {
    /// Number of new entries imported
    let imported: Int
    
    /// Number of duplicate entries found
    let deduplicated: Int
    
    /// Number of existing  updated
    let updated: Int
    
    /// Number of entries that failed to import
    let failed: Int
    
    /// Errors for failed entries
    let errors: [String: Error]
    
    /// Total entries processed
    var total: Int {
        return imported + deduplicated + failed
    }
    
    /// Success rate as percentage
    var successRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(imported + deduplicated) / Double(total) * 100.0
    }
}

// Note: sha256Hash() extension is already defined in KnowledgeModels.swift
// No need to redefine it here

