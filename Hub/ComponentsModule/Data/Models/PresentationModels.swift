import Foundation
import SwiftUI
import Combine

// MARK: - Presentation Types

enum PresentationType: Codable {
    case navigation // Push to navigation stack
    case sheet // Present as sheet
    case fullScreenCover // Present full screen
    case alert // Show alert dialog
    case confirmationDialog // Show action sheet
    case popover // Show popover (macOS)
}

// MARK: - Tab Bar Configuration

struct TabBarConfiguration: Codable, Identifiable, Sendable {
    var id = UUID()
    var tabs: [TabItem]
    var accentColor: String?
    
    struct TabItem: Codable, Identifiable, Sendable {
        var id = UUID()
        var title: String
        var icon: String
        var screenID: UUID
        var badge: String?
    }
}

// MARK: - Alert Configuration

struct AlertConfiguration: Codable, Identifiable {
    var id = UUID()
    var title: String
    var message: String
    var buttons: [AlertButton]
    
    struct AlertButton: Codable, Identifiable {
        var id = UUID()
        var title: String
        var role: ButtonRole
        var action: String
        
        enum ButtonRole: String, Codable {
            case cancel
            case destructive
            case `default`
        }
    }
}

// MARK: - Action Sheet Configuration

struct ActionSheetConfiguration: Codable, Identifiable {
    var id = UUID()
    var title: String
    var message: String?
    var buttons: [ActionButton]
    
    struct ActionButton: Codable, Identifiable {
        var id = UUID()
        var title: String
        var role: ButtonRole
        var action: String
        
        enum ButtonRole: String, Codable {
            case cancel
            case destructive
            case `default`
        }
    }
}

// MARK: - Enhanced Visual Screen

extension VisualScreen {
    var presentationType: PresentationType {
        get {
            // Default to navigation
            return .navigation
        }
    }
    
    var tabBarItem: TabBarConfiguration.TabItem? {
        get {
            // Return tab bar item if this screen is in a tab bar
            return nil
        }
    }
}

// MARK: - Enhanced Button Actions

enum ButtonAction: Codable {
    case custom(name: String)
    case navigate(screenID: UUID, type: PresentationType)
    case dismiss
    case showAlert(AlertConfiguration)
    case showActionSheet(ActionSheetConfiguration)
    case openURL(String)
    
    var actionName: String {
        switch self {
        case .custom(let name):
            return name
        case .navigate(let screenID, _):
            return "navigateTo_\(screenID.uuidString.prefix(8))"
        case .dismiss:
            return "dismiss"
        case .showAlert:
            return "showAlert"
        case .showActionSheet:
            return "showActionSheet"
        case .openURL:
            return "openURL"
        }
    }
}

// MARK: - App Structure Type

enum AppStructureType: String, Codable, CaseIterable {
    case singleScreen = "Single Screen"
    case navigation = "Navigation Stack"
    case tabBar = "Tab Bar"
    case tabBarWithNavigation = "Tab Bar + Navigation"
    
    var description: String {
        switch self {
        case .singleScreen:
            return "Simple single-screen app"
        case .navigation:
            return "Navigation-based app with push/pop"
        case .tabBar:
            return "Tab bar with multiple sections"
        case .tabBarWithNavigation:
            return "Tab bar where each tab has navigation"
        }
    }
    
    var icon: String {
        switch self {
        case .singleScreen:
            return "rectangle"
        case .navigation:
            return "arrow.right"
        case .tabBar:
            return "square.split.bottomrightquarter"
        case .tabBarWithNavigation:
            return "square.stack.3d.down.right"
        }
    }
}

// MARK: - Enhanced Template Model Extension

extension TemplateModel {
    var appStructure: AppStructureType {
        get {
            // Determine structure from screens
            if visualScreens.count <= 1 {
                return .singleScreen
            }
            
            // Check if there's a tab bar configuration
            if tabBarConfiguration != nil {
                return .tabBarWithNavigation
            }
            
            return .navigation
        }
    }
    
    var tabBarConfiguration: TabBarConfiguration? {
        get {
            // Decode from data if exists
            guard let data = tabBarConfigData else { return nil }
            return try? JSONDecoder().decode(TabBarConfiguration.self, from: data)
        }
        set {
            tabBarConfigData = try? JSONEncoder().encode(newValue)
        }
    }
    
    private var tabBarConfigData: Data? {
        get {
            // This would be stored in the model
            return nil
        }
        set {
            // This would be stored in the model
        }
    }
}

// MARK: - Presentation State Manager

class PresentationStateManager: ObservableObject {
    @Published var activeSheet: UUID?
    @Published var activeFullScreenCover: UUID?
    @Published var activeAlert: AlertConfiguration?
    @Published var activeActionSheet: ActionSheetConfiguration?
    @Published var navigationPath: [UUID] = []
    
    func present(_ screenID: UUID, type: PresentationType) {
        switch type {
        case .navigation:
            navigationPath.append(screenID)
        case .sheet:
            activeSheet = screenID
        case .fullScreenCover:
            activeFullScreenCover = screenID
        case .alert, .confirmationDialog, .popover:
            break // Handled separately
        }
    }
    
    func dismiss() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        activeSheet = nil
        activeFullScreenCover = nil
    }
    
    func showAlert(_ config: AlertConfiguration) {
        activeAlert = config
    }
    
    func showActionSheet(_ config: ActionSheetConfiguration) {
        activeActionSheet = config
    }
}

// MARK: - Animation Configuration

struct AnimationConfiguration: Codable {
    var type: AnimationType
    var duration: Double
    var delay: Double
    
    enum AnimationType: String, Codable, CaseIterable {
        case none
        case fade
        case slide
        case scale
        case spring
        case easeIn
        case easeOut
        case easeInOut
        
        func swiftUIAnimation(duration: Double) -> String {
            switch self {
            case .none:
                return "nil"
            case .fade:
                return ".easeInOut(duration: \(duration))"
            case .slide:
                return ".easeInOut(duration: \(duration))"
            case .scale:
                return ".spring(response: \(duration), dampingFraction: 0.8)"
            case .spring:
                return ".spring()"
            case .easeIn:
                return ".easeIn(duration: \(duration))"
            case .easeOut:
                return ".easeOut(duration: \(duration))"
            case .easeInOut:
                return ".easeInOut(duration: \(duration))"
            }
        }
    }
}

// MARK: - Transition Configuration

struct TransitionConfiguration: Codable {
    var type: TransitionType
    var edge: Edge?
    
    enum TransitionType: String, Codable, CaseIterable {
        case opacity
        case scale
        case slide
        case move
        case offset
        case identity
        
        var description: String {
            switch self {
            case .opacity:
                return "Fade in/out"
            case .scale:
                return "Scale up/down"
            case .slide:
                return "Slide from edge"
            case .move:
                return "Move from edge"
            case .offset:
                return "Offset position"
            case .identity:
                return "No transition"
            }
        }
    }
    
    enum Edge: String, Codable, CaseIterable {
        case top, bottom, leading, trailing
    }
    
    func toSwiftUI() -> String {
        switch type {
        case .opacity:
            return ".opacity"
        case .scale:
            return ".scale"
        case .slide:
            if let _ = edge {
                return ".slide"
            }
            return ".slide"
        case .move:
            if let edge = edge {
                return ".move(edge: .\(edge.rawValue))"
            }
            return ".move(edge: .leading)"
        case .offset:
            return ".offset(x: 100, y: 0)"
        case .identity:
            return ".identity"
        }
    }
}
