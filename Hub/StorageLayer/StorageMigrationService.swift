//
//  StorageMigrationService.swift
//  Hub
//
//  Migration service for transitioning from old storage to new local-first architecture
//  Supports dual-write mode, data verification, and rollback on failure
//

import Foundation

// MARK: - Migration Status

/// Status of the migration process
enum MigrationStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case dualWrite
    case completed
    case failed
    case rolledBack
}

// MARK: - Storage Migration Error

/// Errors that can occur during storage migration
enum StorageMigrationError: Error, LocalizedError {
    case migrationAlreadyInProgress
    case migrationNotInProgress
    case verificationFailed(String)
    case rollbackFailed(String)
    case dataCorruption(String)
    case incompatibleVersion(Int, Int)
    
    var errorDescription: String? {
        switch self {
        case .migrationAlreadyInProgress:
            return "Migration is already in progress"
        case .migrationNotInProgress:
            return "No migration is currently in progress"
        case .verificationFailed(let reason):
            return "Migration verification failed: \(reason)"
        case .rollbackFailed(let reason):
            return "Failed to rollback migration: \(reason)"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        case .incompatibleVersion(let current, let expected):
            return "Incompatible schema version: current=\(current), expected=\(expected)"
        }
    }
}

// MARK: - Migration Result

/// Result of a migration operation
struct MigrationResult: Codable {
    /// Total number of entries to migrate
    let totalEntries: Int
    
    /// Number of entries successfully migrated
    let migratedEntries: Int
    
    /// Number of entries that failed to migrate
    let failedEntries: Int
    
    /// IDs of entries that failed
    let failedEntryIds: [String]
    
    /// Duration of migration in seconds
    let duration: TimeInterval
    
    /// Whether migration was successful
    var isSuccessful: Bool {
        return failedEntries == 0 && migratedEntries == totalEntries
    }
    
    /// Success rate as percentage
    var successRate: Double {
        guard totalEntries > 0 else { return 0.0 }
        return Double(migratedEntries) / Double(totalEntries) * 100.0
    }
}

// MARK: - Migration Configuration

/// Configuration for migration process
struct MigrationConfiguration: Sendable {
    /// Whether to enable dual-write mode during migration
    let enableDualWrite: Bool
    
    /// Whether to verify data after migration
    let verifyAfterMigration: Bool
    
    /// Whether to automatically rollback on failure
    let autoRollbackOnFailure: Bool
    
    /// Batch size for migration operations
    let batchSize: Int
    
    /// Maximum number of retries for failed entries
    let maxRetries: Int
    
    nonisolated(unsafe) static let `default` = MigrationConfiguration(
        enableDualWrite: true,
        verifyAfterMigration: true,
        autoRollbackOnFailure: true,
        batchSize: 100,
        maxRetries: 3
    )
}

// MARK: - Storage Migration Service

