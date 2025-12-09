//
//  DesignSystemExporter.swift
//  Hub
//
//  Export design system tokens to various formats
//

import Foundation
import Combine

public struct DesignSystemExporter {
    
    // MARK: - VFX Manifest Export
    
    public static func exportVFXManifest() -> String {
        let manifest: [String: Any] = [
            "version": "1.0.0",
            "particles": [
                "sparkle": [
                    "count": 50,
                    "lifetime": 2.0,
                    "speed": 100,
                    "spread": 360,
                    "color": "#FFD700",
                    "blendMode": "additive"
                ],
                "smoke": [
                    "count": 30,
                    "lifetime": 3.0,
                    "speed": 50,
                    "spread": 45,
                    "color": "#808080",
                    "blendMode": "normal"
                ]
            ],
            "shaders": [
                "bloom": [
                    "intensity": 0.8,
                    "threshold": 0.7,
                    "radius": 5.0,
                    "softKnee": 0.5
                ],
                "vignette": [
                    "intensity": 0.5,
                    "smoothness": 0.4,
                    "roundness": 1.0
                ]
            ],
            "performance": [
                "mobile": [
                    "maxParticles": 500,
                    "maxLights": 4,
                    "shadowQuality": "low",
                    "targetFPS": 60
                ],
                "console": [
                    "maxParticles": 2000,
                    "maxLights": 16,
                    "shadowQuality": "medium",
                    "targetFPS": 60
                ],
                "pc": [
                    "maxParticles": 5000,
                    "maxLights": 32,
                    "shadowQuality": "high",
                    "targetFPS": 60
                ]
            ]
        ]
        
        return toJSON(manifest)
    }
    
    // MARK: - Color Tokens Export
    
    public static func exportColorTokens() -> String {
        let tokens: [String: Any] = [
            "version": "1.0.0",
            "colors": [
                "primary": [
                    "50": "#E3F2FD",
                    "100": "#BBDEFB",
                    "200": "#90CAF9",
                    "300": "#64B5F6",
                    "400": "#42A5F5",
                    "500": "#2196F3",
                    "600": "#1E88E5",
                    "700": "#1976D2",
                    "800": "#1565C0",
                    "900": "#0D47A1"
                ],
                "semantic": [
                    "success": "#4CAF50",
                    "warning": "#FF9800",
                    "error": "#F44336",
                    "info": "#2196F3"
                ]
            ],
            "contrast": [
                "budgets": [
                    "wcag_aa": [
                        "minimumRatio": 4.5,
                        "largeTextRatio": 3.0,
                        "uiComponentRatio": 3.0
                    ],
                    "wcag_aaa": [
                        "minimumRatio": 7.0,
                        "largeTextRatio": 4.5,
                        "uiComponentRatio": 3.0
                    ]
                ]
            ],
            "harmony": [
                "complementary": [
                    "baseHue": 0,
                    "offsets": [180]
                ],
                "triadic": [
                    "baseHue": 0,
                    "offsets": [120, 240]
                ],
                "analogous": [
                    "baseHue": 0,
                    "offsets": [30, -30]
                ]
            ],
            "vibes": [
                "energetic": [
                    "primary": "#FF6B35",
                    "secondary": "#F7931E",
                    "accent": "#FDC830",
                    "background": "#FFFFFF",
                    "text": "#2C3E50"
                ],
                "calm": [
                    "primary": "#6C9BCF",
                    "secondary": "#8BBDD9",
                    "accent": "#A8D8EA",
                    "background": "#F8F9FA",
                    "text": "#2C3E50"
                ]
            ],
            "accessibility": [
                "protanopia": [
                    "primary": "#0173B2",
                    "secondary": "#DE8F05",
                    "success": "#029E73",
                    "warning": "#CC78BC",
                    "error": "#CA9161"
                ],
                "universal": [
                    "primary": "#0173B2",
                    "secondary": "#DE8F05",
                    "success": "#029E73",
                    "warning": "#ECE133",
                    "error": "#CC3311"
                ]
            ]
        ]
        
        return toJSON(tokens)
    }
    
    // MARK: - Lighting Rig Export
    
