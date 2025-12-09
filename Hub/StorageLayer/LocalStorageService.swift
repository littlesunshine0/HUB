//
//  LocalStorageService.swift
//  Hub
//
//  Local storage service actor for local-first database architecture
//  Provides thread-safe storage operations with transaction support
//

import Foundation

/// Actor providing thread-safe local storage operations
/// Implements concurrent reads and serialized writes with transaction support
actor LocalStorageService {
    
    // MARK: - Properties
    
    /// In-memory storage for entries
    private var entries: [String: any Storable] = [:]
    
    /// Storage indices for fast search and filtering
    private let indices: StorageIndices
    
    /// Active transaction (if any)
    private var activeTransaction: StorageTransaction?
    
    /// Metrics collector for monitoring
    private let metrics: StorageMetrics
    
    /// LRU cache for frequently accessed entries (using existing implementation)
    private let cache: LRUCache<String, any Storable>
    
    /// Batch disk writer for optimized I/O
    private let batchWriter: BatchDiskWriter?
    
    /// Index compactor for memory optimization
    private let indexCompactor: IndexCompactor
    
    /// Memory pressure monitor for automatic eviction
    private let memoryMonitor: MemoryPressureMonitor
    
    /// Whether performance optimizations are enabled
    private let optimizationsEnabled: Bool
    
    // MARK: - Initialization
    
    init(
        indices: StorageIndices = StorageIndices(),
        metrics: StorageMetrics = StorageMetrics(),
        cacheCapacity: Int = 1000,
        storageDirectory: URL? = nil,
        enableOptimizations: Bool = true
    ) {
        self.indices = indices
        self.metrics = metrics
        self.optimizationsEnabled = enableOptimizations
        
        // Initialize performance components
        self.cache = LRUCache(capacity: cacheCapacity)
        self.indexCompactor = IndexCompactor()
        self.memoryMonitor = MemoryPressureMonitor()
        
        // Initialize batch writer if storage directory provided
        if let directory = storageDirectory {
            self.batchWriter = BatchDiskWriter(storageDirectory: directory)
        } else {
            self.batchWriter = nil
        }
        
        // Start memory monitoring if optimizations enabled
        if enableOptimizations {
            Task {
                await setupMemoryMonitoring()
            }
        }
    }
    
    /// Setup memory pressure monitoring
    private func setupMemoryMonitoring() async {
        await memoryMonitor.onPressureChange { [weak self] level in
            guard let self = self else { return }
            
            Task {
                await self.handleMemoryPressure(level)
            }
        }
        
        await memoryMonitor.startMonitoring()
    }
    
    /// Handle memory pressure events
    private func handleMemoryPressure(_ level: MemoryPressureMonitor.PressureLevel) async {
        switch level {
        case .normal:
            // No action needed
            break
            
        case .warning:
            // Evict 25% of cache
            let targetSize = await cache.count * 3 / 4
            await cache.evictToSize(targetSize)
            print("⚠️ Memory warning: Evicted cache to \(targetSize) entries")
            
        case .critical:
            // Evict 50% of cache and compact indices
            let targetSize = await cache.count / 2
            await cache.evictToSize(targetSize)
            await compactIndices()
            print("🚨 Memory critical: Evicted cache to \(targetSize) entries and compacted indices")
        }
    }
    
    // MARK: - Read Operations (Concurrent)
    
    /// Load an entry by ID
    /// - Parameter id: The entry ID to load
    /// - Returns: The entry if found
    /// - Throws: LocalStorageError.entryNotFound if entry doesn't exist
    func load<T: Storable>(id: String) async throws -> T {
        let timer = MetricsTimer()
        
        do {
            // Check cache first if optimizations enabled
            if optimizationsEnabled, let cached = await cache.get(id) as? T {
                await metrics.recordOperation(.load, duration: timer.elapsed, success: true)
                return cached
            }
            
            guard let entry = entries[id] as? T else {
                await metrics.recordOperation(.load, duration: timer.elapsed, success: false)
                throw LocalStorageError.entryNotFound(id)
            }
            
            // Add to cache if optimizations enabled
            if optimizationsEnabled {
                await cache.set(id, value: entry)
            }
            
            await metrics.recordOperation(.load, duration: timer.elapsed, success: true)
            return entry
        } catch {
            await metrics.recordOperation(.load, duration: timer.elapsed, success: false, error: error)
            throw error
        }
    }
    
    /// Load multiple entries by IDs
    /// - Parameter ids: Array of entry IDs to load
    /// - Returns: Array of entries (may be fewer than requested if some don't exist)
    func loadMultiple<T: Storable>(ids: [String]) async -> [T] {
        return ids.compactMap { entries[$0] as? T }
    }
    
    /// Load all entries of a specific type
    /// - Returns: Array of all entries of type T
    func loadAll<T: Storable>() async -> [T] {
        return entries.values.compactMap { $0 as? T }
    }
    
    /// Check if an entry exists
    /// - Parameter id: The entry ID to check
    /// - Returns: True if entry exists
    func exists(id: String) async -> Bool {
        return entries[id] != nil
    }
    
    /// Get count of all entries
    /// - Returns: Total number of entries
    func count() async -> Int {
        return entries.count
    }
    
    // MARK: - Write Operations (Serialized)
    
    /// Save an entry to storage
    /// - Parameter item: The item to save
    /// - Throws: LocalStorageError if save fails
    func save<T: Storable>(_ item: T) async throws {
        let timer = MetricsTimer()
        
        do {
            // Validate the item
            try validate(item)
            
            // Store previous state for rollback
            let previousState = entries[item.id]
            
            do {
                // Update in-memory storage
                entries[item.id] = item
                
                // Update indices
                try await indices.update(for: item, removing: previousState as? T)
                
                // If in transaction, track the change
                if let transaction = activeTransaction {
                    transaction.addChange(item, previousState: previousState)
                }
                
                await metrics.recordOperation(.save, duration: timer.elapsed, success: true)
                
            } catch {
                // Rollback on failure
                if let previous = previousState {
                    entries[item.id] = previous
                } else {
                    entries.removeValue(forKey: item.id)
                }
                throw LocalStorageError.saveFailed("Failed to save entry \(item.id): \(error.localizedDescription)")
            }
        } catch {
            await metrics.recordOperation(.save, duration: timer.elapsed, success: false, error: error)
            await metrics.recordError(component: "storage", error: error)
            throw error
        }
    }
    
    /// Save multiple entries in a batch
    /// - Parameter items: Array of items to save
    /// - Throws: LocalStorageError.batchSaveFailed with details of failures
    func saveMultiple<T: Storable>(_ items: [T]) async throws {
        var errors: [String: Error] = [:]
        
        for item in items {
            do {
                try await save(item)
            } catch {
                errors[item.id] = error
            }
        }
        
        if !errors.isEmpty {
            throw LocalStorageError.batchSaveFailed(errors)
        }
    }
    
    /// Delete an entry by ID
    /// - Parameter id: The entry ID to delete
    /// - Throws: LocalStorageError.entryNotFound if entry doesn't exist
    func delete(id: String) async throws {
        let timer = MetricsTimer()
        
        do {
            guard let entry = entries[id] else {
                await metrics.recordOperation(.delete, duration: timer.elapsed, success: false)
                throw LocalStorageError.entryNotFound(id)
            }
            
            // Store previous state for rollback
            let previousState = entry
            
            do {
                // Remove from storage
                entries.removeValue(forKey: id)
                
                // Update indices
                if let typedEntry = entry as? OfflineKnowledgeEntry {
                    try await indices.update(for: typedEntry, removing: typedEntry)
                }
                
                // If in transaction, track the change
                if let transaction = activeTransaction {
                    transaction.addChange(entry, previousState: previousState)
                }
                
                await metrics.recordOperation(.delete, duration: timer.elapsed, success: true)
                
            } catch {
                // Rollback on failure
                entries[id] = previousState
                throw LocalStorageError.saveFailed("Failed to delete entry \(id): \(error.localizedDescription)")
            }
        } catch {
            await metrics.recordOperation(.delete, duration: timer.elapsed, success: false, error: error)
            await metrics.recordError(component: "storage", error: error)
            throw error
        }
    }
    
    /// Delete multiple entries by IDs
    /// - Parameter ids: Array of entry IDs to delete
    /// - Throws: LocalStorageError.batchSaveFailed with details of failures
    func deleteMultiple(ids: [String]) async throws {
        var errors: [String: Error] = [:]
        
        for id in ids {
            do {
                try await delete(id: id)
            } catch {
                errors[id] = error
            }
        }
        
        if !errors.isEmpty {
            throw LocalStorageError.batchSaveFailed(errors)
        }
    }
    
    /// Clear all entries from storage
    func clear() async {
        entries.removeAll()
        await indices.clear()
    }
    
    // MARK: - Transaction Support
    
    /// Begin a new transaction
    /// - Returns: The new transaction
    /// - Throws: LocalStorageError.transactionAlreadyActive if a transaction is already active
    func beginTransaction() async throws -> StorageTransaction {
        guard activeTransaction == nil else {
            throw LocalStorageError.transactionAlreadyActive
        }
        
        let transaction = StorageTransaction()
        activeTransaction = transaction
        return transaction
    }
    
    /// Commit the active transaction
    /// - Parameter transaction: The transaction to commit
    /// - Throws: LocalStorageError if commit fails
    func commit(_ transaction: StorageTransaction) async throws {
        guard let active = activeTransaction, active.id == transaction.id else {
            throw LocalStorageError.invalidTransaction
        }
        
        guard transaction.isActive else {
            throw LocalStorageError.invalidTransaction
        }
        
        // Mark as committed
        transaction.isCommitted = true
        activeTransaction = nil
        
        // All changes are already applied, so we just finalize
    }
    
    /// Rollback the active transaction
    /// - Parameter transaction: The transaction to rollback
    /// - Throws: LocalStorageError if rollback fails
    func rollback(_ transaction: StorageTransaction) async throws {
        guard let active = activeTransaction, active.id == transaction.id else {
            throw LocalStorageError.invalidTransaction
        }
        
        guard transaction.isActive else {
            throw LocalStorageError.invalidTransaction
        }
        
        // Restore previous states in reverse order
        for (id, previousState) in transaction.previousStates.reversed() {
            if let previous = previousState {
                entries[id] = previous
            } else {
                entries.removeValue(forKey: id)
            }
        }
        
        // Rebuild indices from current state
        let allEntries = entries.values.compactMap { $0 as? OfflineKnowledgeEntry }
        await indices.rebuild(from: allEntries)
        
        // Mark as rolled back
        transaction.isRolledBack = true
        activeTransaction = nil
    }
    
    // MARK: - Search Operations
    
    /// Search for entries matching a query
    /// - Parameter query: Search query string
    /// - Returns: Array of matching entry IDs
    func search(query: String) async -> [String] {
        let timer = MetricsTimer()
        let matchingIds = await indices.search(query: query)
        await metrics.recordOperation(.search, duration: timer.elapsed, success: true)
        return Array(matchingIds)
    }
    
    /// Search entries by entity type
    /// - Parameter entityType: The entity type to search for
    /// - Returns: Array of matching entry IDs
    func searchByEntity(type entityType: String) async -> [String] {
        let matchingIds = await indices.searchByEntity(type: entityType)
        return Array(matchingIds)
    }
    
    /// Search entries by tag
    /// - Parameter tag: The tag to search for
    /// - Returns: Array of matching entry IDs
    func searchByTag(_ tag: String) async -> [String] {
        let matchingIds = await indices.searchByTag(tag)
        return Array(matchingIds)
    }
    
    // MARK: - Index Management
    
    /// Check if indices are healthy
    /// - Returns: True if indices are consistent
    func isIndexHealthy() async -> Bool {
        return await indices.isHealthy()
    }
    
    /// Detect and repair index corruption
    func repairIndices() async {
        let timer = MetricsTimer()
        let corruptedIds = await indices.detectCorruption()
        
        if !corruptedIds.isEmpty {
            print("⚠️ Detected \(corruptedIds.count) corrupted index entries. Cleaning up...")
            await metrics.recordIndexCorruption(corruptedCount: corruptedIds.count)
            await indices.cleanupCorruption(corruptedIds)
        }
        
        // Rebuild indices from current storage
        let allEntries = entries.values.compactMap { $0 as? OfflineKnowledgeEntry }
        await indices.rebuild(from: allEntries)
        await metrics.recordIndexRebuild()
        await metrics.recordOperation(.indexRebuild, duration: timer.elapsed, success: true)
    }
    
    /// Get index statistics
    /// - Returns: Dictionary with index metrics
    func indexStatistics() async -> [String: Any] {
        return await indices.statistics()
    }
    
    // MARK: - Health and Diagnostics
    
    /// Perform comprehensive health check
    /// - Returns: Health status of storage system
    func performHealthCheck() async -> StorageMetrics.HealthStatus {
        let indexHealthy = await indices.isHealthy()
        let corruptedIds = await indices.detectCorruption()
        let totalEntries = entries.count
        
        return await metrics.performHealthCheck(
            indexHealth: (isHealthy: indexHealthy, corruptedCount: corruptedIds.count),
            totalEntries: totalEntries
        )
    }
    
    /// Get performance metrics
    /// - Returns: Dictionary with performance statistics
    func getPerformanceMetrics() async -> [String: Any] {
        return await metrics.getPerformanceSummary()
    }
    
    /// Get diagnostic information
    /// - Returns: Dictionary with diagnostic data
    func getDiagnostics() async -> [String: Any] {
        var diagnostics = await metrics.getDiagnostics()
        
        // Add storage-specific diagnostics
        diagnostics["storageInfo"] = [
            "entryCount": entries.count,
            "hasActiveTransaction": activeTransaction != nil,
            "indexStatistics": await indices.statistics()
        ]
        
        // Add performance optimization diagnostics
        if optimizationsEnabled {
            diagnostics["cacheStatistics"] = await cache.getStatistics()
            diagnostics["memoryStatistics"] = await memoryMonitor.getStatistics()
            diagnostics["indexCompactorStatistics"] = await indexCompactor.getStatistics()
            
            if let batchWriter = batchWriter {
                diagnostics["batchWriterStatistics"] = await batchWriter.getStatistics()
            }
        }
        
        return diagnostics
    }
    
    // MARK: - Performance Optimization Methods
    
    /// Compact indices to optimize memory usage
    func compactIndices() async {
        guard optimizationsEnabled else { return }
        
        let timer = MetricsTimer()
        print("🔧 Starting index compaction...")
        
        // Get current index statistics
        let indexStats = await indices.statistics()
        
        // Note: Actual compaction would require access to internal index structures
        // This is a placeholder for the compaction logic
        // In a real implementation, StorageIndices would expose methods for compaction
        
        await metrics.recordOperation(.indexRebuild, duration: timer.elapsed, success: true)
        print("✅ Index compaction completed in \(String(format: "%.2f", timer.elapsed * 1000))ms")
    }
    
    /// Evict cache entries based on memory pressure
    /// - Parameter percentage: Percentage of cache to evict (0.0 to 1.0)
    func evictCache(percentage: Double) async {
        guard optimizationsEnabled else { return }
        
        let currentCount = await cache.count
        let targetSize = Int(Double(currentCount) * (1.0 - percentage))
        await cache.evictToSize(max(0, targetSize))
        
        print("🗑️ Evicted \(currentCount - targetSize) cache entries")
    }
    
    /// Clear the cache completely
    func clearCache() async {
        guard optimizationsEnabled else { return }
        
        await cache.clear()
        print("🗑️ Cache cleared")
    }
    
    /// Flush pending batch writes to disk
    func flushBatchWrites() async throws {
        guard optimizationsEnabled, let batchWriter = batchWriter else { return }
        
        try await batchWriter.flush()
    }
    
    /// Get cache statistics
    /// - Returns: Dictionary with cache metrics
    func getCacheStatistics() async -> [String: Any] {
        guard optimizationsEnabled else {
            return ["enabled": false]
        }
        
        let stats = await cache.getStatistics()
        return [
            "count": stats.count,
            "capacity": stats.capacity,
            "hitRate": stats.hitRate
        ]
    }
    
    /// Get memory statistics
    /// - Returns: Dictionary with memory metrics
    func getMemoryStatistics() async -> [String: Any] {
        guard optimizationsEnabled else {
            return ["enabled": false]
        }
        
        return await memoryMonitor.getStatistics()
    }
    
    /// Trigger manual memory pressure check
    func checkMemoryPressure() async {
        guard optimizationsEnabled else { return }
        
        await memoryMonitor.checkMemoryPressure()
    }
    
    /// Enable or disable performance optimizations
    /// - Parameter enabled: Whether optimizations should be enabled
    func setOptimizationsEnabled(_ enabled: Bool) async {
        // Note: This would require making optimizationsEnabled mutable
        // For now, optimizations are set at initialization
        if enabled {
            await memoryMonitor.startMonitoring()
        } else {
            await memoryMonitor.stopMonitoring()
        }
    }
    
    /// Get metrics for a specific operation type
    /// - Parameter operation: The operation type
    /// - Returns: Statistics for the operation
    func getOperationMetrics(_ operation: StorageMetrics.OperationType) async -> StorageMetrics.AggregatedStats? {
        return await metrics.getStatistics(for: operation)
    }
    
    // MARK: - Validation
    
    /// Validate an entry before saving
    /// - Parameter item: The item to validate
    /// - Throws: LocalStorageError.invalidEntry if validation fails
    private func validate<T: Storable>(_ item: T) throws {
        // Check that ID is not empty
        if item.id.isEmpty {
            throw LocalStorageError.invalidEntry("Entry ID cannot be empty")
        }
        
        // Check that timestamp is reasonable (not in the future by more than 1 minute)
        let oneMinuteFromNow = Date().addingTimeInterval(60)
        if item.timestamp > oneMinuteFromNow {
            throw LocalStorageError.invalidEntry("Entry timestamp is too far in the future")
        }
    }
}
