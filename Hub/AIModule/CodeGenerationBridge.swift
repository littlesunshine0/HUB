//
//  CodeGenerationBridge.swift
//  Hub
//
//  Bridge connecting AIModule with CodeGeneratorModule for AI-powered code generation
//

import Foundation
import SwiftUI
import Combine

/// Bridge that connects AI capabilities with code generation
@MainActor
class CodeGenerationBridge: ObservableObject {
    
    // MARK: - Dependencies
    
    private let codeGenerator: EnhancedCodeGenerator
    private let advancedGenerator: AIAdvancedCodeGenerator
    private let hubBuilder: HubBuilderService
    private var achievementTracker: AIAchievementTracker?
    
    // MARK: - Published State
    
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Double = 0.0
    @Published var lastGeneratedCode: [String: String] = [:]
    @Published var generationError: String?
    
    // MARK: - Initialization
    
    init(
        codeGenerator: EnhancedCodeGenerator = .shared,
        advancedGenerator: AIAdvancedCodeGenerator = .shared,
        hubBuilder: HubBuilderService = .shared,
        achievementTracker: AIAchievementTracker? = nil
    ) {
        self.codeGenerator = codeGenerator
        self.advancedGenerator = advancedGenerator
        self.hubBuilder = hubBuilder
        self.achievementTracker = achievementTracker
    }
    
    // MARK: - Configuration
    
    public func setAchievementTracker(_ tracker: AIAchievementTracker) {
        self.achievementTracker = tracker
    }
    
    // MARK: - AI-Powered Code Generation
    
    /// Generate code from natural language description using AI
    func generateFromDescription(_ description: String, appName: String) async -> CodeGenerationResult {
        isGenerating = true
        generationProgress = 0.0
        generationError = nil
        defer { isGenerating = false }
        
        do {
            // Step 1: Parse intent from description (20%)
            generationProgress = 0.2
            let intent = parseIntent(from: description)
            
            // Step 2: Generate visual layout from intent (40%)
            generationProgress = 0.4
            let screens = await generateScreens(from: intent)
            
            // Step 3: Apply branding (60%)
            generationProgress = 0.6
            let branding = generateBranding(from: intent)
            
            // Step 4: Generate code (80%)
            generationProgress = 0.8
            let code = codeGenerator.generateApp(
                from: screens,
                branding: branding,
                appName: appName,
                bundleIdentifier: "com.hub.\(appName.lowercased().replacingOccurrences(of: " ", with: ""))"
            )
            
            // Step 5: Complete (100%)
            generationProgress = 1.0
            lastGeneratedCode = code
            
            // Track achievement
            achievementTracker?.trackCodeGeneration(success: true)
            achievementTracker?.trackNaturalLanguageGeneration()
            
            if screens.count > 1 {
                achievementTracker?.trackMultiScreenGeneration()
            }
            
            return CodeGenerationResult(
                success: true,
                files: code,
                screens: screens,
                branding: branding
            )
        } catch {
            generationError = error.localizedDescription
            achievementTracker?.trackCodeGeneration(success: false)
            return CodeGenerationResult(
                success: false,
                files: [:],
                screens: [],
                branding: TemplateBranding.default,
                error: error.localizedDescription
            )
        }
    }
    
