//
//  OfflineAssistantView.swift
//  Hub
//
//  Main UI for Offline Assistant with search and knowledge queries
//

import SwiftUI

public struct OfflineAssistantView: View {
    @StateObject private var viewModel = OfflineAssistantViewModel()
    @State private var searchQuery = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                if searchQuery.isEmpty {
                    dashboardView
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("Offline Assistant")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Index Documentation") {
                            Task {
                                await viewModel.indexDocumentation()
                            }
                        }
                        Button("Clear Cache") {
                            Task {
                                await viewModel.clearCache()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search documentation, templates, code...", text: $searchQuery)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task {
                        await viewModel.search(query: searchQuery)
                    }
                }
            
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Dashboard
    
    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Actions
                quickActionsSection
                
                // Recent Queries
                if !viewModel.recentQueries.isEmpty {
                    recentQueriesSection
                }
                
                // Popular Topics
                popularTopicsSection
                
                // Statistics
                statisticsSection
            }
            .padding()
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                OfflineAssistantQuickActionCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Search Docs",
                    action: { searchQuery = "documentation" }
                )
                OfflineAssistantQuickActionCard(
                    icon: "square.grid.2x2",
                    title: "Find Templates",
                    action: { searchQuery = "templates" }
                )
                OfflineAssistantQuickActionCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "Code Examples",
                    action: { searchQuery = "code examples" }
                )
                OfflineAssistantQuickActionCard(
                    icon: "questionmark.circle",
                    title: "How-To Guides",
                    action: { searchQuery = "how to" }
                )
            }
        }
    }
    
    private var recentQueriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Queries")
                .font(.headline)
            
            ForEach(viewModel.recentQueries.prefix(5), id: \.self) { query in
                Button(action: {
                    searchQuery = query
                    Task {
                        await viewModel.search(query: query)
                    }
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        Text(query)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var popularTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Topics")
                .font(.headline)
            
            // TEMPORARY: FlowLayout not available - using HStack
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.popularTopics, id: \.self) { topic in
                        Button(topic) {
                            searchQuery = topic
                            Task {
                                await viewModel.search(query: topic)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Knowledge Base")
                .font(.headline)
            
            HStack(spacing: 20) {
                OfflineAssistantStatCard(value: "\(viewModel.documentCount)", label: "Documents")
                OfflineAssistantStatCard(value: "\(viewModel.templateCount)", label: "Templates")
                OfflineAssistantStatCard(value: "\(viewModel.codeExampleCount)", label: "Examples")
            }
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if viewModel.searchResults.isEmpty {
                    emptyResultsView
                } else {
                    ForEach(viewModel.searchResults) { result in
                        SearchResultCard(result: result)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No results found")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Try different keywords or browse popular topics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Supporting Views

private struct OfflineAssistantQuickActionCard: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct OfflineAssistantStatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.icon)
                    .foregroundStyle(.blue)
                Text(result.title)
                    .font(.headline)
            }
            
            Text(result.snippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(result.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(result.relevance, format: .percent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    OfflineAssistantView()
}
