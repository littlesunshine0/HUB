//
//  StorageConfiguration.swift
//  Hub
//
//  Configuration and feature flags for local-first storage system
//  Provides centralized configuration for storage URLs, CloudKit, and sync behavior
//

import Foundation

/// Configuration for the local-first storage system
/// Provides centralized control over storage behavior, CloudKit integration, and feature flags
public struct StorageConfiguration {
    
    // MARK: - Storage URLs
    
    /// URL for local file storage
    /// If nil, uses default location in Documents directory
    public let storageURL: URL?
    
    /// URL for cache directory
    /// If nil, uses default location in Caches directory
    public let cacheURL: URL?
    
    /// URL for temporary storage
    /// If nil, uses system temporary directory
    public let temporaryURL: URL?
    
    // MARK: - Feature Flags
    
    /// Whether the new local-first storage system is enabled
    /// When false, falls back to legacy storage implementation
    public let localFirstStorageEnabled: Bool
    
    /// Whether performance optimizations are enabled
    /// Includes LRU cache, batch writes, index compaction, and memory monitoring
    public let performanceOptimizationsEnabled: Bool
    
    /// Whether automatic index repair is enabled
    /// When true, corrupted indices are automatically detected and rebuilt
    public let autoIndexRepairEnabled: Bool
    
    /// Whether storage metrics collection is enabled
    /// When true, collects detailed performance and health metrics
    public let metricsEnabled: Bool
    
    // MARK: - CloudKit Configuration
    
    /// Whether CloudKit synchronization is enabled
    /// When false, operates in local-only mode
    public let cloudKitEnabled: Bool
    
    /// CloudKit container identifier
    /// Required when cloudKitEnabled is true
    public let cloudKitContainerIdentifier: String?
    
    /// Whether to use CloudKit public database
    /// When false, uses private database (requires authentication)
    public let usePublicDatabase: Bool
    
    /// Whether to automatically sync on save
    /// When false, sync must be triggered manually
    public let autoSyncEnabled: Bool
    
    // MARK: - Sync Intervals
    
    /// Interval between CloudKit availability checks (in seconds)
    /// Default: 300 seconds (5 minutes)
    public let availabilityCheckInterval: TimeInterval
    
    /// Interval between automatic sync operations (in seconds)
    /// Only used when autoSyncEnabled is true
    /// Default: 60 seconds (1 minute)
    public let syncInterval: TimeInterval
    
    /// Maximum time to wait for sync operation before timeout (in seconds)
    /// Default: 30 seconds
    public let syncTimeout: TimeInterval
    
    /// Interval between retry attempts for failed sync operations (in seconds)
    /// Uses exponential backoff starting from this value
    /// Default: 5 seconds
    public let retryInterval: TimeInterval
    
    /// Maximum number of retry attempts for failed sync operations
    /// Default: 3 attempts
    public let maxRetryAttempts: Int
    
    // MARK: - Performance Tuning
    
    /// Maximum number of entries to keep in LRU cache
    /// Default: 1000 entries
    public let cacheCapacity: Int
    
    /// Maximum number of operations to batch before writing to disk
    /// Default: 10 operations
    public let batchWriteSize: Int
    
    /// Interval between batch write flushes (in seconds)
    /// Default: 5 seconds
    public let batchWriteInterval: TimeInterval
    
    /// Memory pressure threshold for cache eviction (0.0 to 1.0)
    /// Default: 0.8 (80% memory usage)
    public let memoryPressureThreshold: Double
    
    /// Percentage of cache to evict when memory pressure is high (0.0 to 1.0)
    /// Default: 0.25 (25% of cache)
    public let cacheEvictionPercentage: Double
    
    // MARK: - Initialization
    
