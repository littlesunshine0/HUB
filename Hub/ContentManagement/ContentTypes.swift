//
//  ContentTypes.swift
//  Hub
//
//  Unified content type definitions for all manageable content
//

import Foundation
import SwiftUI

// MARK: - Hub Content Type

/// All manageable content types in the Hub system
public enum HubContentType: String, CaseIterable, Identifiable, Sendable {
    case hub = "Hub"
    case template = "Template"
    case component = "Component"
    case module = "Module"
    case blueprint = "Blueprint"
    case package = "Package"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .hub: return "square.stack.3d.up.fill"
        case .template: return "doc.text.fill"
        case .component: return "cube.fill"
        case .module: return "shippingbox.fill"
        case .blueprint: return "square.grid.3x3.fill"
        case .package: return "gift.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .hub: return .purple
        case .template: return .blue
        case .component: return .green
        case .module: return .orange
        case .blueprint: return .pink
        case .package: return .red
        }
    }
    
    public var pluralName: String {
        switch self {
        case .hub: return "Hubs"
        case .template: return "Templates"
        case .component: return "Components"
        case .module: return "Modules"
        case .blueprint: return "Blueprints"
        case .package: return "Packages"
        }
    }
}

// MARK: - View Mode

/// Different view modes for content display
public enum ContentViewMode: String, CaseIterable, Identifiable, Sendable {
    // Display modes
    case gallery = "Gallery"
    case icon = "Icon"
    case column = "Column"
    case list = "List"
    case table = "Table"
    
    // Detail modes
    case detail = "Detail"
    case edit = "Edit"
    case live = "Live"
    case preview = "Preview"
    case quick = "Quick"
    
    // File modes
    case folder = "Folder"
    case file = "File"
    case project = "Project"
    case package = "Package"
    
    // Advanced modes
    case dragDrop = "Drag & Drop"
    case liveRender = "Live Render"
    case parser = "Parser"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .gallery: return "square.grid.2x2"
        case .icon: return "square.grid.3x3"
        case .column: return "rectangle.split.3x1"
        case .list: return "list.bullet"
        case .table: return "tablecells"
        case .detail: return "doc.text.magnifyingglass"
        case .edit: return "pencil.circle"
        case .live: return "play.circle"
        case .preview: return "eye"
        case .quick: return "bolt"
        case .folder: return "folder"
        case .file: return "doc"
        case .project: return "folder.badge.gearshape"
        case .package: return "shippingbox"
        case .dragDrop: return "hand.draw"
        case .liveRender: return "wand.and.stars"
        case .parser: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    public var isDisplayMode: Bool {
        switch self {
        case .gallery, .icon, .column, .list, .table: return true
        default: return false
        }
    }
}

// MARK: - Content Item Protocol

/// Protocol for all content items
public protocol ContentItem: Identifiable {
    var id: UUID { get }
    var name: String { get set }
    var contentDescription: String { get }
    var icon: String { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var contentType: HubContentType { get }
}

// MARK: - Content Action

/// Actions that can be performed on content
public enum ContentAction: String, CaseIterable, Sendable {
    case create = "Create"
    case read = "Read"
    case update = "Update"
    case delete = "Delete"
    case duplicate = "Duplicate"
    case export = "Export"
    case share = "Share"
    case build = "Build"
    case launch = "Launch"
    case preview = "Preview"
    case archive = "Archive"
    
    public var icon: String {
        switch self {
        case .create: return "plus.circle"
        case .read: return "eye"
        case .update: return "pencil"
        case .delete: return "trash"
        case .duplicate: return "doc.on.doc"
        case .export: return "square.and.arrow.up"
        case .share: return "square.and.arrow.up.on.square"
        case .build: return "hammer"
        case .launch: return "play"
        case .preview: return "eye.circle"
        case .archive: return "archivebox"
        }
    }
    
    public var isDestructive: Bool {
        self == .delete
    }
}
