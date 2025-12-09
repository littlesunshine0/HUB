//
//  ValidationTypes.swift
//  Hub
//
//  Shared validation types used across the app
//

import Foundation

// MARK: - Validation Issue

/// Represents a validation issue found during hub/template validation
public struct ValidationIssue: Identifiable, Sendable {
    public let id: UUID
    public let severity: Severity
    public let message: String
    
    public init(id: UUID = UUID(), severity: Severity, message: String) {
        self.id = id
        self.severity = severity
        self.message = message
    }
    
    public enum Severity: String, Sendable, CaseIterable {
        case error
        case warning
        case info
    }
}

// MARK: - Dependency Status

/// Status of a dependency resolution
public enum DependencyStatus: Equatable, Sendable {
    case available
    case missing
    case unknown
    case error(String)
}
