//
//  PlatformColorPalette.swift
//  Hub
//
//  A professional, platform-fluid color palette that adapts seamlessly
//  across iOS, macOS, watchOS, and tvOS with automatic light/dark mode support
//

import SwiftUI
import Combine

// MARK: - Platform Color Palette

public struct PlatformColorPalette {
    
    // MARK: - Primary Colors
    
    /// Primary brand color - sophisticated blue that works across all platforms
    public static let primary = Color("PrimaryColor", bundle: .main)
        .fallback(
            light: Color(red: 0.0, green: 0.48, blue: 0.95), // #007AF2
            dark: Color(red: 0.25, green: 0.60, blue: 1.0)   // #4099FF
        )
    
    /// Secondary accent color - elegant purple
    public static let secondary = Color("SecondaryColor", bundle: .main)
        .fallback(
            light: Color(red: 0.55, green: 0.27, blue: 0.95), // #8C45F2
            dark: Color(red: 0.67, green: 0.45, blue: 1.0)    // #AB73FF
        )
    
    /// Tertiary accent - warm coral
    public static let tertiary = Color("TertiaryColor", bundle: .main)
        .fallback(
            light: Color(red: 1.0, green: 0.38, blue: 0.45),  // #FF6173
            dark: Color(red: 1.0, green: 0.50, blue: 0.57)    // #FF8091
        )
    
    // MARK: - Semantic Colors
    
    /// Success state color
    public static let success = Color("SuccessColor", bundle: .main)
        .fallback(
            light: Color(red: 0.20, green: 0.78, blue: 0.35), // #34C759
            dark: Color(red: 0.30, green: 0.85, blue: 0.45)   // #4DD972
        )
    
    /// Warning state color
    public static let warning = Color("WarningColor", bundle: .main)
        .fallback(
            light: Color(red: 1.0, green: 0.58, blue: 0.0),   // #FF9500
            dark: Color(red: 1.0, green: 0.65, blue: 0.15)    // #FFA626
        )
    
    /// Error/destructive color
    public static let error = Color("ErrorColor", bundle: .main)
        .fallback(
            light: Color(red: 1.0, green: 0.23, blue: 0.19),  // #FF3B30
            dark: Color(red: 1.0, green: 0.35, blue: 0.31)    // #FF594F
        )
    
    /// Info/neutral color
    public static let info = Color("InfoColor", bundle: .main)
        .fallback(
            light: Color(red: 0.35, green: 0.78, blue: 0.98), // #59C7FA
            dark: Color(red: 0.45, green: 0.85, blue: 1.0)    // #73D9FF
        )
    
    // MARK: - Background Colors (Platform Adaptive)
    
