//
//  FrameworkDocumentationCrawler.swift
//  Hub
//
//  Framework-Driven Template System
//  Crawls and indexes Apple framework documentation
//

import Foundation

// MARK: - Crawled Document

/// Represents a document crawled from Apple's documentation
public struct CrawledDocument: Codable, Identifiable {
    public let id: UUID
    public let url: URL
    public let title: String
    public let content: String
    public let htmlContent: String
    public let metadata: DocumentMetadata
    public let crawledAt: Date
    
    public init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        content: String,
        htmlContent: String,
        metadata: DocumentMetadata = DocumentMetadata(),
        crawledAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.content = content
        self.htmlContent = htmlContent
        self.metadata = metadata
        self.crawledAt = crawledAt
    }
}

// MARK: - Document Metadata

/// Metadata extracted from crawled documents
public struct DocumentMetadata: Codable {
    public var documentType: DocumentType
    public var framework: String?
    public var apiType: String?
    public var codeLanguage: String?
    public var lastModified: Date?
    
    public init(
        documentType: DocumentType = .unknown,
        framework: String? = nil,
        apiType: String? = nil,
        codeLanguage: String? = nil,
        lastModified: Date? = nil
    ) {
        self.documentType = documentType
        self.framework = framework
        self.apiType = apiType
        self.codeLanguage = codeLanguage
        self.lastModified = lastModified
    }
}

// MARK: - Document Type

/// Types of documentation pages
public enum DocumentType: String, Codable {
    case apiReference = "API Reference"
    case tutorial = "Tutorial"
    case guide = "Guide"
    case sampleCode = "Sample Code"
    case wwdcSession = "WWDC Session"
    case unknown = "Unknown"
}

// MARK: - Crawl Configuration Builder

/// Builder for creating crawl configurations
public struct CrawlConfigurationBuilder {
    private var id: UUID = UUID()
    private var name: String = ""
    private var startURL: URL
    private var maxDepth: Int = 3
    private var maxPages: Int = 500
    private var allowedDomains: [String] = []
    private var urlPatterns: [String] = []
    private var respectRobotsTxt: Bool = true
    private var userAgent: String = "HubFrameworkCrawler/1.0"
    private var rateLimit: Double = 1.0
    
    public init(startURL: URL) {
        self.startURL = startURL
    }
    
    public func withName(_ name: String) -> CrawlConfigurationBuilder {
        var builder = self
        builder.name = name
        return builder
    }
    
    public func withMaxDepth(_ depth: Int) -> CrawlConfigurationBuilder {
        var builder = self
        builder.maxDepth = depth
        return builder
    }
    
    public func withMaxPages(_ pages: Int) -> CrawlConfigurationBuilder {
        var builder = self
        builder.maxPages = pages
        return builder
    }
    
    public func withAllowedDomains(_ domains: [String]) -> CrawlConfigurationBuilder {
        var builder = self
        builder.allowedDomains = domains
        return builder
    }
    
    public func withURLPatterns(_ patterns: [String]) -> CrawlConfigurationBuilder {
        var builder = self
        builder.urlPatterns = patterns
        return builder
    }
    
    public func withRateLimit(_ limit: Double) -> CrawlConfigurationBuilder {
        var builder = self
        builder.rateLimit = limit
        return builder
    }
    
    public func build() -> CrawlConfig {
        return CrawlConfig(
            id: id,
            name: name,
            startURL: startURL,
            maxDepth: maxDepth,
            maxPages: maxPages,
            allowedDomains: allowedDomains,
            urlPatterns: urlPatterns,
            respectRobotsTxt: respectRobotsTxt,
            userAgent: userAgent,
            rateLimit: rateLimit
        )
    }
}

// MARK: - Crawl Config

/// Configuration for a crawl operation
public struct CrawlConfig: Codable {
    public let id: UUID
    public let name: String
    public let startURL: URL
    public let maxDepth: Int
    public let maxPages: Int
    public let allowedDomains: [String]
    public let urlPatterns: [String]
    public let respectRobotsTxt: Bool
    public let userAgent: String
    public let rateLimit: Double
    
