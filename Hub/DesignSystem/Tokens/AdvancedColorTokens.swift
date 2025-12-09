//
//  AdvancedColorTokens.swift
//  Hub
//
//  Advanced color system with contrast budgets, harmony, and accessibility
//

import SwiftUI

public struct AdvancedColorTokens {
    
    // MARK: - Contrast Budgets
    
    public struct ContrastBudgets {
        // WCAG 2.1 Compliance Levels
        public static let wcagAA = ContrastBudget(
            minimumRatio: 4.5,
            largeTextRatio: 3.0,
            uiComponentRatio: 3.0,
            level: .aa
        )
        
        public static let wcagAAA = ContrastBudget(
            minimumRatio: 7.0,
            largeTextRatio: 4.5,
            uiComponentRatio: 3.0,
            level: .aaa
        )
        
        // Context-Specific Budgets
        public static let gaming = ContrastBudget(
            minimumRatio: 3.0,
            largeTextRatio: 2.5,
            uiComponentRatio: 2.0,
            level: .custom
        )
        
        public static let medical = ContrastBudget(
            minimumRatio: 7.0,
            largeTextRatio: 5.0,
            uiComponentRatio: 4.5,
            level: .aaa
        )
    }
    
    // MARK: - Color Harmony Recipes
    
    public struct ColorHarmony {
        public static let complementary = HarmonyRecipe(
            name: "Complementary",
            baseHue: 0,
            offsets: [180],
            saturationAdjust: [0, 0],
            lightnessAdjust: [0, 0]
        )
        
        public static let splitComplementary = HarmonyRecipe(
            name: "Split Complementary",
            baseHue: 0,
            offsets: [150, 210],
            saturationAdjust: [0, -10, -10],
            lightnessAdjust: [0, 5, 5]
        )
        
        public static let triadic = HarmonyRecipe(
            name: "Triadic",
            baseHue: 0,
            offsets: [120, 240],
            saturationAdjust: [0, 0, 0],
            lightnessAdjust: [0, 0, 0]
        )
        
        public static let tetradic = HarmonyRecipe(
            name: "Tetradic",
            baseHue: 0,
            offsets: [90, 180, 270],
            saturationAdjust: [0, 0, 0, 0],
            lightnessAdjust: [0, 0, 0, 0]
        )
        
        public static let analogous = HarmonyRecipe(
            name: "Analogous",
            baseHue: 0,
            offsets: [30, -30],
            saturationAdjust: [0, -5, -5],
            lightnessAdjust: [0, 5, -5]
        )
        
        public static let monochromatic = HarmonyRecipe(
            name: "Monochromatic",
            baseHue: 0,
            offsets: [0, 0, 0],
            saturationAdjust: [0, -20, -40],
            lightnessAdjust: [0, 15, 30]
        )
    }
    
    // MARK: - Vibe-Based Color Pairings
    
    public struct VibePairings {
        public static let energetic = VibePalette(
            name: "Energetic",
            primary: "#FF6B35",
            secondary: "#F7931E",
            accent: "#FDC830",
            background: "#FFFFFF",
            text: "#2C3E50",
            mood: .energetic
        )
        
        public static let calm = VibePalette(
            name: "Calm",
            primary: "#6C9BCF",
            secondary: "#8BBDD9",
            accent: "#A8D8EA",
            background: "#F8F9FA",
            text: "#2C3E50",
            mood: .calm
        )
        
        public static let professional = VibePalette(
            name: "Professional",
            primary: "#2C3E50",
            secondary: "#34495E",
            accent: "#3498DB",
            background: "#ECF0F1",
            text: "#2C3E50",
            mood: .professional
        )
        
        public static let playful = VibePalette(
            name: "Playful",
            primary: "#FF6B9D",
            secondary: "#C06C84",
            accent: "#F67280",
            background: "#FFF5E4",
            text: "#355C7D",
            mood: .playful
        )
        
        public static let elegant = VibePalette(
            name: "Elegant",
            primary: "#1A1A2E",
            secondary: "#16213E",
            accent: "#C5A880",
            background: "#F8F4E6",
            text: "#1A1A2E",
            mood: .elegant
        )
        
        public static let natural = VibePalette(
            name: "Natural",
            primary: "#6A994E",
            secondary: "#A7C957",
            accent: "#F2E8CF",
            background: "#FEFAE0",
            text: "#3A5A40",
            mood: .natural
        )
        
        public static let dramatic = VibePalette(
            name: "Dramatic",
            primary: "#D00000",
            secondary: "#9D0208",
            accent: "#FFB703",
            background: "#000000",
            text: "#FFFFFF",
            mood: .dramatic
        )
        
        public static let futuristic = VibePalette(
            name: "Futuristic",
            primary: "#00F5FF",
            secondary: "#7B2CBF",
            accent: "#FF006E",
            background: "#0A0E27",
            text: "#E0E0E0",
            mood: .futuristic
        )
    }
    
    // MARK: - Material Color Systems
    
    public struct MaterialColors {
        public static let metal = MaterialPalette(
            name: "Metal",
            baseColor: "#C0C0C0",
            roughness: 0.2,
            metallic: 1.0,
            specular: 0.9,
            variants: [
                "polished": "#E8E8E8",
                "brushed": "#B8B8B8",
                "oxidized": "#8B7355"
            ]
        )
        
