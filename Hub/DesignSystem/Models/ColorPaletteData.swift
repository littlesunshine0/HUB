import Foundation
import SwiftData

/// SwiftData model for color palette data from JSON
@Model
final class ColorPaletteData {
    @Attribute(.unique) var id: UUID
    var name: String
    var customName: String?
    var baseHex: String
    var category: String
    var subCategory: String?
    var isPrimary: Bool
    var isSecondary: Bool
    var isTertiary: Bool
    
    // RGB values
    var rgbR: Int
    var rgbG: Int
    var rgbB: Int
    
    // CMYK values
    var cmykC: Double
    var cmykM: Double
    var cmykY: Double
    var cmykK: Double
    
    // Relationships
    @Relationship(deleteRule: .cascade) var tints: [ColorVariant]
    @Relationship(deleteRule: .cascade) var shades: [ColorVariant]
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        customName: String? = nil,
        baseHex: String,
        category: String,
        subCategory: String? = nil,
        isPrimary: Bool = false,
        isSecondary: Bool = false,
        isTertiary: Bool = false,
        rgbR: Int,
        rgbG: Int,
        rgbB: Int,
        cmykC: Double,
        cmykM: Double,
        cmykY: Double,
        cmykK: Double,
        tints: [ColorVariant] = [],
        shades: [ColorVariant] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.customName = customName
        self.baseHex = baseHex
        self.category = category
        self.subCategory = subCategory
        self.isPrimary = isPrimary
        self.isSecondary = isSecondary
        self.isTertiary = isTertiary
        self.rgbR = rgbR
        self.rgbG = rgbG
        self.rgbB = rgbB
        self.cmykC = cmykC
        self.cmykM = cmykM
        self.cmykY = cmykY
        self.cmykK = cmykK
        self.tints = tints
        self.shades = shades
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Color variant (tint or shade)
@Model
final class ColorVariant {
    @Attribute(.unique) var id: UUID
    var name: String
    var baseHex: String
    var variantType: String // "tint" or "shade"
    
    init(
        id: UUID = UUID(),
        name: String,
        baseHex: String,
        variantType: String
    ) {
        self.id = id
        self.name = name
        self.baseHex = baseHex
        self.variantType = variantType
    }
}

// MARK: - JSON Decodable Structures

struct ColorPaletteJSON: Codable {
    let name: String
    let customName: String?
    let base: String
    let category: String
    let subCategory: String?
    let type: ColorType
    let rgb: RGB
    let cmyk: CMYK
    let tints: [ColorVariantJSON]
    let shades: [ColorVariantJSON]
    
    struct ColorType: Codable {
        let primary: Bool
        let secondary: Bool
        let tertiary: Bool
    }
    
    struct RGB: Codable {
        let r: Int
        let g: Int
        let b: Int
    }
    
    struct CMYK: Codable {
        let c: Double
        let m: Double
        let y: Double
        let k: Double
    }
    
    struct ColorVariantJSON: Codable {
        let name: String
        let baseHex: String
    }
    
    /// Convert JSON to SwiftData model
    func toModel() -> ColorPaletteData {
        let tintModels = tints.map { ColorVariant(name: $0.name, baseHex: $0.baseHex, variantType: "tint") }
        let shadeModels = shades.map { ColorVariant(name: $0.name, baseHex: $0.baseHex, variantType: "shade") }
        
        return ColorPaletteData(
            name: name,
            customName: customName,
            baseHex: base,
            category: category,
            subCategory: subCategory,
            isPrimary: type.primary,
            isSecondary: type.secondary,
            isTertiary: type.tertiary,
            rgbR: rgb.r,
            rgbG: rgb.g,
            rgbB: rgb.b,
            cmykC: cmyk.c,
            cmykM: cmyk.m,
            cmykY: cmyk.y,
            cmykK: cmyk.k,
            tints: tintModels,
            shades: shadeModels
        )
    }
}
