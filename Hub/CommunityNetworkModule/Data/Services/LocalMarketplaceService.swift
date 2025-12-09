import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Local Marketplace Service

/// Service for managing marketplace content locally without CloudKit dependency
/// Enables offline marketplace functionality and testing
@MainActor
class LocalMarketplaceService: ObservableObject {
    static let shared = LocalMarketplaceService()
    
    @Published var localContent: [MarketplaceItem] = []
    @Published var isCloudKitAvailable: Bool = false
    @Published var contentSource: ContentSource = .local
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cloudKitService: CloudKitService
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    private init() {
        self.cloudKitService = CloudKitService.shared
        self.isCloudKitAvailable = cloudKitService.isSignedIn
        self.contentSource = isCloudKitAvailable ? .hybrid : .local
    }
    
    /// Configure the service with a SwiftData model context
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Content Loading
    
    /// Load all locally available Hubs and Templates
    func loadLocalContent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let context = modelContext else {
                throw LocalMarketplaceError.contextNotConfigured
            }
            
            // Fetch all templates from SwiftData
            let templateDescriptor = FetchDescriptor<TemplateModel>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            let templates = try context.fetch(templateDescriptor)
            
            // Convert templates to marketplace items
            let items = templates.map { template in
                MarketplaceItem(
                    id: template.id,
                    name: template.name,
                    type: .template,
                    source: .local,
                    template: template,
                    hub: nil,
                    description: template.templateDescription,
                    author: template.author,
                    category: template.category,
                    icon: template.icon,
                    downloadCount: template.downloadCount,
                    rating: template.rating,
                    tags: template.tags,
                    createdAt: template.createdAt,
                    updatedAt: template.updatedAt
                )
            }
            
            localContent = items
            isLoading = false
            
