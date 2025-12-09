import Foundation
import SwiftUI

import Combine

class VisualCodeGenerator {
    static let shared = VisualCodeGenerator()
    
    private init() {}
    
    /// Generates a complete Swift app from visual components
    func generateApp(from components: [RenderableComponent], appName: String, bundleIdentifier: String) -> String {
        let stateVariables = extractStateVariables(from: components)
        let bodyCode = generateBody(from: components, indent: 2)
        
        return """
        import SwiftUI
        
        @main
        struct \(appName.replacingOccurrences(of: " ", with: ""))App: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
            }
        }
        
        struct ContentView: View {
        \(stateVariables.map { "    @State private var \($0.name): \($0.type) = \($0.defaultValue)" }.joined(separator: "\n"))
            
            var body: some View {
        \(bodyCode)
            }
        \(generateActionMethods(from: components))
        }
        
        #Preview {
            ContentView()
        }
        """
    }
    
    /// Generates the body content from components
    private func generateBody(from components: [RenderableComponent], indent: Int) -> String {
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
    
    /// Generates code for a single component
    func generateComponent(_ component: RenderableComponent, indent: Int) -> String {
        let indentStr = String(repeating: " ", count: indent * 4)
        var baseCode = ""
        var modifiers: ComponentModifiers = .init()
        
        switch component {
        case .vstack(_, let spacing, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)VStack(spacing: \(spacing)) {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .hstack(_, let spacing, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)HStack(spacing: \(spacing)) {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .zstack(_, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)ZStack {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .text(_, let content, let fontSize, let fontWeight, let color, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Text(\"\(content)\")"
            baseCode += "\n\(indentStr)    .font(.system(size: \(fontSize), weight: .\(fontWeight.rawValue)))"
            if !color.isEmpty {
                baseCode += "\n\(indentStr)    .foregroundStyle(Color(hex: \"\(color)\") ?? .primary)"
            }
            
        case .button(_, let title, let action, let style, let mods):
            modifiers = mods
            baseCode = generateButtonCode(title: title, action: action, style: style, indent: indent)
            
        case .textField(_, let placeholder, let binding, let mods):
            modifiers = mods
            baseCode = "\(indentStr)TextField(\"\(placeholder)\", text: $\(binding))"
            
        case .image(_, let systemName, let size, let color, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Image(systemName: \"\(systemName)\")"
            baseCode += "\n\(indentStr)    .font(.system(size: \(size)))"
            if !color.isEmpty {
                baseCode += "\n\(indentStr)    .foregroundStyle(Color(hex: \"\(color)\") ?? .primary)"
            }
            
        case .spacer(_, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Spacer()"
            
        case .divider(_, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Divider()"
            
        case .scrollView(_, let axis, let children, let mods):
            modifiers = mods
            let axisParam = axis == .horizontal ? ".horizontal" : ".vertical"
            baseCode = "\(indentStr)ScrollView(\(axisParam)) {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .list(_, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)List {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .navigationStack(_, let title, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)NavigationStack {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)    .navigationTitle(\"\(title)\")\n"
            baseCode += "\(indentStr)}"
            
        case .form(_, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Form {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .section(_, let header, let children, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Section(\"\(header)\") {\n"
            for child in children {
                baseCode += generateComponent(child, indent: indent + 1)
                baseCode += "\n"
            }
            baseCode += "\(indentStr)}"
            
        case .toggle(_, let label, let binding, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Toggle(\"\(label)\", isOn: $\(binding))"
            
        case .picker(_, let label, let binding, let options, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Picker(\"\(label)\", selection: $\(binding)) {\n"
            for (index, option) in options.enumerated() {
                baseCode += "\(indentStr)    Text(\"\(option)\").tag(\(index))\n"
            }
            baseCode += "\(indentStr)}"
            
        case .progressView(_, let label, let mods):
            modifiers = mods
            baseCode = "\(indentStr)ProgressView(\"\(label)\")"
            
        case .rectangle(_, let width, let height, let color, let cornerRadius, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Rectangle()"
            baseCode += "\n\(indentStr)    .fill(Color(hex: \"\(color)\") ?? .blue)"
            if let w = width {
                baseCode += "\n\(indentStr)    .frame(width: \(w)"
                if let h = height {
                    baseCode += ", height: \(h)"
                }
                baseCode += ")"
            } else if let h = height {
                baseCode += "\n\(indentStr)    .frame(height: \(h))"
            }
            if cornerRadius > 0 {
                baseCode += "\n\(indentStr)    .cornerRadius(\(cornerRadius))"
            }
            
        case .circle(_, let size, let color, let mods):
            modifiers = mods
            baseCode = "\(indentStr)Circle()"
            baseCode += "\n\(indentStr)    .fill(Color(hex: \"\(color)\") ?? .blue)"
            baseCode += "\n\(indentStr)    .frame(width: \(size), height: \(size))"
        }
        
        // Apply modifiers
        baseCode += generateModifiers(from: modifiers, indent: indent)
        return baseCode
    }
    
    /// Generates button code with navigation support
    private func generateButtonCode(title: String, action: NavigationAction, style: ButtonStyleOption, indent: Int) -> String {
        let indentStr = String(repeating: " ", count: indent * 4)
        var code = ""
        
        switch action {
        case .none, .custom:
            code = "\(indentStr)Button {\n"
            if case .custom(let actionName) = action {
                code += "\(indentStr)    \(actionName)()\n"
            } else {
                code += "\(indentStr)    // No action\n"
            }
            code += "\(indentStr)} label: {\n"
            code += "\(indentStr)    Text(\"\(title)\")\n"
            code += "\(indentStr)}"
            code += "\n\(indentStr).buttonStyle(.\(style.rawValue))"
            
        case .navigateTo(let screenID):
            code = "\(indentStr)NavigationLink(destination: Screen_\(screenID.uuidString.prefix(8))()) {\n"
            code += "\(indentStr)    Text(\"\(title)\")\n"
            code += "\(indentStr)}"
            code += "\n\(indentStr).buttonStyle(.\(style.rawValue))"
            
        case .sheet(let screenID):
            code = "\(indentStr)Button {\n"
            code += "\(indentStr)    showSheet_\(screenID.uuidString.prefix(8)) = true\n"
            code += "\(indentStr)} label: {\n"
            code += "\(indentStr)    Text(\"\(title)\")\n"
            code += "\(indentStr)}"
            code += "\n\(indentStr).buttonStyle(.\(style.rawValue))"
            
        case .dismiss:
            code = "\(indentStr)Button {\n"
            code += "\(indentStr)    dismiss()\n"
            code += "\(indentStr)} label: {\n"
            code += "\(indentStr)    Text(\"\(title)\")\n"
            code += "\(indentStr)}"
            code += "\n\(indentStr).buttonStyle(.\(style.rawValue))"
        }
        
        return code
    }
    
    /// Generates modifier code from ComponentModifiers
    private func generateModifiers(from modifiers: ComponentModifiers, indent: Int) -> String {
        let indentStr = String(repeating: " ", count: indent * 4)
        var code = ""
        
        if let padding = modifiers.padding {
            code += "\n\(indentStr).padding(\(padding))"
        }
        
        if let frame = modifiers.frame {
            var frameParams: [String] = []
            if let width = frame.width {
                frameParams.append("width: \(width)")
            }
            if let height = frame.height {
                frameParams.append("height: \(height)")
            }
            if let maxWidth = frame.maxWidth {
                frameParams.append("maxWidth: \(maxWidth)")
            }
            if let maxHeight = frame.maxHeight {
                frameParams.append("maxHeight: \(maxHeight)")
            }
            if !frameParams.isEmpty {
                code += "\n\(indentStr).frame(\(frameParams.joined(separator: ", ")))"
            }
        }
        
        if let background = modifiers.background, !background.isEmpty {
            code += "\n\(indentStr).background(Color(hex: \"\(background)\") ?? .clear)"
        }
        
        if let foreground = modifiers.foregroundColor, !foreground.isEmpty {
            code += "\n\(indentStr).foregroundStyle(Color(hex: \"\(foreground)\") ?? .primary)"
        }
        
        if let cornerRadius = modifiers.cornerRadius {
            code += "\n\(indentStr).cornerRadius(\(cornerRadius))"
        }
        
        if let opacity = modifiers.opacity {
            code += "\n\(indentStr).opacity(\(opacity))"
        }
        
        if let offset = modifiers.offset {
            code += "\n\(indentStr).offset(x: \(offset.x), y: \(offset.y))"
        }
        
        if let shadow = modifiers.shadow {
            code += "\n\(indentStr).shadow(color: Color(hex: \"\(shadow.color)\") ?? .black, radius: \(shadow.radius), x: \(shadow.x), y: \(shadow.y))"
        }
        
        return code
    }
    
    /// Extracts state variables from components
    private func extractStateVariables(from components: [RenderableComponent]) -> [(name: String, type: String, defaultValue: String)] {
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
            case .button(_, _, let action, _, _):
                // Add sheet state variables
                if case .sheet(let screenID) = action {
                    let varName = "showSheet_\(screenID.uuidString.prefix(8))"
                    if !seen.contains(varName) {
                        variables.append((name: varName, type: "Bool", defaultValue: "false"))
                        seen.insert(varName)
                    }
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
    
    /// Generates action methods for buttons
    private func generateActionMethods(from components: [RenderableComponent]) -> String {
        var actions = Set<String>()
        
        func extractActions(from component: RenderableComponent) {
            if case .button(_, _, let action, _, _) = component {
                if case .custom(let actionName) = action {
                    actions.insert(actionName)
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
}