    public static func exportLightingRig() -> String {
        return """
        # Lighting Rig Configuration
        
        ## Three-Point Lighting Setup
        
        ### Key Light
        - Type: Directional
        - Intensity: 1.0
        - Color: #FFFFFF
        - Temperature: 6500K
        - Position: Azimuth 45°, Elevation 60°
        - Shadows: Hard
        
        ### Fill Light
        - Type: Directional
        - Intensity: 0.4
        - Color: #B0C4DE
        - Temperature: 7500K
        - Position: Azimuth 225°, Elevation 30°
        - Shadows: None
        
        ### Rim Light
        - Type: Directional
        - Intensity: 0.8
        - Color: #FFE4B5
        - Temperature: 3200K
        - Position: Azimuth 135°, Elevation 45°
        - Shadows: None
        
        ### Ambient Light
        - Type: Ambient
        - Intensity: 0.2
        - Color: #87CEEB
        - Temperature: 6000K
        
        ## Shadow/Elevation Ladder
        
        | Elevation | Blur | Spread | Offset Y | Opacity |
        |-----------|------|--------|----------|---------|
        | 0         | 0    | 0      | 0        | 0.0     |
        | 1         | 2    | 0      | 1        | 0.12    |
        | 2         | 4    | 0      | 2        | 0.16    |
        | 3         | 8    | 0      | 4        | 0.20    |
        | 4         | 16   | 0      | 8        | 0.24    |
        | 5         | 24   | 0      | 12       | 0.28    |
        
        ## Global Illumination
        
        ### Indoor
        - Technique: SSGI
        - Bounces: 2
        - Intensity: 0.8
        - Sky Color: #87CEEB
        - Ground Color: #8B7355
        
        ### Outdoor
        - Technique: Light Probes
        - Bounces: 3
        - Intensity: 1.2
        - Sky Color: #87CEEB
        - Ground Color: #228B22
        
        ## Screen Space Effects
        
        ### SSAO (Screen Space Ambient Occlusion)
        - Radius: 0.5
        - Intensity: 1.0
        - Bias: 0.025
        - Samples: 16
        - Quality: High
        
        ### SSR (Screen Space Reflections)
        - Max Distance: 50.0
        - Thickness: 0.5
        - Fade Start: 0.8
        - Fade End: 1.0
        - Quality: Medium
        
        ## Tone Mapping
        
        ### ACES
        - Exposure: 1.0
        - Contrast: 1.0
        - Saturation: 1.0
        - White Point: 1.0
        
        ### Filmic
        - Exposure: 1.0
        - Contrast: 1.1
        - Saturation: 1.05
        - White Point: 1.0
        
        ## Atmospherics
        
        ### Clear
        - Fog Density: 0.0
        - Sky: #87CEEB → #4682B4
        - Sun Intensity: 1.0
        
        ### Sunset
        - Fog Density: 0.02
        - Fog Color: #FFB347
        - Sky: #FF6347 → #FF4500 → #8B008B
        - Sun Intensity: 0.8
        
        ### Night
        - Fog Density: 0.03
        - Fog Color: #191970
        - Sky: #000080 → #000000
        - Sun Intensity: 0.0
        """
    }
    
    // MARK: - Figma Palette Export
    
    public static func exportFigmaPalette() -> String {
        let palette: [String: Any] = [
            "name": "Hub Design System",
            "version": "1.0.0",
            "colors": [
                [
                    "name": "Primary/500",
                    "color": ["r": 0.13, "g": 0.59, "b": 0.95, "a": 1.0],
                    "hex": "#2196F3"
                ],
                [
                    "name": "Success/500",
                    "color": ["r": 0.30, "g": 0.69, "b": 0.31, "a": 1.0],
                    "hex": "#4CAF50"
                ],
                [
                    "name": "Warning/500",
                    "color": ["r": 1.0, "g": 0.60, "b": 0.0, "a": 1.0],
                    "hex": "#FF9800"
                ],
                [
                    "name": "Error/500",
                    "color": ["r": 0.96, "g": 0.26, "b": 0.21, "a": 1.0],
                    "hex": "#F44336"
                ]
            ],
            "styles": [
                [
                    "name": "Elevation/1",
                    "effect": [
                        "type": "DROP_SHADOW",
                        "color": ["r": 0, "g": 0, "b": 0, "a": 0.12],
                        "offset": ["x": 0, "y": 1],
                        "radius": 2,
                        "spread": 0
                    ]
                ],
                [
                    "name": "Elevation/3",
                    "effect": [
                        "type": "DROP_SHADOW",
                        "color": ["r": 0, "g": 0, "b": 0, "a": 0.20],
                        "offset": ["x": 0, "y": 4],
                        "radius": 8,
                        "spread": 0
                    ]
                ]
            ]
        ]
        
        return toJSON(palette)
    }
    
    // MARK: - Complete Design System Export
    
    public static func exportCompleteSystem(to directory: URL) throws {
        // VFX Manifest
        let vfxManifest = exportVFXManifest()
        try vfxManifest.write(to: directory.appendingPathComponent("vfx_manifest.json"), atomically: true, encoding: .utf8)
        
        // Color Tokens
        let colorTokens = exportColorTokens()
        try colorTokens.write(to: directory.appendingPathComponent("color_tokens.json"), atomically: true, encoding: .utf8)
        
        // Lighting Rig
        let lightingRig = exportLightingRig()
        try lightingRig.write(to: directory.appendingPathComponent("lighting_rig.md"), atomically: true, encoding: .utf8)
        
        // Figma Palette
        let figmaPalette = exportFigmaPalette()
        try figmaPalette.write(to: directory.appendingPathComponent("figma_palette.json"), atomically: true, encoding: .utf8)
    }
    
    // MARK: - Helper
    
    private static func toJSON(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
