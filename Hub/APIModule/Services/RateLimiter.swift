//
//  RateLimiter.swift
//  Hub
//
//  Rate limiting service for API requests
//

import Foundation

// MARK: - Rate Limiter

public class RateLimiter {
    public static let shared = RateLimiter()
    
    private var buckets: [String: TokenBucket] = [:]
    private let queue = DispatchQueue(label: "com.hub.ratelimiter", attributes: .concurrent)
    
    // Default limits
    public var defaultLimit: Int = 100
    public var defaultWindow: TimeInterval = 60 // 1 minute
    
    private init() {}
    
    // MARK: - Rate Limiting
    
    public func checkLimit(for identifier: String, limit: Int? = nil, window: TimeInterval? = nil) throws {
        let actualLimit = limit ?? defaultLimit
        let actualWindow = window ?? defaultWindow
        
        try queue.sync(flags: .barrier) {
            let bucket = getBucket(for: identifier, limit: actualLimit, window: actualWindow)
            
            guard bucket.consume() else {
                throw APIError(
                    code: "RATE_LIMIT_EXCEEDED",
                    message: "Rate limit exceeded. Try again in \(Int(bucket.resetTime.timeIntervalSinceNow)) seconds",
                    details: [
                        "limit": "\(actualLimit)",
                        "window": "\(actualWindow)",
                        "resetAt": ISO8601DateFormatter().string(from: bucket.resetTime)
                    ]
                )
            }
        }
    }
    
    public func getRemainingRequests(for identifier: String) -> Int {
        return queue.sync {
            guard let bucket = buckets[identifier] else {
                return defaultLimit
            }
            return bucket.remaining
        }
    }
    
    public func getResetTime(for identifier: String) -> Date? {
        return queue.sync {
            return buckets[identifier]?.resetTime
        }
    }
    
    public func reset(for identifier: String) {
        queue.sync(flags: .barrier) {
            buckets.removeValue(forKey: identifier)
        }
    }
    
    public func resetAll() {
        queue.sync(flags: .barrier) {
            buckets.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func getBucket(for identifier: String, limit: Int, window: TimeInterval) -> TokenBucket {
        if let bucket = buckets[identifier] {
            bucket.refill()
            return bucket
        }
        
        let bucket = TokenBucket(capacity: limit, refillRate: Double(limit) / window)
        buckets[identifier] = bucket
        return bucket
    }
}

// MARK: - Token Bucket

private class TokenBucket {
    let capacity: Int
    let refillRate: Double // tokens per second
    
    private var tokens: Double
    private var lastRefill: Date
    
    var remaining: Int {
        return Int(tokens)
    }
    
    var resetTime: Date {
        let tokensNeeded = Double(capacity) - tokens
        let secondsUntilFull = tokensNeeded / refillRate
        return Date().addingTimeInterval(secondsUntilFull)
    }
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = Double(capacity)
        self.lastRefill = Date()
    }
    
    func consume() -> Bool {
        refill()
        
        guard tokens >= 1 else {
            return false
        }
        
        tokens -= 1
        return true
    }
    
    func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let tokensToAdd = elapsed * refillRate
        
        tokens = min(Double(capacity), tokens + tokensToAdd)
        lastRefill = now
    }
}

// MARK: - Rate Limit Strategies

public enum RateLimitStrategy {
    case perUser(limit: Int, window: TimeInterval)
    case perIP(limit: Int, window: TimeInterval)
    case perEndpoint(limit: Int, window: TimeInterval)
    case global(limit: Int, window: TimeInterval)
    
    public var limit: Int {
        switch self {
        case .perUser(let limit, _),
             .perIP(let limit, _),
             .perEndpoint(let limit, _),
             .global(let limit, _):
            return limit
        }
    }
    
    public var window: TimeInterval {
        switch self {
        case .perUser(_, let window),
             .perIP(_, let window),
             .perEndpoint(_, let window),
             .global(_, let window):
            return window
        }
    }
}

// MARK: - Rate Limit Middleware

public class RateLimitMiddleware {
    private let rateLimiter: RateLimiter
    private let strategy: RateLimitStrategy
    
    public init(rateLimiter: RateLimiter = .shared, strategy: RateLimitStrategy) {
        self.rateLimiter = rateLimiter
        self.strategy = strategy
    }
    
    public func check(userId: String?, ipAddress: String?, endpoint: String?) throws {
        let identifier: String
        
        switch strategy {
        case .perUser:
            guard let userId = userId else {
                throw APIError(code: "UNAUTHORIZED", message: "User authentication required")
            }
            identifier = "user:\(userId)"
            
        case .perIP:
            guard let ipAddress = ipAddress else {
                throw APIError(code: "INVALID_REQUEST", message: "IP address required")
            }
            identifier = "ip:\(ipAddress)"
            
        case .perEndpoint:
            guard let endpoint = endpoint else {
                throw APIError(code: "INVALID_REQUEST", message: "Endpoint required")
            }
            identifier = "endpoint:\(endpoint)"
            
        case .global:
            identifier = "global"
        }
        
        try rateLimiter.checkLimit(
            for: identifier,
            limit: strategy.limit,
            window: strategy.window
        )
    }
    
    public func getRateLimitInfo(userId: String?, ipAddress: String?, endpoint: String?) -> RateLimitInfo? {
        let identifier: String
        
        switch strategy {
        case .perUser:
            guard let userId = userId else { return nil }
            identifier = "user:\(userId)"
        case .perIP:
            guard let ipAddress = ipAddress else { return nil }
            identifier = "ip:\(ipAddress)"
        case .perEndpoint:
            guard let endpoint = endpoint else { return nil }
            identifier = "endpoint:\(endpoint)"
        case .global:
            identifier = "global"
        }
        
        let remaining = rateLimiter.getRemainingRequests(for: identifier)
        let resetAt = rateLimiter.getResetTime(for: identifier) ?? Date().addingTimeInterval(strategy.window)
        
        return RateLimitInfo(
            limit: strategy.limit,
            remaining: remaining,
            resetAt: resetAt
        )
    }
}
