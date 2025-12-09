import SwiftUI
import Combine

@MainActor
public class BuilderSettingsViewModel: ObservableObject {
    @Published var preferences: BuilderPreferences
    @Published var isClearing: Bool = false
    @Published var cacheSize: Int64 = 0
    @Published var errorMessage: String?
    
    private let clearBuildCacheUseCase: ClearBuildCacheUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let settingsManager: SettingsManager
    private let builderService: HubBuilderService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    public init(
        preferences: BuilderPreferences,
        settingsManager: SettingsManager,
        clearBuildCacheUseCase: ClearBuildCacheUseCase,
        saveSettingsUseCase: SaveSettingsUseCase,
        builderService: HubBuilderService
    ) {
        self.preferences = preferences
        self.settingsManager = settingsManager
        self.clearBuildCacheUseCase = clearBuildCacheUseCase
        self.saveSettingsUseCase = saveSettingsUseCase
        self.builderService = builderService
        
        setupBindings()
        loadCacheSize()
    }
    
    @MainActor
    public convenience init(
        preferences: BuilderPreferences,
        settingsManager: SettingsManager
    ) {
        self.init(
            preferences: preferences,
            settingsManager: settingsManager,
            clearBuildCacheUseCase: ClearBuildCacheUseCase(),
            saveSettingsUseCase: SaveSettingsUseCase(settingsManager: settingsManager),
            builderService: .shared
        )
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Auto-save preferences when they change
        $preferences
            .dropFirst() // Skip initial value
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] newPreferences in
                self?.savePreferences(newPreferences)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func clearCacheButtonTapped() async {
        isClearing = true
        errorMessage = nil
        
        do {
            let result = try await clearBuildCacheUseCase.execute()
            cacheSize = 0
            print("Cleared cache: \(result.formattedSize)")
        } catch {
            errorMessage = "Failed to clear cache: \(error.localizedDescription)"
        }
        
        isClearing = false
    }
    
    func refreshCacheSize() {
        loadCacheSize()
    }
    
    // MARK: - Private Methods
    
    private func savePreferences(_ newPreferences: BuilderPreferences) {
        do {
            try settingsManager.updateBuilderPreferences(newPreferences)
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }
    
    private func loadCacheSize() {
        do {
            cacheSize = try builderService.getBuildsDirectorySize()
        } catch {
            print("Failed to get cache size: \(error.localizedDescription)")
            cacheSize = 0
        }
    }
    
    // MARK: - Computed Properties
    
    var cacheSizeFormatted: String {
        let mb = Double(cacheSize) / 1_048_576.0
        let gb = Double(cacheSize) / 1_073_741_824.0
        
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }
}
