import Foundation
import SwiftUI

// MARK: - Pattern Category

/// Categories for organizing design patterns
public enum PatternCategory: String, CaseIterable {
    case basic = "Basic"
    case advancedUI = "Advanced UI"
    case dashboard = "Dashboard"
    case forms = "Forms"
    case social = "Social"
    
    var icon: String {
        switch self {
        case .basic: return "square.stack.3d.up"
        case .advancedUI: return "rectangle.3.group"
        case .dashboard: return "chart.bar.fill"
        case .forms: return "list.bullet.rectangle"
        case .social: return "person.2.fill"
        }
    }
}

// MARK: - Design Pattern Enum

/// Enumeration of all available compound design patterns
public enum DesignPattern: String, Codable, CaseIterable {
    case card = "Card"
    case listCell = "ListCell"
    case carousel = "Carousel"
    case formStack = "FormStack"
    case modalSheet = "ModalSheet"
    case iconBadge = "IconBadge"
    
    // Advanced UI Patterns
    case profileHeader = "ProfileHeader"
    case settingsRow = "SettingsRow"
    case tabBar = "TabBar"
    case searchBar = "SearchBar"
    case navigationHeader = "NavigationHeader"
    case statCard = "StatCard"
    case imageGallery = "ImageGallery"
    case actionSheet = "ActionSheet"
    
    // Dashboard & Analytics Patterns
    case chartCard = "ChartCard"
    case metricGrid = "MetricGrid"
    case progressBar = "ProgressBar"
    case timeline = "Timeline"
    case kpiDashboard = "KPIDashboard"
    case filterBar = "FilterBar"
    
    // Form & Input Patterns
    case loginForm = "LoginForm"
    case registrationForm = "RegistrationForm"
    case dateTimePicker = "DateTimePicker"
    case dropdownMenu = "DropdownMenu"
    case multiSelect = "MultiSelect"
    case ratingInput = "RatingInput"
    
    // Social & Content Patterns
    case commentCell = "CommentCell"
    case feedCard = "FeedCard"
    case userProfile = "UserProfile"
    case notification = "Notification"
    case mediaPlayer = "MediaPlayer"
    
    /// Returns the pattern definition for this pattern type
    public var definition: PatternDefinition {
        PatternLibrary.shared.definition(for: self)
    }
    
    /// Returns the category this pattern belongs to
    public var category: PatternCategory {
        switch self {
        case .card, .listCell, .carousel, .formStack, .modalSheet, .iconBadge:
            return .basic
        case .profileHeader, .settingsRow, .tabBar, .searchBar, .navigationHeader, .statCard, .imageGallery, .actionSheet:
            return .advancedUI
        case .chartCard, .metricGrid, .progressBar, .timeline, .kpiDashboard, .filterBar:
            return .dashboard
        case .loginForm, .registrationForm, .dateTimePicker, .dropdownMenu, .multiSelect, .ratingInput:
            return .forms
        case .commentCell, .feedCard, .userProfile, .notification, .mediaPlayer:
            return .social
        }
    }
}

// MARK: - Pattern Definition

/// Complete definition of a design pattern including metadata and component recipe
public struct PatternDefinition: Identifiable {
    public let id: String
    public let pattern: DesignPattern
    public let name: String
    public let icon: String
    public let description: String
    public let recipe: RenderableComponent
    
    public init(
        pattern: DesignPattern,
        name: String,
        icon: String,
        description: String,
        recipe: RenderableComponent
    ) {
        self.id = pattern.rawValue
        self.pattern = pattern
        self.name = name
        self.icon = icon
        self.description = description
        self.recipe = recipe
    }
}

// MARK: - Pattern Library

/// Singleton registry providing access to all design pattern definitions
public class PatternLibrary {
    public static let shared = PatternLibrary()
    
    private let definitions: [DesignPattern: PatternDefinition]
    
    private init() {
        self.definitions = Self.createDefinitions()
    }
    
    /// Returns the definition for a specific pattern
    public func definition(for pattern: DesignPattern) -> PatternDefinition {
        definitions[pattern]!
    }
    
    /// Returns all pattern definitions sorted by name
    public func allDefinitions() -> [PatternDefinition] {
        Array(definitions.values).sorted { $0.name < $1.name }
    }
    
    // MARK: - Pattern Factory Methods
    
