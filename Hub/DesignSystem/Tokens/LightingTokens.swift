//
//  LightingTokens.swift
//  Hub
//
//  Lighting, shadowing, and tone-mapping tokens
//

import SwiftUI

public struct LightingTokens {
    
    // MARK: - Light Configurations
    
    public struct Lights {
        public static let keyLight = LightConfig(
            type: .directional,
            intensity: 1.0,
            color: "#FFFFFF",
            temperature: 6500,
            shadows: .hard,
            angle: LightAngle(azimuth: 45, elevation: 60)
        )
        
        public static let fillLight = LightConfig(
            type: .directional,
            intensity: 0.4,
            color: "#B0C4DE",
            temperature: 7500,
            shadows: .none,
            angle: LightAngle(azimuth: 225, elevation: 30)
        )
        
        public static let rimLight = LightConfig(
            type: .directional,
            intensity: 0.8,
            color: "#FFE4B5",
            temperature: 3200,
            shadows: .none,
            angle: LightAngle(azimuth: 135, elevation: 45)
        )
        
        public static let ambient = LightConfig(
            type: .ambient,
            intensity: 0.2,
            color: "#87CEEB",
            temperature: 6000,
            shadows: .none,
            angle: LightAngle(azimuth: 0, elevation: 90)
        )
    }
    
    // MARK: - Shadow Configurations
    
    public struct Shadows {
        // Shadow/Elevation Ladder
        public static let elevation0 = LightingShadowConfig(
            blur: 0,
            spread: 0,
            offset: CGSize(width: 0, height: 0),
            color: "#000000",
            opacity: 0.0
        )
        
        public static let elevation1 = LightingShadowConfig(
            blur: 2,
            spread: 0,
            offset: CGSize(width: 0, height: 1),
            color: "#000000",
            opacity: 0.12
        )
        
        public static let elevation2 = LightingShadowConfig(
            blur: 4,
            spread: 0,
            offset: CGSize(width: 0, height: 2),
            color: "#000000",
            opacity: 0.16
        )
        
        public static let elevation3 = LightingShadowConfig(
            blur: 8,
            spread: 0,
            offset: CGSize(width: 0, height: 4),
            color: "#000000",
            opacity: 0.20
        )
        
        public static let elevation4 = LightingShadowConfig(
            blur: 16,
            spread: 0,
            offset: CGSize(width: 0, height: 8),
            color: "#000000",
            opacity: 0.24
        )
        
        public static let elevation5 = LightingShadowConfig(
            blur: 24,
            spread: 0,
            offset: CGSize(width: 0, height: 12),
            color: "#000000",
            opacity: 0.28
        )
    }
    
    // MARK: - Global Illumination
    
    public struct GlobalIllumination {
        public static let indoor = GIConfig(
            technique: .ssgi,
            bounces: 2,
            intensity: 0.8,
            skyColor: "#87CEEB",
            groundColor: "#8B7355"
        )
        
        public static let outdoor = GIConfig(
            technique: .lightProbes,
            bounces: 3,
            intensity: 1.2,
            skyColor: "#87CEEB",
            groundColor: "#228B22"
        )
        
        public static let studio = GIConfig(
            technique: .none,
            bounces: 0,
            intensity: 0.0,
            skyColor: "#000000",
            groundColor: "#000000"
        )
    }
    
    // MARK: - Screen Space Effects
    
    public struct ScreenSpace {
        public static let ssao = SSAOConfig(
            radius: 0.5,
            intensity: 1.0,
            bias: 0.025,
            samples: 16,
            quality: .high
        )
        
        public static let ssr = SSRConfig(
            maxDistance: 50.0,
            thickness: 0.5,
            fadeStart: 0.8,
            fadeEnd: 1.0,
            quality: .medium
        )
        
        public static let ssgi = SSGIConfig(
            bounces: 1,
            intensity: 1.0,
            radius: 2.0,
            samples: 32,
            quality: .medium
        )
    }
    
    // MARK: - Atmospherics
    
    public struct Atmospherics {
        public static let clear = AtmosphericConfig(
            fogDensity: 0.0,
            fogColor: "#FFFFFF",
            skyGradient: ["#87CEEB", "#4682B4"],
            sunIntensity: 1.0,
            cloudCoverage: 0.0
        )
        
        public static let overcast = AtmosphericConfig(
            fogDensity: 0.05,
            fogColor: "#D3D3D3",
            skyGradient: ["#A9A9A9", "#696969"],
            sunIntensity: 0.4,
            cloudCoverage: 0.8
        )
        
        public static let sunset = AtmosphericConfig(
            fogDensity: 0.02,
            fogColor: "#FFB347",
            skyGradient: ["#FF6347", "#FF4500", "#8B008B"],
            sunIntensity: 0.8,
            cloudCoverage: 0.3
        )
        
        public static let night = AtmosphericConfig(
            fogDensity: 0.03,
            fogColor: "#191970",
            skyGradient: ["#000080", "#000000"],
            sunIntensity: 0.0,
            cloudCoverage: 0.2
        )
    }
    
