//
//  AnimationEasing.swift
//  Hub
//
//  Animation easing curves for Hub Onboarding Animation System
//  Provides precise timing functions as SwiftUI Animation extensions
//

import SwiftUI

// MARK: - Animation Easing

/// Easing curves for onboarding animations
/// Each case provides a specific timing function optimized for different animation contexts
public enum AnimationEasing: String, Codable, CaseIterable {
    /// Cubic ease-out: Starts fast, decelerates smoothly
    /// Best for: Entrance animations, content reveals
    case easeOutCubic
    
    /// Cubic ease-in-out: Smooth acceleration and deceleration
    /// Best for: Transitions, icon movements
    case easeInOutCubic
    
    /// Quartic ease-out: Starts very fast, strong deceleration
    /// Best for: Dramatic reveals, workspace transitions
    case easeOutQuart
    
    /// Quadratic ease-in-out: Smooth acceleration and deceleration
    /// Best for: Interactive transitions, step changes
    case easeInOutQuad
    
    /// Simple ease-out: Basic deceleration
    /// Best for: Simple fades, basic transitions
    case easeOut
    
    /// Back ease-out: Overshoots slightly then settles
    /// Best for: Playful interactions, selection feedback
    case easeOutBack
    
    /// Sine ease-in-out: Gentle, natural motion
    /// Best for: Continuous animations, scanning effects
    case easeInOutSine
    
    /// Quadratic ease-out: Simple deceleration
    /// Best for: Quick transitions, simple movements
    case easeOutQuad
    
    /// Quintic ease-out: Very smooth deceleration
    /// Best for: Elegant reveals, smooth expansions
    case easeOutQuint
    
    /// Exponential ease-out: Rapid deceleration
    /// Best for: Dramatic effects, quick stops
    case easeOutExpo
    
    /// Linear: Constant speed
    /// Best for: Spinners, continuous motion
    case linear
    
    // MARK: - SwiftUI Animation Conversion
    
    /// Converts the easing curve to a SwiftUI Animation with the specified duration
    /// - Parameter duration: Animation duration in seconds
    /// - Returns: Configured SwiftUI Animation
    public func animation(duration: TimeInterval) -> Animation {
        switch self {
        case .easeOutCubic:
            // Cubic bezier approximation: (0.215, 0.61, 0.355, 1.0)
            return .timingCurve(0.215, 0.61, 0.355, 1.0, duration: duration)
            
        case .easeInOutCubic:
            // Cubic bezier approximation: (0.645, 0.045, 0.355, 1.0)
            return .timingCurve(0.645, 0.045, 0.355, 1.0, duration: duration)
            
        case .easeOutQuart:
            // Quartic bezier approximation: (0.165, 0.84, 0.44, 1.0)
            return .timingCurve(0.165, 0.84, 0.44, 1.0, duration: duration)
            
        case .easeInOutQuad:
            // Quadratic bezier approximation: (0.455, 0.03, 0.515, 0.955)
            return .timingCurve(0.455, 0.03, 0.515, 0.955, duration: duration)
            
        case .easeOut:
            // Simple ease-out: (0.0, 0.0, 0.58, 1.0)
            return .timingCurve(0.0, 0.0, 0.58, 1.0, duration: duration)
            
        case .easeOutBack:
            // Back easing with overshoot: (0.175, 0.885, 0.32, 1.275)
            // The 1.275 creates the characteristic overshoot
            return .timingCurve(0.175, 0.885, 0.32, 1.275, duration: duration)
            
        case .easeInOutSine:
            // Sine wave approximation: (0.445, 0.05, 0.55, 0.95)
            return .timingCurve(0.445, 0.05, 0.55, 0.95, duration: duration)
            
        case .easeOutQuad:
            // Quadratic ease-out: (0.25, 0.46, 0.45, 0.94)
            return .timingCurve(0.25, 0.46, 0.45, 0.94, duration: duration)
            
        case .easeOutQuint:
            // Quintic ease-out: (0.23, 1.0, 0.32, 1.0)
            return .timingCurve(0.23, 1.0, 0.32, 1.0, duration: duration)
            
        case .easeOutExpo:
            // Exponential ease-out: (0.19, 1.0, 0.22, 1.0)
            return .timingCurve(0.19, 1.0, 0.22, 1.0, duration: duration)
            
        case .linear:
            // Linear: constant speed
            return .linear(duration: duration)
        }
    }
    
    /// Converts the easing curve to a SwiftUI Animation with default duration (0.3s)
    public var animation: Animation {
        animation(duration: 0.3)
    }
    
    // MARK: - Descriptive Properties
    
