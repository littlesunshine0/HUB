//
//  EnhancedHubURLBuilder.swift
//  Hub
//
//  Complete URL builder for all Hub modules
//

import Foundation

public struct EnhancedHubURLBuilder {
    
    // MARK: - Template URLs
    
    public static func template(id: String, action: String? = nil) -> URL? {
        buildURL(host: "template", path: id, action: action)
    }
    
    public static var templateGallery: URL? {
        buildURL(host: "template")
    }
    
    // MARK: - Hub URLs
    
    public static func hub(id: String, action: String? = nil) -> URL? {
        buildURL(host: "hub", path: id, action: action)
    }
    
    public static var hubGallery: URL? {
        buildURL(host: "hub")
    }
    
    // MARK: - Marketplace URLs
    
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
    
    // MARK: - AI Module URLs
    
    public static func ai(agent: String? = nil, task: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "ai"
        
        if let agent = agent {
            components.path = "/\(agent)"
        }
        
        if let task = task {
            components.queryItems = [URLQueryItem(name: "task", value: task)]
        }
        
        return components.url
    }
    
    // MARK: - Package Module URLs
    
    public static func package(id: String? = nil, action: String? = nil) -> URL? {
        buildURL(host: "package", path: id, action: action)
    }
    
    // MARK: - Community URLs
    
    public static func community(section: String? = nil, filter: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "community"
        
        if let section = section {
            components.path = "/\(section)"
        }
        
        if let filter = filter {
            components.queryItems = [URLQueryItem(name: "filter", value: filter)]
        }
        
        return components.url
    }
    
    // MARK: - Achievement URLs
    
    public static func achievement(id: String? = nil) -> URL? {
        buildURL(host: "achievement", path: id)
    }
    
    // MARK: - Onboarding URLs
    
    public static func onboarding(role: String? = nil) -> URL? {
        buildURL(host: "onboarding", path: role)
    }
    
    // MARK: - Settings URLs
    
    public static func settings(section: String? = nil) -> URL? {
        buildURL(host: "settings", path: section)
    }
    
    // MARK: - Authentication URLs
    
    public static func auth(flow: String, provider: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "auth"
        components.path = "/\(flow)"
        
        if let provider = provider {
            components.queryItems = [URLQueryItem(name: "provider", value: provider)]
        }
        
        return components.url
    }
    
    // MARK: - Offline Assistant URLs
    
    public static func assistant(query: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = "assistant"
        
        if let query = query {
            components.queryItems = [URLQueryItem(name: "q", value: query)]
        }
        
        return components.url
    }
    
    // MARK: - Design System URLs
    
    public static func designSystem(component: String? = nil) -> URL? {
        buildURL(host: "design", path: component)
    }
    
    // MARK: - Helper Methods
    
    private static func buildURL(
        host: String,
        path: String? = nil,
        action: String? = nil
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "hub"
        components.host = host
        
        if let path = path {
            components.path = "/\(path)"
        }
        
        if let action = action {
            components.queryItems = [URLQueryItem(name: "action", value: action)]
        }
        
        return components.url
    }
    
    // MARK: - URL Validation
    
    public static func isValidHubURL(_ url: URL) -> Bool {
        return url.scheme == "hub" && url.host != nil
    }
    
    // MARK: - URL Shortening
    
    public static func shortenURL(_ url: URL) -> String {
        // Extract key parts
        let host = url.host ?? ""
        let path = url.path.replacingOccurrences(of: "/", with: "")
        
        if path.isEmpty {
            return "hub://\(host)"
        }
        
        return "hub://\(host)/\(path)"
    }
}

// MARK: - URL Extensions

extension URL {
    /// Check if this is a Hub deep link
    public var isHubDeepLink: Bool {
        return scheme == "hub"
    }
    
    /// Get the module name from the URL
    public var hubModule: String? {
        return host
    }
    
    /// Get the resource ID from the URL
    public var hubResourceID: String? {
        let components = path.split(separator: "/")
        return components.first.map(String.init)
    }
    
    /// Get the action from query parameters
    public var hubAction: String? {
        return queryParameters["action"]
    }
}
