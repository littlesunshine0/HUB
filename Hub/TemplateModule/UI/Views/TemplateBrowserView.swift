import SwiftUI
import UniformTypeIdentifiers

/// Professional template browser with multiple view modes, preview, and advanced features
struct TemplateBrowserView: View {
    @ObservedObject var templateManager: TemplateManager
    @ObservedObject var roleManager: RoleManager = .shared
    @StateObject private var cloudService = CloudKitService.shared
    
    // View State
    @State private var viewMode: ViewMode = .gallery
    @State private var selectedTemplate: TemplateModel?
    @State private var showingPreview = true
    @State private var selectedSection: BrowserSection = .all
    @State private var sortOption: SortOption = .name
    @State private var groupOption: GroupOption = .none
    
    // Actions
    @State private var showingTemplateEditor = false
    @State private var showingCodeEditor = false
    @State private var editingTemplate: TemplateModel?
    @State private var showingImportDialog = false
    @State private var showingNewTemplate = false
    @State private var showingBulkOperations = false
    @State private var selectedTemplates: Set<UUID> = []
    @State private var showingCleanup = false
    @State private var showingAnalytics = false
    @State private var publishingTemplate: TemplateModel?
    @State private var showingReviewSheet = false
    @State private var reviewingTemplate: TemplateModel?
    
    // MARK: - Enums
    
    enum ViewMode: String, CaseIterable {
        case gallery = "Gallery"
        case column = "Column"
        case list = "List"
        
        var icon: String {
            switch self {
            case .gallery: return "square.grid.2x2"
            case .column: return "rectangle.split.3x1"
            case .list: return "list.bullet"
            }
        }
    }
    
    enum BrowserSection: String, CaseIterable {
        case all = "All Templates"
        case featured = "Featured"
        case popular = "Popular"
        case topRated = "Top Rated"
        case recent = "Recently Viewed"
        case myTemplates = "My Templates"
        