    /// Generate code with advanced features (navigation, tabs, presentations)
    func generateAdvancedApp(
        screens: [VisualScreen],
        branding: TemplateBranding,
        appName: String,
        structure: AppStructureType,
        tabBarConfig: TabBarConfiguration?
    ) async -> [String: String] {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Generate app using feature generation
            let files = try await advancedGenerator.generateFeature(
                featureName: appName,
                components: [.model, .view, .viewModel, .service]
            )
            
            // Convert to dictionary format
            var codeFiles: [String: String] = [:]
            for file in files {
                codeFiles[file.name] = file.content
            }
            
            lastGeneratedCode = codeFiles
            
            // Track achievements for advanced features
            achievementTracker?.trackCodeGeneration(success: true)
            
            switch structure {
            case .navigation:
                achievementTracker?.trackAdvancedFeatureGeneration(feature: "navigation")
            case .tabBar, .tabBarWithNavigation:
                achievementTracker?.trackAdvancedFeatureGeneration(feature: "tabBar")
            default:
                break
            }
            
            return codeFiles
        } catch {
            // Return empty dictionary on error
            return [:]
        }
    }
    
    /// Generate and build a complete app from AI description
    func generateAndBuildApp(
        description: String,
        appName: String,
        userID: String
    ) async throws -> AppHub {
        // Generate code
        let result = await generateFromDescription(description, appName: appName)
        
        guard result.success else {
            throw NSError(
                domain: "CodeGenerationBridge",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: result.error ?? "Code generation failed"]
            )
        }
        
        // Create template from generated code
        let template = createTemplate(
            from: result.files,
            screens: result.screens,
            branding: result.branding,
            appName: appName
        )
        
        // Create hub
        let customization = HubCustomization(
            primaryColor: result.branding.primaryColor,
            accentColor: result.branding.accentColor,
            appName: appName,
            bundleIdentifier: "com.hub.\(appName.lowercased().replacingOccurrences(of: " ", with: ""))",
            features: [:],
            settings: [:]
        )
        
        let hub = hubBuilder.createHub(
            templateID: template.id,
            templateName: "AI Generated",
            name: appName,
            icon: "sparkles",
            customization: customization,
            userID: userID
        )
        
        // Track AI hub creation achievement
        achievementTracker?.trackAIHubCreation()
        
        return hub
    }
    
    // MARK: - AI Intent Parsing
    
    private func parseIntent(from description: String) -> AppIntent {
        let lowercased = description.lowercased()
        
        // Detect app type
        var appType: AppType = .utility
        if lowercased.contains("finance") || lowercased.contains("budget") || lowercased.contains("expense") {
            appType = .finance
        } else if lowercased.contains("todo") || lowercased.contains("task") || lowercased.contains("productivity") {
            appType = .productivity
        } else if lowercased.contains("social") || lowercased.contains("chat") || lowercased.contains("message") {
            appType = .social
        } else if lowercased.contains("health") || lowercased.contains("fitness") || lowercased.contains("workout") {
            appType = .health
        }
        
        // Detect required features
        var features: [String] = []
        if lowercased.contains("login") || lowercased.contains("auth") || lowercased.contains("sign in") {
            features.append("authentication")
        }
        if lowercased.contains("list") || lowercased.contains("table") {
            features.append("list")
        }
        if lowercased.contains("form") || lowercased.contains("input") {
            features.append("form")
        }
        if lowercased.contains("chart") || lowercased.contains("graph") || lowercased.contains("visualize") {
            features.append("charts")
        }
        if lowercased.contains("settings") || lowercased.contains("preferences") {
            features.append("settings")
        }
        
        // Detect color preferences
        var primaryColor = "#007AFF"
        let accentColor = "#FF9500"
        
        if lowercased.contains("blue") {
            primaryColor = "#007AFF"
        } else if lowercased.contains("green") {
            primaryColor = "#34C759"
        } else if lowercased.contains("red") {
            primaryColor = "#FF3B30"
        } else if lowercased.contains("purple") {
            primaryColor = "#AF52DE"
        }
        
        return AppIntent(
            appType: appType,
            features: features,
            primaryColor: primaryColor,
            accentColor: accentColor,
            description: description
        )
    }
    
    // MARK: - Screen Generation
    
    private func generateScreens(from intent: AppIntent) async -> [VisualScreen] {
        var screens: [VisualScreen] = []
        
        // Generate main screen based on app type
        let mainScreen = generateMainScreen(for: intent)
        screens.append(mainScreen)
        
        // Add authentication if needed
        if intent.features.contains("authentication") {
            screens.append(generateLoginScreen(for: intent))
        }
        
        // Add settings if needed
        if intent.features.contains("settings") {
            screens.append(generateSettingsScreen(for: intent))
        }
        
        return screens
    }
    
    private func generateMainScreen(for intent: AppIntent) -> VisualScreen {
        // Simplified screen generation - actual implementation would use proper component types
        return VisualScreen(
            id: UUID(),
            name: "MainView",
            components: [],
            isInitialScreen: true,
            navigationTitle: "Home"
        )
    }
    
    private func generateLoginScreen(for intent: AppIntent) -> VisualScreen {
        // Simplified screen generation
        return VisualScreen(
            id: UUID(),
            name: "LoginView",
            components: [],
            isInitialScreen: false,
            navigationTitle: "Sign In"
        )
    }
    
    private func generateSettingsScreen(for intent: AppIntent) -> VisualScreen {
        // Simplified screen generation
        return VisualScreen(
            id: UUID(),
            name: "SettingsView",
            components: [],
            isInitialScreen: false,
            navigationTitle: "Settings"
        )
    }
    
    // MARK: - Branding Generation
    
    private func generateBranding(from intent: AppIntent) -> TemplateBranding {
        TemplateBranding(
            accentColor: intent.accentColor,
            primaryColor: intent.primaryColor,
            backgroundColor: "#FFFFFF",
            assets: [:]
        )
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(
        from files: [String: String],
        screens: [VisualScreen],
        branding: TemplateBranding,
        appName: String
    ) -> TemplateModel {
        TemplateModel(
            id: UUID(),
            name: appName,
            category: .productivity,
            description: "AI-generated app",
            icon: "sparkles",
            sourceFiles: files,
            features: [],
            dependencies: [],
            sharedModules: [],
            featureToggles: [:],
            visualScreens: screens,
            branding: branding,
            isVisualTemplate: true
        )
    }
}

// MARK: - Supporting Types

struct CodeGenerationResult {
    let success: Bool
    let files: [String: String]
    let screens: [VisualScreen]
    let branding: TemplateBranding
    var error: String?
}

struct AppIntent {
    let appType: AppType
    let features: [String]
    let primaryColor: String
    let accentColor: String
    let description: String
}

enum AppType {
    case finance
    case productivity
    case social
    case health
    case utility
}

// Note: AppStructureType and TabBarConfiguration are defined in AdvancedCodeGenerator
