//
//  HomeDirectoryProvider.swift
//  Hub
//
//  Uses your local codebase, frameworks, and personal directories as the AI knowledge base
//  No API required - completely free and private
//

import Foundation
import NaturalLanguage
import SwiftUI
import Combine

// MARK: - Home Directory AI Provider

@MainActor
final class HomeDirectoryProvider: ObservableObject {
    static let shared = HomeDirectoryProvider()
    
    @Published var isIndexing = false
    @Published var indexProgress: Double = 0
    @Published var indexedFileCount = 0
    @Published var knowledgeBaseSize: String = "0 KB"
    @Published var lastIndexDate: Date?
    
    private var knowledgeBase: LocalKnowledgeBase
    private var codeAnalyzer: CodebaseAnalyzer
    private var responseGenerator: LocalResponseGenerator
    
    // Configurable paths
    var projectPath: String = FileManager.default.currentDirectoryPath
    var personalDirectories: [String] = []
    var frameworkPaths: [String] = []
    
    init() {
        self.knowledgeBase = LocalKnowledgeBase()
        self.codeAnalyzer = CodebaseAnalyzer()
        self.responseGenerator = LocalResponseGenerator()
        
        // Auto-detect common paths
        setupDefaultPaths()
    }
    
    private func setupDefaultPaths() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        
        // Personal code directories
        personalDirectories = [
            "\(home)/Developer",
            "\(home)/Projects",
            "\(home)/Code",
            "\(home)/Documents/Code"
        ].filter { FileManager.default.fileExists(atPath: $0) }
        
