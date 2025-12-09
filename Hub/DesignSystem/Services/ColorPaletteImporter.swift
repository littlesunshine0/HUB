import Foundation
import SwiftData

/// Service to import color palette JSON files into SwiftData
@MainActor
class ColorPaletteImporter {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Import a single color palette JSON file
    func importColorPalette(from fileURL: URL) async throws -> ColorPaletteData {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let json = try decoder.decode(ColorPaletteJSON.self, from: data)
        
        let model = json.toModel()
        modelContext.insert(model)
        
        try modelContext.save()
        
        return model
    }
    
    /// Import all color palette files from a directory
    func importAllColorPalettes(from directory: URL) async throws -> [ColorPaletteData] {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey]) else {
            throw ImportError.directoryNotFound
        }
        
        var imported: [ColorPaletteData] = []
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "json",
                  !fileURL.lastPathComponent.contains(".meta") else {
                continue
            }
            
            do {
                let palette = try await importColorPalette(from: fileURL)
                imported.append(palette)
                print("✅ Imported: \(palette.name)")
            } catch {
                print("⚠️  Failed to import \(fileURL.lastPathComponent): \(error)")
            }
        }
        
        return imported
    }
    
    /// Check if a palette already exists
    func paletteExists(name: String) -> Bool {
        let descriptor = FetchDescriptor<ColorPaletteData>(
            predicate: #Predicate { $0.name == name }
        )
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Get all imported palettes
    func fetchAllPalettes() throws -> [ColorPaletteData] {
        let descriptor = FetchDescriptor<ColorPaletteData>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Delete all palettes
    func deleteAllPalettes() throws {
        try modelContext.delete(model: ColorPaletteData.self)
        try modelContext.save()
    }
}

enum ImportError: Error {
    case directoryNotFound
    case invalidJSON
    case fileNotFound
}
