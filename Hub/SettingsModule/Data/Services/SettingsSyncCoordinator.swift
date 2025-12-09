import Foundation
import Combine
import CloudKit

// MARK: - Settings Sync Coordinator

/// Coordinates automatic syncing of settings between local storage and CloudKit
@MainActor
public class SettingsSyncCoordinator: ObservableObject {
    @Published public private(set) var syncStatus: SettingsSyncStatus = .idle
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncError: Error?
    
    private let settingsManager: SettingsManager
    private let cloudKitSync: SettingsCloudKitSync?
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Sync configuration
    private let autoSyncInterval: TimeInterval = 300 // 5 minutes
    private let conflictResolutionStrategy: ConflictResolutionStrategy = .newerWins
    
    // MARK: - Initializer
    
    public init(
        settingsManager: SettingsManager,
        cloudKitSync: SettingsCloudKitSync? = nil
    ) {
        self.settingsManager = settingsManager
        self.cloudKitSync = cloudKitSync
        
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe settings changes for auto-sync
        settingsManager.objectWillChange
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.syncIfEnabled()
                }
            }
            .store(in: &cancellables)
        
        // Observe CloudKit sync status if available
        cloudKitSync?.$isSyncing
            .sink { [weak self] isSyncing in
                if isSyncing {
                    self?.syncStatus = .syncing
                } else if self?.syncStatus == .syncing {
                    self?.syncStatus = .idle
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync Control
    
    /// Starts automatic syncing
    public func startAutoSync() {
        guard settingsManager.currentSettings?.syncEnabled == true else {
            print("Settings Sync: Auto-sync not enabled")
            return
        }
        
        stopAutoSync() // Stop existing timer
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: autoSyncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSync()
            }
        }
        
        print("Settings Sync: Auto-sync started (interval: \(autoSyncInterval)s)")
        
        // Perform initial sync
        Task {
            await performSync()
        }
    }
    
    /// Stops automatic syncing
    public func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("Settings Sync: Auto-sync stopped")
    }
    
    /// Performs a manual sync
    public func performSync() async {
        guard let settings = settingsManager.currentSettings else {
            syncError = CoordinatorSyncError.noSettings
            return
        }
        
        guard let cloudKitSync = cloudKitSync else {
            syncError = CoordinatorSyncError.cloudKitNotConfigured
            return
        }
        
        guard settings.syncEnabled else {
            syncError = CoordinatorSyncError.syncDisabled
            return
        }
        
        syncStatus = .syncing
        syncError = nil
        
        do {
            // Fetch remote settings
            if let remoteSettings = try await cloudKitSync.pullSettings(for: settings.userID) {
                // Resolve conflicts
                let resolvedSettings = try await resolveConflict(
                    local: settings,
                    remote: remoteSettings
                )
                
                // Update local if needed
                if resolvedSettings.updatedAt > settings.updatedAt {
                    settingsManager.currentSettings = resolvedSettings
                    try settingsManager.saveSettings()
                    syncStatus = .completed(.downloaded)
                } else if resolvedSettings.updatedAt < settings.updatedAt {
                    // Push local changes
                    try await cloudKitSync.pushSettings(settings)
                    syncStatus = .completed(.uploaded)
                } else {
                    syncStatus = .completed(.upToDate)
                }
            } else {
                // No remote settings, push local
                try await cloudKitSync.pushSettings(settings)
                syncStatus = .completed(.uploaded)
            }
            
            lastSyncDate = Date()
            
        } catch {
            syncError = error
            syncStatus = .failed(error.localizedDescription)
            print("Settings Sync Error: \(error.localizedDescription)")
        }
    }
    
    /// Syncs only if sync is enabled
    private func syncIfEnabled() async {
        guard settingsManager.currentSettings?.syncEnabled == true else {
            return
        }
        
        await performSync()
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(
        local: AppSettings,
        remote: AppSettings
    ) async throws -> AppSettings {
        switch conflictResolutionStrategy {
        case .newerWins:
            return local.updatedAt > remote.updatedAt ? local : remote
            
        case .localWins:
            return local
            
        case .remoteWins:
            return remote
            
        case .merge:
            return try mergeSettings(local: local, remote: remote)
        }
    }
    
    private func mergeSettings(
        local: AppSettings,
        remote: AppSettings
    ) throws -> AppSettings {
        // Create a merged settings object
        let merged = AppSettings(
            userID: local.userID,
            defaultEditorMode: local.updatedAt > remote.updatedAt ? local.defaultEditorMode : remote.defaultEditorMode,
            p2pDisplayName: local.p2pDisplayName.isEmpty ? remote.p2pDisplayName : local.p2pDisplayName,
            p2pAutoAccept: local.p2pAutoAccept || remote.p2pAutoAccept,
            syncEnabled: local.syncEnabled
        )
        
        // Merge preferences (prefer newer)
        if local.updatedAt > remote.updatedAt {
            merged.editorPreferences = local.editorPreferences
            merged.builderPreferences = local.builderPreferences
            merged.enterprisePreferences = local.enterprisePreferences
        } else {
            merged.editorPreferences = remote.editorPreferences
            merged.builderPreferences = remote.builderPreferences
            merged.enterprisePreferences = remote.enterprisePreferences
        }
        
        merged.updatedAt = max(local.updatedAt, remote.updatedAt)
        
        return merged
    }
    
    // MARK: - Force Operations
    
    /// Forces a push to CloudKit, overwriting remote
    public func forcePush() async throws {
        guard let settings = settingsManager.currentSettings else {
            throw CoordinatorSyncError.noSettings
        }
        
        guard let cloudKitSync = cloudKitSync else {
            throw CoordinatorSyncError.cloudKitNotConfigured
        }
        
        syncStatus = .syncing
        
        do {
            try await cloudKitSync.pushSettings(settings)
            syncStatus = .completed(.uploaded)
            lastSyncDate = Date()
        } catch {
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }
    
    /// Forces a pull from CloudKit, overwriting local
    public func forcePull() async throws {
        guard let settings = settingsManager.currentSettings else {
            throw CoordinatorSyncError.noSettings
        }
        
        guard let cloudKitSync = cloudKitSync else {
            throw CoordinatorSyncError.cloudKitNotConfigured
        }
        
        syncStatus = .syncing
        
        do {
            if let remoteSettings = try await cloudKitSync.pullSettings(for: settings.userID) {
                settingsManager.currentSettings = remoteSettings
                try settingsManager.saveSettings()
                syncStatus = .completed(.downloaded)
                lastSyncDate = Date()
            } else {
                throw CoordinatorSyncError.noRemoteSettings
            }
        } catch {
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Status Helpers
    
    public var isSyncing: Bool {
        if case .syncing = syncStatus {
            return true
        }
        return false
    }
    
    public var lastSyncDescription: String {
        guard let date = lastSyncDate else {
            return "Never synced"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - Sync Status

public enum SettingsSyncStatus: Equatable {
    case idle
    case syncing
    case completed(SyncResult)
    case failed(String) // Changed from Error to String for Equatable conformance
    
    public static func == (lhs: SettingsSyncStatus, rhs: SettingsSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.syncing, .syncing): return true
        case (.completed(let l), .completed(let r)): return l == r
        case (.failed(let l), .failed(let r)): return l == r
        default: return false
        }
    }
    
    var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .completed(let result):
            return result.description
        case .failed(let message):
            return "Failed: \(message)"
        }
    }
    
    var icon: String {
        switch self {
        case .idle:
            return "icloud"
        case .syncing:
            return "icloud.and.arrow.up.and.down"
        case .completed:
            return "icloud.and.arrow.up"
        case .failed:
            return "icloud.slash"
        }
    }
}

// MARK: - Sync Result

public enum SyncResult: Equatable {
    case uploaded
    case downloaded
    case upToDate
    
    var description: String {
        switch self {
        case .uploaded:
            return "Uploaded to cloud"
        case .downloaded:
            return "Downloaded from cloud"
        case .upToDate:
            return "Up to date"
        }
    }
}

// MARK: - Conflict Resolution Strategy

public enum ConflictResolutionStrategy {
    case newerWins
    case localWins
    case remoteWins
    case merge
}

// MARK: - Coordinator Sync Errors

enum CoordinatorSyncError: LocalizedError {
    case noSettings
    case syncDisabled
    case noRemoteSettings
    case cloudKitNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .noSettings:
            return "No settings available to sync"
        case .syncDisabled:
            return "Sync is not enabled"
        case .noRemoteSettings:
            return "No remote settings found"
        case .cloudKitNotConfigured:
            return "CloudKit sync is not configured"
        }
    }
}
