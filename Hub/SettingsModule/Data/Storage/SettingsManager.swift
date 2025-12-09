import SwiftData
import Combine
import Foundation

@MainActor
public class SettingsManager: ObservableObject {
    @Published var currentSettings: AppSettings?
    @Published var isSyncing: Bool = false
    
    private let modelContext: ModelContext
    private let cloudKitSync: SettingsCloudKitSync?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    public init(modelContext: ModelContext, cloudKitSync: SettingsCloudKitSync? = nil) {
        self.modelContext = modelContext
        // Only use CloudKit if explicitly provided (disabled by default until configured)
        self.cloudKitSync = cloudKitSync
        
        // Observe CloudKit sync status if available
        cloudKitSync?.$isSyncing
            .assign(to: &$isSyncing)
    }
    
    // MARK: - Load Settings
    
    /// Loads settings for the specified user, creating default settings if none exist
    func loadSettings(for userID: String) throws {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.userID == userID }
        )
        
        let results = try modelContext.fetch(descriptor)
        
        if let existing = results.first {
            currentSettings = existing
        } else {
            // Create default settings for new user
            let newSettings = AppSettings(
                userID: userID,
                p2pDisplayName: "User-\(userID.prefix(8))"
            )
            modelContext.insert(newSettings)
            try modelContext.save()
            currentSettings = newSettings
        }
    }
    
    // MARK: - Save Settings
    
    /// Saves the current settings to persistent storage
    func saveSettings() throws {
        guard currentSettings != nil else {
            throw SettingsError.noCurrentSettings
        }
        
        currentSettings?.updatedAt = Date()
        try modelContext.save()
        
        // Propagate changes to all modules
        propagateSettings()
    }
    
    // MARK: - Update Methods
    
    func updateEditorMode(_ mode: AppSettings.EditorMode) throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        settings.updateEditorMode(mode)
        try saveSettings()
    }
    
    func updateEditorPreferences(_ preferences: EditorPreferences) throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        settings.editorPreferences = preferences
        try saveSettings()
        propagateEditorPreferences()
    }
    
    func updateBuilderPreferences(_ preferences: BuilderPreferences) throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        settings.builderPreferences = preferences
        try saveSettings()
        propagateBuilderPreferences()
    }
    
    func updateP2PSettings(displayName: String, autoAccept: Bool) throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        settings.updateP2PSettings(displayName: displayName, autoAccept: autoAccept)
        try saveSettings()
    }
    
    func updateEnterprisePreferences(_ preferences: EnterprisePreferences) throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        settings.enterprisePreferences = preferences
        try saveSettings()
        propagateEnterprisePreferences()
    }
    
    // MARK: - CloudKit Sync
    
    func enableSync() async throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        guard let cloudKitSync = cloudKitSync else {
            throw SettingsError.cloudKitNotConfigured
        }
        
        settings.syncEnabled = true
        try saveSettings()
        
        // Push to CloudKit
        try await cloudKitSync.pushSettings(settings)
        
        // Setup subscription for updates
        try await cloudKitSync.setupSubscription()
    }
    
    func disableSync() throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        settings.syncEnabled = false
        try saveSettings()
    }
    
    func syncWithCloud() async throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        guard let cloudKitSync = cloudKitSync else {
            throw SettingsError.cloudKitNotConfigured
        }
        
        guard settings.syncEnabled else {
            throw SettingsError.syncDisabled
        }
        
        let syncedSettings = try await cloudKitSync.syncSettings(settings)
        
        // Update local settings if remote was newer
        if syncedSettings.updatedAt > settings.updatedAt {
            currentSettings = syncedSettings
            try saveSettings()
        }
    }
    
    func pushToCloud() async throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        guard let cloudKitSync = cloudKitSync else {
            throw SettingsError.cloudKitNotConfigured
        }
        
        guard settings.syncEnabled else {
            throw SettingsError.syncDisabled
        }
        
        try await cloudKitSync.pushSettings(settings)
    }
    
    func pullFromCloud() async throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        guard let cloudKitSync = cloudKitSync else {
            throw SettingsError.cloudKitNotConfigured
        }
        
        guard settings.syncEnabled else {
            throw SettingsError.syncDisabled
        }
        
        if let remoteSettings = try await cloudKitSync.pullSettings(for: settings.userID) {
            currentSettings = remoteSettings
            try saveSettings()
        }
    }
    
    // MARK: - Reset
    
    /// Resets settings to defaults for the current user
    func resetToDefaults() throws {
        guard let settings = currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        let userID = settings.userID
        modelContext.delete(settings)
        
        let newSettings = AppSettings(
            userID: userID,
            p2pDisplayName: "User-\(userID.prefix(8))"
        )
        modelContext.insert(newSettings)
        try modelContext.save()
        currentSettings = newSettings
    }
}

// MARK: - Errors

enum SettingsError: LocalizedError {
    case noCurrentSettings
    case saveFailed(Error)
    case loadFailed(Error)
    case syncDisabled
    case cloudKitNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .noCurrentSettings:
            return "No settings loaded for current user"
        case .saveFailed(let error):
            return "Failed to save settings: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load settings: \(error.localizedDescription)"
        case .syncDisabled:
            return "CloudKit sync is not enabled"
        case .cloudKitNotConfigured:
            return "CloudKit sync is not configured for this app"
        }
    }
}