    /// Human-readable description of the easing curve's behavior
    public var description: String {
        switch self {
        case .easeOutCubic:
            return "Cubic ease-out: Starts fast, decelerates smoothly"
        case .easeInOutCubic:
            return "Cubic ease-in-out: Smooth acceleration and deceleration"
        case .easeOutQuart:
            return "Quartic ease-out: Starts very fast, strong deceleration"
        case .easeInOutQuad:
            return "Quadratic ease-in-out: Smooth acceleration and deceleration"
        case .easeOut:
            return "Simple ease-out: Basic deceleration"
        case .easeOutBack:
            return "Back ease-out: Overshoots slightly then settles"
        case .easeInOutSine:
            return "Sine ease-in-out: Gentle, natural motion"
        case .easeOutQuad:
            return "Quadratic ease-out: Simple deceleration"
        case .easeOutQuint:
            return "Quintic ease-out: Very smooth deceleration"
        case .easeOutExpo:
            return "Exponential ease-out: Rapid deceleration"
        case .linear:
            return "Linear: Constant speed"
        }
    }
    
    /// Recommended use cases for this easing curve
    public var useCases: [String] {
        switch self {
        case .easeOutCubic:
            return ["Entrance animations", "Content reveals", "Intro sequences"]
        case .easeInOutCubic:
            return ["Icon transitions", "Position changes", "Smooth movements"]
        case .easeOutQuart:
            return ["Dramatic reveals", "Workspace transitions", "Major state changes"]
        case .easeInOutQuad:
            return ["Interactive transitions", "Step changes", "Toggle animations"]
        case .easeOut:
            return ["Simple fades", "Basic transitions", "Quick animations"]
        case .easeOutBack:
            return ["Playful interactions", "Selection feedback", "Completion pulses"]
        case .easeInOutSine:
            return ["Continuous animations", "Scanning effects", "Looping motions"]
        case .easeOutQuad:
            return ["Quick transitions", "Simple movements", "Basic interactions"]
        case .easeOutQuint:
            return ["Elegant reveals", "Smooth expansions", "Graceful movements"]
        case .easeOutExpo:
            return ["Dramatic effects", "Quick stops", "Emphasis animations"]
        case .linear:
            return ["Spinners", "Continuous motion", "Progress indicators"]
        }
    }
}

// MARK: - SwiftUI Animation Extensions

public extension Animation {
    
    /// Creates an animation with ease-out cubic timing
    /// - Parameter duration: Animation duration in seconds (default: 0.3)
    /// - Returns: Animation with cubic ease-out curve
    static func easeOutCubic(duration: TimeInterval = 0.3) -> Animation {
        AnimationEasing.easeOutCubic.animation(duration: duration)
    }
    
    /// Creates an animation with ease-out quartic timing
    /// - Parameter duration: Animation duration in seconds (default: 0.3)
    /// - Returns: Animation with quartic ease-out curve
    static func easeOutQuart(duration: TimeInterval = 0.3) -> Animation {
        AnimationEasing.easeOutQuart.animation(duration: duration)
    }
    
    /// Creates an animation with ease-in-out quadratic timing
    /// - Parameter duration: Animation duration in seconds (default: 0.3)
    /// - Returns: Animation with quadratic ease-in-out curve
    static func easeInOutQuad(duration: TimeInterval = 0.3) -> Animation {
        AnimationEasing.easeInOutQuad.animation(duration: duration)
    }
    
    /// Creates an animation with ease-out back timing (with overshoot)
    /// - Parameter duration: Animation duration in seconds (default: 0.3)
    /// - Returns: Animation with back ease-out curve
    static func easeOutBack(duration: TimeInterval = 0.3) -> Animation {
        AnimationEasing.easeOutBack.animation(duration: duration)
    }
    
    /// Creates an animation with ease-in-out sine timing
    /// - Parameter duration: Animation duration in seconds (default: 0.3)
    /// - Returns: Animation with sine ease-in-out curve
    static func easeInOutSine(duration: TimeInterval = 0.3) -> Animation {
        AnimationEasing.easeInOutSine.animation(duration: duration)
    }
}

// MARK: - View Modifiers

public extension View {
    
    /// Applies an animation with the specified easing curve
    /// - Parameters:
    ///   - easing: The easing curve to use
    ///   - duration: Animation duration in seconds
    ///   - value: The value to observe for changes
    /// - Returns: View with animation applied
    func animation<V: Equatable>(_ easing: AnimationEasing, duration: TimeInterval = 0.3, value: V) -> some View {
        self.animation(easing.animation(duration: duration), value: value)
    }
}

// MARK: - Preview Helpers

#if DEBUG
/// Preview helper to visualize easing curves
public struct EasingCurvePreview: View {
    let easing: AnimationEasing
    @State private var progress: CGFloat = 0
    
    public init(easing: AnimationEasing) {
        self.easing = easing
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text(easing.rawValue)
                .font(.headline)
            
            Text(easing.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Visual representation
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .offset(x: progress * 280)
            }
            .frame(width: 300)
            
            Button("Animate") {
                progress = 0
                withAnimation(easing.animation(duration: 1.0)) {
                    progress = 1
                }
            }
            
            // Use cases
            VStack(alignment: .leading, spacing: 4) {
                Text("Use Cases:")
                    .font(.caption)
                    .fontWeight(.semibold)
                ForEach(easing.useCases, id: \.self) { useCase in
                    Text("• \(useCase)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .padding()
    }
}

/// Preview all easing curves
struct EasingCurvePreviews: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ForEach(AnimationEasing.allCases, id: \.self) { easing in
                    EasingCurvePreview(easing: easing)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}
#endif
