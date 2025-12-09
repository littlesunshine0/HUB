//
//  CentersModule.swift
//  Hub
//
//  Centralized Centers System
//

import SwiftUI

/// Main Centers Module - Provides access to all center types
public struct CentersModule {
    public static let shared = CentersModule()
    
    private init() {}
    
    // MARK: - Center Types
    
    public enum CenterType: String, CaseIterable, Identifiable {
        case action = "Action Center"
        case control = "Control Center"
        case help = "Help Center"
        case knowledge = "Knowledge Center"
        case download = "Download Center"
        case security = "Security Center"
        case admin = "Administration Center"
        case media = "Media Center"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .action: return "bell.badge.fill"
            case .control: return "slider.horizontal.3"
            case .help: return "questionmark.circle.fill"
            case .knowledge: return "book.fill"
            case .download: return "arrow.down.circle.fill"
            case .security: return "lock.shield.fill"
            case .admin: return "gearshape.2.fill"
            case .media: return "photo.on.rectangle.angled"
            }
        }
        
        public var description: String {
            switch self {
            case .action: return "Centralized notifications and quick actions"
            case .control: return "Manage settings and configurations"
            case .help: return "Documentation, FAQs, and support"
            case .knowledge: return "Technical articles and guides"
            case .download: return "Manage hub and template downloads"
            case .security: return "Security status and controls"
            case .admin: return "System administration console"
            case .media: return "Organize glyphs, icons, and media"
            }
        }
        
        public var color: Color {
            switch self {
            case .action: return .orange
            case .control: return .blue
            case .help: return .green
            case .knowledge: return .purple
            case .download: return .cyan
            case .security: return .red
            case .admin: return .indigo
            case .media: return .pink
            }
        }
    }
}
