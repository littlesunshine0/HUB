//
//  IntegrationTypes.swift
//  Hub
//
//  Shared types for system integration
//

import Foundation

// MARK: - Integration Status

/// Status of a system integration
public enum IntegrationStatus: String, Sendable, CaseIterable {
    case connected
    case warning
    case disconnected
    case error
}

#if canImport(SwiftUI)
import SwiftUI

extension IntegrationStatus {
    public var color: Color {
        switch self {
        case .connected: return .green
        case .warning: return .orange
        case .disconnected, .error: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .disconnected, .error: return "xmark.circle.fill"
        }
    }
}
#endif

// Note: CollaborationSession and SmartRecommendation are defined in CommunityNetworkModule
