import SwiftUI
import Combine

@MainActor
public class EditorSettingsViewModel: ObservableObject {
    @Published var preferences: EditorPreferences
    @Published var errorMessage: String?
    
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    public init(
        preferences: EditorPreferences,
        settingsManager: SettingsManager
    ) {
        self.preferences = preferences
        self.settingsManager = settingsManager
        
        setupBindings()
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
    
    // MARK: - Private Methods
    
    private func savePreferences(_ newPreferences: EditorPreferences) {
        do {
            try settingsManager.updateEditorPreferences(newPreferences)
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }
}
