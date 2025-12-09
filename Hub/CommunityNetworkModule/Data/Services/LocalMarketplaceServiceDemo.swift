import SwiftUI
import SwiftData
import Combine
// MARK: - Local Marketplace Service Demo

/// Demo view showing how to use LocalMarketplaceService
struct LocalMarketplaceServiceDemo: View {
    @State private var marketplaceService = LocalMarketplaceService.shared
    @State private var searchQuery = ""
    @State private var selectedCategory: HubCategory?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Bar
                statusBar
                
                // Search Bar
                searchBar
                
                // Content List
                if marketplaceService.isLoading {
                    ProgressView("Loading marketplace...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredContent.isEmpty {
                    emptyState
                } else {
                    contentList
                }
            }
            .navigationTitle("Local Marketplace")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Refresh Local Content") {
                            Task {
                                await marketplaceService.loadLocalContent()
                            }
                        }
                        
                        Button("Check CloudKit") {
                            Task {
                                await marketplaceService.checkCloudKitAvailability()
                            }
                        }
                        
                        if marketplaceService.isCloudKitAvailable {
                            Button("Sync with Cloud") {
                                Task {
                                    try? await marketplaceService.syncWithCloud()
                                }
                            }
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(marketplaceService.errorMessage ?? "Unknown error")
            }
            .task {
                await marketplaceService.loadLocalContent()
            }
        }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            Image(systemName: marketplaceService.contentSource.icon)
                .foregroundStyle(sourceColor)
            
            Text(marketplaceService.contentSource.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(filteredContent.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var sourceColor: Color {
        switch marketplaceService.contentSource {
        case .local: return .blue
        case .cloud: return .green
        case .hybrid: return .purple
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search templates...", text: $searchQuery)
                    .textFieldStyle(.plain)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    MarketplaceCategoryChip(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(HubCategory.allCases, id: \.self) { category in
                        MarketplaceCategoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
    }
    
    // MARK: - Content List
    
    private var contentList: some View {
        List {
            ForEach(filteredContent) { item in
                MarketplaceItemRow(item: item) {
                    Task {
                        do {
                            try await marketplaceService.downloadFromLocal(item: item)
                        } catch {
                            marketplaceService.errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No items found")
                .font(.headline)
            
            Text("Try adjusting your search or filters")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Load Content") {
                Task {
                    await marketplaceService.loadLocalContent()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filtered Content
    
    private var filteredContent: [MarketplaceItem] {
        marketplaceService.searchLocal(query: searchQuery, category: selectedCategory)
    }
}

// MARK: - Marketplace Category Chip

struct MarketplaceCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Marketplace Item Row

struct MarketplaceItemRow: View {
    let item: MarketplaceItem
    let onDownload: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                    
                    // Source indicator
                    Image(systemName: item.source.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label("\(item.downloadCount)", systemImage: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label(String(format: "%.1f", item.rating), systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Download Button
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    LocalMarketplaceServiceDemo()
}

// MARK: - Usage Examples

/*
 
 EXAMPLE 1: Basic Setup
 ----------------------
 
 import SwiftUI
 import SwiftData
 
 @main
 struct MyApp: App {
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .modelContainer(for: [HubTemplateModel.self])
         }
     }
 }
 
 struct ContentView: View {
     @Environment(\.modelContext) private var modelContext
     @StateObject private var marketplace = LocalMarketplaceService.shared
     
     var body: some View {
         MarketplaceView()
             .task {
                 // Configure with model context
                 marketplace.configure(with: modelContext)
                 
                 // Load local content
                 await marketplace.loadLocalContent()
             }
     }
 }
 
 
 EXAMPLE 2: Search Functionality
 --------------------------------
 
 struct SearchView: View {
     @StateObject private var marketplace = LocalMarketplaceService.shared
     @State private var searchQuery = ""
     
     var body: some View {
         VStack {
             TextField("Search...", text: $searchQuery)
             
             List(searchResults) { item in
                 Text(item.name)
             }
         }
     }
     
     var searchResults: [MarketplaceItem] {
         marketplace.searchLocal(query: searchQuery)
     }
 }
 
 
 EXAMPLE 3: Download Template
 -----------------------------
 
 struct MarketplaceTemplateDetailView: View {
     let item: MarketplaceItem
     @StateObject private var marketplace = LocalMarketplaceService.shared
     @State private var isDownloading = false
     
     var body: some View {
         VStack {
             Text(item.name)
             
             Button("Download") {
                 Task {
                     isDownloading = true
                     try? await marketplace.downloadFromLocal(item: item)
                     isDownloading = false
                 }
             }
             .disabled(isDownloading)
         }
     }
 }
 
 
 EXAMPLE 4: CloudKit Sync
 -------------------------
 
 struct SyncView: View {
     @StateObject private var marketplace = LocalMarketplaceService.shared
     
     var body: some View {
         VStack {
             Text("Source: \(marketplace.contentSource.displayName)")
             
             if marketplace.isCloudKitAvailable {
                 Button("Sync with Cloud") {
                     Task {
                         try? await marketplace.syncWithCloud()
                     }
                 }
             } else {
                 Text("CloudKit unavailable - using local only")
                     .foregroundStyle(.secondary)
             }
         }
         .task {
             await marketplace.checkCloudKitAvailability()
         }
     }
 }
 
 
 EXAMPLE 5: Category Filtering
 ------------------------------
 
 struct CategoryView: View {
     @StateObject private var marketplace = LocalMarketplaceService.shared
     let category: HubCategory
     
     var body: some View {
         List(categoryContent) { item in
             Text(item.name)
         }
         .navigationTitle(category.rawValue)
     }
     
     var categoryContent: [MarketplaceItem] {
         marketplace.getContent(by: category)
     }
 }
 
 
 EXAMPLE 6: Featured Content
 ----------------------------
 
 struct FeaturedView: View {
     @StateObject private var marketplace = LocalMarketplaceService.shared
     
     var body: some View {
         ScrollView {
             LazyVStack {
                 ForEach(marketplace.getFeaturedContent(limit: 5)) { item in
                     FeaturedItemCard(item: item)
                 }
             }
         }
     }
 }
 
 */

