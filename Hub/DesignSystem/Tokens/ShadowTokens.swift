//
//  ShadowTokens.swift
//  Hub
//
//  Unified Shadow & Depth System
//  Extracted from ButtonSystem's depth & lighting recipe
//

import SwiftUI
import Combine

public struct ShadowConfig: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    public let blendMode: BlendMode
    
    public init(
        color: Color,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0,
        blendMode: BlendMode = .normal
    ) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
        self.blendMode = blendMode
    }
}

public struct ShadowTokens {
    // MARK: - Light Mode Shadows
    public struct Light {
        // Ambient shadow (soft, diffused)
        public static let ambient = ShadowConfig(
            color: .black.opacity(0.10),
            radius: 22,
            y: 9
        )
        
        // Key shadow (directional, sharper)
        public static let key = ShadowConfig(
            color: .black.opacity(0.15),
            radius: 6,
            y: 3
        )
        
        // Inner shadow for pressed states
        public static let innerPressed = ShadowConfig(
            color: .black.opacity(0.14),
            radius: 9,
            y: 2,
            blendMode: .multiply
        )
        
        // Edge highlight
        public static let edgeHighlight = ShadowConfig(
            color: .white.opacity(0.35),
            radius: 1.5
        )
        
        // Bevel effects
        public static let bevelTop = ShadowConfig(
            color: .white.opacity(0.25),
            radius: 1
        )
        
        public static let bevelBottom = ShadowConfig(
            color: .black.opacity(0.12),
            radius: 1,
            y: 1
        )
    }
    
    // MARK: - Dark Mode Shadows
    public struct Dark {
        // Ambient shadow (more pronounced in dark mode)
        public static let ambient = ShadowConfig(
            color: .black.opacity(0.12),
            radius: 28,
            y: 12
        )
        
        // Key shadow
        public static let key = ShadowConfig(
            color: .black.opacity(0.18),
            radius: 8,
            y: 4
        )
        
        // Inner shadow for pressed states
        public static let innerPressed = ShadowConfig(
            color: .black.opacity(0.18),
            radius: 12,
            y: 3,
            blendMode: .multiply
        )
        
        // Edge highlight (more subtle in dark mode)
        public static let edgeHighlight = ShadowConfig(
            color: .white.opacity(0.20),
            radius: 1.5
        )
        
        // Bevel effects
        public static let bevelTop = ShadowConfig(
            color: .white.opacity(0.15),
            radius: 1
        )
        
        public static let bevelBottom = ShadowConfig(
            color: .black.opacity(0.20),
            radius: 1,
            y: 1
        )
    }
    
    // MARK: - Elevation Levels
    public enum Elevation {
        case flat, low, medium, high, highest
        
        public func shadow(for colorScheme: ColorScheme) -> ShadowConfig {
            let key: ShadowConfig
            let ambient: ShadowConfig
            
            switch colorScheme {
            case .light:
                key = Light.key
                ambient = Light.ambient
                _ = Light.innerPressed
                _ = Light.edgeHighlight
                _ = Light.bevelTop
                _ = Light.bevelBottom
            case .dark:
                key = Dark.key
                ambient = Dark.ambient
                _ = Dark.innerPressed
                _ = Dark.edgeHighlight
                _ = Dark.bevelTop
                _ = Dark.bevelBottom
            @unknown default:
                key = Light.key
                ambient = Light.ambient
                _ = Light.innerPressed
                _ = Light.edgeHighlight
                _ = Light.bevelTop
                _ = Light.bevelBottom
            }
            
            switch self {
            case .flat:
                return ShadowConfig(color: .clear, radius: 0)
            case .low:
                return ShadowConfig(color: key.color, radius: 2, y: 1)
            case .medium:
                return key
            case .high:
                return ambient
            case .highest:
                return ShadowConfig(
                    color: ambient.color,
                    radius: ambient.radius * 1.5,
                    y: ambient.y * 1.5
                )
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    func elevation(_ level: ShadowTokens.Elevation, colorScheme: ColorScheme = .light) -> some View {
        let shadow = level.shadow(for: colorScheme)
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

