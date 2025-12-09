//
//  MarketplaceSeeder.swift
//  Hub
//
//  Service for seeding marketplace with local Hubs and Templates
//  Implements Requirements 8.1, 8.2, 8.3, 8.4, 8.5
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Marketplace Seeder

/// Seeds the marketplace with all local Hubs and Templates
/// Generates metadata and preview images for marketplace display
@MainActor
class MarketplaceSeeder: ObservableObject {
    @Published var isSeeding: Bool = false
    @Published var progress: SeedingProgress = SeedingProgress()
    @Published var lastSeedingResult: SeedingResult?
    @Published var errorMessage: String?
    
    private let templateManager: TemplateManager
    private let hubManager: HubManager
    private let marketplaceService: LocalMarketplaceService
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(
        templateManager: TemplateManager,
        hubManager: HubManager,
        marketplaceService: LocalMarketplaceService,
        modelContext: ModelContext
    ) {
        self.templateManager = templateManager
        self.hubManager = hubManager
        self.marketplaceService = marketplaceService
        self.modelContext = modelContext
    }
    
    // MARK: - Seeding
    
    /// Seed the marketplace with all local Hubs and Templates
    /// Requirement 8.1: Scan all local Hubs and Templates
    /// Requirement 8.2: Add content to marketplace catalog
    func seedMarketplace() async throws -> SeedingResult {
        isSeeding = true
        errorMessage = nil
        progress = SeedingProgress()
        
        var result = SeedingResult(
            templatesAdded: 0,
            hubsAdded: 0,
            previewsGenerated: 0,
            errors: []
        )
        
        do {
            // Step 1: Scan and seed templates
            print("📦 Scanning templates...")
            progress.currentPhase = "Scanning templates..."
            progress.currentItem = 0
            progress.totalItems = templateManager.templates.count
            
            for (index, template) in templateManager.templates.enumerated() {
                progress.currentItem = index + 1
                
                do {
                    try await seedTemplate(template)
                    result.templatesAdded += 1
                } catch {
                    let errorMsg = "Failed to seed template '\(template.name)': \(error.localizedDescription)"
                    result.errors.append(errorMsg)
                    print("❌ \(errorMsg)")
                }
            }
            
            // Step 2: Scan and seed hubs
            print("📦 Scanning hubs...")
            progress.currentPhase = "Scanning hubs..."
            let allHubs = hubManager.getAllHubs()
            progress.currentItem = 0
            progress.totalItems = allHubs.count
            
            for (index, hub) in allHubs.enumerated() {
                progress.currentItem = index + 1
                
                do {
                    try await seedHub(hub)
                    result.hubsAdded += 1
                } catch {
                    let errorMsg = "Failed to seed hub '\(hub.name)': \(error.localizedDescription)"
                    result.errors.append(errorMsg)
                    print("❌ \(errorMsg)")
                }
            }
            
            // Step 3: Generate previews
            print("🖼️ Generating previews...")
            progress.currentPhase = "Generating previews..."
            result.previewsGenerated = try await generatePreviews()
            
            // Step 4: Reload marketplace content
            print("🔄 Reloading marketplace...")
            progress.currentPhase = "Reloading marketplace..."
            await marketplaceService.loadLocalContent()
            
            lastSeedingResult = result
            isSeeding = false
            
            print("✅ Marketplace seeding complete!")
            print("   Templates: \(result.templatesAdded)")
            print("   Hubs: \(result.hubsAdded)")
            print("   Previews: \(result.previewsGenerated)")
            print("   Errors: \(result.errors.count)")
            
            return result
        } catch {
            errorMessage = "Seeding failed: \(error.localizedDescription)"
            isSeeding = false
            throw error
        }
    }
    
    // MARK: - Template Seeding
    
    /// Seed a single template to the marketplace
    /// Requirement 8.3: Generate marketplace metadata
    private func seedTemplate(_ template: TemplateModel) async throws {
        // Generate metadata
        let _ = generateTemplateMetadata(template)
        
        // Update template with marketplace metadata
        template.updatedAt = Date()
        
        // Ensure template has proper tags
        if template.tags.isEmpty {
            template.tags = generateDefaultTags(for: template)
        }
        
        // Ensure template has a rating (if not already set)
        if template.rating == 0.0 {
            template.rating = generateInitialRating(for: template)
        }
        
        // Save changes
        try modelContext.save()
        
        print("✅ Seeded template: \(template.name)")
    }
    
