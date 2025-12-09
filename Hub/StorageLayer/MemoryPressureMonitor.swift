//
//  MemoryPressureMonitor.swift
//  Hub
//
//  Memory pressure monitoring for automatic cache eviction
//  Monitors system memory and triggers cache cleanup when needed
//

import Foundation

#if os(macOS)
import Darwin
#endif

/// Memory pressure monitor for automatic cache management
actor MemoryPressureMonitor {
    
    // MARK: - Memory Pressure Level
    
    enum PressureLevel: Int, Sendable {
        case normal = 0
        case warning = 1
        case critical = 2
        
        var description: String {
            switch self {
            case .normal: return "Normal"
            case .warning: return "Warning"
            case .critical: return "Critical"
            }
        }
    }
    
    // MARK: - Memory Statistics
    
    struct MemoryStats: Sendable {
        let totalMemory: UInt64
        let usedMemory: UInt64
        let freeMemory: UInt64
        let pressureLevel: PressureLevel
        let timestamp: Date
        
        var usagePercentage: Double {
            guard totalMemory > 0 else { return 0.0 }
            return Double(usedMemory) / Double(totalMemory) * 100.0
        }
    }
    
    // MARK: - Properties
    
    /// Current pressure level
    private(set) var currentPressureLevel: PressureLevel = .normal
    
    /// Callbacks to invoke when pressure level changes
    private var pressureCallbacks: [(PressureLevel) -> Void] = []
    
    /// Monitoring interval in seconds
    private let monitoringInterval: TimeInterval
    
    /// Whether monitoring is active
    private var isMonitoring: Bool = false
    
    /// Last memory statistics
    private var lastStats: MemoryStats?
    
    /// Pressure level thresholds (percentage of memory used)
    private let warningThreshold: Double = 75.0
    private let criticalThreshold: Double = 90.0
    
    /// Statistics
    private var totalChecks: Int = 0
    private var warningEvents: Int = 0
    private var criticalEvents: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize memory pressure monitor
    /// - Parameter monitoringInterval: How often to check memory (default: 10 seconds)
    init(monitoringInterval: TimeInterval = 10.0) {
        self.monitoringInterval = max(1.0, monitoringInterval)
    }
    
    // MARK: - Monitoring Control
    
    /// Start monitoring memory pressure
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        Task {
            await monitorLoop()
        }
    }
    
    /// Stop monitoring memory pressure
    func stopMonitoring() {
        isMonitoring = false
    }
    
    /// Main monitoring loop
    private func monitorLoop() async {
        while isMonitoring {
            await checkMemoryPressure()
            
            // Wait for next check
            try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
        }
    }
    
    // MARK: - Memory Checking
    
    /// Check current memory pressure
    func checkMemoryPressure() async {
        totalChecks += 1
        
        let stats = getMemoryStatistics()
        lastStats = stats
        
        // Determine pressure level
        let newLevel: PressureLevel
        if stats.usagePercentage >= criticalThreshold {
            newLevel = .critical
            criticalEvents += 1
        } else if stats.usagePercentage >= warningThreshold {
            newLevel = .warning
            warningEvents += 1
        } else {
            newLevel = .normal
        }
        
        // Notify if level changed
        if newLevel != currentPressureLevel {
            let oldLevel = currentPressureLevel
            currentPressureLevel = newLevel
            
            print("🧠 Memory pressure changed: \(oldLevel.description) → \(newLevel.description) (\(String(format: "%.1f", stats.usagePercentage))% used)")
            
            // Invoke callbacks
            notifyPressureChange(newLevel)
        }
    }
    
    /// Get current memory statistics
    func getMemoryStatistics() -> MemoryStats {
        #if os(macOS)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_page_size)
            let totalPages = UInt64(stats.free_count) + UInt64(stats.active_count) + 
                           UInt64(stats.inactive_count) + UInt64(stats.wire_count)
            let usedPages = UInt64(stats.active_count) + UInt64(stats.wire_count)
            
            let totalMemory = totalPages * pageSize
            let usedMemory = usedPages * pageSize
            let freeMemory = totalMemory - usedMemory
            
            return MemoryStats(
                totalMemory: totalMemory,
                usedMemory: usedMemory,
                freeMemory: freeMemory,
                pressureLevel: currentPressureLevel,
                timestamp: Date()
            )
        }
        #endif
        
        // Fallback for non-macOS or if stats unavailable
        return MemoryStats(
            totalMemory: 8_589_934_592, // 8 GB default
            usedMemory: 4_294_967_296,  // 4 GB default
            freeMemory: 4_294_967_296,  // 4 GB default
            pressureLevel: currentPressureLevel,
            timestamp: Date()
        )
    }
    
    // MARK: - Callbacks
    
    /// Register a callback for pressure level changes
    /// - Parameter callback: Closure to invoke when pressure changes
    func onPressureChange(_ callback: @escaping (PressureLevel) -> Void) {
        pressureCallbacks.append(callback)
    }
    
    /// Notify all callbacks of pressure change
    private func notifyPressureChange(_ level: PressureLevel) {
        for callback in pressureCallbacks {
            callback(level)
        }
    }
    
    // MARK: - Statistics
    
    /// Get monitoring statistics
    /// - Returns: Dictionary with monitoring metrics
    func getStatistics() -> [String: Any] {
        var stats: [String: Any] = [
            "isMonitoring": isMonitoring,
            "currentPressureLevel": currentPressureLevel.description,
            "totalChecks": totalChecks,
            "warningEvents": warningEvents,
            "criticalEvents": criticalEvents,
            "monitoringInterval": monitoringInterval
        ]
        
        if let lastStats = lastStats {
            stats["lastCheck"] = [
                "timestamp": lastStats.timestamp,
                "totalMemory": formatBytes(lastStats.totalMemory),
                "usedMemory": formatBytes(lastStats.usedMemory),
                "freeMemory": formatBytes(lastStats.freeMemory),
                "usagePercentage": String(format: "%.1f%%", lastStats.usagePercentage)
            ]
        }
        
        return stats
    }
    
    /// Format bytes for human-readable display
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Reset statistics
    func resetStatistics() {
        totalChecks = 0
        warningEvents = 0
        criticalEvents = 0
    }
    
    /// Get current pressure level
    func getCurrentPressureLevel() -> PressureLevel {
        return currentPressureLevel
    }
    
    /// Get last memory statistics
    func getLastStats() -> MemoryStats? {
        return lastStats
    }
}

