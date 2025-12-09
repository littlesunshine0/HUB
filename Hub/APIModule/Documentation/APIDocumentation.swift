//
//  APIDocumentation.swift
//  Hub
//
//  API documentation generator and viewer
//

import Foundation

// MARK: - API Documentation

public struct APIDocumentation: Codable {
    public let version: String
    public let title: String
    public let description: String
    public let baseURL: String
    public let endpoints: [EndpointDocumentation]
    public let models: [ModelDocumentation]
    public let authentication: AuthenticationDocumentation
    public let errors: [ErrorDocumentation]
    
    public init(
        version: String,
        title: String,
        description: String,
        baseURL: String,
        endpoints: [EndpointDocumentation],
        models: [ModelDocumentation],
        authentication: AuthenticationDocumentation,
        errors: [ErrorDocumentation]
    ) {
        self.version = version
        self.title = title
        self.description = description
        self.baseURL = baseURL
        self.endpoints = endpoints
        self.models = models
        self.authentication = authentication
        self.errors = errors
    }
}

// MARK: - Endpoint Documentation

public struct EndpointDocumentation: Codable {
    public let path: String
    public let method: String
    public let summary: String
    public let description: String
    public let parameters: [ParameterDocumentation]
    public let requestBody: RequestBodyDocumentation?
    public let responses: [ResponseDocumentation]
    public let requiresAuth: Bool
    public let rateLimit: String?
    public let examples: [ExampleDocumentation]
    
    public init(
        path: String,
        method: String,
        summary: String,
        description: String,
        parameters: [ParameterDocumentation] = [],
        requestBody: RequestBodyDocumentation? = nil,
        responses: [ResponseDocumentation],
        requiresAuth: Bool = false,
        rateLimit: String? = nil,
        examples: [ExampleDocumentation] = []
    ) {
        self.path = path
        self.method = method
        self.summary = summary
        self.description = description
        self.parameters = parameters
        self.requestBody = requestBody
        self.responses = responses
        self.requiresAuth = requiresAuth
        self.rateLimit = rateLimit
        self.examples = examples
    }
}

// MARK: - Parameter Documentation

public struct ParameterDocumentation: Codable {
    public let name: String
    public let location: ParameterLocation
    public let type: String
    public let required: Bool
    public let description: String
    public let defaultValue: String?
    
    public enum ParameterLocation: String, Codable {
        case path
        case query
        case header
        case cookie
    }
    
    public init(
        name: String,
        location: ParameterLocation,
        type: String,
        required: Bool,
        description: String,
        defaultValue: String? = nil
    ) {
        self.name = name
        self.location = location
        self.type = type
        self.required = required
        self.description = description
        self.defaultValue = defaultValue
    }
}

// MARK: - Request Body Documentation

public struct RequestBodyDocumentation: Codable {
    public let description: String
    public let required: Bool
    public let contentType: String
    public let schema: String
    public let example: String?
    
    public init(
        description: String,
        required: Bool,
        contentType: String = "application/json",
        schema: String,
        example: String? = nil
    ) {
        self.description = description
        self.required = required
        self.contentType = contentType
        self.schema = schema
        self.example = example
    }
}

// MARK: - Response Documentation

public struct ResponseDocumentation: Codable {
    public let statusCode: Int
    public let description: String
    public let contentType: String
    public let schema: String?
    public let example: String?
    
    public init(
        statusCode: Int,
        description: String,
        contentType: String = "application/json",
        schema: String? = nil,
        example: String? = nil
    ) {
        self.statusCode = statusCode
        self.description = description
        self.contentType = contentType
        self.schema = schema
        self.example = example
    }
}

// MARK: - Example Documentation

public struct ExampleDocumentation: Codable {
    public let title: String
    public let description: String
    public let request: String
    public let response: String
    
    public init(title: String, description: String, request: String, response: String) {
        self.title = title
        self.description = description
        self.request = request
        self.response = response
    }
}

// MARK: - Model Documentation

public struct ModelDocumentation: Codable {
    public let name: String
    public let description: String
    public let properties: [PropertyDocumentation]
    public let example: String?
    
    public init(
        name: String,
        description: String,
        properties: [PropertyDocumentation],
        example: String? = nil
    ) {
        self.name = name
        self.description = description
        self.properties = properties
        self.example = example
    }
}

// MARK: - Property Documentation

public struct PropertyDocumentation: Codable {
    public let name: String
    public let type: String
    public let required: Bool
    public let description: String
    public let format: String?
    public let example: String?
    
    public init(
        name: String,
        type: String,
        required: Bool,
        description: String,
        format: String? = nil,
        example: String? = nil
    ) {
        self.name = name
        self.type = type
        self.required = required
        self.description = description
        self.format = format
        self.example = example
    }
}

// MARK: - Authentication Documentation

public struct AuthenticationDocumentation: Codable {
    public let type: String
    public let description: String
    public let flows: [AuthFlowDocumentation]
    
    public init(type: String, description: String, flows: [AuthFlowDocumentation]) {
        self.type = type
        self.description = description
        self.flows = flows
    }
}

// MARK: - Auth Flow Documentation

public struct AuthFlowDocumentation: Codable {
    public let name: String
    public let description: String
    public let tokenURL: String?
    public let authorizationURL: String?
    public let scopes: [String: String]
    
    public init(
        name: String,
        description: String,
        tokenURL: String? = nil,
        authorizationURL: String? = nil,
        scopes: [String: String] = [:]
    ) {
        self.name = name
        self.description = description
        self.tokenURL = tokenURL
        self.authorizationURL = authorizationURL
        self.scopes = scopes
    }
}

