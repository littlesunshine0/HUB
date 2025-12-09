//
//  BatchDiskWriter.swift
//  Hub
//
//  Batch disk write optimization for improved I/O performance
//  Collects multiple write operations and flushes them together
//

import Foundation

/// Batch disk writer for optimizing disk I/O operations
actor BatchDiskWriter {
    
    // MARK: - Batch Entry
    
    /// Represents a pending write operation
    private struct PendingWrite: Sendable {
        let id: String
        let data: Data
        let timestamp: Date
    }
    
    // MARK: - Properties
    
    /// Pending writes waiting to be flushed
    private var pendingWrites: [String: PendingWrite] = [:]
    
    /// Maximum number of writes to batch before auto-flush
    private let batchSize: Int
    
    /// Maximum time to wait before auto-flush (in seconds)
    private let flushInterval: TimeInterval
    
    /// Last flush time
    private var lastFlushTime: Date = Date()
    
    /// File manager for disk operations
    private let fileManager: FileManager
    
    /// Base directory for storage
    private let storageDirectory: URL
    
    /// Whether auto-flush is enabled
    private var autoFlushEnabled: Bool = true
    
    /// Statistics
    private var totalWrites: Int = 0
    private var totalFlushes: Int = 0
    private var totalBytesWritten: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize batch disk writer
    /// - Parameters:
    ///   - storageDirectory: Base directory for storage files
    ///   - batchSize: Maximum writes before auto-flush (default: 10)
    ///   - flushInterval: Maximum seconds before auto-flush (default: 5.0)
    init(
        storageDirectory: URL,
        batchSize: Int = 10,
        flushInterval: TimeInterval = 5.0
    ) {
        self.storageDirectory = storageDirectory
        self.batchSize = max(1, batchSize)
        self.flushInterval = max(0.1, flushInterval)
        self.fileManager = FileManager.default
        
        // Ensure storage directory exists
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Write Operations
    
    /// Queue a write operation
    /// - Parameters:
    ///   - data: Data to write
    ///   - id: Identifier for the write (used as filename)
    func queueWrite(data: Data, forId id: String) async throws {
        let write = PendingWrite(id: id, data: data, timestamp: Date())
        pendingWrites[id] = write
        totalWrites += 1
        
        // Check if we should auto-flush
        if autoFlushEnabled && shouldFlush() {
            try await flush()
        }
    }
    
    /// Flush all pending writes to disk
    /// - Throws: Error if disk write fails
    func flush() async throws {
        guard !pendingWrites.isEmpty else { return }
        
        let writes = pendingWrites
        pendingWrites.removeAll()
        lastFlushTime = Date()
        totalFlushes += 1
        
        // Write all pending entries
        var errors: [String: Error] = [:]
        
        for (id, write) in writes {
            do {
                let fileURL = storageDirectory.appendingPathComponent("\(id).json")
                
                // Atomic write to prevent corruption
                try write.data.write(to: fileURL, options: .atomic)
                totalBytesWritten += write.data.count
                
            } catch {
                errors[id] = error
            }
        }
        
        if !errors.isEmpty {
            throw LocalStorageError.batchSaveFailed(errors)
        }
    }
    
    /// Force flush without checking conditions
    func forceFlush() async throws {
        try await flush()
    }
    
    // MARK: - Flush Control
    
    /// Check if we should flush based on batch size or time
    private func shouldFlush() -> Bool {
        // Flush if batch size reached
        if pendingWrites.count >= batchSize {
            return true
        }
        
        // Flush if flush interval elapsed
        let timeSinceLastFlush = Date().timeIntervalSince(lastFlushTime)
        if timeSinceLastFlush >= flushInterval {
            return true
        }
        
        return false
    }
    
    /// Enable or disable auto-flush
    /// - Parameter enabled: Whether auto-flush should be enabled
    func setAutoFlush(enabled: Bool) {
        autoFlushEnabled = enabled
    }
    
    // MARK: - Statistics
    
    /// Get batch writer statistics
    /// - Returns: Dictionary with metrics
    func getStatistics() -> [String: Any] {
        let avgBatchSize = totalFlushes > 0 ? Double(totalWrites) / Double(totalFlushes) : 0.0
        let avgBytesPerWrite = totalWrites > 0 ? Double(totalBytesWritten) / Double(totalWrites) : 0.0
        
        return [
            "pendingWrites": pendingWrites.count,
            "totalWrites": totalWrites,
            "totalFlushes": totalFlushes,
            "totalBytesWritten": totalBytesWritten,
            "averageBatchSize": avgBatchSize,
            "averageBytesPerWrite": avgBytesPerWrite,
            "timeSinceLastFlush": Date().timeIntervalSince(lastFlushTime)
        ]
    }
    
    /// Reset statistics
    func resetStatistics() {
        totalWrites = 0
        totalFlushes = 0
        totalBytesWritten = 0
    }
    
    /// Get count of pending writes
    func getPendingCount() -> Int {
        return pendingWrites.count
    }
}

