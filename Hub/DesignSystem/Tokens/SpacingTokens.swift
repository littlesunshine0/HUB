///  SpacingTokens.swift
//  Hub
//
//  Unified Spacing System
//  Provides consistent spacing values across the app
//

import SwiftUI
import Combine

public struct SpacingTokens {
    // MARK: - Base Spacing Scale
    public static let xxxs: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 40
    
    // MARK: - Component Specific
    public struct Button {
        public static let paddingHorizontal: CGFloat = 16
        public static let paddingVertical: CGFloat = 12
        public static let iconSpacing: CGFloat = 8
        public static let minHeight: CGFloat = 44
    }
    
    public struct Card {
        public static let padding: CGFloat = 16
        public static let spacing: CGFloat = 12
    }
    
    public struct Carousel {
        public static let dotSpacing: CGFloat = 8
        public static let dotSize: CGFloat = 8
        public static let navSize: CGFloat = 44
    }
}