    /// Initialize with custom configuration
    public init(
        storageURL: URL? = nil,
        cacheURL: URL? = nil,
        temporaryURL: URL? = nil,
        localFirstStorageEnabled: Bool = true,
        performanceOptimizationsEnabled: Bool = true,
        autoIndexRepairEnabled: Bool = true,
        metricsEnabled: Bool = true,
        cloudKitEnabled: Bool = false,
        cloudKitContainerIdentifier: String? = nil,
        usePublicDatabase: Bool = true,
        autoSyncEnabled: Bool = true,
        availabilityCheckInterval: TimeInterval = 300,
        syncInterval: TimeInterval = 60,
        syncTimeout: TimeInterval = 30,
        retryInterval: TimeInterval = 5,
        maxRetryAttempts: Int = 3,
        cacheCapacity: Int = 1000,
        batchWriteSize: Int = 10,
        batchWriteInterval: TimeInterval = 5,
        memoryPressureThreshold: Double = 0.8,
        cacheEvictionPercentage: Double = 0.25
    ) {
        self.storageURL = storageURL
        self.cacheURL = cacheURL
        self.temporaryURL = temporaryURL
        self.localFirstStorageEnabled = localFirstStorageEnabled
        self.performanceOptimizationsEnabled = performanceOptimizationsEnabled
        self.autoIndexRepairEnabled = autoIndexRepairEnabled
        self.metricsEnabled = metricsEnabled
        self.cloudKitEnabled = cloudKitEnabled
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        self.usePublicDatabase = usePublicDatabase
        self.autoSyncEnabled = autoSyncEnabled
        self.availabilityCheckInterval = availabilityCheckInterval
        self.syncInterval = syncInterval
        self.syncTimeout = syncTimeout
        self.retryInterval = retryInterval
        self.maxRetryAttempts = maxRetryAttempts
        self.cacheCapacity = cacheCapacity
        self.batchWriteSize = batchWriteSize
        self.batchWriteInterval = batchWriteInterval
        self.memoryPressureThreshold = memoryPressureThreshold
        self.cacheEvictionPercentage = cacheEvictionPercentage
    }
    
    // MARK: - Preset Configurations
    
    /// Default production configuration
    /// - Local-first storage enabled
    /// - Performance optimizations enabled
    /// - CloudKit disabled by default (must be explicitly enabled)
    /// - Automatic sync enabled
    public static let production = StorageConfiguration(
        localFirstStorageEnabled: true,
        performanceOptimizationsEnabled: true,
        autoIndexRepairEnabled: true,
        metricsEnabled: true,
        cloudKitEnabled: false,
        autoSyncEnabled: true
    )
    
    /// Development configuration
    /// - Local-first storage enabled
    /// - Performance optimizations enabled
    /// - CloudKit disabled
    /// - Shorter sync intervals for faster testing
    /// - Detailed metrics enabled
    public static let development = StorageConfiguration(
        localFirstStorageEnabled: true,
        performanceOptimizationsEnabled: true,
        autoIndexRepairEnabled: true,
        metricsEnabled: true,
        cloudKitEnabled: false,
        autoSyncEnabled: true,
        availabilityCheckInterval: 60,  // Check every minute
        syncInterval: 30,  // Sync every 30 seconds
        syncTimeout: 10,  // Shorter timeout for faster feedback
        retryInterval: 2,  // Faster retries
        maxRetryAttempts: 5  // More retries for testing
    )
    
    /// Testing configuration
    /// - Local-first storage enabled
    /// - Performance optimizations disabled for deterministic behavior
    /// - CloudKit disabled
    /// - Metrics enabled for test validation
    /// - Custom storage URLs for test isolation
    public static func testing(storageURL: URL? = nil) -> StorageConfiguration {
        return StorageConfiguration(
            storageURL: storageURL,
            localFirstStorageEnabled: true,
            performanceOptimizationsEnabled: false,  // Disable for deterministic tests
            autoIndexRepairEnabled: true,
            metricsEnabled: true,
            cloudKitEnabled: false,
            autoSyncEnabled: false,  // Manual sync control in tests
            cacheCapacity: 100,  // Smaller cache for tests
            batchWriteSize: 5,  // Smaller batches for tests
            batchWriteInterval: 1  // Faster flushes for tests
        )
    }
    
