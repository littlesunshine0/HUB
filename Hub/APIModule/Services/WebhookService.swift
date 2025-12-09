//
//  WebhookService.swift
//  Hub
//
//  Webhook handling service for receiving events from external systems
//

import Foundation
import CryptoKit

public class WebhookService: WebhookHandler {
    public static let shared = WebhookService()
    
    private var handlers: [String: [(WebhookEvent) async throws -> Void]] = [:]
    private let signingSecret: String
    
    private init(signingSecret: String = ProcessInfo.processInfo.environment["WEBHOOK_SECRET"] ?? "default-secret") {
        self.signingSecret = signingSecret
    }
    
    // MARK: - Registration
    
    public func register(eventType: String, handler: @escaping (WebhookEvent) async throws -> Void) {
        if handlers[eventType] == nil {
            handlers[eventType] = []
        }
        handlers[eventType]?.append(handler)
    }
    
    public func unregister(eventType: String) {
        handlers.removeValue(forKey: eventType)
    }
    
    // MARK: - WebhookHandler Protocol
    
    public func handle(event: WebhookEvent) async throws {
        guard let eventHandlers = handlers[event.type] else {
            print("No handlers registered for event type: \(event.type)")
            return
        }
        
        for handler in eventHandlers {
            try await handler(event)
        }
    }
    
    public func verify(signature: String, payload: Data) -> Bool {
        let computedSignature = computeSignature(for: payload)
        return signature == computedSignature
    }
    
    // MARK: - Signature Verification
    
    private func computeSignature(for payload: Data) -> String {
        let key = SymmetricKey(data: Data(signingSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        return Data(signature).base64EncodedString()
    }
    
    // MARK: - Webhook Processing
    
    public func processWebhook(signature: String?, payload: Data) async throws {
        // Verify signature if provided
        if let signature = signature {
            guard verify(signature: signature, payload: payload) else {
                throw APIError(code: "INVALID_SIGNATURE", message: "Webhook signature verification failed")
            }
        }
        
        // Parse event
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let event = try decoder.decode(WebhookEvent.self, from: payload)
        
        // Handle event
        try await handle(event: event)
    }
}

// MARK: - Webhook Event Types

public extension WebhookService {
    enum EventType {
        public static let hubCreated = "hub.created"
        public static let hubUpdated = "hub.updated"
        public static let hubDeleted = "hub.deleted"
        public static let hubShared = "hub.shared"
        
        public static let templatePublished = "template.published"
        public static let templateDownloaded = "template.downloaded"
        
        public static let userRegistered = "user.registered"
        public static let userUpdated = "user.updated"
        
        public static let syncCompleted = "sync.completed"
        public static let syncFailed = "sync.failed"
    }
}

// MARK: - Webhook Server (for receiving webhooks)

#if canImport(Vapor)
import Vapor

public class WebhookServer {
    private let app: Application
    private let webhookService: WebhookService
    
    public init(port: Int = 8080, webhookService: WebhookService = .shared) {
        self.app = Application(.production)
        self.webhookService = webhookService
        configureRoutes()
    }
    
    private func configureRoutes() {
        app.post("webhooks") { req async throws -> HTTPStatus in
            let signature = req.headers.first(name: "X-Hub-Signature")
            let payload = try req.content.decode(Data.self)
            
            try await self.webhookService.processWebhook(signature: signature, payload: payload)
            
            return .ok
        }
    }
    
    public func start() throws {
        try app.run()
    }
    
    public func shutdown() {
        app.shutdown()
    }
}
#endif