        // Framework/SDK paths
        frameworkPaths = [
            "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks",
            "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
            "\(home)/Library/Developer/Xcode/DerivedData"
        ].filter { FileManager.default.fileExists(atPath: $0) }
    }
    
    // MARK: - Indexing
    
    func indexCurrentProject() async {
        await indexDirectory(projectPath, label: "Current Project")
    }
    
    func indexPersonalDirectories() async {
        for dir in personalDirectories {
            await indexDirectory(dir, label: "Personal: \(dir.components(separatedBy: "/").last ?? dir)")
        }
    }
    
    func indexAll() async {
        isIndexing = true
        indexProgress = 0
        
        // Index current project first (highest priority)
        await indexDirectory(projectPath, label: "Current Project", priority: .high)
        indexProgress = 0.4
        
        // Index personal directories
        for (index, dir) in personalDirectories.enumerated() {
            await indexDirectory(dir, label: "Personal", priority: .medium, maxDepth: 3)
            indexProgress = 0.4 + (0.4 * Double(index + 1) / Double(personalDirectories.count))
        }
        
        // Light index of framework headers (for API knowledge)
        for framework in frameworkPaths.prefix(2) {
            await indexFrameworkHeaders(framework)
        }
        indexProgress = 1.0
        
        lastIndexDate = Date()
        isIndexing = false
        
        await updateStats()
    }
    
    private func indexDirectory(_ path: String, label: String, priority: IndexPriority = .medium, maxDepth: Int = 10) async {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return }
        
        let codeExtensions = Set(["swift", "m", "h", "ts", "tsx", "js", "jsx", "py", "go", "rs", "java", "kt", "rb", "md", "json", "yaml", "yml"])
        var depth = 0
        var currentDir = ""
        
        while let file = enumerator.nextObject() as? String {
            // Track depth
            let components = file.components(separatedBy: "/")
            if components.count > maxDepth {
                enumerator.skipDescendants()
                continue
            }
            
            // Skip common non-code directories
            let skipDirs = ["node_modules", ".git", "build", "DerivedData", "Pods", ".build", "vendor", "__pycache__"]
            if skipDirs.contains(where: { file.contains("/\($0)/") || file.hasPrefix("\($0)/") }) {
                continue
            }
            
            let ext = (file as NSString).pathExtension.lowercased()
            guard codeExtensions.contains(ext) else { continue }
            
            let fullPath = (path as NSString).appendingPathComponent(file)
            
            // Read and index file
            if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                let doc = CodeDocument(
                    path: fullPath,
                    relativePath: file,
                    content: content,
                    language: ext,
                    priority: priority,
                    source: label
                )
                await knowledgeBase.index(doc)
                indexedFileCount += 1
            }
        }
    }
    
    private func indexFrameworkHeaders(_ frameworkPath: String) async {
        // Only index .h files for API signatures
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: frameworkPath) else { return }
        
        var headerCount = 0
        let maxHeaders = 500 // Limit to avoid huge index
        
        while let file = enumerator.nextObject() as? String, headerCount < maxHeaders {
            guard file.hasSuffix(".h") else { continue }
            
            let fullPath = (frameworkPath as NSString).appendingPathComponent(file)
            
            if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                // Only index public API declarations
                let apiContent = extractAPIDeclarations(content)
                if !apiContent.isEmpty {
                    let doc = CodeDocument(
                        path: fullPath,
                        relativePath: file,
                        content: apiContent,
                        language: "objc",
                        priority: .low,
                        source: "Framework"
                    )
                    await knowledgeBase.index(doc)
                    headerCount += 1
                }
            }
        }
    }
    
    private func extractAPIDeclarations(_ content: String) -> String {
        // Extract only interface declarations, not implementation
        var declarations: [String] = []
        let lines = content.components(separatedBy: "\n")
        
        var inInterface = false
        var currentDecl = ""
        
        for line in lines {
            if line.contains("@interface") || line.contains("@protocol") {
                inInterface = true
                currentDecl = line
            } else if inInterface {
                currentDecl += "\n" + line
                if line.contains("@end") {
                    declarations.append(currentDecl)
                    inInterface = false
                    currentDecl = ""
                }
            } else if line.hasPrefix("NS_") || line.hasPrefix("CF_") || line.contains("API_AVAILABLE") {
                declarations.append(line)
            }
        }
        
        return declarations.joined(separator: "\n\n")
    }
    
    private func updateStats() async {
        let stats = await knowledgeBase.stats()
        indexedFileCount = stats.documentCount
        knowledgeBaseSize = formatBytes(stats.totalSize)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Query Interface
    
    func ask(_ query: String, context: AIContext? = nil) async -> LocalAIResponse {
        // 1. Analyze the query
        let intent = analyzeIntent(query)
        
        // 2. Search knowledge base
        let relevantDocs = await knowledgeBase.search(query: query, topK: 10)
        
        // 3. If we have file context, prioritize it
        var contextDocs: [CodeDocument] = []
        if let filePath = context?.currentFile?.path {
            if let doc = await knowledgeBase.getDocument(path: filePath) {
                contextDocs.append(doc)
            }
        }
        
        // 4. Analyze code if selection provided
        var codeAnalysis: CodeAnalysisResult?
        if let selection = context?.selectedText {
            codeAnalysis = codeAnalyzer.analyze(selection)
        }
        
        // 5. Generate response based on local knowledge
        let response = await responseGenerator.generate(
            query: query,
            intent: intent,
            relevantDocs: relevantDocs,
            contextDocs: contextDocs,
            codeAnalysis: codeAnalysis
        )
        
        return response
    }
    
    func askStreaming(_ query: String, context: AIContext? = nil) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                let response = await ask(query, context: context)
                
                // Stream the response word by word
                let words = response.content.split(separator: " ")
                for word in words {
                    continuation.yield(String(word) + " ")
                    try? await Task.sleep(nanoseconds: 30_000_000) // 30ms per word
                }
                
                continuation.finish()
            }
        }
    }
    
    private func analyzeIntent(_ query: String) -> QueryIntent {
        let lowercased = query.lowercased()
        
        if lowercased.contains("how do i") || lowercased.contains("how to") {
            return .howTo
        } else if lowercased.contains("what is") || lowercased.contains("explain") {
            return .explain
        } else if lowercased.contains("find") || lowercased.contains("where") || lowercased.contains("search") {
            return .find
        } else if lowercased.contains("generate") || lowercased.contains("create") || lowercased.contains("write") {
            return .generate
        } else if lowercased.contains("fix") || lowercased.contains("error") || lowercased.contains("bug") {
            return .debug
        } else if lowercased.contains("refactor") || lowercased.contains("improve") {
            return .refactor
        } else if lowercased.contains("example") || lowercased.contains("show me") {
            return .example
        }
        return .general
    }
}