    /// Local-only configuration (no CloudKit)
    /// - Local-first storage enabled
    /// - Performance optimizations enabled
    /// - CloudKit explicitly disabled
    /// - No sync operations
    public static let localOnly = StorageConfiguration(
        localFirstStorageEnabled: true,
        performanceOptimizationsEnabled: true,
        autoIndexRepairEnabled: true,
        metricsEnabled: true,
        cloudKitEnabled: false,
        autoSyncEnabled: false
    )
    
    /// CloudKit-enabled configuration
    /// - Local-first storage enabled
    /// - Performance optimizations enabled
    /// - CloudKit enabled with specified container
    /// - Automatic sync enabled
    /// - Parameters:
    ///   - containerIdentifier: CloudKit container identifier
    ///   - usePublicDatabase: Whether to use public database (default: true)
    public static func withCloudKit(
        containerIdentifier: String,
        usePublicDatabase: Bool = true
    ) -> StorageConfiguration {
        return StorageConfiguration(
            localFirstStorageEnabled: true,
            performanceOptimizationsEnabled: true,
            autoIndexRepairEnabled: true,
            metricsEnabled: true,
            cloudKitEnabled: true,
            cloudKitContainerIdentifier: containerIdentifier,
            usePublicDatabase: usePublicDatabase,
            autoSyncEnabled: true
        )
    }
    
    /// Legacy storage configuration (for migration period)
    /// - Local-first storage disabled
    /// - Falls back to legacy storage implementation
    /// - CloudKit disabled
    public static let legacy = StorageConfiguration(
        localFirstStorageEnabled: false,
        performanceOptimizationsEnabled: false,
        autoIndexRepairEnabled: false,
        metricsEnabled: false,
        cloudKitEnabled: false,
        autoSyncEnabled: false
    )
    
    // MARK: - Validation
    
    /// Validate the configuration
    /// - Returns: Array of validation errors (empty if valid)
    public func validate() -> [String] {
        var errors: [String] = []
        
        // CloudKit validation
        if cloudKitEnabled && cloudKitContainerIdentifier == nil {
            errors.append("CloudKit is enabled but no container identifier provided")
        }
        
        if !cloudKitEnabled && cloudKitContainerIdentifier != nil {
            errors.append("CloudKit container identifier provided but CloudKit is disabled")
        }
        
        // Interval validation
        if availabilityCheckInterval <= 0 {
            errors.append("Availability check interval must be positive")
        }
        
        if syncInterval <= 0 {
            errors.append("Sync interval must be positive")
        }
        
        if syncTimeout <= 0 {
            errors.append("Sync timeout must be positive")
        }
        
        if retryInterval <= 0 {
            errors.append("Retry interval must be positive")
        }
        
        if maxRetryAttempts < 0 {
            errors.append("Max retry attempts cannot be negative")
        }
        
        // Performance tuning validation
        if cacheCapacity <= 0 {
            errors.append("Cache capacity must be positive")
        }
        
        if batchWriteSize <= 0 {
            errors.append("Batch write size must be positive")
        }
        
        if batchWriteInterval <= 0 {
            errors.append("Batch write interval must be positive")
        }
        
        if memoryPressureThreshold < 0 || memoryPressureThreshold > 1 {
            errors.append("Memory pressure threshold must be between 0 and 1")
        }
        
        if cacheEvictionPercentage < 0 || cacheEvictionPercentage > 1 {
            errors.append("Cache eviction percentage must be between 0 and 1")
        }
        
        return errors
    }
    
    /// Check if configuration is valid
    /// - Returns: True if configuration is valid
    public var isValid: Bool {
        return validate().isEmpty
    }
    
    // MARK: - Computed Properties
    
