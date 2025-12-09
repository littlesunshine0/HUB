//
//  AnimationSpec.swift
//  Hub
//
//  Created for Hub Onboarding Animation System
//

import SwiftUI

// MARK: - Animation Size

/// Scope of the animation
public enum AnimationSize: String, Codable {
    case fullScreen
    case region
    case element
    
    public var description: String {
        switch self {
        case .fullScreen:
            return "Full screen animation"
        case .region:
            return "Region-scoped animation"
        case .element:
            return "Element-level animation"
        }
    }
}

// MARK: - Visual Behavior

/// Visual behavior step for animations
public struct VisualBehaviorStep: Codable {
    let type: BehaviorType
    let fromValue: Double?
    let toValue: Double?
    let at: TimeInterval?
    let duration: TimeInterval?
    let color: String?
    let intensity: Double?
    let distance: Double?
    let direction: String?
    
    public enum BehaviorType: String, Codable {
        case scale
        case translateX
        case translateY
        case opacity
        case fade
        case glow
        case slideToPosition
        case strokeDraw
        case blur
        case shadow
        case border
        case highlight
        case fillWidth
        case jump
        case checkmark
        case slide
        case tint
        case hidden
        case fadeIn
        case instant
        case gradient
        case orbit
    }
    
    public init(
        type: BehaviorType,
        fromValue: Double? = nil,
        toValue: Double? = nil,
        at: TimeInterval? = nil,
        duration: TimeInterval? = nil,
        color: String? = nil,
        intensity: Double? = nil,
        distance: Double? = nil,
        direction: String? = nil
    ) {
        self.type = type
        self.fromValue = fromValue
        self.toValue = toValue
        self.at = at
        self.duration = duration
        self.color = color
        self.intensity = intensity
        self.distance = distance
        self.direction = direction
    }
}

// MARK: - Reduce Motion Behavior

/// Alternative behavior for reduce motion mode
public struct ReduceMotionBehavior: Codable {
    let replacementSteps: [String: [VisualBehaviorStep]]
    
    public init(replacementSteps: [String: [VisualBehaviorStep]]) {
        self.replacementSteps = replacementSteps
    }
}

// MARK: - Platform Adaptation

/// Platform-specific animation adaptations
public struct PlatformAdaptation: Codable {
    let platform: Platform
    let spec: AnimationSpec?
    let trigger: TriggerType?
    let enabled: Bool
    let condition: String?
    
    public enum Platform: String, Codable {
        case iOS
        case macOS
        case iPad
        case tvOS
        case visionOS
    }
    
    public enum TriggerType: String, Codable {
        case onMouseEnter
        case onTouchDown
        case onFocus
        case onKeyPress
    }
    
    public init(
        platform: Platform,
        spec: AnimationSpec? = nil,
        trigger: TriggerType? = nil,
        enabled: Bool = true,
        condition: String? = nil
    ) {
        self.platform = platform
        self.spec = spec
        self.trigger = trigger
        self.enabled = enabled
        self.condition = condition
    }
}

// MARK: - Animation Spec

/// Complete specification for an animation
public struct AnimationSpec: Codable {
    public let name: String
    public let duration: TimeInterval
    public let easing: AnimationEasing
    public let size: AnimationSize
    public let description: String
    public let visualBehavior: [String: [VisualBehaviorStep]]
    public let reduceMotionBehavior: ReduceMotionBehavior?
    public let platformAdaptations: [PlatformAdaptation]
    public let stagger: TimeInterval?
    public let repeatable: Bool
    
    public init(
        name: String,
        duration: TimeInterval,
        easing: AnimationEasing,
        size: AnimationSize,
        description: String,
        visualBehavior: [String: [VisualBehaviorStep]],
        reduceMotionBehavior: ReduceMotionBehavior? = nil,
        platformAdaptations: [PlatformAdaptation] = [],
        stagger: TimeInterval? = nil,
        repeatable: Bool = false
    ) {
        self.name = name
        self.duration = duration
        self.easing = easing
        self.size = size
        self.description = description
        self.visualBehavior = visualBehavior
        self.reduceMotionBehavior = reduceMotionBehavior
        self.platformAdaptations = platformAdaptations
        self.stagger = stagger
        self.repeatable = repeatable
    }
    
    // MARK: - Computed Properties
    
    /// Check if reduce motion alternative exists
    public var hasReduceMotionAlternative: Bool {
        return reduceMotionBehavior != nil
    }
    
    /// Get animation with duration
    public var animation: Animation {
        return easing.animation(duration: duration)
    }
    
    /// Calculate stagger delays for multiple elements
    func calculateStaggerDelays(for count: Int) -> [TimeInterval] {
        guard let staggerDelay = stagger else {
            return Array(repeating: 0.0, count: count)
        }
        
        return (0..<count).map { index in
            TimeInterval(index) * staggerDelay
        }
    }
    
    /// Get platform-specific adaptation
    func adaptation(for platform: PlatformAdaptation.Platform) -> PlatformAdaptation? {
        return platformAdaptations.first { $0.platform == platform }
    }
    
    /// Check if animation is enabled for platform
    func isEnabled(for platform: PlatformAdaptation.Platform) -> Bool {
        if let adaptation = adaptation(for: platform) {
            return adaptation.enabled
        }
        return true // Default to enabled if no specific adaptation
    }
    
    /// Get visual behavior for element
    func behavior(for element: String) -> [VisualBehaviorStep]? {
        return visualBehavior[element]
    }
    
    /// Get reduce motion behavior for element
    func reduceMotionBehavior(for element: String) -> [VisualBehaviorStep]? {
        return reduceMotionBehavior?.replacementSteps[element]
    }
}

// MARK: - Animation Spec Extensions

extension AnimationSpec {
    /// Create a simple fade animation spec
    static func fade(
        name: String,
        duration: TimeInterval,
        description: String = "Fade animation"
    ) -> AnimationSpec {
        return AnimationSpec(
            name: name,
            duration: duration,
            easing: .easeInOutQuad,
            size: .element,
            description: description,
            visualBehavior: [
                "element": [
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "element": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: duration * 0.5)
                    ]
                ]
            )
        )
    }
    
    /// Create a simple scale animation spec
    static func scale(
        name: String,
        duration: TimeInterval,
        from: Double = 0.8,
        to: Double = 1.0,
        description: String = "Scale animation"
    ) -> AnimationSpec {
        return AnimationSpec(
            name: name,
            duration: duration,
            easing: .easeOutBack,
            size: .element,
            description: description,
            visualBehavior: [
                "element": [
                    VisualBehaviorStep(type: .scale, fromValue: from, toValue: to)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "element": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: duration * 0.5)
                    ]
                ]
            )
        )
    }
}