// MARK: - Local Knowledge Base

actor LocalKnowledgeBase {
    private var documents: [String: CodeDocument] = [:]
    private var invertedIndex: [String: Set<String>] = [:] // term -> document paths
    private var embeddings: [String: [Float]] = [:]
    private let embeddingService = LocalEmbeddingProvider()
    
    func index(_ doc: CodeDocument) async {
        documents[doc.path] = doc
        
        // Build inverted index
        let terms = tokenize(doc.content)
        for term in terms {
            invertedIndex[term, default: []].insert(doc.path)
        }
        
        // Generate embedding for semantic search
        if let embedding = try? await embeddingService.embed(doc.content.prefix(2000).description) {
            embeddings[doc.path] = embedding
        }
    }
    
    func search(query: String, topK: Int) async -> [CodeDocument] {
        // Hybrid search: keyword + semantic
        let keywordResults = keywordSearch(query: query, topK: topK * 2)
        let semanticResults = await semanticSearch(query: query, topK: topK * 2)
        
        // Merge with RRF
        var scores: [String: Double] = [:]
        let k = 60.0
        
        for (rank, path) in keywordResults.enumerated() {
            scores[path, default: 0] += 1.0 / (k + Double(rank + 1))
        }
        
        for (rank, path) in semanticResults.enumerated() {
            scores[path, default: 0] += 1.0 / (k + Double(rank + 1))
        }
        
        let sortedPaths = scores.sorted { $0.value > $1.value }
            .prefix(topK)
            .map { $0.key }
        
        return sortedPaths.compactMap { documents[$0] }
    }
    
    func getDocument(path: String) -> CodeDocument? {
        documents[path]
    }
    
    func stats() -> KnowledgeBaseStats {
        let totalSize = documents.values.reduce(0) { $0 + $1.content.count }
        return KnowledgeBaseStats(
            documentCount: documents.count,
            totalSize: totalSize,
            termCount: invertedIndex.count
        )
    }
    
    private func keywordSearch(query: String, topK: Int) -> [String] {
        let queryTerms = tokenize(query)
        var docScores: [String: Int] = [:]
        
        for term in queryTerms {
            if let matchingDocs = invertedIndex[term] {
                for docPath in matchingDocs {
                    docScores[docPath, default: 0] += 1
                }
            }
        }
        
        return docScores.sorted { $0.value > $1.value }
            .prefix(topK)
            .map { $0.key }
    }
    
    private func semanticSearch(query: String, topK: Int) async -> [String] {
        guard let queryEmbedding = try? await embeddingService.embed(query) else {
            return []
        }
        
        var scores: [(String, Float)] = []
        
        for (path, embedding) in embeddings {
            let similarity = cosineSimilarity(queryEmbedding, embedding)
            scores.append((path, similarity))
        }
        
        return scores.sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { $0.0 }
    }
    
    private func tokenize(_ text: String) -> Set<String> {
        Set(text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 })
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }
}


// MARK: - Codebase Analyzer

struct CodebaseAnalyzer {
    func analyze(_ code: String) -> CodeAnalysisResult {
        var result = CodeAnalysisResult()
        
        // Detect language
        result.language = detectLanguage(code)
        
        // Extract structure
        result.functions = extractFunctions(code, language: result.language)
        result.classes = extractClasses(code, language: result.language)
        result.imports = extractImports(code, language: result.language)
        
        // Analyze patterns
        result.patterns = detectPatterns(code)
        
        // Find potential issues
        result.issues = findIssues(code, language: result.language)
        
        // Complexity estimate
        result.complexity = estimateComplexity(code)
        
        return result
    }
    
    private func detectLanguage(_ code: String) -> String {
        if code.contains("import SwiftUI") || code.contains("func ") && code.contains("-> ") {
            return "swift"
        } else if code.contains("import React") || code.contains("const ") && code.contains("=>") {
            return "typescript"
        } else if code.contains("def ") && code.contains(":") && !code.contains("{") {
            return "python"
        } else if code.contains("func ") && code.contains("package ") {
            return "go"
        } else if code.contains("fn ") && code.contains("let mut") {
            return "rust"
        }
        return "unknown"
    }
    
