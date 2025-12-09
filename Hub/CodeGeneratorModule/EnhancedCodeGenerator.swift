import Foundation
import SwiftUI


class EnhancedCodeGenerator {
    static let shared = EnhancedCodeGenerator()
    
    private var achievementTracker: CodeGeneratorAchievementTracker?
    
    private init() {}
    
    // MARK: - Configuration
    
    func setAchievementTracker(_ tracker: CodeGeneratorAchievementTracker) {
        self.achievementTracker = tracker
    }
    
    /// Generates a complete multi-screen Swift app with branding
    func generateApp(
        from screens: [VisualScreen],
        branding: TemplateBranding,
        appName: String,
        bundleIdentifier: String
    ) -> [String: String] {
        var files: [String: String] = [:]
        
        // Generate main app file
        files["main.swift"] = generateMainApp(appName: appName, initialScreen: screens.first { $0.isInitialScreen })
        
        // Track component usage across all screens
        var allComponentTypes = Set<String>()
        for screen in screens {
            let componentTypes = extractComponentTypes(from: screen.components)
            allComponentTypes.formUnion(componentTypes)
        }
        achievementTracker?.trackComponentUsage(componentTypes: allComponentTypes)
        
        // Generate each screen as a separate view
        for screen in screens {
            let fileName = "\(screen.name).swift"
            files[fileName] = generateScreen(screen, branding: branding)
        }
        
        // Generate branding extensions
        files["BrandingExtensions.swift"] = generateBrandingExtensions(branding)
        
        return files
    }
    
    // MARK: - Component Type Extraction
    
    private func extractComponentTypes(from components: [RenderableComponent]) -> Set<String> {
        var types = Set<String>()
        
        func extract(from component: RenderableComponent) {
            // Extract component type name
            let typeName = String(describing: component).components(separatedBy: "(").first ?? "Unknown"
            types.insert(typeName)
            
            for child in component.children {
                extract(from: child)
            }
        }
        
        for component in components {
            extract(from: component)
        }
        
        return types
    }
    
    // MARK: - Main App Generation
    
    private func generateMainApp(appName: String, initialScreen: VisualScreen?) -> String {
        let sanitizedName = appName.replacingOccurrences(of: " ", with: "")
        let initialViewName = initialScreen?.name ?? "ContentView"
        
        return """
        import SwiftUI
        
        @main
        struct \(sanitizedName)App: App {
            var body: some Scene {
                WindowGroup {
                    \(initialViewName)()
                }
            }
        }
        """
    }
    
    // MARK: - Screen Generation
    
    private func generateScreen(_ screen: VisualScreen, branding: TemplateBranding) -> String {
        let stateVariables = extractStateVariables(from: screen.components)
        let bodyCode = generateBody(from: screen.components, indent: 2)
        let actionMethods = generateActionMethods(from: screen.components)
        
        var code = """
        import SwiftUI
        
        struct \(screen.name): View {
        """
        
        // Add state variables
        if !stateVariables.isEmpty {
            code += "\n"
            for variable in stateVariables {
                code += "    @State private var \(variable.name): \(variable.type) = \(variable.defaultValue)\n"
            }
        }
        
        // Add body
        code += """
        
            var body: some View {
        """
        
        // Wrap in NavigationStack if screen has navigation title
        if let navTitle = screen.navigationTitle {
            code += """
        
                NavigationStack {
        \(bodyCode)
                    .navigationTitle("\(navTitle)")
                }
        """
        } else {
            code += "\n\(bodyCode)\n"
        }
        
        // Add background if specified
        if let bgColor = screen.backgroundColor {
            code += """
        
                .background(Color(hex: "\(bgColor)") ?? .clear)
        """
        }
        
        code += """
        
            }
        """
        
        // Add action methods
        if !actionMethods.isEmpty {
            code += actionMethods
        }
        
        code += """
        
        }
        
        #Preview {
            \(screen.name)()
        }
        """
        
        return code
    }
    
