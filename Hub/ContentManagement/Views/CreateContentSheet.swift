//
//  CreateContentSheet.swift
//  Hub
//
//  Sheet for creating new content of any type
//

import SwiftUI
import SwiftData

// MARK: - Create Content Sheet

struct CreateContentSheet: View {
    let contentType: HubContentType
    @ObservedObject var contentManager: HubContentManager
    @Environment(\.dismiss) private var dismiss
    @Query private var templates: [TemplateModel]
    
    // Common fields
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedIcon: String = "app.fill"
    @State private var selectedCategory: HubCategory = .productivity
    
    // Hub-specific
    @State private var selectedTemplate: TemplateModel?
    
    // Template-specific
    @State private var sourceCode: String = ""
    @State private var features: [String] = []
    @State private var newFeature: String = ""
    
    @State private var showingIconPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                
                switch contentType {
                case .hub:
                    hubSpecificSection
                case .template, .component, .module, .blueprint, .package:
                    templateSpecificSection
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New \(contentType.rawValue)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createContent()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Name", text: $name)
            
            TextEditor(text: $description)
                .frame(minHeight: 80)
            
            HStack {
                Image(systemName: selectedIcon)
                    .font(.title)
                    .foregroundStyle(contentType.color)
                    .frame(width: 44, height: 44)
                    .background(contentType.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Choose Icon") {
                    showingIconPicker = true
                }
                .buttonStyle(.bordered)
            }
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(HubCategory.allCases, id: \.self) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }
        }
    }
    
    // MARK: - Hub Specific Section
    
    private var hubSpecificSection: some View {
        Section("Template") {
            Picker("Choose Template", selection: $selectedTemplate) {
                Text("Select a template").tag(nil as TemplateModel?)
                ForEach(templates.filter { !$0.name.contains("Component") && !$0.name.contains("Module") }) { template in
                    HStack {
                        Image(systemName: template.icon)
                        Text(template.name)
                    }
                    .tag(template as TemplateModel?)
                }
            }
            
            if let template = selectedTemplate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.templateDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !template.features.isEmpty {
                        Text("Features:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        ForEach(template.features.prefix(5), id: \.self) { feature in
                            Label(feature, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Template Specific Section
    
    private var templateSpecificSection: some View {
        Group {
            Section("Features") {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Text(feature)
                        Spacer()
                        Button {
                            features.removeAll { $0 == feature }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack {
                    TextField("Add feature", text: $newFeature)
                    Button("Add") {
                        if !newFeature.isEmpty {
                            features.append(newFeature)
                            newFeature = ""
                        }
                    }
                    .disabled(newFeature.isEmpty)
                }
            }
            
            Section("Source Code") {
                TextEditor(text: $sourceCode)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        guard !name.isEmpty else { return false }
        
        switch contentType {
        case .hub:
            return selectedTemplate != nil
        default:
            return true
        }
    }
    
    // MARK: - Create Content
    
    private func createContent() {
        switch contentType {
        case .hub:
            guard let template = selectedTemplate else { return }
            
            let customization = HubCustomization(
                primaryColor: "#000000",
                accentColor: "#007AFF",
                appName: name,
                bundleIdentifier: "com.hub.\(name.lowercased().replacingOccurrences(of: " ", with: ""))",
                features: Dictionary(uniqueKeysWithValues: template.features.map { ($0, true) }),
                settings: [:]
            )
            
            _ = contentManager.createHub(
                name: name,
                description: description,
                icon: selectedIcon,
                category: selectedCategory,
                templateID: template.id,
                templateName: template.name,
                customization: customization
            )
            
        case .template:
            _ = contentManager.createTemplate(
                name: name,
                category: selectedCategory,
                description: description,
                icon: selectedIcon,
                sourceFiles: ["main.swift": sourceCode],
                features: features
            )
            
        case .component:
            _ = contentManager.createTemplate(
                name: "\(name) Component",
                category: selectedCategory,
                description: description,
                icon: selectedIcon,
                sourceFiles: ["main.swift": sourceCode],
                features: features
            )
            
        case .module:
            _ = contentManager.createTemplate(
                name: "\(name) Module",
                category: selectedCategory,
                description: description,
                icon: selectedIcon,
                sourceFiles: ["main.swift": sourceCode],
                features: features
            )
            
        case .blueprint:
            _ = contentManager.createTemplate(
                name: "\(name) Blueprint",
                category: selectedCategory,
                description: description,
                icon: selectedIcon,
                sourceFiles: ["main.swift": sourceCode],
                features: features
            )
            
        case .package:
            _ = contentManager.createTemplate(
                name: "\(name) Package",
                category: selectedCategory,
                description: description,
                icon: selectedIcon,
                sourceFiles: ["main.swift": sourceCode],
                features: features
            )
        }
    }
}

// Note: IconPickerView is defined in HubCRUDOperations.swift
