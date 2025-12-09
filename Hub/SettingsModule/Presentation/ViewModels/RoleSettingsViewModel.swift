//
//  RoleSettingsViewModel.swift
//  Hub
//
//  ViewModel for role settings management
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class RoleSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedRole: UserRole
    @Published var currentCapabilities: [RoleCapability] = []
    @Published var availableTasks: [AutomatedTask] = []
    @Published var isExecutingTask = false
    @Published var taskExecutionStatus: String?
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var ownerAnalytics: OwnerAnalytics?
    
    // MARK: - Dependencies
    
    private let roleManager: RoleManager
    private let templateManager: TemplateManager?
    private let hubManager: HubManager?
    private let marketplaceService: LocalMarketplaceService?
    private let modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        roleManager: RoleManager = .shared,
        templateManager: TemplateManager? = nil,
        hubManager: HubManager? = nil,
        marketplaceService: LocalMarketplaceService? = nil,
        modelContext: ModelContext? = nil
    ) {
        self.roleManager = roleManager
        self.templateManager = templateManager
        self.hubManager = hubManager
        self.marketplaceService = marketplaceService
        self.modelContext = modelContext
        self.selectedRole = roleManager.currentRole
        
        setupObservers()
        updateCapabilities()
        updateAvailableTasks()
        
        if roleManager.isOwner {
            loadOwnerAnalytics()
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe role changes
        roleManager.$currentRole
            .sink { [weak self] newRole in
                self?.selectedRole = newRole
                self?.updateCapabilities()
                self?.updateAvailableTasks()
                
                if newRole == .owner {
                    self?.loadOwnerAnalytics()
                } else {
                    self?.ownerAnalytics = nil
                }
            }
            .store(in: &cancellables)
        
        // Observe task execution status
        roleManager.$isExecutingTask
            .sink { [weak self] isExecuting in
                self?.isExecutingTask = isExecuting
            }
            .store(in: &cancellables)
        
        // Observe enabled tasks changes
        roleManager.$enabledTasks
            .sink { [weak self] _ in
                self?.updateAvailableTasks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Role Management
    
    public func changeRole(_ newRole: UserRole) {
        roleManager.setRole(newRole)
        selectedRole = newRole
        updateCapabilities()
        updateAvailableTasks()
        
        if newRole == .owner {
            loadOwnerAnalytics()
        } else {
            ownerAnalytics = nil
        }
    }
    
    public func updateCapabilities() {
        currentCapabilities = roleManager.availableCapabilities()
    }
    
    public func updateAvailableTasks() {
        availableTasks = roleManager.availableTasks()
    }
    
    // MARK: - Task Management
    
    public func binding(for taskId: UUID) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.roleManager.enabledTasks.contains(taskId) ?? false
            },
            set: { [weak self] _ in
                self?.roleManager.toggleTask(taskId)
            }
        )
    }
    
    public func executeTask(_ task: AutomatedTask) async {
        taskExecutionStatus = "Executing \(task.name)..."
        
        do {
            try await roleManager.executeTask(task)
            taskExecutionStatus = "\(task.name) completed successfully"
            
            // Clear status after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            taskExecutionStatus = nil
        } catch {
            errorMessage = "Failed to execute \(task.name): \(error.localizedDescription)"
            showError = true
            taskExecutionStatus = nil
        }
    }
    
    public func getTaskHistory() -> [TaskExecution] {
        return roleManager.taskHistory
    }
    
    public func getTaskStatistics() -> TaskStatistics {
        return roleManager.taskStatistics()
    }
    
    // MARK: - Owner-Specific Features
    
    /// Seed the marketplace with all local Hubs and Templates
    /// Requirement 3.4: Owner can seed marketplace
    /// Requirement 8.1: Scan all local Hubs and Templates
    public func seedMarketplace() async {
        guard roleManager.isOwner else {
            errorMessage = "Only owners can seed the marketplace"
            showError = true
            return
        }
        
        taskExecutionStatus = "Seeding marketplace..."
        isExecutingTask = true
        
        do {
            // Use MarketplaceSeeder if available
            if let templateManager = templateManager,
               let hubManager = hubManager,
               let marketplaceService = marketplaceService,
               let modelContext = modelContext {
                
                let seeder = MarketplaceSeeder(
                    templateManager: templateManager,
                    hubManager: hubManager,
                    marketplaceService: marketplaceService,
                    modelContext: modelContext
                )
                
                let result = try await seeder.seedMarketplace()
                
                taskExecutionStatus = """
                Marketplace seeded successfully!
                Templates: \(result.templatesAdded)
                Hubs: \(result.hubsAdded)
                Previews: \(result.previewsGenerated)
                """
                
                // Reload analytics
                loadOwnerAnalytics()
                
                // Clear status after 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                taskExecutionStatus = nil
            } else {
                // Fallback to task execution
                if let seedTask = availableTasks.first(where: { $0.name == "Seed Marketplace" }) {
                    await executeTask(seedTask)
                }
            }
        } catch {
            errorMessage = "Failed to seed marketplace: \(error.localizedDescription)"
            showError = true
            taskExecutionStatus = nil
        }
        
        isExecutingTask = false
    }
    
    /// Convert a Swift package to a Hub
    /// Requirement 3.4: Owner can convert packages
    public func convertPackage() async {
        guard roleManager.isOwner else {
            errorMessage = "Only owners can convert packages"
            showError = true
            return
        }
        
        if let convertTask = availableTasks.first(where: { $0.name == "Convert Package to Hub" }) {
            await executeTask(convertTask)
        }
    }
    
    /// Generate comprehensive system analytics
    /// Requirement 3.4: Owner can view system analytics
    public func generateSystemAnalytics() async {
        guard roleManager.isOwner else {
            errorMessage = "Only owners can generate system analytics"
            showError = true
            return
        }
        
        if let analyticsTask = availableTasks.first(where: { $0.name == "Generate System Analytics" }) {
            await executeTask(analyticsTask)
        }
        
        // Reload analytics after generation
        loadOwnerAnalytics()
    }
    
    /// Backup all Hubs, Templates, and user data
    /// Requirement 3.4: Owner can backup all content
    public func backupAllContent() async {
        guard roleManager.isOwner else {
            errorMessage = "Only owners can backup all content"
            showError = true
            return
        }
        
        if let backupTask = availableTasks.first(where: { $0.name == "Backup All Content" }) {
            await executeTask(backupTask)
        }
    }
    
    /// Load owner analytics data
    /// Requirement 3.4: Provide owner analytics data
    private func loadOwnerAnalytics() {
        // Fetch real analytics data if services are available
        let totalHubs = hubManager?.getAllHubs().count ?? 0
        let totalTemplates = templateManager?.templates.count ?? 0
        let marketplaceItems = (marketplaceService?.localContent.count ?? 0)
        
        // Calculate storage used (simplified)
        let storageUsed = calculateStorageUsed()
        
        // Get last backup time from task history
        let lastBackup = getLastBackupTime()
        
        ownerAnalytics = OwnerAnalytics(
            totalHubs: totalHubs,
            totalTemplates: totalTemplates,
            totalUsers: 1, // Single user for now
            marketplaceItems: marketplaceItems,
            systemUptime: "99.8%", // Mock value
            storageUsed: storageUsed,
            lastBackup: lastBackup,
            activeAutomations: roleManager.enabledTasks.count
        )
    }
    
    /// Calculate storage used by the system
    private func calculateStorageUsed() -> String {
        // Simplified calculation
        let templateCount = templateManager?.templates.count ?? 0
        let hubCount = hubManager?.getAllHubs().count ?? 0
        
        // Estimate: ~100KB per template, ~500KB per hub
        let estimatedBytes = (templateCount * 100_000) + (hubCount * 500_000)
        
        return formatBytes(estimatedBytes)
    }
    
    /// Format bytes to human-readable string
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Get the last backup time from task history
    private func getLastBackupTime() -> Date {
        let backupExecutions = roleManager.taskHistory.filter { execution in
            execution.task.name == "Backup All Content" && execution.status == .completed
        }
        
        return backupExecutions.first?.endTime ?? Date().addingTimeInterval(-86400)
    }
}

// MARK: - Supporting Types

public struct OwnerAnalytics {
    public let totalHubs: Int
    public let totalTemplates: Int
    public let totalUsers: Int
    public let marketplaceItems: Int
    public let systemUptime: String
    public let storageUsed: String
    public let lastBackup: Date
    public let activeAutomations: Int
}