    // MARK: - Tone Mapping
    
    public struct ToneMapping {
        public static let aces = ToneMappingConfig(
            mode: .aces,
            exposure: 1.0,
            contrast: 1.0,
            saturation: 1.0,
            whitePoint: 1.0
        )
        
        public static let filmic = ToneMappingConfig(
            mode: .filmic,
            exposure: 1.0,
            contrast: 1.1,
            saturation: 1.05,
            whitePoint: 1.0
        )
        
        public static let reinhard = ToneMappingConfig(
            mode: .reinhard,
            exposure: 1.0,
            contrast: 1.0,
            saturation: 1.0,
            whitePoint: 2.0
        )
        
        public static let uncharted = ToneMappingConfig(
            mode: .uncharted,
            exposure: 1.2,
            contrast: 1.15,
            saturation: 1.1,
            whitePoint: 11.2
        )
    }
    
    // MARK: - Lighting Presets
    
    public struct Presets {
        public static let threePoint = LightingPreset(
            name: "Three-Point Lighting",
            lights: [
                Lights.keyLight,
                Lights.fillLight,
                Lights.rimLight
            ],
            ambient: Lights.ambient,
            shadows: Shadows.elevation3
        )
        
        public static let dramatic = LightingPreset(
            name: "Dramatic",
            lights: [
                LightConfig(type: .directional, intensity: 1.5, color: "#FFFFFF", temperature: 5500, shadows: .hard, angle: LightAngle(azimuth: 90, elevation: 45)),
                LightConfig(type: .directional, intensity: 0.2, color: "#4169E1", temperature: 8000, shadows: .none, angle: LightAngle(azimuth: 270, elevation: 20))
            ],
            ambient: LightConfig(type: .ambient, intensity: 0.1, color: "#000033", temperature: 6000, shadows: .none, angle: LightAngle(azimuth: 0, elevation: 90)),
            shadows: Shadows.elevation4
        )
        
        public static let soft = LightingPreset(
            name: "Soft",
            lights: [
                LightConfig(type: .directional, intensity: 0.8, color: "#FFF8DC", temperature: 5000, shadows: .soft, angle: LightAngle(azimuth: 45, elevation: 60)),
                LightConfig(type: .directional, intensity: 0.6, color: "#F0E68C", temperature: 4500, shadows: .none, angle: LightAngle(azimuth: 315, elevation: 40))
            ],
            ambient: LightConfig(type: .ambient, intensity: 0.4, color: "#FFFACD", temperature: 5500, shadows: .none, angle: LightAngle(azimuth: 0, elevation: 90)),
            shadows: Shadows.elevation2
        )
    }
}

// MARK: - Supporting Types

public struct LightConfig: Codable {
    public let type: LightType
    public let intensity: Double
    public let color: String
    public let temperature: Int // Kelvin
    public let shadows: ShadowType
    public let angle: LightAngle
    
    public enum LightType: String, Codable {
        case directional, point, spot, ambient, area
    }
    
    public enum ShadowType: String, Codable {
        case none, soft, hard
    }
}

public struct LightAngle: Codable {
    public let azimuth: Double // 0-360
    public let elevation: Double // 0-90
}

public struct LightingShadowConfig: Codable {
    public let blur: Double
    public let spread: Double
    public let offset: CGSize
    public let color: String
    public let opacity: Double
}

public struct GIConfig: Codable {
    public let technique: GITechnique
    public let bounces: Int
    public let intensity: Double
    public let skyColor: String
    public let groundColor: String
    
    public enum GITechnique: String, Codable {
        case none, lightProbes, ssgi, rayTraced
    }
}

public struct SSAOConfig: Codable {
    public let radius: Double
    public let intensity: Double
    public let bias: Double
    public let samples: Int
    public let quality: Quality
    
    public enum Quality: String, Codable {
        case low, medium, high, ultra
    }
}

public struct SSRConfig: Codable {
    public let maxDistance: Double
    public let thickness: Double
    public let fadeStart: Double
    public let fadeEnd: Double
    public let quality: Quality
    
    public enum Quality: String, Codable {
        case low, medium, high, ultra
    }
}

public struct SSGIConfig: Codable {
    public let bounces: Int
    public let intensity: Double
    public let radius: Double
    public let samples: Int
    public let quality: Quality
    
    public enum Quality: String, Codable {
        case low, medium, high, ultra
    }
}

public struct AtmosphericConfig: Codable {
    public let fogDensity: Double
    public let fogColor: String
    public let skyGradient: [String]
    public let sunIntensity: Double
    public let cloudCoverage: Double
}

public struct ToneMappingConfig: Codable {
    public let mode: ToneMappingMode
    public let exposure: Double
    public let contrast: Double
    public let saturation: Double
    public let whitePoint: Double
    
    public enum ToneMappingMode: String, Codable {
        case linear, reinhard, filmic, aces, uncharted
    }
}

public struct LightingPreset: Codable {
    public let name: String
    public let lights: [LightConfig]
    public let ambient: LightConfig
    public let shadows: LightingShadowConfig
}