    private func extractFunctions(_ code: String, language: String) -> [String] {
        var functions: [String] = []
        let pattern: String
        
        switch language {
        case "swift":
            pattern = #"func\s+(\w+)\s*\("#
        case "typescript", "javascript":
            pattern = #"(?:function\s+(\w+)|const\s+(\w+)\s*=\s*(?:async\s*)?\()"#
        case "python":
            pattern = #"def\s+(\w+)\s*\("#
        default:
            pattern = #"func\s+(\w+)"#
        }
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(code.startIndex..., in: code)
            let matches = regex.matches(in: code, range: range)
            
            for match in matches {
                for i in 1..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: code) {
                        functions.append(String(code[range]))
                        break
                    }
                }
            }
        }
        
        return functions
    }
    
    private func extractClasses(_ code: String, language: String) -> [String] {
        var classes: [String] = []
        let pattern: String
        
        switch language {
        case "swift":
            pattern = #"(?:class|struct|enum|protocol)\s+(\w+)"#
        case "typescript", "javascript":
            pattern = #"class\s+(\w+)"#
        case "python":
            pattern = #"class\s+(\w+)"#
        default:
            pattern = #"class\s+(\w+)"#
        }
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(code.startIndex..., in: code)
            let matches = regex.matches(in: code, range: range)
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: code) {
                    classes.append(String(code[range]))
                }
            }
        }
        
        return classes
    }
    
    private func extractImports(_ code: String, language: String) -> [String] {
        var imports: [String] = []
        let pattern: String
        
        switch language {
        case "swift":
            pattern = #"import\s+(\w+)"#
        case "typescript", "javascript":
            pattern = #"import\s+.*?from\s+['\"]([^'\"]+)['\"]"#
        case "python":
            pattern = #"(?:from\s+(\w+)|import\s+(\w+))"#
        default:
            pattern = #"import\s+(\w+)"#
        }
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(code.startIndex..., in: code)
            let matches = regex.matches(in: code, range: range)
            
            for match in matches {
                for i in 1..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: code), !code[range].isEmpty {
                        imports.append(String(code[range]))
                        break
                    }
                }
            }
        }
        
        return Array(Set(imports))
    }
    
    private func detectPatterns(_ code: String) -> [String] {
        var patterns: [String] = []
        
        if code.contains("@Observable") || code.contains("ObservableObject") {
            patterns.append("MVVM")
        }
        if code.contains("protocol") && code.contains("extension") {
            patterns.append("Protocol-Oriented")
        }
        if code.contains("async") && code.contains("await") {
            patterns.append("Async/Await")
        }
        if code.contains("Combine") || code.contains("Publisher") {
            patterns.append("Reactive")
        }
        if code.contains("@State") || code.contains("@Binding") {
            patterns.append("SwiftUI State Management")
        }
        if code.contains("dependency") || code.contains("inject") {
            patterns.append("Dependency Injection")
        }
        if code.contains("singleton") || code.contains("shared") {
            patterns.append("Singleton")
        }
        
        return patterns
    }
    
    private func findIssues(_ code: String, language: String) -> [String] {
        var issues: [String] = []
        
        if language == "swift" {
            if code.contains("!") && !code.contains("!=") {
                issues.append("Force unwrapping detected - consider using optional binding")
            }
            if code.contains("try!") {
                issues.append("Force try detected - consider proper error handling")
            }
            if code.contains("as!") {
                issues.append("Force cast detected - consider using as?")
            }
        }
        
        // General issues
        let lines = code.components(separatedBy: "\n")
        if lines.count > 300 {
            issues.append("File is quite long (\(lines.count) lines) - consider splitting")
        }
        
        let longLines = lines.filter { $0.count > 120 }
        if longLines.count > 10 {
            issues.append("\(longLines.count) lines exceed 120 characters")
        }
        
        return issues
    }
    
    private func estimateComplexity(_ code: String) -> Int {
        var complexity = 1
        let patterns = ["if ", "else ", "for ", "while ", "switch ", "case ", "catch ", "guard ", "&&", "||", "?"]
        
        for pattern in patterns {
            complexity += code.components(separatedBy: pattern).count - 1
        }
        
        return complexity
    }
}

