//
//  CrawlConfiguration.swift
//  Hub
//
//  Created by Offline Assistant Module
//  Configuration models for web crawling and knowledge extraction
//

import Foundation

// MARK: - Crawl Defaults

/// Default crawl settings that can be applied globally or overridden per domain
struct CrawlDefaults: Codable, Equatable {
    /// Maximum depth to crawl from the starting URL
    var maxDepth: Int = 3
    
    /// Timeout for each HTTP request in seconds
    var timeout: TimeInterval = 30.0
    
    /// Number of concurrent requests allowed
    var concurrency: Int = 3
    
    /// Maximum number of pages to crawl
    var maxPages: Int = 100
    
    /// Maximum requests per second per host
    var requestsPerSecond: Double = 2.0
    
    /// Burst capacity for rate limiting
    var rateLimitBurst: Int = 5
    
    /// Delay between requests in milliseconds
    var requestDelayMs: Int = 500
    
    /// Whether to respect robots.txt
    var respectRobots: Bool = true
    
    /// Whether to use WebKit for JavaScript-heavy sites
    var useWebKitForJS: Bool = false
    
    /// Whether to restrict crawling to the same host
    var sameHostOnly: Bool = true
    
    /// Validate the configuration
    func validate() -> [ConfigValidationIssue] {
        var issues: [ConfigValidationIssue] = []
        
        if maxDepth < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "maxDepth must be at least 1",
                path: "maxDepth"
            ))
        }
        
        if timeout <= 0 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "timeout must be positive",
                path: "timeout"
            ))
        }
        
        if concurrency < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "concurrency must be at least 1",
                path: "concurrency"
            ))
        }
        
        if maxPages < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "maxPages must be at least 1",
                path: "maxPages"
            ))
        }
        
        if requestsPerSecond <= 0 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "requestsPerSecond must be positive",
                path: "requestsPerSecond"
            ))
        }
        
        if rateLimitBurst < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "rateLimitBurst must be at least 1",
                path: "rateLimitBurst"
            ))
        }
        
        if requestDelayMs < 0 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "requestDelayMs cannot be negative",
                path: "requestDelayMs"
            ))
        }
        
        return issues
    }
}

// MARK: - Domain Override

/// Domain-specific configuration that overrides defaults
struct DomainOverride: Codable, Equatable {
    var requestsPerSecond: Double?
    var rateLimitBurst: Int?
    var requestDelayMs: Int?
    var useWebKitForJS: Bool?
    var basicAuth: BasicAuthCredentials?
    var maxDepth: Int?
    var maxPages: Int?
    
    /// Validate the domain override
    func validate(host: String) -> [ConfigValidationIssue] {
        var issues: [ConfigValidationIssue] = []
        
        if let rps = requestsPerSecond, rps <= 0 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "requestsPerSecond must be positive",
                path: "domains.\(host).requestsPerSecond"
            ))
        }
        
        if let burst = rateLimitBurst, burst < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "rateLimitBurst must be at least 1",
                path: "domains.\(host).rateLimitBurst"
            ))
        }
        
        if let delay = requestDelayMs, delay < 0 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "requestDelayMs cannot be negative",
                path: "domains.\(host).requestDelayMs"
            ))
        }
        
        if let depth = maxDepth, depth < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "maxDepth must be at least 1",
                path: "domains.\(host).maxDepth"
            ))
        }
        
        if let pages = maxPages, pages < 1 {
            issues.append(ConfigValidationIssue(
                severity: .error,
                message: "maxPages must be at least 1",
                path: "domains.\(host).maxPages"
            ))
        }
        
        return issues
    }
}

/// Basic authentication credentials for protected domains
struct BasicAuthCredentials: Codable, Equatable {
    var username: String
    var password: String
}

// MARK: - Crawler Config

/// Complete crawler configuration with defaults and domain-specific overrides
struct CrawlerConfig: Codable, Equatable {
    var defaults: CrawlDefaults
    var domains: [String: DomainOverride]
    
    init(defaults: CrawlDefaults = CrawlDefaults(), domains: [String: DomainOverride] = [:]) {
        self.defaults = defaults
        self.domains = domains
    }
    
