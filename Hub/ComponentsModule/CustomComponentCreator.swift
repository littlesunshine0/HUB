import SwiftUI
import Combine

// MARK: - Custom Component Creator
struct CustomComponentCreatorView: View {
    @StateObject private var viewModel = ComponentCreatorViewModel()
    
    var body: some View {
        HSplitView {
            // Properties Panel
            ComponentPropertiesPanel(component: $viewModel.component)
                .frame(minWidth: 250, maxWidth: 300)
            
            // Preview
            VStack {
                Text("Preview")
                    .font(.headline)
                
                ComponentPreview(component: viewModel.component)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            }
            
            // Code View
            CodeGenerationView(code: viewModel.generatedCode)
                .frame(minWidth: 300)
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Save") { viewModel.saveComponent() }
                Button("Publish") { viewModel.publishToLibrary() }
            }
        }
    }
}

struct ComponentPropertiesPanel: View {
    @Binding var component: CustomComponent
    
    var body: some View {
        Form {
            Section("Basic") {
                TextField("Name", text: $component.name)
                TextField("Description", text: $component.description)
                Picker("Category", selection: $component.category) {
                    ForEach(CustomComponentCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }
            
            Section("Layout") {
                Picker("Type", selection: $component.layoutType) {
                    Text("VStack").tag(LayoutType.vstack)
                    Text("HStack").tag(LayoutType.hstack)
                    Text("ZStack").tag(LayoutType.zstack)
                }
                
                Slider(value: $component.padding, in: 0...50) {
                    Text("Padding: \(Int(component.padding))")
                }
                
                Slider(value: $component.spacing, in: 0...30) {
                    Text("Spacing: \(Int(component.spacing))")
                }
            }
            
            Section("Style") {
                ColorPicker("Background", selection: $component.backgroundColor)
                ColorPicker("Foreground", selection: $component.foregroundColor)
                
                Slider(value: $component.cornerRadius, in: 0...30) {
                    Text("Corner Radius: \(Int(component.cornerRadius))")
                }
                
                Toggle("Shadow", isOn: $component.hasShadow)
            }
            
            Section("Properties") {
                ForEach($component.properties) { $property in
                    HStack {
                        TextField("Name", text: $property.name)
                        TextField("Type", text: $property.type)
                        Button(action: {
                            component.properties.removeAll { $0.id == property.id }
                        }) {
                            Image(systemName: "minus.circle")
                        }
                    }
                }
                
                Button("Add Property") {
                    component.properties.append(ComponentProperty(name: "newProperty", type: "String"))
                }
            }
        }
        .padding()
    }
}

struct ComponentPreview: View {
    let component: CustomComponent
    
    var body: some View {
        Group {
            switch component.layoutType {
            case .vstack:
                VStack(spacing: component.spacing) {
                    componentContent
                }
            case .hstack:
                HStack(spacing: component.spacing) {
                    componentContent
                }
            case .zstack:
                ZStack {
                    componentContent
                }
            }
        }
        .padding(component.padding)
        .background(component.backgroundColor)
        .foregroundColor(component.foregroundColor)
        .cornerRadius(component.cornerRadius)
        .shadow(radius: component.hasShadow ? 4 : 0)
    }
    
    @ViewBuilder
    private var componentContent: some View {
        Text(component.name)
            .font(.headline)
        Text(component.description)
            .font(.caption)
    }
}

struct CodeGenerationView: View {
    let code: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Generated Code")
                    .font(.headline)
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                }
            }
            .padding()
            
            ScrollView {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .background(Color.black.opacity(0.05))
        }
    }
}

@MainActor
class ComponentCreatorViewModel: ObservableObject {
    @Published var component = CustomComponent()
    
    var generatedCode: String {
        generateSwiftUICode(for: component)
    }
    
    func saveComponent() {
        // Save to local library
    }
    
    func publishToLibrary() {
        // Publish to marketplace
    }
    
    private func generateSwiftUICode(for component: CustomComponent) -> String {
        var code = "import SwiftUI\n\n"
        code += "struct \(component.name): View {\n"
        
        // Properties
        for property in component.properties {
            code += "    let \(property.name): \(property.type)\n"
        }
        
        code += "\n    var body: some View {\n"
        
        // Layout
        let layout = component.layoutType.rawValue.capitalized
        code += "        \(layout)(spacing: \(Int(component.spacing))) {\n"
        code += "            Text(\"\(component.name)\")\n"
        code += "                .font(.headline)\n"
        code += "        }\n"
        
        // Modifiers
        code += "        .padding(\(Int(component.padding)))\n"
        code += "        .background(Color(...))\n"
        code += "        .foregroundColor(Color(...))\n"
        code += "        .cornerRadius(\(Int(component.cornerRadius)))\n"
        
        if component.hasShadow {
            code += "        .shadow(radius: 4)\n"
        }
        
        code += "    }\n"
        code += "}\n"
        
        return code
    }
}

struct CustomComponent: Identifiable {
    let id = UUID()
    var name: String = "CustomComponent"
    var description: String = "A custom component"
    var category: CustomComponentCategory = .button
    var layoutType: LayoutType = .vstack
    var padding: Double = 16
    var spacing: Double = 8
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var cornerRadius: Double = 8
    var hasShadow: Bool = false
    var properties: [ComponentProperty] = []
}

struct ComponentProperty: Identifiable {
    let id = UUID()
    var name: String
    var type: String
}

enum CustomComponentCategory: String, CaseIterable {
    case button, input, layout, display, navigation
}

enum LayoutType: String {
    case vstack, hstack, zstack
}
