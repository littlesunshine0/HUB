//
//  RetryManager.swift
//  Hub
//
//  Retry manager for handling sync failures with exponential backoff
//  Provides automatic retry scheduling and execution for failed CloudKit operations
//

import Foundation

/// Actor managing retry logic for failed sync operations
/// Implements exponential backoff strategy to avoid overwhelming CloudKit
actor RetryManager {
    
    // MARK: - Properties
    
    /// Pending retry operations with their retry state
    private var retryQueue: [String: RetryState] = [:]
    
    /// CloudSync service for executing retry operations
    private let cloudSync: CloudSyncService
    
    /// Maximum number of retry attempts before giving up
    private let maxRetries: Int
    
    /// Base delay for exponential backoff (in seconds)
    private let baseDelay: TimeInterval
    
    /// Maximum delay between retries (in seconds)
    private let maxDelay: TimeInterval
    
    /// Statistics for monitoring
    private var totalRetries: Int = 0
    private var totalSuccesses: Int = 0
    private var totalGivenUp: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize retry manager with cloud sync service
    /// - Parameters:
    ///   - cloudSync: The CloudSync service to use for retry operations
    ///   - maxRetries: Maximum number of retry attempts (default: 5)
    ///   - baseDelay: Base delay for exponential backoff in seconds (default: 2.0)
    ///   - maxDelay: Maximum delay between retries in seconds (default: 300.0)
    init(
        cloudSync: CloudSyncService,
        maxRetries: Int = 5,
        baseDelay: TimeInterval = 2.0,
        maxDelay: TimeInterval = 300.0
    ) {
        self.cloudSync = cloudSync
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
    
    // MARK: - Retry Scheduling
    
    /// Schedule a retry for a failed sync operation
    /// - Parameters:
    ///   - operation: The sync operation that failed
    ///   - error: The error that caused the failure
    func scheduleRetry(operation: LocalSyncOperation, error: Error) {
        let entryId = operation.entryId
        
        // Check if we already have a retry state for this entry
        if var state = retryQueue[entryId] {
            // Increment retry count
            state.attemptCount += 1
            
            // Check if we've exceeded max retries
            if state.attemptCount >= maxRetries {
                logWarning("Giving up on sync operation after \(maxRetries) attempts: \(entryId)")
                totalGivenUp += 1
                retryQueue.removeValue(forKey: entryId)
                return
            }
            
            // Update state
            state.lastError = error
            state.nextRetryTime = calculateNextRetryTime(attemptCount: state.attemptCount)
            retryQueue[entryId] = state
            
            logInfo("Scheduled retry \(state.attemptCount)/\(maxRetries) for \(entryId) at \(state.nextRetryTime)")
        } else {
            // Create new retry state
            let state = RetryState(
                operation: operation,
                attemptCount: 1,
                lastError: error,
                nextRetryTime: calculateNextRetryTime(attemptCount: 1)
            )
            retryQueue[entryId] = state
            
            logInfo("Scheduled first retry for \(entryId) at \(state.nextRetryTime)")
        }
        
        totalRetries += 1
        
        // Schedule retry execution
        Task {
            await executeRetries()
        }
    }
    
    /// Calculate next retry time using exponential backoff
    /// - Parameter attemptCount: Current attempt count
    /// - Returns: Date when the next retry should occur
    private func calculateNextRetryTime(attemptCount: Int) -> Date {
        // Exponential backoff: baseDelay * 2^(attemptCount - 1)
        let delay = min(baseDelay * pow(2.0, Double(attemptCount - 1)), maxDelay)
        return Date().addingTimeInterval(delay)
    }
    
    // MARK: - Retry Execution
    
    /// Execute all pending retries that are due
    /// Runs asynchronously without blocking
    private func executeRetries() async {
        let now = Date()
        
        // Find all retries that are due
        let dueRetries = retryQueue.filter { _, state in
            state.nextRetryTime <= now
        }
        
        // Execute each due retry
        for (entryId, state) in dueRetries {
            do {
                let success = try await executeRetry(state)
                
                if success {
                    // Retry succeeded - remove from queue
                    retryQueue.removeValue(forKey: entryId)
                    totalSuccesses += 1
                    logInfo("Retry succeeded for \(entryId)")
                } else {
                    // CloudKit unavailable - schedule another retry
                    scheduleRetry(operation: state.operation, error: LocalStorageError.cloudKitUnavailable)
                }
            } catch {
                // Retry failed - schedule another retry
                scheduleRetry(operation: state.operation, error: error)
            }
        }
    }
    
    /// Execute a single retry operation
    /// - Parameter state: The retry state to execute
    /// - Returns: True if operation succeeded, false if CloudKit unavailable
    /// - Throws: Error if operation fails
    private func executeRetry(_ state: RetryState) async throws -> Bool {
        let entryId = state.operation.entryId
        logInfo("Executing retry for \(entryId)")
        
        switch state.operation {
        case .save(let item):
            return await cloudSync.sync(item)
            
        case .update(let item):
            return await cloudSync.sync(item)
            
        case .delete(let id):
            return await cloudSync.delete(id: id)
        }
    }
    
    // MARK: - Monitoring
    
    /// Get current retry queue depth
    /// - Returns: Number of operations waiting for retry
    func getRetryQueueDepth() -> Int {
        return retryQueue.count
    }
    
    /// Get retry statistics for monitoring
    /// - Returns: Dictionary of statistics
    func getStatistics() -> [String: Int] {
        return [
            "retryQueueDepth": retryQueue.count,
            "totalRetries": totalRetries,
            "totalSuccesses": totalSuccesses,
            "totalGivenUp": totalGivenUp
        ]
    }
    
    /// Get all pending retry operations (for debugging)
    /// - Returns: Array of entry IDs with retry counts
    func getPendingRetries() -> [(entryId: String, attemptCount: Int, nextRetry: Date)] {
        return retryQueue.map { entryId, state in
            (entryId: entryId, attemptCount: state.attemptCount, nextRetry: state.nextRetryTime)
        }
    }
    
    /// Clear all pending retries (for testing or emergency)
    /// - Returns: Number of retries cleared
    func clearRetries() -> Int {
        let count = retryQueue.count
        retryQueue.removeAll()
        logWarning("Cleared \(count) pending retries")
        return count
    }
    
    /// Force retry all pending operations immediately (for testing)
    func forceRetryAll() async {
        logInfo("Forcing immediate retry of all pending operations")
        
        // Update all retry times to now
        for (entryId, var state) in retryQueue {
            state.nextRetryTime = Date()
            retryQueue[entryId] = state
        }
        
        // Execute retries
        await executeRetries()
    }
    
    // MARK: - Logging
    
    /// Log informational message
    /// - Parameter message: The message to log
    private func logInfo(_ message: String) {
        // In production, this would use a proper logging framework
        print("[RetryManager] INFO: \(message)")
    }
    
    /// Log warning message
    /// - Parameter message: The message to log
    private func logWarning(_ message: String) {
        // In production, this would use a proper logging framework
        print("[RetryManager] WARNING: \(message)")
    }
    
    /// Log error message
    /// - Parameter message: The message to log
    private func logError(_ message: String) {
        // In production, this would use a proper logging framework
        print("[RetryManager] ERROR: \(message)")
    }
}

// MARK: - Retry State

/// Internal state for tracking retry operations
private struct RetryState {
    /// The sync operation to retry
    let operation: LocalSyncOperation
    
    /// Number of retry attempts so far
    var attemptCount: Int
    
    /// The last error that occurred
    var lastError: Error
    
    /// When the next retry should occur
    var nextRetryTime: Date
}