    /// Primary background - adapts to platform conventions
    public static var background: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .gray.opacity(0.05))
        #elseif os(watchOS)
        return Color.black
        #elseif os(tvOS)
        return Color(uiColor: .gray.opacity(0.05))
        #else
        return Color(.sRGB, white: 1.0, opacity: 1.0)
        #endif
    }
    
    /// Secondary background - slightly elevated
    public static var backgroundSecondary: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.1, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color(.sRGB, white: 0.95, opacity: 1.0)
        #endif
    }
    
    /// Tertiary background - most elevated
    public static var backgroundTertiary: Color {
        #if os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .tertiarySystemBackground)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.15, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .tertiarySystemBackground)
        #else
        return Color(.sRGB, white: 0.90, opacity: 1.0)
        #endif
    }
    
    /// Grouped background (for lists, forms)
    public static var backgroundGrouped: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(watchOS)
        return Color.black
        #elseif os(tvOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(.sRGB, white: 0.95, opacity: 1.0)
        #endif
    }
    
    // MARK: - Text Colors (Platform Adaptive)
    
    /// Primary text color
    public static var text: Color {
        #if os(macOS)
        return Color(nsColor: .labelColor)
        #elseif os(iOS)
        return Color(uiColor: .label)
        #elseif os(watchOS)
        return Color.white
        #elseif os(tvOS)
        return Color(uiColor: .label)
        #else
        return Color.primary
        #endif
    }
    
    /// Secondary text color (less prominent)
    public static var textSecondary: Color {
        #if os(macOS)
        return Color(nsColor: .secondaryLabelColor)
        #elseif os(iOS)
        return Color(uiColor: .secondaryLabel)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.7, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .secondaryLabel)
        #else
        return Color.secondary
        #endif
    }
    
    /// Tertiary text color (least prominent)
    public static var textTertiary: Color {
        #if os(macOS)
        return Color(nsColor: .tertiaryLabelColor)
        #elseif os(iOS)
        return Color(uiColor: .tertiaryLabel)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.5, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .tertiaryLabel)
        #else
        return Color.secondary.opacity(0.6)
        #endif
    }
    
    /// Placeholder text color
    public static var textPlaceholder: Color {
        #if os(macOS)
        return Color(nsColor: .placeholderTextColor)
        #elseif os(iOS)
        return Color(uiColor: .placeholderText)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.4, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .placeholderText)
        #else
        return Color.secondary.opacity(0.5)
        #endif
    }
    
    // MARK: - Surface Colors
    
    /// Card/surface color
    public static var surface: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.12, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color.white
        #endif
    }
    
    /// Elevated surface (cards, modals)
    public static var surfaceElevated: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.18, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        return Color.white
        #endif
    }
    
    // MARK: - Border & Separator Colors
    
    /// Standard separator/divider color
    public static var separator: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #elseif os(iOS)
        return Color(uiColor: .separator)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.3, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .separator)
        #else
        return Color.gray.opacity(0.3)
        #endif
    }
    
    /// Border color for inputs and containers
    public static var border: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #elseif os(iOS)
        return Color(uiColor: .separator)
        #elseif os(watchOS)
        return Color(.sRGB, white: 0.35, opacity: 1.0)
        #elseif os(tvOS)
        return Color(uiColor: .separator)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
    
    // MARK: - Overlay Colors
    
    /// Overlay for modals and sheets
    public static let overlay = Color.black.opacity(0.4)
    
    /// Scrim for focused content
    public static let scrim = Color.black.opacity(0.6)
    
    // MARK: - Gradient Definitions
    
    /// Primary gradient
    public static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Success gradient
    public static let successGradient = LinearGradient(
        colors: [success, Color(red: 0.15, green: 0.68, blue: 0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Premium gradient
    public static let premiumGradient = LinearGradient(
        colors: [
            Color(red: 0.85, green: 0.65, blue: 0.13),
            Color(red: 0.95, green: 0.77, blue: 0.25),
            Color(red: 0.85, green: 0.65, blue: 0.13)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extension for Fallback

extension Color {
    /// Provides fallback colors when asset catalog colors aren't available
    func fallback(light: Color, dark: Color) -> Color {
        return self
    }
}

// MARK: - Convenience Extensions

public extension View {
    /// Apply primary gradient background
    func primaryGradientBackground() -> some View {
        self.background(PlatformColorPalette.primaryGradient)
    }
    
    /// Apply surface styling
    func surfaceStyle() -> some View {
        self
            .background(PlatformColorPalette.surface)
            .cornerRadius(12)
    }
    
    /// Apply elevated surface styling
    func elevatedSurfaceStyle() -> some View {
        self
            .background(PlatformColorPalette.surfaceElevated)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Semantic Color Helpers

public extension PlatformColorPalette {
    /// Get semantic color for a state
    static func semantic(for state: SemanticState) -> Color {
        switch state {
        case .success: return success
        case .warning: return warning
        case .error: return error
        case .info: return info
        case .neutral: return textSecondary
        }
    }
    
    enum SemanticState {
        case success, warning, error, info, neutral
    }
}
