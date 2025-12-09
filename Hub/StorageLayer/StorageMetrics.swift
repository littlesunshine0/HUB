//
//  StorageMetrics.swift
//  Hub
//
//  Metrics collection and monitoring for local-first database
//  Tracks operation latency, health status, and performance statistics
//

import Foundation

// MARK: - Storage Metrics

/// Collects and reports metrics for storage operations
actor StorageMetrics {
    
    // MARK: - Metric Types
    
    /// Represents a single operation measurement
    struct OperationMetric: Sendable {
        let operation: OperationType
        let duration: TimeInterval
        let timestamp: Date
        let success: Bool
        let errorType: String?
        
        init(operation: OperationType, duration: TimeInterval, success: Bool, errorType: String? = nil) {
            self.operation = operation
            self.duration = duration
            self.timestamp = Date()
            self.success = success
            self.errorType = errorType
        }
    }
    
    /// Types of storage operations to track
    enum OperationType: String, Sendable {
        case save
        case load
        case delete
        case search
        case transaction
        case indexUpdate
        case indexRebuild
        case diskPersist
        case diskLoad
        case cloudSync
    }
    
    /// Health status of storage components
    struct HealthStatus: Sendable {
        let isHealthy: Bool
        let indexHealth: IndexHealth
        let storageHealth: ComponentHealth
        let syncHealth: ComponentHealth
        let timestamp: Date
        
        struct IndexHealth: Sendable {
            let isHealthy: Bool
            let corruptedEntryCount: Int
            let totalEntries: Int
            let lastRebuildTime: Date?
        }
        
        struct ComponentHealth: Sendable {
            let isHealthy: Bool
            let errorCount: Int
            let lastError: String?
            let lastErrorTime: Date?
        }
    }
    
    // MARK: - Properties
    
    /// Recent operation metrics (last 1000 operations)
    private var recentMetrics: [OperationMetric] = []
    private let maxRecentMetrics = 1000
    
    /// Aggregated statistics by operation type
    private var aggregatedStats: [OperationType: AggregatedStats] = [:]
    
    /// Error counts by type
    private var errorCounts: [String: Int] = [:]
    
    /// Last error by component
    private var lastErrors: [String: (error: String, timestamp: Date)] = [:]
    
    /// Index health tracking
    private var indexCorruptionCount: Int = 0
    private var lastIndexRebuild: Date?
    
    /// Start time for uptime calculation
    private let startTime: Date = Date()
    
    // MARK: - Aggregated Statistics
    
    struct AggregatedStats: Sendable {
        var count: Int = 0
        var totalDuration: TimeInterval = 0
        var minDuration: TimeInterval = .infinity
        var maxDuration: TimeInterval = 0
        var successCount: Int = 0
        var failureCount: Int = 0
        
        var averageDuration: TimeInterval {
            count > 0 ? totalDuration / Double(count) : 0
        }
        
        var successRate: Double {
            count > 0 ? Double(successCount) / Double(count) : 0
        }
        
        mutating func record(duration: TimeInterval, success: Bool) {
            count += 1
            totalDuration += duration
            minDuration = min(minDuration, duration)
            maxDuration = max(maxDuration, duration)
            
            if success {
                successCount += 1
            } else {
                failureCount += 1
            }
        }
    }
    
    // MARK: - Recording Metrics
    
    /// Record an operation metric
    /// - Parameters:
    ///   - operation: Type of operation
    ///   - duration: Duration in seconds
    ///   - success: Whether the operation succeeded
    ///   - error: Optional error if operation failed
    func recordOperation(
        _ operation: OperationType,
        duration: TimeInterval,
        success: Bool,
        error: Error? = nil
    ) {
        let errorType = error.map { String(describing: type(of: $0)) }
        let metric = OperationMetric(
            operation: operation,
            duration: duration,
            success: success,
            errorType: errorType
        )
        
        // Add to recent metrics
        recentMetrics.append(metric)
        if recentMetrics.count > maxRecentMetrics {
            recentMetrics.removeFirst()
        }
        
        // Update aggregated stats
        var stats = aggregatedStats[operation] ?? AggregatedStats()
        stats.record(duration: duration, success: success)
        aggregatedStats[operation] = stats
        
        // Track errors
        if let errorType = errorType {
            errorCounts[errorType, default: 0] += 1
        }
        
        // Log slow operations (>100ms for local operations)
        if duration > 0.1 && operation != .cloudSync {
            print("⚠️ Slow operation: \(operation.rawValue) took \(String(format: "%.2f", duration * 1000))ms")
        }
    }
    
    /// Record an error for a component
    /// - Parameters:
    ///   - component: Component name (e.g., "storage", "index", "sync")
    ///   - error: The error that occurred
    func recordError(component: String, error: Error) {
        let errorDescription = error.localizedDescription
        lastErrors[component] = (errorDescription, Date())
        errorCounts[component, default: 0] += 1
        
        print("❌ Error in \(component): \(errorDescription)")
    }
    
    /// Record index corruption detection
    /// - Parameter corruptedCount: Number of corrupted entries found
    func recordIndexCorruption(corruptedCount: Int) {
        indexCorruptionCount += corruptedCount
        print("⚠️ Index corruption detected: \(corruptedCount) entries")
    }
    
    /// Record index rebuild
    func recordIndexRebuild() {
        lastIndexRebuild = Date()
        print("🔄 Index rebuild completed")
    }
    
    // MARK: - Statistics Retrieval
    
    /// Get statistics for a specific operation type
    /// - Parameter operation: The operation type
    /// - Returns: Statistics for the operation
    func getStatistics(for operation: OperationType) -> AggregatedStats? {
        return aggregatedStats[operation]
    }
    
    /// Get all operation statistics
    /// - Returns: Dictionary of statistics by operation type
    func getAllStatistics() -> [OperationType: AggregatedStats] {
        return aggregatedStats
    }
    
    /// Get recent metrics
    /// - Parameter count: Number of recent metrics to return (default: 100)
    /// - Returns: Array of recent operation metrics
    func getRecentMetrics(count: Int = 100) -> [OperationMetric] {
        let startIndex = max(0, recentMetrics.count - count)
        return Array(recentMetrics[startIndex...])
    }
    
    /// Get error counts
    /// - Returns: Dictionary of error counts by type
    func getErrorCounts() -> [String: Int] {
        return errorCounts
    }
    
    /// Get uptime in seconds
    /// - Returns: Time since metrics started tracking
    func getUptime() -> TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Performance Analysis
    
    /// Calculate percentile for operation duration
    /// - Parameters:
    ///   - operation: Operation type
    ///   - percentile: Percentile to calculate (e.g., 0.95 for p95)
    /// - Returns: Duration at the specified percentile
    func getPercentile(for operation: OperationType, percentile: Double) -> TimeInterval? {
        let operationMetrics = recentMetrics.filter { $0.operation == operation && $0.success }
        guard !operationMetrics.isEmpty else { return nil }
        
        let sortedDurations = operationMetrics.map { $0.duration }.sorted()
        let index = Int(Double(sortedDurations.count) * percentile)
        return sortedDurations[min(index, sortedDurations.count - 1)]
    }
    
    /// Get performance summary
    /// - Returns: Dictionary with key performance metrics
    func getPerformanceSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        // Overall statistics
        let totalOperations = recentMetrics.count
        let successfulOperations = recentMetrics.filter { $0.success }.count
        let failedOperations = totalOperations - successfulOperations
        
        summary["totalOperations"] = totalOperations
        summary["successfulOperations"] = successfulOperations
        summary["failedOperations"] = failedOperations
        summary["successRate"] = totalOperations > 0 ? Double(successfulOperations) / Double(totalOperations) : 0.0
        summary["uptime"] = getUptime()
        
        // Per-operation statistics
        var operationStats: [String: [String: Any]] = [:]
        for (operation, stats) in aggregatedStats {
            operationStats[operation.rawValue] = [
                "count": stats.count,
                "averageDuration": stats.averageDuration,
                "minDuration": stats.minDuration == .infinity ? 0 : stats.minDuration,
                "maxDuration": stats.maxDuration,
                "successRate": stats.successRate
            ]
        }
        summary["operationStats"] = operationStats
        
        // Percentiles for key operations
        if let saveP95 = getPercentile(for: .save, percentile: 0.95) {
            summary["saveP95"] = saveP95
        }
        if let loadP95 = getPercentile(for: .load, percentile: 0.95) {
            summary["loadP95"] = loadP95
        }
        if let searchP95 = getPercentile(for: .search, percentile: 0.95) {
            summary["searchP95"] = searchP95
        }
        
        // Error statistics
        summary["errorCounts"] = errorCounts
        summary["indexCorruptionCount"] = indexCorruptionCount
        
        return summary
    }
    
    // MARK: - Health Checks
    
    /// Perform health check on storage system
    /// - Parameters:
    ///   - indexHealth: Current index health status
    ///   - totalEntries: Total number of entries in storage
    /// - Returns: Overall health status
    func performHealthCheck(
        indexHealth: (isHealthy: Bool, corruptedCount: Int),
        totalEntries: Int
    ) -> HealthStatus {
        // Check storage health
        let storageErrors = errorCounts.filter { $0.key.contains("storage") || $0.key.contains("LocalStorageError") }
        let storageErrorCount = storageErrors.values.reduce(0, +)
        let storageHealth = HealthStatus.ComponentHealth(
            isHealthy: storageErrorCount < 10, // Threshold: less than 10 errors
            errorCount: storageErrorCount,
            lastError: lastErrors["storage"]?.error,
            lastErrorTime: lastErrors["storage"]?.timestamp
        )
        
        // Check sync health
        let syncErrors = errorCounts.filter { $0.key.contains("sync") || $0.key.contains("CloudKit") }
        let syncErrorCount = syncErrors.values.reduce(0, +)
        let syncHealth = HealthStatus.ComponentHealth(
            isHealthy: syncErrorCount < 20, // Threshold: less than 20 errors (sync can fail more often)
            errorCount: syncErrorCount,
            lastError: lastErrors["sync"]?.error,
            lastErrorTime: lastErrors["sync"]?.timestamp
        )
        
        // Overall health
        let isHealthy = indexHealth.isHealthy && storageHealth.isHealthy
        
        return HealthStatus(
            isHealthy: isHealthy,
            indexHealth: HealthStatus.IndexHealth(
                isHealthy: indexHealth.isHealthy,
                corruptedEntryCount: indexHealth.corruptedCount,
                totalEntries: totalEntries,
                lastRebuildTime: lastIndexRebuild
            ),
            storageHealth: storageHealth,
            syncHealth: syncHealth,
            timestamp: Date()
        )
    }
    
    // MARK: - Diagnostics
    
    /// Get diagnostic information for troubleshooting
    /// - Returns: Dictionary with diagnostic data
    func getDiagnostics() -> [String: Any] {
        var diagnostics: [String: Any] = [:]
        
        // Performance summary
        diagnostics["performance"] = getPerformanceSummary()
        
        // Recent errors
        var recentErrors: [[String: Any]] = []
        for metric in recentMetrics.suffix(50).reversed() where !metric.success {
            recentErrors.append([
                "operation": metric.operation.rawValue,
                "timestamp": metric.timestamp,
                "duration": metric.duration,
                "errorType": metric.errorType ?? "unknown"
            ])
        }
        diagnostics["recentErrors"] = recentErrors
        
        // Component status
        diagnostics["lastErrors"] = lastErrors.mapValues { ["error": $0.error, "timestamp": $0.timestamp] }
        
        // Index status
        diagnostics["indexStatus"] = [
            "corruptionCount": indexCorruptionCount,
            "lastRebuild": lastIndexRebuild?.description ?? "never"
        ]
        
        // System info
        diagnostics["systemInfo"] = [
            "startTime": startTime,
            "uptime": getUptime(),
            "metricsCount": recentMetrics.count
        ]
        
        return diagnostics
    }
    
    /// Reset all metrics (useful for testing)
    func reset() {
        recentMetrics.removeAll()
        aggregatedStats.removeAll()
        errorCounts.removeAll()
        lastErrors.removeAll()
        indexCorruptionCount = 0
        lastIndexRebuild = nil
    }
}

// MARK: - Metrics Helper

/// Helper for measuring operation duration
struct MetricsTimer {
    private let startTime: Date
    
    init() {
        self.startTime = Date()
    }
    
    /// Get elapsed time in seconds
    var elapsed: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}
