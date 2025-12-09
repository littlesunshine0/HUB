//
//  AdaptiveBackoffCenter.swift
//  Hub
//
//  Created for Offline Assistant Module
//  Dynamically adjusts request timing based on server responses and errors
//

import Foundation

/// Manages adaptive backoff behavior for web crawling operations
/// Tracks per-host metrics and dynamically adjusts delays based on success/failure patterns
class AdaptiveBackoffCenter {
    
    // MARK: - Types
    
    /// Detailed metrics for a specific host
    struct HostMetrics {
        var currentDelay: TimeInterval
        var recentSuccesses: Int
        var recentFailures: Int
        var recent429Count: Int
        var recent5xxCount: Int
        var totalRequests: Int
        var totalSuccesses: Int
        var totalFailures: Int
        var lastRequestTime: Date?
        var firstRequestTime: Date?
        var requestsPerSecond: Double?
        var burstCapacity: Int
        var avgLatencyMs: Int
        var minLatencyMs: Int?
        var maxLatencyMs: Int?
        var latencyHistory: [Int]
        
        init(initialDelay: TimeInterval) {
            self.currentDelay = initialDelay
            self.recentSuccesses = 0
            self.recentFailures = 0
            self.recent429Count = 0
            self.recent5xxCount = 0
            self.totalRequests = 0
            self.totalSuccesses = 0
            self.totalFailures = 0
            self.lastRequestTime = nil
            self.firstRequestTime = nil
            self.requestsPerSecond = nil
            self.burstCapacity = 5
            self.avgLatencyMs = 0
            self.minLatencyMs = nil
            self.maxLatencyMs = nil
            self.latencyHistory = []
        }
        
        /// Calculate success rate as a percentage
        var successRate: Double {
            guard totalRequests > 0 else { return 0.0 }
            return Double(totalSuccesses) / Double(totalRequests) * 100.0
        }
        
        /// Calculate failure rate as a percentage
        var failureRate: Double {
            guard totalRequests > 0 else { return 0.0 }
            return Double(totalFailures) / Double(totalRequests) * 100.0
        }
        
        /// Determine if host is currently healthy
        var isHealthy: Bool {
            // Healthy if no recent failures and success rate is good
            return recentFailures == 0 && successRate >= 90.0
        }
        
        /// Get health status
        var healthStatus: HostHealthStatus {
            if recent429Count > 0 {
                return .rateLimited
            } else if recent5xxCount > 0 {
                return .serverError
            } else if recentFailures > 0 {
                return .degraded
            } else if successRate >= 95.0 {
                return .healthy
            } else if successRate >= 80.0 {
                return .degraded
            } else {
                return .unhealthy
            }
        }
        
        /// Calculate average requests per second over lifetime
        var lifetimeRPS: Double? {
            guard let first = firstRequestTime, let last = lastRequestTime else { return nil }
            let duration = last.timeIntervalSince(first)
            guard duration > 0 else { return nil }
            return Double(totalRequests) / duration
        }
    }
    
    /// Health status for a host
    enum HostHealthStatus: String {
        case healthy = "Healthy"
        case degraded = "Degraded"
        case unhealthy = "Unhealthy"
        case rateLimited = "Rate Limited"
        case serverError = "Server Error"
    }
    
    /// Snapshot of current backoff state for diagnostics
    struct BackoffSnapshot {
        let host: String
        let rps: Double?
        let lifetimeRPS: Double?
        let burst: Int
        let latencyMs: Int
        let minLatencyMs: Int?
        let maxLatencyMs: Int?
        let recent429: Int
        let recent5xx: Int
        let total: Int
        let totalSuccesses: Int
        let totalFailures: Int
        let successRate: Double
        let failureRate: Double
        let currentDelay: TimeInterval
        let healthStatus: HostHealthStatus
        let isHealthy: Bool
        let recentSuccesses: Int
        let recentFailures: Int
        let firstRequestTime: Date?
        let lastRequestTime: Date?
    }
    
    // MARK: - Properties
    
    private var hostMetrics: [String: HostMetrics] = [:]
    private let lock = NSLock()
    
    // Configuration
    private let minDelay: TimeInterval
    private let maxDelay: TimeInterval
    private let backoffMultiplier: Double
    private let recoveryMultiplier: Double
    private let successThreshold: Int
    
    // MARK: - Initialization
    
