//
//  TouchSystem.swift
//  Hub
//
//  Enhanced touchscreen interface system optimized for touch interactions
//

import SwiftUI
import Combine

// MARK: - Touch Interface Manager

@MainActor
public class TouchInterfaceManager: ObservableObject {
    public static let shared = TouchInterfaceManager()
    
    @Published public var isEnabled = true
    @Published public var touchMode: TouchMode = .standard
    @Published public var touchSize: TouchSize = .medium
    @Published public var hapticEnabled = true
    @Published public var touchHistory: [TouchEvent] = []
    
    private let maxHistoryCount = 100
    
    private init() {}
    
    // MARK: - Touch Modes
    
    public enum TouchMode {
        case standard      // Normal touch interactions
        case precise       // Smaller touch targets for precision
        case accessible    // Larger touch targets for accessibility
        case oneHanded     // Optimized for one-handed use
        
        public var minimumTouchSize: CGFloat {
            switch self {
            case .standard: return 44
            case .precise: return 32
            case .accessible: return 60
            case .oneHanded: return 50
            }
        }
        
        public var description: String {
            switch self {
            case .standard: return "Standard touch mode"
            case .precise: return "Precise touch mode for detailed work"
            case .accessible: return "Accessible mode with larger targets"
            case .oneHanded: return "One-handed mode"
            }
        }
    }
    
    // MARK: - Touch Sizes
    
    public enum TouchSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "Extra Large"
        
        public var multiplier: CGFloat {
            switch self {
            case .small: return 0.85
            case .medium: return 1.0
            case .large: return 1.15
            case .extraLarge: return 1.3
            }
        }
    }
    
    // MARK: - Touch Event Tracking
    
    public func recordTouch(_ event: TouchEvent) {
        touchHistory.insert(event, at: 0)
        if touchHistory.count > maxHistoryCount {
            touchHistory.removeLast()
        }
        
        if hapticEnabled {
            provideHapticFeedback(for: event.type)
        }
    }
    
    private func provideHapticFeedback(for type: TouchEventType) {
        #if os(iOS)
        switch type {
        case .tap:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .longPress:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .swipe:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .drag:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        #endif
    }
}

// MARK: - Touch Event

public struct TouchEvent {
    public let id: UUID
    public let type: TouchEventType
    public let location: CGPoint
    public let timestamp: Date
    public let duration: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        type: TouchEventType,
        location: CGPoint,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.location = location
        self.timestamp = timestamp
        self.duration = duration
    }
}

public enum TouchEventType {
    case tap
    case longPress
    case swipe
    case drag
}

// MARK: - Touch Target

public struct TouchTarget {
    public let minimumSize: CGSize
    public let padding: EdgeInsets
    public let shape: TouchShape
    
    public enum TouchShape {
        case rectangle
        case circle
        case roundedRectangle(cornerRadius: CGFloat)
    }
    
    public init(
        minimumSize: CGSize = CGSize(width: 44, height: 44),
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        shape: TouchShape = .roundedRectangle(cornerRadius: 8)
    ) {
        self.minimumSize = minimumSize
        self.padding = padding
        self.shape = shape
    }
    
    public static let standard = TouchTarget()
    public static let large = TouchTarget(
        minimumSize: CGSize(width: 60, height: 60),
        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
    )
    public static let small = TouchTarget(
        minimumSize: CGSize(width: 32, height: 32),
        padding: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    )
}

// MARK: - Touch Feedback

public enum TouchFeedback {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
    
    #if os(iOS)
    public func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    #else
    public func trigger() {
        // macOS doesn't have haptic feedback
    }
    #endif
}