// MARK: - Local Response Generator

actor LocalResponseGenerator {
    func generate(
        query: String,
        intent: QueryIntent,
        relevantDocs: [CodeDocument],
        contextDocs: [CodeDocument],
        codeAnalysis: CodeAnalysisResult?
    ) async -> LocalAIResponse {
        
        var response = ""
        var codeExamples: [String] = []
        var references: [String] = []
        
        switch intent {
        case .find:
            response = generateFindResponse(query: query, docs: relevantDocs)
            references = relevantDocs.prefix(5).map { $0.relativePath }
            
        case .explain:
            response = generateExplainResponse(query: query, docs: relevantDocs, analysis: codeAnalysis)
            if let analysis = codeAnalysis {
                codeExamples = analysis.functions.prefix(3).map { "func \($0)" }
            }
            
        case .howTo:
            response = generateHowToResponse(query: query, docs: relevantDocs)
            codeExamples = extractCodeExamples(from: relevantDocs, matching: query)
            
        case .generate:
            response = generateCodeResponse(query: query, docs: relevantDocs, context: contextDocs)
            codeExamples = [generateCodeSuggestion(query: query, docs: relevantDocs)]
            
        case .debug:
            response = generateDebugResponse(query: query, analysis: codeAnalysis, docs: relevantDocs)
            
        case .refactor:
            response = generateRefactorResponse(query: query, analysis: codeAnalysis, docs: relevantDocs)
            
        case .example:
            response = "Here are examples from your codebase:"
            codeExamples = extractCodeExamples(from: relevantDocs, matching: query)
            references = relevantDocs.prefix(3).map { $0.relativePath }
            
        case .general:
            response = generateGeneralResponse(query: query, docs: relevantDocs)
        }
        
        return LocalAIResponse(
            content: response,
            codeExamples: codeExamples,
            references: references,
            intent: intent
        )
    }
    
    private func generateFindResponse(query: String, docs: [CodeDocument]) -> String {
        if docs.isEmpty {
            return "I couldn't find anything matching '\(query)' in your codebase. Try a different search term."
        }
        
        var response = "Found \(docs.count) relevant files:\n\n"
        
        for (index, doc) in docs.prefix(5).enumerated() {
            response += "\(index + 1). **\(doc.relativePath)**\n"
            response += "   Language: \(doc.language), Source: \(doc.source)\n"
            
            // Show a snippet
            let snippet = doc.content.prefix(200).description.replacingOccurrences(of: "\n", with: " ")
            response += "   Preview: \(snippet)...\n\n"
        }
        
        return response
    }
    
    private func generateExplainResponse(query: String, docs: [CodeDocument], analysis: CodeAnalysisResult?) -> String {
        var response = ""
        
        if let analysis = analysis {
            response += "## Code Analysis\n\n"
            response += "**Language:** \(analysis.language)\n"
            response += "**Complexity:** \(analysis.complexity) (cyclomatic)\n\n"
            
            if !analysis.patterns.isEmpty {
                response += "**Patterns detected:** \(analysis.patterns.joined(separator: ", "))\n\n"
            }
            
            if !analysis.functions.isEmpty {
                response += "**Functions:** \(analysis.functions.joined(separator: ", "))\n\n"
            }
            
            if !analysis.classes.isEmpty {
                response += "**Types:** \(analysis.classes.joined(separator: ", "))\n\n"
            }
            
            if !analysis.issues.isEmpty {
                response += "**Potential issues:**\n"
                for issue in analysis.issues {
                    response += "- \(issue)\n"
                }
            }
        }
        
        if !docs.isEmpty {
            response += "\n## Related code in your project\n\n"
            for doc in docs.prefix(3) {
                response += "- \(doc.relativePath)\n"
            }
        }
        
        return response
    }
    
    private func generateHowToResponse(query: String, docs: [CodeDocument]) -> String {
        var response = "Based on your codebase, here's how you might approach this:\n\n"
        
        // Find similar implementations
        let examples = docs.filter { doc in
            let queryTerms = query.lowercased().split(separator: " ")
            return queryTerms.contains { doc.content.lowercased().contains($0) }
        }
        
        if !examples.isEmpty {
            response += "I found similar implementations in your project:\n\n"
            for doc in examples.prefix(3) {
                response += "**\(doc.relativePath)**\n"
            }
        } else {
            response += "I didn't find exact matches, but here are related files that might help:\n\n"
            for doc in docs.prefix(3) {
                response += "- \(doc.relativePath)\n"
            }
        }
        
        return response
    }
    
    private func generateCodeResponse(query: String, docs: [CodeDocument], context: [CodeDocument]) -> String {
        var response = "Based on your project's patterns, here's a suggestion:\n\n"
        
        // Analyze context to match style
        if let contextDoc = context.first {
            response += "Following the style in `\(contextDoc.relativePath)`:\n\n"
        }
        
        return response
    }
    
    private func generateDebugResponse(query: String, analysis: CodeAnalysisResult?, docs: [CodeDocument]) -> String {
        var response = "## Debugging Analysis\n\n"
        
        if let analysis = analysis, !analysis.issues.isEmpty {
            response += "**Potential issues found:**\n"
            for issue in analysis.issues {
                response += "- ⚠️ \(issue)\n"
            }
            response += "\n"
        }
        
        response += "**Suggestions:**\n"
        response += "1. Check for nil values and optional handling\n"
        response += "2. Verify all async operations are properly awaited\n"
        response += "3. Look for type mismatches\n"
        
        return response
    }
    
    private func generateRefactorResponse(query: String, analysis: CodeAnalysisResult?, docs: [CodeDocument]) -> String {
        var response = "## Refactoring Suggestions\n\n"
        
        if let analysis = analysis {
            if analysis.complexity > 10 {
                response += "- **Reduce complexity:** Consider breaking this into smaller functions\n"
            }
            
            if !analysis.issues.isEmpty {
                response += "- **Address issues:**\n"
                for issue in analysis.issues {
                    response += "  - \(issue)\n"
                }
            }
            
            if !analysis.patterns.contains("Protocol-Oriented") {
                response += "- Consider using protocols for better abstraction\n"
            }
        }
        
        return response
    }
    
    private func generateGeneralResponse(query: String, docs: [CodeDocument]) -> String {
        if docs.isEmpty {
            return "I can help you with questions about your codebase. Try asking about specific files, functions, or patterns."
        }
        
        return "Based on your codebase, here's what I found relevant to your question. Check these files: \(docs.prefix(3).map { $0.relativePath }.joined(separator: ", "))"
    }
    
    private func extractCodeExamples(from docs: [CodeDocument], matching query: String) -> [String] {
        var examples: [String] = []
        
        for doc in docs.prefix(5) {
            // Extract relevant code blocks
            let lines = doc.content.components(separatedBy: "\n")
            var inRelevantBlock = false
            var currentBlock = ""
            
            for line in lines {
                if line.lowercased().contains(query.lowercased().prefix(10)) {
                    inRelevantBlock = true
                }
                
                if inRelevantBlock {
                    currentBlock += line + "\n"
                    if line.contains("}") && currentBlock.filter({ $0 == "{" }).count == currentBlock.filter({ $0 == "}" }).count {
                        examples.append(currentBlock.trimmingCharacters(in: .whitespacesAndNewlines))
                        break
                    }
                }
            }
        }
        
        return examples.prefix(3).map { $0 }
    }
    
    private func generateCodeSuggestion(query: String, docs: [CodeDocument]) -> String {
        // Generate a code template based on query and existing patterns
        let lowercased = query.lowercased()
        
        if lowercased.contains("view") {
            return """
            struct NewView: View {
                var body: some View {
                    VStack {
                        Text("New View")
                    }
                }
            }
            """
        } else if lowercased.contains("function") || lowercased.contains("func") {
            return """
            func newFunction() {
                // Implementation
            }
            """
        } else if lowercased.contains("class") || lowercased.contains("model") {
            return """
            class NewModel: ObservableObject {
                @Published var data: String = ""
            }
            """
        }
        
        return "// Generated code based on your query"
    }
}


