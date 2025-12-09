//
//  FrameworkDocumentationCrawlerIntegration.swift
//  Hub
//
//  Integration between FrameworkDocumentationCrawler and OfflineAssistantModule
//

import Foundation

// MARK: - Framework Documentation Crawler Integration

extension FrameworkDocumentationCrawler {
    
    /// Crawl a framework and store results in KnowledgeStorageService
    /// - Parameters:
    ///   - framework: The framework to crawl
    ///   - knowledgeStorage: The knowledge storage service to use
    /// - Returns: The framework knowledge extracted from crawled documents
    /// - Throws: CrawlerError if crawling fails
    func crawlAndStore(
        framework: AppleFramework,
        knowledgeStorage: KnowledgeStorageService
    ) async throws -> FrameworkKnowledge {
        // Start the crawl
        let configId = try await crawlFramework(framework)
        
        // Wait for completion
        try await waitForCompletion(configId: configId)
        
        // Get crawled documents
        let documents = await getDocuments(for: configId)
        
        // Extract knowledge from documents
        let knowledge = await extractKnowledge(from: documents, framework: framework)
        
        // Store in knowledge base
        try await storeKnowledge(knowledge, in: knowledgeStorage)
        
        return knowledge
    }
    
    /// Wait for a crawl to complete
    /// - Parameter configId: The crawl configuration ID
    /// - Throws: CrawlerError if crawl fails or times out
    private func waitForCompletion(configId: UUID, timeout: TimeInterval = 300) async throws {
        let startTime = Date()
        
        while true {
            guard let progress = await getProgress(for: configId) else {
                throw CrawlerError.invalidConfiguration("Crawl not found")
            }
            
            switch progress.status {
            case .completed:
                return
            case .failed:
                throw CrawlerError.httpError("Crawl failed")
            case .cancelled:
                throw CrawlerError.httpError("Crawl cancelled")
            case .running, .pending, .paused:
                // Check timeout
                if Date().timeIntervalSince(startTime) > timeout {
                    throw CrawlerError.httpError("Crawl timeout")
                }
                
                // Wait before checking again
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    /// Extract knowledge from crawled documents
    /// - Parameters:
    ///   - documents: The crawled documents
    ///   - framework: The framework being documented
    /// - Returns: Extracted framework knowledge
    private func extractKnowledge(
        from documents: [CrawledDocument],
        framework: AppleFramework
    ) async -> FrameworkKnowledge {
        var capabilities: [FrameworkCapability] = []
        var patternNames: [String] = []
        var examples: [CodeExample] = []
        
        for document in documents {
            // Extract capabilities from API reference pages
            if document.metadata.documentType == .apiReference {
                let caps = await extractCapabilities(from: document)
                capabilities.append(contentsOf: caps)
            }
            
            // Extract patterns from tutorial pages
            if document.metadata.documentType == .tutorial {
                let patterns = extractPatternNames(from: document)
                patternNames.append(contentsOf: patterns)
            }
            
            // Extract code examples from all pages
            let exs = await extractCodeExamples(from: document)
            examples.append(contentsOf: exs)
        }
        
        return FrameworkKnowledge(
            framework: framework,
            capabilities: capabilities,
            patternNames: Array(Set(patternNames)), // Remove duplicates
            examples: examples,
            lastUpdated: Date()
        )
    }
    
    /// Extract capabilities from a document
    private func extractCapabilities(from document: CrawledDocument) async -> [FrameworkCapability] {
        var capabilities: [FrameworkCapability] = []
        
        // Look for API sections in the content
        let lines = document.content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            // Simple heuristic: look for lines that might be API names
            if line.contains("func ") || line.contains("class ") || line.contains("struct ") {
                let name = extractAPIName(from: line)
                let description = extractDescription(from: lines, startingAt: index)
                
                if !name.isEmpty {
                    let capability = await FrameworkCapability(
                        name: name,
                        description: description,
                        apiEndpoints: [name],
                        codeExamples: [],
                        complexity: .intermediate
                    )
                    capabilities.append(capability)
                }
            }
        }
        
        return capabilities
    }
    
    /// Extract API name from a line
    private func extractAPIName(from line: String) -> String {
        // Simple extraction - in production would use proper parsing
        let components = line.components(separatedBy: " ")
        for (index, component) in components.enumerated() {
            if component == "func" || component == "class" || component == "struct" {
                if index + 1 < components.count {
                    return components[index + 1].trimmingCharacters(in: CharacterSet(charactersIn: "(){}"))
                }
            }
        }
        return ""
    }
    
    /// Extract description from lines
    private func extractDescription(from lines: [String], startingAt index: Int) -> String {
        // Look for description in nearby lines
        var description = ""
        let startIndex = max(0, index - 3)
        let endIndex = min(lines.count, index + 3)
        
        for i in startIndex..<endIndex {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("///") || line.hasPrefix("//") {
                description += line.replacingOccurrences(of: "///", with: "")
                    .replacingOccurrences(of: "//", with: "")
                    .trimmingCharacters(in: .whitespaces) + " "
            }
        }
        
        return description.trimmingCharacters(in: .whitespaces)
    }
    
    /// Extract pattern names from a document
    private func extractPatternNames(from document: CrawledDocument) -> [String] {
        var patterns: [String] = []
        
        // Common design patterns to look for
        let commonPatterns = [
            "MVVM", "MVC", "Repository", "Singleton", "Factory",
            "Observer", "Delegate", "Strategy", "Coordinator"
        ]
        
        for pattern in commonPatterns {
            if document.content.contains(pattern) {
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    /// Extract code examples from a document
    private func extractCodeExamples(from document: CrawledDocument) async -> [CodeExample] {
        var examples: [CodeExample] = []
        
        // Look for code blocks in HTML
        let codeBlockPattern = "<code[^>]*>([^<]+)</code>"
        guard let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) else {
            return examples
        }
        
        let range = NSRange(document.htmlContent.startIndex..., in: document.htmlContent)
        let matches = regex.matches(in: document.htmlContent, range: range)
        
        for match in matches {
            guard let codeRange = Range(match.range(at: 1), in: document.htmlContent) else {
                continue
            }
            
            let code = String(document.htmlContent[codeRange])
            
            // Only include substantial code examples
            if code.count > 20 {
                let example = await CodeExample(
                    title: "Code Example from \(document.title)",
                    code: code,
                    language: "swift",
                    description: "Extracted from \(document.url.absoluteString)",
                    sourceURL: document.url
                )
                examples.append(example)
            }
        }
        
        return examples
    }
    
    /// Store framework knowledge in the knowledge storage service
    /// - Parameters:
    ///   - knowledge: The framework knowledge to store
    ///   - storage: The knowledge storage service
    /// - Throws: StorageError if storage fails
    private func storeKnowledge(
        _ knowledge: FrameworkKnowledge,
        in storage: KnowledgeStorageService
    ) async throws {
        // Create a knowledge entry for the framework
        let entry = await OfflineKnowledgeEntry(
            id: knowledge.id.uuidString,
            domainId: "apple-frameworks",
            originalSubmission: "Framework: \(knowledge.framework.name)",
            mappedData: await MappedData(
                type: .general_note_offline,
                content: createKnowledgeContent(from: knowledge),
                extractedEntities: await createEntities(from: knowledge)
            ),
            timestamp: knowledge.lastUpdated,
            status: .success,
            metadata: [
                "framework": knowledge.framework.name,
                "category": knowledge.framework.category.rawValue,
                "tags": createTags(from: knowledge).joined(separator: ",")
            ]
        )
        
        // Save to storage
        try await storage.save(entry)
    }
    
    /// Create knowledge content from framework knowledge
    private func createKnowledgeContent(from knowledge: FrameworkKnowledge) -> String {
        var content = "# \(knowledge.framework.name)\n\n"
        content += "Category: \(knowledge.framework.category.rawValue)\n"
        content += "Minimum OS: \(knowledge.framework.minimumOS)\n\n"
        
        content += "## Capabilities\n\n"
        for capability in knowledge.capabilities {
            content += "- **\(capability.name)**: \(capability.description)\n"
        }
        
        content += "\n## Design Patterns\n\n"
        for pattern in knowledge.patternNames {
            content += "- \(pattern)\n"
        }
        
        content += "\n## Code Examples\n\n"
        for example in knowledge.examples.prefix(5) {
            content += "### \(example.title)\n\n"
            content += "```\(example.language)\n\(example.code)\n```\n\n"
        }
        
        return content
    }
    
    /// Create entities from framework knowledge
    private func createEntities(from knowledge: FrameworkKnowledge) async -> [Entity] {
        var entities: [Entity] = []
        
        // Add framework as an entity
        entities.append(await Entity(
            type: "framework",
            value: knowledge.framework.name,
            metadata: ["category": knowledge.framework.category.rawValue]
        ))
        
        // Add capabilities as entities
        for capability in knowledge.capabilities.prefix(10) {
            entities.append(await Entity(
                type: "capability",
                value: capability.name,
                metadata: ["complexity": capability.complexity.rawValue]
            ))
        }
        
        return entities
    }
    
    /// Create tags from framework knowledge
    private func createTags(from knowledge: FrameworkKnowledge) -> [String] {
        var tags: [String] = []
        
        tags.append(knowledge.framework.name)
        tags.append(knowledge.framework.category.rawValue)
        tags.append("apple-framework")
        tags.append("documentation")
        
        // Add pattern names as tags
        tags.append(contentsOf: knowledge.patternNames)
        
        return Array(Set(tags)) // Remove duplicates
    }
}

// MARK: - Batch Crawling with Progress

extension FrameworkDocumentationCrawler {
    
    /// Crawl multiple frameworks and store results with progress tracking
    /// - Parameters:
    ///   - frameworks: The frameworks to crawl
    ///   - knowledgeStorage: The knowledge storage service
    ///   - progressHandler: Closure called with progress (0.0 to 1.0)
    /// - Returns: Dictionary mapping framework names to their knowledge
    func crawlAndStoreBatch(
        frameworks: [AppleFramework],
        knowledgeStorage: KnowledgeStorageService,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> [String: FrameworkKnowledge] {
        var results: [String: FrameworkKnowledge] = [:]
        let totalCount = frameworks.count
        
        for (index, framework) in frameworks.enumerated() {
            do {
                progressHandler(Double(index) / Double(totalCount), "Crawling \(framework.name)...")
                
                let knowledge = try await crawlAndStore(
                    framework: framework,
                    knowledgeStorage: knowledgeStorage
                )
                
                results[framework.name] = knowledge
                
                progressHandler(Double(index + 1) / Double(totalCount), "Completed \(framework.name)")
                
                // Rate limiting between frameworks
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
            } catch {
                print("⚠️ Failed to crawl \(framework.name): \(error)")
                progressHandler(Double(index + 1) / Double(totalCount), "Failed: \(framework.name)")
            }
        }
        
        return results
    }
}