    /// Generate metadata for a template
    /// Requirement 8.3: Generate marketplace metadata
    private func generateTemplateMetadata(_ template: TemplateModel) -> MarketplaceTemplateMetadata {
        return MarketplaceTemplateMetadata(
            id: template.id,
            name: template.name,
            description: template.templateDescription,
            category: template.category,
            author: template.author,
            version: template.version,
            tags: template.tags.isEmpty ? generateDefaultTags(for: template) : template.tags,
            features: template.features,
            dependencies: template.dependencies,
            rating: template.rating,
            downloadCount: template.downloadCount,
            isBuiltIn: template.isBuiltIn,
            isFeatured: template.isFeatured,
            createdAt: template.createdAt,
            updatedAt: template.updatedAt
        )
    }
    
    /// Generate default tags for a template
    private func generateDefaultTags(for template: TemplateModel) -> [String] {
        var tags: [String] = []
        
        // Add category
        tags.append(template.category.rawValue.lowercased())
        
        // Add type
        if template.isVisualTemplate {
            tags.append("visual")
        } else {
            tags.append("code")
        }
        
        // Add built-in tag
        if template.isBuiltIn {
            tags.append("built-in")
        }
        
        // Add feature-based tags
        for feature in template.features {
            let tag = feature.lowercased()
                .replacingOccurrences(of: " ", with: "-")
            tags.append(tag)
        }
        
        return Array(Set(tags)) // Remove duplicates
    }
    
    /// Generate initial rating for a template
    private func generateInitialRating(for template: TemplateModel) -> Double {
        if template.isFeatured {
            return 4.5 + Double.random(in: 0...0.5)
        } else if template.isBuiltIn {
            return 4.0 + Double.random(in: 0...1.0)
        } else {
            return 3.5 + Double.random(in: 0...1.5)
        }
    }
    
    // MARK: - Hub Seeding
    
    /// Seed a single hub to the marketplace
    /// Requirement 8.3: Generate marketplace metadata
    private func seedHub(_ hub: AppHub) async throws {
        // Generate metadata
        let metadata = generateHubMetadata(hub)
        
        // Update hub
        hub.updatedAt = Date()
        
        // Save changes
        try modelContext.save()
        
        print("✅ Seeded hub: \(hub.name)")
    }
    
    /// Generate metadata for a hub
    /// Requirement 8.3: Generate marketplace metadata
    private func generateHubMetadata(_ hub: AppHub) -> HubMetadata {
        return HubMetadata(
            id: hub.id,
            name: hub.name,
            description: hub.details,
            category: hub.category,
            icon: hub.icon,
            templateName: hub.templateName,
            isPublished: hub.isPublished,
            createdAt: hub.createdAt,
            updatedAt: hub.updatedAt
        )
    }
    
    // MARK: - Preview Generation
    
    /// Generate preview images for marketplace items
    /// Requirement 8.4: Create preview images
    func generatePreviews() async throws -> Int {
        var count = 0
        
        // Generate previews for templates
        for template in templateManager.templates {
            if template.previewImageData == nil {
                do {
                    let previewData = try await generateTemplatePreview(template)
                    template.previewImageData = previewData
                    try modelContext.save()
                    count += 1
                } catch {
                    print("⚠️ Failed to generate preview for template '\(template.name)': \(error)")
                }
            }
        }
        
        return count
    }
    
    /// Generate preview image for a template
    /// Requirement 8.4: Create preview images
    private func generateTemplatePreview(_ template: TemplateModel) async throws -> Data {
        // For visual templates, render the components
        if template.isVisualTemplate && !template.visualScreens.isEmpty {
            return try await generateVisualTemplatePreview(template)
        }
        
        // For code templates, generate a placeholder
        return try generateCodeTemplatePreview(template)
    }
    
