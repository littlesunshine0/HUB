import SwiftUI
import Combine

// MARK: - Settings Sync View

struct SettingsSyncView: View {
    @ObservedObject var coordinator: SettingsSyncCoordinator
    @ObservedObject var settingsManager: SettingsManager
    
    @State private var showingEnableAlert = false
    @State private var showingForceOptions = false
    
    var body: some View {
        Form {
            // Sync Status Section
            Section("Sync Status") {
                HStack {
                    Image(systemName: coordinator.syncStatus.icon)
                        .foregroundColor(statusColor)
                    Text(coordinator.syncStatus.description)
                    Spacer()
                    if coordinator.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if let lastSync = coordinator.lastSyncDate {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = coordinator.syncError {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Sync Control Section
            Section("Sync Control") {
                Toggle("Enable CloudKit Sync", isOn: Binding(
                    get: { settingsManager.currentSettings?.syncEnabled ?? false },
                    set: { newValue in
                        if newValue {
                            showingEnableAlert = true
                        } else {
                            disableSync()
                        }
                    }
                ))
                
                if settingsManager.currentSettings?.syncEnabled == true {
                    Button {
                        Task {
                            await coordinator.performSync()
                        }
                    } label: {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(coordinator.isSyncing)
                    
                    Button {
                        showingForceOptions = true
                    } label: {
                        Label("Advanced Sync Options", systemImage: "gearshape")
                    }
                }
            }
            
            // Information Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About CloudKit Sync")
                        .font(.headline)
                    
                    Text("When enabled, your settings will automatically sync across all your devices using iCloud.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Settings sync every 5 minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Changes are synced immediately when you save")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Conflicts are resolved automatically (newer wins)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Information")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings Sync")
        .alert("Enable CloudKit Sync?", isPresented: $showingEnableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                enableSync()
            }
        } message: {
            Text("This will sync your settings to iCloud and across all your devices. Make sure you're signed in to iCloud.")
        }
        .confirmationDialog("Advanced Sync Options", isPresented: $showingForceOptions) {
            Button("Force Upload to Cloud") {
                Task {
                    try? await coordinator.forcePush()
                }
            }
            Button("Force Download from Cloud") {
                Task {
                    try? await coordinator.forcePull()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Force operations will overwrite either local or remote settings. Use with caution.")
        }
    }
    
    // MARK: - Actions
    
    private func enableSync() {
        Task {
            do {
                try await settingsManager.enableSync()
                coordinator.startAutoSync()
            } catch {
                print("Failed to enable sync: \(error)")
            }
        }
    }
    
    private func disableSync() {
        do {
            try settingsManager.disableSync()
            coordinator.stopAutoSync()
        } catch {
            print("Failed to disable sync: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch coordinator.syncStatus {
        case .idle:
            return .blue
        case .syncing:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

// MARK: - Sync Status Badge

struct SyncStatusBadge: View {
    let status: SettingsSyncStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            Text(statusText)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private var statusText: String {
        switch status {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing"
        case .completed:
            return "Synced"
        case .failed:
            return "Failed"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .idle:
            return .blue
        case .syncing:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Form {
            Text("Settings Sync Preview")
        }
    }
}
