import Foundation
import SwiftUI

// MARK: - Renderable Component Model

public enum RenderableComponent: Codable, Identifiable {
    case vstack(id: UUID, spacing: Double, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case hstack(id: UUID, spacing: Double, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case zstack(id: UUID, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case text(id: UUID, content: String, fontSize: Double, fontWeight: FontWeightOption, color: String, modifiers: ComponentModifiers = .init())
    case button(id: UUID, title: String, action: NavigationAction = .none, style: ButtonStyleOption, modifiers: ComponentModifiers = .init())
    case textField(id: UUID, placeholder: String, binding: String, modifiers: ComponentModifiers = .init())
    case image(id: UUID, systemName: String, size: Double, color: String, modifiers: ComponentModifiers = .init())
    case spacer(id: UUID, modifiers: ComponentModifiers = .init())
    case divider(id: UUID, modifiers: ComponentModifiers = .init())
    case scrollView(id: UUID, axis: AxisOption, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case list(id: UUID, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case navigationStack(id: UUID, title: String, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case form(id: UUID, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case section(id: UUID, header: String, children: [RenderableComponent], modifiers: ComponentModifiers = .init())
    case toggle(id: UUID, label: String, binding: String, modifiers: ComponentModifiers = .init())
    case picker(id: UUID, label: String, binding: String, options: [String], modifiers: ComponentModifiers = .init())
    case progressView(id: UUID, label: String, modifiers: ComponentModifiers = .init())
    case rectangle(id: UUID, width: Double?, height: Double?, color: String, cornerRadius: Double, modifiers: ComponentModifiers = .init())
    case circle(id: UUID, size: Double, color: String, modifiers: ComponentModifiers = .init())
    
    public var id: UUID {
        switch self {
        case .vstack(let id, _, _, _): return id
        case .hstack(let id, _, _, _): return id
        case .zstack(let id, _, _): return id
        case .text(let id, _, _, _, _, _): return id
        case .button(let id, _, _, _, _): return id
        case .textField(let id, _, _, _): return id
        case .image(let id, _, _, _, _): return id
        case .spacer(let id, _): return id
        case .divider(let id, _): return id
        case .scrollView(let id, _, _, _): return id
        case .list(let id, _, _): return id
        case .navigationStack(let id, _, _, _): return id
        case .form(let id, _, _): return id
        case .section(let id, _, _, _): return id
        case .toggle(let id, _, _, _): return id
        case .picker(let id, _, _, _, _): return id
        case .progressView(let id, _, _): return id
        case .rectangle(let id, _, _, _, _, _): return id
        case .circle(let id, _, _, _): return id
        }
    }
    
    public var displayName: String {
        switch self {
        case .vstack: return "VStack"
        case .hstack: return "HStack"
        case .zstack: return "ZStack"
        case .text: return "Text"
        case .button: return "Button"
        case .textField: return "TextField"
        case .image: return "Image"
        case .spacer: return "Spacer"
        case .divider: return "Divider"
        case .scrollView: return "ScrollView"
        case .list: return "List"
        case .navigationStack: return "NavigationStack"
        case .form: return "Form"
        case .section: return "Section"
        case .toggle: return "Toggle"
        case .picker: return "Picker"
        case .progressView: return "ProgressView"
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        }
    }
    
    public var icon: String {
        switch self {
        case .vstack: return "rectangle.stack"
        case .hstack: return "rectangle.3.group"
        case .zstack: return "square.stack.3d.up"
        case .text: return "textformat"
        case .button: return "button.programmable"
        case .textField: return "textbox"
        case .image: return "photo"
        case .spacer: return "arrow.left.and.right"
        case .divider: return "minus"
        case .scrollView: return "scroll"
        case .list: return "list.bullet"
        case .navigationStack: return "sidebar.left"
        case .form: return "list.bullet.rectangle"
        case .section: return "rectangle.split.3x1"
        case .toggle: return "switch.2"
        case .picker: return "list.bullet.below.rectangle"
        case .progressView: return "progress.indicator"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        }
    }
    
    public var canHaveChildren: Bool {
        switch self {
        case .vstack, .hstack, .zstack, .scrollView, .list, .navigationStack, .form, .section:
            return true
        default:
            return false
        }
    }
    
    public var children: [RenderableComponent] {
        get {
            switch self {
            case .vstack(_, _, let children, _): return children
            case .hstack(_, _, let children, _): return children
            case .zstack(_, let children, _): return children
            case .scrollView(_, _, let children, _): return children
            case .list(_, let children, _): return children
            case .navigationStack(_, _, let children, _): return children
            case .form(_, let children, _): return children
            case .section(_, _, let children, _): return children
            default: return []
            }
        }
    }
    
    public mutating func setChildren(_ newChildren: [RenderableComponent]) {
        switch self {
        case .vstack(let id, let spacing, _, let modifiers):
            self = .vstack(id: id, spacing: spacing, children: newChildren, modifiers: modifiers)
        case .hstack(let id, let spacing, _, let modifiers):
            self = .hstack(id: id, spacing: spacing, children: newChildren, modifiers: modifiers)
        case .zstack(let id, _, let modifiers):
            self = .zstack(id: id, children: newChildren, modifiers: modifiers)
        case .scrollView(let id, let axis, _, let modifiers):
            self = .scrollView(id: id, axis: axis, children: newChildren, modifiers: modifiers)
        case .list(let id, _, let modifiers):
            self = .list(id: id, children: newChildren, modifiers: modifiers)
        case .navigationStack(let id, let title, _, let modifiers):
            self = .navigationStack(id: id, title: title, children: newChildren, modifiers: modifiers)
        case .form(let id, _, let modifiers):
            self = .form(id: id, children: newChildren, modifiers: modifiers)
        case .section(let id, let header, _, let modifiers):
            self = .section(id: id, header: header, children: newChildren, modifiers: modifiers)
        default:
            break
        }
    }
}

// MARK: - Supporting Enums

public enum FontWeightOption: String, Codable, CaseIterable {
    case regular = "regular"
    case bold = "bold"
    case semibold = "semibold"
    case light = "light"
    case medium = "medium"
}

public enum ButtonStyleOption: String, Codable, CaseIterable {
    case plain = "plain"
    case bordered = "bordered"
    case borderedProminent = "borderedProminent"
}

public enum AxisOption: String, Codable, CaseIterable {
    case vertical = "vertical"
    case horizontal = "horizontal"
}

// MARK: - Component Factory

public struct ComponentFactory {
    public static func createDefault(_ type:
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     
                                     ComponentType) -> RenderableComponent {
        let id = UUID()
        
        switch type {
        case .vstack:
            return .vstack(id: id, spacing: 8, children: [], modifiers: .init())
        case .hstack:
            return .hstack(id: id, spacing: 8, children: [], modifiers: .init())
        case .zstack:
            return .zstack(id: id, children: [], modifiers: .init())
        case .text:
            return .text(id: id, content: "Hello, World!", fontSize: 16, fontWeight: .regular, color: "", modifiers: .init())
        case .button:
            return .button(id: id, title: "Button", action: .none, style: .bordered, modifiers: .init())
        case .textField:
            return .textField(id: id, placeholder: "Enter text", binding: "textInput", modifiers: .init())
        case .image:
            return .image(id: id, systemName: "star.fill", size: 24, color: "", modifiers: .init())
        case .spacer:
            return .spacer(id: id, modifiers: .init())
        case .divider:
            return .divider(id: id, modifiers: .init())
        case .scrollView:
            return .scrollView(id: id, axis: .vertical, children: [], modifiers: .init())
        case .list:
            return .list(id: id, children: [], modifiers: .init())
        case .navigationStack:
            return .navigationStack(id: id, title: "Navigation", children: [], modifiers: .init())
        case .form:
            return .form(id: id, children: [], modifiers: .init())
        case .section:
            return .section(id: id, header: "Section", children: [], modifiers: .init())
        case .toggle:
            return .toggle(id: id, label: "Toggle", binding: "isEnabled", modifiers: .init())
        case .picker:
            return .picker(id: id, label: "Picker", binding: "selection", options: ["Option 1", "Option 2"], modifiers: .init())
        case .progressView:
            return .progressView(id: id, label: "Loading...", modifiers: .init())
        case .rectangle:
            return .rectangle(id: id, width: 100, height: 100, color: "#007AFF", cornerRadius: 8, modifiers: .init())
        case .circle:
            return .circle(id: id, size: 50, color: "#007AFF", modifiers: .init())
        }
    }
}

public enum ComponentType: String, CaseIterable {
    case vstack = "VStack"
    case hstack = "HStack"
    case zstack = "ZStack"
    case text = "Text"
    case button = "Button"
    case textField = "TextField"
    case image = "Image"
    case spacer = "Spacer"
    case divider = "Divider"
    case scrollView = "ScrollView"
    case list = "List"
    case navigationStack = "NavigationStack"
    case form = "Form"
    case section = "Section"
    case toggle = "Toggle"
    case picker = "Picker"
    case progressView = "ProgressView"
    case rectangle = "Rectangle"
    case circle = "Circle"
}
