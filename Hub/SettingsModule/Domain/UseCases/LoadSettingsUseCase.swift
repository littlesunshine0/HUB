import Foundation

// MARK: - Load Settings Use Case

@MainActor
public class LoadSettingsUseCase {
    private let settingsManager: SettingsManager
    
    // MARK: - Initializer
    
    public init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Execute
    
    /// Loads settings for the specified user
    func execute(for userID: String) throws -> AppSettings {
        try settingsManager.loadSettings(for: userID)
        
        guard let settings = settingsManager.currentSettings else {
            throw SettingsError.noCurrentSettings
        }
        
        return settings
    }
    
    /// Loads settings for the current user if available
    func execute() throws -> AppSettings? {
        return settingsManager.currentSettings
    }
}
