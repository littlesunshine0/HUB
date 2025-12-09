//
//  APIManager.swift
//  Hub
//
//  Main API manager for handling all API communications
//

import Foundation

public class APIManager: APIClient {
    public static let shared = APIManager()
    
    private let baseURL: URL
    private let session: URLSession
    private var authToken: AuthenticationToken?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Configuration
    public var timeout: TimeInterval = 30
    public var retryCount: Int = 3
    public var retryDelay: TimeInterval = 1
    
    private init(baseURL: String = "https://api.hub.app/v1") {
        self.baseURL = URL(string: baseURL)!
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        self.session = URLSession(configuration: config)
        
        // Configure encoders/decoders
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    public func send<T: Codable>(_ request: APIRequest<T>) async throws -> APIResponse<T> {
        let startTime = Date()
        
        // Build URL request
        var urlRequest = try buildURLRequest(from: request)
        
        // Add authentication if required
        if let token = authToken {
            urlRequest.setValue("\(token.tokenType) \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Execute with retry logic
        var lastError: Error?
        for attempt in 0..<retryCount {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError(code: "INVALID_RESPONSE", message: "Invalid response type")
                }
                
                let processingTime = Date().timeIntervalSince(startTime)
                
                // Parse response
                return try parseResponse(
                    data: data,
                    statusCode: httpResponse.statusCode,
                    requestId: request.id,
                    processingTime: processingTime
                )
                
            } catch {
                lastError = error
                
                // Don't retry on client errors (4xx)
                if let apiError = error as? APIError,
                   apiError.code.starts(with: "4") {
                    throw error
                }
                
                // Wait before retry
                if attempt < retryCount - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIError(code: "UNKNOWN_ERROR", message: "Request failed")
    }
    
    public func authenticate(credentials: APICredentials) async throws -> AuthenticationToken {
        let request = APIRequest<APICredentials>(
            endpoint: "/auth/token",
            method: "POST",
            body: credentials
        )
        
        let response = try await send(request)
        
        // Manually decode the response data as AuthenticationToken
        guard let data = response.data else {
            throw response.error ?? APIError(code: "AUTH_FAILED", message: "Authentication failed")
        }
        
        // In a real implementation, we'd decode from the response
        // For now, create a mock token
        let token = AuthenticationToken(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            tokenType: "Bearer",
            expiresIn: 3600,
            scope: []
        )
        
        self.authToken = token
        return token
    }
    
    public func refreshToken(_ token: AuthenticationToken) async throws -> AuthenticationToken {
        guard let refreshToken = token.refreshToken else {
            throw APIError(code: "NO_REFRESH_TOKEN", message: "No refresh token available")
        }
        
        let request = APIRequest<[String: String]>(
            endpoint: "/auth/refresh",
            method: "POST",
            body: ["refresh_token": refreshToken]
        )
        
        let response = try await send(request)
        
        guard response.data != nil else {
            throw response.error ?? APIError(code: "REFRESH_FAILED", message: "Token refresh failed")
        }
        
        // In a real implementation, we'd decode from the response
        // For now, create a mock token
        let newToken = AuthenticationToken(
            accessToken: "mock_refreshed_token",
            refreshToken: refreshToken,
            tokenType: "Bearer",
            expiresIn: 3600,
            scope: []
        )
        
        self.authToken = newToken
        return newToken
    }
    
    public func setAuthToken(_ token: AuthenticationToken) {
        self.authToken = token
    }
    
    public func clearAuthToken() {
        self.authToken = nil
    }
    
    // MARK: - Private Methods
    
    private func buildURLRequest<T: Codable>(from request: APIRequest<T>) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(request.endpoint), resolvingAgainstBaseURL: true)!
        
        // Add query parameters
        if let parameters = request.parameters {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw APIError(code: "INVALID_URL", message: "Failed to construct URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.timeoutInterval = timeout
        
        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Hub/1.0", forHTTPHeaderField: "User-Agent")
        urlRequest.setValue(request.version, forHTTPHeaderField: "API-Version")
        
        // Add body
        if let body = request.body {
            urlRequest.httpBody = try encoder.encode(body)
        }
        
        return urlRequest
    }
    
    private func parseResponse<T: Codable>(
        data: Data,
        statusCode: Int,
        requestId: String,
        processingTime: TimeInterval
    ) throws -> APIResponse<T> {
        let success = (200...299).contains(statusCode)
        
        if success {
            let responseData = try decoder.decode(T.self, from: data)
            return APIResponse(
                requestId: requestId,
                statusCode: statusCode,
                success: true,
                data: responseData,
                metadata: ResponseMetadata(
                    processingTime: processingTime,
                    serverVersion: "1.0"
                )
            )
        } else {
            let error = try? decoder.decode(APIError.self, from: data)
            return APIResponse(
                requestId: requestId,
                statusCode: statusCode,
                success: false,
                error: error ?? APIError(
                    code: "HTTP_\(statusCode)",
                    message: HTTPURLResponse.localizedString(forStatusCode: statusCode)
                )
            )
        }
    }
}

// MARK: - Convenience Methods

extension APIManager {
    public func get<T: Codable>(
        _ endpoint: String,
        parameters: [String: String]? = nil
    ) async throws -> T {
        let request = APIRequest<EmptyBody>(
            endpoint: endpoint,
            method: "GET",
            parameters: parameters
        )
        
        _ = try await send(request)
        
        // In a real implementation, we'd decode the response data as T
        // For now, throw an error indicating this needs implementation
        throw APIError(code: "NOT_IMPLEMENTED", message: "Generic GET not fully implemented")
    }
    
    public func post<T: Codable, U: Codable>(
        _ endpoint: String,
        body: T
    ) async throws -> U {
        let request = APIRequest<T>(
            endpoint: endpoint,
            method: "POST",
            body: body
        )
        
        _ = try await send(request)
        
        // In a real implementation, we'd decode the response data as U
        // For now, throw an error indicating this needs implementation
        throw APIError(code: "NOT_IMPLEMENTED", message: "Generic POST not fully implemented")
    }
    
    public func put<T: Codable, U: Codable>(
        _ endpoint: String,
        body: T
    ) async throws -> U {
        let request = APIRequest<T>(
            endpoint: endpoint,
            method: "PUT",
            body: body
        )
        
        _ = try await send(request)
        
        // In a real implementation, we'd decode the response data as U
        // For now, throw an error indicating this needs implementation
        throw APIError(code: "NOT_IMPLEMENTED", message: "Generic PUT not fully implemented")
    }
    
    public func delete(_ endpoint: String) async throws {
        let request = APIRequest<EmptyBody>(
            endpoint: endpoint,
            method: "DELETE"
        )
        
        let response: APIResponse<EmptyBody> = try await send(request)
        
        if !response.success {
            throw response.error ?? APIError(code: "DELETE_FAILED", message: "Delete operation failed")
        }
    }
}

// MARK: - Empty Body

public struct EmptyBody: Codable {}
