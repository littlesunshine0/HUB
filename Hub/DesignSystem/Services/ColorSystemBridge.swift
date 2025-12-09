import SwiftUI
import SwiftData
import Combine

/// Bridge to connect ColorPaletteData (SwiftData) with UnifiedColorSystem
@MainActor
class ColorSystemBridge: ObservableObject {
    static let shared = ColorSystemBridge()
    
    private var modelContext: ModelContext?
    private let colorSystem = UnifiedColorSystem.shared
    
    private init() {}
    
    /// Initialize with model context
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        colorSystem.connect(modelContext: modelContext)
    }
    
    /// Import colors on first launch
    func importColorsIfNeeded() async {
        guard let modelContext = modelContext else { return }
        
        // Check if already imported
        let descriptor = FetchDescriptor<ColorPaletteData>()
        do {
            let count = try modelContext.fetchCount(descriptor)
            if count > 0 {
                print("✅ Colors already imported (\(count) palettes)")
                return
            }
        } catch {
            print("⚠️ Error checking color import status: \(error)")
            return
        }
        
        // Import colors
        print("🎨 Importing color palettes...")
        let importer = ColorPaletteImporter(modelContext: modelContext)
        
        let colorsPath = "Hub/HubSeeds/Colors"
        let colorsURL = URL(fileURLWithPath: colorsPath)
        
        do {
            let imported = try await importer.importAllColorPalettes(from: colorsURL)
            print("✅ Imported \(imported.count) color palettes")
            
            // Reload in color system
            colorSystem.loadImportedPalettes()
        } catch {
            print("⚠️ Failed to import colors: \(error)")
        }
    }
    
    /// Get all available colors
    func getAllColors() -> [ColorPaletteData] {
        colorSystem.importedPalettes
    }
    
    /// Get color by name
    func getColor(named name: String) -> Color? {
        colorSystem.getColor(named: name)
    }
}
