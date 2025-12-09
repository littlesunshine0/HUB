//
//  ContentDetailViews.swift
//  Hub
//
//  Detail views for all content types with multiple view modes
//
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Unified Content Manager

@MainActor
public class HubContentManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var selectedContentType: HubContentType = .hub
    @Published public var selectedViewMode: ContentViewMode = .detail
    @Published public var searchQuery: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // Content counts
    @Published public var hubCount: Int = 0
    @Published public var templateCount: Int = 0
    @Published public var componentCount: Int = 0
    @Published public var moduleCount: Int = 0
    @Published public var blueprintCount: Int = 0
    @Published public var packageCount: Int = 0
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let userID: String
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext, userID: String) {
        self.modelContext = modelContext
        self.userID = userID
        refreshCounts()
    }
    
    // MARK: - Count Management
    
    public func refreshCounts() {
        Task {
            await loadCounts()
        }
    }
    
    private func loadCounts() async {
        isLoading = true
        defer { isLoading = false }
        
        // Hub count
        let hubDescriptor = FetchDescriptor<AppHub>(
            predicate: #Predicate { $0.userID == userID }
        )
        hubCount = (try? modelContext.fetchCount(hubDescriptor)) ?? 0
        
        // Template count
        let templateDescriptor = FetchDescriptor<TemplateModel>()
        templateCount = (try? modelContext.fetchCount(templateDescriptor)) ?? 0
        
        // Component, Module, Blueprint, Package counts from templates
        let templates = (try? modelContext.fetch(templateDescriptor)) ?? []
        componentCount = templates.filter { $0.name.contains("Component") }.count
        moduleCount = templates.filter { $0.name.contains("Module") }.count
        blueprintCount = templates.filter { $0.name.contains("Blueprint") }.count
        packageCount = templates.filter { $0.name.contains("Package") }.count
    }
    
    // MARK: - Hub CRUD
    
    func fetchHubs() -> [AppHub] {
        let descriptor = FetchDescriptor<AppHub>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func createHub(
        name: String,
        description: String,
        icon: String,
        category: HubCategory,
        templateID: UUID,
        templateName: String,
        customization: HubCustomization
    ) -> AppHub {
        let hub = AppHub(
            name: name,
            description: description,
            icon: icon,
            category: category,
            templateID: templateID,
            templateName: templateName,
            customization: customization,
            userID: userID
        )
        modelContext.insert(hub)
        saveContext()
        refreshCounts()
        return hub
    }
    
    func updateHub(_ hub: AppHub) {
        hub.updatedAt = Date()
        saveContext()
    }
    
    func deleteHub(_ hub: AppHub) {
        modelContext.delete(hub)
        saveContext()
        refreshCounts()
    }
    
    func duplicateHub(_ hub: AppHub) -> AppHub {
        let duplicate = AppHub(
            name: "\(hub.name) Copy",
            description: hub.details,
            icon: hub.icon,
            category: hub.category,
            templateID: hub.templateID,
            templateName: hub.templateName,
            customization: hub.customization,
            userID: userID
        )
        modelContext.insert(duplicate)
        saveContext()
        refreshCounts()
        return duplicate
    }
    
    // MARK: - Template CRUD
    
    func fetchTemplates(filter: String? = nil) -> [TemplateModel] {
        var descriptor = FetchDescriptor<TemplateModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        if let filter = filter, !filter.isEmpty {
            descriptor.predicate = #Predicate { template in
                template.name.localizedStandardContains(filter)
            }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchComponents() -> [TemplateModel] {
        let descriptor = FetchDescriptor<TemplateModel>(
            predicate: #Predicate { $0.name.contains("Component") },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchModules() -> [TemplateModel] {
        let descriptor = FetchDescriptor<TemplateModel>(
            predicate: #Predicate { $0.name.contains("Module") },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchBlueprints() -> [TemplateModel] {
        let descriptor = FetchDescriptor<TemplateModel>(
            predicate: #Predicate { $0.name.contains("Blueprint") },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchPackages() -> [TemplateModel] {
        let descriptor = FetchDescriptor<TemplateModel>(
            predicate: #Predicate { $0.name.contains("Package") },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func createTemplate(
        name: String,
        category: HubCategory,
        description: String,
        icon: String,
        sourceFiles: [String: String] = [:],
        features: [String] = []
    ) -> TemplateModel {
        let template = TemplateModel(
            name: name,
            category: category,
            description: description,
            icon: icon,
            sourceFiles: sourceFiles,
            features: features,
            dependencies: [],
            isBuiltIn: false,
            userID: userID
        )
        modelContext.insert(template)
        saveContext()
        refreshCounts()
        return template
    }
    
    func updateTemplate(_ template: TemplateModel) {
        template.updatedAt = Date()
        saveContext()
    }
    
    func deleteTemplate(_ template: TemplateModel) {
        modelContext.delete(template)
        saveContext()
        refreshCounts()
    }
    
    func duplicateTemplate(_ template: TemplateModel) -> TemplateModel {
        let duplicate = TemplateModel(
            name: "\(template.name) Copy",
            category: template.category,
            description: template.templateDescription,
            icon: template.icon,
            sourceFiles: template.sourceFiles,
            features: template.features,
            dependencies: template.dependencies,
            isBuiltIn: false,
            userID: userID
        )
        modelContext.insert(duplicate)
        saveContext()
        refreshCounts()
        return duplicate
    }
    
    // MARK: - Search
    
    func search(query: String, contentType: HubContentType? = nil) -> [any ContentItem] {
        guard !query.isEmpty else { return [] }
        
        var results: [any ContentItem] = []
        
        let types = contentType.map { [$0] } ?? HubContentType.allCases
        
        for type in types {
            switch type {
            case .hub:
                let hubs = fetchHubs().filter {
                    $0.name.localizedCaseInsensitiveContains(query) ||
                    $0.details.localizedCaseInsensitiveContains(query)
                }
                // Note: AppHub would need to conform to ContentItem
                
            case .template, .component, .module, .blueprint, .package:
                let templates = fetchTemplates(filter: query)
                // Note: TemplateModel would need to conform to ContentItem
                break
            }
        }
        
        return results
    }
    
    // MARK: - Helpers
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    public func getCount(for type: HubContentType) -> Int {
        switch type {
        case .hub: return hubCount
        case .template: return templateCount
        case .component: return componentCount
        case .module: return moduleCount
        case .blueprint: return blueprintCount
        case .package: return packageCount
        }
    }
}

// MARK: - Content Detail Container

struct ContentDetailContainer: View {
    let itemID: UUID
    let contentType: HubContentType
    let viewMode: ContentViewMode
    @ObservedObject var contentManager: HubContentManager
    
    var body: some View {
        Group {
            switch viewMode {
            // Display modes - show detail view
            case .gallery, .icon, .column, .list, .table:
                DetailModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            
            // Detail modes
            case .detail:
                DetailModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .edit:
                EditModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .live:
                LiveModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .preview:
                PreviewModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .quick:
                QuickModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            
            // File modes
            case .folder:
                FolderModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .file:
                FileModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .project:
                ProjectModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .package:
                PackageModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            
            // Advanced modes
            case .dragDrop:
                DragDropModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .liveRender:
                LiveRenderModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            case .parser:
                ParserModeView(itemID: itemID, contentType: contentType, contentManager: contentManager)
            }
        }
    }
}

// MARK: - Detail Mode View

struct DetailModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var hubs: [AppHub]
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch contentType {
                case .hub:
                    if let hub = hubs.first(where: { $0.id == itemID }) {
                        HubDetailContent(hub: hub, contentManager: contentManager)
                    }
                case .template, .component, .module, .blueprint, .package:
                    if let template = templates.first(where: { $0.id == itemID }) {
                        TemplateDetailContent(template: template, contentManager: contentManager)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detail View")
    }
}

struct HubDetailContent: View {
    let hub: AppHub
    @ObservedObject var contentManager: HubContentManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: hub.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(hub.name)
                        .font(.title)
                        .bold()
                    
                    Label(hub.category.rawValue, systemImage: hub.category.icon)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        if hub.isPublished {
                            Label("Published", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                        
                        Text("Updated \(hub.updatedAt, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(hub.details)
                    .foregroundStyle(.secondary)
            }
            
            // Customization
            if let customization = hub.customization {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Customization")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InfoCard(title: "App Name", value: customization.appName, icon: "app")
                        InfoCard(title: "Bundle ID", value: customization.bundleIdentifier, icon: "number")
                        
                        HStack {
                            Circle()
                                .fill(Color(hex: customization.primaryColor))
                                .frame(width: 20, height: 20)
                            Text("Primary: \(customization.primaryColor)")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        HStack {
                            Circle()
                                .fill(Color(hex: customization.accentColor))
                                .frame(width: 20, height: 20)
                            Text("Accent: \(customization.accentColor)")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    // Build action
                } label: {
                    Label("Build", systemImage: "hammer.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    // Launch action
                } label: {
                    Label("Launch", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(hub.builtAppPath == nil)
                
                Button {
                    // Export action
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct TemplateDetailContent: View {
    let template: TemplateModel
    @ObservedObject var contentManager: HubContentManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: template.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.title)
                        .bold()
                    
                    Label(template.category.rawValue, systemImage: template.category.icon)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        if template.isFeatured {
                            Label("Featured", systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                        
                        if template.isPremium {
                            Label("Premium", systemImage: "crown.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(template.templateDescription)
                    .foregroundStyle(.secondary)
            }
            
            // Features
            if !template.features.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                        ForEach(template.features, id: \.self) { feature in
                            Label(feature, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Source Code Preview
            if !template.sourceFiles.values.joined(separator: "\n\n").isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Source Code")
                            .font(.headline)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(template.sourceFiles.values.joined(separator: "\n\n"), forType: .string)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(template.sourceFiles.values.joined(separator: "\n\n").prefix(500) + (template.sourceFiles.values.joined(separator: "\n\n").count > 500 ? "..." : ""))
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    // Use template
                } label: {
                    Label("Use Template", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    _ = contentManager.duplicateTemplate(template)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Edit Mode View

struct EditModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var hubs: [AppHub]
    @Query private var templates: [TemplateModel]
    
    @State private var editedName: String = ""
    @State private var editedDescription: String = ""
    @State private var editedIcon: String = ""
    @State private var hasChanges: Bool = false
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Name", text: $editedName)
                    .onChange(of: editedName) { _ in
                        hasChanges = true
                    }
                
                TextEditor(text: $editedDescription)
                    .frame(minHeight: 100)
                    .onChange(of: editedDescription) { _ in
                        hasChanges = true
                    }
                
                HStack {
                    Image(systemName: editedIcon)
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    TextField("Icon Name", text: $editedIcon)
                        .onChange(of: editedIcon) { _ in
                            hasChanges = true
                        }
                }
            }
            
            Section {
                HStack {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasChanges)
                    
                    Button("Discard") {
                        loadCurrentValues()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasChanges)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Mode")
        .onAppear {
            loadCurrentValues()
        }
    }
    
    private func loadCurrentValues() {
        switch contentType {
        case .hub:
            if let hub = hubs.first(where: { $0.id == itemID }) {
                editedName = hub.name
                editedDescription = hub.details
                editedIcon = hub.icon
            }
        default:
            if let template = templates.first(where: { $0.id == itemID }) {
                editedName = template.name
                editedDescription = template.templateDescription
                editedIcon = template.icon
            }
        }
        hasChanges = false
    }
    
    private func saveChanges() {
        switch contentType {
        case .hub:
            if let hub = hubs.first(where: { $0.id == itemID }) {
                hub.name = editedName
                hub.details = editedDescription
                hub.icon = editedIcon
                contentManager.updateHub(hub)
            }
        default:
            if let template = templates.first(where: { $0.id == itemID }) {
                template.name = editedName
                template.templateDescription = editedDescription
                template.icon = editedIcon
                contentManager.updateTemplate(template)
            }
        }
        hasChanges = false
    }
}

// MARK: - Live Mode View

struct LiveModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var hubs: [AppHub]
    
    var body: some View {
        VStack {
            if contentType == .hub, let hub = hubs.first(where: { $0.id == itemID }) {
                if hub.builtAppPath != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                        
                        Text("App is ready to launch")
                            .font(.title2)
                        
                        Button {
                            // Launch app
                        } label: {
                            Label("Launch \(hub.name)", systemImage: "play.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "hammer.circle")
                            .font(.system(size: 80))
                            .foregroundStyle(.orange)
                        
                        Text("App needs to be built first")
                            .font(.title2)
                        
                        Button {
                            // Build app
                        } label: {
                            Label("Build \(hub.name)", systemImage: "hammer.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            } else {
                Text("Live mode is only available for Hubs")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Live Mode")
    }
}

// MARK: - Preview Mode View

struct PreviewModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        VStack {
            if let template = templates.first(where: { $0.id == itemID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview: \(template.name)")
                            .font(.title2)
                            .bold()
                        
                        if !template.sourceFiles.values.joined(separator: "\n\n").isEmpty {
                            Text(template.sourceFiles.values.joined(separator: "\n\n"))
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text("No source code available for preview")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Select a template to preview")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Preview Mode")
    }
}

// MARK: - Quick Mode View

struct QuickModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var hubs: [AppHub]
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        VStack(spacing: 16) {
            // Quick actions grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                ContentQuickActionButton(title: "Edit", icon: "pencil", color: .blue) {
                    // Edit action
                }
                
                ContentQuickActionButton(title: "Duplicate", icon: "doc.on.doc", color: .green) {
                    // Duplicate action
                }
                
                ContentQuickActionButton(title: "Export", icon: "square.and.arrow.up", color: .orange) {
                    // Export action
                }
                
                ContentQuickActionButton(title: "Share", icon: "square.and.arrow.up.on.square", color: .purple) {
                    // Share action
                }
                
                if contentType == .hub {
                    ContentQuickActionButton(title: "Build", icon: "hammer", color: .blue) {
                        // Build action
                    }
                    
                    ContentQuickActionButton(title: "Launch", icon: "play", color: .green) {
                        // Launch action
                    }
                }
                
                ContentQuickActionButton(title: "Delete", icon: "trash", color: .red) {
                    // Delete action
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Quick Actions")
    }
}

struct ContentQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 100, height: 80)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Folder Mode View

struct FolderModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let template = templates.first(where: { $0.id == itemID }) {
                Text("Files in \(template.name)")
                    .font(.title2)
                    .bold()
                
                List {
                    ForEach(template.sourceFiles.keys.sorted(), id: \.self) { filename in
                        HStack {
                            Image(systemName: fileIcon(for: filename))
                                .foregroundStyle(.blue)
                            Text(filename)
                            Spacer()
                            Text("\(template.sourceFiles[filename]?.count ?? 0) chars")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No files available")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Folder View")
    }
    
    private func fileIcon(for filename: String) -> String {
        if filename.hasSuffix(".swift") { return "swift" }
        if filename.hasSuffix(".json") { return "curlybraces" }
        if filename.hasSuffix(".md") { return "doc.text" }
        return "doc"
    }
}

// MARK: - File Mode View

struct FileModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    @State private var selectedFile: String?
    
    var body: some View {
        HSplitView {
            // File list
            List(selection: $selectedFile) {
                if let template = templates.first(where: { $0.id == itemID }) {
                    ForEach(template.sourceFiles.keys.sorted(), id: \.self) { filename in
                        Text(filename)
                            .tag(filename)
                    }
                }
            }
            .frame(minWidth: 200)
            
            // File content
            if let template = templates.first(where: { $0.id == itemID }),
               let filename = selectedFile,
               let content = template.sourceFiles[filename] {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Select a file to view")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("File View")
    }
}

// MARK: - Drag Drop Mode View

struct DragDropModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.draw")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("Drag & Drop Editor")
                .font(.title2)
            
            Text("Visual component arrangement coming soon")
                .foregroundStyle(.secondary)
            
            // Placeholder for drag-drop interface
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(.secondary)
                .frame(height: 300)
                .overlay {
                    Text("Drop components here")
                        .foregroundStyle(.secondary)
                }
        }
        .padding()
        .navigationTitle("Drag & Drop")
    }
}

// MARK: - Live Render Mode View

struct LiveRenderModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        HSplitView {
            // Code editor
            VStack(alignment: .leading) {
                Text("Source Code")
                    .font(.headline)
                
                if let template = templates.first(where: { $0.id == itemID }) {
                    ScrollView {
                        Text(template.sourceFiles.values.joined(separator: "\n\n"))
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .frame(minWidth: 300)
            
            // Live preview
            VStack(alignment: .leading) {
                Text("Live Preview")
                    .font(.headline)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay {
                        VStack {
                            Image(systemName: "wand.and.stars")
                                .font(.largeTitle)
                                .foregroundStyle(.purple)
                            Text("Live rendering preview")
                                .foregroundStyle(.secondary)
                        }
                    }
            }
            .padding()
        }
        .navigationTitle("Live Render")
    }
}

// MARK: - Parser Mode View

struct ParserModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Code Parser")
                .font(.title2)
                .bold()
            
            if let template = templates.first(where: { $0.id == itemID }) {
                HStack(alignment: .top, spacing: 16) {
                    // Source
                    VStack(alignment: .leading) {
                        Text("Source")
                            .font(.headline)
                        ScrollView {
                            Text(template.sourceFiles.values.joined(separator: "\n\n").prefix(1000))
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Parsed output
                    VStack(alignment: .leading) {
                        Text("Parsed Structure")
                            .font(.headline)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ParserOutputRow(label: "Type", value: contentType.rawValue)
                                ParserOutputRow(label: "Name", value: template.name)
                                ParserOutputRow(label: "Category", value: template.category.rawValue)
                                ParserOutputRow(label: "Features", value: "\(template.features.count)")
                                ParserOutputRow(label: "Dependencies", value: "\(template.dependencies.count)")
                                ParserOutputRow(label: "Lines of Code", value: "\(template.sourceFiles.values.joined(separator: "\n\n").components(separatedBy: "\n").count)")
                            }
                            .padding()
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Parser View")
    }
}

struct ParserOutputRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}


// MARK: - Project Mode View

struct ProjectModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let template = templates.first(where: { $0.id == itemID }) {
                // Project header
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.title2)
                            .bold()
                        Text("Project Structure")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Project tree
                List {
                    DisclosureGroup("Source Files") {
                        ForEach(template.sourceFiles.keys.sorted(), id: \.self) { filename in
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.blue)
                                Text(filename)
                                Spacer()
                                Text("\(template.sourceFiles[filename]?.count ?? 0) chars")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    DisclosureGroup("Features (\(template.features.count))") {
                        ForEach(template.features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(feature)
                            }
                        }
                    }
                    
                    DisclosureGroup("Dependencies (\(template.dependencies.count))") {
                        ForEach(template.dependencies, id: \.self) { dep in
                            HStack {
                                Image(systemName: "link")
                                    .foregroundStyle(.orange)
                                Text(dep)
                            }
                        }
                    }
                }
            } else {
                Text("Select a template to view project structure")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("Project View")
    }
}

// MARK: - Package Mode View

struct PackageModeView: View {
    let itemID: UUID
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Query private var templates: [TemplateModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let template = templates.first(where: { $0.id == itemID }) {
                // Package header
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.title2)
                            .bold()
                        Text("Package Contents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("v\(template.version)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text("by \(template.author)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Package info grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    PackageInfoCard(title: "Category", value: template.category.rawValue, icon: "folder")
                    PackageInfoCard(title: "Files", value: "\(template.sourceFiles.count)", icon: "doc.text")
                    PackageInfoCard(title: "Features", value: "\(template.features.count)", icon: "star")
                    PackageInfoCard(title: "Dependencies", value: "\(template.dependencies.count)", icon: "link")
                }
                
                // Tags
                if !template.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                        
                        ContentFlowLayout(spacing: 8) {
                            ForEach(template.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack {
                    Button {
                        // Install package
                    } label: {
                        Label("Install", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        // View source
                    } label: {
                        Label("View Source", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("Select a package to view contents")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("Package View")
    }
}

struct PackageInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Simple flow layout for tags
struct ContentFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
