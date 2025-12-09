//
//  SyncQueue.swift
//  Hub
//
//  Sync queue actor for managing background CloudKit sync operations
//  Provides FIFO queue processing with error handling and monitoring
//

import Foundation

/// Actor managing background sync operations for CloudKit
/// Ensures operations are processed in order without blocking local storage
actor SyncQueue {
    
    // MARK: - Properties
    
    /// FIFO queue of pending sync operations
    private var queue: [LocalSyncOperation] = []
    
    /// Whether the queue is currently processing operations
    private var isProcessing: Bool = false
    
    /// CloudSync service for executing operations
    private let cloudSync: CloudSyncService
    
    /// Retry manager for handling failed operations
    private let retryManager: RetryManager?
    
    /// Maximum queue depth before warning (for monitoring)
    private let maxQueueDepth: Int = 1000
    
    /// Statistics for monitoring
    private var totalEnqueued: Int = 0
    private var totalProcessed: Int = 0
    private var totalFailed: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize sync queue with cloud sync service
    /// - Parameters:
    ///   - cloudSync: The CloudSync service to use for operations
    ///   - retryManager: Optional retry manager for handling failures
    init(cloudSync: CloudSyncService, retryManager: RetryManager? = nil) {
        self.cloudSync = cloudSync
        self.retryManager = retryManager
    }
    
    // MARK: - Queue Management
    
    /// Enqueue a sync operation for background processing
    /// Operations are processed in FIFO order
    /// - Parameter operation: The sync operation to enqueue
    func enqueue(_ operation: LocalSyncOperation) {
        queue.append(operation)
        totalEnqueued += 1
        
        // Check queue depth for monitoring
        if queue.count > maxQueueDepth {
            logWarning("Sync queue depth exceeded \(maxQueueDepth): \(queue.count) operations pending")
        }
        
        // Start processing if not already running
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Enqueue multiple sync operations at once
    /// - Parameter operations: Array of sync operations to enqueue
    func enqueueMultiple(_ operations: [LocalSyncOperation]) {
        queue.append(contentsOf: operations)
        totalEnqueued += operations.count
        
        // Check queue depth for monitoring
        if queue.count > maxQueueDepth {
            logWarning("Sync queue depth exceeded \(maxQueueDepth): \(queue.count) operations pending")
        }
        
        // Start processing if not already running
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    // MARK: - Queue Processing
    
    /// Process all operations in the queue
    /// Runs asynchronously without blocking
    private func processQueue() async {
        // Prevent concurrent processing
        guard !isProcessing else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Process operations in FIFO order
        while !queue.isEmpty {
            let operation = queue.removeFirst()
            
            do {
                let success = try await executeOperation(operation)
                
                if success {
                    totalProcessed += 1
                    logInfo("Sync operation succeeded: \(operation.entryId)")
                } else {
                    totalFailed += 1
                    logWarning("Sync operation failed (CloudKit unavailable): \(operation.entryId)")
                    
                    // Schedule retry if retry manager is available
                    if let retryManager = retryManager {
                        await retryManager.scheduleRetry(operation: operation, error: LocalStorageError.cloudKitUnavailable)
                    }
                }
            } catch {
                totalFailed += 1
                logError("Sync operation failed with error: \(operation.entryId) - \(error.localizedDescription)")
                
                // Schedule retry if retry manager is available
                if let retryManager = retryManager {
                    await retryManager.scheduleRetry(operation: operation, error: error)
                }
            }
        }
    }
    
    /// Execute a single sync operation
    /// - Parameter operation: The operation to execute
    /// - Returns: True if operation succeeded, false if CloudKit unavailable
    /// - Throws: Error if operation fails
    private func executeOperation(_ operation: LocalSyncOperation) async throws -> Bool {
        switch operation {
        case .save(let item):
            return await cloudSync.sync(item)
            
        case .update(let item):
            // Update is the same as save in CloudKit
            return await cloudSync.sync(item)
            
        case .delete(let id):
            return await cloudSync.delete(id: id)
        }
    }
    
    // MARK: - Monitoring
    
    /// Get current queue depth
    /// - Returns: Number of operations waiting in queue
    func getQueueDepth() -> Int {
        return queue.count
    }
    
    /// Get queue statistics for monitoring
    /// - Returns: Dictionary of statistics
    func getStatistics() -> [String: Int] {
        return [
            "queueDepth": queue.count,
            "totalEnqueued": totalEnqueued,
            "totalProcessed": totalProcessed,
            "totalFailed": totalFailed,
            "isProcessing": isProcessing ? 1 : 0
        ]
    }
    
    /// Check if queue is currently processing
    /// - Returns: True if processing operations
    func isCurrentlyProcessing() -> Bool {
        return isProcessing
    }
    
    /// Clear all pending operations (for testing or emergency)
    /// - Returns: Number of operations cleared
    func clearQueue() -> Int {
        let count = queue.count
        queue.removeAll()
        logWarning("Cleared \(count) operations from sync queue")
        return count
    }
    
    // MARK: - Logging
    
    /// Log informational message
    /// - Parameter message: The message to log
    private func logInfo(_ message: String) {
        // In production, this would use a proper logging framework
        print("[SyncQueue] INFO: \(message)")
    }
    
    /// Log warning message
    /// - Parameter message: The message to log
    private func logWarning(_ message: String) {
        // In production, this would use a proper logging framework
        print("[SyncQueue] WARNING: \(message)")
    }
    
    /// Log error message
    /// - Parameter message: The message to log
    private func logError(_ message: String) {
        // In production, this would use a proper logging framework
        print("[SyncQueue] ERROR: \(message)")
    }
}