    public init(
        id: UUID = UUID(),
        name: String,
        startURL: URL,
        maxDepth: Int = 3,
        maxPages: Int = 500,
        allowedDomains: [String] = [],
        urlPatterns: [String] = [],
        respectRobotsTxt: Bool = true,
        userAgent: String = "HubFrameworkCrawler/1.0",
        rateLimit: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.startURL = startURL
        self.maxDepth = maxDepth
        self.maxPages = maxPages
        self.allowedDomains = allowedDomains
        self.urlPatterns = urlPatterns
        self.respectRobotsTxt = respectRobotsTxt
        self.userAgent = userAgent
        self.rateLimit = rateLimit
    }
}

// MARK: - Crawl Progress

/// Progress information for a crawl operation
public struct CrawlProgress: Codable {
    public let configId: UUID
    public let pagesProcessed: Int
    public let totalPages: Int
    public let currentDepth: Int
    public let status: CrawlStatus
    public let startedAt: Date
    public let lastUpdate: Date
    
    public var progress: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(pagesProcessed) / Double(totalPages)
    }
    
    public init(
        configId: UUID,
        pagesProcessed: Int = 0,
        totalPages: Int = 0,
        currentDepth: Int = 0,
        status: CrawlStatus = .pending,
        startedAt: Date = Date(),
        lastUpdate: Date = Date()
    ) {
        self.configId = configId
        self.pagesProcessed = pagesProcessed
        self.totalPages = totalPages
        self.currentDepth = currentDepth
        self.status = status
        self.startedAt = startedAt
        self.lastUpdate = lastUpdate
    }
}

// MARK: - Crawl Status

