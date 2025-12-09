//
//  VFXTokens.swift
//  Hub
//
//  Visual Effects tokens for gameplay, environment, and shader systems
//

import SwiftUI
import Combine

public struct VFXTokens {
    
    // MARK: - Particle Systems
    
    public struct ParticleEffects {
        public static let sparkle = ParticleConfig(
            count: 50,
            lifetime: 2.0,
            speed: 100,
            spread: 360,
            color: "#FFD700",
            blendMode: .additive
        )
        
        public static let smoke = ParticleConfig(
            count: 30,
            lifetime: 3.0,
            speed: 50,
            spread: 45,
            color: "#808080",
            blendMode: .normal
        )
        
        public static let fire = ParticleConfig(
            count: 100,
            lifetime: 1.5,
            speed: 150,
            spread: 30,
            color: "#FF4500",
            blendMode: .additive
        )
        
        public static let magic = ParticleConfig(
            count: 75,
            lifetime: 2.5,
            speed: 80,
            spread: 180,
            color: "#9370DB",
            blendMode: .additive
        )
    }
    
    // MARK: - Shader Effects
    
    public struct ShaderEffects {
        public static let bloom = ShaderConfig(
            name: "bloom",
            intensity: 0.8,
            threshold: 0.7,
            radius: 5.0,
            parameters: ["softKnee": 0.5]
        )
        
        public static let chromaticAberration = ShaderConfig(
            name: "chromatic_aberration",
            intensity: 0.3,
            threshold: 0.0,
            radius: 2.0,
            parameters: ["offset": 0.002]
        )
        
        public static let vignette = ShaderConfig(
            name: "vignette",
            intensity: 0.5,
            threshold: 0.0,
            radius: 1.0,
            parameters: ["smoothness": 0.4, "roundness": 1.0]
        )
        
        public static let filmGrain = ShaderConfig(
            name: "film_grain",
            intensity: 0.15,
            threshold: 0.0,
            radius: 0.0,
            parameters: ["size": 1.0, "colored": false]
        )
        
        public static let motionBlur = ShaderConfig(
            name: "motion_blur",
            intensity: 0.6,
            threshold: 0.0,
            radius: 8.0,
            parameters: ["samples": 16]
        )
    }
    
    // MARK: - Environment Effects
    
    public struct EnvironmentEffects {
        public static let fog = EnvironmentConfig(
            type: .exponential,
            density: 0.02,
            color: "#B0C4DE",
            start: 10.0,
            end: 100.0
        )
        
        public static let rain = EnvironmentConfig(
            type: .weather,
            density: 0.5,
            color: "#4682B4",
            start: 0.0,
            end: 50.0
        )
        
        public static let snow = EnvironmentConfig(
            type: .weather,
            density: 0.3,
            color: "#FFFFFF",
            start: 0.0,
            end: 40.0
        )
        
        public static let dust = EnvironmentConfig(
            type: .ambient,
            density: 0.1,
            color: "#D2B48C",
            start: 0.0,
            end: 30.0
        )
    }
    
    // MARK: - Post-Processing Stack
    
    public struct PostProcessing {
        public static let cinematic = PostProcessStack(
            effects: [
                .bloom(intensity: 0.6),
                .vignette(intensity: 0.4),
                .filmGrain(intensity: 0.1),
                .colorGrading(lut: "cinematic_lut")
            ],
            order: [0, 1, 2, 3]
        )
        
        public static let stylized = PostProcessStack(
            effects: [
                .outline(thickness: 2.0),
                .colorGrading(lut: "stylized_lut"),
                .bloom(intensity: 0.8)
            ],
            order: [0, 1, 2]
        )
        
        public static let realistic = PostProcessStack(
            effects: [
                .ssao(radius: 0.5),
                .ssr(maxDistance: 50.0),
                .bloom(intensity: 0.3),
                .toneMapping(mode: "aces")
            ],
            order: [0, 1, 2, 3]
        )
    }
    
    // MARK: - Performance Budgets
    
    public struct PerformanceBudgets {
        public static let mobile = VFXBudget(
            maxParticles: 500,
            maxLights: 4,
            shadowQuality: .low,
            postProcessing: .minimal,
            targetFPS: 60
        )
        
        public static let console = VFXBudget(
            maxParticles: 2000,
            maxLights: 16,
            shadowQuality: .medium,
            postProcessing: .standard,
            targetFPS: 60
        )
        
        public static let pc = VFXBudget(
            maxParticles: 5000,
            maxLights: 32,
            shadowQuality: .high,
            postProcessing: .full,
            targetFPS: 60
        )
    }
}

// MARK: - Supporting Types

public struct ParticleConfig: Codable {
    public let count: Int
    public let lifetime: Double
    public let speed: Double
    public let spread: Double
    public let color: String
    public let blendMode: BlendMode
    
    public enum BlendMode: String, Codable {
        case normal, additive, multiply, screen
    }
}

public struct ShaderConfig: Codable {
    public let name: String
    public let intensity: Double
    public let threshold: Double
    public let radius: Double
    public let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name, intensity, threshold, radius, parameters
    }
    
    public init(name: String, intensity: Double, threshold: Double, radius: Double, parameters: [String: Any]) {
        self.name = name
        self.intensity = intensity
        self.threshold = threshold
        self.radius = radius
        self.parameters = parameters
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        intensity = try container.decode(Double.self, forKey: .intensity)
        threshold = try container.decode(Double.self, forKey: .threshold)
        radius = try container.decode(Double.self, forKey: .radius)
        parameters = [:] // Simplified for Swift
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(threshold, forKey: .threshold)
        try container.encode(radius, forKey: .radius)
    }
}

public struct EnvironmentConfig: Codable {
    public let type: EffectType
    public let density: Double
    public let color: String
    public let start: Double
    public let end: Double
    
    public enum EffectType: String, Codable {
        case exponential, linear, weather, ambient
    }
}

public struct PostProcessStack: Codable {
    public let effects: [PostProcessEffect]
    public let order: [Int]
}

public enum PostProcessEffect: Codable {
    case bloom(intensity: Double)
    case vignette(intensity: Double)
    case filmGrain(intensity: Double)
    case colorGrading(lut: String)
    case outline(thickness: Double)
    case ssao(radius: Double)
    case ssr(maxDistance: Double)
    case toneMapping(mode: String)
}

public struct VFXBudget: Codable {
    public let maxParticles: Int
    public let maxLights: Int
    public let shadowQuality: Quality
    public let postProcessing: ProcessingLevel
    public let targetFPS: Int
    
    public enum Quality: String, Codable {
        case low, medium, high, ultra
    }
    
    public enum ProcessingLevel: String, Codable {
        case minimal, standard, full, ultra
    }
}

