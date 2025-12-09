//
//  CloudSyncService.swift
//  Hub
//
//  Cloud sync service actor for optional CloudKit synchronization
//  Provides non-blocking async sync that doesn't affect local operations
//

import Foundation
import CloudKit

/// Actor providing optional CloudKit synchronization for local-first database
/// All sync operations are async and non-blocking - local operations never wait for CloudKit
actor CloudSyncService {
    
    // MARK: - Properties
    
    /// Optional CloudKit container (nil if CloudKit not configured)
    private let container: CKContainer?
    
    /// Whether CloudKit is currently available
    private var isAvailable: Bool = false
    
    /// Last time availability was checked
    private var lastAvailabilityCheck: Date?
    
    /// Interval between availability checks
    private let availabilityCheckInterval: TimeInterval
    
    // MARK: - Initialization
    
    /// Initialize with optional CloudKit container
    /// - Parameters:
    ///   - containerIdentifier: CloudKit container identifier (nil to disable CloudKit)
    ///   - availabilityCheckInterval: Interval between availability checks (default: 300 seconds)
    init(containerIdentifier: String? = nil, availabilityCheckInterval: TimeInterval = 300) {
        if let identifier = containerIdentifier {
            self.container = CKContainer(identifier: identifier)
        } else {
            self.container = nil
        }
        
        self.availabilityCheckInterval = availabilityCheckInterval
        
        // Start availability check in background
        Task {
            await checkAvailability()
        }
    }
    
    // MARK: - Availability Checking
    
    /// Check if CloudKit is available
    /// This is cached and only checked periodically to avoid excessive API calls
    /// - Returns: True if CloudKit is available
    func isCloudKitAvailable() async -> Bool {
        // Check if we need to refresh availability
        if let lastCheck = lastAvailabilityCheck,
           Date().timeIntervalSince(lastCheck) < availabilityCheckInterval {
            return isAvailable
        }
        
        // Refresh availability
        await checkAvailability()
        return isAvailable
    }
    
    /// Check CloudKit availability and update cached status
    private func checkAvailability() async {
        guard let container = container else {
            isAvailable = false
            lastAvailabilityCheck = Date()
            return
        }
        
        do {
            let status = try await container.accountStatus()
            isAvailable = (status == .available)
            lastAvailabilityCheck = Date()
        } catch {
            // Silently fail - CloudKit unavailability is expected and normal
            isAvailable = false
            lastAvailabilityCheck = Date()
        }
    }
    
    // MARK: - Sync Operations
    
    /// Sync an item to CloudKit (non-blocking)
    /// - Parameter item: The item to sync
    /// - Returns: True if sync succeeded, false if CloudKit unavailable or sync failed
    func sync<T: Storable>(_ item: T) async -> Bool {
        // Check availability first
        guard await isCloudKitAvailable(), let container = container else {
            // Silently skip if CloudKit unavailable - this is expected behavior
            return false
        }
        
        do {
            // Convert to CloudKit record
            let record = try item.toCKRecord()
            
            // Save to CloudKit
            _ = try await container.publicCloudDatabase.save(record)
            
            return true
        } catch {
            // Silently fail - sync failures don't affect local operations
            // In production, this would be logged for monitoring
            return false
        }
    }
    
    /// Sync multiple items to CloudKit (non-blocking)
    /// - Parameter items: Array of items to sync
    /// - Returns: Array of successfully synced item IDs
    func syncMultiple<T: Storable>(_ items: [T]) async -> [String] {
        // Check availability first
        guard await isCloudKitAvailable(), let container = container else {
            return []
        }
        
        var successfulIds: [String] = []
        
        do {
            // Convert all items to CloudKit records
            let records = try items.map { try $0.toCKRecord() }
            
            // Batch save to CloudKit
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .utility
            
            // Track successful saves
            operation.perRecordSaveBlock = { recordID, result in
                switch result {
                case .success:
                    successfulIds.append(recordID.recordName)
                case .failure:
                    // Silently skip failed records
                    break
                }
            }
            
            // Execute operation
            try await container.publicCloudDatabase.add(operation)
            
        } catch {
            // Silently fail - sync failures don't affect local operations
        }
        
        return successfulIds
    }
    
    /// Delete an item from CloudKit (non-blocking)
    /// - Parameter id: The item ID to delete
    /// - Returns: True if deletion succeeded, false if CloudKit unavailable or deletion failed
    func delete(id: String) async -> Bool {
        // Check availability first
        guard await isCloudKitAvailable(), let container = container else {
            return false
        }
        
        do {
            let recordID = CKRecord.ID(recordName: id)
            _ = try await container.publicCloudDatabase.deleteRecord(withID: recordID)
            return true
        } catch {
            // Silently fail - sync failures don't affect local operations
            return false
        }
    }
    
    /// Fetch an item from CloudKit (non-blocking)
    /// - Parameter id: The item ID to fetch
    /// - Returns: The CloudKit record if found, nil otherwise
    func fetch(id: String) async -> CKRecord? {
        // Check availability first
        guard await isCloudKitAvailable(), let container = container else {
            return nil
        }
        
        do {
            let recordID = CKRecord.ID(recordName: id)
            let record = try await container.publicCloudDatabase.record(for: recordID)
            return record
        } catch {
            // Silently fail - sync failures don't affect local operations
            return nil
        }
    }
    
    /// Fetch all items of a specific record type from CloudKit (non-blocking)
    /// - Parameter recordType: The CloudKit record type to fetch
    /// - Returns: Array of CloudKit records
    func fetchAll(recordType: String) async -> [CKRecord] {
        // Check availability first
        guard await isCloudKitAvailable(), let container = container else {
            return []
        }
        
        do {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let results = try await container.publicCloudDatabase.records(matching: query)
            
            // Extract successful records
            return results.matchResults.compactMap { _, result in
                try? result.get()
            }
        } catch {
            // Silently fail - sync failures don't affect local operations
            return []
        }
    }
    
    // MARK: - Error Handling
    
    /// Handle CloudKit errors gracefully
    /// This method ensures errors don't propagate to local operations
    /// - Parameter error: The error to handle
    private func handleError(_ error: Error) {
        // In production, this would log to monitoring system
        // For now, we silently handle errors as CloudKit unavailability is expected
        
        // If error indicates CloudKit is unavailable, update status
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure, .notAuthenticated:
                isAvailable = false
            default:
                break
            }
        }
    }
}
