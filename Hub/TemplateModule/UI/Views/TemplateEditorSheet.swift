import SwiftUI

/// Template metadata editor sheet
struct TemplateEditorSheet: View {
    let template: TemplateModel
    let templateManager: TemplateManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var icon: String
    @State private var category: HubCategory
    @State private var author: String
    @State private var version: String
    @State private var tags: String
    @State private var isFeatured: Bool
    @State private var isVisualTemplate: Bool
    
    init(template: TemplateModel, templateManager: TemplateManager) {
        self.template = template
        self.templateManager = templateManager
        _name = State(initialValue: template.name)
        _description = State(initialValue: template.templateDescription)
        _icon = State(initialValue: template.icon)
        _category = State(initialValue: template.category)
        _author = State(initialValue: template.author)
        _version = State(initialValue: template.version)
        _tags = State(initialValue: template.tags.joined(separator: ", "))
        _isFeatured = State(initialValue: template.isFeatured)
        _isVisualTemplate = State(initialValue: template.isVisualTemplate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        TextField("Icon (SF Symbol)", text: $icon)
                        Image(systemName: icon)
                            .foregroundStyle(.blue)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(HubCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
                
                Section("Metadata") {
                    TextField("Author", text: $author)
                    TextField("Version", text: $version)
                    TextField("Tags (comma-separated)", text: $tags)
                }
                
                Section("Options") {
                    Toggle("Featured Template", isOn: $isFeatured)
                    Toggle("Visual Template", isOn: $isVisualTemplate)
                }
                
                Section("Statistics") {
                    LabeledContent("Downloads", value: "\(template.downloadCount)")
                    LabeledContent("Views", value: "\(template.viewCount)")
                    LabeledContent("Rating", value: String(format: "%.1f", template.averageRating))
                    LabeledContent("Reviews", value: "\(template.reviewCount)")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    private func saveChanges() {
        template.name = name
        template.templateDescription = description
        template.icon = icon
        template.category = category
        template.author = author
        template.version = version
        template.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        template.isFeatured = isFeatured
        template.isVisualTemplate = isVisualTemplate
        
        templateManager.updateTemplate(template)
    }
}

/// New template creation sheet
struct NewTemplateSheet: View {
    let templateManager: TemplateManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var icon = "doc.fill"
    @State private var category: HubCategory = .utilities
    @State private var templateType: TemplateType = .code
    
    enum TemplateType: String, CaseIterable {
        case code = "Code-Based"
        case visual = "Visual"
        
        var description: String {
            switch self {
            case .code: return "Create a template with Swift code"
            case .visual: return "Create a template with visual editor"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Information") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        TextField("Icon (SF Symbol)", text: $icon)
                        Image(systemName: icon)
                            .foregroundStyle(.blue)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(HubCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
                
                Section("Template Type") {
                    Picker("Type", selection: $templateType) {
                        ForEach(TemplateType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(templateType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTemplate()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func createTemplate() {
        let template = TemplateModel(
            name: name,
            category: category,
            description: description,
            icon: icon,
            author: "User",
            version: "1.0.0",
            sourceFiles: templateType == .code ? ["ContentView.swift": "// New template\n"] : [:],
            isBuiltIn: false,
            isVisualTemplate: templateType == .visual
        )
        
        templateManager.createTemplate(template)
    }
}

// Preview removed - requires model context
