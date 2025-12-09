//
//  StoragePerformanceDemo.swift
//  Hub
//
//  Demo showcasing performance optimizations for local-first database
//

import Foundation
import SwiftUI
import Combine
/// Demo view for storage performance optimization features
struct StoragePerformanceDemo: View {
    @StateObject private var viewModel = StoragePerformanceViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Optimizations")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Monitor and control storage performance features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Cache Statistics
                GroupBox(label: Label("LRU Cache", systemImage: "memorychip")) {
                    VStack(alignment: .leading, spacing: 12) {
                        StorageStatRow(label: "Capacity", value: "\(viewModel.cacheCapacity)")
                        StorageStatRow(label: "Current Size", value: "\(viewModel.cacheCount)")
                        StorageStatRow(label: "Hit Rate", value: String(format: "%.1f%%", viewModel.cacheHitRate * 100))
                        StorageStatRow(label: "Evictions", value: "\(viewModel.cacheEvictions)")
                        
                        HStack {
                            Button("Clear Cache") {
                                Task {
                                    await viewModel.clearCache()
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Evict 25%") {
                                Task {
                                    await viewModel.evictCache(percentage: 0.25)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
                
                // Memory Pressure
                GroupBox(label: Label("Memory Pressure", systemImage: "gauge")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Current Level:")
                            Spacer()
                            Text(viewModel.memoryPressureLevel)
                                .fontWeight(.semibold)
                                .foregroundColor(memoryPressureColor)
                        }
                        
                        StorageStatRow(label: "Memory Usage", value: String(format: "%.1f%%", viewModel.memoryUsage))
                        StorageStatRow(label: "Warning Events", value: "\(viewModel.warningEvents)")
                        StorageStatRow(label: "Critical Events", value: "\(viewModel.criticalEvents)")
                        
                        Button("Check Memory") {
                            Task {
                                await viewModel.checkMemoryPressure()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                // Batch Writer
                if viewModel.batchWriterEnabled {
                    GroupBox(label: Label("Batch Disk Writer", systemImage: "externaldrive")) {
                        VStack(alignment: .leading, spacing: 12) {
                            StorageStatRow(label: "Pending Writes", value: "\(viewModel.pendingWrites)")
                            StorageStatRow(label: "Total Flushes", value: "\(viewModel.totalFlushes)")
                            StorageStatRow(label: "Avg Batch Size", value: String(format: "%.1f", viewModel.avgBatchSize))
                            
                            Button("Flush Now") {
                                Task {
                                    await viewModel.flushBatchWrites()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
                
                // Index Compaction
                GroupBox(label: Label("Index Compaction", systemImage: "arrow.down.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        StorageStatRow(label: "Total Compactions", value: "\(viewModel.totalCompactions)")
                        StorageStatRow(label: "Last Compaction", value: viewModel.lastCompactionTime)
                        
                        Button("Compact Indices") {
                            Task {
                                await viewModel.compactIndices()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                // Performance Summary
                GroupBox(label: Label("Performance Summary", systemImage: "chart.line.uptrend.xyaxis")) {
                    VStack(alignment: .leading, spacing: 12) {
                        StorageStatRow(label: "Avg Load Time", value: String(format: "%.2fms", viewModel.avgLoadTime * 1000))
                        StorageStatRow(label: "Avg Save Time", value: String(format: "%.2fms", viewModel.avgSaveTime * 1000))
                        StorageStatRow(label: "Total Operations", value: "\(viewModel.totalOperations)")
                        StorageStatRow(label: "Success Rate", value: String(format: "%.1f%%", viewModel.successRate * 100))
                    }
                    .padding()
                }
                
                // Actions
                HStack {
                    Button("Refresh Stats") {
                        Task {
                            await viewModel.refreshStatistics()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reset Stats") {
                        Task {
                            await viewModel.resetStatistics()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .padding()
        }
        .task {
            await viewModel.startMonitoring()
        }
    }
    
    private var memoryPressureColor: Color {
        switch viewModel.memoryPressureLevel {
        case "Normal": return .green
        case "Warning": return .orange
        case "Critical": return .red
        default: return .gray
        }
    }
}

/// Stat row component for storage performance
private struct StorageStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

/// View model for storage performance optimization demo
@MainActor
class StoragePerformanceViewModel: ObservableObject {
    @Published var cacheCapacity: Int = 0
    @Published var cacheCount: Int = 0
    @Published var cacheHitRate: Double = 0.0
    @Published var cacheEvictions: Int = 0
    
    @Published var memoryPressureLevel: String = "Normal"
    @Published var memoryUsage: Double = 0.0
    @Published var warningEvents: Int = 0
    @Published var criticalEvents: Int = 0
    
    @Published var batchWriterEnabled: Bool = false
    @Published var pendingWrites: Int = 0
    @Published var totalFlushes: Int = 0
    @Published var avgBatchSize: Double = 0.0
    
    @Published var totalCompactions: Int = 0
    @Published var lastCompactionTime: String = "Never"
    
    @Published var avgLoadTime: TimeInterval = 0.0
    @Published var avgSaveTime: TimeInterval = 0.0
    @Published var totalOperations: Int = 0
    @Published var successRate: Double = 0.0
    
    private var storageService: LocalStorageService?
    
    func startMonitoring() async {
        // Initialize storage service with optimizations enabled
        let indices = StorageIndices()
        let metrics = StorageMetrics()
        
        storageService = LocalStorageService(
            indices: indices,
            metrics: metrics,
            cacheCapacity: 1000,
            enableOptimizations: true
        )
        
        await refreshStatistics()
        
        // Start periodic refresh
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await refreshStatistics()
            }
        }
    }
    
    func refreshStatistics() async {
        guard let service = storageService else { return }
        
        // Cache statistics
        let cacheStats = await service.getCacheStatistics()
        if let capacity = cacheStats["capacity"] as? Int {
            cacheCapacity = capacity
        }
        if let count = cacheStats["count"] as? Int {
            cacheCount = count
        }
        if let hitRate = cacheStats["hitRate"] as? Double {
            cacheHitRate = hitRate
        }
        if let evictions = cacheStats["evictions"] as? Int {
            cacheEvictions = evictions
        }
        
        // Memory statistics
        let memoryStats = await service.getMemoryStatistics()
        if let level = memoryStats["currentPressureLevel"] as? String {
            memoryPressureLevel = level
        }
        if let lastCheck = memoryStats["lastCheck"] as? [String: Any],
           let usage = lastCheck["usagePercentage"] as? String {
            memoryUsage = Double(usage.replacingOccurrences(of: "%", with: "")) ?? 0.0
        }
        if let warnings = memoryStats["warningEvents"] as? Int {
            warningEvents = warnings
        }
        if let critical = memoryStats["criticalEvents"] as? Int {
            criticalEvents = critical
        }
        
        // Performance metrics
        let perfMetrics = await service.getPerformanceMetrics()
        if let loadP95 = perfMetrics["loadP95"] as? TimeInterval {
            avgLoadTime = loadP95
        }
        if let saveP95 = perfMetrics["saveP95"] as? TimeInterval {
            avgSaveTime = saveP95
        }
        if let total = perfMetrics["totalOperations"] as? Int {
            totalOperations = total
        }
        if let rate = perfMetrics["successRate"] as? Double {
            successRate = rate
        }
        
        // Diagnostics
        let diagnostics = await service.getDiagnostics()
        if let compactorStats = diagnostics["indexCompactorStatistics"] as? [String: Any] {
            if let total = compactorStats["totalCompactions"] as? Int {
                totalCompactions = total
            }
            if let lastTime = compactorStats["lastCompactionTime"] as? String {
                lastCompactionTime = lastTime
            }
        }
        
        if let batchStats = diagnostics["batchWriterStatistics"] as? [String: Any] {
            batchWriterEnabled = true
            if let pending = batchStats["pendingWrites"] as? Int {
                pendingWrites = pending
            }
            if let flushes = batchStats["totalFlushes"] as? Int {
                totalFlushes = flushes
            }
            if let avgSize = batchStats["averageBatchSize"] as? Double {
                avgBatchSize = avgSize
            }
        }
    }
    
    func clearCache() async {
        guard let service = storageService else { return }
        await service.clearCache()
        await refreshStatistics()
    }
    
    func evictCache(percentage: Double) async {
        guard let service = storageService else { return }
        await service.evictCache(percentage: percentage)
        await refreshStatistics()
    }
    
    func checkMemoryPressure() async {
        guard let service = storageService else { return }
        await service.checkMemoryPressure()
        await refreshStatistics()
    }
    
    func flushBatchWrites() async {
        guard let service = storageService else { return }
        try? await service.flushBatchWrites()
        await refreshStatistics()
    }
    
    func compactIndices() async {
        guard let service = storageService else { return }
        await service.compactIndices()
        await refreshStatistics()
    }
    
    func resetStatistics() async {
        // Reset would require additional methods on the service
        await refreshStatistics()
    }
}

// MARK: - Preview

#Preview {
    StoragePerformanceDemo()
}

