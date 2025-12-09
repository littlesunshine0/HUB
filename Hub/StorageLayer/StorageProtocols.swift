//
//  StorageProtocols.swift
//  Hub
//
//  Core storage protocols and types for local-first database architecture
//

import Foundation
import CloudKit

// MARK: - Storable Protocol

/// Protocol for objects that can be stored in the local-first database
/// All stored items must conform to this protocol for persistence and CloudKit sync
protocol Storable: Codable, Identifiable, Sendable where ID == String {
    /// Unique identifier for the stored item
    nonisolated var id: String { get }
    
    /// Timestamp when the item was created or last modified
    nonisolated var timestamp: Date { get }
    
    /// Convert the item to a CloudKit record for syncing
    /// - Returns: CKRecord representation of the item
    /// - Throws: LocalStorageError if conversion fails
    func toCKRecord() throws -> CKRecord
    
    /// Create an instance from a CloudKit record
    /// - Parameter record: The CloudKit record to convert
    /// - Returns: Instance of the conforming type
    /// - Throws: LocalStorageError if conversion fails
    static func fromCKRecord(_ record: CKRecord) throws -> Self
}

// MARK: - Local Storage Error

/// Comprehensive error types for local-first storage operations
enum LocalStorageError: Error, LocalizedError {
    case entryNotFound(String)
    case indexCorrupted
    case invalidTransaction
    case saveFailed(String)
    case batchSaveFailed([String: Error])
    case rollbackFailed(String)
    case persistenceFailed(String)
    case diskSpaceInsufficient
    case invalidEntry(String)
    case cloudKitUnavailable
    case cloudKitConversionFailed(String)
    case transactionAlreadyActive
    case transactionNotActive
    case concurrentModification(String)
    
    var errorDescription: String? {
        switch self {
        case .entryNotFound(let id):
            return "Entry not found: \(id)"
        case .indexCorrupted:
            return "Search index is corrupted and needs rebuilding"
        case .invalidTransaction:
            return "Invalid transaction state"
        case .saveFailed(let reason):
            return "Failed to save entry: \(reason)"
        case .batchSaveFailed(let errors):
            return "Batch save failed for \(errors.count) entries"
        case .rollbackFailed(let reason):
            return "Failed to rollback transaction: \(reason)"
        case .persistenceFailed(let reason):
            return "Failed to persist to disk: \(reason)"
        case .diskSpaceInsufficient:
            return "Insufficient disk space for storage operation"
        case .invalidEntry(let reason):
            return "Invalid entry: \(reason)"
        case .cloudKitUnavailable:
            return "CloudKit is not available"
        case .cloudKitConversionFailed(let reason):
            return "Failed to convert to/from CloudKit record: \(reason)"
        case .transactionAlreadyActive:
            return "A transaction is already active"
        case .transactionNotActive:
            return "No active transaction"
        case .concurrentModification(let id):
            return "Concurrent modification detected for entry: \(id)"
        }
    }
}

// MARK: - Storage Transaction

/// Represents a transaction for batch storage operations with rollback capability
final class StorageTransaction: @unchecked Sendable {
    /// Unique identifier for the transaction
    let id: UUID
    
    /// Entries that have been modified in this transaction
    var changes: [any Storable] = []
    
    /// Previous states of modified entries for rollback
    /// Key is entry ID, value is the previous state (nil if entry was newly created)
    var previousStates: [String: (any Storable)?] = [:]
    
    /// Whether the transaction has been committed
    var isCommitted: Bool = false
    
    /// Whether the transaction has been rolled back
    var isRolledBack: Bool = false
    
    /// Timestamp when the transaction was created
    let createdAt: Date
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
    }
    
    /// Add a change to the transaction
    /// - Parameters:
    ///   - item: The item being modified
    ///   - previousState: The previous state of the item (nil if new)
    func addChange(_ item: any Storable, previousState: (any Storable)?) {
        changes.append(item)
        if previousStates[item.id] == nil {
            previousStates[item.id] = previousState
        }
    }
    
    /// Check if the transaction is still active
    var isActive: Bool {
        return !isCommitted && !isRolledBack
    }
}

// MARK: - Sync Operation

/// Represents a queued sync operation for CloudKit
enum LocalSyncOperation: Sendable {
    case save(any Storable)
    case delete(String)
    case update(any Storable)
    
    /// The entry ID associated with this operation
    var entryId: String {
        switch self {
        case .save(let item), .update(let item):
            return item.id
        case .delete(let id):
            return id
        }
    }
}

// MARK: - Cloud Sync Status

/// Status of CloudKit synchronization for local-first database
enum CloudSyncStatus: Sendable {
    case idle
    case syncing(progress: Double)
    case completed
    case failed(Error)
    
    var isActive: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
}
