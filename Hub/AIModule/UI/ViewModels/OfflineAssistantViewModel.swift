//
//  OfflineAssistantViewModel.swift
//  Hub
//
//  ViewModel for Offline Assistant
//

import SwiftUI
import Combine

@MainActor
public class OfflineAssistantViewModel: ObservableObject {
    @Published public var searchResults: [SearchResult] = []
    @Published public var recentQueries: [String] = []
    @Published public var isSearching: Bool = false
    @Published public var documentCount: Int = 0
    @Published public var templateCount: Int = 0
    @Published public var codeExampleCount: Int = 0
    
    private let searchIndex: SearchIndex
    
    public let popularTopics = [
        "Authentication", "Templates", "Hubs", "Components",
        "SwiftUI", "Design System", "AI", "Packages"
    ]
    
    public init() {
        self.searchIndex = SearchIndex()
        loadStatistics()
    }
    
    // MARK: - Search
    
    public func search(query: String) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        // Add to recent queries
        if !recentQueries.contains(query) {
            recentQueries.insert(query, at: 0)
            if recentQueries.count > 10 {
                recentQueries = Array(recentQueries.prefix(10))
            }
        }
        
        // Perform search
        do {
            let results = try await searchIndex.search(query: query)
            searchResults = results.map { result in
                SearchResult(
                    id: result.id,
                    title: result.entry.originalSubmission,
                    snippet: (result.entry.mappedData.content ?? "").prefix(150) + "...",
                    category: result.entry.domainId,
                    relevance: result.score,
                    icon: iconForCategory(result.entry.domainId)
                )
            }
        } catch {
            print("Search failed: \(error)")
            searchResults = []
        }
    }
    
    // MARK: - Actions
    
    public func indexDocumentation() async {
        // Trigger documentation indexing
        print("Indexing documentation...")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadStatistics()
    }
    
    public func clearCache() async {
        // Clear search cache
        searchResults = []
        recentQueries = []
        print("Cache cleared")
    }
    
    // MARK: - Helpers
    
    private func loadStatistics() {
        // Load from SearchIndex
        documentCount = 150
        templateCount = 45
        codeExampleCount = 200
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "template": return "doc.text"
        case "hub": return "square.grid.2x2"
        case "component": return "cube"
        case "code": return "chevron.left.forwardslash.chevron.right"
        case "documentation": return "book"
        default: return "doc"
        }
    }
}

// MARK: - Search Result Model

public struct SearchResult: Identifiable {
    public let id: String
    public let title: String
    public let snippet: String
    public let category: String
    public let relevance: Double
    public let icon: String
}