            print("✅ Loaded \(items.count) local marketplace items")
        } catch {
            errorMessage = "Failed to load local content: \(error.localizedDescription)"
            isLoading = false
            print("❌ Error loading local content: \(error)")
        }
    }
    
    // MARK: - Search
    
    /// Search through local content
    func searchLocal(query: String) -> [MarketplaceItem] {
        guard !query.isEmpty else {
            return localContent
        }
        
        let lowercasedQuery = query.lowercased()
        
        return localContent.filter { item in
            item.name.lowercased().contains(lowercasedQuery) ||
            item.description.lowercased().contains(lowercasedQuery) ||
            item.author.lowercased().contains(lowercasedQuery) ||
            item.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    /// Search with category filter
    func searchLocal(query: String, category: HubCategory?) -> [MarketplaceItem] {
        var results = searchLocal(query: query)
        
        if let category = category {
            results = results.filter { $0.category == category }
        }
        
        return results
    }
    
    // MARK: - Download
    
    /// Download (copy) a template from local storage to user's workspace
    func downloadFromLocal(item: MarketplaceItem) async throws {
        guard let context = modelContext else {
            throw LocalMarketplaceError.contextNotConfigured
        }
        
        guard let template = item.template else {
            throw LocalMarketplaceError.templateNotFound
        }
        
        // Create a copy of the template for the user
        let copiedTemplate = TemplateModel(
            id: UUID(), // New ID for the copy
            name: template.name,
            category: template.category,
            description: template.templateDescription,
            icon: template.icon,
            author: template.author,
            version: template.version,
            sourceFiles: template.sourceFiles,
            features: template.features,
            dependencies: template.dependencies,
            isBuiltIn: false, // User's copy is not built-in
            tags: template.tags
        )
        
        // Copy source files data if available
        if let sourceFilesData = template.sourceFilesData {
            copiedTemplate.sourceFilesData = sourceFilesData
        }
        
        // Insert the copied template
        context.insert(copiedTemplate)
        try context.save()
        
        // Increment download count on original
        template.downloadCount += 1
        try context.save()
        
        print("✅ Downloaded template '\(template.name)' from local marketplace")
    }
    
    // MARK: - CloudKit Integration
    
    /// Check CloudKit availability and update status
    func checkCloudKitAvailability() async {
        await cloudKitService.checkAccountStatus()
        isCloudKitAvailable = cloudKitService.isSignedIn
        contentSource = isCloudKitAvailable ? .hybrid : .local
        
        if isCloudKitAvailable {
            print("✅ CloudKit is available - switching to hybrid mode")
        } else {
            print("ℹ️ CloudKit is unavailable - using local-only mode")
        }
    }
    
    /// Sync local content with CloudKit when available
    func syncWithCloud() async throws {
        guard isCloudKitAvailable else {
            throw LocalMarketplaceError.cloudKitUnavailable
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch cloud templates
            let cloudTemplates = try await cloudKitService.fetchPublicTemplates()
            
            // Merge with local content
            await mergeCloudContent(cloudTemplates)
            
            isLoading = false
            print("✅ Synced with CloudKit - \(cloudTemplates.count) cloud templates")
        } catch {
            errorMessage = "Failed to sync with cloud: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Merge cloud templates with local content, avoiding duplicates
    func mergeCloudContent(_ cloudTemplates: [CloudTemplate]) async {
        guard let context = modelContext else { return }
        
        var mergedItems = localContent
        
        for cloudTemplate in cloudTemplates {
            // Check if we already have this template locally
            let existsLocally = localContent.contains { item in
                item.template?.id == cloudTemplate.templateID
            }
            
            if !existsLocally {
                // Add cloud template as marketplace item
                let item = MarketplaceItem(
                    id: cloudTemplate.templateID,
                    name: cloudTemplate.name,
                    type: .template,
                    source: .cloud,
                    template: cloudTemplate.toHubTemplateModel(),
                    hub: nil,
                    description: cloudTemplate.templateDescription,
                    author: cloudTemplate.author,
                    category: cloudTemplate.category,
                    icon: cloudTemplate.icon,
                    downloadCount: cloudTemplate.downloadCount,
                    rating: cloudTemplate.rating,
                    tags: cloudTemplate.tags,
                    createdAt: cloudTemplate.createdAt,
                    updatedAt: cloudTemplate.updatedAt
                )
                mergedItems.append(item)
            }
        }
        
        localContent = mergedItems
        contentSource = .hybrid
    }
    
    // MARK: - Content Management
    
    /// Get all marketplace items (local or hybrid)
    func getAllContent() -> [MarketplaceItem] {
        return localContent
    }
    
    /// Get content by category
    func getContent(by category: HubCategory) -> [MarketplaceItem] {
        return localContent.filter { $0.category == category }
    }
    
    /// Get content by type
    func getContent(by type: MarketplaceItemType) -> [MarketplaceItem] {
        return localContent.filter { $0.type == type }
    }
    
    /// Get featured content (highest rated and most downloaded)
    func getFeaturedContent(limit: Int = 10) -> [MarketplaceItem] {
        return localContent
            .sorted { item1, item2 in
                // Sort by rating first, then by download count
                if item1.rating != item2.rating {
                    return item1.rating > item2.rating
                }
                return item1.downloadCount > item2.downloadCount
            }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Supporting Types

enum ContentSource: String, Codable {
    case local = "Local"
    case cloud = "Cloud"
    case hybrid = "Hybrid"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .local: return "internaldrive"
        case .cloud: return "icloud"
        case .hybrid: return "arrow.triangle.2.circlepath.icloud"
        }
    }
}

struct MarketplaceItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: MarketplaceItemType
    let source: ContentSource
    let template: TemplateModel?
    let hub: AppHub?
    let description: String
    let author: String
    let category: HubCategory
    let icon: String
    let downloadCount: Int
    let rating: Double
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MarketplaceItem, rhs: MarketplaceItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum MarketplaceItemType: String, Codable, CaseIterable {
    case template = "Template"
    case hub = "Hub"
    case bundle = "Bundle"
    
    var icon: String {
        switch self {
        case .template: return "doc.text"
        case .hub: return "square.grid.2x2"
        case .bundle: return "shippingbox"
        }
    }
}

enum LocalMarketplaceError: LocalizedError {
    case contextNotConfigured
    case templateNotFound
    case cloudKitUnavailable
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .contextNotConfigured:
            return "Model context not configured. Call configure(with:) first."
        case .templateNotFound:
            return "Template not found in marketplace item."
        case .cloudKitUnavailable:
            return "CloudKit is not available. Cannot sync with cloud."
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        }
    }
}
