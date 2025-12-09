//
//  APIProtocol.swift
//  Hub
//
//  Core API protocol definitions for inter-program communication
//

import Foundation

// MARK: - API Protocol

/// Base protocol for all API endpoints
public protocol APIEndpoint {
    associatedtype Response: Codable
    
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryParameters: [String: String]? { get }
    var body: Data? { get }
    var requiresAuthentication: Bool { get }
}

// MARK: - HTTP Method

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}

// MARK: - API Request

public struct APIRequest<T: Codable>: Codable {
    public let id: String
    public let timestamp: Date
    public let version: String
    public let endpoint: String
    public let method: String
    public let headers: [String: String]
    public let parameters: [String: String]?
    public let body: T?
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        version: String = "1.0",
        endpoint: String,
        method: String,
        headers: [String: String] = [:],
        parameters: [String: String]? = nil,
        body: T? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.version = version
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.parameters = parameters
        self.body = body
    }
}

// MARK: - API Response

public struct APIResponse<T: Codable>: Codable {
    public let id: String
    public let requestId: String
    public let timestamp: Date
    public let statusCode: Int
    public let success: Bool
    public let data: T?
    public let error: APIError?
    public let metadata: ResponseMetadata?
    
    public init(
        id: String = UUID().uuidString,
        requestId: String,
        timestamp: Date = Date(),
        statusCode: Int,
        success: Bool,
        data: T? = nil,
        error: APIError? = nil,
        metadata: ResponseMetadata? = nil
    ) {
        self.id = id
        self.requestId = requestId
        self.timestamp = timestamp
        self.statusCode = statusCode
        self.success = success
        self.data = data
        self.error = error
        self.metadata = metadata
    }
}

// MARK: - Response Metadata

public struct ResponseMetadata: Codable {
    public let processingTime: TimeInterval
    public let serverVersion: String
    public let rateLimit: RateLimitInfo?
    public let pagination: PaginationInfo?
    
    public init(
        processingTime: TimeInterval,
        serverVersion: String,
        rateLimit: RateLimitInfo? = nil,
        pagination: PaginationInfo? = nil
    ) {
        self.processingTime = processingTime
        self.serverVersion = serverVersion
        self.rateLimit = rateLimit
        self.pagination = pagination
    }
}

// MARK: - Rate Limit Info

public struct RateLimitInfo: Codable {
    public let limit: Int
    public let remaining: Int
    public let resetAt: Date
    
    public init(limit: Int, remaining: Int, resetAt: Date) {
        self.limit = limit
        self.remaining = remaining
        self.resetAt = resetAt
    }
}

// MARK: - Pagination Info

public struct PaginationInfo: Codable {
    public let page: Int
    public let pageSize: Int
    public let totalPages: Int
    public let totalItems: Int
    public let hasNext: Bool
    public let hasPrevious: Bool
    
    public init(
        page: Int,
        pageSize: Int,
        totalPages: Int,
        totalItems: Int,
        hasNext: Bool,
        hasPrevious: Bool
    ) {
        self.page = page
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.totalItems = totalItems
        self.hasNext = hasNext
        self.hasPrevious = hasPrevious
    }
}

// MARK: - API Error

public struct APIError: Codable, Error {
    public let code: String
    public let message: String
    public let details: [String: String]?
    public let timestamp: Date
    
    public init(
        code: String,
        message: String,
        details: [String: String]? = nil,
        timestamp: Date = Date()
    ) {
        self.code = code
        self.message = message
        self.details = details
        self.timestamp = timestamp
    }
}

// MARK: - API Client Protocol

public protocol APIClient {
    func send<T: Codable>(_ request: APIRequest<T>) async throws -> APIResponse<T>
    func authenticate(credentials: APICredentials) async throws -> AuthenticationToken
    func refreshToken(_ token: AuthenticationToken) async throws -> AuthenticationToken
}

// MARK: - Authentication

public struct APICredentials: Codable {
    public let clientId: String
    public let clientSecret: String
    public let scope: [String]
    
    public init(clientId: String, clientSecret: String, scope: [String] = []) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.scope = scope
    }
}

public struct AuthenticationToken: Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let tokenType: String
    public let expiresIn: TimeInterval
    public let scope: [String]
    public let issuedAt: Date
    
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: String = "Bearer",
        expiresIn: TimeInterval,
        scope: [String] = [],
        issuedAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
        self.issuedAt = issuedAt
    }
    
    public var isExpired: Bool {
        Date().timeIntervalSince(issuedAt) >= expiresIn
    }
}

// MARK: - Webhook Protocol

public protocol WebhookHandler {
    func handle(event: WebhookEvent) async throws
    func verify(signature: String, payload: Data) -> Bool
}

public struct WebhookEvent: Codable {
    public let id: String
    public let type: String
    public let timestamp: Date
    public let data: [String: AnyCodable]
    public let signature: String?
    
    public init(
        id: String = UUID().uuidString,
        type: String,
        timestamp: Date = Date(),
        data: [String: AnyCodable],
        signature: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.data = data
        self.signature = signature
    }
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }
}
