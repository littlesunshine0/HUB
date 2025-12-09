//
//  DeepLinkHandler.swift
//  Hub
//
//  Handles deep linking to templates and hubs via URL schemes
//

import SwiftUI
import Combine

/// Deep link handler for Hub URL schemes
/// Supports: hub://template/{id}, hub://hub/{id}, hub://marketplace, etc.
@MainActor
public class DeepLinkHandler: ObservableObject {
    @Published public var activeDeepLink: DeepLink?
    
    public init() {}
    
    // MARK: - URL Handling
    
    /// Handle incoming URL
    public func handle(url: URL) {
        guard url.scheme == "hub" else {
            print("⚠️ Invalid URL scheme: \(url.scheme ?? "none")")
            return
        }
        
        let host = url.host ?? ""
        let path = url.path
        let components = path.split(separator: "/").map(String.init)
        
        switch host {
        case "template":
            handleTemplateURL(components: components, query: url.queryParameters)
            
        case "hub":
            handleHubURL(components: components, query: url.queryParameters)
            
        case "marketplace":
            handleMarketplaceURL(components: components, query: url.queryParameters)
            
        case "onboarding":
            handleOnboardingURL(components: components, query: url.queryParameters)
            
        case "settings":
            handleSettingsURL(components: components, query: url.queryParameters)
            
        default:
            print("⚠️ Unknown URL host: \(host)")
        }
    }
    
    // MARK: - Template URLs
    
    /// Handle template URLs: hub://template/{id}
    private func handleTemplateURL(components: [String], query: [String: String]) {
        guard let templateId = components.first else {
            // No ID - show template gallery
            activeDeepLink = .templateGallery
            return
        }
        
        // Open specific template
        activeDeepLink = .template(id: templateId, action: query["action"])
    }
    
    // MARK: - Hub URLs
    
    /// Handle hub URLs: hub://hub/{id}
    private func handleHubURL(components: [String], query: [String: String]) {
        guard let hubId = components.first else {
            // No ID - show hub gallery
            activeDeepLink = .hubGallery
            return
        }
        
        // Open specific hub
        activeDeepLink = .hub(id: hubId, action: query["action"])
    }
    
    // MARK: - Marketplace URLs
    
    /// Handle marketplace URLs: hub://marketplace/{category}
    private func handleMarketplaceURL(components: [String], query: [String: String]) {
        let category = components.first
        let searchQuery = query["search"]
        
        activeDeepLink = .marketplace(category: category, search: searchQuery)
    }
    
    // MARK: - Onboarding URLs
    
    /// Handle onboarding URLs: hub://onboarding/{role}
    private func handleOnboardingURL(components: [String], query: [String: String]) {
        let role = components.first
        activeDeepLink = .onboarding(role: role)
    }
    
    // MARK: - Settings URLs
    
    /// Handle settings URLs: hub://settings/{section}
    private func handleSettingsURL(components: [String], query: [String: String]) {
        let section = components.first
        activeDeepLink = .settings(section: section)
    }
    
    // MARK: - Clear
    
    /// Clear active deep link
    public func clearDeepLink() {
        activeDeepLink = nil
    }
}

// MARK: - Deep Link Types

public enum DeepLink: Equatable {
    case template(id: String, action: String?)
    case templateGallery
    case hub(id: String, action: String?)
    case hubGallery
    case marketplace(category: String?, search: String?)
    case onboarding(role: String?)
    case settings(section: String?)
    
    public var description: String {
        switch self {
        case .template(let id, let action):
            return "Template: \(id)" + (action.map { " (\($0))" } ?? "")
        case .templateGallery:
            return "Template Gallery"
        case .hub(let id, let action):
            return "Hub: \(id)" + (action.map { " (\($0))" } ?? "")
        case .hubGallery:
            return "Hub Gallery"
        case .marketplace(let category, let search):
            var desc = "Marketplace"
            if let cat = category { desc += " - \(cat)" }
            if let search = search { desc += " (search: \(search))" }
            return desc
        case .onboarding(let role):
            return "Onboarding" + (role.map { r in " - \(r)" } ?? "")
        case .settings(let section):
            return "Settings" + (section.map { " - \($0)" } ?? "")
        }
    }
}

// MARK: - URL Extensions

extension URL {
    /// Parse query parameters from URL
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        return params
    }
}

// MARK: - URL Builder

public struct HubURLBuilder {
    
    /// Build template URL
    public static func template(id: String, action: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "template"
        components.path = "/\(id)"
        
        if let action = action {
            components.queryItems = [URLQueryItem(name: "action", value: action)]
        }
        
        return components.url
    }
    
    /// Build hub URL
    public static func hub(id: String, action: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "hub"
        components.path = "/\(id)"
        
        if let action = action {
            components.queryItems = [URLQueryItem(name: "action", value: action)]
        }
        
        return components.url
    }
    
    /// Build marketplace URL
    public static func marketplace(category: String? = nil, search: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "marketplace"
        
        if let category = category {
            components.path = "/\(category)"
        }
        
        var queryItems: [URLQueryItem] = []
        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url
    }
    
    /// Build template gallery URL
    public static var templateGallery: URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "template"
        return components.url
    }
    
    /// Build hub gallery URL
    public static var hubGallery: URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "hub"
        return components.url
    }
    
    /// Build onboarding URL
    public static func onboarding(role: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "onboarding"
        
        if let role = role {
            components.path = "/\(role)"
        }
        
        return components.url
    }
    
    /// Build settings URL
    public static func settings(section: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "settings"
        
        if let section = section {
            components.path = "/\(section)"
        }
        
        return components.url
    }
}
