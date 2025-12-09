import SwiftUI

// MARK: - Live Preview Renderer

/// Optimized renderer for live preview of RenderableComponents
/// Split into category-based functions to avoid Swift compiler complexity issues
struct LivePreviewRenderer {
    
    // MARK: - Main Render Function
    
    /// Renders a RenderableComponent to AnyView
    /// - Parameter component: The component to render
    /// - Returns: Type-erased view of the rendered component
    static func render(component: RenderableComponent) -> AnyView {
        switch component {
        // Layout components
        case .vstack, .hstack, .zstack:
            return renderLayout(component)
            
        // Control components
        case .button, .textField, .toggle, .picker:
            return renderControl(component)
            
        // Display components
        case .text, .image, .progressView:
            return renderDisplay(component)
            
        // Container components
        case .scrollView, .list, .navigationStack, .form, .section:
            return renderContainer(component)
            
        // Shape components
        case .rectangle, .circle, .spacer, .divider:
            return renderShape(component)
        }
    }
    
    // MARK: - Layout Components
    
    private static func renderLayout(_ component: RenderableComponent) -> AnyView {
        switch component {
        case .vstack(_, let spacing, let children, let modifiers):
            return AnyView(
                VStack(spacing: spacing) {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .hstack(_, let spacing, let children, let modifiers):
            return AnyView(
                HStack(spacing: spacing) {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .zstack(_, let children, let modifiers):
            return AnyView(
                ZStack {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        default:
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Control Components
    
    private static func renderControl(_ component: RenderableComponent) -> AnyView {
        switch component {
        case .button(_, let title, _, let style, let modifiers):
            return AnyView(
                Group {
                    switch style {
                    case .plain:
                        Button(title) { }.buttonStyle(.plain)
                    case .bordered:
                        Button(title) { }.buttonStyle(.bordered)
                    case .borderedProminent:
                        Button(title) { }.buttonStyle(.borderedProminent)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .textField(_, let placeholder, _, let modifiers):
            return AnyView(
                TextField(placeholder, text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .applyModifiers(modifiers)
            )
            
        case .toggle(_, let label, _, let modifiers):
            return AnyView(
                Toggle(label, isOn: .constant(false))
                    .applyModifiers(modifiers)
            )
            
        case .picker(_, let label, _, let options, let modifiers):
            return AnyView(
                Picker(label, selection: .constant(0)) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Text(option).tag(index)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        default:
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Display Components
    
    private static func renderDisplay(_ component: RenderableComponent) -> AnyView {
        switch component {
        case .text(_, let content, let fontSize, let fontWeight, let color, let modifiers):
            return AnyView(
                Text(content)
                    .font(.system(size: fontSize, weight: fontWeight.toSwiftUI()))
                    .foregroundStyle(Color(hex: color) ?? .primary)
                    .applyModifiers(modifiers)
            )
            
        case .image(_, let systemName, let size, let color, let modifiers):
            return AnyView(
                Image(systemName: systemName)
                    .font(.system(size: size))
                    .foregroundStyle(Color(hex: color) ?? .primary)
                    .applyModifiers(modifiers)
            )
            
        case .progressView(_, let label, let modifiers):
            return AnyView(
                ProgressView(label)
                    .applyModifiers(modifiers)
            )
            
        default:
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Container Components
    
    private static func renderContainer(_ component: RenderableComponent) -> AnyView {
        switch component {
        case .scrollView(_, _, let children, let modifiers):
            return AnyView(
                ScrollView {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .list(_, let children, let modifiers):
            return AnyView(
                List {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .navigationStack(_, _, let children, let modifiers):
            return AnyView(
                NavigationStack {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .form(_, let children, let modifiers):
            return AnyView(
                Form {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        case .section(_, let header, let children, let modifiers):
            return AnyView(
                Section(header: Text(header)) {
                    ForEach(children, id: \.id) { child in
                        render(component: child)
                    }
                }
                .applyModifiers(modifiers)
            )
            
        default:
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Shape Components
    
    private static func renderShape(_ component: RenderableComponent) -> AnyView {
        switch component {
        case .rectangle(_, let width, let height, let color, let cornerRadius, let modifiers):
            let w: CGFloat? = width.map { CGFloat($0) }
            let h: CGFloat? = height.map { CGFloat($0) }
            return AnyView(
                Rectangle()
                    .fill(Color(hex: color) ?? .blue)
                    .frame(width: w, height: h)
                    .cornerRadius(cornerRadius)
                    .applyModifiers(modifiers)
            )
            
        case .circle(_, let diameter, let color, let modifiers):
            return AnyView(
                Circle()
                    .fill(Color(hex: color) ?? .blue)
                    .frame(width: diameter, height: diameter)
                    .applyModifiers(modifiers)
            )
            
        case .spacer(_, let modifiers):
            return AnyView(
                Spacer()
                    .applyModifiers(modifiers)
            )
            
        case .divider(_, let modifiers):
            return AnyView(
                Divider()
                    .applyModifiers(modifiers)
            )
            
        default:
            return AnyView(EmptyView())
        }
    }
}

// MARK: - Font Weight Extension
// Note: FontWeightOption.toSwiftUI() is defined in VisualEditorView.swift
