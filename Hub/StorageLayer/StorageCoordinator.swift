//
//  StorageCoordinator.swift
//  Hub
//
//  Storage coordinator for local-first database architecture
//  Routes operations to local storage first, then queues CloudKit sync
//

import Foundation
import Combine

/// Main interface for local-first storage with optional CloudKit sync
/// All operations go to local storage first, then sync to CloudKit asynchronously
@MainActor
public class StorageCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current CloudKit sync status
    @Published var syncStatus: CloudSyncStatus = .idle
    
    /// Whether CloudKit is currently available
    @Published var isCloudKitAvailable: Bool = false
    
    // MARK: - Private Properties
    
    /// Local storage service (always available)
    private let localStorage: LocalStorageService
    
    /// Cloud sync service (optional)
    private let cloudSync: CloudSyncService
    
    /// Sync queue for background operations
    private let syncQueue: SyncQueue
    
    /// Storage file manager for disk persistence
    private let fileManager: StorageFileManager
    
    /// Whether CloudKit sync is enabled
    private let cloudKitEnabled: Bool
    
    /// Timer for periodic availability checks
    private var availabilityCheckTimer: Timer?
    
    /// Storage URL for file persistence
    var storageURL: URL? {
        return fileManager.storageDirectory
    }
    
    // MARK: - Initialization
    
    /// Private initializer - use create() factory method instead
    /// - Parameters:
    ///   - localStorage: Local storage service
    ///   - fileManager: File manager for disk persistence
    ///   - cloudSync: Cloud sync service
    ///   - syncQueue: Sync queue for background operations
    ///   - cloudKitEnabled: Whether CloudKit is enabled
    private init(
        localStorage: LocalStorageService,
        fileManager: StorageFileManager,
        cloudSync: CloudSyncService,
        syncQueue: SyncQueue,
        cloudKitEnabled: Bool
    ) {
        self.localStorage = localStorage
        self.fileManager = fileManager
        self.cloudSync = cloudSync
        self.syncQueue = syncQueue
        self.cloudKitEnabled = cloudKitEnabled
        
        // Start monitoring CloudKit availability
        if cloudKitEnabled {
            startAvailabilityMonitoring()
        }
    }
    
    /// Create a new storage coordinator with configuration
    /// - Parameter configuration: Storage configuration (uses current configuration if nil)
    /// - Returns: Initialized storage coordinator
    static func create(configuration: StorageConfiguration? = nil) async throws -> StorageCoordinator {
        // Use provided configuration or current configuration
        let config = configuration ?? StorageConfigurationManager.shared.currentConfiguration
        
        // Validate configuration
        let errors = config.validate()
        guard errors.isEmpty else {
            throw StorageConfigurationError.invalidConfiguration(errors)
        }
        
        // Check if local-first storage is enabled
        guard config.localFirstStorageEnabled else {
            throw StorageConfigurationError.invalidConfiguration(["Local-first storage is disabled"])
        }
        
        // Initialize local storage (always available)
        let indices = StorageIndices()
        let localStorage = LocalStorageService(
            indices: indices,
            cacheCapacity: config.cacheCapacity,
            storageDirectory: config.effectiveStorageURL,
            enableOptimizations: config.performanceOptimizationsEnabled
        )
        
        // Initialize file manager for disk persistence
        let fileManager = try await StorageFileManager(storageDirectory: config.effectiveStorageURL)
        
        // Initialize CloudKit sync (optional)
        let cloudSync = CloudSyncService(
            containerIdentifier: config.cloudKitEnabled ? config.cloudKitContainerIdentifier : nil,
            availabilityCheckInterval: config.availabilityCheckInterval
        )
        
        // Initialize retry manager with configuration
        let retryManager = RetryManager(
            cloudSync: cloudSync,
            maxRetries: config.maxRetryAttempts,
            baseDelay: config.retryInterval,
            maxDelay: config.syncTimeout
        )
        
        // Initialize sync queue
        let syncQueue = SyncQueue(cloudSync: cloudSync, retryManager: retryManager)
        
        return StorageCoordinator(
            localStorage: localStorage,
            fileManager: fileManager,
            cloudSync: cloudSync,
            syncQueue: syncQueue,
            cloudKitEnabled: config.cloudKitEnabled
        )
    }
    
    /// Create a new storage coordinator with optional CloudKit support (legacy method)
    /// - Parameters:
    ///   - storageURL: URL for local file storage (nil for default)
    ///   - cloudKitContainerIdentifier: CloudKit container ID (nil to disable CloudKit)
    /// - Returns: Initialized storage coordinator
    @available(*, deprecated, message: "Use create(configuration:) instead")
    static func create(storageURL: URL? = nil, cloudKitContainerIdentifier: String? = nil) async throws -> StorageCoordinator {
        let config = StorageConfiguration(
            storageURL: storageURL,
            cloudKitEnabled: cloudKitContainerIdentifier != nil,
            cloudKitContainerIdentifier: cloudKitContainerIdentifier
        )
        return try await create(configuration: config)
    }
    
    // MARK: - Save Operations
    
    /// Save an entry to local storage and queue for CloudKit sync
    /// - Parameter item: The item to save
    /// - Throws: LocalStorageError if local save fails
    func save<T: Storable>(_ item: T) async throws {
        // Save to local storage first (fast, always succeeds)
        try await localStorage.save(item)
        
        // Persist to disk asynchronously
        Task.detached(priority: .utility) {
            try? await self.fileManager.persist(item)
        }
        
        // Queue for CloudKit sync (async, non-blocking)
        if cloudKitEnabled && isCloudKitAvailable {
            await syncQueue.enqueue(.save(item))
        }
    }
    
    /// Save multiple entries in a batch
    /// - Parameter items: Array of items to save
    /// - Throws: LocalStorageError if local save fails
    func saveMultiple<T: Storable>(_ items: [T]) async throws {
        // Save to local storage first
        try await localStorage.saveMultiple(items)
        
        // Persist to disk asynchronously
        Task.detached(priority: .utility) {
            for item in items {
                try? await self.fileManager.persist(item)
            }
        }
        
        // Queue for CloudKit sync (async, non-blocking)
        if cloudKitEnabled && isCloudKitAvailable {
            let operations = items.map { LocalSyncOperation.save($0) }
            await syncQueue.enqueueMultiple(operations)
        }
    }
    
    // MARK: - Load Operations
    
    /// Load an entry by ID from local storage
    /// - Parameter id: The entry ID to load
    /// - Returns: The entry if found
    /// - Throws: LocalStorageError.entryNotFound if entry doesn't exist
    func load<T: Storable>(id: String) async throws -> T {
        // Try loading from memory first
        do {
            return try await localStorage.load(id: id)
        } catch LocalStorageError.entryNotFound {
            // Try loading from disk
            if let entry: T = try? await fileManager.load(id: id) {
                // Cache in memory for future access
                try? await localStorage.save(entry)
                return entry
            }
            throw LocalStorageError.entryNotFound(id)
        }
    }
    
    /// Load multiple entries by IDs
    /// - Parameter ids: Array of entry IDs to load
    /// - Returns: Array of entries (may be fewer than requested if some don't exist)
    func loadMultiple<T: Storable>(ids: [String]) async -> [T] {
        // Load from memory
        var entries: [T] = await localStorage.loadMultiple(ids: ids)
        
        // For any missing entries, try loading from disk
        let loadedIds = Set(entries.map { $0.id })
        let missingIds = ids.filter { !loadedIds.contains($0) }
        
        for id in missingIds {
            if let entry: T = try? await fileManager.load(id: id) {
                // Cache in memory
                try? await localStorage.save(entry)
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    /// Load all entries of a specific type
    /// - Returns: Array of all entries of type T
    func loadAll<T: Storable>() async -> [T] {
        // First, ensure all disk entries are loaded into memory
        _ = await loadAllFromDisk()
        
        // Return all from memory
        return await localStorage.loadAll()
    }
    
    /// Check if an entry exists
    /// - Parameter id: The entry ID to check
    /// - Returns: True if entry exists
    func exists(id: String) async -> Bool {
        // Check memory first
        if await localStorage.exists(id: id) {
            return true
        }
        
        // Check disk
        return await fileManager.exists(id: id)
    }
    
    // MARK: - Delete Operations
    
    /// Delete an entry by ID
    /// - Parameter id: The entry ID to delete
    /// - Throws: LocalStorageError if deletion fails
    func delete(id: String) async throws {
        // Delete from local storage
        try await localStorage.delete(id: id)
        
        // Delete from disk asynchronously
        Task.detached(priority: .utility) {
            try? await self.fileManager.delete(id: id)
        }
        
        // Queue for CloudKit deletion (async, non-blocking)
        if cloudKitEnabled && isCloudKitAvailable {
            await syncQueue.enqueue(.delete(id))
        }
    }
    
    /// Delete multiple entries by IDs
    /// - Parameter ids: Array of entry IDs to delete
    /// - Throws: LocalStorageError if deletion fails
    func deleteMultiple(ids: [String]) async throws {
        // Delete from local storage
        try await localStorage.deleteMultiple(ids: ids)
        
        // Delete from disk asynchronously
        Task.detached(priority: .utility) {
            for id in ids {
                try? await self.fileManager.delete(id: id)
            }
        }
        
        // Queue for CloudKit deletion (async, non-blocking)
        if cloudKitEnabled && isCloudKitAvailable {
            let operations = ids.map { LocalSyncOperation.delete($0) }
            await syncQueue.enqueueMultiple(operations)
        }
    }
    
    // MARK: - Search Operations
    
    /// Search for entries matching a query
    /// - Parameter query: Search query string
    /// - Returns: Array of matching entry IDs
    func search(query: String) async -> [String] {
        return await localStorage.search(query: query)
    }
    
    /// Search entries by entity type
    /// - Parameter entityType: The entity type to search for
    /// - Returns: Array of matching entry IDs
    func searchByEntity(type entityType: String) async -> [String] {
        return await localStorage.searchByEntity(type: entityType)
    }
    
    /// Search entries by tag
    /// - Parameter tag: The tag to search for
    /// - Returns: Array of matching entry IDs
    func searchByTag(_ tag: String) async -> [String] {
        return await localStorage.searchByTag(tag)
    }
    
    // MARK: - Transaction Support
    
    /// Begin a new transaction for batch operations
    /// - Returns: The new transaction
    /// - Throws: LocalStorageError.transactionAlreadyActive if a transaction is already active
    func beginTransaction() async throws -> StorageTransaction {
        return try await localStorage.beginTransaction()
    }
    
    /// Commit a transaction
    /// - Parameter transaction: The transaction to commit
    /// - Throws: LocalStorageError if commit fails
    func commit(_ transaction: StorageTransaction) async throws {
        // Commit to local storage
        try await localStorage.commit(transaction)
        
        // Copy changes to avoid actor isolation issues
        let changes = transaction.changes
        
        // Persist all changes to disk asynchronously
        Task.detached(priority: .utility) { [fileManager] in
            for item in changes {
                try? await fileManager.persist(item)
            }
        }
        
        // Queue for CloudKit sync (async, non-blocking)
        if self.cloudKitEnabled && self.isCloudKitAvailable {
            let operations = changes.map { LocalSyncOperation.save($0) }
            await self.syncQueue.enqueueMultiple(operations)
        }
    }
    
    /// Rollback a transaction
    /// - Parameter transaction: The transaction to rollback
    /// - Throws: LocalStorageError if rollback fails
    func rollback(_ transaction: StorageTransaction) async throws {
        try await localStorage.rollback(transaction)
    }
    
    // MARK: - Index Management
    
    /// Check if indices are healthy
    /// - Returns: True if indices are consistent
    func isIndexHealthy() async -> Bool {
        return await localStorage.isIndexHealthy()
    }
    
    /// Repair corrupted indices
    func repairIndices() async {
        await localStorage.repairIndices()
    }
    
    /// Get index statistics
    /// - Returns: Dictionary with index metrics
    func indexStatistics() async -> [String: Any] {
        return await localStorage.indexStatistics()
    }
    
    // MARK: - CloudKit Availability Monitoring
    
    /// Start monitoring CloudKit availability
    private func startAvailabilityMonitoring() {
        // Check immediately
        Task {
            await checkCloudKitAvailability()
        }
        
        // Check periodically (every 5 minutes)
        availabilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkCloudKitAvailability()
            }
        }
    }
    
    /// Check CloudKit availability and update published property
    private func checkCloudKitAvailability() async {
        let available = await cloudSync.isCloudKitAvailable()
        
        // Update on main actor
        await MainActor.run {
            self.isCloudKitAvailable = available
        }
    }
    
    /// Get sync queue statistics
    /// - Returns: Dictionary with sync queue metrics
    func syncQueueStatistics() async -> [String: Int] {
        return await syncQueue.getStatistics()
    }
    
    // MARK: - Monitoring and Observability
    
    /// Perform comprehensive health check on all storage components
    /// - Returns: Health status of the entire storage system
    func performHealthCheck() async -> StorageMetrics.HealthStatus {
        return await localStorage.performHealthCheck()
    }
    
    /// Get performance metrics for storage operations
    /// - Returns: Dictionary with performance statistics
    func getPerformanceMetrics() async -> [String: Any] {
        return await localStorage.getPerformanceMetrics()
    }
    
    /// Get comprehensive diagnostic information
    /// - Returns: Dictionary with diagnostic data from all components
    func getDiagnostics() async -> [String: Any] {
        var diagnostics = await localStorage.getDiagnostics()
        
        // Add coordinator-specific diagnostics
        diagnostics["coordinatorInfo"] = [
            "cloudKitEnabled": cloudKitEnabled,
            "cloudKitAvailable": isCloudKitAvailable,
            "syncStatus": String(describing: syncStatus),
            "syncQueueStats": await syncQueue.getStatistics()
        ]
        
        return diagnostics
    }
    
    /// Get metrics for a specific operation type
    /// - Parameter operation: The operation type
    /// - Returns: Statistics for the operation
    func getOperationMetrics(_ operation: StorageMetrics.OperationType) async -> StorageMetrics.AggregatedStats? {
        return await localStorage.getOperationMetrics(operation)
    }
    
    /// Log current system status (for debugging)
    func logSystemStatus() async {
        print("📊 Storage System Status")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let health = await performHealthCheck()
        print("🏥 Health: \(health.isHealthy ? "✅ Healthy" : "⚠️ Unhealthy")")
        print("   Index: \(health.indexHealth.isHealthy ? "✅" : "⚠️") (\(health.indexHealth.totalEntries) entries, \(health.indexHealth.corruptedEntryCount) corrupted)")
        print("   Storage: \(health.storageHealth.isHealthy ? "✅" : "⚠️") (\(health.storageHealth.errorCount) errors)")
        print("   Sync: \(health.syncHealth.isHealthy ? "✅" : "⚠️") (\(health.syncHealth.errorCount) errors)")
        
        let metrics = await getPerformanceMetrics()
        if let totalOps = metrics["totalOperations"] as? Int,
           let successRate = metrics["successRate"] as? Double {
            print("📈 Operations: \(totalOps) total, \(String(format: "%.1f%%", successRate * 100)) success rate")
        }
        
        if let operationStats = metrics["operationStats"] as? [String: [String: Any]] {
            for (operation, stats) in operationStats.sorted(by: { $0.key < $1.key }) {
                if let count = stats["count"] as? Int,
                   let avgDuration = stats["averageDuration"] as? Double {
                    print("   \(operation): \(count) ops, avg \(String(format: "%.2f", avgDuration * 1000))ms")
                }
            }
        }
        
        let syncStats = await syncQueueStatistics()
        print("☁️ Sync Queue: \(syncStats["queueDepth"] ?? 0) pending, \(syncStats["totalProcessed"] ?? 0) processed")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    // MARK: - Initialization Helper
    
    /// Initialize the coordinator by loading all entries from disk
    func initialize() async throws {
        print("🔄 Initializing StorageCoordinator...")
        
        // Load all entries from disk into memory
        let loadedCount = await loadAllFromDisk()
        print("📚 Loaded \(loadedCount) entries from disk")
        
        // Check index health
        let isHealthy = await localStorage.isIndexHealthy()
        if !isHealthy {
            print("⚠️ Index corruption detected. Repairing...")
            await localStorage.repairIndices()
            print("✅ Index repair complete")
        }
        
        // Check CloudKit availability
        if cloudKitEnabled {
            await checkCloudKitAvailability()
            print("☁️ CloudKit available: \(isCloudKitAvailable)")
        }
        
        print("✅ StorageCoordinator initialization complete")
    }
    
    /// Load all entries from disk into memory
    /// - Returns: Number of entries loaded
    private func loadAllFromDisk() async -> Int {
        do {
            let entries: [OfflineKnowledgeEntry] = try await fileManager.loadAll()
            
            for entry in entries {
                try? await localStorage.save(entry)
            }
            
            return entries.count
        } catch {
            print("⚠️ Failed to load entries from disk: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        availabilityCheckTimer?.invalidate()
    }
}
