import SwiftUI
import Combine

@MainActor
public class SettingsMainViewModel: ObservableObject {
    @Published var accountVM: AccountSettingsViewModel
    @Published var editorVM: EditorSettingsViewModel
    @Published var builderVM: BuilderSettingsViewModel
    @Published var enterpriseVM: EnterpriseSettingsViewModel
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let loadSettingsUseCase: LoadSettingsUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let settingsManager: SettingsManager
    // TEMPORARY: Auth disabled
    // private let authManager: AppAuthManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    public init(
        settingsManager: SettingsManager,
        loadSettingsUseCase: LoadSettingsUseCase,
        saveSettingsUseCase: SaveSettingsUseCase
    ) {
        // TEMPORARY: Auth disabled
        // self.authManager = authManager
        self.settingsManager = settingsManager
        self.loadSettingsUseCase = loadSettingsUseCase
        self.saveSettingsUseCase = saveSettingsUseCase
        
        // Initialize sub-ViewModels with current settings or defaults
        let currentSettings = settingsManager.currentSettings
        
        self.accountVM = AccountSettingsViewModel()
        self.editorVM = EditorSettingsViewModel(
            preferences: currentSettings?.editorPreferences ?? EditorPreferences(),
            settingsManager: settingsManager
        )
        self.builderVM = BuilderSettingsViewModel(
            preferences: currentSettings?.builderPreferences ?? BuilderPreferences(),
            settingsManager: settingsManager
        )
        self.enterpriseVM = EnterpriseSettingsViewModel(
            preferences: currentSettings?.enterprisePreferences ?? EnterprisePreferences(),
            settingsManager: settingsManager
        )
        
        setupBindings()
    }
    
    @MainActor
    public convenience init(settingsManager: SettingsManager) {
        self.init(
            settingsManager: settingsManager,
            loadSettingsUseCase: LoadSettingsUseCase(settingsManager: settingsManager),
            saveSettingsUseCase: SaveSettingsUseCase(settingsManager: settingsManager)
        )
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // TEMPORARY: Auth disabled - no bindings needed
        // authManager.objectWillChange
        //     .sink { [weak self] _ in
        //         Task { @MainActor in
        //             await self?.loadAllSettings()
        //         }
        //     }
        //     .store(in: &cancellables)
    }
    
    // MARK: - Load Settings
    
    func loadAllSettings() async {
        // TEMPORARY: Auth disabled - using temp user ID
        let userID = "temp-id"
        
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try loadSettingsUseCase.execute(for: userID)
            
            // Update sub-ViewModels with loaded settings
            editorVM = EditorSettingsViewModel(
                preferences: settings.editorPreferences,
                settingsManager: settingsManager
            )
            builderVM = BuilderSettingsViewModel(
                preferences: settings.builderPreferences,
                settingsManager: settingsManager
            )
            enterpriseVM = EnterpriseSettingsViewModel(
                preferences: settings.enterprisePreferences,
                settingsManager: settingsManager
            )
            
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Save Settings
    
    func saveAllSettings() {
        do {
            // Settings are auto-saved by individual ViewModels
            // This method can be used for explicit saves if needed
            try saveSettingsUseCase.execute()
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reset Settings
    
    func resetToDefaults() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try settingsManager.resetToDefaults()
            await loadAllSettings()
        } catch {
            errorMessage = "Failed to reset settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var currentSettings: AppSettings? {
        settingsManager.currentSettings
    }
}