    /// Get the effective storage directory URL
    /// Returns configured URL or default Documents directory
    public var effectiveStorageURL: URL {
        if let url = storageURL {
            return url
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("KnowledgeEntries")
    }
    
    /// Get the effective cache directory URL
    /// Returns configured URL or default Caches directory
    public var effectiveCacheURL: URL {
        if let url = cacheURL {
            return url
        }
        
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesPath.appendingPathComponent("StorageCache")
    }
    
    /// Get the effective temporary directory URL
    /// Returns configured URL or system temporary directory
    public var effectiveTemporaryURL: URL {
        if let url = temporaryURL {
            return url
        }
        
        return FileManager.default.temporaryDirectory.appendingPathComponent("StorageTemp")
    }
    
    // MARK: - Description
    
    /// Human-readable description of configuration
    public var description: String {
        var lines: [String] = []
        
        lines.append("Storage Configuration:")
        lines.append("  Local-First Storage: \(localFirstStorageEnabled ? "✅" : "❌")")
        lines.append("  Performance Optimizations: \(performanceOptimizationsEnabled ? "✅" : "❌")")
        lines.append("  Auto Index Repair: \(autoIndexRepairEnabled ? "✅" : "❌")")
        lines.append("  Metrics: \(metricsEnabled ? "✅" : "❌")")
        lines.append("")
        lines.append("CloudKit Configuration:")
        lines.append("  Enabled: \(cloudKitEnabled ? "✅" : "❌")")
        if let identifier = cloudKitContainerIdentifier {
            lines.append("  Container: \(identifier)")
        }
        lines.append("  Database: \(usePublicDatabase ? "Public" : "Private")")
        lines.append("  Auto Sync: \(autoSyncEnabled ? "✅" : "❌")")
        lines.append("")
        lines.append("Sync Intervals:")
        lines.append("  Availability Check: \(Int(availabilityCheckInterval))s")
        lines.append("  Sync: \(Int(syncInterval))s")
        lines.append("  Timeout: \(Int(syncTimeout))s")
        lines.append("  Retry: \(Int(retryInterval))s (max \(maxRetryAttempts) attempts)")
        lines.append("")
        lines.append("Performance Tuning:")
        lines.append("  Cache Capacity: \(cacheCapacity)")
        lines.append("  Batch Write Size: \(batchWriteSize)")
        lines.append("  Batch Write Interval: \(Int(batchWriteInterval))s")
        lines.append("  Memory Threshold: \(Int(memoryPressureThreshold * 100))%")
        lines.append("  Cache Eviction: \(Int(cacheEvictionPercentage * 100))%")
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Configuration Manager

/// Manager for loading and saving storage configuration
/// Provides persistence and runtime configuration management
public class StorageConfigurationManager {
    
    // MARK: - Singleton
    
    /// Shared configuration manager instance
    public static let shared = StorageConfigurationManager()
    
    // MARK: - Properties
    
    /// Current active configuration
    private(set) public var currentConfiguration: StorageConfiguration
    
    /// UserDefaults key for persisted configuration
    private let configurationKey = "com.hub.storage.configuration"
    
    // MARK: - Initialization
    
    private init() {
        // Load persisted configuration or use default
        if let persisted = Self.loadPersistedConfiguration() {
            self.currentConfiguration = persisted
        } else {
            self.currentConfiguration = .production
        }
    }
    
    // MARK: - Configuration Management
    
    /// Update the current configuration
    /// - Parameter configuration: New configuration to apply
    /// - Throws: Error if configuration is invalid
    public func updateConfiguration(_ configuration: StorageConfiguration) throws {
        // Validate configuration
        let errors = configuration.validate()
        guard errors.isEmpty else {
            throw StorageConfigurationError.invalidConfiguration(errors)
        }
        
        // Update current configuration
        self.currentConfiguration = configuration
        
        // Persist to UserDefaults
        Self.persistConfiguration(configuration)
    }
    
    /// Reset to default production configuration
    public func resetToDefault() {
        self.currentConfiguration = .production
        Self.persistConfiguration(.production)
    }
    
    /// Load configuration from UserDefaults
    /// - Returns: Persisted configuration or nil if not found
    private static func loadPersistedConfiguration() -> StorageConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: "com.hub.storage.configuration") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PersistedConfiguration.self, from: data).toConfiguration()
        } catch {
            print("⚠️ Failed to load persisted configuration: \(error)")
            return nil
        }
    }
    
    /// Persist configuration to UserDefaults
    /// - Parameter configuration: Configuration to persist
    private static func persistConfiguration(_ configuration: StorageConfiguration) {
        do {
            let encoder = JSONEncoder()
            let persisted = PersistedConfiguration(from: configuration)
            let data = try encoder.encode(persisted)
            UserDefaults.standard.set(data, forKey: "com.hub.storage.configuration")
        } catch {
            print("⚠️ Failed to persist configuration: \(error)")
        }
    }
}

