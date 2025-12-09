import Foundation
import Combine



// MARK: - Achievement Category

public enum AchievementCategory: String, CaseIterable {
    case general = "General"
    case building = "Building"
    case templates = "Templates"
    case sharing = "Sharing"
    case customization = "Customization"
    
    var icon: String {
        switch self {
        case .general: return "star.fill"
        case .building: return "hammer.fill"
        case .templates: return "doc.text.fill"
        case .sharing: return "square.and.arrow.up.fill"
        case .customization: return "paintbrush.fill"
        }
    }
}

// MARK: - Achievement Rarity

public enum AchievementRarity: String, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: String {
        switch self {
        case .common: return "#808080"      // Gray
        case .uncommon: return "#00FF00"    // Green
        case .rare: return "#0070DD"        // Blue
        case .epic: return "#A335EE"        // Purple
        case .legendary: return "#FF8000"   // Orange
        }
    }
}