    private static func createDefinitions() -> [DesignPattern: PatternDefinition] {
        var defs: [DesignPattern: PatternDefinition] = [:]
        
        defs[.card] = PatternDefinition(
            pattern: .card,
            name: "Card",
            icon: "rectangle.on.rectangle",
            description: "A card layout with image, title, subtitle, and description",
            recipe: createCardPattern()
        )
        
        defs[.listCell] = PatternDefinition(
            pattern: .listCell,
            name: "List Cell",
            icon: "list.bullet.rectangle",
            description: "A list cell with icon, title, detail, and chevron",
            recipe: createListCellPattern()
        )
        
        defs[.carousel] = PatternDefinition(
            pattern: .carousel,
            name: "Carousel",
            icon: "rectangle.stack",
            description: "A horizontal scrolling carousel with multiple items",
            recipe: createCarouselPattern()
        )
        
        defs[.formStack] = PatternDefinition(
            pattern: .formStack,
            name: "Form Stack",
            icon: "list.bullet.rectangle.fill",
            description: "A form with title, text fields, toggle, and submit button",
            recipe: createFormStackPattern()
        )
        
        defs[.modalSheet] = PatternDefinition(
            pattern: .modalSheet,
            name: "Modal Sheet",
            icon: "rectangle.portrait.bottomhalf.filled",
            description: "A modal sheet with close button, title, content, and action button",
            recipe: createModalSheetPattern()
        )
        
        defs[.iconBadge] = PatternDefinition(
            pattern: .iconBadge,
            name: "Icon Badge",
            icon: "circle.hexagongrid.fill",
            description: "An icon badge with circular background",
            recipe: createIconBadgePattern()
        )
        
        // Advanced UI Patterns
        defs[.profileHeader] = PatternDefinition(
            pattern: .profileHeader,
            name: "Profile Header",
            icon: "person.crop.circle",
            description: "Profile header with avatar, name, and bio layout",
            recipe: createProfileHeaderPattern()
        )
        
        defs[.settingsRow] = PatternDefinition(
            pattern: .settingsRow,
            name: "Settings Row",
            icon: "gearshape.fill",
            description: "Settings row with label, value, and chevron",
            recipe: createSettingsRowPattern()
        )
        
        defs[.tabBar] = PatternDefinition(
            pattern: .tabBar,
            name: "Tab Bar",
            icon: "square.split.bottomrightquarter",
            description: "Bottom navigation tab bar with icons",
            recipe: createTabBarPattern()
        )
        
        defs[.searchBar] = PatternDefinition(
            pattern: .searchBar,
            name: "Search Bar",
            icon: "magnifyingglass",
            description: "Search bar with icon and clear button",
            recipe: createSearchBarPattern()
        )
        
        defs[.navigationHeader] = PatternDefinition(
            pattern: .navigationHeader,
            name: "Navigation Header",
            icon: "arrow.left.circle",
            description: "Navigation header with back button, title, and actions",
            recipe: createNavigationHeaderPattern()
        )
        
        defs[.statCard] = PatternDefinition(
            pattern: .statCard,
            name: "Stat Card",
            icon: "chart.bar.fill",
            description: "Stat card with icon, metric, label, and trend indicator",
            recipe: createStatCardPattern()
        )
        
        defs[.imageGallery] = PatternDefinition(
            pattern: .imageGallery,
            name: "Image Gallery",
            icon: "photo.on.rectangle.angled",
            description: "Grid layout with image placeholders",
            recipe: createImageGalleryPattern()
        )
        
        defs[.actionSheet] = PatternDefinition(
            pattern: .actionSheet,
            name: "Action Sheet",
            icon: "list.bullet.rectangle.portrait",
            description: "Modal bottom sheet with action buttons",
            recipe: createActionSheetPattern()
        )
        
        // Dashboard & Analytics Patterns
        defs[.chartCard] = PatternDefinition(
            pattern: .chartCard,
            name: "Chart Card",
            icon: "chart.bar.doc.horizontal",
            description: "Chart card with title, chart placeholder, and legend",
            recipe: createChartCardPattern()
        )
        
        defs[.metricGrid] = PatternDefinition(
            pattern: .metricGrid,
            name: "Metric Grid",
            icon: "square.grid.2x2",
            description: "2x2 grid of stat cards with metrics",
            recipe: createMetricGridPattern()
        )
        
        defs[.progressBar] = PatternDefinition(
            pattern: .progressBar,
            name: "Progress Bar",
            icon: "chart.bar.xaxis",
            description: "Progress bar with label and percentage",
            recipe: createProgressBarPattern()
        )
        
        defs[.timeline] = PatternDefinition(
            pattern: .timeline,
            name: "Timeline",
            icon: "timeline.selection",
            description: "Vertical timeline with date markers and events",
            recipe: createTimelinePattern()
        )
        
        defs[.kpiDashboard] = PatternDefinition(
            pattern: .kpiDashboard,
            name: "KPI Dashboard",
            icon: "gauge.with.dots.needle.67percent",
            description: "Hero metric with trend and supporting metrics",
            recipe: createKPIDashboardPattern()
        )
        
        defs[.filterBar] = PatternDefinition(
            pattern: .filterBar,
            name: "Filter Bar",
            icon: "line.3.horizontal.decrease.circle",
            description: "Horizontal scrolling filter chips",
            recipe: createFilterBarPattern()
        )
        
        // Form & Input Patterns
        defs[.loginForm] = PatternDefinition(
            pattern: .loginForm,
            name: "Login Form",
            icon: "person.crop.circle.badge.checkmark",
            description: "Login form with username, password, submit, and forgot password",
            recipe: createLoginFormPattern()
        )
        
        defs[.registrationForm] = PatternDefinition(
            pattern: .registrationForm,
            name: "Registration Form",
            icon: "person.crop.circle.badge.plus",
            description: "Multi-field registration form with validation indicators",
            recipe: createRegistrationFormPattern()
        )
        
        defs[.dateTimePicker] = PatternDefinition(
            pattern: .dateTimePicker,
            name: "Date Time Picker",
            icon: "calendar.badge.clock",
            description: "Date and time selection with calendar icon",
            recipe: createDateTimePickerPattern()
        )
        
        defs[.dropdownMenu] = PatternDefinition(
            pattern: .dropdownMenu,
            name: "Dropdown Menu",
            icon: "chevron.down.circle",
            description: "Dropdown menu with button and menu items",
            recipe: createDropdownMenuPattern()
        )
        
        defs[.multiSelect] = PatternDefinition(
            pattern: .multiSelect,
            name: "Multi Select",
            icon: "checklist",
            description: "Multi-select with checkboxes, select all, and done button",
            recipe: createMultiSelectPattern()
        )
        
        defs[.ratingInput] = PatternDefinition(
            pattern: .ratingInput,
            name: "Rating Input",
            icon: "star.fill",
            description: "Star rating input with label",
            recipe: createRatingInputPattern()
        )
        
        // Social & Content Patterns
        defs[.commentCell] = PatternDefinition(
            pattern: .commentCell,
            name: "Comment Cell",
            icon: "bubble.left.fill",
            description: "Comment cell with avatar, name, timestamp, text, and actions",
            recipe: createCommentCellPattern()
        )
        
        defs[.feedCard] = PatternDefinition(
            pattern: .feedCard,
            name: "Feed Card",
            icon: "photo.on.rectangle",
            description: "Social feed card with header, image, caption, and engagement metrics",
            recipe: createFeedCardPattern()
        )
        
        defs[.userProfile] = PatternDefinition(
            pattern: .userProfile,
            name: "User Profile",
            icon: "person.crop.rectangle",
            description: "User profile with cover photo, avatar, stats, and bio",
            recipe: createUserProfilePattern()
        )
        
        defs[.notification] = PatternDefinition(
            pattern: .notification,
            name: "Notification",
            icon: "bell.fill",
            description: "Notification with icon, title, body, timestamp, and action",
            recipe: createNotificationPattern()
        )
        
        defs[.mediaPlayer] = PatternDefinition(
            pattern: .mediaPlayer,
            name: "Media Player",
            icon: "play.rectangle.fill",
            description: "Media player with thumbnail, controls, progress, and metadata",
            recipe: createMediaPlayerPattern()
        )
        
        return defs
    }
    
    // MARK: - Card Pattern
    
