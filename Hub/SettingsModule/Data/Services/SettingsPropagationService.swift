import Foundation
import Combine

// MARK: - Settings Propagation Service

/// Service responsible for propagating settings changes across all modules
@MainActor
public class SettingsPropagationService: ObservableObject {
    public static let shared = SettingsPropagationService()
    
    // Publishers for different settings types
    @Published public private(set) var editorPreferences: EditorPreferences?
    @Published public private(set) var builderPreferences: BuilderPreferences?
    @Published public private(set) var enterprisePreferences: EnterprisePreferences?
    
    // Event stream for settings changes
    public let settingsChanged = PassthroughSubject<SettingsChangeEvent, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe editor preferences changes
        $editorPreferences
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] preferences in
                self?.settingsChanged.send(.editorPreferencesChanged(preferences))
            }
            .store(in: &cancellables)
        
        // Observe builder preferences changes
        $builderPreferences
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] preferences in
                self?.settingsChanged.send(.builderPreferencesChanged(preferences))
            }
            .store(in: &cancellables)
        
        // Observe enterprise preferences changes
        $enterprisePreferences
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] preferences in
                self?.settingsChanged.send(.enterprisePreferencesChanged(preferences))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Propagation Methods
    
    /// Propagates editor preferences to all listening modules
    public func propagateEditorPreferences(_ preferences: EditorPreferences) {
        editorPreferences = preferences
    }
    
    /// Propagates builder preferences to all listening modules
    public func propagateBuilderPreferences(_ preferences: BuilderPreferences) {
        builderPreferences = preferences
    }
    
    /// Propagates enterprise preferences to all listening modules
    public func propagateEnterprisePreferences(_ preferences: EnterprisePreferences) {
        enterprisePreferences = preferences
    }
    
    /// Propagates all settings at once
    public func propagateAllSettings(_ settings: AppSettings) {
        editorPreferences = settings.editorPreferences
        builderPreferences = settings.builderPreferences
        enterprisePreferences = settings.enterprisePreferences
        
        settingsChanged.send(.allSettingsChanged(settings))
    }
    
    // MARK: - Subscription Helpers
    
    /// Subscribe to editor preferences changes
    public func subscribeToEditorPreferences(_ handler: @escaping (EditorPreferences) -> Void) -> AnyCancellable {
        $editorPreferences
            .compactMap { $0 }
            .sink(receiveValue: handler)
    }
    
    /// Subscribe to builder preferences changes
    public func subscribeToBuilderPreferences(_ handler: @escaping (BuilderPreferences) -> Void) -> AnyCancellable {
        $builderPreferences
            .compactMap { $0 }
            .sink(receiveValue: handler)
    }
    
    /// Subscribe to enterprise preferences changes
    public func subscribeToEnterprisePreferences(_ handler: @escaping (EnterprisePreferences) -> Void) -> AnyCancellable {
        $enterprisePreferences
            .compactMap { $0 }
            .sink(receiveValue: handler)
    }
    
    /// Subscribe to all settings change events
    public func subscribeToSettingsChanges(_ handler: @escaping (SettingsChangeEvent) -> Void) -> AnyCancellable {
        settingsChanged.sink(receiveValue: handler)
    }
}

// MARK: - Settings Change Event

public enum SettingsChangeEvent {
    case editorPreferencesChanged(EditorPreferences)
    case builderPreferencesChanged(BuilderPreferences)
    case enterprisePreferencesChanged(EnterprisePreferences)
    case allSettingsChanged(AppSettings)
    
    var description: String {
        switch self {
        case .editorPreferencesChanged:
            return "Editor preferences changed"
        case .builderPreferencesChanged:
            return "Builder preferences changed"
        case .enterprisePreferencesChanged:
            return "Enterprise preferences changed"
        case .allSettingsChanged:
            return "All settings changed"
        }
    }
}

// MARK: - Module Integration Protocol

/// Protocol for modules that want to receive settings updates
public protocol SettingsObserver: AnyObject {
    func settingsDidChange(_ event: SettingsChangeEvent)
}

// MARK: - Settings Observer Manager

/// Manages weak references to settings observers
@MainActor
public class SettingsObserverManager {
    public static let shared = SettingsObserverManager()
    
    private var observers: [WeakObserver] = []
    private var cancellable: AnyCancellable?
    
    private init() {
        setupPropagation()
    }
    
    private func setupPropagation() {
        cancellable = SettingsPropagationService.shared.settingsChanged
            .sink { [weak self] event in
                self?.notifyObservers(event)
            }
    }
    
    public func addObserver(_ observer: SettingsObserver) {
        // Remove nil observers
        observers.removeAll { $0.observer == nil }
        
        // Add new observer if not already present
        if !observers.contains(where: { $0.observer === observer }) {
            observers.append(WeakObserver(observer: observer))
        }
    }
    
    public func removeObserver(_ observer: SettingsObserver) {
        observers.removeAll { $0.observer === observer }
    }
    
    private func notifyObservers(_ event: SettingsChangeEvent) {
        // Clean up nil observers
        observers.removeAll { $0.observer == nil }
        
        // Notify all observers
        for weakObserver in observers {
            weakObserver.observer?.settingsDidChange(event)
        }
    }
    
    // MARK: - Weak Observer Wrapper
    
    private class WeakObserver {
        weak var observer: SettingsObserver?
        
        init(observer: SettingsObserver) {
            self.observer = observer
        }
    }
}

// MARK: - Settings Manager Extension

extension SettingsManager {
    /// Propagates settings changes to all modules
    func propagateSettings() {
        guard let settings = currentSettings else { return }
        SettingsPropagationService.shared.propagateAllSettings(settings)
    }
    
    /// Propagates specific preference changes
    func propagateEditorPreferences() {
        guard let settings = currentSettings else { return }
        SettingsPropagationService.shared.propagateEditorPreferences(settings.editorPreferences)
    }
    
    func propagateBuilderPreferences() {
        guard let settings = currentSettings else { return }
        SettingsPropagationService.shared.propagateBuilderPreferences(settings.builderPreferences)
    }
    
    func propagateEnterprisePreferences() {
        guard let settings = currentSettings else { return }
        SettingsPropagationService.shared.propagateEnterprisePreferences(settings.enterprisePreferences)
    }
}
