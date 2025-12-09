import Foundation
import SwiftData
import CloudKit

@Model
public final class AppSettings {
    @Attribute(.unique) var userID: String
    var defaultEditorMode: String
    var p2pDisplayName: String
    var p2pAutoAccept: Bool
    var editorPreferencesData: Data?
    var builderPreferencesData: Data?
    var enterprisePreferencesData: Data?
    var cloudKitRecordID: String?
    var lastSyncedAt: Date?
    var syncEnabled: Bool = false
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Nested Types
    
    enum EditorMode: String, CaseIterable, Identifiable {
        case visual = "Visual"
        case code = "Code"
        case split = "Split"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .visual:
                return "Visual editor with drag-and-drop components"
            case .code:
                return "Code editor with syntax highlighting"
            case .split:
                return "Split view with both visual and code"
            }
        }
        
        var icon: String {
            switch self {
            case .visual: return "square.grid.2x2"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .split: return "rectangle.split.2x1"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var editorPreferences: EditorPreferences {
        get {
            guard let data = editorPreferencesData else {
                return EditorPreferences()
            }
            return Self.decodeEditorPreferences(from: data)
        }
        set {
            editorPreferencesData = Self.encodeEditorPreferences(newValue)
            updatedAt = Date()
        }
    }
    
    var builderPreferences: BuilderPreferences {
        get {
            guard let data = builderPreferencesData else {
                return BuilderPreferences()
            }
            return Self.decodeBuilderPreferences(from: data)
        }
        set {
            builderPreferencesData = Self.encodeBuilderPreferences(newValue)
            updatedAt = Date()
        }
    }
    
    var enterprisePreferences: EnterprisePreferences {
        get {
            guard let data = enterprisePreferencesData else {
                return EnterprisePreferences()
            }
            return Self.decodeEnterprisePreferences(from: data)
        }
        set {
            enterprisePreferencesData = Self.encodeEnterprisePreferences(newValue)
            updatedAt = Date()
        }
    }
    
    // MARK: - Nonisolated Encoding/Decoding Helpers
    
    nonisolated private static func decodeEditorPreferences(from data: Data) -> EditorPreferences {
        return (try? JSONDecoder().decode(EditorPreferences.self, from: data)) ?? EditorPreferences()
    }
    
    nonisolated private static func encodeEditorPreferences(_ preferences: EditorPreferences) -> Data? {
        return try? JSONEncoder().encode(preferences)
    }
    
    nonisolated private static func decodeBuilderPreferences(from data: Data) -> BuilderPreferences {
        return (try? JSONDecoder().decode(BuilderPreferences.self, from: data)) ?? BuilderPreferences()
    }
    
    nonisolated private static func encodeBuilderPreferences(_ preferences: BuilderPreferences) -> Data? {
        return try? JSONEncoder().encode(preferences)
    }
    
    nonisolated private static func decodeEnterprisePreferences(from data: Data) -> EnterprisePreferences {
        return (try? JSONDecoder().decode(EnterprisePreferences.self, from: data)) ?? EnterprisePreferences()
    }
    
    nonisolated private static func encodeEnterprisePreferences(_ preferences: EnterprisePreferences) -> Data? {
        return try? JSONEncoder().encode(preferences)
    }
    
    var editorModeEnum: EditorMode {
        get {
            EditorMode(rawValue: defaultEditorMode) ?? .visual
        }
        set {
            defaultEditorMode = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    // MARK: - Initializer
    
    init(
        userID: String,
        defaultEditorMode: String = EditorMode.visual.rawValue,
        p2pDisplayName: String = "",
        p2pAutoAccept: Bool = false,
        editorPreferences: EditorPreferences = EditorPreferences(),
        builderPreferences: BuilderPreferences = BuilderPreferences(),
        enterprisePreferences: EnterprisePreferences = EnterprisePreferences(),
        syncEnabled: Bool = false
    ) {
        self.userID = userID
        self.defaultEditorMode = defaultEditorMode
        self.p2pDisplayName = p2pDisplayName
        self.p2pAutoAccept = p2pAutoAccept
        self.syncEnabled = syncEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Encode preferences using nonisolated helpers
        self.editorPreferencesData = Self.encodeEditorPreferences(editorPreferences)
        self.builderPreferencesData = Self.encodeBuilderPreferences(builderPreferences)
        self.enterprisePreferencesData = Self.encodeEnterprisePreferences(enterprisePreferences)
    }
    
    // MARK: - Helper Methods
    
    func updateEditorMode(_ mode: EditorMode) {
        defaultEditorMode = mode.rawValue
        updatedAt = Date()
    }
    
    func updateP2PSettings(displayName: String, autoAccept: Bool) {
        p2pDisplayName = displayName
        p2pAutoAccept = autoAccept
        updatedAt = Date()
    }
}