// MARK: - Persisted Configuration

/// Codable wrapper for StorageConfiguration
/// Used for persisting configuration to UserDefaults
private struct PersistedConfiguration: Codable {
    let localFirstStorageEnabled: Bool
    let performanceOptimizationsEnabled: Bool
    let autoIndexRepairEnabled: Bool
    let metricsEnabled: Bool
    let cloudKitEnabled: Bool
    let cloudKitContainerIdentifier: String?
    let usePublicDatabase: Bool
    let autoSyncEnabled: Bool
    let availabilityCheckInterval: TimeInterval
    let syncInterval: TimeInterval
    let syncTimeout: TimeInterval
    let retryInterval: TimeInterval
    let maxRetryAttempts: Int
    let cacheCapacity: Int
    let batchWriteSize: Int
    let batchWriteInterval: TimeInterval
    let memoryPressureThreshold: Double
    let cacheEvictionPercentage: Double
    
    init(from config: StorageConfiguration) {
        self.localFirstStorageEnabled = config.localFirstStorageEnabled
        self.performanceOptimizationsEnabled = config.performanceOptimizationsEnabled
        self.autoIndexRepairEnabled = config.autoIndexRepairEnabled
        self.metricsEnabled = config.metricsEnabled
        self.cloudKitEnabled = config.cloudKitEnabled
        self.cloudKitContainerIdentifier = config.cloudKitContainerIdentifier
        self.usePublicDatabase = config.usePublicDatabase
        self.autoSyncEnabled = config.autoSyncEnabled
        self.availabilityCheckInterval = config.availabilityCheckInterval
        self.syncInterval = config.syncInterval
        self.syncTimeout = config.syncTimeout
        self.retryInterval = config.retryInterval
        self.maxRetryAttempts = config.maxRetryAttempts
        self.cacheCapacity = config.cacheCapacity
        self.batchWriteSize = config.batchWriteSize
        self.batchWriteInterval = config.batchWriteInterval
        self.memoryPressureThreshold = config.memoryPressureThreshold
        self.cacheEvictionPercentage = config.cacheEvictionPercentage
    }
    
    func toConfiguration() -> StorageConfiguration {
        return StorageConfiguration(
            localFirstStorageEnabled: localFirstStorageEnabled,
            performanceOptimizationsEnabled: performanceOptimizationsEnabled,
            autoIndexRepairEnabled: autoIndexRepairEnabled,
            metricsEnabled: metricsEnabled,
            cloudKitEnabled: cloudKitEnabled,
            cloudKitContainerIdentifier: cloudKitContainerIdentifier,
            usePublicDatabase: usePublicDatabase,
            autoSyncEnabled: autoSyncEnabled,
            availabilityCheckInterval: availabilityCheckInterval,
            syncInterval: syncInterval,
            syncTimeout: syncTimeout,
            retryInterval: retryInterval,
            maxRetryAttempts: maxRetryAttempts,
            cacheCapacity: cacheCapacity,
            batchWriteSize: batchWriteSize,
            batchWriteInterval: batchWriteInterval,
            memoryPressureThreshold: memoryPressureThreshold,
            cacheEvictionPercentage: cacheEvictionPercentage
        )
    }
}

// MARK: - Configuration Errors

/// Errors related to storage configuration
public enum StorageConfigurationError: Error, LocalizedError {
    case invalidConfiguration([String])
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let errors):
            return "Invalid configuration: \(errors.joined(separator: ", "))"
        }
    }
}
