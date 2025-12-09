import SwiftUI
import SwiftData
import Combine

// MARK: - Community Marketplace View

/// Enhanced marketplace view with local/cloud indicators, offline mode, and sync status
/// Requirements: 4.1, 4.5, 8.5
struct CommunityMarketplaceView: View {
    @StateObject private var viewModel = CommunityMarketplaceViewModel()
    @ObservedObject var templateManager: TemplateManager
    @StateObject private var localMarketplace = LocalMarketplaceService.shared
    
    var body: some View {
        NavigationSplitView {
            sidebarList
        } detail: {
            detailView
        }
    }
    
    private var sidebarList: some View {
        List {
            // Content Source Section with enhanced indicators
            Section("Content Source") {
                contentSourceSection
            }
            
            // Sync Status Section
            Section("Sync Status") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.syncStatus.icon)
                            .foregroundStyle(viewModel.syncStatus.color)
                        Text(viewModel.syncStatus.displayText)
                            .font(.caption)
                        Spacer()
                    }
                    
                    if let lastSync = viewModel.lastSyncDate {
                        Text("Last synced: \(lastSync, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if viewModel.syncStatus == .syncing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Account") {
                if viewModel.isSignedIn {
                    Label("Signed In", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if let userID = viewModel.userID {
                        Text("User: \(userID)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label("Not Signed In", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Using local content only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Content Type Filter
            Section("Content Type") {
                ForEach(MarketplaceItemType.allCases, id: \.self) { type in
                    Button {
                        viewModel.selectContentType(type)
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                            Spacer()
                            if viewModel.selectedContentType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Filters") {
                ForEach(MarketplaceFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.selectFilter(filter)
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                            Spacer()
                            if viewModel.selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Statistics") {
                HStack {
                    Text("Cloud:")
                    Spacer()
                    Text("\(viewModel.cloudTemplates.count)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("Local:")
                    Spacer()
                    Text("\(localMarketplace.localContent.count)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("Total:")
                    Spacer()
                    Text("\(viewModel.totalItemCount)")
                        .foregroundStyle(.blue)
                }
                .font(.caption)
                .bold()
            }
            
            // Sync Actions
            if localMarketplace.isCloudKitAvailable {
                Section {
                    Button {
                        Task {
                            await syncContent()
                        }
                    } label: {
                        Label("Sync with Cloud", systemImage: "arrow.triangle.2.circlepath.icloud")
                    }
                    .disabled(localMarketplace.isLoading)
                }
            }
        }
        .navigationTitle("Filters")
    }
    
    private var detailView: some View {
        VStack(spacing: 0) {
            // Header with sync status
            HStack {
                VStack(alignment: .leading) {
                    Text("Community Marketplace")
                        .font(.largeTitle)
                        .bold()
                    HStack(spacing: 8) {
                        Text(marketplaceSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Sync status indicator
                        if localMarketplace.isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Syncing...")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        } else if localMarketplace.contentSource == .hybrid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("Synced")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Refresh button
                Button {
                    Task {
                        await refreshContent()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading || localMarketplace.isLoading)
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search templates...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content
            if viewModel.isLoading || localMarketplace.isLoading {
                ProgressView("Loading content...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.allMarketplaceItems.isEmpty {
                ContentUnavailableView(
                    "No Content Available",
                    systemImage: "tray",
                    description: Text(emptyStateMessage)
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Seeded Content Section (Local content) - Enhanced
                        if !localMarketplace.localContent.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Section header with badge
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "internaldrive")
                                            .foregroundStyle(.blue)
                                            .font(.title3)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 8) {
                                            Text("Local Content")
                                                .font(.title2)
                                                .bold()
                                            
                                            // Seeded badge
                                            Text("SEEDED")
                                                .font(.caption2)
                                                .bold()
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue)
                                                .foregroundStyle(.white)
                                                .cornerRadius(4)
                                        }
                                        
                                        Text("Available offline • \(localMarketplace.localContent.count) items")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Local content indicator
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                        Text("Ready")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                
                                // Content grid
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 20)
                                ], spacing: 20) {
                                    ForEach(viewModel.filteredLocalItems) { item in
                                        MarketplaceItemCard(
                                            item: item,
                                            onDownload: {
                                                await downloadItem(item)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Cloud Content Section (if available) - Enhanced
                        if viewModel.isSignedIn && !viewModel.cloudTemplates.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Section header with sync indicator
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.purple.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "icloud")
                                            .foregroundStyle(.purple)
                                            .font(.title3)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 8) {
                                            Text("Cloud Content")
                                                .font(.title2)
                                                .bold()
                                            
                                            // Cloud badge
                                            Text("SYNCED")
                                                .font(.caption2)
                                                .bold()
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.purple)
                                                .foregroundStyle(.white)
                                                .cornerRadius(4)
                                        }
                                        
                                        Text("Community shared • \(viewModel.cloudTemplates.count) items")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Sync status indicator
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Image(systemName: viewModel.syncStatus.icon)
                                            .foregroundStyle(viewModel.syncStatus.color)
                                            .font(.title3)
                                        Text(viewModel.syncStatus.displayText)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                
                                // Content grid
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 20)
                                ], spacing: 20) {
                                    ForEach(viewModel.cloudTemplates) { template in
                                        CloudTemplateCard(
                                            template: template,
                                            onDownload: {
                                                await viewModel.downloadTemplate(template, templateManager: templateManager)
                                            },
                                            onViewDetails: {
                                                viewModel.showTemplateDetail(template)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Enhanced offline mode notice
                        if !viewModel.isSignedIn && !localMarketplace.localContent.isEmpty {
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "wifi.slash")
                                            .font(.title)
                                            .foregroundStyle(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Offline Mode Active")
                                            .font(.headline)
                                        Text("You're browsing local content only")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Local content is fully functional", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    
                                    Label("Sign in to iCloud for cloud content", systemImage: "icloud")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Label("All features work offline", systemImage: "bolt.fill")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        // TODO: Fix CloudTemplateItem to CloudTemplate conversion
        // .sheet(isPresented: $viewModel.showingTemplateDetail) {
        //     if let template = viewModel.selectedTemplate {
        //         CloudTemplateDetailView(
        //             template: template,
        //             cloudService: CloudKitService.shared,
        //             onDownload: {
        //                 await viewModel.downloadTemplate(template, templateManager: templateManager)
        //                 viewModel.hideTemplateDetail()
        //             }
        //         )
        //     }
        // }
        .task {
            await initializeMarketplace()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil || localMarketplace.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
                localMarketplace.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? localMarketplace.errorMessage ?? "")
        }
    }
    
    // MARK: - Computed Properties
    
    private var contentSourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: localMarketplace.contentSource.icon)
                    .foregroundStyle(contentSourceColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localMarketplace.contentSource.displayName)
                        .font(.headline)
                    Text(contentSourceDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if localMarketplace.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            // Offline mode indicator
            if !localMarketplace.isCloudKitAvailable {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("Offline Mode Active")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var contentSourceColor: Color {
        switch localMarketplace.contentSource {
        case .local: return .blue
        case .cloud: return .purple
        case .hybrid: return .green
        }
    }
    
    private var contentSourceDescription: String {
        switch localMarketplace.contentSource {
        case .local: return "Device storage only"
        case .cloud: return "iCloud synced"
        case .hybrid: return "Local + Cloud"
        }
    }
    
    private var marketplaceSubtitle: String {
        switch localMarketplace.contentSource {
        case .local:
            return "Browsing local content (offline)"
        case .cloud:
            return "Browsing cloud content"
        case .hybrid:
            return "Browsing local and cloud content"
        }
    }
    
    private var emptyStateMessage: String {
        if !viewModel.isSignedIn {
            return "No local content available. Sign in to iCloud to access cloud content."
        } else {
            return "No content found. Try adjusting your filters or search query."
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeMarketplace() async {
        // Configure local marketplace with model context
        localMarketplace.configure(with: templateManager.modelContext)
        
        // Load local content
        await localMarketplace.loadLocalContent()
        
        // Check CloudKit availability
        await localMarketplace.checkCloudKitAvailability()
        
        // Load cloud content if available
        if viewModel.isSignedIn {
            await viewModel.loadTemplates()
        }
        
        // Merge content in view model
        viewModel.mergeLocalContent(localMarketplace.localContent)
    }
    
    private func refreshContent() async {
        await localMarketplace.loadLocalContent()
        await localMarketplace.checkCloudKitAvailability()
        
        if viewModel.isSignedIn {
            await viewModel.loadTemplates()
        }
        
        viewModel.mergeLocalContent(localMarketplace.localContent)
    }
    
    private func syncContent() async {
        do {
            try await localMarketplace.syncWithCloud()
            await viewModel.loadTemplates()
            viewModel.mergeLocalContent(localMarketplace.localContent)
        } catch {
            print("❌ Sync failed: \(error)")
        }
    }
    
    private func performSearch() async {
        if viewModel.searchText.isEmpty {
            await refreshContent()
        } else {
            // Search both local and cloud
            let localResults = localMarketplace.searchLocal(query: viewModel.searchText)
            viewModel.updateLocalSearchResults(localResults)
            
            if viewModel.isSignedIn {
                await viewModel.searchTemplates()
            }
        }
    }
    
    private func downloadItem(_ item: MarketplaceItem) async {
        do {
            try await localMarketplace.downloadFromLocal(item: item)
            await localMarketplace.loadLocalContent()
            viewModel.mergeLocalContent(localMarketplace.localContent)
        } catch {
            localMarketplace.errorMessage = "Failed to download: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Marketplace Item Card
    
    struct MarketplaceItemCard: View {
        let item: MarketplaceItem
        let onDownload: () async -> Void
        
        @State private var isDownloading = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and source indicator
                HStack {
                    Image(systemName: item.icon)
                        .font(.title)
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Source badge
                    HStack(spacing: 4) {
                        Image(systemName: item.source.icon)
                            .font(.caption2)
                        Text(item.source.displayName)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sourceBackgroundColor)
                    .foregroundStyle(sourceForegroundColor)
                    .cornerRadius(6)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Metadata
                HStack(spacing: 12) {
                    Label("\(item.downloadCount)", systemImage: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label(String(format: "%.1f", item.rating), systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(item.type.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Tags
                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Download button
                Button {
                    Task {
                        isDownloading = true
                        await onDownload()
                        isDownloading = false
                    }
                } label: {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isDownloading ? "Downloading..." : "Download")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDownloading)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        
        private var sourceBackgroundColor: Color {
            switch item.source {
            case .local: return Color.blue.opacity(0.2)
            case .cloud: return Color.purple.opacity(0.2)
            case .hybrid: return Color.green.opacity(0.2)
            }
        }
        
        private var sourceForegroundColor: Color {
            switch item.source {
            case .local: return .blue
            case .cloud: return .purple
            case .hybrid: return .green
            }
        }
    }
    
    
    // MARK: - Cloud Template Card
    
    struct CloudTemplateCard: View {
        let template: CloudTemplateItem
        let onDownload: () async -> Void
        let onViewDetails: () -> Void
        
        @State private var isDownloading = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and cloud badge
                HStack {
                    Image(systemName: template.icon)
                        .font(.title)
                        .foregroundStyle(.purple)
                        .frame(width: 44, height: 44)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Cloud badge
                    HStack(spacing: 4) {
                        Image(systemName: "icloud")
                            .font(.caption2)
                        Text("Cloud")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundStyle(.purple)
                    .cornerRadius(6)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Metadata
                HStack(spacing: 12) {
                    Label("\(template.downloadCount)", systemImage: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label(String(format: "%.1f", template.rating), systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(template.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Tags
                if !template.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(template.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    Button {
                        onViewDetails()
                    } label: {
                        Text("Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        Task {
                            isDownloading = true
                            await onDownload()
                            isDownloading = false
                        }
                    } label: {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(isDownloading ? "Downloading..." : "Download")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isDownloading)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    
    // MARK: - Flow Layout Helper
    
    private struct CommunityFlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(
                in: proposal.replacingUnspecifiedDimensions().width,
                subviews: subviews,
                spacing: spacing
            )
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(
                in: bounds.width,
                subviews: subviews,
                spacing: spacing
            )
            for (index, subview) in subviews.enumerated() {
                subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
            }
        }
        
        struct FlowResult {
            var size: CGSize = .zero
            var positions: [CGPoint] = []
            
            init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var x: CGFloat = 0
                var y: CGFloat = 0
                var lineHeight: CGFloat = 0
                
                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if x + size.width > maxWidth && x > 0 {
                        x = 0
                        y += lineHeight + spacing
                        lineHeight = 0
                    }
                    
                    positions.append(CGPoint(x: x, y: y))
                    lineHeight = max(lineHeight, size.height)
                    x += size.width + spacing
                }
                
                self.size = CGSize(width: maxWidth, height: y + lineHeight)
            }
        }
    }
}

