import Foundation
import SwiftUI

// MARK: - Template Branding Model

struct TemplateBranding: Codable {
    var appIconData: Data?
    var accentColor: String
    var primaryColor: String
    var backgroundColor: String
    var secondaryColor: String
    var assets: [String: Data] // Image assets (name -> data)
    var fonts: [String: String] // Font mappings (style -> font name)
    var designSystem: DesignSystem
    var colorScheme: ColorSchemeVariant
    
    init(
        appIconData: Data? = nil,
        accentColor: String = "#007AFF",
        primaryColor: String = "#000000",
        backgroundColor: String = "#FFFFFF",
        secondaryColor: String = "#8E8E93",
        assets: [String: Data] = [:],
        fonts: [String: String] = [:],
        designSystem: DesignSystem = .standard,
        colorScheme: ColorSchemeVariant = .light
    ) {
        self.appIconData = appIconData
        self.accentColor = accentColor
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.secondaryColor = secondaryColor
        self.assets = assets
        self.fonts = fonts
        self.designSystem = designSystem
        self.colorScheme = colorScheme
    }
    
    static var `default`: TemplateBranding {
        TemplateBranding()
    }
}

// MARK: - Design System Variants

enum DesignSystem: String, Codable, CaseIterable {
    case standard = "Standard"
    case minimal = "Minimal"
    case bold = "Bold"
    case corporate = "Corporate"
    
    var description: String {
        switch self {
        case .standard:
            return "Balanced design with modern aesthetics"
        case .minimal:
            return "Clean, simple design with minimal elements"
        case .bold:
            return "Strong, vibrant design with high contrast"
        case .corporate:
            return "Professional design for business applications"
        }
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "square.grid.2x2"
        case .minimal:
            return "circle"
        case .bold:
            return "bolt.fill"
        case .corporate:
            return "building.2"
        }
    }
}

// MARK: - Color Scheme Variants

enum ColorSchemeVariant: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
}

// MARK: - Branding Presets

extension TemplateBranding {
    // MARK: Standard Presets
    
    static var standardLight: TemplateBranding {
        TemplateBranding(
            accentColor: "#007AFF",
            primaryColor: "#000000",
            backgroundColor: "#FFFFFF",
            secondaryColor: "#8E8E93",
            designSystem: .standard,
            colorScheme: .light
        )
    }
    
    static var standardDark: TemplateBranding {
        TemplateBranding(
            accentColor: "#0A84FF",
            primaryColor: "#FFFFFF",
            backgroundColor: "#000000",
            secondaryColor: "#8E8E93",
            designSystem: .standard,
            colorScheme: .dark
        )
    }
    
    // MARK: Minimal Presets
    
    static var minimalLight: TemplateBranding {
        TemplateBranding(
            accentColor: "#000000",
            primaryColor: "#1C1C1E",
            backgroundColor: "#FFFFFF",
            secondaryColor: "#C7C7CC",
            fonts: [
                "body": "SF Pro Text",
                "headline": "SF Pro Display"
            ],
            designSystem: .minimal,
            colorScheme: .light
        )
    }
    
    static var minimalDark: TemplateBranding {
        TemplateBranding(
            accentColor: "#FFFFFF",
            primaryColor: "#F2F2F7",
            backgroundColor: "#000000",
            secondaryColor: "#48484A",
            fonts: [
                "body": "SF Pro Text",
                "headline": "SF Pro Display"
            ],
            designSystem: .minimal,
            colorScheme: .dark
        )
    }
    
    // MARK: Bold Presets
    
    static var boldLight: TemplateBranding {
        TemplateBranding(
            accentColor: "#FF3B30",
            primaryColor: "#000000",
            backgroundColor: "#FFFFFF",
            secondaryColor: "#FF9500",
            fonts: [
                "body": "SF Pro Text",
                "headline": "SF Pro Display"
            ],
            designSystem: .bold,
            colorScheme: .light
        )
    }
    
    static var boldDark: TemplateBranding {
        TemplateBranding(
            accentColor: "#FF453A",
            primaryColor: "#FFFFFF",
            backgroundColor: "#1C1C1E",
            secondaryColor: "#FF9F0A",
            fonts: [
                "body": "SF Pro Text",
                "headline": "SF Pro Display"
            ],
            designSystem: .bold,
            colorScheme: .dark
        )
    }
    
    // MARK: Corporate Presets
    
