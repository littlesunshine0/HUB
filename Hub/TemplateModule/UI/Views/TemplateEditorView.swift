import SwiftUI

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var templateManager: TemplateManager
    
    let template: TemplateModel?
    
    @State private var name: String
    @State private var templateDescription: String
    @State private var icon: String
    @State private var category: HubCategory
    @State private var author: String
    @State private var version: String
    @State private var features: [String]
    @State private var dependencies: [String]
    @State private var tags: [String]
    @State private var sourceFiles: [String: String]
    @State private var sharedModules: [String]
    @State private var featureToggles: [String: Bool]
    @State private var visualLayout: [RenderableComponent]
    @State private var visualScreens: [VisualScreen]
    @State private var branding: TemplateBranding
    @State private var isVisualTemplate: Bool
    
    @State private var newFeature = ""
    @State private var newDependency = ""
    @State private var newTag = ""
    @State private var selectedFileName = "main.swift"
    @State private var newFileName = ""
    @State private var showingAddFile = false
    @State private var editorMode: EditorMode = .code
    
    enum EditorMode {
        case code
        case visual
    }
    
    init(templateManager: TemplateManager, template: TemplateModel?) {
        self.templateManager = templateManager
        self.template = template
        
        // Initialize state from template or defaults
        _name = State(initialValue: template?.name ?? "")
        _templateDescription = State(initialValue: template?.templateDescription ?? "")
        _icon = State(initialValue: template?.icon ?? "doc.fill")
        _category = State(initialValue: template?.category ?? .development)
        _author = State(initialValue: template?.author ?? "")
        _version = State(initialValue: template?.version ?? "1.0.0")
        _features = State(initialValue: template?.features ?? [])
        _dependencies = State(initialValue: template?.dependencies ?? [])
        _tags = State(initialValue: template?.tags ?? [])
        _sourceFiles = State(initialValue: template?.sourceFiles ?? ["main.swift": TemplateEditorView.defaultMainSwift])
        _sharedModules = State(initialValue: template?.sharedModules ?? [])
        _featureToggles = State(initialValue: template?.featureToggles ?? [:])
        _visualLayout = State(initialValue: template?.visualLayout ?? [])
        _visualScreens = State(initialValue: template?.visualScreens ?? [])
        _branding = State(initialValue: template?.branding ?? .default)
        _isVisualTemplate = State(initialValue: template?.isVisualTemplate ?? false)
        _editorMode = State(initialValue: (template?.isVisualTemplate ?? false) ? .visual : .code)
    }
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // Left panel - Metadata
                Form {
                    Section("Basic Info") {
                        TextField("Template Name", text: $name)
                        TextField("Description", text: $templateDescription, axis: .vertical)
                            .lineLimit(3...6)
                        
                        HStack {
                            TextField("Icon", text: $icon)
                            Image(systemName: icon)
                                .font(.title2)
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
                    }
                    
                    Section("Features") {
                        ForEach(features, id: \.self) { feature in
                            HStack {
                                Text(feature)
                                Spacer()
                                Button {
                                    features.removeAll { $0 == feature }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack {
                            TextField("Add feature", text: $newFeature)
                            Button {
                                if !newFeature.isEmpty {
                                    features.append(newFeature)
                                    newFeature = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newFeature.isEmpty)
                        }
                    }
                    
                    Section("Dependencies") {
                        ForEach(dependencies, id: \.self) { dependency in
                            HStack {
                                Text(dependency)
                                Spacer()
                                Button {
                                    dependencies.removeAll { $0 == dependency }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack {
                            TextField("Add framework", text: $newDependency)
                            Button {
                                if !newDependency.isEmpty {
                                    dependencies.append(newDependency)
                                    newDependency = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newDependency.isEmpty)
                        }
                    }
                    
                    Section("Tags") {
                        TemplateFlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                        
                        HStack {
                            TextField("Add tag", text: $newTag)
                            Button {
                                if !newTag.isEmpty {
                                    tags.append(newTag.lowercased())
                                    newTag = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newTag.isEmpty)
                        }
                    }
                    
                    Section("Shared Modules") {
                        Text("Add reusable components to your template")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(SharedModuleLibrary.shared.allModules) { module in
                            Toggle(isOn: Binding(
                                get: { sharedModules.contains(module.id) },
                                set: { isOn in
                                    if isOn {
                                        sharedModules.append(module.id)
                                    } else {
                                        sharedModules.removeAll { $0 == module.id }
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.name)
                                        .font(.body)
                                    Text(module.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !module.dependencies.isEmpty {
                                        Text("Requires: \(module.dependencies.joined(separator: ", "))")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Feature Toggles") {
                        Text("Enable/disable features at build time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Toggle("Authentication", isOn: Binding(
                            get: { featureToggles["Auth"] ?? false },
                            set: { featureToggles["Auth"] = $0 }
                        ))
                        
                        Toggle("Analytics", isOn: Binding(
                            get: { featureToggles["Analytics"] ?? false },
                            set: { featureToggles["Analytics"] = $0 }
                        ))
                        
                        Toggle("Notifications", isOn: Binding(
                            get: { featureToggles["Notifications"] ?? false },
                            set: { featureToggles["Notifications"] = $0 }
                        ))
                        
                        Toggle("In-App Purchases", isOn: Binding(
                            get: { featureToggles["IAP"] ?? false },
                            set: { featureToggles["IAP"] = $0 }
                        ))
                    }
                }
                .formStyle(.grouped)
                .frame(minWidth: 300, maxWidth: 400)
                
                // Right panel - Editor (Code or Visual)
                VStack(alignment: .leading, spacing: 0) {
                    // Mode selector
                    HStack {
                        Picker("Editor Mode", selection: $editorMode) {
                            Text("Code Editor").tag(EditorMode.code)
                            Text("Visual Editor").tag(EditorMode.visual)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 250)
                        
                        Spacer()
                        
                        if editorMode == .code {
                            Button {
                                showingAddFile = true
                            } label: {
                                Label("Add File", systemImage: "plus")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    Divider()
                    
                    // Editor content
                    if editorMode == .code {
                        VStack(spacing: 0) {
                            // File tabs
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(Array(sourceFiles.keys.sorted()), id: \.self) { filename in
                                        Button {
                                            selectedFileName = filename
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(filename)
                                                    .font(.caption)
                                                
                                                if sourceFiles.count > 1 {
                                                    Button {
                                                        sourceFiles.removeValue(forKey: filename)
                                                        if selectedFileName == filename {
                                                            selectedFileName = sourceFiles.keys.first ?? ""
                                                        }
                                                    } label: {
                                                        Image(systemName: "xmark")
                                                            .font(.caption2)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedFileName == filename ? Color.accentColor.opacity(0.2) : Color.clear)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .windowBackgroundColor))
                            
                            Divider()
                            
                            // Code editor
                            TextEditor(text: Binding(
                                get: { sourceFiles[selectedFileName] ?? "" },
                                set: { sourceFiles[selectedFileName] = $0 }
                            ))
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                        }
                    } else {
                        // Multi-screen visual editor
                        MultiScreenVisualEditor(screens: $visualScreens, branding: $branding)
                    }
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if template != nil && isVisualTemplate {
                        Menu {
                            Button("Save") {
                                saveTemplate()
                            }
                            .disabled(!isValid)
                            
                            Divider()
                            
                            Menu("Create Variant") {
                                ForEach(DesignSystem.allCases, id: \.self) { system in
                                    Menu(system.rawValue) {
                                        ForEach(ColorSchemeVariant.allCases, id: \.self) { scheme in
                                            Button("\(scheme.rawValue)") {
                                                createVariant(designSystem: system, colorScheme: scheme)
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Save", systemImage: "chevron.down")
                        }
                    } else {
                        Button("Save") {
                            saveTemplate()
                        }
                        .disabled(!isValid)
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .alert("Add File", isPresented: $showingAddFile) {
            TextField("Filename", text: $newFileName)
            Button("Cancel", role: .cancel) {
                newFileName = ""
            }
            Button("Add") {
                if !newFileName.isEmpty && !sourceFiles.keys.contains(newFileName) {
                    sourceFiles[newFileName] = "// \(newFileName)\n\n"
                    selectedFileName = newFileName
                    newFileName = ""
                }
            }
        } message: {
            Text("Enter the filename (e.g., Helper.swift)")
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !templateDescription.isEmpty &&
        !author.isEmpty &&
        !sourceFiles.isEmpty &&
        sourceFiles.values.allSatisfy { !$0.isEmpty }
    }
    
    private func saveTemplate() {
        // Update isVisualTemplate based on current mode
        let isVisual = editorMode == .visual
        
        if let existingTemplate = template {
            // Update existing
            existingTemplate.name = name
            existingTemplate.templateDescription = templateDescription
            existingTemplate.icon = icon
            existingTemplate.category = category
            existingTemplate.author = author
            existingTemplate.version = version
            existingTemplate.features = features
            existingTemplate.dependencies = dependencies
            existingTemplate.tags = tags
            existingTemplate.sharedModules = sharedModules
            existingTemplate.featureToggles = featureToggles
            existingTemplate.sourceFiles = sourceFiles
            existingTemplate.visualLayout = visualLayout
            existingTemplate.visualScreens = visualScreens
            existingTemplate.branding = branding
            existingTemplate.isVisualTemplate = isVisual
            
            templateManager.updateTemplate(existingTemplate)
        } else {
            // Create new
            let newTemplate = TemplateModel(
                name: name,
                category: category,
                description: templateDescription,
                icon: icon,
                author: author,
                version: version,
                sourceFiles: sourceFiles,
                features: features,
                dependencies: dependencies,
                isBuiltIn: false,
                tags: tags,
                sharedModules: sharedModules,
                featureToggles: featureToggles,
                visualLayout: visualLayout,
                visualScreens: visualScreens,
                branding: branding,
                isVisualTemplate: isVisual
            )
            
            templateManager.createTemplate(newTemplate)
        }
        
        dismiss()
    }
    
    private func createVariant(designSystem: DesignSystem, colorScheme: ColorSchemeVariant) {
        guard let existingTemplate = template else { return }
        
        let variantBranding = TemplateBranding.preset(for: designSystem, colorScheme: colorScheme)
        let variantName = "\(existingTemplate.name) (\(designSystem.rawValue) - \(colorScheme.rawValue))"
        
        let variant = TemplateModel(
            name: variantName,
            category: existingTemplate.category,
            description: existingTemplate.templateDescription,
            icon: existingTemplate.icon,
            author: existingTemplate.author,
            version: existingTemplate.version,
            sourceFiles: existingTemplate.sourceFiles,
            features: existingTemplate.features,
            dependencies: existingTemplate.dependencies,
            isBuiltIn: false,
            tags: existingTemplate.tags + [designSystem.rawValue.lowercased(), colorScheme.rawValue.lowercased()],
            sharedModules: existingTemplate.sharedModules,
            featureToggles: existingTemplate.featureToggles,
            visualLayout: existingTemplate.visualLayout,
            visualScreens: existingTemplate.visualScreens,
            branding: variantBranding,
            isVisualTemplate: true
        )
        
        templateManager.createTemplate(variant)
        
        // Show success notification
        AppNotificationService.shared.post(
            message: "Created variant: \(variantName)",
            level: .success
        )
        
        dismiss()
    }
    
    private static var defaultMainSwift: String {
        """
        import SwiftUI
        
        @main
        struct MyApp: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
            }
        }
        
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
                    .padding()
            }
        }
        """
    }
}

// Simple flow layout for tags
struct TemplateFlowLayout: Layout {
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
