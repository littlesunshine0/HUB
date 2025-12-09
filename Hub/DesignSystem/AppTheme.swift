//
//  AppTheme.swift
//  Hub
//
//  Unified Theme System
//  Provides consistent theming across the entire app
//
/*
import SwiftUI
import Combine

// MARK: - App Theme

public struct AppTheme: Sendable {
    // Colors
    public let primary: Color
    public let background: Color
    public let backgroundSecondary: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let border: Color
    public let shadowColor: Color
    public let destructive: Color
    public let success: Color
    public let warning: Color
    public let info: Color
    
    // Shadows
    public let dropShadowAmbient: ShadowConfig
    public let dropShadowKey: ShadowConfig
    public let innerShadowPressed: ShadowConfig
    public let edgeHighlight: ShadowConfig
    public let bevelTop: ShadowConfig
    public let bevelBottom: ShadowConfig
    
    public init(
        primary: Color,
        background: Color,
        backgroundSecondary: Color,
        textPrimary: Color,
        textSecondary: Color,
        border: Color,
        shadowColor: Color,
        destructive: Color,
        success: Color,
        warning: Color,
        info: Color,
        dropShadowAmbient: ShadowConfig,
        dropShadowKey: ShadowConfig,
        innerShadowPressed: ShadowConfig,
        edgeHighlight: ShadowConfig,
        bevelTop: ShadowConfig,
        bevelBottom: ShadowConfig
    ) {
        self.primary = primary
        self.background = background
        self.backgroundSecondary = backgroundSecondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.border = border
        self.shadowColor = shadowColor
        self.destructive = destructive
        self.success = success
        self.warning = warning
        self.info = info
        self.dropShadowAmbient = dropShadowAmbient
        self.dropShadowKey = dropShadowKey
        self.innerShadowPressed = innerShadowPressed
        self.edgeHighlight = edgeHighlight
        self.bevelTop = bevelTop
        self.bevelBottom = bevelBottom
    }
}

// MARK: - Predefined Themes

public extension AppTheme {
    static let light = AppTheme(
        primary: ColorTokens.primaryLight,
        background: ColorTokens.Neutral.backgroundLight,
        backgroundSecondary: ColorTokens.Neutral.backgroundSecondaryLight,
        textPrimary: ColorTokens.Neutral.textPrimaryLight,
        textSecondary: ColorTokens.Neutral.textSecondaryLight,
        border: ColorTokens.Neutral.borderLight,
        shadowColor: ColorTokens.Shadow.light,
        destructive: ColorTokens.Semantic.errorLight,
        success: ColorTokens.Semantic.successLight,
        warning: ColorTokens.Semantic.warningLight,
        info: ColorTokens.Semantic.infoLight,
        dropShadowAmbient: ShadowTokens.Light.ambient,
        dropShadowKey: ShadowTokens.Light.key,
        innerShadowPressed: ShadowTokens.Light.innerPressed,
        edgeHighlight: ShadowTokens.Light.edgeHighlight,
        bevelTop: ShadowTokens.Light.bevelTop,
        bevelBottom: ShadowTokens.Light.bevelBottom
    )
    
    static let dark = AppTheme(
        primary: ColorTokens.primaryDark,
        background: ColorTokens.Neutral.backgroundDark,
        backgroundSecondary: ColorTokens.Neutral.backgroundSecondaryDark,
        textPrimary: ColorTokens.Neutral.textPrimaryDark,
        textSecondary: ColorTokens.Neutral.textSecondaryDark,
        border: ColorTokens.Neutral.borderDark,
        shadowColor: ColorTokens.Shadow.dark,
        destructive: ColorTokens.Semantic.errorDark,
        success: ColorTokens.Semantic.successDark,
        warning: ColorTokens.Semantic.warningDark,
        info: ColorTokens.Semantic.infoDark,
        dropShadowAmbient: ShadowTokens.Dark.ambient,
        dropShadowKey: ShadowTokens.Dark.key,
        innerShadowPressed: ShadowTokens.Dark.innerPressed,
        edgeHighlight: ShadowTokens.Dark.edgeHighlight,
        bevelTop: ShadowTokens.Dark.bevelTop,
        bevelBottom: ShadowTokens.Dark.bevelBottom
    )
}

// MARK: - Environment Support

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

public extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

public extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
    
    func adaptiveAppTheme() -> some View {
        modifier(AdaptiveThemeModifier())
    }
}

// MARK: - Adaptive Theme Modifier

private struct AdaptiveThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .appTheme(colorScheme == .dark ? .dark : .light)
    }
}
*/
