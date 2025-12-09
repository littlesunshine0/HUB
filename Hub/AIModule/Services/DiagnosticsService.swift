//
//  DiagnosticsService.swift
//  Hub
//
//  Created for Offline Assistant Module
//  Collects and manages system diagnostics
//

import Foundation
import Combine

/// Service for collecting and managing system diagnostics
class DiagnosticsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSnapshot: DiagnosticsSnapshot
    @Published var performanceMetrics: AssistantPerformanceMetrics
    @Published var systemHealth: SystemHealth
    
    // MARK: - Private Properties
    
    private var errors: [DiagnosticError] = []
    private let maxErrors: Int = 50
    private let lock = NSLock()
    
    // References to other services
    private weak var backoffCenter: AdaptiveBackoffCenter?
    
    // MARK: - Initialization
    
    init(backoffCenter: AdaptiveBackoffCenter? = nil) {
        self.currentSnapshot = DiagnosticsSnapshot()
        self.performanceMetrics = AssistantPerformanceMetrics()
        self.systemHealth = .unknown
        self.backoffCenter = backoffCenter
    }
    
    // MARK: - Public Methods
    
    /// Update the diagnostics snapshot with current system state
    /// - Parameters:
    ///   - entryCount: Number of knowledge entries
    ///   - indexSize: Size of the search index
    ///   - queueSize: Number of items in processing queue
    func updateSnapshot(entryCount: Int, indexSize: String, queueSize: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        // Get backoff metrics if available
        var backoffMetrics: [String: BackoffMetrics] = [:]
        if let backoffCenter = backoffCenter {
            let snapshot = backoffCenter.snapshot()
            backoffMetrics = snapshot.mapValues { BackoffMetrics(from: $0) }
        }
        
        currentSnapshot = DiagnosticsSnapshot(
            avgQueryTime: Int(performanceMetrics.avgQueryLatency * 1000),
            cacheHitRate: performanceMetrics.cacheHitRate,
            entryCount: entryCount,
            indexSize: indexSize,
            queueSize: queueSize,
            recentErrors: Array(errors.suffix(10)),
            backoffSnapshot: backoffMetrics,
            timestamp: Date()
        )
        
        systemHealth = SystemHealth.from(snapshot: currentSnapshot)
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Record a query operation
    /// - Parameters:
    ///   - latency: Query latency in seconds
    ///   - cacheHit: Whether the query hit the cache
    func recordQuery(latency: TimeInterval, cacheHit: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        performanceMetrics.recordQuery(latency: latency, cacheHit: cacheHit)
    }
    
    /// Record an indexing operation
    /// - Parameter latency: Indexing latency in seconds
    func recordIndexing(latency: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        performanceMetrics.recordIndexing(latency: latency)
    }
    
    /// Record an import operation
    /// - Parameter latency: Import latency in seconds
    func recordImport(latency: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        performanceMetrics.recordImport(latency: latency)
    }
    
    /// Log a diagnostic error
    /// - Parameters:
    ///   - type: Error type
    ///   - message: Error message
    ///   - suggestedResolution: Suggested resolution (optional)
    ///   - severity: Error severity
    func logError(
        type: DiagnosticError.ErrorType,
        message: String,
        suggestedResolution: String? = nil,
        severity: DiagnosticError.Severity = .medium
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        let error = DiagnosticError(
            type: type,
            message: message,
            suggestedResolution: suggestedResolution,
            severity: severity
        )
        
        errors.append(error)
        
        // Keep only recent errors
        if errors.count > maxErrors {
            errors.removeFirst(errors.count - maxErrors)
        }
        
        // Update system health
        systemHealth = SystemHealth.from(snapshot: currentSnapshot)
    }
    
    /// Clear all errors
    func clearErrors() {
        lock.lock()
        defer { lock.unlock() }
        
        errors.removeAll()
        systemHealth = SystemHealth.from(snapshot: currentSnapshot)
    }
    
    /// Get recent errors
    /// - Parameter count: Number of recent errors to retrieve
    /// - Returns: Array of recent errors
    func recentErrors(count: Int = 10) -> [DiagnosticError] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(errors.suffix(count))
    }
    
    /// Get errors by type
    /// - Parameter type: Error type to filter by
    /// - Returns: Array of errors matching the type
    func errors(ofType type: DiagnosticError.ErrorType) -> [DiagnosticError] {
        lock.lock()
        defer { lock.unlock() }
        
        return errors.filter { $0.type == type }
    }
    
    /// Get errors by severity
    /// - Parameter severity: Severity level to filter by
    /// - Returns: Array of errors matching the severity
    func errors(withSeverity severity: DiagnosticError.Severity) -> [DiagnosticError] {
        lock.lock()
        defer { lock.unlock() }
        
        return errors.filter { $0.severity == severity }
    }
    
    /// Generate a diagnostic report
    /// - Returns: Human-readable diagnostic report
    func generateReport() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let snapshot = currentSnapshot
        
        var report = """
        === Offline Assistant Diagnostics Report ===
        Generated: \(snapshot.timestamp)
        System Health: \(systemHealth)
        
        Performance Metrics:
        - Average Query Time: \(snapshot.avgQueryTime)ms
        - Cache Hit Rate: \(String(format: "%.1f", snapshot.cacheHitRate))%
        - Knowledge Base Size: \(snapshot.entryCount) entries
        - Index Size: \(snapshot.indexSize)
        - Processing Queue: \(snapshot.queueSize) items
        
        """
        
        if !snapshot.backoffSnapshot.isEmpty {
            report += """
            
            Adaptive Backoff Status:
            """
            for (host, metrics) in snapshot.backoffSnapshot.sorted(by: { $0.key < $1.key }) {
                report += """
                
                - \(host):
                  Requests: \(metrics.total)
                  Current Delay: \(String(format: "%.2f", metrics.currentDelay))s
                  Latency: \(metrics.latencyMs)ms
                  429 Errors: \(metrics.recent429)
                  5xx Errors: \(metrics.recent5xx)
                """
            }
        }
        
        if !errors.isEmpty {
            report += """
            
            
            Recent Errors (\(errors.count)):
            """
            for error in errors.suffix(5) {
                report += """
                
                - [\(error.severity)] \(error.type): \(error.message)
                """
                if let resolution = error.suggestedResolution {
                    report += """
                    
                      Resolution: \(resolution)
                    """
                }
            }
        }
        
        return report
    }
    
    /// Export diagnostics to JSON
    /// - Returns: JSON data of diagnostics
    func exportJSON() throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        
        let exportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: currentSnapshot.timestamp),
            "systemHealth": "\(systemHealth)",
            "avgQueryTime": currentSnapshot.avgQueryTime,
            "cacheHitRate": currentSnapshot.cacheHitRate,
            "entryCount": currentSnapshot.entryCount,
            "indexSize": currentSnapshot.indexSize,
            "queueSize": currentSnapshot.queueSize,
            "errors": errors.map { error in
                [
                    "id": error.id.uuidString,
                    "timestamp": ISO8601DateFormatter().string(from: error.timestamp),
                    "type": error.type.rawValue,
                    "message": error.message,
                    "severity": error.severity.rawValue,
                    "suggestedResolution": error.suggestedResolution ?? ""
                ]
            },
            "backoffMetrics": currentSnapshot.backoffSnapshot.mapValues { metrics in
                [
                    "rps": metrics.rps ?? 0,
                    "burst": metrics.burst,
                    "latencyMs": metrics.latencyMs,
                    "recent429": metrics.recent429,
                    "recent5xx": metrics.recent5xx,
                    "total": metrics.total,
                    "currentDelay": metrics.currentDelay
                ]
            }
        ]
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
}

// MARK: - Convenience Extensions

extension DiagnosticsService {
    /// Check if system is healthy
    var isHealthy: Bool {
        systemHealth == .healthy
    }
    
    /// Check if system is in critical state
    var isCritical: Bool {
        systemHealth == .critical
    }
    
    /// Get count of critical errors
    var criticalErrorCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return errors.filter { $0.severity == .critical }.count
    }
    
    /// Get count of high severity errors
    var highSeverityErrorCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return errors.filter { $0.severity == .high }.count
    }
}
