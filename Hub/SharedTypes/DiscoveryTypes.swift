//
//  DiscoveryTypes.swift
//  Hub
//
//  Shared types for hub discovery and browsing
//

import Foundation
import SwiftUI

// MARK: - Hub Discovery Category

/// Categories for hub discovery/marketplace
public enum HubDiscoveryCategory: String, CaseIterable, Codable, Sendable {
    case development = "Development"
    case content = "Content & Media"
    case collaboration = "Collaboration"
    case analytics = "Analytics"
    
    public var icon: String {
        switch self {
        case .development: return "hammer.fill"
        case .content: return "photo.stack.fill"
        case .collaboration: return "person.2.fill"
        case .analytics: return "chart.bar.fill"
        }
    }
}

// MARK: - Hub Sort Option

/// Sorting options for hub lists
public enum HubSortOption: String, CaseIterable, Sendable {
    case featured = "Featured"
    case name = "Name"
    case category = "Category"
    case newest = "Newest"
    case popular = "Popular"
    
    public var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .name: return "textformat.abc"
        case .category: return "folder.fill"
        case .newest: return "clock.fill"
        case .popular: return "arrow.up.right"
        }
    }
}
