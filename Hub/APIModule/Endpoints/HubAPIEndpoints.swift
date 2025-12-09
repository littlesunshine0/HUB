//
//  HubAPIEndpoints.swift
//  Hub
//
//  Specific API endpoints for Hub operations
//

import Foundation

// MARK: - Hub Endpoints

public enum HubAPI {
    case list(page: Int, pageSize: Int)
    case get(id: String)
    case create(hub: HubCreateRequest)
    case update(id: String, hub: HubUpdateRequest)
    case delete(id: String)
    case search(query: String, filters: [String: String]?)
    case share(id: String, shareRequest: ShareRequest)
    case sync(hubs: [String])
}

extension HubAPI: APIEndpoint {
    public typealias Response = HubResponse
    
    public var path: String {
        switch self {
        case .list:
            return "/hubs"
        case .get(let id):
            return "/hubs/\(id)"
        case .create:
            return "/hubs"
        case .update(let id, _):
            return "/hubs/\(id)"
        case .delete(let id):
            return "/hubs/\(id)"
        case .search:
            return "/hubs/search"
        case .share(let id, _):
            return "/hubs/\(id)/share"
        case .sync:
            return "/hubs/sync"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .list, .get, .search:
            return .get
        case .create, .share, .sync:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        }
    }
    
    public var headers: [String: String] {
        return ["Content-Type": "application/json"]
    }
    
    public var queryParameters: [String: String]? {
        switch self {
        case .list(let page, let pageSize):
            return ["page": "\(page)", "pageSize": "\(pageSize)"]
        case .search(let query, let filters):
            var params = ["q": query]
            if let filters = filters {
                params.merge(filters) { $1 }
            }
            return params
        default:
            return nil
        }
    }
    
    public var body: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        switch self {
        case .create(let hub):
            return try? encoder.encode(hub)
        case .update(_, let hub):
            return try? encoder.encode(hub)
        case .share(_, let shareRequest):
            return try? encoder.encode(shareRequest)
        case .sync(let hubs):
            return try? encoder.encode(["hubIds": hubs])
        default:
            return nil
        }
    }
    
    public var requiresAuthentication: Bool {
        return true
    }
}

// MARK: - Template Endpoints

public enum TemplateAPI {
    case list(category: String?)
    case get(id: String)
    case create(template: TemplateCreateRequest)
    case update(id: String, template: TemplateUpdateRequest)
    case delete(id: String)
    case download(id: String)
    case publish(id: String)
}

extension TemplateAPI: APIEndpoint {
    public typealias Response = TemplateResponse
    
    public var path: String {
        switch self {
        case .list:
            return "/templates"
        case .get(let id):
            return "/templates/\(id)"
        case .create:
            return "/templates"
        case .update(let id, _):
            return "/templates/\(id)"
        case .delete(let id):
            return "/templates/\(id)"
        case .download(let id):
            return "/templates/\(id)/download"
        case .publish(let id):
            return "/templates/\(id)/publish"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .list, .get, .download:
            return .get
        case .create, .publish:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        }
    }
    
    public var headers: [String: String] {
        return ["Content-Type": "application/json"]
    }
    
    public var queryParameters: [String: String]? {
        switch self {
        case .list(let category):
            return category != nil ? ["category": category!] : nil
        default:
            return nil
        }
    }
    
    public var body: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        switch self {
        case .create(let template):
            return try? encoder.encode(template)
        case .update(_, let template):
            return try? encoder.encode(template)
        default:
            return nil
        }
    }
    
    public var requiresAuthentication: Bool {
        switch self {
        case .list, .get:
            return false
        default:
            return true
        }
    }
}

// MARK: - User Endpoints

public enum UserAPI {
    case profile
    case update(profile: UserProfileUpdate)
    case settings
    case updateSettings(settings: UserSettings)
    case activity(page: Int)
}

extension UserAPI: APIEndpoint {
    public typealias Response = UserResponse
    
    public var path: String {
        switch self {
        case .profile, .update:
            return "/user/profile"
        case .settings, .updateSettings:
            return "/user/settings"
        case .activity:
            return "/user/activity"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .profile, .settings, .activity:
            return .get
        case .update, .updateSettings:
            return .put
        }
    }
    
    public var headers: [String: String] {
        return ["Content-Type": "application/json"]
    }
    
    public var queryParameters: [String: String]? {
        switch self {
        case .activity(let page):
            return ["page": "\(page)"]
        default:
            return nil
        }
    }
    
    public var body: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        switch self {
        case .update(let profile):
            return try? encoder.encode(profile)
        case .updateSettings(let settings):
            return try? encoder.encode(settings)
        default:
            return nil
        }
    }
    
    public var requiresAuthentication: Bool {
        return true
    }
}

// MARK: - Request/Response Models

public struct HubCreateRequest: Codable {
    public let name: String
    public let description: String
    public let category: String
    public let templateId: String?
    public let icon: String
    public let tags: [String]
    
    public init(name: String, description: String, category: String, templateId: String? = nil, icon: String, tags: [String] = []) {
        self.name = name
        self.description = description
        self.category = category
        self.templateId = templateId
        self.icon = icon
        self.tags = tags
    }
}

public struct HubUpdateRequest: Codable {
    public let name: String?
    public let description: String?
    public let icon: String?
    public let tags: [String]?
    
    public init(name: String? = nil, description: String? = nil, icon: String? = nil, tags: [String]? = nil) {
        self.name = name
        self.description = description
        self.icon = icon
        self.tags = tags
    }
}

public struct HubResponse: Codable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let icon: String
    public let tags: [String]
    public let createdAt: Date
    public let updatedAt: Date
    public let userId: String
}

public struct ShareRequest: Codable {
    public let recipients: [String]
    public let permissions: [String]
    public let message: String?
    
    public init(recipients: [String], permissions: [String], message: String? = nil) {
        self.recipients = recipients
        self.permissions = permissions
        self.message = message
    }
}

public struct TemplateCreateRequest: Codable {
    public let name: String
    public let description: String
    public let category: String
    public let features: [String]
    public let tags: [String]
    
    public init(name: String, description: String, category: String, features: [String], tags: [String]) {
        self.name = name
        self.description = description
        self.category = category
        self.features = features
        self.tags = tags
    }
}

public struct TemplateUpdateRequest: Codable {
    public let name: String?
    public let description: String?
    public let features: [String]?
    public let tags: [String]?
    
    public init(name: String? = nil, description: String? = nil, features: [String]? = nil, tags: [String]? = nil) {
        self.name = name
        self.description = description
        self.features = features
        self.tags = tags
    }
}

public struct TemplateResponse: Codable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let features: [String]
    public let tags: [String]
    public let downloads: Int
    public let rating: Double
    public let createdAt: Date
}

public struct UserProfileUpdate: Codable {
    public let fullName: String?
    public let email: String?
    public let bio: String?
    public let avatar: String?
    
    public init(fullName: String? = nil, email: String? = nil, bio: String? = nil, avatar: String? = nil) {
        self.fullName = fullName
        self.email = email
        self.bio = bio
        self.avatar = avatar
    }
}

public struct UserSettings: Codable {
    public let theme: String?
    public let notifications: Bool?
    public let autoSync: Bool?
    public let language: String?
    
    public init(theme: String? = nil, notifications: Bool? = nil, autoSync: Bool? = nil, language: String? = nil) {
        self.theme = theme
        self.notifications = notifications
        self.autoSync = autoSync
        self.language = language
    }
}

public struct UserResponse: Codable {
    public let id: String
    public let username: String
    public let email: String
    public let fullName: String
    public let bio: String?
    public let avatar: String?
    public let createdAt: Date
}
