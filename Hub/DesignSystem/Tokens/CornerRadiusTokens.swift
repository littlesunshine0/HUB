//
//  CornerRadiusTokens.swift
//  Hub
//
//  Unified Corner Radius System
//

import SwiftUI

public enum CornerRadiusToken: CGFloat, Sendable {
    case none = 0
    case xs = 4
    case sm = 8
    case md = 12
    case lg = 16
    case xl = 20
    case xxl = 24
    case full = 9999
    
    public var cgFloat: CGFloat { rawValue }
}

public extension CGFloat {
    static let radiusXS: CGFloat = 4
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusXXL: CGFloat = 24
}