// MARK: - Error Documentation

public struct ErrorDocumentation: Codable {
    public let code: String
    public let statusCode: Int
    public let message: String
    public let description: String
    
    public init(code: String, statusCode: Int, message: String, description: String) {
        self.code = code
        self.message = message
        self.statusCode = statusCode
        self.description = description
    }
}

// MARK: - Documentation Generator

public class APIDocumentationGenerator {
    public static func generateHubAPIDocumentation() -> APIDocumentation {
        return APIDocumentation(
            version: "1.0.0",
            title: "Hub API",
            description: "RESTful API for Hub application",
            baseURL: "https://api.hub.app/v1",
            endpoints: generateEndpoints(),
            models: generateModels(),
            authentication: generateAuthDocumentation(),
            errors: generateErrorDocumentation()
        )
    }
    
    private static func generateEndpoints() -> [EndpointDocumentation] {
        return [
            EndpointDocumentation(
                path: "/hubs",
                method: "GET",
                summary: "List all hubs",
                description: "Retrieve a paginated list of hubs",
                parameters: [
                    ParameterDocumentation(
                        name: "page",
                        location: .query,
                        type: "integer",
                        required: false,
                        description: "Page number",
                        defaultValue: "1"
                    ),
                    ParameterDocumentation(
                        name: "pageSize",
                        location: .query,
                        type: "integer",
                        required: false,
                        description: "Number of items per page",
                        defaultValue: "20"
                    )
                ],
                responses: [
                    ResponseDocumentation(
                        statusCode: 200,
                        description: "Successful response",
                        schema: "HubListResponse"
                    )
                ],
                requiresAuth: true,
                rateLimit: "100 requests per minute"
            ),
            EndpointDocumentation(
                path: "/hubs",
                method: "POST",
                summary: "Create a new hub",
                description: "Create a new hub with the provided details",
                requestBody: RequestBodyDocumentation(
                    description: "Hub creation data",
                    required: true,
                    schema: "HubCreateRequest"
                ),
                responses: [
                    ResponseDocumentation(
                        statusCode: 201,
                        description: "Hub created successfully",
                        schema: "HubResponse"
                    ),
                    ResponseDocumentation(
                        statusCode: 400,
                        description: "Invalid request data"
                    )
                ],
                requiresAuth: true
            )
        ]
    }
    
    private static func generateModels() -> [ModelDocumentation] {
        return [
            ModelDocumentation(
                name: "HubResponse",
                description: "Hub object representation",
                properties: [
                    PropertyDocumentation(
                        name: "id",
                        type: "string",
                        required: true,
                        description: "Unique hub identifier",
                        format: "uuid"
                    ),
                    PropertyDocumentation(
                        name: "name",
                        type: "string",
                        required: true,
                        description: "Hub name"
                    ),
                    PropertyDocumentation(
                        name: "description",
                        type: "string",
                        required: true,
                        description: "Hub description"
                    ),
                    PropertyDocumentation(
                        name: "createdAt",
                        type: "string",
                        required: true,
                        description: "Creation timestamp",
                        format: "date-time"
                    )
                ]
            )
        ]
    }
    
    private static func generateAuthDocumentation() -> AuthenticationDocumentation {
        return AuthenticationDocumentation(
            type: "OAuth 2.0",
            description: "OAuth 2.0 authentication with Bearer tokens",
            flows: [
                AuthFlowDocumentation(
                    name: "Client Credentials",
                    description: "Machine-to-machine authentication",
                    tokenURL: "https://api.hub.app/v1/auth/token",
                    scopes: [
                        "read": "Read access to resources",
                        "write": "Write access to resources",
                        "admin": "Administrative access"
                    ]
                )
            ]
        )
    }
    
    private static func generateErrorDocumentation() -> [ErrorDocumentation] {
        return [
            ErrorDocumentation(
                code: "UNAUTHORIZED",
                statusCode: 401,
                message: "Authentication required",
                description: "The request requires authentication"
            ),
            ErrorDocumentation(
                code: "FORBIDDEN",
                statusCode: 403,
                message: "Access denied",
                description: "You don't have permission to access this resource"
            ),
            ErrorDocumentation(
                code: "NOT_FOUND",
                statusCode: 404,
                message: "Resource not found",
                description: "The requested resource does not exist"
            ),
            ErrorDocumentation(
                code: "RATE_LIMIT_EXCEEDED",
                statusCode: 429,
                message: "Too many requests",
                description: "Rate limit exceeded. Please try again later"
            )
        ]
    }
    
    // MARK: - Export Formats
    
    public static func exportAsJSON(_ documentation: APIDocumentation) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(documentation)
    }
    
    public static func exportAsMarkdown(_ documentation: APIDocumentation) -> String {
        var markdown = """
        # \(documentation.title)
        
        **Version:** \(documentation.version)
        
        **Base URL:** `\(documentation.baseURL)`
        
        \(documentation.description)
        
        ## Authentication
        
        **Type:** \(documentation.authentication.type)
        
        \(documentation.authentication.description)
        
        ## Endpoints
        
        """
        
        for endpoint in documentation.endpoints {
            markdown += """
            
            ### \(endpoint.method) \(endpoint.path)
            
            \(endpoint.summary)
            
            \(endpoint.description)
            
            **Authentication Required:** \(endpoint.requiresAuth ? "Yes" : "No")
            
            """
            
            if let rateLimit = endpoint.rateLimit {
                markdown += "**Rate Limit:** \(rateLimit)\n\n"
            }
        }
        
        return markdown
    }
}
