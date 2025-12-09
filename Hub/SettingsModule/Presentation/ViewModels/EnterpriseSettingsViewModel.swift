import SwiftUI
import Combine

@MainActor
public class EnterpriseSettingsViewModel: ObservableObject {
    @Published var preferences: EnterprisePreferences
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    public init(
        preferences: EnterprisePreferences,
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
                Task { @MainActor in
                    await self?.autoSavePreferences(newPreferences)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func saveSettings() async {
        isSaving = true
        errorMessage = nil
        
        do {
            try settingsManager.updateEnterprisePreferences(preferences)
            
            // If sync is enabled, push to cloud
            if settingsManager.currentSettings?.syncEnabled == true {
                try await settingsManager.pushToCloud()
            }
            
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func resetToDefaults() {
        preferences = EnterprisePreferences()
        errorMessage = nil
    }
    
    func updateOrganizationID(_ id: String) {
        preferences.organizationID = id.isEmpty ? nil : id
    }
    
    // MARK: - Private Methods
    
    private func autoSavePreferences(_ newPreferences: EnterprisePreferences) async {
        do {
            try settingsManager.updateEnterprisePreferences(newPreferences)
        } catch {
            errorMessage = "Auto-save failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var isEnterpriseEnabled: Bool {
        preferences.licenseType == .enterprise || preferences.licenseType == .unlimited
    }
    
    var estimatedMonthlyCost: Decimal {
        let baseCost: Decimal
        switch preferences.licenseType {
        case .trial: baseCost = 0
        case .standard: baseCost = 29
        case .professional: baseCost = 99
        case .enterprise: baseCost = 299
        case .unlimited: baseCost = 999
        }
        
        let seatCost = baseCost * Decimal(preferences.seatCount)
        let discount = seatCost * Decimal(preferences.volumeDiscountTier.discountPercentage / 100)
        
        return seatCost - discount
    }
    
    var formattedMonthlyCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: estimatedMonthlyCost as NSDecimalNumber) ?? "$0.00"
    }
}
