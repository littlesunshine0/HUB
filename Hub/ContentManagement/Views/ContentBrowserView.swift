//
//  ContentBrowserView.swift
//  Hub
//
//  Main browser for all content types with multiple view modes
//

import SwiftUI
import SwiftData

struct TemplateRowView: View {
    let template: TemplateModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                
                Text(template.templateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(template.category.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}
// MARK: - Component List View

struct ComponentListView: View {
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private var components: [TemplateModel] {
        let all = contentManager.fetchComponents()
        if searchText.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(components, selection: $selectedID) { component in
            TemplateRowView(template: component)
                .tag(component.id)
        }
        .navigationTitle("Components")
    }
}

// MARK: - Module List View

struct ModuleListView: View {
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private var modules: [TemplateModel] {
        let all = contentManager.fetchModules()
        if searchText.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(modules, selection: $selectedID) { module in
            TemplateRowView(template: module)
                .tag(module.id)
        }
        .navigationTitle("Modules")
    }
}

// MARK: - Blueprint List View

struct BlueprintListView: View {
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private var blueprints: [TemplateModel] {
        let all = contentManager.fetchBlueprints()
        if searchText.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(blueprints, selection: $selectedID) { blueprint in
            TemplateRowView(template: blueprint)
                .tag(blueprint.id)
        }
        .navigationTitle("Blueprints")
    }
}

// MARK: - Package List View

struct PackageListView: View {
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private var packages: [TemplateModel] {
        let all = contentManager.fetchPackages()
        if searchText.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(packages, selection: $selectedID) { package in
            TemplateRowView(template: package)
                .tag(package.id)
        }
        .navigationTitle("Packages")
    }
}

// MARK: - Content Browser View

struct ContentBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var contentManager: HubContentManager
    
    @State private var selectedContentType: HubContentType = .hub
    @State private var selectedViewMode: ContentViewMode = .gallery
    @State private var searchText: String = ""
    @State private var selectedItemID: UUID?
    @State private var showingCreateSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    init(userID: String, modelContext: ModelContext) {
        _contentManager = StateObject(wrappedValue: HubContentManager(modelContext: modelContext, userID: userID))
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            contentArea
        } detail: {
            detailView
        }
        .searchable(text: $searchText, prompt: "Search \(selectedContentType.pluralName)")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateContentSheet(
                contentType: selectedContentType,
                contentManager: contentManager
            )
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedContentType) {
            Section("Content Types") {
                ForEach(HubContentType.allCases) { type in
                    Label {
                        HStack {
                            Text(type.pluralName)
                            Spacer()
                            Text("\(contentManager.getCount(for: type))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    } icon: {
                        Image(systemName: type.icon)
                            .foregroundStyle(type.color)
                    }
                    .tag(type)
                }
            }
            
            Section("Display") {
                ForEach(ContentViewMode.allCases.filter { $0.isDisplayMode }) { mode in
                    viewModeButton(mode)
                }
            }
            
            Section("Detail Views") {
                ForEach([ContentViewMode.detail, .edit, .live, .preview, .quick]) { mode in
                    viewModeButton(mode)
                }
            }
            
            Section("File Views") {
                ForEach([ContentViewMode.folder, .file, .project, .package]) { mode in
                    viewModeButton(mode)
                }
            }
            
            Section("Advanced") {
                ForEach([ContentViewMode.dragDrop, .liveRender, .parser]) { mode in
                    viewModeButton(mode)
                }
            }
        }
        .navigationTitle("Content")
        .listStyle(.sidebar)
    }
    
    private func viewModeButton(_ mode: ContentViewMode) -> some View {
        Button {
            selectedViewMode = mode
        } label: {
            Label(mode.rawValue, systemImage: mode.icon)
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedViewMode == mode ? .blue : .primary)
    }
    
    // MARK: - Content Area (Display Modes)
    
    @ViewBuilder
    private var contentArea: some View {
        if selectedViewMode.isDisplayMode {
            displayModeContent
        } else {
            // For non-display modes, show list and detail in split
            contentList
        }
    }
    
    @ViewBuilder
    private var displayModeContent: some View {
        switch selectedViewMode {
        case .gallery:
            GalleryDisplayView(
                contentType: selectedContentType,
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .icon:
            IconDisplayView(
                contentType: selectedContentType,
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .column:
            ColumnDisplayView(
                contentType: selectedContentType,
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .list:
            ListDisplayView(
                contentType: selectedContentType,
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .table:
            TableDisplayView(
                contentType: selectedContentType,
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        default:
            contentList
        }
    }
    
    // MARK: - Content List (for non-display modes)
    
    @ViewBuilder
    private var contentList: some View {
        switch selectedContentType {
        case .hub:
            HubListView(
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .template:
            TemplateListView(
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .component:
            ComponentListView(
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .module:
            ModuleListView(
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .blueprint:
            BlueprintListView(
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        case .package:
            PackageListView(
                contentManager: contentManager,
                searchText: searchText,
                selectedID: $selectedItemID
            )
        }
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        if let itemID = selectedItemID {
            ContentDetailContainer(
                itemID: itemID,
                contentType: selectedContentType,
                viewMode: selectedViewMode,
                contentManager: contentManager
            )
        } else {
            ContentPlaceholder(contentType: selectedContentType)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingCreateSheet = true
            } label: {
                Label("New \(selectedContentType.rawValue)", systemImage: "plus")
            }
        }
        
        ToolbarItem(placement: .automatic) {
            Picker("View", selection: $selectedViewMode) {
                ForEach(ContentViewMode.allCases.filter { $0.isDisplayMode }) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        
        ToolbarItem(placement: .automatic) {
            Button {
                contentManager.refreshCounts()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Gallery Display View

struct GalleryDisplayView: View {
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    @Query private var hubs: [AppHub]
    @Query private var templates: [TemplateModel]
    
    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 300))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                switch contentType {
                case .hub:
                    ForEach(filteredHubs) { hub in
                        ContentGalleryCard(
                            title: hub.name,
                            subtitle: hub.category.rawValue,
                            icon: hub.icon,
                            color: .purple,
                            isSelected: selectedID == hub.id
                        ) {
                            selectedID = hub.id
                        }
                    }
                default:
                    ForEach(filteredTemplates) { template in
                        ContentGalleryCard(
                            title: template.name,
                            subtitle: template.category.rawValue,
                            icon: template.icon,
                            color: contentType.color,
                            isSelected: selectedID == template.id
                        ) {
                            selectedID = template.id
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(contentType.pluralName) - Gallery")
    }
    
    private var filteredHubs: [AppHub] {
        let all = contentManager.fetchHubs()
        if searchText.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredTemplates: [TemplateModel] {
        contentManager.fetchTemplates(filter: searchText.isEmpty ? nil : searchText)
    }
}

struct ContentGalleryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(color)
                    .frame(width: 80, height: 80)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Display View

struct IconDisplayView: View {
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private let columns = [GridItem(.adaptive(minimum: 80, maximum: 100))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                switch contentType {
                case .hub:
                    ForEach(contentManager.fetchHubs().filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }) { hub in
                        IconItem(
                            name: hub.name,
                            icon: hub.icon,
                            color: .purple,
                            isSelected: selectedID == hub.id
                        ) {
                            selectedID = hub.id
                        }
                    }
                default:
                    ForEach(contentManager.fetchTemplates(filter: searchText.isEmpty ? nil : searchText)) { template in
                        IconItem(
                            name: template.name,
                            icon: template.icon,
                            color: contentType.color,
                            isSelected: selectedID == template.id
                        ) {
                            selectedID = template.id
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(contentType.pluralName) - Icons")
    }
}

struct IconItem: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? color.opacity(0.2) : color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Column Display View

struct ColumnDisplayView: View {
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    var body: some View {
        HStack(spacing: 0) {
            // Categories column
            List {
                ForEach(HubCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .font(.headline)
                }
            }
            .frame(width: 200)
            
            Divider()
            
            // Items column
            List {
                switch contentType {
                case .hub:
                    ForEach(contentManager.fetchHubs().filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }) { hub in
                        HStack {
                            Image(systemName: hub.icon)
                            Text(hub.name)
                        }
                        .tag(hub.id)
                    }
                default:
                    ForEach(contentManager.fetchTemplates(filter: searchText.isEmpty ? nil : searchText)) { template in
                        HStack {
                            Image(systemName: template.icon)
                            Text(template.name)
                        }
                        .tag(template.id)
                    }
                }
            }
        }
        .navigationTitle("\(contentType.pluralName) - Columns")
    }
}

// MARK: - List Display View

struct ListDisplayView: View {
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    var body: some View {
        List(selection: $selectedID) {
            switch contentType {
            case .hub:
                ForEach(contentManager.fetchHubs().filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }) { hub in
                    HStack(spacing: 12) {
                        Image(systemName: hub.icon)
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(hub.name)
                                .font(.headline)
                            Text(hub.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(hub.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .tag(hub.id)
                }
            default:
                ForEach(contentManager.fetchTemplates(filter: searchText.isEmpty ? nil : searchText)) { template in
                    HStack(spacing: 12) {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .foregroundStyle(contentType.color)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(template.name)
                                .font(.headline)
                            Text(template.templateDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(template.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .tag(template.id)
                }
            }
        }
        .navigationTitle("\(contentType.pluralName) - List")
    }
}

// MARK: - Table Display View

struct TableDisplayView: View {
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    var body: some View {
        Table(of: TableItem.self, selection: $selectedID) {
            TableColumn("Icon") { item in
                Image(systemName: item.icon)
                    .foregroundStyle(contentType.color)
            }
            .width(40)
            
            TableColumn("Name", value: \.name)
            
            TableColumn("Category", value: \.category)
                .width(120)
            
            TableColumn("Updated") { item in
                Text(item.updatedAt, style: .date)
            }
            .width(100)
        } rows: {
            ForEach(tableItems) { item in
                TableRow(item)
            }
        }
        .navigationTitle("\(contentType.pluralName) - Table")
    }
    
    private var tableItems: [TableItem] {
        switch contentType {
        case .hub:
            return contentManager.fetchHubs()
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .map { TableItem(id: $0.id, name: $0.name, icon: $0.icon, category: $0.category.rawValue, updatedAt: $0.updatedAt) }
        default:
            return contentManager.fetchTemplates(filter: searchText.isEmpty ? nil : searchText)
                .map { TableItem(id: $0.id, name: $0.name, icon: $0.icon, category: $0.category.rawValue, updatedAt: $0.updatedAt) }
        }
    }
}

struct TableItem: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let category: String
    let updatedAt: Date
}

// MARK: - Content Placeholder

struct ContentPlaceholder: View {
    let contentType: HubContentType
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: contentType.icon)
                .font(.system(size: 64))
                .foregroundStyle(contentType.color.opacity(0.5))
            
            Text("Select a \(contentType.rawValue.lowercased())")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Choose an item from the list to view details")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
