import Foundation

// MARK: - Save Settings Use Case

@MainActor
public class SaveSettingsUseCase {
    private let settingsManager: SettingsManager
    private let notificationService: AppNotificationService
    
    // MARK: - Initializer
    
    public init(
        settingsManager: SettingsManager,
        notificationService: AppNotificationService
    ) {
        self.settingsManager = settingsManager
        self.notificationService = notificationService
    }
    
    public convenience init(settingsManager: SettingsManager) {
        self.init(settingsManager: settingsManager, notificationService: .shared)
    }
    
    // MARK: - Execute
    
    /// Saves the current settings
    func execute() throws {
        try settingsManager.saveSettings()
        
        notificationService.post(
            message: "Settings saved successfully",
            level: .success
        )
    }
    
    /// Saves settings with a specific update
    func execute<T>(update: (AppSettings) -> T) throws -> T {
        guard let settings = settingsManager.currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        let result = update(settings)
        try settingsManager.saveSettings()
        
        notificationService.post(
            message: "Settings saved successfully",
            level: .success
        )
        
        return result
    }
}