/// Service for migrating data from old storage to new local-first architecture
actor StorageMigrationService {
    
    // MARK: - Properties
    
    /// Current migration status
    private(set) var status: MigrationStatus = .notStarted
    
    /// Configuration for migration
    private let configuration: MigrationConfiguration
    
    /// Old storage service (source)
    private let oldStorage: KnowledgeStorageService
    
    /// New storage coordinator (destination)
    private let newStorage: StorageCoordinator
    
    /// Backup of old data for rollback
    private var backup: [OfflineKnowledgeEntry] = []
    
    /// Migration start time
    private var migrationStartTime: Date?
    
    /// Whether dual-write mode is currently active
    private(set) var isDualWriteActive: Bool = false
    
    // MARK: - Initialization
    
    init(
        oldStorage: KnowledgeStorageService,
        newStorage: StorageCoordinator,
        configuration: MigrationConfiguration = .default
    ) {
        self.oldStorage = oldStorage
        self.newStorage = newStorage
        self.configuration = configuration
    }
    
    // MARK: - Migration Operations
    
    /// Start the migration process
    /// - Returns: Migration result with statistics
    /// - Throws: MigrationError if migration fails
    func startMigration() async throws -> MigrationResult {
        guard status == .notStarted || status == .failed || status == .rolledBack else {
            throw StorageMigrationError.migrationAlreadyInProgress
        }
        
        print("🚀 Starting storage migration...")
        status = .inProgress
        migrationStartTime = Date()
        
        do {
            // Step 1: Load all entries from old storage
            print("📚 Loading entries from old storage...")
            let entries = try await oldStorage.loadAll()
            print("✅ Loaded \(entries.count) entries")
            
            // Step 2: Create backup for rollback
            print("💾 Creating backup for rollback...")
            backup = entries
            print("✅ Backup created")
            
            // Step 3: Migrate entries in batches
            print("🔄 Migrating entries to new storage...")
            let result = try await migrateEntries(entries)
            
            // Step 4: Verify migration if configured
            if configuration.verifyAfterMigration {
                print("🔍 Verifying migrated data...")
                try await verifyMigration(entries)
                print("✅ Verification successful")
            }
            
            // Step 5: Enable dual-write mode if configured
            if configuration.enableDualWrite {
                print("🔀 Enabling dual-write mode...")
                // enableDualWrite is non-throwing, so keep await without try
                await enableDualWrite()
                status = .dualWrite
                print("✅ Dual-write mode enabled")
            } else {
                status = .completed
            }
            
            let duration = Date().timeIntervalSince(migrationStartTime!)
            print("✨ Migration completed in \(String(format: "%.2f", duration))s")
            print("   - Total: \(result.totalEntries)")
            print("   - Migrated: \(result.migratedEntries)")
            print("   - Failed: \(result.failedEntries)")
            print("   - Success rate: \(String(format: "%.1f%%", result.successRate))")
            
            return result
            
        } catch {
            print("❌ Migration failed: \(error.localizedDescription)")
            status = .failed
            
            // Auto-rollback if configured
            if configuration.autoRollbackOnFailure {
                print("🔙 Auto-rollback enabled, attempting rollback...")
                try await rollback()
            }
            
            throw error
        }
    }
    
    /// Migrate entries in batches
    /// - Parameter entries: Entries to migrate
    /// - Returns: Migration result
    private func migrateEntries(_ entries: [OfflineKnowledgeEntry]) async throws -> MigrationResult {
        var migratedCount = 0
        var failedCount = 0
        var failedIds: [String] = []
        
        // Process in batches
        let batches = entries.chunked(into: configuration.batchSize)
        
        for (index, batch) in batches.enumerated() {
            print("   Batch \(index + 1)/\(batches.count): Processing \(batch.count) entries...")
            
            for entry in batch {
                var retries = 0
                var success = false
                
                while retries < configuration.maxRetries && !success {
                    do {
                        try await newStorage.save(entry)
                        migratedCount += 1
                        success = true
                    } catch {
                        retries += 1
                        if retries >= configuration.maxRetries {
                            print("   ⚠️ Failed to migrate entry \(entry.id) after \(retries) retries")
                            failedCount += 1
                            failedIds.append(entry.id)
                        } else {
                            // Wait before retry with exponential backoff
                            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retries)) * 100_000_000))
                        }
                    }
                }
            }
            
            print("   ✅ Batch \(index + 1) complete: \(migratedCount)/\(entries.count) migrated")
        }
        
        let duration = Date().timeIntervalSince(migrationStartTime!)
        
        return MigrationResult(
            totalEntries: entries.count,
            migratedEntries: migratedCount,
            failedEntries: failedCount,
            failedEntryIds: failedIds,
            duration: duration
        )
    }
    
    /// Verify that migration was successful
    /// - Parameter originalEntries: Original entries from old storage
    /// - Throws: MigrationError if verification fails
    private func verifyMigration(_ originalEntries: [OfflineKnowledgeEntry]) async throws {
        var missingEntries: [String] = []
        var corruptedEntries: [String] = []
        
        for originalEntry in originalEntries {
            do {
                let migratedEntry: OfflineKnowledgeEntry = try await newStorage.load(id: originalEntry.id)
                
                // Verify data integrity
                if !areEntriesEqual(originalEntry, migratedEntry) {
                    corruptedEntries.append(originalEntry.id)
                }
            } catch {
                missingEntries.append(originalEntry.id)
            }
        }
        
        if !missingEntries.isEmpty {
            throw StorageMigrationError.verificationFailed("Missing \(missingEntries.count) entries: \(missingEntries.prefix(5).joined(separator: ", "))")
        }
        
        if !corruptedEntries.isEmpty {
            let corruptedList = corruptedEntries.prefix(5).joined(separator: ", ")
            throw StorageMigrationError.dataCorruption("Corrupted \(corruptedEntries.count) entries: \(corruptedList)")
        }
    }
    
    /// Compare two entries for equality
    /// - Parameters:
    ///   - entry1: First entry
    ///   - entry2: Second entry
    /// - Returns: True if entries are equal
    private func areEntriesEqual(_ entry1: OfflineKnowledgeEntry, _ entry2: OfflineKnowledgeEntry) -> Bool {
        return entry1.id == entry2.id &&
               entry1.domainId == entry2.domainId &&
               entry1.originalSubmission == entry2.originalSubmission &&
               entry1.schemaVersion == entry2.schemaVersion &&
               entry1.status == entry2.status
    }
    
    // MARK: - Dual-Write Mode
    
    /// Enable dual-write mode (writes go to both old and new storage)
    func enableDualWrite() async {
        isDualWriteActive = true
        print("🔀 Dual-write mode enabled")
    }
    
    /// Disable dual-write mode (writes go only to new storage)
    func disableDualWrite() async {
        isDualWriteActive = false
        print("🔀 Dual-write mode disabled")
    }
    
    /// Save an entry in dual-write mode
    /// - Parameter entry: Entry to save
    /// - Throws: Error if save fails
    func saveDualWrite(_ entry: OfflineKnowledgeEntry) async throws {
        guard isDualWriteActive else {
            throw StorageMigrationError.migrationNotInProgress
        }
        
        // Write to both storages
        var errors: [Error] = []
        
        // Write to new storage (primary)
        do {
            try await newStorage.save(entry)
        } catch {
            errors.append(error)
        }
        
        // Write to old storage (secondary)
        do {
            try await oldStorage.save(entry)
        } catch {
            errors.append(error)
        }
        
        // If both failed, throw error
        if errors.count == 2 {
            throw errors[0]
        }
    }
    
    // MARK: - Rollback
    
    /// Rollback the migration
    /// - Throws: MigrationError if rollback fails
    func rollback() async throws {
        guard status == .inProgress || status == .failed || status == .dualWrite else {
            throw StorageMigrationError.migrationNotInProgress
        }
        
        print("🔙 Rolling back migration...")
        
        do {
            // Clear new storage
            print("   Clearing new storage...")
            let allIds = backup.map { $0.id }
            try await newStorage.deleteMultiple(ids: allIds)
            
            // Restore old storage from backup
            print("   Restoring old storage from backup...")
            for entry in backup {
                try await oldStorage.save(entry)
            }
            
            // Clear backup
            backup.removeAll()
            
            // Disable dual-write if active
            if isDualWriteActive {
                await disableDualWrite()
            }
            
            status = .rolledBack
            print("✅ Rollback completed successfully")
            
        } catch {
            throw StorageMigrationError.rollbackFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Completion
    
    /// Complete the migration (disable dual-write and mark as completed)
    /// - Throws: MigrationError if not in dual-write mode
    func completeMigration() async throws {
        guard status == .dualWrite else {
            throw StorageMigrationError.migrationNotInProgress
        }
        
        print("✅ Completing migration...")
        
        // Disable dual-write mode
        await disableDualWrite()
        
        // Clear backup
        backup.removeAll()
        
        status = .completed
        print("✨ Migration completed and finalized")
    }
    
    // MARK: - Status and Diagnostics
    
    /// Get current migration status
    /// - Returns: Current status
    func getStatus() -> MigrationStatus {
        return status
    }
    
    /// Get migration diagnostics
    /// - Returns: Dictionary with diagnostic information
    func getDiagnostics() async -> [String: Any] {
        var diagnostics: [String: Any] = [
            "status": status.rawValue,
            "isDualWriteActive": isDualWriteActive,
            "backupSize": backup.count
        ]
        
        if let startTime = migrationStartTime {
            diagnostics["elapsedTime"] = Date().timeIntervalSince(startTime)
        }
        
        return diagnostics
    }
}

// MARK: - Array Extension

extension Array {
    /// Split array into chunks of specified size
    /// - Parameter size: Size of each chunk
    /// - Returns: Array of chunks
    nonisolated func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

