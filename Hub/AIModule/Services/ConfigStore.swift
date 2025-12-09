//
//  ConfigStore.swift
//  Hub
//
//  Created by Offline Assistant Module
//  Persistent storage for crawler configuration
//

import Foundation
import Combine

/// Manages persistent storage and retrieval of crawler configuration
@MainActor
class ConfigStore: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var config: CrawlerConfig
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let fileURL: URL
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    /// Initialize with a custom file URL
    /// - Parameter fileURL: The URL where the configuration file should be stored
    init(fileURL: URL) {
        self.fileURL = fileURL
        self.config = CrawlerConfig()
        
        // Ensure the directory exists
        let directory = fileURL.deletingLastPathComponent()
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    /// Initialize with default file location in Application Support
    convenience init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let hubDirectory = appSupport.appendingPathComponent("Hub", isDirectory: true)
        let configDirectory = hubDirectory.appendingPathComponent("OfflineAssistant", isDirectory: true)
        let fileURL = configDirectory.appendingPathComponent("crawler-config.json")
        
        self.init(fileURL: fileURL)
    }
    
    // MARK: - Public Methods
    
    /// Load configuration from disk or create default if not found
    func loadOrCreateDefault() async {
        isLoading = true
        lastError = nil
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                config = try decoder.decode(CrawlerConfig.self, from: data)
            } else {
                // Create default configuration
                config = createDefaultConfig()
                try await save()
            }
        } catch {
            lastError = error
            // Fall back to default config on error
            config = createDefaultConfig()
        }
        
        isLoading = false
    }
    
    /// Save the current configuration to disk
    func save() async throws {
        isLoading = true
        lastError = nil
        
        do {
            // Validate before saving
            let issues = config.validate()
            let errors = issues.filter { $0.severity == .error }
            if !errors.isEmpty {
                throw ConfigStoreError.validationFailed(issues: errors)
            }
            
            // Encode and save
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            
            // Ensure directory exists
            let directory = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            
            // Write atomically
            try data.write(to: fileURL, options: .atomic)
        } catch {
            lastError = error
            throw error
        }
        
        isLoading = false
    }
    
    /// Update the configuration and save
    /// - Parameter newConfig: The new configuration to save
    func update(_ newConfig: CrawlerConfig) async throws {
        config = newConfig
        try await save()
    }
    
    /// Apply a preset and save
    /// - Parameter preset: The preset to apply
    func applyPreset(_ preset: ConfigPreset) async throws {
        config.apply(preset)
        try await save()
    }
    
    /// Add or update a domain override
    /// - Parameters:
    ///   - host: The host to configure
    ///   - override: The domain-specific override
    func setDomainOverride(host: String, override: DomainOverride) async throws {
        config.domains[host] = override
        try await save()
    }
    
    /// Remove a domain override
    /// - Parameter host: The host to remove
    func removeDomainOverride(host: String) async throws {
        config.domains.removeValue(forKey: host)
        try await save()
    }
    
    /// Reset to default configuration
    func resetToDefaults() async throws {
        config = createDefaultConfig()
        try await save()
    }
    
    /// Export configuration to a file
    /// - Parameter url: The destination URL
    func export(to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
    }
    
    /// Import configuration from a file
    /// - Parameter url: The source URL
    func `import`(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let importedConfig = try decoder.decode(CrawlerConfig.self, from: data)
        
        // Validate before importing
        let issues = importedConfig.validate()
        let errors = issues.filter { $0.severity == .error }
        if !errors.isEmpty {
            throw ConfigStoreError.validationFailed(issues: errors)
        }
        
        config = importedConfig
        try await save()
    }
    
    /// Validate the current configuration
    /// - Returns: Array of validation issues
    func validate() -> [ConfigValidationIssue] {
        return config.validate()
    }
    
    // MARK: - Private Methods
    
    private func createDefaultConfig() -> CrawlerConfig {
        var config = CrawlerConfig()
        
        // Add some common domain presets
        config.domains["github.com"] = DomainOverride(
            requestsPerSecond: 2.0,
            rateLimitBurst: 5,
            requestDelayMs: 500,
            useWebKitForJS: false
        )
        
        config.domains["stackoverflow.com"] = DomainOverride(
            requestsPerSecond: 1.5,
            rateLimitBurst: 3,
            requestDelayMs: 700,
            useWebKitForJS: false
        )
        
        config.domains["developer.apple.com"] = DomainOverride(
            requestsPerSecond: 1.0,
            rateLimitBurst: 2,
            requestDelayMs: 1000,
            useWebKitForJS: true
        )
        
        return config
    }
}

// MARK: - Config Store Error

enum ConfigStoreError: LocalizedError {
    case validationFailed(issues: [ConfigValidationIssue])
    case fileNotFound
    case invalidFormat
    case saveFailed(underlying: Error)
    case loadFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let issues):
            let messages = issues.map { "\($0.path): \($0.message)" }.joined(separator: ", ")
            return "Configuration validation failed: \(messages)"
        case .fileNotFound:
            return "Configuration file not found"
        case .invalidFormat:
            return "Configuration file has invalid format"
        case .saveFailed(let error):
            return "Failed to save configuration: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load configuration: \(error.localizedDescription)"
        }
    }
}
