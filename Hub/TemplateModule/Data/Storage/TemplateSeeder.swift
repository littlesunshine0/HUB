import Foundation
import SwiftData

/// Seeds the template database with comprehensive hub templates
/// Expands from 67 templates to 200+ templates based on discovered projects
@MainActor
class TemplateSeeder {
    static let shared = TemplateSeeder()
    
    private init() {}
    
    /// Seed all templates into the model context with auto-recovery
    func seedAllTemplates(into context: ModelContext, forceReseed: Bool = false) {
        let existingCount = countExistingTemplates(in: context)
        
        print("📊 Current template count: \(existingCount)")
        
        // Auto-recovery: If we have very few templates (< 10), something went wrong - force reseed
        let needsRecovery = existingCount > 0 && existingCount < 10
        
        if needsRecovery {
            print("⚠️ Auto-recovery triggered: Only \(existingCount) templates found")
            print("🔄 Clearing corrupted data and reseeding...")
            clearAllTemplates(in: context)
        }
        
        // Only seed if we have fewer than 50 templates or force reseed requested
        guard existingCount < 50 || forceReseed || needsRecovery else {
            print("✓ Templates already seeded (\(existingCount) templates)")
            return
        }
        
        if forceReseed {
            print("🔄 Force reseed requested - clearing existing templates...")
            clearAllTemplates(in: context)
        }
        
        print("🌱 Seeding comprehensive template library...")
        
        // Get all expanded templates
        let expandedTemplates = ExpandedHubLibrary.shared.getAllExpandedTemplates()
        
        var seededCount = 0
        var skippedCount = 0
        
        for templateDef in expandedTemplates {
            // Check if template already exists
            if templateExists(name: templateDef.name, in: context) {
                skippedCount += 1
                continue
            }
            
            // Create template model
            let template = TemplateModel(
                name: templateDef.name,
                category: templateDef.category,
                description: generateDescription(for: templateDef),
                icon: generateIcon(for: templateDef),
                author: "System",
                version: "1.0.0",
                sourceFiles: [:], // SimpleTemplateDefinition doesn't have sourceFiles
                features: templateDef.features,
                dependencies: templateDef.dependencies,
                isBuiltIn: true,
                tags: generateTags(for: templateDef),
                sharedModules: [],
                featureToggles: [:],
                userID: nil,
                isVisualTemplate: false,
                isFeatured: isFeaturedTemplate(templateDef.name)
            )
            
            // Set initial ratings and downloads for featured templates
            if template.isFeatured {
                template.rating = 4.5 + Double.random(in: 0...0.5)
                template.downloadCount = Int.random(in: 100...500)
            } else {
                template.rating = 3.5 + Double.random(in: 0...1.5)
                template.downloadCount = Int.random(in: 10...100)
            }
            
            context.insert(template)
            seededCount += 1
        }
        
        // Save context
        do {
            try context.save()
            print("✓ Seeded \(seededCount) new templates (skipped \(skippedCount) existing)")
            print("✓ Total templates: \(countExistingTemplates(in: context))")
        } catch {
            print("✗ Failed to save templates: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func countExistingTemplates(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<TemplateModel>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    private func templateExists(name: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<TemplateModel>(
            predicate: #Predicate { $0.name == name }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    private func clearAllTemplates(in context: ModelContext) {
        let descriptor = FetchDescriptor<TemplateModel>()
        guard let templates = try? context.fetch(descriptor) else { return }
        
        for template in templates {
            context.delete(template)
        }
        
        do {
            try context.save()
            print("✓ Cleared \(templates.count) existing templates")
        } catch {
            print("✗ Failed to clear templates: \(error)")
        }
    }
    
    private func generateDescription(for template: SimpleTemplateDefinition) -> String {
        let name = template.name
        let category = template.category.rawValue
        let features = template.features.prefix(3).joined(separator: ", ")
        
        return "A \(category.lowercased()) hub for \(name.lowercased()). Features: \(features)."
    }
    
    private func generateIcon(for template: SimpleTemplateDefinition) -> String {
        // Map categories to SF Symbols
        switch template.category {
        case .productivity:
            return ["checkmark.circle", "list.bullet", "calendar", "note.text"].randomElement()!
        case .development:
            return ["hammer", "wrench.and.screwdriver", "chevron.left.forwardslash.chevron.right", "terminal"].randomElement()!
        case .business:
            return ["chart.bar", "briefcase", "dollarsign.circle", "building.2"].randomElement()!
        case .creative:
            return ["paintbrush", "photo", "music.note", "film"].randomElement()!
        case .utilities:
            return ["gear", "folder", "doc", "archivebox"].randomElement()!
        case .security:
            return ["lock.shield", "key", "checkmark.shield", "lock"].randomElement()!
        case .education:
            return ["book", "graduationcap", "pencil", "lightbulb"].randomElement()!
        case .entertainment:
            return ["play.circle", "tv", "gamecontroller", "music.note"].randomElement()!
        case .lifestyle:
            return ["heart", "leaf", "figure.walk", "house"].randomElement()!
        default:
            return "app"
        }
    }
    
    private func generateTags(for template: SimpleTemplateDefinition) -> [String] {
        var tags: [String] = []
        
        // Add category
        tags.append(template.category.rawValue.lowercased())
        
        // Add features as tags
        tags.append(contentsOf: template.features.map { $0.lowercased() })
        
        // Add name-based tags
        let name = template.name.lowercased()
        let words = name.components(separatedBy: " ")
        tags.append(contentsOf: words)
        
        // Remove duplicates and common words
        let commonWords = ["the", "a", "an", "and", "or", "but", "for", "with"]
        tags = Array(Set(tags)).filter { !commonWords.contains($0) }
        
        return tags
    }
    
    private func isFeaturedTemplate(_ name: String) -> Bool {
        // Featured templates are the most useful/popular ones
        let featured = [
            "File Manager Pro",
            "File Explorer",
            "Console",
            "Knowledge Engine",
            "Database Manager",
            "Code Analyzer Pro",
            "Build System",
            "Test Runner",
            "Deployment Manager",
            "System Monitor",
            "Team Workspace",
            "Tutorial Builder",
            "Code Snippets",
            "Packager",
            "Icon Designer",
            "Color Palette Generator",
            "Media Library",
            "API Documentation",
            "Performance Analyzer",
            "CI/CD Pipeline"
        ]
        
        return featured.contains(name)
    }
}

// MARK: - Integration with Existing System

extension TemplateAssitManager {
    /// Seed expanded templates on first launch using an explicit ModelContext
    func seedExpandedTemplates(using context: ModelContext) {
        TemplateSeeder.shared.seedAllTemplates(into: context)
        loadTemplates() // Reload to show new templates
    }

    @available(*, unavailable, message: "Use seedExpandedTemplates(using:) with an explicit ModelContext. This type's modelContext is not accessible here.")
    func seedExpandedTemplates() {
        // This overload is intentionally unavailable to avoid accessing a private `modelContext`.
        // Callers must pass an explicit ModelContext instead:
        // seedExpandedTemplates(using: someModelContext)
    }
}