        var icon: String {
            switch self {
            case .all: return "square.stack.3d.up"
            case .featured: return "star.fill"
            case .popular: return "chart.line.uptrend.xyaxis"
            case .topRated: return "star.circle.fill"
            case .recent: return "clock.fill"
            case .myTemplates: return "person.fill"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case dateCreated = "Date Created"
        case dateModified = "Date Modified"
        case rating = "Rating"
        case downloads = "Downloads"
        case category = "Category"
        
        var icon: String {
            switch self {
            case .name: return "textformat"
            case .dateCreated: return "calendar.badge.plus"
            case .dateModified: return "calendar.badge.clock"
            case .rating: return "star.fill"
            case .downloads: return "arrow.down.circle.fill"
            case .category: return "folder.fill"
            }
        }
    }
    
    enum GroupOption: String, CaseIterable {
        case none = "None"
        case category = "Category"
        case author = "Author"
        case rating = "Rating"
        case type = "Type"
        
        var icon: String {
            switch self {
            case .none: return "square.stack"
            case .category: return "folder.fill"
            case .author: return "person.fill"
            case .rating: return "star.fill"
            case .type: return "doc.fill"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HSplitView {
            // Left: Sidebar
            sidebarView
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)
                .frame(maxHeight: .infinity)
            
            // Center: Template List/Grid
            templateContentView
                .frame(minWidth: 400)
                .frame(maxHeight: .infinity)
            
            // Right: Preview Panel (optional)
            if showingPreview {
                previewPanel
                    .frame(minWidth: 300, idealWidth: 350, maxWidth: 500)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingTemplateEditor) {
            if let template = editingTemplate {
                TemplateEditorSheet(template: template, templateManager: templateManager)
            }
        }
        .sheet(isPresented: $showingCodeEditor) {
            if let template = editingTemplate {
                TemplateCodeEditorView(template: template, templateManager: templateManager)
            }
        }
        .sheet(isPresented: $showingNewTemplate) {
            NewTemplateSheet(templateManager: templateManager)
        }
        .sheet(isPresented: $showingCleanup) {
            TemplateCleanupView(templateManager: templateManager)
        }
        .sheet(isPresented: $showingAnalytics) {
            TemplateAnalyticsView(templateManager: templateManager)
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        List(selection: $selectedTemplate) {
            // Sections
            Section("Browse") {
                ForEach(BrowserSection.allCases, id: \.self) { section in
                    Button {
                        selectedSection = section
                        applySection()
                    } label: {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedSection == section ? .blue : .primary)
                }
            }
            
            // Filters
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
                .onChange(of: templateManager.selectedCategory) { _, _ in
                    templateManager.applyFilters()
                }
                
                Toggle("Built-in Only", isOn: $templateManager.showBuiltInOnly)
                    .onChange(of: templateManager.showBuiltInOnly) { _, _ in
                        templateManager.applyFilters()
                    }
            }
            
            // Statistics
            Section("Statistics") {
                BrowserStatRow(label: "Total", value: "\(templateManager.templates.count)")
                BrowserStatRow(label: "Filtered", value: "\(filteredTemplates.count)")
                BrowserStatRow(label: "Built-in", value: "\(templateManager.templates.filter { $0.isBuiltIn }.count)")
                BrowserStatRow(label: "Custom", value: "\(templateManager.templates.filter { !$0.isBuiltIn }.count)")
                BrowserStatRow(label: "Featured", value: "\(templateManager.templates.filter { $0.isFeatured }.count)")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Template Browser")
    }
    
    // MARK: - Content View
    
    private var templateContentView: some View {
        VStack(spacing: 0) {
            // Header with controls
            contentHeader
            
            Divider()
            
            // Template content based on view mode
            ScrollView {
                switch viewMode {
                case .gallery:
                    galleryView
                case .column:
                    columnView
                case .list:
                    listView
                }
            }
        }
    }
    
    private var contentHeader: some View {
        HStack {
            // View mode picker
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            Spacer()
            
            // Sort menu
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Label("Sort: \(sortOption.rawValue)", systemImage: "arrow.up.arrow.down")
            }
            
            // Group menu
            Menu {
                ForEach(GroupOption.allCases, id: \.self) { option in
                    Button {
                        groupOption = option
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                        if groupOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Label("Group: \(groupOption.rawValue)", systemImage: "square.stack.3d.up")
            }
            
            // Preview toggle
            Button {
                withAnimation {
                    showingPreview.toggle()
                }
            } label: {
                Label("Preview", systemImage: showingPreview ? "sidebar.right" : "sidebar.left")
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Gallery View
    
    private var galleryView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
        ], spacing: 16) {
            ForEach(sortedAndGroupedTemplates) { template in
                BrowserTemplateCard(
                    template: template,
                    isSelected: selectedTemplate?.id == template.id,
                    isMultiSelected: selectedTemplates.contains(template.id)
                )
                .onTapGesture {
                    selectedTemplate = template
                    templateManager.trackTemplateView(template)
                }
                .contextMenu {
                    templateContextMenu(for: template)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Column View
    
    private var columnView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(sortedAndGroupedTemplates) { template in
                TemplateColumnCard(
                    template: template,
                    isSelected: selectedTemplate?.id == template.id
                )
                .onTapGesture {
                    selectedTemplate = template
                    templateManager.trackTemplateView(template)
                }
                .contextMenu {
                    templateContextMenu(for: template)
                }
            }
        }
        .padding()
    }
    
    // MARK: - List View
    
    private var listView: some View {
        LazyVStack(spacing: 1) {
            ForEach(sortedAndGroupedTemplates) { template in
                TemplateListRow(
                    template: template,
                    isSelected: selectedTemplate?.id == template.id,
                    isMultiSelected: selectedTemplates.contains(template.id)
                )
                .onTapGesture {
                    selectedTemplate = template
                    templateManager.trackTemplateView(template)
                }
                .contextMenu {
                    templateContextMenu(for: template)
                }
            }
        }
    }
    
    // MARK: - Preview Panel
    
    private var previewPanel: some View {
        VStack(spacing: 0) {
            if let template = selectedTemplate {
                TemplateDetailPreviewView(
                    template: template,
                    templateManager: templateManager,
                    onEdit: {
                        editingTemplate = template
                        showingTemplateEditor = true
                    },
                    onEditCode: {
                        editingTemplate = template
                        showingCodeEditor = true
                    },
                    onDuplicate: {
                        templateManager.duplicateTemplate(template)
                    },
                    onDelete: {
                        templateManager.deleteTemplate(template)
                        selectedTemplate = nil
                    }
                )
            } else {
                ContentUnavailableView(
                    "No Template Selected",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select a template to see details and preview")
                )
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                showingNewTemplate = true
            } label: {
                Label("New Template", systemImage: "plus")
            }
            
            Button {
                showingImportDialog = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            
            Menu {
                Button {
                    showingCleanup = true
                } label: {
                    Label("Clean Up", systemImage: "trash")
                }
                
                Button {
                    showingBulkOperations = true
                } label: {
                    Label("Bulk Operations", systemImage: "square.stack.3d.up")
                }
                
                Button {
                    showingAnalytics = true
                } label: {
                    Label("Analytics", systemImage: "chart.bar")
                }
                
                Divider()
                
                Button {
                    refreshTemplates()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                
                Button {
                    forceReseed()
                } label: {
                    Label("Force Reseed (Debug)", systemImage: "arrow.triangle.2.circlepath")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func templateContextMenu(for template: TemplateModel) -> some View {
        Button {
            editingTemplate = template
            showingTemplateEditor = true
        } label: {
            Label("Edit Template", systemImage: "pencil")
        }
        
        Button {
            editingTemplate = template
            showingCodeEditor = true
        } label: {
            Label("Edit Code", systemImage: "chevron.left.forwardslash.chevron.right")
        }
        
        Divider()
        
        Button {
            templateManager.duplicateTemplate(template)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Button {
            exportTemplate(template)
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        
        if !template.isBuiltIn {
            Divider()
            
            Button(role: .destructive) {
                templateManager.deleteTemplate(template)
                if selectedTemplate?.id == template.id {
                    selectedTemplate = nil
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTemplates: [TemplateModel] {
        templateManager.filteredTemplates
    }
    
    private var sortedAndGroupedTemplates: [TemplateModel] {
        let sorted = sortTemplates(filteredTemplates)
        // Grouping would be handled by sections in a more complex implementation
        return sorted
    }
    
    // MARK: - Helper Methods
    
    private func sortTemplates(_ templates: [TemplateModel]) -> [TemplateModel] {
        switch sortOption {
        case .name:
            return templates.sorted { $0.name < $1.name }
        case .dateCreated:
            return templates.sorted { $0.createdAt > $1.createdAt }
        case .dateModified:
            return templates.sorted { $0.updatedAt > $1.updatedAt }
        case .rating:
            return templates.sorted { $0.averageRating > $1.averageRating }
        case .downloads:
            return templates.sorted { $0.downloadCount > $1.downloadCount }
        case .category:
            return templates.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }
    
    private func applySection() {
        switch selectedSection {
        case .all:
            templateManager.showBuiltInOnly = false
            templateManager.selectedCategory = nil
        case .featured:
            templateManager.showBuiltInOnly = false
            templateManager.selectedCategory = nil
            // Filter featured in computed property
        case .popular:
            templateManager.showBuiltInOnly = false
            templateManager.selectedCategory = nil
            sortOption = .downloads
        case .topRated:
            templateManager.showBuiltInOnly = false
            templateManager.selectedCategory = nil
            sortOption = .rating
        case .recent:
            templateManager.showBuiltInOnly = false
            templateManager.selectedCategory = nil
            // Filter recent in computed property
        case .myTemplates:
            templateManager.showBuiltInOnly = false
            templateManager.selectedCategory = nil
            // Filter user templates
        }
        templateManager.applyFilters()
    }
    
    private func refreshTemplates() {
        templateManager.loadTemplates()
    }
    
    private func forceReseed() {
        // Force reseed by calling seeder directly with forceReseed flag
        let context = templateManager.modelContext
        TemplateSeeder.shared.seedAllTemplates(into: context, forceReseed: true)
        
        // Reload
        templateManager.loadTemplates()
    }
    
    private func exportTemplate(_ template: TemplateModel) {
        do {
            let data = try templateManager.exportTemplate(template)
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "\(template.name).json"
            panel.allowedContentTypes = [.json]
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    try? data.write(to: url)
                }
            }
        } catch {
            print("Export failed: \(error)")
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
                print("Import failed: \(error)")
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct BrowserStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

struct BrowserTemplateCard: View {
    let template: TemplateModel
    let isSelected: Bool
    let isMultiSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            Image(systemName: template.icon)
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)
            
            // Name
            Text(template.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // Category
            Text(template.category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            
            // Rating
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", template.averageRating))
                    .font(.caption)
                Text("(\(template.reviewCount))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Downloads
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("\(template.downloadCount)")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            
            if template.isFeatured {
                Label("Featured", systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .overlay(
            isMultiSelected ?
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.blue)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            : nil
        )
    }
}

struct TemplateColumnCard: View {
    let template: TemplateModel
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(template.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if template.isFeatured {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Text(template.templateDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", template.averageRating))
                        .font(.caption2)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle")
                        .font(.caption2)
                    Text("\(template.downloadCount)")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TemplateListRow: View {
    let template: TemplateModel
    let isSelected: Bool
    let isMultiSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Image(systemName: isMultiSelected ? "checkmark.square.fill" : "square")
                .foregroundStyle(isMultiSelected ? .blue : .secondary)
            
            // Icon
            Image(systemName: template.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            // Name and description
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(template.templateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 250, alignment: .leading)
            
            // Category
            Text(template.category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            // Rating
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", template.averageRating))
                    .font(.caption)
            }
            .frame(width: 60, alignment: .leading)
            
            // Downloads
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle")
                    .font(.caption)
                Text("\(template.downloadCount)")
                    .font(.caption)
            }
            .frame(width: 80, alignment: .leading)
            
            // Date
            Text(template.updatedAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            // Featured badge
            if template.isFeatured {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

// Preview removed - requires model context
