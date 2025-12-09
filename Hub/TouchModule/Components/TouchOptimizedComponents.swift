//
//  TouchOptimizedComponents.swift
//  Hub
//
//  Touch-optimized UI components for smartphones and tablets
//

import SwiftUI

// MARK: - Touch Button

public struct TouchButton<Label: View>: View {
    let action: () -> Void
    let feedback: TouchFeedback
    let target: TouchTarget
    @ViewBuilder let label: Label
    
    @State private var isPressed = false
    
    public init(
        action: @escaping () -> Void,
        feedback: TouchFeedback = .light,
        target: TouchTarget = .standard,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.feedback = feedback
        self.target = target
        self.label = label()
    }
    
    public var body: some View {
        Button {
            feedback.trigger()
            action()
        } label: {
            label
                .frame(minWidth: target.minimumSize.width, minHeight: target.minimumSize.height)
                .padding(target.padding)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Touch Card

public struct TouchCard<Content: View>: View {
    let action: (() -> Void)?
    @ViewBuilder let content: Content
    
    @State private var isPressed = false
    
    public init(
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
    }
    
    public var body: some View {
        Group {
            if let action = action {
                Button {
                    TouchFeedback.light.trigger()
                    action()
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
            )
    }
}

// MARK: - Touch List Item

public struct TouchListItem<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content
    
    @State private var isPressed = false
    
    public init(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
    }
    
    public var body: some View {
        Button {
            TouchFeedback.selection.trigger()
            action()
        } label: {
            HStack {
                content
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)
            .padding(.horizontal)
            .background(isPressed ? Color(.selectedControlColor) : Color.clear)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Touch Toggle

public struct TouchToggle: View {
    let label: String
    @Binding var isOn: Bool
    let feedback: TouchFeedback
    
    public init(
        _ label: String,
        isOn: Binding<Bool>,
        feedback: TouchFeedback = .selection
    ) {
        self.label = label
        self._isOn = isOn
        self.feedback = feedback
    }
    
    public var body: some View {
        Button {
            feedback.trigger()
            isOn.toggle()
        } label: {
            HStack {
                Text(label)
                    .font(.body)
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOn ? Color.blue : Color(.separatorColor))
                        .frame(width: 51, height: 31)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 27, height: 27)
                        .offset(x: isOn ? 10 : -10)
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isOn)
    }
}

// MARK: - Touch Slider

public struct TouchSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    public init(
        _ label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1.0
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
                .frame(minHeight: 44)
                .onChange(of: value) { _, _ in
                    TouchFeedback.selection.trigger()
                }
        }
    }
}

// MARK: - Touch Picker

public struct TouchPicker<T: Hashable>: View {
    let label: String
    let options: [T]
    @Binding var selection: T
    let displayName: (T) -> String
    
    @State private var showPicker = false
    
    public init(
        _ label: String,
        options: [T],
        selection: Binding<T>,
        displayName: @escaping (T) -> String
    ) {
        self.label = label
        self.options = options
        self._selection = selection
        self.displayName = displayName
    }
    
    public var body: some View {
        Button {
            TouchFeedback.light.trigger()
            showPicker = true
        } label: {
            HStack {
                Text(label)
                    .font(.body)
                
                Spacer()
                
                Text(displayName(selection))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                List {
                    ForEach(options, id: \.self) { option in
                        Button {
                            TouchFeedback.selection.trigger()
                            selection = option
                            showPicker = false
                        } label: {
                            HStack {
                                Text(displayName(option))
                                Spacer()
                                if option == selection {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(label)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showPicker = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Touch Action Sheet

public struct TouchActionSheet: View {
    let title: String
    let message: String?
    let actions: [TouchAction]
    @Binding var isPresented: Bool
    
    public struct TouchAction {
        let title: String
        let icon: String?
        let role: ActionRole
        let action: () -> Void
        
        public enum ActionRole {
            case normal
            case destructive
            case cancel
        }
        
        public init(
            title: String,
            icon: String? = nil,
            role: ActionRole = .normal,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.role = role
            self.action = action
        }
    }
    
    public init(
        title: String,
        message: String? = nil,
        actions: [TouchAction],
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            
            Divider()
            
            // Actions
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        
                        Button {
                            TouchFeedback.light.trigger()
                            action.action()
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                if let icon = action.icon {
                                    Image(systemName: icon)
                                        .foregroundStyle(action.role == .destructive ? .red : .blue)
                                }
                                
                                Text(action.title)
                                    .foregroundStyle(action.role == .destructive ? .red : .primary)
                                
                                Spacer()
                            }
                            .frame(minHeight: 56)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        
                        if index < actions.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

// MARK: - Touch Floating Action Button

public struct TouchFAB: View {
    let icon: String
    let action: () -> Void
    let position: FABPosition
    
    public enum FABPosition {
        case bottomTrailing
        case bottomLeading
        case topTrailing
        case topLeading
        
        var alignment: Alignment {
            switch self {
            case .bottomTrailing: return .bottomTrailing
            case .bottomLeading: return .bottomLeading
            case .topTrailing: return .topTrailing
            case .topLeading: return .topLeading
            }
        }
    }
    
    @State private var isPressed = false
    
    public init(
        icon: String,
        position: FABPosition = .bottomTrailing,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.position = position
        self.action = action
    }
    
    public var body: some View {
        Button {
            TouchFeedback.medium.trigger()
            action()
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue.gradient)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Touch Bottom Sheet

public struct TouchBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let detents: [PresentationDetent]
    @ViewBuilder let content: Content
    
    public init(
        isPresented: Binding<Bool>,
        detents: [PresentationDetent] = [.medium, .large],
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.content = content()
    }
    
    public var body: some View {
        content
            .presentationDetents(Set(detents))
            .presentationDragIndicator(.visible)
    }
}