    // MARK: - Body Generation
    
    func generateBody(from components: [RenderableComponent], indent: Int) -> String {
        let indentStr = String(repeating: " ", count: indent * 4)
        
        if components.isEmpty {
            return "\(indentStr)Text(\"Empty View\")"
        }
        
        if components.count == 1 {
            return generateComponent(components[0], indent: indent)
        }
        
        // Multiple root components - wrap in VStack
        var code = "\(indentStr)VStack {\n"
        for component in components {
            code += generateComponent(component, indent: indent + 1)
            code += "\n"
        }
        code += "\(indentStr)}"
        return code
    }
    
    // MARK: - Component Generation
    
    func generateComponent(_ component: RenderableComponent, indent: Int) -> String {
        // Use the existing VisualCodeGenerator for component generation with modifiers
        return VisualCodeGenerator.shared.generateComponent(component, indent: indent)
    }
    
    // MARK: - State Variables
    
    func extractStateVariables(from components: [RenderableComponent]) -> [(name: String, type: String, defaultValue: String)] {
        var variables: [(name: String, type: String, defaultValue: String)] = []
        var seen = Set<String>()
        
        func extract(from component: RenderableComponent) {
            switch component {
            case .textField(_, _, let binding, _):
                if !seen.contains(binding) {
                    variables.append((name: binding, type: "String", defaultValue: "\"\""))
                    seen.insert(binding)
                }
            case .toggle(_, _, let binding, _):
                if !seen.contains(binding) {
                    variables.append((name: binding, type: "Bool", defaultValue: "false"))
                    seen.insert(binding)
                }
            case .picker(_, _, let binding, _, _):
                if !seen.contains(binding) {
                    variables.append((name: binding, type: "Int", defaultValue: "0"))
                    seen.insert(binding)
                }
            default:
                break
            }
            
            // Recursively extract from children
            for child in component.children {
                extract(from: child)
            }
        }
        
        for component in components {
            extract(from: component)
        }
        
        return variables
    }
    
    // MARK: - Action Methods
    
    func generateActionMethods(from components: [RenderableComponent]) -> String {
        var actions = Set<String>()
        
        func extractActions(from component: RenderableComponent) {
            if case .button(_, _, let action, _, _) = component {
                // Extract action name from NavigationAction
                switch action {
                case .custom(let actionName):
                    actions.insert(actionName)
                case .navigateTo, .sheet, .dismiss, .none:
                    break
                }
            }
            
            for child in component.children {
                extractActions(from: child)
            }
        }
        
        for component in components {
            extractActions(from: component)
        }
        
        if actions.isEmpty {
            return ""
        }
        
        var code = "\n    // MARK: - Actions\n"
        for action in actions.sorted() {
            code += """
            
                private func \(action)() {
                    print("\(action) called")
                    // Add your action code here
                }
            """
        }
        
        return code
    }
    
    // MARK: - Branding Extensions
    
    func generateBrandingExtensions(_ branding: TemplateBranding) -> String {
        return """
        import SwiftUI
        
        // MARK: - Color Extensions
        
        extension Color {
            init?(hex: String) {
                var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
                
                var rgb: UInt64 = 0
                guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
                
                let r = Double((rgb & 0xFF0000) >> 16) / 255.0
                let g = Double((rgb & 0x00FF00) >> 8) / 255.0
                let b = Double(rgb & 0x0000FF) / 255.0
                
                self.init(red: r, green: g, blue: b)
            }
            
            static var brandAccent: Color {
                Color(hex: "\(branding.accentColor)") ?? .blue
            }
            
            static var brandPrimary: Color {
                Color(hex: "\(branding.primaryColor)") ?? .primary
            }
            
            static var brandBackground: Color {
                Color(hex: "\(branding.backgroundColor)") ?? .white
            }
        }
        """
    }
}
