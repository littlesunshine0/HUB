//
//  RoleSettingsView.swift
//  Hub
//
//  Role settings view for managing user roles and automated tasks
//

import SwiftUI
import Combine

public struct RoleSettingsView: View {
    @StateObject var viewModel: RoleSettingsViewModel
    @State private var showTaskHistory = false
    @State private var showOwnerOnboarding = false
    
    public init(roleManager: RoleManager = .shared) {
        self._viewModel = StateObject(wrappedValue: RoleSettingsViewModel(roleManager: roleManager))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Current Role Section
                currentRoleSection
                
                // Role Selection Section
                roleSelectionSection
                
                // Capabilities Section
                capabilitiesSection
                
                // Automated Tasks Section
                automatedTasksSection
                
                // Owner-Specific Features
                if viewModel.selectedRole == .owner {
                    ownerFeaturesSection
                    ownerAnalyticsSection
                }
                
                // Task History Section
                taskHistorySection
            }
            .formStyle(.grouped)
            .navigationTitle("Role Settings")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showTaskHistory) {
                TaskHistoryView(viewModel: viewModel)
            }
            // TEMPORARY: Onboarding disabled
            // TODO: Implement new OnboardingModule
            // .sheet(isPresented: $showOwnerOnboarding) {
            //     UltimateOwnerOnboardingView()
            // }
            .overlay {
                if viewModel.isExecutingTask, let status = viewModel.taskExecutionStatus {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text(status)
                                .font(.caption)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - Current Role Section
    
    private var currentRoleSection: some View {
        Section {
            HStack {
                Image(systemName: viewModel.selectedRole.icon)
                    .font(.largeTitle)
                    .foregroundStyle(viewModel.selectedRole == .owner ? .yellow : .blue)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedRole.rawValue)
                        .font(.headline)
                    Text(viewModel.selectedRole.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
            
            if viewModel.selectedRole == .owner {
                HStack {
                    Label("Owner Privileges Active", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Spacer()
                    Button {
                        showOwnerOnboarding = true
                    } label: {
                        Text("Review Setup")
                            .font(.caption)
                    }
                }
            }
        } header: {
            Text("Current Role")
        }
    }
    
    // MARK: - Role Selection Section
    
    private var roleSelectionSection: some View {
        Section {
            Picker("Select Role", selection: Binding(
                get: { viewModel.selectedRole },
                set: { viewModel.changeRole($0) }
            )) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    HStack {
                        Image(systemName: role.icon)
                        Text(role.rawValue)
                    }
                    .tag(role)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Change Role")
        } footer: {
            Text("Changing your role will update available capabilities and automated tasks.")
        }
    }
    
    // MARK: - Capabilities Section
    
    private var capabilitiesSection: some View {
        Section {
            if viewModel.currentCapabilities.isEmpty {
                Text("No capabilities available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(viewModel.currentCapabilities, id: \.self) { capability in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(capability.rawValue)
                            .font(.subheadline)
                    }
                }
            }
        } header: {
            HStack {
                Text("Role Capabilities")
                Spacer()
                Text("\(viewModel.currentCapabilities.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        } footer: {
            Text("These are the capabilities granted by your current role.")
        }
    }
    
    // MARK: - Automated Tasks Section
    
    private var automatedTasksSection: some View {
        Section {
            if viewModel.availableTasks.isEmpty {
                Text("No automated tasks available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(viewModel.availableTasks, id: \.id) { task in
                    Toggle(isOn: viewModel.binding(for: task.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(task.name)
                                    .font(.subheadline)
                                Spacer()
                                TaskPriorityBadge(priority: task.priority)
                            }
                            Text(task.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Label(task.category.rawValue, systemImage: "folder.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(task.trigger.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        } header: {
            HStack {
                Text("Automated Tasks")
                Spacer()
                Text("\(viewModel.availableTasks.count) available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        } footer: {
            Text("Enable tasks to run automatically based on their triggers. Manual tasks can be executed from the Owner Features section.")
        }
    }
    
    // MARK: - Owner Features Section
    
    private var ownerFeaturesSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.seedMarketplace()
                }
            } label: {
                Label("Seed Marketplace", systemImage: "square.and.arrow.down.fill")
            }
            .disabled(viewModel.isExecutingTask)
            
            Button {
                Task {
                    await viewModel.convertPackage()
                }
            } label: {
                Label("Convert Package to Hub", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(viewModel.isExecutingTask)
            
            Button {
                Task {
                    await viewModel.generateSystemAnalytics()
                }
            } label: {
                Label("Generate System Analytics", systemImage: "chart.bar.fill")
            }
            .disabled(viewModel.isExecutingTask)
            
            Button {
                Task {
                    await viewModel.backupAllContent()
                }
            } label: {
                Label("Backup All Content", systemImage: "externaldrive.fill")
            }
            .disabled(viewModel.isExecutingTask)
        } header: {
            Text("Owner Tools")
        } footer: {
            Text("These tools are only available to users with the Owner role.")
        }
    }
    
    // MARK: - Owner Analytics Section
    
    private var ownerAnalyticsSection: some View {
        Section {
            if let analytics = viewModel.ownerAnalytics {
                LabeledContent("Total Hubs", value: "\(analytics.totalHubs)")
                LabeledContent("Total Templates", value: "\(analytics.totalTemplates)")
                LabeledContent("Total Users", value: "\(analytics.totalUsers)")
                LabeledContent("Marketplace Items", value: "\(analytics.marketplaceItems)")
                LabeledContent("System Uptime", value: analytics.systemUptime)
                LabeledContent("Storage Used", value: analytics.storageUsed)
                LabeledContent("Last Backup") {
                    Text(analytics.lastBackup, style: .relative)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Active Automations", value: "\(analytics.activeAutomations)")
            } else {
                ProgressView("Loading analytics...")
            }
        } header: {
            Text("System Analytics")
        } footer: {
            Text("Real-time system statistics and metrics.")
        }
    }
    
    // MARK: - Task History Section
    
    private var taskHistorySection: some View {
        Section {
            let statistics = viewModel.getTaskStatistics()
            
            LabeledContent("Total Executions", value: "\(statistics.totalExecutions)")
            LabeledContent("Completed", value: "\(statistics.completedTasks)")
            LabeledContent("Failed", value: "\(statistics.failedTasks)")
            LabeledContent("Success Rate") {
                Text(String(format: "%.1f%%", statistics.successRate * 100))
                    .foregroundStyle(statistics.successRate > 0.8 ? .green : .orange)
            }
            LabeledContent("Avg Duration") {
                Text(String(format: "%.1fs", statistics.averageDuration))
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showTaskHistory = true
            } label: {
                HStack {
                    Text("View Full History")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Task Execution Statistics")
        }
    }
}

// MARK: - Task Priority Badge

struct TaskPriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundStyle(.white)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Task History View

struct TaskHistoryView: View {
    @ObservedObject var viewModel: RoleSettingsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                let history = viewModel.getTaskHistory()
                
                if history.isEmpty {
                    ContentUnavailableView(
                        "No Task History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Task execution history will appear here")
                    )
                } else {
                    ForEach(history) { execution in
                        TaskExecutionRow(execution: execution)
                    }
                }
            }
            .navigationTitle("Task History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Task Execution Row

struct TaskExecutionRow: View {
    let execution: TaskExecution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(execution.task.name)
                    .font(.headline)
                Spacer()
                statusBadge
            }
            
            Text(execution.task.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Label(execution.startTime.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let endTime = execution.endTime {
                    Spacer()
                    let duration = endTime.timeIntervalSince(execution.startTime)
                    Text(String(format: "%.1fs", duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch execution.status {
        case .running:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Running")
                    .font(.caption)
            }
            .foregroundStyle(.blue)
        case .completed:
            Label("Completed", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed(let error):
            Label("Failed", systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .help(error)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoleSettingsView()
    }
}