    private static func createCardPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Header with image and title/subtitle
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "photo",
                            size: 40,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        ),
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Title",
                                    fontSize: 18,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Subtitle",
                                    fontSize: 14,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Divider
                .divider(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                // Description
                .text(
                    id: UUID(),
                    content: "Description text goes here. This is a sample card component with multiple elements.",
                    fontSize: 14,
                    fontWeight: .regular,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16,
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 8,
                    x: 0,
                    y: 2
                )
            )
        )
    }
    
    // MARK: - List Cell Pattern
    
    private static func createListCellPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Leading icon
                .image(
                    id: UUID(),
                    systemName: "circle.fill",
                    size: 24,
                    color: "#007AFF",
                    modifiers: ComponentModifiers()
                ),
                // Title and detail
                .vstack(
                    id: UUID(),
                    spacing: 2,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Item Title",
                            fontSize: 16,
                            fontWeight: .medium,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        .text(
                            id: UUID(),
                            content: "Detail text",
                            fontSize: 12,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Spacer
                .spacer(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                // Trailing chevron
                .image(
                    id: UUID(),
                    systemName: "chevron.right",
                    size: 14,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 12
            )
        )
    }
    
    // MARK: - Carousel Pattern
    
    private static func createCarouselPattern() -> RenderableComponent {
        .scrollView(
            id: UUID(),
            axis: .horizontal,
            children: [
                .hstack(
                    id: UUID(),
                    spacing: 16,
                    children: [
                        .rectangle(
                            id: UUID(),
                            width: 200,
                            height: 150,
                            color: "#007AFF",
                            cornerRadius: 12,
                            modifiers: ComponentModifiers()
                        ),
                        .rectangle(
                            id: UUID(),
                            width: 200,
                            height: 150,
                            color: "#34C759",
                            cornerRadius: 12,
                            modifiers: ComponentModifiers()
                        ),
                        .rectangle(
                            id: UUID(),
                            width: 200,
                            height: 150,
                            color: "#FF9500",
                            cornerRadius: 12,
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers()
        )
    }
    
    // MARK: - Form Stack Pattern
    
    private static func createFormStackPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Form title
                .text(
                    id: UUID(),
                    content: "Form Title",
                    fontSize: 20,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Name field
                .textField(
                    id: UUID(),
                    placeholder: "Name",
                    binding: "name",
                    modifiers: ComponentModifiers()
                ),
                // Email field
                .textField(
                    id: UUID(),
                    placeholder: "Email",
                    binding: "email",
                    modifiers: ComponentModifiers()
                ),
                // Subscribe toggle
                .toggle(
                    id: UUID(),
                    label: "Subscribe to newsletter",
                    binding: "subscribe",
                    modifiers: ComponentModifiers()
                ),
                // Submit button
                .button(
                    id: UUID(),
                    title: "Submit",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 20
            )
        )
    }
    
    // MARK: - Modal Sheet Pattern
    
    private static func createModalSheetPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 20,
            children: [
                // Header with close button
                .hstack(
                    id: UUID(),
                    spacing: 0,
                    children: [
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "✕",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Modal title
                .text(
                    id: UUID(),
                    content: "Modal Title",
                    fontSize: 24,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Modal content
                .text(
                    id: UUID(),
                    content: "Modal content goes here. This is a sample modal sheet component.",
                    fontSize: 16,
                    fontWeight: .regular,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Spacer
                .spacer(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                // Done button
                .button(
                    id: UUID(),
                    title: "Done",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 24
            )
        )
    }
    
    // MARK: - Icon Badge Pattern
    
    private static func createIconBadgePattern() -> RenderableComponent {
        .zstack(
            id: UUID(),
            children: [
                // Background circle
                .circle(
                    id: UUID(),
                    size: 60,
                    color: "#007AFF",
                    modifiers: ComponentModifiers()
                ),
                // Icon
                .image(
                    id: UUID(),
                    systemName: "star.fill",
                    size: 30,
                    color: "#FFFFFF",
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers()
        )
    }
    
    // MARK: - Profile Header Pattern
    
    private static func createProfileHeaderPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Avatar
                .circle(
                    id: UUID(),
                    size: 80,
                    color: "#007AFF",
                    modifiers: ComponentModifiers()
                ),
                // Name
                .text(
                    id: UUID(),
                    content: "John Doe",
                    fontSize: 24,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers()
                ),
                // Bio
                .text(
                    id: UUID(),
                    content: "iOS Developer | Swift Enthusiast",
                    fontSize: 14,
                    fontWeight: .regular,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: 300)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 20
            )
        )
    }
    
    // MARK: - Settings Row Pattern
    
    private static func createSettingsRowPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Label
                .text(
                    id: UUID(),
                    content: "Setting Name",
                    fontSize: 16,
                    fontWeight: .regular,
                    color: "",
                    modifiers: ComponentModifiers()
                ),
                // Spacer
                .spacer(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                // Value
                .text(
                    id: UUID(),
                    content: "Value",
                    fontSize: 16,
                    fontWeight: .regular,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers()
                ),
                // Chevron
                .image(
                    id: UUID(),
                    systemName: "chevron.right",
                    size: 14,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16,
                background: "#FFFFFF"
            )
        )
    }
    
    // MARK: - Tab Bar Pattern
    
    private static func createTabBarPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 0,
            children: [
                // Home Tab
                .vstack(
                    id: UUID(),
                    spacing: 4,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "house.fill",
                            size: 24,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        ),
                        .text(
                            id: UUID(),
                            content: "Home",
                            fontSize: 10,
                            fontWeight: .regular,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Search Tab
                .vstack(
                    id: UUID(),
                    spacing: 4,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "magnifyingglass",
                            size: 24,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        ),
                        .text(
                            id: UUID(),
                            content: "Search",
                            fontSize: 10,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Profile Tab
                .vstack(
                    id: UUID(),
                    spacing: 4,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "person.fill",
                            size: 24,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        ),
                        .text(
                            id: UUID(),
                            content: "Profile",
                            fontSize: 10,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 8,
                background: "#F2F2F7",
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 4,
                    x: 0,
                    y: -2
                )
            )
        )
    }
    
    // MARK: - Search Bar Pattern
    
    private static func createSearchBarPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 8,
            children: [
                // Search icon
                .image(
                    id: UUID(),
                    systemName: "magnifyingglass",
                    size: 16,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers()
                ),
                // Text field
                .textField(
                    id: UUID(),
                    placeholder: "Search",
                    binding: "searchText",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Clear button
                .button(
                    id: UUID(),
                    title: "✕",
                    action: .none,
                    style: .plain,
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 8,
                background: "#F2F2F7",
                cornerRadius: 10
            )
        )
    }
    
    // MARK: - Navigation Header Pattern
    
    private static func createNavigationHeaderPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Back button
                .button(
                    id: UUID(),
                    title: "←",
                    action: .dismiss,
                    style: .plain,
                    modifiers: ComponentModifiers()
                ),
                // Title
                .text(
                    id: UUID(),
                    content: "Screen Title",
                    fontSize: 18,
                    fontWeight: .semibold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Action button
                .button(
                    id: UUID(),
                    title: "⋯",
                    action: .none,
                    style: .plain,
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16,
                background: "#F2F2F7"
            )
        )
    }
    
    // MARK: - Stat Card Pattern
    
    private static func createStatCardPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Icon and trend row
                .hstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "chart.line.uptrend.xyaxis",
                            size: 24,
                            color: "#34C759",
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .text(
                            id: UUID(),
                            content: "+12%",
                            fontSize: 14,
                            fontWeight: .semibold,
                            color: "#34C759",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Metric
                .text(
                    id: UUID(),
                    content: "1,234",
                    fontSize: 32,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Label
                .text(
                    id: UUID(),
                    content: "Total Users",
                    fontSize: 14,
                    fontWeight: .regular,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16,
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 8,
                    x: 0,
                    y: 2
                )
            )
        )
    }
    
    // MARK: - Image Gallery Pattern
    
    private static func createImageGalleryPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 8,
            children: [
                // First row
                .hstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .rectangle(
                            id: UUID(),
                            width: 100,
                            height: 100,
                            color: "#E5E5EA",
                            cornerRadius: 8,
                            modifiers: ComponentModifiers()
                        ),
                        .rectangle(
                            id: UUID(),
                            width: 100,
                            height: 100,
                            color: "#E5E5EA",
                            cornerRadius: 8,
                            modifiers: ComponentModifiers()
                        ),
                        .rectangle(
                            id: UUID(),
                            width: 100,
                            height: 100,
                            color: "#E5E5EA",
                            cornerRadius: 8,
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Second row
                .hstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .rectangle(
                            id: UUID(),
                            width: 100,
                            height: 100,
                            color: "#E5E5EA",
                            cornerRadius: 8,
                            modifiers: ComponentModifiers()
                        ),
                        .rectangle(
                            id: UUID(),
                            width: 100,
                            height: 100,
                            color: "#E5E5EA",
                            cornerRadius: 8,
                            modifiers: ComponentModifiers()
                        ),
                        .rectangle(
                            id: UUID(),
                            width: 100,
                            height: 100,
                            color: "#E5E5EA",
                            cornerRadius: 8,
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16
            )
        )
    }
    
    // MARK: - Action Sheet Pattern
    
    private static func createActionSheetPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 0,
            children: [
                // Handle indicator
                .rectangle(
                    id: UUID(),
                    width: 40,
                    height: 4,
                    color: "#C7C7CC",
                    cornerRadius: 2,
                    modifiers: ComponentModifiers(
                        padding: 12
                    )
                ),
                // Title
                .text(
                    id: UUID(),
                    content: "Choose an action",
                    fontSize: 18,
                    fontWeight: .semibold,
                    color: "",
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                .divider(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                // Action buttons
                .button(
                    id: UUID(),
                    title: "Action 1",
                    action: .none,
                    style: .plain,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                .divider(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                .button(
                    id: UUID(),
                    title: "Action 2",
                    action: .none,
                    style: .plain,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                .divider(
                    id: UUID(),
                    modifiers: ComponentModifiers()
                ),
                .button(
                    id: UUID(),
                    title: "Cancel",
                    action: .dismiss,
                    style: .plain,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity),
                        foregroundColor: "#FF3B30"
                    )
                )
            ],
            modifiers: ComponentModifiers(
                background: "#FFFFFF",
                cornerRadius: 16,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 20,
                    x: 0,
                    y: -4
                )
            )
        )
    }
    
    // MARK: - Chart Card Pattern
    
    private static func createChartCardPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Title
                .text(
                    id: UUID(),
                    content: "Revenue Overview",
                    fontSize: 18,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Chart placeholder
                .rectangle(
                    id: UUID(),
                    width: Double.infinity,
                    height: 200,
                    color: "#F2F2F7",
                    cornerRadius: 8,
                    modifiers: ComponentModifiers()
                ),
                // Legend
                .hstack(
                    id: UUID(),
                    spacing: 16,
                    children: [
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .circle(
                                    id: UUID(),
                                    size: 12,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Series 1",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .circle(
                                    id: UUID(),
                                    size: 12,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Series 2",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16,
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 8,
                    x: 0,
                    y: 2
                )
            )
        )
    }
    
    // MARK: - Metric Grid Pattern
    
    private static func createMetricGridPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 12,
            children: [
                // First row
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Metric 1
                        .vstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "1,234",
                                    fontSize: 24,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Users",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 16,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        ),
                        // Metric 2
                        .vstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "567",
                                    fontSize: 24,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Orders",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 16,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Second row
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Metric 3
                        .vstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "$89K",
                                    fontSize: 24,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Revenue",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 16,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        ),
                        // Metric 4
                        .vstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "92%",
                                    fontSize: 24,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Satisfaction",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 16,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16
            )
        )
    }
    
    // MARK: - Progress Bar Pattern
    
    private static func createProgressBarPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 8,
            children: [
                // Label and percentage row
                .hstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Project Progress",
                            fontSize: 14,
                            fontWeight: .medium,
                            color: "",
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .text(
                            id: UUID(),
                            content: "75%",
                            fontSize: 14,
                            fontWeight: .semibold,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Progress bar
                .zstack(
                    id: UUID(),
                    children: [
                        // Background
                        .rectangle(
                            id: UUID(),
                            width: Double.infinity,
                            height: 8,
                            color: "#E5E5EA",
                            cornerRadius: 4,
                            modifiers: ComponentModifiers()
                        ),
                        // Progress fill
                        .rectangle(
                            id: UUID(),
                            width: 200,
                            height: 8,
                            color: "#007AFF",
                            cornerRadius: 4,
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity, alignment: "leading")
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16
            )
        )
    }
    
    // MARK: - Timeline Pattern
    
    private static func createTimelinePattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 0,
            children: [
                // Timeline item 1
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Timeline marker
                        .vstack(
                            id: UUID(),
                            spacing: 0,
                            children: [
                                .circle(
                                    id: UUID(),
                                    size: 12,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                ),
                                .rectangle(
                                    id: UUID(),
                                    width: 2,
                                    height: 60,
                                    color: "#E5E5EA",
                                    cornerRadius: 1,
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        // Event content
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Event Title",
                                    fontSize: 16,
                                    fontWeight: .semibold,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Event description goes here",
                                    fontSize: 14,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "2 hours ago",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#C7C7CC",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Timeline item 2
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Timeline marker
                        .vstack(
                            id: UUID(),
                            spacing: 0,
                            children: [
                                .circle(
                                    id: UUID(),
                                    size: 12,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                ),
                                .rectangle(
                                    id: UUID(),
                                    width: 2,
                                    height: 60,
                                    color: "#E5E5EA",
                                    cornerRadius: 1,
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        // Event content
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Another Event",
                                    fontSize: 16,
                                    fontWeight: .semibold,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "More details about this event",
                                    fontSize: 14,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Yesterday",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#C7C7CC",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Timeline item 3 (final)
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Timeline marker (no line)
                        .circle(
                            id: UUID(),
                            size: 12,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        ),
                        // Event content
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Past Event",
                                    fontSize: 16,
                                    fontWeight: .semibold,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Historical event details",
                                    fontSize: 14,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Last week",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#C7C7CC",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16
            )
        )
    }
    
    // MARK: - KPI Dashboard Pattern
    
    private static func createKPIDashboardPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 20,
            children: [
                // Hero metric
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Total Revenue",
                            fontSize: 16,
                            fontWeight: .medium,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        ),
                        .text(
                            id: UUID(),
                            content: "$124,567",
                            fontSize: 48,
                            fontWeight: .bold,
                            color: "",
                            modifiers: ComponentModifiers()
                        ),
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .image(
                                    id: UUID(),
                                    systemName: "arrow.up.right",
                                    size: 16,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "+23.5% from last month",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 20,
                        background: "#FFFFFF",
                        cornerRadius: 12,
                        shadow: ShadowModifier(
                            color: "#000000",
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                    )
                ),
                // Supporting metrics
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Metric 1
                        .vstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "4,567",
                                    fontSize: 20,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "New Users",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "+12%",
                                    fontSize: 12,
                                    fontWeight: .semibold,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        ),
                        // Metric 2
                        .vstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "89%",
                                    fontSize: 20,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Conversion",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "+5%",
                                    fontSize: 12,
                                    fontWeight: .semibold,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        ),
                        // Metric 3
                        .vstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "2.4K",
                                    fontSize: 20,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Active",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "+8%",
                                    fontSize: 12,
                                    fontWeight: .semibold,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity), background: "#FFFFFF",
                                cornerRadius: 12,
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16
            )
        )
    }
    
    // MARK: - Filter Bar Pattern
    
    private static func createFilterBarPattern() -> RenderableComponent {
        .scrollView(
            id: UUID(),
            axis: .horizontal,
            children: [
                .hstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        // Filter chip 1 (active)
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "All",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "#FFFFFF",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 10,
                                background: "#007AFF",
                                cornerRadius: 20
                            )
                        ),
                        // Filter chip 2
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Active",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 10,
                                background: "#E5E5EA",
                                cornerRadius: 20
                            )
                        ),
                        // Filter chip 3
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Completed",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 10,
                                background: "#E5E5EA",
                                cornerRadius: 20
                            )
                        ),
                        // Filter chip 4
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Archived",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 10,
                                background: "#E5E5EA",
                                cornerRadius: 20
                            )
                        ),
                        // Filter chip 5
                        .hstack(
                            id: UUID(),
                            spacing: 6,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Favorites",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 10,
                                background: "#E5E5EA",
                                cornerRadius: 20
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 12
            )
        )
    }
    
    // MARK: - Login Form Pattern
    
    private static func createLoginFormPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 20,
            children: [
                // Title
                .text(
                    id: UUID(),
                    content: "Welcome Back",
                    fontSize: 28,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Subtitle
                .text(
                    id: UUID(),
                    content: "Sign in to continue",
                    fontSize: 16,
                    fontWeight: .regular,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Username field
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Username",
                            fontSize: 14,
                            fontWeight: .medium,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        .textField(
                            id: UUID(),
                            placeholder: "Enter your username",
                            binding: "username",
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Password field
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Password",
                            fontSize: 14,
                            fontWeight: .medium,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        .textField(
                            id: UUID(),
                            placeholder: "Enter your password",
                            binding: "password",
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Forgot password link
                .button(
                    id: UUID(),
                    title: "Forgot Password?",
                    action: .none,
                    style: .plain,
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity, alignment: "trailing"),
                        foregroundColor: "#007AFF"
                    )
                ),
                // Sign in button
                .button(
                    id: UUID(),
                    title: "Sign In",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 24
            )
        )
    }
    
    // MARK: - Registration Form Pattern
    
    private static func createRegistrationFormPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 20,
            children: [
                // Title
                .text(
                    id: UUID(),
                    content: "Create Account",
                    fontSize: 28,
                    fontWeight: .bold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Full name field with validation
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .hstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Full Name",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                ),
                                .image(
                                    id: UUID(),
                                    systemName: "checkmark.circle.fill",
                                    size: 16,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .textField(
                            id: UUID(),
                            placeholder: "Enter your full name",
                            binding: "fullName",
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Email field with validation
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .hstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Email",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                ),
                                .image(
                                    id: UUID(),
                                    systemName: "checkmark.circle.fill",
                                    size: 16,
                                    color: "#34C759",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .textField(
                            id: UUID(),
                            placeholder: "Enter your email",
                            binding: "email",
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Password field with validation
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .hstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Password",
                                    fontSize: 14,
                                    fontWeight: .medium,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                ),
                                .image(
                                    id: UUID(),
                                    systemName: "xmark.circle.fill",
                                    size: 16,
                                    color: "#FF3B30",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .textField(
                            id: UUID(),
                            placeholder: "Create a password",
                            binding: "password",
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        ),
                        .text(
                            id: UUID(),
                            content: "Password must be at least 8 characters",
                            fontSize: 12,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Terms and conditions toggle
                .toggle(
                    id: UUID(),
                    label: "I agree to the Terms and Conditions",
                    binding: "agreeToTerms",
                    modifiers: ComponentModifiers()
                ),
                // Create account button
                .button(
                    id: UUID(),
                    title: "Create Account",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 24
            )
        )
    }
    
    // MARK: - Date Time Picker Pattern
    
    private static func createDateTimePickerPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Label
                .text(
                    id: UUID(),
                    content: "Select Date & Time",
                    fontSize: 18,
                    fontWeight: .semibold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Date picker row
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "calendar",
                            size: 24,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        ),
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Date",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "November 10, 2025",
                                    fontSize: 16,
                                    fontWeight: .medium,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .image(
                            id: UUID(),
                            systemName: "chevron.right",
                            size: 14,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 16,
                        background: "#F2F2F7",
                        cornerRadius: 12
                    )
                ),
                // Time picker row
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        .image(
                            id: UUID(),
                            systemName: "clock",
                            size: 24,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        ),
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Time",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "2:30 PM",
                                    fontSize: 16,
                                    fontWeight: .medium,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .image(
                            id: UUID(),
                            systemName: "chevron.right",
                            size: 14,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 16,
                        background: "#F2F2F7",
                        cornerRadius: 12
                    )
                ),
                // Confirm button
                .button(
                    id: UUID(),
                    title: "Confirm",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 20
            )
        )
    }
    
    // MARK: - Dropdown Menu Pattern
    
    private static func createDropdownMenuPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Label
                .text(
                    id: UUID(),
                    content: "Select Option",
                    fontSize: 14,
                    fontWeight: .medium,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Dropdown button
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Choose an option",
                            fontSize: 16,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .image(
                            id: UUID(),
                            systemName: "chevron.down",
                            size: 14,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 12,
                        background: "#F2F2F7",
                        cornerRadius: 8
                    )
                ),
                // Menu items (expanded state)
                .vstack(
                    id: UUID(),
                    spacing: 0,
                    children: [
                        .button(
                            id: UUID(),
                            title: "Option 1",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity, alignment: "leading")
                            )
                        ),
                        .divider(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "Option 2",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity, alignment: "leading")
                            )
                        ),
                        .divider(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "Option 3",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity, alignment: "leading")
                            )
                        ),
                        .divider(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "Option 4",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(maxWidth: Double.infinity, alignment: "leading")
                            )
                        )
                    ],
                    modifiers: ComponentModifiers(
                        background: "#FFFFFF",
                        cornerRadius: 8,
                        shadow: ShadowModifier(
                            color: "#000000",
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 16
            )
        )
    }
    
    // MARK: - Multi Select Pattern
    
    private static func createMultiSelectPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Header with select all
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Select Items",
                            fontSize: 18,
                            fontWeight: .semibold,
                            color: "",
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "Select All",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers(
                                foregroundColor: "#007AFF"
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Checkbox items
                .vstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Item 1 (checked)
                        .hstack(
                            id: UUID(),
                            spacing: 12,
                            children: [
                                .image(
                                    id: UUID(),
                                    systemName: "checkmark.square.fill",
                                    size: 24,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Item 1",
                                    fontSize: 16,
                                    fontWeight: .regular,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        ),
                        // Item 2 (unchecked)
                        .hstack(
                            id: UUID(),
                            spacing: 12,
                            children: [
                                .image(
                                    id: UUID(),
                                    systemName: "square",
                                    size: 24,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Item 2",
                                    fontSize: 16,
                                    fontWeight: .regular,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        ),
                        // Item 3 (checked)
                        .hstack(
                            id: UUID(),
                            spacing: 12,
                            children: [
                                .image(
                                    id: UUID(),
                                    systemName: "checkmark.square.fill",
                                    size: 24,
                                    color: "#007AFF",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Item 3",
                                    fontSize: 16,
                                    fontWeight: .regular,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        ),
                        // Item 4 (unchecked)
                        .hstack(
                            id: UUID(),
                            spacing: 12,
                            children: [
                                .image(
                                    id: UUID(),
                                    systemName: "square",
                                    size: 24,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "Item 4",
                                    fontSize: 16,
                                    fontWeight: .regular,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers(
                                padding: 12,
                                background: "#F2F2F7",
                                cornerRadius: 8
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Done button
                .button(
                    id: UUID(),
                    title: "Done (2 selected)",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 20
            )
        )
    }
    
    // MARK: - Rating Input Pattern
    
    private static func createRatingInputPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Label
                .text(
                    id: UUID(),
                    content: "Rate Your Experience",
                    fontSize: 18,
                    fontWeight: .semibold,
                    color: "",
                    modifiers: ComponentModifiers(
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                ),
                // Star rating
                .hstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        // Star 1 (filled)
                        .image(
                            id: UUID(),
                            systemName: "star.fill",
                            size: 32,
                            color: "#FFD700",
                            modifiers: ComponentModifiers()
                        ),
                        // Star 2 (filled)
                        .image(
                            id: UUID(),
                            systemName: "star.fill",
                            size: 32,
                            color: "#FFD700",
                            modifiers: ComponentModifiers()
                        ),
                        // Star 3 (filled)
                        .image(
                            id: UUID(),
                            systemName: "star.fill",
                            size: 32,
                            color: "#FFD700",
                            modifiers: ComponentModifiers()
                        ),
                        // Star 4 (filled)
                        .image(
                            id: UUID(),
                            systemName: "star.fill",
                            size: 32,
                            color: "#FFD700",
                            modifiers: ComponentModifiers()
                        ),
                        // Star 5 (empty)
                        .image(
                            id: UUID(),
                            systemName: "star",
                            size: 32,
                            color: "#E5E5EA",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Rating text
                .text(
                    id: UUID(),
                    content: "4 out of 5 stars",
                    fontSize: 14,
                    fontWeight: .medium,
                    color: "#8E8E93",
                    modifiers: ComponentModifiers()
                ),
                // Submit button
                .button(
                    id: UUID(),
                    title: "Submit Rating",
                    action: .none,
                    style: .borderedProminent,
                    modifiers: ComponentModifiers(
                        padding: 16,
                        frame: FrameModifier(maxWidth: Double.infinity)
                    )
                )
            ],
            modifiers: ComponentModifiers(
                padding: 20
            )
        )
    }
    
    // MARK: - Comment Cell Pattern
    
    private static func createCommentCellPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Avatar
                .circle(
                    id: UUID(),
                    size: 40,
                    color: "#007AFF",
                    modifiers: ComponentModifiers()
                ),
                // Content
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        // Name and timestamp
                        .hstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "John Doe",
                                    fontSize: 14,
                                    fontWeight: .semibold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "2h ago",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        // Comment text
                        .text(
                            id: UUID(),
                            content: "This is a great post! Thanks for sharing your thoughts on this topic.",
                            fontSize: 14,
                            fontWeight: .regular,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        // Actions
                        .hstack(
                            id: UUID(),
                            spacing: 16,
                            children: [
                                .button(
                                    id: UUID(),
                                    title: "Like",
                                    action: .none,
                                    style: .plain,
                                    modifiers: ComponentModifiers(
                                        foregroundColor: "#8E8E93"
                                    )
                                ),
                                .button(
                                    id: UUID(),
                                    title: "Reply",
                                    action: .none,
                                    style: .plain,
                                    modifiers: ComponentModifiers(
                                        foregroundColor: "#8E8E93"
                                    )
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 12,
                background: "#FFFFFF",
                cornerRadius: 12
            )
        )
    }
    
    // MARK: - Feed Card Pattern
    
    private static func createFeedCardPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 0,
            children: [
                // Header
                .hstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        .circle(
                            id: UUID(),
                            size: 40,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        ),
                        .vstack(
                            id: UUID(),
                            spacing: 2,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Jane Smith",
                                    fontSize: 14,
                                    fontWeight: .semibold,
                                    color: "",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                ),
                                .text(
                                    id: UUID(),
                                    content: "5 minutes ago",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity)
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .spacer(
                            id: UUID(),
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "⋯",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 12
                    )
                ),
                // Image
                .rectangle(
                    id: UUID(),
                    width: Double.infinity,
                    height: 300,
                    color: "#E5E5EA",
                    cornerRadius: 0,
                    modifiers: ComponentModifiers()
                ),
                // Caption and engagement
                .vstack(
                    id: UUID(),
                    spacing: 12,
                    children: [
                        // Engagement metrics
                        .hstack(
                            id: UUID(),
                            spacing: 20,
                            children: [
                                .hstack(
                                    id: UUID(),
                                    spacing: 6,
                                    children: [
                                        .image(
                                            id: UUID(),
                                            systemName: "heart",
                                            size: 20,
                                            color: "#000000",
                                            modifiers: ComponentModifiers()
                                        ),
                                        .text(
                                            id: UUID(),
                                            content: "234",
                                            fontSize: 14,
                                            fontWeight: .medium,
                                            color: "",
                                            modifiers: ComponentModifiers()
                                        )
                                    ],
                                    modifiers: ComponentModifiers()
                                ),
                                .hstack(
                                    id: UUID(),
                                    spacing: 6,
                                    children: [
                                        .image(
                                            id: UUID(),
                                            systemName: "bubble.right",
                                            size: 20,
                                            color: "#000000",
                                            modifiers: ComponentModifiers()
                                        ),
                                        .text(
                                            id: UUID(),
                                            content: "45",
                                            fontSize: 14,
                                            fontWeight: .medium,
                                            color: "",
                                            modifiers: ComponentModifiers()
                                        )
                                    ],
                                    modifiers: ComponentModifiers()
                                ),
                                .hstack(
                                    id: UUID(),
                                    spacing: 6,
                                    children: [
                                        .image(
                                            id: UUID(),
                                            systemName: "paperplane",
                                            size: 20,
                                            color: "#000000",
                                            modifiers: ComponentModifiers()
                                        ),
                                        .text(
                                            id: UUID(),
                                            content: "12",
                                            fontSize: 14,
                                            fontWeight: .medium,
                                            color: "",
                                            modifiers: ComponentModifiers()
                                        )
                                    ],
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        // Caption
                        .text(
                            id: UUID(),
                            content: "Beautiful sunset at the beach today! 🌅 #nature #photography",
                            fontSize: 14,
                            fontWeight: .regular,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 12
                    )
                )
            ],
            modifiers: ComponentModifiers(
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 8,
                    x: 0,
                    y: 2
                )
            )
        )
    }
    
    // MARK: - User Profile Pattern
    
    private static func createUserProfilePattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 0,
            children: [
                // Cover photo
                .rectangle(
                    id: UUID(),
                    width: Double.infinity,
                    height: 150,
                    color: "#007AFF",
                    cornerRadius: 0,
                    modifiers: ComponentModifiers()
                ),
                // Profile info
                .vstack(
                    id: UUID(),
                    spacing: 16,
                    children: [
                        // Avatar (overlapping cover)
                        .circle(
                            id: UUID(),
                            size: 100,
                            color: "#FFFFFF",
                            modifiers: ComponentModifiers(
                                shadow: ShadowModifier(
                                    color: "#000000",
                                    radius: 8,
                                    x: 0,
                                    y: 2
                                )
                            )
                        ),
                        // Name and username
                        .vstack(
                            id: UUID(),
                            spacing: 4,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "Sarah Johnson",
                                    fontSize: 24,
                                    fontWeight: .bold,
                                    color: "",
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "@sarahjohnson",
                                    fontSize: 14,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        // Stats
                        .hstack(
                            id: UUID(),
                            spacing: 24,
                            children: [
                                .vstack(
                                    id: UUID(),
                                    spacing: 4,
                                    children: [
                                        .text(
                                            id: UUID(),
                                            content: "1,234",
                                            fontSize: 18,
                                            fontWeight: .bold,
                                            color: "",
                                            modifiers: ComponentModifiers()
                                        ),
                                        .text(
                                            id: UUID(),
                                            content: "Posts",
                                            fontSize: 12,
                                            fontWeight: .regular,
                                            color: "#8E8E93",
                                            modifiers: ComponentModifiers()
                                        )
                                    ],
                                    modifiers: ComponentModifiers()
                                ),
                                .vstack(
                                    id: UUID(),
                                    spacing: 4,
                                    children: [
                                        .text(
                                            id: UUID(),
                                            content: "5.6K",
                                            fontSize: 18,
                                            fontWeight: .bold,
                                            color: "",
                                            modifiers: ComponentModifiers()
                                        ),
                                        .text(
                                            id: UUID(),
                                            content: "Followers",
                                            fontSize: 12,
                                            fontWeight: .regular,
                                            color: "#8E8E93",
                                            modifiers: ComponentModifiers()
                                        )
                                    ],
                                    modifiers: ComponentModifiers()
                                ),
                                .vstack(
                                    id: UUID(),
                                    spacing: 4,
                                    children: [
                                        .text(
                                            id: UUID(),
                                            content: "892",
                                            fontSize: 18,
                                            fontWeight: .bold,
                                            color: "",
                                            modifiers: ComponentModifiers()
                                        ),
                                        .text(
                                            id: UUID(),
                                            content: "Following",
                                            fontSize: 12,
                                            fontWeight: .regular,
                                            color: "#8E8E93",
                                            modifiers: ComponentModifiers()
                                        )
                                    ],
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        // Bio
                        .text(
                            id: UUID(),
                            content: "Digital creator & photographer 📸\nLove traveling and capturing moments ✨\nBased in San Francisco 🌉",
                            fontSize: 14,
                            fontWeight: .regular,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: 300)
                            )
                        ),
                        // Follow button
                        .button(
                            id: UUID(),
                            title: "Follow",
                            action: .none,
                            style: .borderedProminent,
                            modifiers: ComponentModifiers(
                                padding: 12,
                                frame: FrameModifier(width: 200)
                            )
                        )
                    ],
                    modifiers: ComponentModifiers(
                        padding: 20
                    )
                )
            ],
            modifiers: ComponentModifiers(
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 8,
                    x: 0,
                    y: 2
                )
            )
        )
    }
    
    // MARK: - Notification Pattern
    
    private static func createNotificationPattern() -> RenderableComponent {
        .hstack(
            id: UUID(),
            spacing: 12,
            children: [
                // Icon
                .zstack(
                    id: UUID(),
                    children: [
                        .circle(
                            id: UUID(),
                            size: 40,
                            color: "#007AFF",
                            modifiers: ComponentModifiers()
                        ),
                        .image(
                            id: UUID(),
                            systemName: "bell.fill",
                            size: 20,
                            color: "#FFFFFF",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Content
                .vstack(
                    id: UUID(),
                    spacing: 6,
                    children: [
                        .text(
                            id: UUID(),
                            content: "New Message",
                            fontSize: 16,
                            fontWeight: .semibold,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        .text(
                            id: UUID(),
                            content: "You have a new message from Alex. Tap to view the conversation.",
                            fontSize: 14,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        .text(
                            id: UUID(),
                            content: "5 minutes ago",
                            fontSize: 12,
                            fontWeight: .regular,
                            color: "#C7C7CC",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Action button
                .button(
                    id: UUID(),
                    title: "View",
                    action: .none,
                    style: .bordered,
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 12,
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 4,
                    x: 0,
                    y: 2
                )
            )
        )
    }
    
    // MARK: - Media Player Pattern
    
    private static func createMediaPlayerPattern() -> RenderableComponent {
        .vstack(
            id: UUID(),
            spacing: 16,
            children: [
                // Thumbnail
                .zstack(
                    id: UUID(),
                    children: [
                        .rectangle(
                            id: UUID(),
                            width: Double.infinity,
                            height: 200,
                            color: "#000000",
                            cornerRadius: 12,
                            modifiers: ComponentModifiers()
                        ),
                        .circle(
                            id: UUID(),
                            size: 60,
                            color: "#FFFFFF",
                            modifiers: ComponentModifiers(
                                opacity: 0.9
                            )
                        ),
                        .image(
                            id: UUID(),
                            systemName: "play.fill",
                            size: 30,
                            color: "#000000",
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Progress bar
                .vstack(
                    id: UUID(),
                    spacing: 8,
                    children: [
                        .zstack(
                            id: UUID(),
                            children: [
                                .rectangle(
                                    id: UUID(),
                                    width: Double.infinity,
                                    height: 4,
                                    color: "#E5E5EA",
                                    cornerRadius: 2,
                                    modifiers: ComponentModifiers()
                                ),
                                .rectangle(
                                    id: UUID(),
                                    width: 150,
                                    height: 4,
                                    color: "#007AFF",
                                    cornerRadius: 2,
                                    modifiers: ComponentModifiers(
                                        frame: FrameModifier(maxWidth: Double.infinity, alignment: "leading")
                                    )
                                )
                            ],
                            modifiers: ComponentModifiers()
                        ),
                        .hstack(
                            id: UUID(),
                            spacing: 8,
                            children: [
                                .text(
                                    id: UUID(),
                                    content: "1:23",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                ),
                                .spacer(
                                    id: UUID(),
                                    modifiers: ComponentModifiers()
                                ),
                                .text(
                                    id: UUID(),
                                    content: "3:45",
                                    fontSize: 12,
                                    fontWeight: .regular,
                                    color: "#8E8E93",
                                    modifiers: ComponentModifiers()
                                )
                            ],
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Controls
                .hstack(
                    id: UUID(),
                    spacing: 24,
                    children: [
                        .button(
                            id: UUID(),
                            title: "⏮",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "⏸",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers()
                        ),
                        .button(
                            id: UUID(),
                            title: "⏭",
                            action: .none,
                            style: .plain,
                            modifiers: ComponentModifiers()
                        )
                    ],
                    modifiers: ComponentModifiers()
                ),
                // Metadata
                .vstack(
                    id: UUID(),
                    spacing: 4,
                    children: [
                        .text(
                            id: UUID(),
                            content: "Song Title",
                            fontSize: 18,
                            fontWeight: .semibold,
                            color: "",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        ),
                        .text(
                            id: UUID(),
                            content: "Artist Name",
                            fontSize: 14,
                            fontWeight: .regular,
                            color: "#8E8E93",
                            modifiers: ComponentModifiers(
                                frame: FrameModifier(maxWidth: Double.infinity)
                            )
                        )
                    ],
                    modifiers: ComponentModifiers()
                )
            ],
            modifiers: ComponentModifiers(
                padding: 20,
                background: "#FFFFFF",
                cornerRadius: 12,
                shadow: ShadowModifier(
                    color: "#000000",
                    radius: 8,
                    x: 0,
                    y: 2
                )
            )
        )
    }
}
