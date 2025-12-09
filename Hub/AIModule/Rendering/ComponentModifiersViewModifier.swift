import SwiftUI

// MARK: - Component Modifiers View Modifier

/// ViewModifier that applies ComponentModifiers to any view
struct ComponentModifiersViewModifier: ViewModifier {
    let modifiers: ComponentModifiers
    
    func body(content: Content) -> some View {
        var view = AnyView(content)
        
        // Apply padding
        if let padding = modifiers.padding {
            view = AnyView(view.padding(padding))
        }
        
        // Apply frame
        if let frame = modifiers.frame {
            if frame.width != nil || frame.height != nil {
                let width: CGFloat? = frame.width.map { CGFloat($0) }
                let height: CGFloat? = frame.height.map { CGFloat($0) }
                view = AnyView(view.frame(
                    width: width,
                    height: height,
                    alignment: .center
                ))
            } else if frame.maxWidth != nil || frame.maxHeight != nil {
                let maxWidth: CGFloat? = frame.maxWidth.map { CGFloat($0) }
                let maxHeight: CGFloat? = frame.maxHeight.map { CGFloat($0) }
                view = AnyView(view.frame(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                    alignment: .center
                ))
            }
        }
        
        // Apply background
        if let background = modifiers.background, !background.isEmpty {
            view = AnyView(view.background(Color(hex: background)))
        }
        
        // Apply foreground color
        if let foreground = modifiers.foregroundColor, !foreground.isEmpty {
            view = AnyView(view.foregroundStyle(Color(hex: foreground)))
        }
        
        // Apply corner radius
        if let cornerRadius = modifiers.cornerRadius {
            view = AnyView(view.cornerRadius(cornerRadius))
        }
        
        // Apply shadow
        if let shadow = modifiers.shadow {
            view = AnyView(view.shadow(
                color: Color(hex: shadow.color),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            ))
        }
        
        // Apply opacity
        if let opacity = modifiers.opacity {
            view = AnyView(view.opacity(opacity))
        }
        
        // Apply offset
        if let offset = modifiers.offset {
            view = AnyView(view.offset(x: offset.x, y: offset.y))
        }
        
        return view
    }
}

// MARK: - View Extension

extension View {
    /// Applies ComponentModifiers to the view
    /// - Parameter modifiers: The modifiers to apply
    /// - Returns: Modified view
    func applyModifiers(_ modifiers: ComponentModifiers) -> some View {
        self.modifier(ComponentModifiersViewModifier(modifiers: modifiers))
    }
}

