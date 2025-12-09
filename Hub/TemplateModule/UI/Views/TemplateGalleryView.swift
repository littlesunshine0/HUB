import SwiftUI
import UniformTypeIdentifiers

struct TemplateGalleryView: View {
    @ObservedObject var templateManager: TemplateManager
    @ObservedObject var roleManager: RoleManager = .shared
    @StateObject private var cloudService = CloudKitService.shared
    @State private var showingTemplateEditor = false
    @State private var selectedTemplate: TemplateModel?
    @State private var showingImportDialog = false
    @State private var publishingTemplate: TemplateModel?
    @State private var showingReviewSheet = false
    @State private var reviewingTemplate: TemplateModel?
    @State private var selectedSection: GallerySection = .all
    @State private var showingBulkOperations = false
    @State private var selectedTemplates: Set<UUID> = []
    @State private var showingAnalytics = false
    
    enum GallerySection: String, CaseIterable {
        case all = "All Templates"
        case featured = "Featured"
        case popular = "Popular"
        case topRated = "Top Rated"
        case recent = "Recently Viewed"
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with filters
            List {
                Section("Sections") {
                    ForEach(GallerySection.allCases, id: \.self) { section in
                        Button {
                            selectedSection = section
                        } label: {
                            HStack {
                                Text(section.rawValue)
                                Spacer()
                                if selectedSection == section {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("Filters") {
                    TextField("Search templates...", text: $templateManager.searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: templateManager.searchText) { _, _ in
                            templateManager.applyFilters()
                        }
                    
                    Picker("Category", selection: $templateManager.selectedCategory) {
                        Text("All Categories").tag(nil as HubCategory?)
                        ForEach(HubCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category as HubCategory?)
                        }
                    }
                    .onChange(of: templateManager.selectedCategory) {  _, _ in
                        templateManager.applyFilters()
                    }
                    
                    Toggle("Built-in Only", isOn: $templateManager.showBuiltInOnly)
                        .onChange(of: templateManager.showBuiltInOnly) { _, _ in
                            templateManager.applyFilters()
                        }
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Total Templates:")
                        Spacer()
                        Text("\(templateManager.templates.count)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Built-in:")
                        Spacer()
                        Text("\(templateManager.templates.filter { $0.isBuiltIn }.count)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Custom:")
                        Spacer()
                        Text("\(templateManager.templates.filter { !$0.isBuiltIn }.count)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Filters")
            .frame(minWidth: 200)
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                // Owner Mode Indicator
                if roleManager.isOwner {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Owner Mode - Full Access")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("You can view, edit, and delete all templates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingBulkOperations.toggle()
                        } label: {
                            Label("Bulk Operations", systemImage: "square.stack.3d.up")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    
                    Divider()
                }
                
                // Header
                HStack {
                    Text("Template Gallery")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    // Browser navigation button
                    NavigationLink(destination: HubBrowserView()) {
                        Label("Browse", systemImage: "sidebar.left")
                    }
                    .buttonStyle(.bordered)
                    .help("Open Hub Browser")
                    
                    // Owner-specific analytics button
                    if roleManager.isOwner {
                        Button {
                            showingAnalytics = true
                        } label: {
                            Label("Analytics", systemImage: "chart.bar.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button {
                        showingImportDialog = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        selectedTemplate = nil
                        showingTemplateEditor = true
                    } label: {
                        Label("New Template", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Divider()
                
                // Template grid
                if currentTemplates.isEmpty {
                    ContentUnavailableView(
                        "No Templates Found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Try adjusting your filters or create a new template")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 20)
                        ], spacing: 20) {
                            ForEach(Array(currentTemplates.enumerated()), id: \.element.id) { index, template in
                                TemplateCard(
                                    template: template,
                                    isOwnerMode: roleManager.isOwner,
                                    canEdit: templateManager.canModifyTemplate(template),
                                    canDelete: templateManager.canDeleteTemplate(template),
                                    isSelected: selectedTemplates.contains(template.id),
                                    showSelectionCheckbox: showingBulkOperations && roleManager.isOwner,
                                    onView: {
                                        templateManager.trackTemplateView(template)
                                    },
                                    onEdit: {
                                        selectedTemplate = template
                                        showingTemplateEditor = true
                                    },
                                    onDuplicate: {
                                        templateManager.duplicateTemplate(template)
                                    },
                                    onDelete: {
                                        templateManager.deleteTemplate(template)
                                    },
                                    onExport: {
                                        exportTemplate(template)
                                    },
                                    onPublish: {
                                        await publishToMarketplace(template)
                                    },
                                    onReview: {
                                        reviewingTemplate = template
                                        showingReviewSheet = true
                                    },
                                    onToggleSelection: {
                                        toggleTemplateSelection(template.id)
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                                .animation(.easeOut.delay(Double(index) * 0.05), value: currentTemplates.count)
                            }
                        }
                        .padding()
                    }
                }
                
                // Bulk Operations Bar (Owner Only)
                if showingBulkOperations && roleManager.isOwner && !selectedTemplates.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack {
                            Text("\(selectedTemplates.count) selected")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                bulkExport()
                            } label: {
                                Label("Export Selected", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                bulkDelete()
                            } label: {
                                Label("Delete Selected", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            
                            Button {
                                selectedTemplates.removeAll()
                            } label: {
                                Text("Clear Selection")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplateEditor) {
            TemplateEditorView(
                templateManager: templateManager,
                template: selectedTemplate
            )
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(isPresented: $showingReviewSheet) {
            if let template = reviewingTemplate {
                TemplateReviewSheet(
                    template: template,
                    templateManager: templateManager,
                    onDismiss: {
                        showingReviewSheet = false
                        reviewingTemplate = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            OwnerAnalyticsView(
                templateManager: templateManager,
                onDismiss: {
                    showingAnalytics = false
                }
            )
        }
    }
    
    private var currentTemplates: [TemplateModel] {
        switch selectedSection {
        case .all:
            return templateManager.filteredTemplates
        case .featured:
            return templateManager.getFeaturedTemplates()
        case .popular:
            return templateManager.getPopularTemplates()
        case .topRated:
            return templateManager.getTopRatedTemplates()
        case .recent:
            return templateManager.getRecentlyViewedTemplates()
        }
    }
    
    private func exportTemplate(_ template: TemplateModel) {
        do {
            let data = try templateManager.exportTemplate(template)
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "\(template.name).hubtemplate"
            panel.allowedContentTypes = [.json]
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    try? data.write(to: url)
                }
            }
        } catch {
            print("Export failed: \(error.localizedDescription)")
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                try templateManager.importTemplate(from: data)
            } catch {
                print("Import failed: \(error.localizedDescription)")
            }
        case .failure(let error):
            print("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func publishToMarketplace(_ template: TemplateModel) async {
        guard cloudService.isSignedIn else {
            cloudService.errorMessage = "Please sign in to iCloud to publish templates"
            return
        }
        
        publishingTemplate = template
        
        do {
            try await cloudService.uploadTemplate(template)
            publishingTemplate = nil
        } catch {
            cloudService.errorMessage = "Failed to publish template: \(error.localizedDescription)"
            publishingTemplate = nil
        }
    }
    
    // MARK: - Owner-Specific Functions
    
    private func toggleTemplateSelection(_ templateId: UUID) {
        if selectedTemplates.contains(templateId) {
            selectedTemplates.remove(templateId)
        } else {
            selectedTemplates.insert(templateId)
        }
    }
    
    private func bulkExport() {
        let templatesToExport = templateManager.templates.filter { selectedTemplates.contains($0.id) }
        
        // Export all selected templates
        for template in templatesToExport {
            exportTemplate(template)
        }
        
        Task { @MainActor in
            await AppNotificationService.shared.showBanner(
                message: "Exported \(templatesToExport.count) templates",
                level: .success
            )
        }
        
        selectedTemplates.removeAll()
    }
    
    private func bulkDelete() {
        let templatesToDelete = templateManager.templates.filter { selectedTemplates.contains($0.id) }
        
        // Confirm deletion
        let alert = NSAlert()
        alert.messageText = "Delete \(templatesToDelete.count) Templates?"
        alert.informativeText = "This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            for template in templatesToDelete {
                if templateManager.canDeleteTemplate(template) {
                    templateManager.deleteTemplate(template)
                }
            }
            
            Task { @MainActor in
                await AppNotificationService.shared.showBanner(
                    message: "Deleted \(templatesToDelete.count) templates",
                    level: .success
                )
            }
        }
        
        selectedTemplates.removeAll()
    }
}

struct TemplateCard: View {
    let template: TemplateModel
    let isOwnerMode: Bool
    let canEdit: Bool
    let canDelete: Bool
    let isSelected: Bool
    let showSelectionCheckbox: Bool
    let onView: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void
    let onPublish: () async -> Void
    let onReview: () -> Void
    let onToggleSelection: () -> Void
    
    @State private var showingActions = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview Image or Icon
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .topLeading) {
                    if let previewData = template.previewImageData,
                       let nsImage = NSImage(data: previewData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Fallback to icon-based preview
                        ZStack {
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Image(systemName: template.icon)
                                .font(.system(size: 60))
                                .foregroundStyle(.white)
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Selection checkbox (Owner mode only)
                    if showSelectionCheckbox {
                        Button {
                            onToggleSelection()
                        } label: {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(isSelected ? .blue : .white)
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
                
                // Featured badge
                if template.isFeatured {
                    Label("Featured", systemImage: "star.fill")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.yellow)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        // Owner mode indicator
                        if isOwnerMode && !template.isBuiltIn && template.userID != nil {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .help("User template: \(template.userID ?? "unknown")")
                        }
                    }
                    
                    Label(template.category.rawValue, systemImage: template.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if template.isBuiltIn {
                        Label("Built-in", systemImage: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    
                    // Owner access indicator
                    if isOwnerMode {
                        HStack(spacing: 4) {
                            if canEdit {
                                Image(systemName: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                            if canDelete {
                                Image(systemName: "trash")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            
            // Rating and Stats
            HStack(spacing: 12) {
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", template.averageRating))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("(\(template.reviewCount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 12)
                
                // Downloads
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("\(template.downloadCount)")
                        .font(.caption)
                }
                
                Divider()
                    .frame(height: 12)
                
                // Views
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("\(template.viewCount)")
                        .font(.caption)
                }
                
                Spacer()
            }
            
            // Description
            Text(template.templateDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(height: 32)
            
            // Features
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(template.features.prefix(3), id: \.self) { feature in
                        Text(feature)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    if template.features.count > 3 {
                        Text("+\(template.features.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Metadata
            HStack {
                Label(template.author, systemImage: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(template.version, systemImage: "number")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    onView()
                    if canEdit {
                        onEdit()
                    }
                } label: {
                    Label(canEdit ? "Edit" : "View", systemImage: canEdit ? "pencil" : "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button {
                    onReview()
                } label: {
                    Label("Review", systemImage: "star")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Menu {
                    Button {
                        onDuplicate()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        onExport()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        Task {
                            await onPublish()
                        }
                    } label: {
                        Label("Publish to Marketplace", systemImage: "icloud.and.arrow.up")
                    }
                    .disabled(template.isBuiltIn && !isOwnerMode)
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(!canDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Template Review Sheet

struct TemplateReviewSheet: View {
    let template: TemplateModel
    let templateManager: TemplateManager
    let onDismiss: () -> Void
    
    @State private var rating: Double = 5.0
    @State private var comment: String = ""
    @State private var userName: String = "Anonymous"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Review Template")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(template.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Rating")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = Double(star)
                        } label: {
                            Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                                .font(.title)
                                .foregroundStyle(Double(star) <= rating ? .yellow : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(String(format: "%.0f/5", rating))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // User Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.headline)
                
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Comment
            VStack(alignment: .leading, spacing: 8) {
                Text("Review")
                    .font(.headline)
                
                TextEditor(text: $comment)
                    .frame(height: 120)
                    .border(Color.gray.opacity(0.3), width: 1)
            }
            
            // Existing Reviews
            if !template.reviews.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Reviews")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(template.reviews.prefix(3)) { review in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(review.userName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: Double(star) <= review.rating ? "star.fill" : "star")
                                                    .font(.caption)
                                                    .foregroundStyle(.yellow)
                                            }
                                        }
                                    }
                                    
                                    Text(review.comment)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(review.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Submit Review") {
                    templateManager.addReview(
                        to: template,
                        rating: rating,
                        comment: comment,
                        userName: userName.isEmpty ? "Anonymous" : userName,
                        userID: "current-user" // TODO: Get actual user ID from auth system
                    )
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(comment.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
}

// MARK: - Owner Analytics View

struct OwnerAnalyticsView: View {
    let templateManager: TemplateManager
    let onDismiss: () -> Void
    
    private var totalTemplates: Int {
        templateManager.templates.count
    }
    
    private var builtInTemplates: Int {
        templateManager.templates.filter { $0.isBuiltIn }.count
    }
    
    private var userCreatedTemplates: Int {
        templateManager.templates.filter { !$0.isBuiltIn }.count
    }
    
    private var totalDownloads: Int {
        templateManager.templates.reduce(0) { $0 + $1.downloadCount }
    }
    
    private var totalViews: Int {
        templateManager.templates.reduce(0) { $0 + $1.viewCount }
    }
    
    private var averageRating: Double {
        guard totalTemplates > 0 else { return 0.0 }
        return templateManager.templates.reduce(0.0) { $0 + $1.averageRating } / Double(totalTemplates)
    }
    
    private var totalReviews: Int {
        templateManager.templates.reduce(0) { $0 + $1.reviewCount }
    }
    
    private var categoryBreakdown: [(category: HubCategory, count: Int)] {
        let grouped = Dictionary(grouping: templateManager.templates) { $0.category }
        return grouped.map { (category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    private var topTemplates: [TemplateModel] {
        templateManager.templates
            .sorted { $0.downloadCount > $1.downloadCount }
            .prefix(5)
            .map { $0 }
    }
    
    private var uniqueAuthors: Int {
        Set(templateManager.templates.map { $0.author }).count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading) {
                        Text("Owner Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("System-wide template statistics")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        TemplateGalleryStatCard(
                            title: "Total Templates",
                            value: "\(totalTemplates)",
                            icon: "doc.text.fill",
                            color: .blue
                        )
                        
                        TemplateGalleryStatCard(
                            title: "Total Downloads",
                            value: "\(totalDownloads)",
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )
                        
                        TemplateGalleryStatCard(
                            title: "Total Views",
                            value: "\(totalViews)",
                            icon: "eye.fill",
                            color: .purple
                        )
                        
                        TemplateGalleryStatCard(
                            title: "Average Rating",
                            value: String(format: "%.1f", averageRating),
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        TemplateGalleryStatCard(
                            title: "Total Reviews",
                            value: "\(totalReviews)",
                            icon: "text.bubble.fill",
                            color: .orange
                        )
                        
                        TemplateGalleryStatCard(
                            title: "Unique Authors",
                            value: "\(uniqueAuthors)",
                            icon: "person.fill",
                            color: .pink
                        )
                    }
                    
                    Divider()
                    
                    // Template Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Breakdown")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                    Text("Built-in Templates")
                                        .font(.subheadline)
                                }
                                Text("\(builtInTemplates)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 12, height: 12)
                                    Text("User-Created")
                                        .font(.subheadline)
                                }
                                Text("\(userCreatedTemplates)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Divider()
                    
                    // Category Distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category Distribution")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ForEach(categoryBreakdown, id: \.category) { item in
                                HStack {
                                    Label(item.category.rawValue, systemImage: item.category.icon)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(item.count)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                    
                                    // Progress bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                            
                                            Rectangle()
                                                .fill(Color.accentColor)
                                                .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(totalTemplates))
                                        }
                                    }
                                    .frame(width: 100, height: 8)
                                    .clipShape(Capsule())
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Divider()
                    
                    // Top Templates
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top 5 Templates by Downloads")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(topTemplates.enumerated()), id: \.element.id) { index, template in
                                HStack {
                                    Text("#\(index + 1)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 30)
                                    
                                    Image(systemName: template.icon)
                                        .foregroundStyle(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(template.category.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .font(.caption)
                                            Text("\(template.downloadCount)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundStyle(.yellow)
                                            Text(String(format: "%.1f", template.averageRating))
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 800)
    }
}

// MARK: - Stat Card Component

private struct TemplateGalleryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
