//
//  StorageConfigurationDemo.swift
//  Hub
//
//  Demo showing how to use the storage configuration system
//  Demonstrates various configuration scenarios and best practices
//

import Foundation
import SwiftUI

/// Demo view showing storage configuration usage
struct StorageConfigurationDemo: View {
    @State private var currentConfig: StorageConfiguration = StorageConfigurationManager.shared.currentConfiguration
    @State private var configDescription: String = ""
    @State private var validationErrors: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Storage Configuration Demo")
                    .font(.title)
                    .bold()
                
                // Current Configuration
                GroupBox("Current Configuration") {
                    Text(currentConfig.description)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Validation Status
                GroupBox("Validation") {
                    if validationErrors.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Configuration is valid")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Configuration has errors:")
                                    .bold()
                            }
                            
                            ForEach(validationErrors, id: \.self) { error in
                                Text("• \(error)")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // Preset Configurations
                GroupBox("Preset Configurations") {
                    VStack(spacing: 12) {
                        Button("Production") {
                            applyConfiguration(.production)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Development") {
                            applyConfiguration(.development)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Testing") {
                            applyConfiguration(.testing())
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Local Only") {
                            applyConfiguration(.localOnly)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("With CloudKit") {
                            applyConfiguration(.withCloudKit(containerIdentifier: "iCloud.com.example.hub"))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Custom Configuration Examples
                GroupBox("Custom Configuration Examples") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("High Performance") {
                            applyHighPerformanceConfig()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Low Memory") {
                            applyLowMemoryConfig()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Aggressive Sync") {
                            applyAggressiveSyncConfig()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Conservative Sync") {
                            applyConservativeSyncConfig()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Actions
                GroupBox("Actions") {
                    VStack(spacing: 12) {
                        Button("Reset to Default") {
                            StorageConfigurationManager.shared.resetToDefault()
                            loadCurrentConfiguration()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Validate Configuration") {
                            validateConfiguration()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadCurrentConfiguration()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentConfiguration() {
        currentConfig = StorageConfigurationManager.shared.currentConfiguration
        validateConfiguration()
    }
    
    private func applyConfiguration(_ config: StorageConfiguration) {
        do {
            try StorageConfigurationManager.shared.updateConfiguration(config)
            loadCurrentConfiguration()
        } catch {
            print("Failed to apply configuration: \(error)")
        }
    }
    
    private func validateConfiguration() {
        validationErrors = currentConfig.validate()
    }
    
    // MARK: - Custom Configurations
    
    private func applyHighPerformanceConfig() {
        let config = StorageConfiguration(
            localFirstStorageEnabled: true,
            performanceOptimizationsEnabled: true,
            autoIndexRepairEnabled: true,
            metricsEnabled: true,
            cloudKitEnabled: false,
            cacheCapacity: 5000,  // Large cache
            batchWriteSize: 50,  // Large batches
            batchWriteInterval: 10,  // Less frequent flushes
            memoryPressureThreshold: 0.9,  // Higher threshold
            cacheEvictionPercentage: 0.1  // Smaller evictions
        )
        applyConfiguration(config)
    }
    
    private func applyLowMemoryConfig() {
        let config = StorageConfiguration(
            localFirstStorageEnabled: true,
            performanceOptimizationsEnabled: true,
            autoIndexRepairEnabled: true,
            metricsEnabled: false,  // Disable metrics to save memory
            cloudKitEnabled: false,
            cacheCapacity: 100,  // Small cache
            batchWriteSize: 5,  // Small batches
            batchWriteInterval: 2,  // Frequent flushes
            memoryPressureThreshold: 0.6,  // Lower threshold
            cacheEvictionPercentage: 0.5  // Aggressive evictions
        )
        applyConfiguration(config)
    }
    
    private func applyAggressiveSyncConfig() {
        let config = StorageConfiguration(
            localFirstStorageEnabled: true,
            performanceOptimizationsEnabled: true,
            autoIndexRepairEnabled: true,
            metricsEnabled: true,
            cloudKitEnabled: true,
            cloudKitContainerIdentifier: "iCloud.com.example.hub",
            autoSyncEnabled: true,
            availabilityCheckInterval: 30,  // Check every 30 seconds
            syncInterval: 10,  // Sync every 10 seconds
            syncTimeout: 15,  // Short timeout
            retryInterval: 1,  // Fast retries
            maxRetryAttempts: 10  // Many retries
        )
        applyConfiguration(config)
    }
    
    private func applyConservativeSyncConfig() {
        let config = StorageConfiguration(
            localFirstStorageEnabled: true,
            performanceOptimizationsEnabled: true,
            autoIndexRepairEnabled: true,
            metricsEnabled: true,
            cloudKitEnabled: true,
            cloudKitContainerIdentifier: "iCloud.com.example.hub",
            autoSyncEnabled: true,
            availabilityCheckInterval: 600,  // Check every 10 minutes
            syncInterval: 300,  // Sync every 5 minutes
            syncTimeout: 60,  // Long timeout
            retryInterval: 30,  // Slow retries
            maxRetryAttempts: 3  // Few retries
        )
        applyConfiguration(config)
    }
}

// MARK: - Usage Examples

/// Example: Creating a storage coordinator with default configuration
func exampleDefaultConfiguration() async throws {
    // Uses current configuration from StorageConfigurationManager
    let coordinator = try await StorageCoordinator.create()
    
    print("Created coordinator with default configuration")
}

/// Example: Creating a storage coordinator with custom configuration
func exampleCustomConfiguration() async throws {
    // Create custom configuration
    let config = StorageConfiguration(
        localFirstStorageEnabled: true,
        performanceOptimizationsEnabled: true,
        cloudKitEnabled: true,
        cloudKitContainerIdentifier: "iCloud.com.example.hub",
        syncInterval: 60
    )
    
    // Create coordinator with custom configuration
    let coordinator = try await StorageCoordinator.create(configuration: config)
    
    print("Created coordinator with custom configuration")
}

/// Example: Using preset configurations
func examplePresetConfigurations() async throws {
    // Production configuration
    let prodCoordinator = try await StorageCoordinator.create(configuration: .production)
    
    // Development configuration
    let devCoordinator = try await StorageCoordinator.create(configuration: .development)
    
    // Testing configuration
    let testCoordinator = try await StorageCoordinator.create(configuration: .testing())
    
    // Local-only configuration
    let localCoordinator = try await StorageCoordinator.create(configuration: .localOnly)
    
    // CloudKit-enabled configuration
    let cloudCoordinator = try await StorageCoordinator.create(
        configuration: .withCloudKit(containerIdentifier: "iCloud.com.example.hub")
    )
    
    print("Created coordinators with preset configurations")
}

/// Example: Updating global configuration
func exampleUpdateGlobalConfiguration() throws {
    // Update global configuration
    let config = StorageConfiguration(
        cloudKitEnabled: true,
        cloudKitContainerIdentifier: "iCloud.com.example.hub"
    )
    
    try StorageConfigurationManager.shared.updateConfiguration(config)
    
    print("Updated global configuration")
}

/// Example: Validating configuration
func exampleValidateConfiguration() {
    let config = StorageConfiguration(
        cloudKitEnabled: true,
        cloudKitContainerIdentifier: nil  // Invalid: CloudKit enabled but no container
    )
    
    let errors = config.validate()
    if errors.isEmpty {
        print("Configuration is valid")
    } else {
        print("Configuration errors:")
        for error in errors {
            print("  - \(error)")
        }
    }
}

/// Example: Feature flag usage
func exampleFeatureFlags() async throws {
    // Check if local-first storage is enabled
    let config = StorageConfigurationManager.shared.currentConfiguration
    
    if config.localFirstStorageEnabled {
        // Use new local-first storage
        let coordinator = try await StorageCoordinator.create()
        print("Using local-first storage")
    } else {
        // Use legacy storage
        print("Using legacy storage")
    }
    
    // Check if performance optimizations are enabled
    if config.performanceOptimizationsEnabled {
        print("Performance optimizations enabled")
    }
    
    // Check if CloudKit is enabled
    if config.cloudKitEnabled {
        print("CloudKit sync enabled")
    } else {
        print("Local-only mode")
    }
}

/// Example: Testing with custom storage URL
func exampleTestingConfiguration() async throws {
    // Create temporary directory for testing
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("StorageTests")
        .appendingPathComponent(UUID().uuidString)
    
    // Create testing configuration with custom storage URL
    let config = StorageConfiguration.testing(storageURL: tempDir)
    
    // Create coordinator for testing
    let coordinator = try await StorageCoordinator.create(configuration: config)
    
    print("Created test coordinator with isolated storage at: \(tempDir)")
    
    // Clean up after tests
    try? FileManager.default.removeItem(at: tempDir)
}

/// Example: Migration from legacy to new storage
func exampleMigrationConfiguration() async throws {
    // Start with legacy storage
    try StorageConfigurationManager.shared.updateConfiguration(.legacy)
    
    // ... perform migration ...
    
    // Switch to new storage
    try StorageConfigurationManager.shared.updateConfiguration(.production)
    
    print("Migrated from legacy to new storage")
}

// MARK: - Preview

#Preview {
    StorageConfigurationDemo()
}
