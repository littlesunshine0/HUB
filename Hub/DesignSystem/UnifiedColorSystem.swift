import SwiftUI
import Combine
import SwiftData

/// Unified Color System - Single source of truth for all colors in Hub
@MainActor
class UnifiedColorSystem: ObservableObject {
    static let shared = UnifiedColorSystem()
    
    // MARK: - Color Collections
    
    @Published var colorPalettes: [ColorPalette] = []
    @Published var colorSystems: [ColorSystem] = []
    @Published var themes: [ColorTheme] = []
    
    // MARK: - SwiftData Integration
    
    @Published var importedPalettes: [ColorPaletteData] = []
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    private init() {
        loadDefaultColors()
    }
    
    /// Connect to SwiftData model context
    func connect(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadImportedPalettes()
    }
    
    /// Load imported palettes from SwiftData
    func loadImportedPalettes() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<ColorPaletteData>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            importedPalettes = try modelContext.fetch(descriptor)
            print("✅ Loaded \(importedPalettes.count) imported color palettes")
        } catch {
            print("⚠️ Failed to load imported palettes: \(error)")
        }
    }
    
    // MARK: - Loading
    
    func loadDefaultColors() {
        colorPalettes = ColorPalette.defaults
        colorSystems = ColorSystem.defaults
        themes = ColorTheme.defaults
    }
    
    func loadFromAssets() async {
        // Load from AssetLoaderService
        let loader = AssetLoaderService.shared
        await loader.loadColors()
        await loader.loadColorSystems()
        await loader.loadThemes()
        
        // Convert to unified format
        colorPalettes = loader.colors.compactMap { asset in
            ColorPalette(
                name: asset.name,
                description: asset.description,
                colors: [], // TODO: Parse colors from asset metadata
                category: asset.category,
                tags: asset.tags
            )
        }
        
        colorSystems = loader.colorSystems.compactMap { asset in
            ColorSystem(
                name: asset.name,
                description: asset.description,
                palettes: [],
                semanticColors: [:]
            )
        }
        
        themes = loader.themes.compactMap { asset in
            ColorTheme(
                name: asset.name,
                description: asset.description,
                colorSystem: "Hub Design System",
                appearance: .auto
            )
        }
    }
    
    // MARK: - Access Methods
    
    func getColor(named name: String) -> Color? {
        // Search in imported palettes first
        if let palette = importedPalettes.first(where: { $0.name == name }) {
            return Color(hex: palette.baseHex)
        }
        
        // Search in default palettes
        for palette in colorPalettes {
            if let color = palette.colors.first(where: { $0.name == name }) {
                return color.swiftUIColor
            }
        }
        return nil
    }
    
    /// Get imported palette by name
    func getImportedPalette(named name: String) -> ColorPaletteData? {
        importedPalettes.first { $0.name == name }
    }
    
    /// Get all colors (both default and imported)
    func getAllColors() -> [String: Color] {
        var colors: [String: Color] = [:]
        
        // Add imported palettes
        for palette in importedPalettes {
            colors[palette.name] = Color(hex: palette.baseHex)
        }
        
        // Add default palettes
        for palette in colorPalettes {
            for color in palette.colors {
                colors[color.name] = color.swiftUIColor
            }
        }
        
        return colors
    }
    
    func getPalette(named name: String) -> ColorPalette? {
        colorPalettes.first { $0.name == name }
    }
    
    func getSystem(named name: String) -> ColorSystem? {
        colorSystems.first { $0.name == name }
    }
    
    func getTheme(named name: String) -> ColorTheme? {
        themes.first { $0.name == name }
    }
}

// MARK: - Color Palette

struct ColorPalette: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let colors: [ColorDefinition]
    let category: String
    let tags: [String]
    
    init(id: UUID = UUID(), name: String, description: String, colors: [ColorDefinition], category: String = "General", tags: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.colors = colors
        self.category = category
        self.tags = tags
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(category)
    }
    
    static func == (lhs: ColorPalette, rhs: ColorPalette) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.category == rhs.category
    }
    
    static let defaults: [ColorPalette] = [
        ColorPalette(
            name: "Primary",
            description: "Primary brand colors",
            colors: [
                ColorDefinition(name: "Blue", hex: "#007AFF"),
                ColorDefinition(name: "Purple", hex: "#5856D6"),
                ColorDefinition(name: "Pink", hex: "#FF2D55")
            ],
            category: "Brand",
            tags: ["primary", "brand"]
        ),
        ColorPalette(
            name: "Neutral",
            description: "Neutral grays and blacks",
            colors: [
                ColorDefinition(name: "Black", hex: "#000000"),
                ColorDefinition(name: "Gray", hex: "#8E8E93"),
                ColorDefinition(name: "White", hex: "#FFFFFF")
            ],
            category: "Neutral",
            tags: ["neutral", "gray"]
        )
    ]
}

// MARK: - Color Definition

