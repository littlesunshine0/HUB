//
//  OfflineAssistantIntegration.swift
//  Hub
//
//  Integration helpers for adding Offline Assistant to all modules
//

import SwiftUI

// MARK: - Integration View Modifier

extension View {
    /// Add Offline Assistant integration to any view
    public func withOfflineAssistant(
        context: String? = nil,
        searchHint: String? = nil
    ) -> some View {
        self.modifier(OfflineAssistantModifier(
            context: context,
            searchHint: searchHint
        ))
    }
}

struct OfflineAssistantModifier: ViewModifier {
    let context: String?
    let searchHint: String?
    @State private var showAssistant = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAssistant = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showAssistant) {
                NavigationStack {
                    OfflineAssistantView()
                }
            }
    }
}

// MARK: - Context-Aware Search

public struct ContextualSearchView: View {
    let module: String
    let context: String?
    @State private var searchQuery = ""
    @StateObject private var viewModel = OfflineAssistantViewModel()
    
    public init(module: String, context: String? = nil) {
        self.module = module
        self.context = context
    }
    
    public var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search \(module) help...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await viewModel.search(query: "\(module) \(searchQuery)")
                        }
                    }
            }
            .padding()
            
            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.searchResults.prefix(3)) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.headline)
                                Text(result.snippet)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Quick Help Button

public struct QuickHelpButton: View {
    let topic: String
    @State private var showHelp = false
    
    public init(topic: String) {
        self.topic = topic
    }
    
    public var body: some View {
        Button(action: { showHelp = true }) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
        }
        .popover(isPresented: $showHelp) {
            QuickHelpView(topic: topic)
                .frame(width: 300, height: 200)
        }
    }
}

struct QuickHelpView: View {
    let topic: String
    @StateObject private var viewModel = OfflineAssistantViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help: \(topic)")
                .font(.headline)
            
            if let result = viewModel.searchResults.first {
                ScrollView {
                    Text(result.snippet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.isSearching {
                ProgressView("Loading help...")
            } else {
                Text("No help available for \(topic)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .task {
            await viewModel.search(query: topic)
        }
    }
}

// MARK: - Global Search Bar

public struct GlobalSearchBar: View {
    @State private var searchQuery = ""
    @State private var showResults = false
    @StateObject private var viewModel = OfflineAssistantViewModel()
    
    public init() {}
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search Hub help...", text: $searchQuery)
                .textFieldStyle(.plain)
                .onSubmit {
                    if !searchQuery.isEmpty {
                        showResults = true
                        Task {
                            await viewModel.search(query: searchQuery)
                        }
                    }
                }
        }
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .sheet(isPresented: $showResults) {
            NavigationStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.searchResults) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.headline)
                                Text(result.snippet)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Search Results")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showResults = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Module-Specific Assistants

public struct AIModuleAssistant {
    public static func getAgentHelp(agentType: String) -> some View {
        QuickHelpButton(topic: "AI Agent \(agentType)")
    }
}

public struct TemplateModuleAssistant {
    public static func getTemplateHelp(templateType: String) -> some View {
        QuickHelpButton(topic: "Template \(templateType)")
    }
}

public struct AuthModuleAssistant {
    public static func getAuthHelp(flow: String) -> some View {
        QuickHelpButton(topic: "Authentication \(flow)")
    }
}

public struct PackageModuleAssistant {
    public static func getImportHelp() -> some View {
        QuickHelpButton(topic: "Package Import")
    }
    
    public static func getGitHubHelp() -> some View {
        QuickHelpButton(topic: "GitHub Import")
    }
}

public struct CommunityModuleAssistant {
    public static func getMarketplaceHelp() -> some View {
        QuickHelpButton(topic: "Marketplace")
    }
    
    public static func getSharingHelp() -> some View {
        QuickHelpButton(topic: "Template Sharing")
    }
}

public struct SettingsModuleAssistant {
    public static func getSettingsHelp(section: String) -> some View {
        QuickHelpButton(topic: "Settings \(section)")
    }
}

public struct RoleModuleAssistant {
    public static func getRoleHelp(role: String) -> some View {
        QuickHelpButton(topic: "Role \(role)")
    }
}

public struct AchievementsModuleAssistant {
    public static func getAchievementHelp() -> some View {
        QuickHelpButton(topic: "Achievements")
    }
}

public struct LiveCanvasModuleAssistant {
    public static func getPreviewHelp() -> some View {
        QuickHelpButton(topic: "Live Preview")
    }
}

public struct ComponentsModuleAssistant {
    public static func getComponentHelp(componentType: String) -> some View {
        QuickHelpButton(topic: "Component \(componentType)")
    }
}