// MARK: - Models

struct CodeDocument {
    let path: String
    let relativePath: String
    let content: String
    let language: String
    let priority: IndexPriority
    let source: String
    let indexedAt: Date = Date()
}

enum IndexPriority {
    case high   // Current project
    case medium // Personal directories
    case low    // Frameworks
}

enum QueryIntent {
    case find
    case explain
    case howTo
    case generate
    case debug
    case refactor
    case example
    case general
}

struct CodeAnalysisResult {
    var language: String = "unknown"
    var functions: [String] = []
    var classes: [String] = []
    var imports: [String] = []
    var patterns: [String] = []
    var issues: [String] = []
    var complexity: Int = 0
}

struct LocalAIResponse {
    let content: String
    let codeExamples: [String]
    let references: [String]
    let intent: QueryIntent
}

struct KnowledgeBaseStats {
    let documentCount: Int
    let totalSize: Int
    let termCount: Int
}

// MARK: - Integration with AI Backend

extension AIBackendService {
    /// Use local knowledge base instead of external API
    func chatWithLocalKnowledge(
        message: String,
        context: AIContext?
    ) async -> AIResponse {
        let provider = await HomeDirectoryProvider.shared
        let response = await provider.ask(message, context: context)
        
        var fullContent = response.content
        
        // Add code examples
        if !response.codeExamples.isEmpty {
            fullContent += "\n\n## Code Examples\n\n"
            for (index, example) in response.codeExamples.enumerated() {
                fullContent += "```swift\n\(example)\n```\n\n"
            }
        }
        
        // Add references
        if !response.references.isEmpty {
            fullContent += "\n## References\n"
            for ref in response.references {
                fullContent += "- `\(ref)`\n"
            }
        }
        
        return AIResponse(
            content: fullContent,
            toolCalls: nil,
            tokensUsed: 0, // Free!
            model: "local-knowledge-base",
            finishReason: "complete"
        )
    }
    
