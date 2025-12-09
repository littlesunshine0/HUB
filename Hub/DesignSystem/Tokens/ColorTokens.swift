//
//  ColorTokens.swift
//  Hub
//
//  Unified Color System - Extracted from ButtonSystem
//  Provides semantic color tokens for light and dark modes
//

import SwiftUI

// MARK: - Color Tokens

public struct ColorTokens {
    // MARK: - Primary Colors
    public static let primaryLight = Color(red: 0.00, green: 0.48, blue: 1.00)
    public static let primaryDark = Color(red: 0.47, green: 0.67, blue: 1.00)
    
    // MARK: - Semantic Colors
    public struct Semantic {
        // Success
        public static let successLight = Color.green
        public static let successDark = Color(red: 0.40, green: 0.90, blue: 0.55)
        
        // Error/Destructive
        public static let errorLight = Color.red
        public static let errorDark = Color(red: 1.00, green: 0.47, blue: 0.52)
        
        // Warning
        public static let warningLight = Color.orange
        public static let warningDark = Color(red: 1.00, green: 0.85, blue: 0.40)
        
        // Info
        public static let infoLight = Color.cyan
        public static let infoDark = Color(red: 0.47, green: 0.67, blue: 1.00)
    }
    
    // MARK: - Neutral Colors
    public struct Neutral {
        // Light Mode
        public static let backgroundLight = Color.white
        public static let backgroundSecondaryLight = Color(red: 0.95, green: 0.95, blue: 0.97)
        public static let textPrimaryLight = Color.black
        public static let textSecondaryLight = Color.gray
        public static let borderLight = Color.gray.opacity(0.3)
        
        // Dark Mode
        public static let backgroundDark = Color(red: 0.11, green: 0.15, blue: 0.20)
        public static let backgroundSecondaryDark = Color(red: 0.19, green: 0.23, blue: 0.29)
        public static let textPrimaryDark = Color(red: 0.95, green: 0.96, blue: 0.97)
        public static let textSecondaryDark = Color(red: 0.70, green: 0.76, blue: 0.84)
        public static let borderDark = Color(red: 0.38, green: 0.44, blue: 0.52)
    }
    
    // MARK: - Shadow Colors
    public struct Shadow {
        public static let light = Color.black.opacity(0.10)
        public static let dark = Color.black.opacity(0.30)
    }
}

// MARK: - Semantic Color Extension

public extension Color {
    static func semantic(_ type: SemanticColorType, for colorScheme: ColorScheme) -> Color {
        switch type {
        case .primary:
            return colorScheme == .light ? ColorTokens.primaryLight : ColorTokens.primaryDark
        case .success:
            return colorScheme == .light ? ColorTokens.Semantic.successLight : ColorTokens.Semantic.successDark
        case .error:
            return colorScheme == .light ? ColorTokens.Semantic.errorLight : ColorTokens.Semantic.errorDark
        case .warning:
            return colorScheme == .light ? ColorTokens.Semantic.warningLight : ColorTokens.Semantic.warningDark
        case .info:
            return colorScheme == .light ? ColorTokens.Semantic.infoLight : ColorTokens.Semantic.infoDark
        }
    }
}

public enum SemanticColorType {
    case primary, success, error, warning, info
}
