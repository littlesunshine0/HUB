//
//  CapsuleButtonSystem.swift
//  Hub
//
//  Comprehensive capsule button system with semantic colors and styles
//

import SwiftUI
import Combine

// MARK: - Capsule Button

struct CapsuleButton: View {
    let title: String
    let icon: String?
    let style: CapsuleButtonStyle
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        style: CapsuleButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(style.foregroundColor)
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headline)
                    }
                    
                    Text(title)
                        .font(.headline)
                }
            }
            .frame(maxWidth: style.isFullWidth ? .infinity : nil)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
        }
        .buttonStyle(.plain)
        .background {
            Capsule()
                .fill(style.background(isEnabled: isEnabled, isHovered: isHovered))
        }
        .overlay {
            Capsule()
                .strokeBorder(style.border(isEnabled: isEnabled, isHovered: isHovered), lineWidth: style.borderWidth)
        }
        .foregroundStyle(style.foregroundColor)
        .scaleEffect(isPressed ? 0.96 : (isHovered ? style.hoverScale : 1.0))
        .shadow(
            color: style.shadowColor(isEnabled: isEnabled, isHovered: isHovered),
            radius: isHovered ? style.shadowRadius * 1.5 : style.shadowRadius,
            y: isHovered ? style.shadowY * 1.5 : style.shadowY
        )
        .disabled(!isEnabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Capsule Button Style

enum CapsuleButtonStyle {
    case primary
    case secondary
    case destructive
    case success
    case warning
    case ghost
    case outline
    
    var isFullWidth: Bool {
        switch self {
        case .primary, .destructive, .success:
            return true
        default:
            return false
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .ghost:
            return 16
        default:
            return 32
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .ghost:
            return 8
        default:
            return 14
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outline:
            return 2
        case .ghost:
            return 0
        default:
            return 1
        }
    }
    
    var hoverScale: CGFloat {
        switch self {
        case .ghost:
            return 1.0
        default:
            return 1.02
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .ghost:
            return 0
        case .primary, .destructive, .success:
            return 12
        default:
            return 8
        }
    }
    
    var shadowY: CGFloat {
        switch self {
        case .ghost:
            return 0
        case .primary, .destructive, .success:
            return 6
        default:
            return 4
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary:
            return .primary
        case .warning:
            return .black
        case .ghost, .outline:
            return .primary
        }
    }
    
    func background(isEnabled: Bool, isHovered: Bool) -> AnyShapeStyle {
        guard isEnabled else {
            return AnyShapeStyle(Color.gray.opacity(0.2))
        }
        
        switch self {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .secondary:
            return AnyShapeStyle(.ultraThinMaterial)
            
        case .destructive:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.red, .red.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .success:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .warning:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.yellow, .yellow.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .ghost:
            return AnyShapeStyle(Color.clear)
            
        case .outline:
            return AnyShapeStyle(Color.clear)
        }
    }
    
    func border(isEnabled: Bool, isHovered: Bool) -> Color {
        guard isEnabled else {
            return Color.gray.opacity(0.2)
        }
        
        switch self {
        case .primary:
            return .white.opacity(0.2)
        case .secondary:
            return .gray.opacity(0.3)
        case .destructive:
            return .red.opacity(0.3)
        case .success:
            return .green.opacity(0.3)
        case .warning:
            return .yellow.opacity(0.3)
        case .ghost:
            return .clear
        case .outline:
            return isHovered ? .blue : .gray.opacity(0.3)
        }
    }
    
    func shadowColor(isEnabled: Bool, isHovered: Bool) -> Color {
        guard isEnabled else {
            return .clear
        }
        
        switch self {
        case .primary:
            return .blue.opacity(isHovered ? 0.4 : 0.2)
        case .destructive:
            return .red.opacity(isHovered ? 0.4 : 0.2)
        case .success:
            return .green.opacity(isHovered ? 0.4 : 0.2)
        case .warning:
            return .yellow.opacity(isHovered ? 0.4 : 0.2)
        default:
            return .clear
        }
    }
}

// MARK: - Capsule Button Group

struct CapsuleButtonGroup: View {
    let buttons: [ButtonConfig]
    var spacing: CGFloat = 12
    var axis: Axis = .horizontal
    
    struct ButtonConfig: Identifiable {
        let id = UUID()
        let title: String
        let icon: String?
        let style: CapsuleButtonStyle
        var isLoading: Bool = false
        var isEnabled: Bool = true
        let action: () -> Void
        
        init(
            _ title: String,
            icon: String? = nil,
            style: CapsuleButtonStyle = .secondary,
            isLoading: Bool = false,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.style = style
            self.isLoading = isLoading
            self.isEnabled = isEnabled
            self.action = action
        }
    }
    
    var body: some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: spacing) {
                    ForEach(buttons) { button in
                        CapsuleButton(
                            button.title,
                            icon: button.icon,
                            style: button.style,
                            isLoading: button.isLoading,
                            isEnabled: button.isEnabled,
                            action: button.action
                        )
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    ForEach(buttons) { button in
                        CapsuleButton(
                            button.title,
                            icon: button.icon,
                            style: button.style,
                            isLoading: button.isLoading,
                            isEnabled: button.isEnabled,
                            action: button.action
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Interactive Toggle Button

struct CapsuleToggleButton: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    var style: CapsuleButtonStyle = .outline
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isOn ? .white : .blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isOn ? .white : .primary)
                
                Spacer()
                
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? .white : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .background {
            Capsule()
                .fill(
                    isOn ?
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) :
                        AnyShapeStyle(Color.gray.opacity(0.05))
                )
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    isOn ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2),
                    lineWidth: isOn ? 2 : 1
                )
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: isOn ? .blue.opacity(0.3) : .clear,
            radius: 12,
            y: 6
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Selection Button

struct CapsuleSelectionButton<T: Equatable>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let value: T
    @Binding var selection: T
    
    @State private var isHovered = false
    
    var isSelected: Bool {
        selection == value
    }
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String,
        value: T,
        selection: Binding<T>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.value = value
        self._selection = selection
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = value
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                    }
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected ?
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) :
                        AnyShapeStyle(Color.gray.opacity(0.05))
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? .blue.opacity(0.3) : .clear,
            radius: 12,
            y: 6
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 20) {
        CapsuleButton("Primary Button", icon: "arrow.right", style: .primary) {}
        CapsuleButton("Secondary Button", icon: "gear", style: .secondary) {}
        CapsuleButton("Destructive Button", icon: "trash", style: .destructive) {}
        CapsuleButton("Success Button", icon: "checkmark", style: .success) {}
        CapsuleButton("Warning Button", icon: "exclamationmark.triangle", style: .warning) {}
        CapsuleButton("Ghost Button", icon: "link", style: .ghost) {}
        CapsuleButton("Outline Button", icon: "square.and.arrow.up", style: .outline) {}
        CapsuleButton("Disabled Button", style: .primary, isEnabled: false) {}
        CapsuleButton("Loading Button", style: .primary, isLoading: true) {}
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Button Group") {
    VStack(spacing: 30) {
        CapsuleButtonGroup(buttons: [
            .init("Cancel", style: .secondary) {},
            .init("Save", icon: "checkmark", style: .primary) {}
        ])
        
        CapsuleButtonGroup(
            buttons: [
                .init("Delete", icon: "trash", style: .destructive) {},
                .init("Archive", icon: "archivebox", style: .secondary) {},
                .init("Share", icon: "square.and.arrow.up", style: .outline) {}
            ],
            axis: .vertical
        )
    }
    .padding(40)
    .frame(width: 400)
}