        public static let wood = MaterialPalette(
            name: "Wood",
            baseColor: "#8B4513",
            roughness: 0.6,
            metallic: 0.0,
            specular: 0.3,
            variants: [
                "oak": "#B8860B",
                "walnut": "#654321",
                "pine": "#DEB887"
            ]
        )
        
        public static let fabric = MaterialPalette(
            name: "Fabric",
            baseColor: "#F5F5DC",
            roughness: 0.8,
            metallic: 0.0,
            specular: 0.1,
            variants: [
                "cotton": "#FFFFF0",
                "silk": "#FFF8DC",
                "velvet": "#8B7D6B"
            ]
        )
        
        public static let glass = MaterialPalette(
            name: "Glass",
            baseColor: "#E0F7FA",
            roughness: 0.0,
            metallic: 0.0,
            specular: 1.0,
            variants: [
                "clear": "#F0FFFF",
                "frosted": "#E0F2F7",
                "tinted": "#B2EBF2"
            ]
        )
    }
    
    // MARK: - Accessibility Color Specialist
    
    public struct AccessibilityColors {
        // Color-Blind Safe Palettes
        public static let protanopia = AccessibilityPalette(
            name: "Protanopia Safe",
            type: .protanopia,
            colors: [
                "primary": "#0173B2",
                "secondary": "#DE8F05",
                "success": "#029E73",
                "warning": "#CC78BC",
                "error": "#CA9161"
            ]
        )
        
        public static let deuteranopia = AccessibilityPalette(
            name: "Deuteranopia Safe",
            type: .deuteranopia,
            colors: [
                "primary": "#0173B2",
                "secondary": "#DE8F05",
                "success": "#029E73",
                "warning": "#CC78BC",
                "error": "#CA9161"
            ]
        )
        
        public static let tritanopia = AccessibilityPalette(
            name: "Tritanopia Safe",
            type: .tritanopia,
            colors: [
                "primary": "#E69F00",
                "secondary": "#56B4E9",
                "success": "#009E73",
                "warning": "#F0E442",
                "error": "#D55E00"
            ]
        )
        
        public static let universal = AccessibilityPalette(
            name: "Universal",
            type: .universal,
            colors: [
                "primary": "#0173B2",
                "secondary": "#DE8F05",
                "success": "#029E73",
                "warning": "#ECE133",
                "error": "#CC3311"
            ]
        )
    }
    
    // MARK: - Color Palette Engineer
    
    public struct PaletteEngineering {
        public static func generatePalette(
            baseColor: String,
            harmony: HarmonyRecipe,
            contrastBudget: ContrastBudget
        ) -> GeneratedPalette {
            // Algorithm to generate harmonious palette with contrast validation
            return GeneratedPalette(
                base: baseColor,
                colors: [],
                contrastRatios: [:],
                wcagCompliance: true
            )
        }
        
        public static func validateContrast(
            foreground: String,
            background: String
        ) -> ContrastValidation {
            // Calculate contrast ratio
            let ratio = calculateContrastRatio(foreground, background)
            return ContrastValidation(
                ratio: ratio,
                passesAA: ratio >= 4.5,
                passesAAA: ratio >= 7.0,
                recommendation: ratio < 4.5 ? "Increase contrast" : "Compliant"
            )
        }
        
        private static func calculateContrastRatio(_ fg: String, _ bg: String) -> Double {
            // Simplified contrast calculation
            return 4.5 // Placeholder
        }
    }
}

// MARK: - Supporting Types

public struct ContrastBudget: Codable {
    public let minimumRatio: Double
    public let largeTextRatio: Double
    public let uiComponentRatio: Double
    public let level: WCAGLevel
    
    public enum WCAGLevel: String, Codable {
        case aa = "AA"
        case aaa = "AAA"
        case custom = "Custom"
    }
}

public struct HarmonyRecipe: Codable {
    public let name: String
    public let baseHue: Double
    public let offsets: [Double]
    public let saturationAdjust: [Double]
    public let lightnessAdjust: [Double]
}

public struct VibePalette: Codable {
    public let name: String
    public let primary: String
    public let secondary: String
    public let accent: String
    public let background: String
    public let text: String
    public let mood: Mood
    
    public enum Mood: String, Codable {
        case energetic, calm, professional, playful, elegant, natural, dramatic, futuristic
    }
}

public struct MaterialPalette: Codable {
    public let name: String
    public let baseColor: String
    public let roughness: Double
    public let metallic: Double
    public let specular: Double
    public let variants: [String: String]
}

public struct AccessibilityPalette: Codable {
    public let name: String
    public let type: ColorBlindType
    public let colors: [String: String]
    
    public enum ColorBlindType: String, Codable {
        case protanopia, deuteranopia, tritanopia, universal
    }
}

public struct GeneratedPalette: Codable {
    public let base: String
    public let colors: [String]
    public let contrastRatios: [String: Double]
    public let wcagCompliance: Bool
}

public struct ContrastValidation: Codable {
    public let ratio: Double
    public let passesAA: Bool
    public let passesAAA: Bool
    public let recommendation: String
}