    /// Apply a preset configuration
    mutating func apply(_ preset: ConfigPreset) {
        switch preset {
        case .polite:
            defaults.requestsPerSecond = 1.0
            defaults.requestDelayMs = 1000
            defaults.concurrency = 2
            defaults.respectRobots = true
            defaults.rateLimitBurst = 3
            
        case .aggressive:
            defaults.requestsPerSecond = 5.0
            defaults.requestDelayMs = 100
            defaults.concurrency = 10
            defaults.respectRobots = true
            defaults.rateLimitBurst = 10
            
        case .jsHeavy:
            defaults.useWebKitForJS = true
            defaults.requestsPerSecond = 2.0
            defaults.requestDelayMs = 500
            defaults.concurrency = 3
            defaults.respectRobots = true
            
        case .conservative:
            defaults.requestsPerSecond = 0.5
            defaults.requestDelayMs = 2000
            defaults.concurrency = 1
            defaults.respectRobots = true
            defaults.maxPages = 50
            defaults.rateLimitBurst = 2
            
        case .balanced:
            defaults = CrawlDefaults() // Reset to defaults
        }
    }
    
    /// Get the effective configuration for a specific URL
    func effectiveConfig(for url: URL) -> EffectiveConfig {
        let host = url.host ?? ""
        let override = domains[host]
        
        return EffectiveConfig(
            maxDepth: override?.maxDepth ?? defaults.maxDepth,
            timeout: defaults.timeout,
            concurrency: defaults.concurrency,
            maxPages: override?.maxPages ?? defaults.maxPages,
            requestsPerSecond: override?.requestsPerSecond ?? defaults.requestsPerSecond,
            rateLimitBurst: override?.rateLimitBurst ?? defaults.rateLimitBurst,
            requestDelayMs: override?.requestDelayMs ?? defaults.requestDelayMs,
            respectRobots: defaults.respectRobots,
            useWebKitForJS: override?.useWebKitForJS ?? defaults.useWebKitForJS,
            sameHostOnly: defaults.sameHostOnly,
            basicAuth: override?.basicAuth
        )
    }
    
    /// Validate the entire configuration
    func validate() -> [ConfigValidationIssue] {
        var issues = defaults.validate()
        
        for (host, override) in domains {
            issues.append(contentsOf: override.validate(host: host))
        }
        
        return issues
    }
}

// MARK: - Effective Config

/// The effective configuration for a specific URL after applying overrides
struct EffectiveConfig {
    let maxDepth: Int
    let timeout: TimeInterval
    let concurrency: Int
    let maxPages: Int
    let requestsPerSecond: Double
    let rateLimitBurst: Int
    let requestDelayMs: Int
    let respectRobots: Bool
    let useWebKitForJS: Bool
    let sameHostOnly: Bool
    let basicAuth: BasicAuthCredentials?
}

// MARK: - Config Preset

/// Predefined configuration presets for common use cases
enum ConfigPreset: String, Codable, CaseIterable {
    case polite = "Polite"
    case aggressive = "Aggressive"
    case jsHeavy = "JavaScript Heavy"
    case conservative = "Conservative"
    case balanced = "Balanced"
    
    var description: String {
        switch self {
        case .polite:
            return "Respectful crawling with low request rates (1 req/s)"
        case .aggressive:
            return "Fast crawling with high concurrency (5 req/s)"
        case .jsHeavy:
            return "Optimized for JavaScript-heavy sites with WebKit rendering"
        case .conservative:
            return "Very slow and careful crawling (0.5 req/s)"
        case .balanced:
            return "Default balanced settings (2 req/s)"
        }
    }
}

// MARK: - Config Validation Issue

/// Represents a configuration validation issue
struct ConfigValidationIssue: Codable, Equatable {
    enum Severity: String, Codable {
        case error
        case warning
    }
    
    let severity: Severity
    let message: String
    let path: String
}

// MARK: - Host Policy

/// Host-specific policy derived from configuration
struct HostPolicy {
    let host: String
    let requestsPerSecond: Double
    let rateLimitBurst: Int
    let requestDelayMs: Int
    let useWebKitForJS: Bool
    let basicAuth: BasicAuthCredentials?
    
    init(from defaults: CrawlDefaults, host: String) {
        self.host = host
        self.requestsPerSecond = defaults.requestsPerSecond
        self.rateLimitBurst = defaults.rateLimitBurst
        self.requestDelayMs = defaults.requestDelayMs
        self.useWebKitForJS = defaults.useWebKitForJS
        self.basicAuth = nil
    }
    
    init(host: String, requestsPerSecond: Double, rateLimitBurst: Int, requestDelayMs: Int, useWebKitForJS: Bool, basicAuth: BasicAuthCredentials?) {
        self.host = host
        self.requestsPerSecond = requestsPerSecond
        self.rateLimitBurst = rateLimitBurst
        self.requestDelayMs = requestDelayMs
        self.useWebKitForJS = useWebKitForJS
        self.basicAuth = basicAuth
    }
}
