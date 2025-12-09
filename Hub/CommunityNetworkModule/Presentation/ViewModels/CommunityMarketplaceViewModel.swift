import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Community Marketplace View Model

@MainActor
class CommunityMarketplaceViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var cloudTemplates: [CloudTemplateItem] = []
    @Published var allMarketplaceItems: [MarketplaceItem] = []
    @Published var filteredLocalItems: [MarketplaceItem] = []
    @Published var searchText: String = ""
    @Published var selectedContentType: MarketplaceItemType = .template
    @Published var selectedFilter: MarketplaceFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingTemplateDetail: Bool = false
    @Published var selectedTemplate: CloudTemplateItem?
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    // MARK: - Computed Properties
    
    var isSignedIn: Bool {
        CloudKitService.shared.isSignedIn
    }
    
    var userID: String? {
        CloudKitService.shared.userID
    }
    
    var totalItemCount: Int {
        allMarketplaceItems.count
    }
    
    // MARK: - Services
    
    private let cloudKitService = CloudKitService.shared
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkSignInStatus()
        }
    }
    
    // MARK: - Content Loading
    
    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate cloud template loading
            // In a real implementation, this would fetch from CloudKit
            cloudTemplates = []
            isLoading = false
            syncStatus = .success
            lastSyncDate = Date()
        } catch {
            errorMessage = "Failed to load cloud templates: \(error.localizedDescription)"
            isLoading = false
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    func checkSignInStatus() async {
        await cloudKitService.checkAccountStatus()
    }
    
    // MARK: - Content Merging
    
    func mergeLocalContent(_ localItems: [MarketplaceItem]) {
        // Merge local and cloud content
        var merged = localItems
        
        // Add cloud templates that don't exist locally
        for cloudTemplate in cloudTemplates {
            let existsLocally = localItems.contains { item in
                item.id == cloudTemplate.id
            }
            
            if !existsLocally {
                // Convert cloud template to marketplace item
                let item = MarketplaceItem(
                    id: cloudTemplate.id,
                    name: cloudTemplate.name,
                    type: .template,
                    source: .cloud,
                    template: nil,
                    hub: nil,
                    description: cloudTemplate.description,
                    author: cloudTemplate.author,
                    category: cloudTemplate.category,
                    icon: cloudTemplate.icon,
                    downloadCount: cloudTemplate.downloadCount,
                    rating: cloudTemplate.rating,
                    tags: cloudTemplate.tags,
                    createdAt: cloudTemplate.createdAt,
                    updatedAt: cloudTemplate.updatedAt
                )
                merged.append(item)
            }
        }
        
        allMarketplaceItems = merged
        applyFilters()
    }
    
    // MARK: - Filtering
    
    func selectContentType(_ type: MarketplaceItemType) {
        selectedContentType = type
        applyFilters()
    }
    
    func selectFilter(_ filter: MarketplaceFilter) {
        selectedFilter = filter
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = allMarketplaceItems
        
        // Filter by content type
        filtered = filtered.filter { $0.type == selectedContentType }
        
        // Filter by selected filter
        switch selectedFilter {
        case .all:
            break
        case .local:
            filtered = filtered.filter { $0.source == .local }
        case .cloud:
            filtered = filtered.filter { $0.source == .cloud }
        case .featured:
            filtered = filtered.sorted { $0.rating > $1.rating }.prefix(10).map { $0 }
        case .recent:
            filtered = filtered.sorted { $0.updatedAt > $1.updatedAt }
        case .popular:
            filtered = filtered.sorted { $0.downloadCount > $1.downloadCount }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { item in
                item.name.lowercased().contains(query) ||
                item.description.lowercased().contains(query) ||
                item.author.lowercased().contains(query) ||
                item.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        filteredLocalItems = filtered
    }
    
    // MARK: - Search
    
    func searchTemplates() async {
        applyFilters()
    }
    
    func clearSearch() {
        searchText = ""
        applyFilters()
    }
    
    func updateLocalSearchResults(_ results: [MarketplaceItem]) {
        filteredLocalItems = results
    }
    
    // MARK: - Download
    
    func downloadTemplate(_ template: CloudTemplateItem, templateManager: TemplateManager) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate download
            // In a real implementation, this would download from CloudKit
            isLoading = false
            print("✅ Downloaded template: \(template.name)")
        } catch {
            errorMessage = "Failed to download template: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Template Detail
    
    func showTemplateDetail(_ template: CloudTemplateItem) {
        selectedTemplate = template
        showingTemplateDetail = true
    }
    
    func hideTemplateDetail() {
        showingTemplateDetail = false
        selectedTemplate = nil
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Supporting Types

enum MarketplaceFilter: String, CaseIterable {
    case all = "All"
    case local = "Local Only"
    case cloud = "Cloud Only"
    case featured = "Featured"
    case recent = "Recently Updated"
    case popular = "Most Popular"
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error(String)
    
    var displayText: String {
        switch self {
        case .idle: return "Not synced"
        case .syncing: return "Syncing..."
        case .success: return "Synced"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .syncing: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
}

struct CloudTemplateItem: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let author: String
    let category: HubCategory
    let icon: String
    let downloadCount: Int
    let rating: Double
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
}