    /// Initialize with configurable backoff parameters
    /// - Parameters:
    ///   - minDelay: Minimum delay between requests (default: 0.1s)
    ///   - maxDelay: Maximum delay between requests (default: 10.0s)
    ///   - backoffMultiplier: Multiplier for increasing delay on failure (default: 1.5)
    ///   - recoveryMultiplier: Multiplier for decreasing delay on success (default: 0.8)
    ///   - successThreshold: Number of consecutive successes before reducing delay (default: 5)
    init(
        minDelay: TimeInterval = 0.1,
        maxDelay: TimeInterval = 10.0,
        backoffMultiplier: Double = 1.5,
        recoveryMultiplier: Double = 0.8,
        successThreshold: Int = 5
    ) {
        self.minDelay = minDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
        self.recoveryMultiplier = recoveryMultiplier
        self.successThreshold = successThreshold
    }
    
    // MARK: - Public Methods
    
    /// Record a request result for a host
    /// - Parameters:
    ///   - host: The host domain
    ///   - success: Whether the request succeeded
    ///   - statusCode: HTTP status code (optional)
    ///   - latencyMs: Request latency in milliseconds (optional)
    func record(host: String, success: Bool, statusCode: Int? = nil, latencyMs: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        var metrics = hostMetrics[host] ?? HostMetrics(initialDelay: minDelay)
        
        // Update request count and timing
        metrics.totalRequests += 1
        let now = Date()
        
        // Set first request time if this is the first request
        if metrics.firstRequestTime == nil {
            metrics.firstRequestTime = now
        }
        
        // Calculate requests per second if we have timing data
        if let lastTime = metrics.lastRequestTime {
            let timeDiff = now.timeIntervalSince(lastTime)
            if timeDiff > 0 {
                metrics.requestsPerSecond = 1.0 / timeDiff
            }
        }
        metrics.lastRequestTime = now
        
        // Update latency metrics
        if let latency = latencyMs {
            // Update average latency (exponential moving average)
            if metrics.avgLatencyMs == 0 {
                metrics.avgLatencyMs = latency
            } else {
                metrics.avgLatencyMs = Int(Double(metrics.avgLatencyMs) * 0.7 + Double(latency) * 0.3)
            }
            
            // Update min/max latency
            if let minLatency = metrics.minLatencyMs {
                metrics.minLatencyMs = min(minLatency, latency)
            } else {
                metrics.minLatencyMs = latency
            }
            
            if let maxLatency = metrics.maxLatencyMs {
                metrics.maxLatencyMs = max(maxLatency, latency)
            } else {
                metrics.maxLatencyMs = latency
            }
            
            // Keep latency history (last 100 samples)
            metrics.latencyHistory.append(latency)
            if metrics.latencyHistory.count > 100 {
                metrics.latencyHistory.removeFirst()
            }
        }
        
        if success {
            metrics.recentSuccesses += 1
            metrics.recentFailures = 0
            metrics.totalSuccesses += 1
            
            // Gradually reduce delay after consecutive successes
            if metrics.recentSuccesses >= successThreshold {
                metrics.currentDelay = max(minDelay, metrics.currentDelay * recoveryMultiplier)
                metrics.recentSuccesses = 0
            }
        } else {
            metrics.recentFailures += 1
            metrics.recentSuccesses = 0
            metrics.totalFailures += 1
            
            // Track specific error types and adjust delay accordingly
            if let code = statusCode {
                if code == 429 {
                    // Rate limit hit - aggressive backoff
                    metrics.recent429Count += 1
                    metrics.currentDelay = min(maxDelay, metrics.currentDelay * 2.0)
                } else if code >= 500 && code < 600 {
                    // Server error - moderate backoff
                    metrics.recent5xxCount += 1
                    metrics.currentDelay = min(maxDelay, metrics.currentDelay * backoffMultiplier)
                } else {
                    // Other failure - standard backoff
                    metrics.currentDelay = min(maxDelay, metrics.currentDelay * backoffMultiplier)
                }
            } else {
                // Unknown failure - standard backoff
                metrics.currentDelay = min(maxDelay, metrics.currentDelay * backoffMultiplier)
            }
        }
        
        hostMetrics[host] = metrics
    }
    
