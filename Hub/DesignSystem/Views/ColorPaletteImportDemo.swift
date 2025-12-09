import SwiftUI
import SwiftData

/// Demo view to test color palette JSON import
struct ColorPaletteImportDemo: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var palettes: [ColorPaletteData]
    
    @State private var isImporting = false
    @State private var importStatus = ""
    @State private var importedCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Color Palette JSON Import")
                .font(.title)
                .fontWeight(.bold)
            
            // Status
            if !importStatus.isEmpty {
                Text(importStatus)
                    .foregroundStyle(importedCount > 0 ? .green : .secondary)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Import Button
            Button(action: importColors) {
                Label(isImporting ? "Importing..." : "Import Color Palettes", 
                      systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
            
            // Clear Button
            if !palettes.isEmpty {
                Button(action: clearAll) {
                    Label("Clear All (\(palettes.count))", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            Divider()
            
            // Palette List
            if palettes.isEmpty {
                ContentUnavailableView(
                    "No Palettes",
                    systemImage: "paintpalette",
                    description: Text("Import color palettes to see them here")
                )
            } else {
                List {
                    ForEach(palettes) { palette in
                        ColorPaletteRow(palette: palette)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func importColors() {
        isImporting = true
        importStatus = "Importing..."
        
        Task {
            do {
                let importer = ColorPaletteImporter(modelContext: modelContext)
                
                // Import from Colors directory
                let colorsPath = "Hub/HubSeeds/Colors"
                let colorsURL = URL(fileURLWithPath: colorsPath)
                
                let imported = try await importer.importAllColorPalettes(from: colorsURL)
                
                await MainActor.run {
                    importedCount = imported.count
                    importStatus = "✅ Imported \(imported.count) color palettes"
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importStatus = "❌ Import failed: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
    
    private func clearAll() {
        do {
            let importer = ColorPaletteImporter(modelContext: modelContext)
            try importer.deleteAllPalettes()
            importStatus = "🗑️  Cleared all palettes"
            importedCount = 0
        } catch {
            importStatus = "❌ Clear failed: \(error.localizedDescription)"
        }
    }
}

struct ColorPaletteRow: View {
    let palette: ColorPaletteData
    
    var body: some View {
        HStack(spacing: 12) {
            // Color swatch
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: palette.baseHex))
                .frame(width: 60, height: 60)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(palette.name)
                    .font(.headline)
                
                if let customName = palette.customName {
                    Text(customName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(palette.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Text(palette.baseHex)
                        .font(.caption.monospaced())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text("\(palette.tints.count) tints")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("\(palette.shades.count) shades")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Type badges
            HStack(spacing: 4) {
                if palette.isPrimary {
                    Text("Primary")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                if palette.isSecondary {
                    Text("Secondary")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
                if palette.isTertiary {
                    Text("Tertiary")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Badge and Color.init(hex:) are defined in TemplateDetailPreviewView.swift and ColorExtensions.swift

#Preview {
    ColorPaletteImportDemo()
        .modelContainer(for: [ColorPaletteData.self], inMemory: true)
}
