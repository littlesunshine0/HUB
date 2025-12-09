//
//  KnowledgeCenterView.swift
//  Hub
//
//  Technical documentation and knowledge base
//

import SwiftUI

struct KnowledgeCenterView: View {
    @State private var searchQuery = ""
    @State private var selectedTopic: KnowledgeTopic?
    
    enum KnowledgeTopic: String, CaseIterable, Identifiable {
        case architecture = "Architecture"
        case api = "API Reference"
        case bestPractices = "Best Practices"
        case tutorials = "Tutorials"
        case examples = "Code Examples"
        case changelog = "Changelog"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .architecture: return "building.columns"
            case .api: return "doc.text"
            case .bestPractices: return "checkmark.seal"
            case .tutorials: return "book.pages"
            case .examples: return "chevron.left.forwardslash.chevron.right"
            case .changelog: return "clock.arrow.circlepath"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(KnowledgeTopic.allCases, selection: $selectedTopic) { topic in
                Label(topic.rawValue, systemImage: topic.icon)
                    .tag(topic as KnowledgeTopic?)
            }
            .navigationTitle("Knowledge Center")
            .searchable(text: $searchQuery, prompt: "Search documentation...")
        } detail: {
            if let topic = selectedTopic {
                topicContent(for: topic)
            } else {
                knowledgeOverview
            }
        }
    }
    
    private var knowledgeOverview: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.purple.gradient)
                    
                    Text("Knowledge Center")
                        .font(.largeTitle.bold())
                    
                    Text("Technical documentation and guides")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Topics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(KnowledgeTopic.allCases) { topic in
                        KnowledgeTopicCard(topic: topic) {
                            selectedTopic = topic
                        }
                    }
                }
                .padding(.horizontal)
                
                // Recent Updates
                recentUpdatesSection
            }
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func topicContent(for topic: KnowledgeTopic) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Topic Header
                HStack {
                    Image(systemName: topic.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.purple.gradient)
                    
                    VStack(alignment: .leading) {
                        Text(topic.rawValue)
                            .font(.title.bold())
                        Text("Detailed \(topic.rawValue.lowercased()) documentation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Content
                switch topic {
                case .architecture:
                    architectureContent
                case .api:
                    apiContent
                case .bestPractices:
                    bestPracticesContent
                case .tutorials:
                    tutorialsContent
                case .examples:
                    examplesContent
                case .changelog:
                    changelogContent
                }
            }
            .padding()
        }
    }
    
    private var architectureContent: some View {
        VStack(spacing: 16) {
            DocumentSection(
                title: "System Architecture",
                description: "Overview of Hub's modular architecture",
                tags: ["Core", "Design"]
            )
            DocumentSection(
                title: "Data Flow",
                description: "Understanding data flow and state management",
                tags: ["Data", "State"]
            )
            DocumentSection(
                title: "Module System",
                description: "How modules are structured and interact",
                tags: ["Modules", "Integration"]
            )
            DocumentSection(
                title: "Storage Layer",
                description: "Local-first storage architecture",
                tags: ["Storage", "Sync"]
            )
        }
    }
    
    private var apiContent: some View {
        VStack(spacing: 16) {
            DocumentSection(
                title: "Core API",
                description: "Essential APIs for hub creation and management",
                tags: ["API", "Core"]
            )
            DocumentSection(
                title: "Template API",
                description: "Working with templates programmatically",
                tags: ["API", "Templates"]
            )
            DocumentSection(
                title: "Storage API",
                description: "Local storage and sync APIs",
                tags: ["API", "Storage"]
            )
            DocumentSection(
                title: "UI Components API",
                description: "Reusable UI component library",
                tags: ["API", "UI"]
            )
        }
    }
    
    private var bestPracticesContent: some View {
        VStack(spacing: 16) {
            DocumentSection(
                title: "Code Organization",
                description: "Structuring your hub projects effectively",
                tags: ["Best Practices", "Code"]
            )
            DocumentSection(
                title: "Performance Optimization",
                description: "Tips for optimal performance",
                tags: ["Best Practices", "Performance"]
            )
            DocumentSection(
                title: "Security Guidelines",
                description: "Keeping your hubs secure",
                tags: ["Best Practices", "Security"]
            )
            DocumentSection(
                title: "Testing Strategies",
                description: "Comprehensive testing approaches",
                tags: ["Best Practices", "Testing"]
            )
        }
    }
    
    private var tutorialsContent: some View {
        VStack(spacing: 16) {
            TutorialCard(
                title: "Building a Todo App",
                description: "Create a full-featured todo application",
                difficulty: "Beginner",
                duration: "30 min"
            )
            TutorialCard(
                title: "Real-Time Chat",
                description: "Build a collaborative chat interface",
                difficulty: "Intermediate",
                duration: "45 min"
            )
            TutorialCard(
                title: "E-Commerce Store",
                description: "Complete online store with payments",
                difficulty: "Advanced",
                duration: "2 hours"
            )
            TutorialCard(
                title: "Analytics Dashboard",
                description: "Data visualization and reporting",
                difficulty: "Intermediate",
                duration: "1 hour"
            )
        }
    }
    
    private var examplesContent: some View {
        VStack(spacing: 16) {
            CodeExampleCard(
                title: "Creating a Hub",
                language: "Swift",
                code: """
                let hub = AppHub(
                    name: "My Hub",
                    description: "A sample hub",
                    category: .productivity
                )
                """
            )
            CodeExampleCard(
                title: "Custom Component",
                language: "Swift",
                code: """
                struct CustomCard: View {
                    var body: some View {
                        VStack {
                            Text("Hello")
                        }
                        .padding()
                    }
                }
                """
            )
            CodeExampleCard(
                title: "Data Persistence",
                language: "Swift",
                code: """
                @Query var hubs: [AppHub]
                
                func saveHub() {
                    modelContext.insert(hub)
                    try? modelContext.save()
                }
                """
            )
        }
    }
    
    private var changelogContent: some View {
        VStack(spacing: 16) {
            ChangelogEntry(
                version: "2.0.0",
                date: "November 2025",
                changes: [
                    "Added Centers Module",
                    "Improved performance",
                    "New template system",
                    "Enhanced collaboration"
                ]
            )
            ChangelogEntry(
                version: "1.5.0",
                date: "October 2025",
                changes: [
                    "Local-first architecture",
                    "Offline support",
                    "CRDT sync",
                    "Bug fixes"
                ]
            )
            ChangelogEntry(
                version: "1.0.0",
                date: "September 2025",
                changes: [
                    "Initial release",
                    "Hub creation",
                    "Template system",
                    "Cloud sync"
                ]
            )
        }
    }
    
    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Updates")
                .font(.title2.bold())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                UpdateCard(
                    title: "New API Documentation",
                    description: "Complete API reference now available",
                    date: "2 days ago"
                )
                UpdateCard(
                    title: "Tutorial: Building Chat Apps",
                    description: "Learn to build real-time chat interfaces",
                    date: "1 week ago"
                )
                UpdateCard(
                    title: "Architecture Guide Updated",
                    description: "New section on module integration",
                    date: "2 weeks ago"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct KnowledgeTopicCard: View {
    let topic: KnowledgeCenterView.KnowledgeTopic
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: topic.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.purple.gradient)
                
                Text(topic.rawValue)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct DocumentSection: View {
    let title: String
    let description: String
    let tags: [String]
    
    var body: some View {
        Button {
            // Open document
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.purple.opacity(0.1))
                            .foregroundStyle(.purple)
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TutorialCard: View {
    let title: String
    let description: String
    let difficulty: String
    let duration: String
    
    var body: some View {
        Button {
            // Open tutorial
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Label(difficulty, systemImage: "chart.bar")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    
                    Spacer()
                    
                    Label(duration, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct CodeExampleCard: View {
    let title: String
    let language: String
    let code: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(language)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .cornerRadius(4)
            }
            
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ChangelogEntry: View {
    let version: String
    let date: String
    let changes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Version \(version)")
                    .font(.headline)
                Spacer()
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(change)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct UpdateCard: View {
    let title: String
    let description: String
    let date: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    KnowledgeCenterView()
}
