//
//  AutomationModuleDemo.swift
//  Hub
//
//  Demo and testing for the Hub Automation System
//

import Foundation
import SwiftUI

@MainActor
struct AutomationModuleDemo: View {
    @StateObject private var coordinator = AutomationCoordinator.shared
    @State private var isInitialized = false
    @State private var executionLog: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hub Automation System Demo")
                .font(.title)
            
            if !isInitialized {
                Button("Initialize Automation System") {
                    Task {
                        do {
                            try await coordinator.initialize()
                            isInitialized = true
                            executionLog.append("✅ System initialized")
                        } catch {
                            executionLog.append("❌ Initialization failed: \(error)")
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Button("Execute Simple Workflow") {
                        Task {
                            await executeSimpleWorkflow()
                        }
                    }
                    
                    Button("Get Statistics") {
                        Task {
                            await getStatistics()
                        }
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(executionLog, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(height: 300)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    private func executeSimpleWorkflow() async {
        executionLog.append("▶️ Creating simple workflow...")
        
        let step = WorkflowStep(
            name: "Test Step",
            action: .custom(CustomAction(identifier: "test", parameters: [:]))
        )
        
        let workflow = Workflow(
            name: "Test Workflow",
            description: "A simple test workflow",
            steps: [step]
        )
        
        do {
            let result = try await coordinator.executeWorkflow(workflow)
            executionLog.append("✅ Workflow completed: \(result.status)")
            executionLog.append("   Duration: \(String(format: "%.2f", result.duration))s")
        } catch {
            executionLog.append("❌ Workflow failed: \(error.localizedDescription)")
        }
    }
    
    private func getStatistics() async {
        let stats = await coordinator.getStatistics()
        executionLog.append("📊 Statistics:")
        executionLog.append("   Total: \(stats.totalExecutions)")
        executionLog.append("   Completed: \(stats.completedExecutions)")
        executionLog.append("   Failed: \(stats.failedExecutions)")
        executionLog.append("   Running: \(stats.runningExecutions)")
        executionLog.append("   Success Rate: \(String(format: "%.1f", stats.successRate * 100))%")
    }
}

#Preview {
    AutomationModuleDemo()
}