    func streamWithLocalKnowledge(
        message: String,
        context: AIContext?
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let provider = await HomeDirectoryProvider.shared
                let stream = await provider.askStreaming(message, context: context)
                
                for await chunk in stream {
                    continuation.yield(StreamChunk(content: chunk, isComplete: false))
                }
                
                continuation.yield(StreamChunk(content: "", isComplete: true))
                continuation.finish()
            }
        }
    }
}

// MARK: - Settings Integration

extension AISettingsViewModel {
    func useLocalKnowledgeBase() {
        selectedProvider = .local
        
        Task {
            let provider = await HomeDirectoryProvider.shared
            await provider.indexAll()
        }
    }
}

// MARK: - Preview & Demo

#if DEBUG
struct HomeDirectoryProviderDemo: View {
    @StateObject private var provider = HomeDirectoryProvider.shared
    @State private var query = ""
    @State private var response: LocalAIResponse?
    @State private var isQuerying = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status
            GroupBox("Knowledge Base Status") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Indexed Files", value: "\(provider.indexedFileCount)")
                    LabeledContent("Size", value: provider.knowledgeBaseSize)
                    if let date = provider.lastIndexDate {
                        LabeledContent("Last Indexed", value: date.formatted())
                    }
                }
            }
            
            // Index buttons
            HStack {
                Button("Index Project") {
                    Task { await provider.indexCurrentProject() }
                }
                .disabled(provider.isIndexing)
                
                Button("Index All") {
                    Task { await provider.indexAll() }
                }
                .disabled(provider.isIndexing)
            }
            
            if provider.isIndexing {
                ProgressView(value: provider.indexProgress)
            }
            
            Divider()
            
            // Query
            TextField("Ask about your codebase...", text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task {
                        isQuerying = true
                        response = await provider.ask(query)
                        isQuerying = false
                    }
                }
            
            // Response
            if isQuerying {
                ProgressView("Searching...")
            } else if let response = response {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(response.content)
                            .textSelection(.enabled)
                        
                        if !response.codeExamples.isEmpty {
                            Text("Code Examples:")
                                .font(.headline)
                            ForEach(response.codeExamples, id: \.self) { example in
                                Text(example)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if !response.references.isEmpty {
                            Text("References:")
                                .font(.headline)
                            ForEach(response.references, id: \.self) { ref in
                                Text("• \(ref)")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview("Home Directory Provider") {
    HomeDirectoryProviderDemo()
}
#endif