struct ColorDefinition: Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let hex: String
    let rgb: (r: Double, g: Double, b: Double)
    let hsl: (h: Double, s: Double, l: Double)
    
    init(id: UUID = UUID(), name: String, hex: String) {
        self.id = id
        self.name = name
        self.hex = hex
        self.rgb = ColorDefinition.hexToRGB(hex)
        self.hsl = ColorDefinition.rgbToHSL(rgb: self.rgb)
    }
    
    var swiftUIColor: Color {
        Color(
            red: rgb.r / 255.0,
            green: rgb.g / 255.0,
            blue: rgb.b / 255.0
        )
    }
    
    var nsColor: NSColor {
        NSColor(
            red: rgb.r / 255.0,
            green: rgb.g / 255.0,
            blue: rgb.b / 255.0,
            alpha: 1.0
        )
    }
    
    // MARK: - Color Conversion
    
    static func hexToRGB(_ hex: String) -> (r: Double, g: Double, b: Double) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16)
        let g = Double((rgb & 0x00FF00) >> 8)
        let b = Double(rgb & 0x0000FF)
        
        return (r, g, b)
    }
    
    static func rgbToHSL(rgb: (r: Double, g: Double, b: Double)) -> (h: Double, s: Double, l: Double) {
        let r = rgb.r / 255.0
        let g = rgb.g / 255.0
        let b = rgb.b / 255.0
        
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        var h: Double = 0
        var s: Double = 0
        let l = (max + min) / 2
        
        if delta != 0 {
            s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min)
            
            switch max {
            case r: h = ((g - b) / delta) + (g < b ? 6 : 0)
            case g: h = ((b - r) / delta) + 2
            case b: h = ((r - g) / delta) + 4
            default: break
            }
            
            h /= 6
        }
        
        return (h * 360, s * 100, l * 100)
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(hex)
    }
    
    static func == (lhs: ColorDefinition, rhs: ColorDefinition) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.hex == rhs.hex
    }
}

// MARK: - Color System

struct ColorSystem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let palettes: [ColorPalette]
    let semanticColors: [String: ColorDefinition]
    
    init(id: UUID = UUID(), name: String, description: String, palettes: [ColorPalette], semanticColors: [String: ColorDefinition] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.palettes = palettes
        self.semanticColors = semanticColors
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    static func == (lhs: ColorSystem, rhs: ColorSystem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    static let defaults: [ColorSystem] = [
        ColorSystem(
            name: "Hub Design System",
            description: "Complete color system for Hub",
            palettes: ColorPalette.defaults,
            semanticColors: [
                "primary": ColorDefinition(name: "Primary", hex: "#007AFF"),
                "secondary": ColorDefinition(name: "Secondary", hex: "#5856D6"),
                "success": ColorDefinition(name: "Success", hex: "#34C759"),
                "warning": ColorDefinition(name: "Warning", hex: "#FF9500"),
                "error": ColorDefinition(name: "Error", hex: "#FF3B30")
            ]
        )
    ]
}

// MARK: - Color Theme

struct ColorTheme: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let colorSystem: String
    let appearance: Appearance
    let customizations: [String: String]
    
    enum Appearance: String, Hashable {
        case light, dark, auto
    }
    
    init(id: UUID = UUID(), name: String, description: String, colorSystem: String, appearance: Appearance = .auto, customizations: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.colorSystem = colorSystem
        self.appearance = appearance
        self.customizations = customizations
    }
    

    
    static let defaults: [ColorTheme] = [
        ColorTheme(
            name: "Light",
            description: "Light theme with bright colors",
            colorSystem: "Hub Design System",
            appearance: .light
        ),
        ColorTheme(
            name: "Dark",
            description: "Dark theme with muted colors",
            colorSystem: "Hub Design System",
            appearance: .dark
        ),
        ColorTheme(
            name: "Auto",
            description: "Automatically adapts to system appearance",
            colorSystem: "Hub Design System",
            appearance: .auto
        )
    ]
}

// MARK: - Color Picker Integration

extension UnifiedColorSystem {
    func exportPalette(_ palette: ColorPalette, format: ExportFormat) -> String {
        switch format {
        case .json:
            return exportAsJSON(palette)
        case .swift:
            return exportAsSwift(palette)
        case .css:
            return exportAsCSS(palette)
        }
    }
    
    enum ExportFormat {
        case json, swift, css
    }
    
    private func exportAsJSON(_ palette: ColorPalette) -> String {
        let colors = palette.colors.map { color in
            """
            {
              "name": "\(color.name)",
              "hex": "\(color.hex)",
              "rgb": {"r": \(color.rgb.r), "g": \(color.rgb.g), "b": \(color.rgb.b)}
            }
            """
        }.joined(separator: ",\n    ")
        
        return """
        {
          "name": "\(palette.name)",
          "description": "\(palette.description)",
          "colors": [
            \(colors)
          ]
        }
        """
    }
    
    private func exportAsSwift(_ palette: ColorPalette) -> String {
        let colors = palette.colors.map { color in
            "    static let \(color.name.lowercased()) = Color(hex: \"\(color.hex)\")"
        }.joined(separator: "\n")
        
        return """
        extension Color {
        \(colors)
        }
        """
    }
    
    private func exportAsCSS(_ palette: ColorPalette) -> String {
        let colors = palette.colors.map { color in
            "  --color-\(color.name.lowercased()): \(color.hex);"
        }.joined(separator: "\n")
        
        return """
        :root {
        \(colors)
        }
        """
    }
}