    /// Get the current delay for a host
    /// - Parameter host: The host domain
    /// - Returns: Current delay in seconds
    func delay(for host: String) -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        
        return hostMetrics[host]?.currentDelay ?? minDelay
    }
    
    /// Get a snapshot of all host metrics for diagnostics
    /// - Returns: Dictionary of host to metrics snapshot
    func snapshot() -> [String: BackoffSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        
        return hostMetrics.mapValues { metrics in
            BackoffSnapshot(
                host: "",
                rps: metrics.requestsPerSecond,
                lifetimeRPS: metrics.lifetimeRPS,
                burst: metrics.burstCapacity,
                latencyMs: metrics.avgLatencyMs,
                minLatencyMs: metrics.minLatencyMs,
                maxLatencyMs: metrics.maxLatencyMs,
                recent429: metrics.recent429Count,
                recent5xx: metrics.recent5xxCount,
                total: metrics.totalRequests,
                totalSuccesses: metrics.totalSuccesses,
                totalFailures: metrics.totalFailures,
                successRate: metrics.successRate,
                failureRate: metrics.failureRate,
                currentDelay: metrics.currentDelay,
                healthStatus: metrics.healthStatus,
                isHealthy: metrics.isHealthy,
                recentSuccesses: metrics.recentSuccesses,
                recentFailures: metrics.recentFailures,
                firstRequestTime: metrics.firstRequestTime,
                lastRequestTime: metrics.lastRequestTime
            )
        }
    }
    
    /// Get detailed metrics for a specific host
    /// - Parameter host: The host domain
    /// - Returns: Snapshot of host metrics, or nil if no data exists
    func metrics(for host: String) -> BackoffSnapshot? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let metrics = hostMetrics[host] else { return nil }
        
        return BackoffSnapshot(
            host: host,
            rps: metrics.requestsPerSecond,
            lifetimeRPS: metrics.lifetimeRPS,
            burst: metrics.burstCapacity,
            latencyMs: metrics.avgLatencyMs,
            minLatencyMs: metrics.minLatencyMs,
            maxLatencyMs: metrics.maxLatencyMs,
            recent429: metrics.recent429Count,
            recent5xx: metrics.recent5xxCount,
            total: metrics.totalRequests,
            totalSuccesses: metrics.totalSuccesses,
            totalFailures: metrics.totalFailures,
            successRate: metrics.successRate,
            failureRate: metrics.failureRate,
            currentDelay: metrics.currentDelay,
            healthStatus: metrics.healthStatus,
            isHealthy: metrics.isHealthy,
            recentSuccesses: metrics.recentSuccesses,
            recentFailures: metrics.recentFailures,
            firstRequestTime: metrics.firstRequestTime,
            lastRequestTime: metrics.lastRequestTime
        )
    }
    
    /// Manually adjust backoff parameters for a specific host
    /// - Parameters:
    ///   - host: The host domain
    ///   - delay: New delay value
    ///   - burstCapacity: New burst capacity (optional)
    func adjustParameters(for host: String, delay: TimeInterval, burstCapacity: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        var metrics = hostMetrics[host] ?? HostMetrics(initialDelay: minDelay)
        metrics.currentDelay = min(max(delay, minDelay), maxDelay)
        
        if let burst = burstCapacity {
            metrics.burstCapacity = max(1, burst)
        }
        
        hostMetrics[host] = metrics
    }
    
    /// Reset metrics for a specific host
    /// - Parameter host: The host domain
    func reset(host: String) {
        lock.lock()
        defer { lock.unlock() }
        
        hostMetrics[host] = HostMetrics(initialDelay: minDelay)
    }
    
    /// Reset all metrics
    func resetAll() {
        lock.lock()
        defer { lock.unlock() }
        
        hostMetrics.removeAll()
    }
    
    /// Get all tracked hosts
    /// - Returns: Array of host domains
    func trackedHosts() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(hostMetrics.keys)
    }
}

// MARK: - Convenience Extensions

extension AdaptiveBackoffCenter {
    /// Check if a host is currently experiencing issues
    /// - Parameter host: The host domain
    /// - Returns: True if the host has recent failures
    func isHostExperiencingIssues(_ host: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let metrics = hostMetrics[host] else { return false }
        return metrics.recentFailures > 0 || metrics.recent429Count > 0 || metrics.recent5xxCount > 0
    }
    
    /// Get a summary of the current backoff state
    /// - Returns: Human-readable summary string
    func summary() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let totalHosts = hostMetrics.count
        let hostsWithIssues = hostMetrics.values.filter { $0.recentFailures > 0 }.count
        let totalRequests = hostMetrics.values.reduce(0) { $0 + $1.totalRequests }
        let totalSuccesses = hostMetrics.values.reduce(0) { $0 + $1.totalSuccesses }
        let totalFailures = hostMetrics.values.reduce(0) { $0 + $1.totalFailures }
        let overallSuccessRate = totalRequests > 0 ? Double(totalSuccesses) / Double(totalRequests) * 100.0 : 0.0
        