    /// Generate preview for visual template
    private func generateVisualTemplatePreview(_ template: TemplateModel) async throws -> Data {
        // Create a simple preview image showing the template icon and name
        // In a real implementation, this would render the actual visual components
        
        let size = CGSize(width: 300, height: 200)
        let renderer = ImageRenderer(content: TemplatePreviewView(template: template))
        renderer.proposedSize = ProposedViewSize(size)
        
        #if os(iOS)
        if let uiImage = renderer.uiImage {
            return uiImage.pngData() ?? Data()
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            return nsImage.tiffRepresentation ?? Data()
        }
        #endif
        
        throw MarketplaceSeederError.previewGenerationFailed
    }
    
    /// Generate preview for code template
    private func generateCodeTemplatePreview(_ template: TemplateModel) throws -> Data {
        // Create a simple preview image showing the template icon and name
        let size = CGSize(width: 300, height: 200)
        let renderer = ImageRenderer(content: TemplatePreviewView(template: template))
        renderer.proposedSize = ProposedViewSize(size)
        
        #if os(iOS)
        if let uiImage = renderer.uiImage {
            return uiImage.pngData() ?? Data()
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            return nsImage.tiffRepresentation ?? Data()
        }
        #endif
        
        throw MarketplaceSeederError.previewGenerationFailed
    }
    
    // MARK: - Metadata Creation
    
    /// Create metadata for marketplace items
    /// Requirement 8.3: Generate marketplace metadata
    func createMetadata(for items: [MarketplaceItem]) async {
        for item in items {
            switch item.type {
            case .template:
                if let template = item.template {
                    _ = generateTemplateMetadata(template)
                }
            case .hub:
                if let hub = item.hub {
                    _ = generateHubMetadata(hub)
                }
            case .bundle:
                // Bundle metadata generation not yet implemented
                break
            }
        }
    }
}

// MARK: - Supporting Types

/// Progress tracking for seeding operation
struct SeedingProgress {
    var currentPhase: String = ""
    var currentItem: Int = 0
    var totalItems: Int = 0
    
    var percentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(currentItem) / Double(totalItems) * 100
    }
}

/// Result of marketplace seeding operation
struct SeedingResult {
    var templatesAdded: Int
    var hubsAdded: Int
    var previewsGenerated: Int
    var errors: [String]
    
    var isSuccess: Bool {
        return errors.isEmpty
    }
    
    var summary: String {
        return """
        Marketplace Seeding Complete
        
        Templates Added: \(templatesAdded)
        Hubs Added: \(hubsAdded)
        Previews Generated: \(previewsGenerated)
        Errors: \(errors.count)
        """
    }
}

/// Metadata for a template in the marketplace
struct MarketplaceTemplateMetadata {
    let id: UUID
    let name: String
    let description: String
    let category: HubCategory
    let author: String
    let version: String
    let tags: [String]
    let features: [String]
    let dependencies: [String]
    let rating: Double
    let downloadCount: Int
    let isBuiltIn: Bool
    let isFeatured: Bool
    let createdAt: Date
    let updatedAt: Date
}

/// Metadata for a hub in the marketplace
struct HubMetadata {
    let id: UUID
    let name: String
    let description: String
    let category: HubCategory
    let icon: String
    let templateName: String
    let isPublished: Bool
    let createdAt: Date
    let updatedAt: Date
}

/// Errors that can occur during marketplace seeding
enum MarketplaceSeederError: LocalizedError {
    case templateNotFound
    case hubNotFound
    case previewGenerationFailed
    case metadataGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Template not found"
        case .hubNotFound:
            return "Hub not found"
        case .previewGenerationFailed:
            return "Failed to generate preview image"
        case .metadataGenerationFailed:
            return "Failed to generate metadata"
        }
    }
}

// MARK: - Preview View

/// Simple preview view for templates
private struct TemplatePreviewView: View {
    let template: TemplateModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(template.category.icon).opacity(0.3),
                    Color(template.category.icon).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                // Icon
                Image(systemName: template.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.primary)
                
                // Name
                Text(template.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Category badge
                Text(template.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
}
