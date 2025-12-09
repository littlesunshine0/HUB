//
//  DiagnosticsModels.swift
//  Hub
//
//  Created for Offline Assistant Module
//  Models for diagnostics and monitoring
//

import Foundation

// MARK: - Diagnostics Snapshot

/// Comprehensive snapshot of assistant system diagnostics
struct DiagnosticsSnapshot {
    var avgQueryTime: Int
    var cacheHitRate: Double
    var entryCount: Int
    var indexSize: String
    var queueSize: Int
    var recentErrors: [DiagnosticError]
    var backoffSnapshot: [String: BackoffMetrics]
    var timestamp: Date
    
    init(
        avgQueryTime: Int = 0,
        cacheHitRate: Double = 0.0,
        entryCount: Int = 0,
        indexSize: String = "0 KB",
        queueSize: Int = 0,
        recentErrors: [DiagnosticError] = [],
        backoffSnapshot: [String: BackoffMetrics] = [:],
        timestamp: Date = Date()
    ) {
        self.avgQueryTime = avgQueryTime
        self.cacheHitRate = cacheHitRate
        self.entryCount = entryCount
        self.indexSize = indexSize
        self.queueSize = queueSize
        self.recentErrors = recentErrors
        self.backoffSnapshot = backoffSnapshot
        self.timestamp = timestamp
    }
}

// MARK: - Backoff Metrics

/// Detailed metrics for adaptive backoff monitoring
struct BackoffMetrics {
    let rps: Double?
    let burst: Int
    let latencyMs: Int
    let recent429: Int
    let recent5xx: Int
    let total: Int
    let currentDelay: TimeInterval
    
    init(
        rps: Double? = nil,
        burst: Int = 5,
        latencyMs: Int = 0,
        recent429: Int = 0,
        recent5xx: Int = 0,
        total: Int = 0,
        currentDelay: TimeInterval = 0.1
    ) {
        self.rps = rps
        self.burst = burst
        self.latencyMs = latencyMs
        self.recent429 = recent429
        self.recent5xx = recent5xx
        self.total = total
        self.currentDelay = currentDelay
    }
    
    /// Create from AdaptiveBackoffCenter snapshot
    init(from snapshot: AdaptiveBackoffCenter.BackoffSnapshot) {
        self.rps = snapshot.rps
        self.burst = snapshot.burst
        self.latencyMs = snapshot.latencyMs
        self.recent429 = snapshot.recent429
        self.recent5xx = snapshot.recent5xx
        self.total = snapshot.total
        self.currentDelay = snapshot.currentDelay
    }
}

// MARK: - Diagnostic Error

/// Represents a diagnostic error with context and resolution suggestions
struct DiagnosticError: Identifiable {
    let id: UUID
    let timestamp: Date
    let type: ErrorType
    let message: String
    let suggestedResolution: String?
    let severity: Severity
    
    enum ErrorType: String {
        case network
        case storage
        case validation
        case extraction
        case indexing
        case query
        case importOperation
        case exportOperation
        case unknown
    }
    
    enum Severity: String {
        case low
        case medium
        case high
        case critical
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: ErrorType,
        message: String,
        suggestedResolution: String? = nil,
        severity: Severity = .medium
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.message = message
        self.suggestedResolution = suggestedResolution
        self.severity = severity
    }
}

// MARK: - System Health

/// Overall system health status
enum SystemHealth {
    case healthy
    case degraded
    case critical
    case unknown
    
    /// Determine health from diagnostics snapshot
    static func from(snapshot: DiagnosticsSnapshot) -> SystemHealth {
        // Critical if there are critical errors
        if snapshot.recentErrors.contains(where: { $0.severity == .critical }) {
            return .critical
        }
        
        // Degraded if there are high severity errors or many medium errors
        let highErrors = snapshot.recentErrors.filter { $0.severity == .high }.count
        let mediumErrors = snapshot.recentErrors.filter { $0.severity == .medium }.count
        
        if highErrors > 0 || mediumErrors > 5 {
            return .degraded
        }
        
        // Check backoff metrics for issues
        let hostsWithIssues = snapshot.backoffSnapshot.values.filter { metrics in
            metrics.recent429 > 0 || metrics.recent5xx > 0
        }.count
        
        if hostsWithIssues > snapshot.backoffSnapshot.count / 2 {
            return .degraded
        }
        
        return .healthy
    }
}

// MARK: - Assistant Performance Metrics

/// Performance metrics for monitoring assistant operations
struct AssistantPerformanceMetrics {
    var queryLatency: [TimeInterval] = []
    var indexingLatency: [TimeInterval] = []
    var importLatency: [TimeInterval] = []
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    
    var avgQueryLatency: TimeInterval {
        guard !queryLatency.isEmpty else { return 0 }
        return queryLatency.reduce(0, +) / Double(queryLatency.count)
    }
    
    var avgIndexingLatency: TimeInterval {
        guard !indexingLatency.isEmpty else { return 0 }
        return indexingLatency.reduce(0, +) / Double(indexingLatency.count)
    }
    
    var avgImportLatency: TimeInterval {
        guard !importLatency.isEmpty else { return 0 }
        return importLatency.reduce(0, +) / Double(importLatency.count)
    }
    
    var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total) * 100.0
    }
    
    mutating func recordQuery(latency: TimeInterval, cacheHit: Bool) {
        queryLatency.append(latency)
        if cacheHit {
            cacheHits += 1
        } else {
            cacheMisses += 1
        }
        
        // Keep only recent measurements (last 100)
        if queryLatency.count > 100 {
            queryLatency.removeFirst()
        }
    }
    
    mutating func recordIndexing(latency: TimeInterval) {
        indexingLatency.append(latency)
        if indexingLatency.count > 100 {
            indexingLatency.removeFirst()
        }
    }
    
    mutating func recordImport(latency: TimeInterval) {
        importLatency.append(latency)
        if importLatency.count > 100 {
            importLatency.removeFirst()
        }
    }
}