        return """
        Adaptive Backoff Summary:
        - Tracked Hosts: \(totalHosts)
        - Hosts with Issues: \(hostsWithIssues)
        - Total Requests: \(totalRequests)
        - Total Successes: \(totalSuccesses)
        - Total Failures: \(totalFailures)
        - Overall Success Rate: \(String(format: "%.1f", overallSuccessRate))%
        """
    }
    
    /// Get detailed statistics across all hosts
    /// - Returns: Aggregate statistics
    func aggregateStatistics() -> AggregateStatistics {
        lock.lock()
        defer { lock.unlock() }
        
        let totalHosts = hostMetrics.count
        let totalRequests = hostMetrics.values.reduce(0) { $0 + $1.totalRequests }
        let totalSuccesses = hostMetrics.values.reduce(0) { $0 + $1.totalSuccesses }
        let totalFailures = hostMetrics.values.reduce(0) { $0 + $1.totalFailures }
        let total429s = hostMetrics.values.reduce(0) { $0 + $1.recent429Count }
        let total5xxs = hostMetrics.values.reduce(0) { $0 + $1.recent5xxCount }
        
        let healthyHosts = hostMetrics.values.filter { $0.isHealthy }.count
        let degradedHosts = hostMetrics.values.filter { $0.healthStatus == .degraded }.count
        let unhealthyHosts = hostMetrics.values.filter { $0.healthStatus == .unhealthy }.count
        let rateLimitedHosts = hostMetrics.values.filter { $0.healthStatus == .rateLimited }.count
        let serverErrorHosts = hostMetrics.values.filter { $0.healthStatus == .serverError }.count
        
        let avgLatency = hostMetrics.values.isEmpty ? 0 : 
            hostMetrics.values.reduce(0) { $0 + $1.avgLatencyMs } / hostMetrics.count
        
        let overallSuccessRate = totalRequests > 0 ? 
            Double(totalSuccesses) / Double(totalRequests) * 100.0 : 0.0
        
        return AggregateStatistics(
            totalHosts: totalHosts,
            totalRequests: totalRequests,
            totalSuccesses: totalSuccesses,
            totalFailures: totalFailures,
            total429Errors: total429s,
            total5xxErrors: total5xxs,
            healthyHosts: healthyHosts,
            degradedHosts: degradedHosts,
            unhealthyHosts: unhealthyHosts,
            rateLimitedHosts: rateLimitedHosts,
            serverErrorHosts: serverErrorHosts,
            averageLatencyMs: avgLatency,
            overallSuccessRate: overallSuccessRate
        )
    }
    
    /// Get hosts sorted by health status
    /// - Returns: Array of host names sorted by health (worst first)
    func hostsByHealth() -> [(host: String, status: HostHealthStatus)] {
        lock.lock()
        defer { lock.unlock() }
        
        let statusPriority: [HostHealthStatus: Int] = [
            .rateLimited: 0,
            .serverError: 1,
            .unhealthy: 2,
            .degraded: 3,
            .healthy: 4
        ]
        
        return hostMetrics
            .map { (host: $0.key, status: $0.value.healthStatus) }
            .sorted { statusPriority[$0.status] ?? 5 < statusPriority[$1.status] ?? 5 }
    }
    
    /// Get latency percentiles for a specific host
    /// - Parameter host: The host domain
    /// - Returns: Latency percentiles (p50, p95, p99) or nil if no data
    func latencyPercentiles(for host: String) -> LatencyPercentiles? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let metrics = hostMetrics[host], !metrics.latencyHistory.isEmpty else { return nil }
        
        let sorted = metrics.latencyHistory.sorted()
        let count = sorted.count
        
        let p50Index = count / 2
        let p95Index = Int(Double(count) * 0.95)
        let p99Index = Int(Double(count) * 0.99)
        
        return LatencyPercentiles(
            p50: sorted[min(p50Index, count - 1)],
            p95: sorted[min(p95Index, count - 1)],
            p99: sorted[min(p99Index, count - 1)]
        )
    }
}

// MARK: - Supporting Types

/// Aggregate statistics across all hosts
struct AggregateStatistics {
    let totalHosts: Int
    let totalRequests: Int
    let totalSuccesses: Int
    let totalFailures: Int
    let total429Errors: Int
    let total5xxErrors: Int
    let healthyHosts: Int
    let degradedHosts: Int
    let unhealthyHosts: Int
    let rateLimitedHosts: Int
    let serverErrorHosts: Int
    let averageLatencyMs: Int
    let overallSuccessRate: Double
}

/// Latency percentiles for performance analysis
struct LatencyPercentiles {
    let p50: Int  // Median
    let p95: Int  // 95th percentile
    let p99: Int  // 99th percentile
}