    static var corporateLight: TemplateBranding {
        TemplateBranding(
            accentColor: "#0066CC",
            primaryColor: "#1C1C1E",
            backgroundColor: "#F2F2F7",
            secondaryColor: "#636366",
            fonts: [
                "body": "SF Pro Text",
                "headline": "SF Pro Display"
            ],
            designSystem: .corporate,
            colorScheme: .light
        )
    }
    
    static var corporateDark: TemplateBranding {
        TemplateBranding(
            accentColor: "#0A84FF",
            primaryColor: "#F2F2F7",
            backgroundColor: "#1C1C1E",
            secondaryColor: "#8E8E93",
            fonts: [
                "body": "SF Pro Text",
                "headline": "SF Pro Display"
            ],
            designSystem: .corporate,
            colorScheme: .dark
        )
    }
    
    // MARK: Preset Helpers
    
    static func preset(for designSystem: DesignSystem, colorScheme: ColorSchemeVariant) -> TemplateBranding {
        switch (designSystem, colorScheme) {
        case (.standard, .light):
            return .standardLight
        case (.standard, .dark):
            return .standardDark
        case (.minimal, .light):
            return .minimalLight
        case (.minimal, .dark):
            return .minimalDark
        case (.bold, .light):
            return .boldLight
        case (.bold, .dark):
            return .boldDark
        case (.corporate, .light):
            return .corporateLight
        case (.corporate, .dark):
            return .corporateDark
        }
    }
    
    static var allPresets: [TemplateBranding] {
        var presets: [TemplateBranding] = []
        for designSystem in DesignSystem.allCases {
            for colorScheme in ColorSchemeVariant.allCases {
                presets.append(preset(for: designSystem, colorScheme: colorScheme))
            }
        }
        return presets
    }
}

// MARK: - Visual Screen Model

public struct VisualScreen: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var components: [RenderableComponent]
    public var isInitialScreen: Bool
    public var navigationTitle: String?
    public var backgroundColor: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        components: [RenderableComponent] = [],
        isInitialScreen: Bool = false,
        navigationTitle: String? = nil,
        backgroundColor: String? = nil
    ) {
        self.id = id
        self.name = name
        self.components = components
        self.isInitialScreen = isInitialScreen
        self.navigationTitle = navigationTitle
        self.backgroundColor = backgroundColor
    }
}

// MARK: - Component Modifiers

public struct ComponentModifiers: Codable {
    public var padding: Double?
    public var frame: FrameModifier?
    public var background: String?
    public var foregroundColor: String?
    public var cornerRadius: Double?
    public var shadow: ShadowModifier?
    public var opacity: Double?
    public var offset: OffsetModifier?
    
    public init(
        padding: Double? = nil,
        frame: FrameModifier? = nil,
        background: String? = nil,
        foregroundColor: String? = nil,
        cornerRadius: Double? = nil,
        shadow: ShadowModifier? = nil,
        opacity: Double? = nil,
        offset: OffsetModifier? = nil
    ) {
        self.padding = padding
        self.frame = frame
        self.background = background
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.opacity = opacity
        self.offset = offset
    }
}

public struct FrameModifier: Codable {
    public var width: Double?
    public var height: Double?
    public var maxWidth: Double?
    public var maxHeight: Double?
    public var alignment: String? // "center", "leading", "trailing", etc.
    
    public init(width: Double? = nil, height: Double? = nil, maxWidth: Double? = nil, maxHeight: Double? = nil, alignment: String? = nil) {
        self.width = width
        self.height = height
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.alignment = alignment
    }
}

public struct ShadowModifier: Codable {
    public var color: String
    public var radius: Double
    public var x: Double
    public var y: Double
    
    public init(color: String = "#000000", radius: Double = 5, x: Double = 0, y: Double = 2) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

public struct OffsetModifier: Codable {
    public var x: Double
    public var y: Double
    
    public init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
}

// MARK: - Navigation Action

public enum NavigationAction: Codable, Equatable {
    case none
    case navigateTo(screenID: UUID)
    case sheet(screenID: UUID)
    case dismiss
    case custom(actionName: String)
    
    public var actionName: String {
        switch self {
        case .none:
            return "none"
        case .navigateTo(let screenID):
            return "navigateTo_\(screenID.uuidString)"
        case .sheet(let screenID):
            return "sheet_\(screenID.uuidString)"
        case .dismiss:
            return "dismiss"
        case .custom(let name):
            return name
        }
    }
}
