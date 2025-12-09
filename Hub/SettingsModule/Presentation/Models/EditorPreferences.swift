import Foundation

// MARK: - Editor Preferences

public struct EditorPreferences: Codable, Equatable, Sendable {
    var defaultPanelVisibility: Bool
    var defaultFontSize: Double
    var showLineNumbers: Bool
    var autoSave: Bool
    var autoSaveInterval: TimeInterval
    var syntaxHighlighting: Bool
    var codeCompletion: Bool
    var showMinimap: Bool
    
    init(
        defaultPanelVisibility: Bool = true,
        defaultFontSize: Double = 14.0,
        showLineNumbers: Bool = true,
        autoSave: Bool = true,
        autoSaveInterval: TimeInterval = 30.0,
        syntaxHighlighting: Bool = true,
        codeCompletion: Bool = true,
        showMinimap: Bool = false
    ) {
        self.defaultPanelVisibility = defaultPanelVisibility
        self.defaultFontSize = defaultFontSize
        self.showLineNumbers = showLineNumbers
        self.autoSave = autoSave
        self.autoSaveInterval = autoSaveInterval
        self.syntaxHighlighting = syntaxHighlighting
        self.codeCompletion = codeCompletion
        self.showMinimap = showMinimap
    }
}