/// Status of a crawl operation
public enum CrawlStatus: String, Codable {
    case pending = "Pending"
    case running = "Running"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

// MARK: - Framework Documentation Crawler

/// Crawls and indexes Apple framework documentation
public actor FrameworkDocumentationCrawler {
    
    // MARK: - Properties
    
    /// Active crawl operations
    private var activeCrawls: [UUID: CrawlProgress] = [:]
    
    /// Crawled documents storage
    private var documents: [UUID: [CrawledDocument]] = [:]
    
    /// Rate limiter for respecting crawl limits
    private var lastRequestTime: [String: Date] = [:]
    
    /// Robots.txt cache
    private var robotsCache: [String: RobotsTxt] = [:]
    
    // MARK: - Public API
    
    public init() {}
    
    /// Start a crawl operation for a specific framework
    /// - Parameter framework: The framework to crawl
    /// - Returns: The crawl configuration ID
    /// - Throws: CrawlerError if the crawl cannot be started
    public func crawlFramework(_ framework: AppleFramework) async throws -> UUID {
        let config = createCrawlConfig(for: framework)
        return try await startCrawl(config: config)
    }
    
    /// Start a crawl operation with a custom configuration
    /// - Parameter config: The crawl configuration
    /// - Returns: The crawl configuration ID
    /// - Throws: CrawlerError if the crawl cannot be started
    public func startCrawl(config: CrawlConfig) async throws -> UUID {
        // Validate configuration
        try validateConfig(config)
        
        // Initialize progress tracking
        let progress = await CrawlProgress(
            configId: config.id,
            totalPages: config.maxPages,
            status: .running
        )
        activeCrawls[config.id] = progress
        
        // Start crawling in background
        Task {
            await performCrawl(config: config)
        }
        
        return config.id
    }
    
    /// Get the progress of a crawl operation
    /// - Parameter configId: The crawl configuration ID
    /// - Returns: The current progress, or nil if not found
    public func getProgress(for configId: UUID) -> CrawlProgress? {
        return activeCrawls[configId]
    }
    
    /// Get all documents from a completed crawl
    /// - Parameter configId: The crawl configuration ID
    /// - Returns: Array of crawled documents
    public func getDocuments(for configId: UUID) -> [CrawledDocument] {
        return documents[configId] ?? []
    }
    
    /// Cancel a running crawl operation
    /// - Parameter configId: The crawl configuration ID
    public func cancelCrawl(_ configId: UUID) {
        if var progress = activeCrawls[configId] {
            progress = CrawlProgress(
                configId: progress.configId,
                pagesProcessed: progress.pagesProcessed,
                totalPages: progress.totalPages,
                currentDepth: progress.currentDepth,
                status: .cancelled,
                startedAt: progress.startedAt,
                lastUpdate: Date()
            )
            activeCrawls[configId] = progress
        }
    }
    
    /// Crawl all supported Apple frameworks
    /// - Returns: Dictionary mapping framework names to crawl IDs
    /// - Throws: CrawlerError if any crawl fails to start
    public func crawlAllFrameworks() async throws -> [String: UUID] {
        var results: [String: UUID] = [:]
        
        for framework in await AppleFramework.allCases {
            do {
                let configId = try await crawlFramework(framework)
                results[framework.name] = configId
                
                // Rate limiting between framework crawls
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            } catch {
                print("⚠️ Failed to start crawl for \(framework.name): \(error)")
            }
        }
        
        return results
    }
    
    /// Wait for a crawl to complete and return the documents
    /// - Parameter configId: The crawl configuration ID
    /// - Returns: Array of crawled documents
    /// - Throws: CrawlerError if the crawl fails or is cancelled
    public func waitForCompletion(_ configId: UUID) async throws -> [CrawledDocument] {
        // Poll for completion
        while true {
            guard let progress = activeCrawls[configId] else {
                throw CrawlerError.invalidConfiguration("Crawl not found")
            }
            
            switch progress.status {
            case .completed:
                return documents[configId] ?? []
            case .failed:
                throw CrawlerError.httpError("Crawl failed")
            case .cancelled:
                throw CrawlerError.httpError("Crawl cancelled")
            case .running, .pending, .paused:
                // Wait and check again
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Create a crawl configuration for a framework
    private func createCrawlConfig(for framework: AppleFramework) -> CrawlConfig {
        let frameworkPath = framework.name.lowercased().replacingOccurrences(of: " ", with: "")
        
        return CrawlConfigurationBuilder(startURL: framework.appleDocURL)
            .withName("Framework: \(framework.name)")
            .withMaxDepth(3)
            .withMaxPages(500)
            .withAllowedDomains(["developer.apple.com", "swift.org"])
            .withURLPatterns([
                "/documentation/\(frameworkPath)",
                "/tutorials/\(frameworkPath)"
            ])
            .withRateLimit(1.0)
            .build()
    }
    
    /// Validate a crawl configuration
    private func validateConfig(_ config: CrawlConfig) throws {
        guard config.maxDepth > 0 else {
            throw CrawlerError.invalidConfiguration("maxDepth must be positive")
        }
        
        guard config.maxPages > 0 else {
            throw CrawlerError.invalidConfiguration("maxPages must be positive")
        }
        
        guard config.rateLimit > 0 else {
            throw CrawlerError.invalidConfiguration("rateLimit must be positive")
        }
    }
    
    /// Perform the actual crawl operation
    private func performCrawl(config: CrawlConfig) async {
        var visitedURLs: Set<String> = []
        var urlQueue: [(URL, Int)] = [(config.startURL, 0)]
        var processedCount = 0
        
        while !urlQueue.isEmpty && processedCount < config.maxPages {
            // Check if crawl was cancelled
            guard let progress = activeCrawls[config.id], progress.status == .running else {
                break
            }
            
            let (url, depth) = urlQueue.removeFirst()
            let urlString = url.absoluteString
            
            // Skip if already visited
            guard !visitedURLs.contains(urlString) else { continue }
            
            // Skip if depth exceeded
            guard depth <= config.maxDepth else { continue }
            
            // Check robots.txt
            if config.respectRobotsTxt {
                guard await canCrawl(url: url, userAgent: config.userAgent) else {
                    continue
                }
            }
            
            // Rate limiting
            await enforceRateLimit(for: url.host ?? "", rateLimit: config.rateLimit)
            
            // Fetch and process document
            do {
                let document = try await fetchDocument(url: url, config: config)
                
                // Store document
                if documents[config.id] == nil {
                    documents[config.id] = []
                }
                documents[config.id]?.append(document)
                
                visitedURLs.insert(urlString)
                processedCount += 1
                
                // Update progress
                updateProgress(
                    configId: config.id,
                    pagesProcessed: processedCount,
                    currentDepth: depth
                )
                
                // Extract and queue links if not at max depth
                if depth < config.maxDepth {
                    let links = extractLinks(from: document, baseURL: url, config: config)
                    for link in links {
                        urlQueue.append((link, depth + 1))
                    }
                }
                
            } catch {
                print("⚠️ Failed to fetch \(url): \(error)")
            }
        }
        
        // Mark as completed
        if var progress = activeCrawls[config.id] {
            progress = await CrawlProgress(
                configId: progress.configId,
                pagesProcessed: processedCount,
                totalPages: config.maxPages,
                currentDepth: progress.currentDepth,
                status: .completed,
                startedAt: progress.startedAt,
                lastUpdate: Date()
            )
            activeCrawls[config.id] = progress
        }
    }
    
    /// Fetch a document from a URL
    private func fetchDocument(url: URL, config: CrawlConfig) async throws -> CrawledDocument {
        var request = URLRequest(url: url)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CrawlerError.httpError("Invalid response")
        }
        
        guard let htmlContent = String(data: data, encoding: .utf8) else {
            throw CrawlerError.decodingError("Failed to decode HTML")
        }
        
        // Extract text content (simplified - in production would use proper HTML parsing)
        let content = extractTextContent(from: htmlContent)
        let title = extractTitle(from: htmlContent) ?? url.lastPathComponent
        let metadata = extractMetadata(from: htmlContent, url: url)
        
        return await CrawledDocument(
            url: url,
            title: title,
            content: content,
            htmlContent: htmlContent,
            metadata: metadata
        )
    }
    
    /// Extract text content from HTML
    private func extractTextContent(from html: String) -> String {
        // Simplified text extraction - remove HTML tags
        var text = html
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extract title from HTML
    private func extractTitle(from html: String) -> String? {
        let pattern = "<title>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let titleRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        return String(html[titleRange])
    }
    
    /// Extract metadata from HTML and URL
    private func extractMetadata(from html: String, url: URL) -> DocumentMetadata {
        var metadata = DocumentMetadata()
        
        // Determine document type from URL
        if url.path.contains("/documentation/") {
            metadata.documentType = .apiReference
        } else if url.path.contains("/tutorials/") {
            metadata.documentType = .tutorial
        } else if url.path.contains("/videos/") {
            metadata.documentType = .wwdcSession
        }
        
        // Extract framework name from URL
        let pathComponents = url.pathComponents
        if let docIndex = pathComponents.firstIndex(of: "documentation"),
           docIndex + 1 < pathComponents.count {
            metadata.framework = pathComponents[docIndex + 1]
        }
        
        metadata.codeLanguage = "swift"
        
        return metadata
    }
    
    /// Extract links from a document
    private func extractLinks(from document: CrawledDocument, baseURL: URL, config: CrawlConfig) -> [URL] {
        var links: [URL] = []
        
        // Simple link extraction using regex
        let pattern = "href=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return links
        }
        
        let range = NSRange(document.htmlContent.startIndex..., in: document.htmlContent)
        let matches = regex.matches(in: document.htmlContent, range: range)
        
        for match in matches {
            guard let linkRange = Range(match.range(at: 1), in: document.htmlContent) else {
                continue
            }
            
            let linkString = String(document.htmlContent[linkRange])
            
            // Convert relative URLs to absolute
            if let url = URL(string: linkString, relativeTo: baseURL)?.absoluteURL {
                // Check if URL matches allowed domains and patterns
                if shouldCrawlURL(url, config: config) {
                    links.append(url)
                }
            }
        }
        
        return links
    }
    
    /// Check if a URL should be crawled based on configuration
    private func shouldCrawlURL(_ url: URL, config: CrawlConfig) -> Bool {
        // Check allowed domains
        if !config.allowedDomains.isEmpty {
            guard let host = url.host,
                  config.allowedDomains.contains(where: { host.contains($0) }) else {
                return false
            }
        }
        
        // Check URL patterns
        if !config.urlPatterns.isEmpty {
            let path = url.path
            guard config.urlPatterns.contains(where: { path.contains($0) }) else {
                return false
            }
        }
        
        return true
    }
    
    /// Check if a URL can be crawled according to robots.txt
    private func canCrawl(url: URL, userAgent: String) async -> Bool {
        guard let host = url.host else { return false }
        
        // Check cache first
        if let robots = robotsCache[host] {
            return await robots.isAllowed(path: url.path, userAgent: userAgent)
        }
        
        // Fetch robots.txt
        let robotsURL = URL(string: "https://\(host)/robots.txt")!
        do {
            let (data, _) = try await URLSession.shared.data(from: robotsURL)
            if let content = String(data: data, encoding: .utf8) {
                let robots = await RobotsTxt(content: content)
                robotsCache[host] = robots
                return await robots.isAllowed(path: url.path, userAgent: userAgent)
            }
        } catch {
            // If robots.txt doesn't exist or can't be fetched, allow crawling
            return true
        }
        
        return true
    }
    
    /// Enforce rate limiting for a host
    private func enforceRateLimit(for host: String, rateLimit: Double) async {
        if let lastRequest = lastRequestTime[host] {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            let minimumInterval = 1.0 / rateLimit
            
            if timeSinceLastRequest < minimumInterval {
                let delay = minimumInterval - timeSinceLastRequest
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        lastRequestTime[host] = Date()
    }
    
    /// Update crawl progress
    private func updateProgress(configId: UUID, pagesProcessed: Int, currentDepth: Int) {
        guard let progress = activeCrawls[configId] else { return }
        
        let updated = CrawlProgress(
            configId: configId,
            pagesProcessed: pagesProcessed,
            totalPages: progress.totalPages,
            currentDepth: currentDepth,
            status: progress.status,
            startedAt: progress.startedAt,
            lastUpdate: Date()
        )
        
        activeCrawls[configId] = updated
    }
}

// MARK: - Robots.txt Parser

/// Simple robots.txt parser
private struct RobotsTxt {
    private let rules: [String: [String]]
    
    init(content: String) {
        var currentUserAgent = "*"
        var rules: [String: [String]] = [:]
        
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("User-agent:") {
                currentUserAgent = trimmed.replacingOccurrences(of: "User-agent:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Disallow:") {
                let path = trimmed.replacingOccurrences(of: "Disallow:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if rules[currentUserAgent] == nil {
                    rules[currentUserAgent] = []
                }
                rules[currentUserAgent]?.append(path)
            }
        }
        
        self.rules = rules
    }
    
    func isAllowed(path: String, userAgent: String) -> Bool {
        // Check specific user agent rules
        if let disallowed = rules[userAgent] {
            for pattern in disallowed {
                if path.hasPrefix(pattern) {
                    return false
                }
            }
        }
        
        // Check wildcard rules
        if let disallowed = rules["*"] {
            for pattern in disallowed {
                if path.hasPrefix(pattern) {
                    return false
                }
            }
        }
        
        return true
    }
}

// MARK: - Crawler Error

/// Errors that can occur during crawling
public enum CrawlerError: Error, LocalizedError {
    case invalidConfiguration(String)
    case httpError(String)
    case decodingError(String)
    case rateLimitExceeded
    case robotsTxtDisallowed
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .httpError(let message):
            return "HTTP error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .robotsTxtDisallowed:
            return "Crawling disallowed by robots.txt"
        }
    }
}
