//
//  GenerationTypes.swift
//  Hub
//
//  Shared types for content and code generation
//

import Foundation

// MARK: - Generation Result

/// Result of content generation from directory scanning
public struct GenerationResult: Sendable {
    public var templates: Int
    public var modules: Int
    public var blueprints: Int
    public var components: Int
    public var hubs: Int
    public var packages: Int
    public var duration: TimeInterval
    
    public init(
        templates: Int = 0,
        modules: Int = 0,
        blueprints: Int = 0,
        components: Int = 0,
        hubs: Int = 0,
        packages: Int = 0,
        duration: TimeInterval = 0
    ) {
        self.templates = templates
        self.modules = modules
        self.blueprints = blueprints
        self.components = components
        self.hubs = hubs
        self.packages = packages
        self.duration = duration
    }
    
    public var total: Int {
        templates + modules + blueprints + components + hubs + packages
    }
}

// MARK: - Generation Options

/// Options for content generation
public struct GenerationOptions: Sendable {
    public var generateTemplates: Bool
    public var generateModules: Bool
    public var generateBlueprints: Bool
    public var generateComponents: Bool
    public var generateHubs: Bool
    public var generatePackages: Bool
    public var maxItemsPerType: Int
    
    public init(
        generateTemplates: Bool = true,
        generateModules: Bool = true,
        generateBlueprints: Bool = true,
        generateComponents: Bool = true,
        generateHubs: Bool = true,
        generatePackages: Bool = true,
        maxItemsPerType: Int = 50
    ) {
        self.generateTemplates = generateTemplates
        self.generateModules = generateModules
        self.generateBlueprints = generateBlueprints
        self.generateComponents = generateComponents
        self.generateHubs = generateHubs
        self.generatePackages = generatePackages
        self.maxItemsPerType = maxItemsPerType
    }
    
    public static let `default` = GenerationOptions()
    
    public static let templatesOnly = GenerationOptions(
        generateModules: false,
        generateBlueprints: false,
        generateComponents: false,
        generateHubs: false,
        generatePackages: false
    )
}

// Note: CodeGenerationResult is defined in AIModule/CodeGenerationBridge.swift
