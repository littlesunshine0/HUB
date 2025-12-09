//
//  StorageMonitoringDemo.swift
//  Hub
//
//  Demo showing how to use storage monitoring and observability features
//

import Foundation
import SwiftUI
import Combine

/// Demo view showing storage monitoring capabilities
struct StorageMonitoringDemo: View {
    @StateObject private var viewModel = MonitoringViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Storage Monitoring Demo")
                .font(.title)
            
            // Health Status
            GroupBox("System Health") {
                if let health = viewModel.healthStatus {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Overall:")
                            Spacer()
                            Text(health.isHealthy ? "✅ Healthy" : "⚠️ Unhealthy")
                                .foregroundColor(health.isHealthy ? .green : .orange)
                        }
                        
                        HStack {
                            Text("Index:")
                            Spacer()
                            Text(health.indexHealth.isHealthy ? "✅" : "⚠️")
                            Text("\(health.indexHealth.totalEntries) entries")
                        }
                        
                        HStack {
                            Text("Storage:")
                            Spacer()
                            Text(health.storageHealth.isHealthy ? "✅" : "⚠️")
                            Text("\(health.storageHealth.errorCount) errors")
                        }
                    }
                }
            }
            
            // Performance Metrics
            GroupBox("Performance") {
                if let metrics = viewModel.performanceMetrics {
                    VStack(alignment: .leading, spacing: 8) {
                        if let totalOps = metrics["totalOperations"] as? Int {
                            Text("Total Operations: \(totalOps)")
                        }
                        
                        if let successRate = metrics["successRate"] as? Double {
                            Text("Success Rate: \(String(format: "%.1f%%", successRate * 100))")
                        }
                        
                        if let saveP95 = metrics["saveP95"] as? Double {
                            Text("Save P95: \(String(format: "%.2f", saveP95 * 1000))ms")
                        }
                    }
                }
            }
            
            // Actions
            HStack {
                Button("Refresh") {
                    Task {
                        await viewModel.refresh()
                    }
                }
                
                Button("Run Health Check") {
                    Task {
                        await viewModel.runHealthCheck()
                    }
                }
                
                Button("Show Diagnostics") {
                    Task {
                        await viewModel.showDiagnostics()
                    }
                }
            }
        }
        .padding()
        .task {
            await viewModel.initialize()
        }
    }
}

/// View model for monitoring demo
@MainActor
class MonitoringViewModel: ObservableObject {
    @Published var healthStatus: StorageMetrics.HealthStatus?
    @Published var performanceMetrics: [String: Any]?
    
    private var coordinator: StorageCoordinator?
    
    func initialize() async {
        do {
            coordinator = try await StorageCoordinator.create()
            await refresh()
        } catch {
            print("Failed to initialize coordinator: \(error)")
        }
    }
    
    func refresh() async {
        guard let coordinator = coordinator else { return }
        
        healthStatus = await coordinator.performHealthCheck()
        performanceMetrics = await coordinator.getPerformanceMetrics()
    }
    
    func runHealthCheck() async {
        guard let coordinator = coordinator else { return }
        
        let health = await coordinator.performHealthCheck()
        healthStatus = health
        
        print("🏥 Health Check Results:")
        print("  Overall: \(health.isHealthy ? "✅ Healthy" : "⚠️ Unhealthy")")
        print("  Index: \(health.indexHealth.isHealthy ? "✅" : "⚠️") (\(health.indexHealth.totalEntries) entries)")
        print("  Storage: \(health.storageHealth.isHealthy ? "✅" : "⚠️") (\(health.storageHealth.errorCount) errors)")
        print("  Sync: \(health.syncHealth.isHealthy ? "✅" : "⚠️") (\(health.syncHealth.errorCount) errors)")
    }
    
    func showDiagnostics() async {
        guard let coordinator = coordinator else { return }
        
        await coordinator.logSystemStatus()
        
        let diagnostics = await coordinator.getDiagnostics()
        print("\n📋 Full Diagnostics:")
        print(diagnostics)
    }
}
