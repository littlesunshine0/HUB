//
//  ComponentLibrary.swift
//  Hub
//
//  Central registry for all reusable components
//  Components are used by both Templates and Hubs
//

import SwiftUI

// MARK: - Component Library

/// Central registry of all reusable UI components
/// These components are the building blocks for Templates and Hubs
public class ComponentLibrary {
    public static let shared = ComponentLibrary()
    
    private init() {}
    
    // MARK: - Component Categories
    
    /// All available button components
    public var buttons: [ComponentDefinition] {
        [
            ComponentDefinition(
                id: "primary-button",
                name: "Primary Button",
                category: .button,
                description: "Main action button with theme colors",
                previewImage: "button.primary"
            ),
            ComponentDefinition(
                id: "secondary-button",
                name: "Secondary Button",
                category: .button,
                description: "Secondary action button",
                previewImage: "button.secondary"
            ),
            ComponentDefinition(
                id: "icon-button",
                name: "Icon Button",
                category: .button,
                description: "Button with icon only",
                previewImage: "button.icon"
            )
        ]
    }
    
    /// All available card components
    public var cards: [ComponentDefinition] {
        [
            ComponentDefinition(
                id: "info-card",
                name: "Info Card",
                category: .card,
                description: "Card for displaying information",
                previewImage: "card.info"
            ),
            ComponentDefinition(
                id: "credit-card",
                name: "Credit Card",
                category: .card,
                description: "Credit card display component",
                previewImage: "card.credit"
            )
        ]
    }
    
    /// All available input components
    public var inputs: [ComponentDefinition] {
        [
            ComponentDefinition(
                id: "text-field",
                name: "Text Field",
                category: .input,
                description: "Styled text input field",
                previewImage: "textfield"
            )
        ]
    }
    
    /// All available layout components
    public var layouts: [ComponentDefinition] {
        [
            ComponentDefinition(
                id: "carousel",
                name: "Carousel",
                category: .layout,
                description: "Scrollable carousel component",
                previewImage: "carousel"
            )
        ]
    }
    
    // MARK: - Query Methods
    
    /// Get all components
    public func getAllComponents() -> [ComponentDefinition] {
        buttons + cards + inputs + layouts
    }
    
    /// Get components by category
    public func getComponents(for category: ComponentCategory) -> [ComponentDefinition] {
        getAllComponents().filter { $0.category == category }
    }
    
    /// Get component by ID
    public func getComponent(id: String) -> ComponentDefinition? {
        getAllComponents().first { $0.id == id }
    }
    
    /// Search components
    public func searchComponents(query: String) -> [ComponentDefinition] {
        let lowercased = query.lowercased()
        return getAllComponents().filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        }
    }
}

// MARK: - Component Definition

/// Defines a reusable component that can be used in Templates and Hubs
public struct ComponentDefinition: Identifiable, Codable {
    public let id: String
    public let name: String
    public let category: ComponentCategory
    public let description: String
    public let previewImage: String
    public var tags: [String] = []
    public var usageCount: Int = 0
    
    public init(
        id: String,
        name: String,
        category: ComponentCategory,
        description: String,
        previewImage: String,
        tags: [String] = [],
        usageCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.previewImage = previewImage
        self.tags = tags
        self.usageCount = usageCount
    }
}

// MARK: - Component Category

/// Categories for organizing components
public enum ComponentCategory: String, Codable, CaseIterable {
    case button = "Button"
    case card = "Card"
    case input = "Input"
    case layout = "Layout"
    case navigation = "Navigation"
    case display = "Display"
    case feedback = "Feedback"
    case media = "Media"
    
    public var icon: String {
        switch self {
        case .button: return "button.programmable"
        case .card: return "rectangle.on.rectangle"
        case .input: return "textformat"
        case .layout: return "square.grid.2x2"
        case .navigation: return "arrow.left.arrow.right"
        case .display: return "eye"
        case .feedback: return "bell"
        case .media: return "photo"
        }
    }
}

// MARK: - Component Usage Tracking

extension ComponentLibrary {
    /// Track component usage (called when component is added to template/hub)
    public func trackUsage(componentId: String) {
        // This would update usage statistics
        // Could be persisted to track popular components
    }
    
    /// Get most used components
    public func getMostUsedComponents(limit: Int = 10) -> [ComponentDefinition] {
        getAllComponents()
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(limit)
            .map { $0 }
    }
}
