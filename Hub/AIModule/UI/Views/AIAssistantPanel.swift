//
//  AIAssistantPanel.swift
//  Hub
//
//  Floating AI assistant panel that appears contextually across all modules
//

import SwiftUI
import SwiftData
import Combine

struct AIAssistantPanel: View {
    @ObservedObject var orchestrator: UnifiedAIOrchestrator
    @State private var isExpanded: Bool = false
    @State private var userQuery: String = ""
    @State private var chatHistory: [AIChatMessage] = []
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .frame(width: isExpanded ? 400 : 60, height: isExpanded ? 600 : 60)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Collapsed View
    
    private var collapsedView: some View {
        Button {
            withAnimation {
                isExpanded = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
                    .symbolEffect(.pulse)
            }
        }
        .buttonStyle(.plain)
        .padding(5)
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("AI Assistant")
                        .font(.headline)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Context Badge
            HStack {
                Image(systemName: contextIcon)
                    .foregroundColor(.accentColor)
                Text(contextText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            
            // Chat History
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 12) {
                        if chatHistory.isEmpty {
                            emptyState
                        } else {
                            ForEach(chatHistory) { message in
                                AIChatBubble(message: message)
                            }
                        }
                        
                        // Suggestions
                        if !orchestrator.suggestions.isEmpty {
                            suggestionsView
                        }
                    }
                    .padding()
                    .onChange(of: chatHistory.count) { _, _ in
                        if let lastMessage = chatHistory.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 8) {
                TextField("Ask me anything...", text: $userQuery)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                if orchestrator.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(userQuery.isEmpty)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("How can I help?")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("I can assist with creating hubs, finding templates, explaining concepts, and more.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Suggestions View
    
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            ForEach(orchestrator.suggestions.prefix(3)) { suggestion in
                SuggestionCard(suggestion: suggestion) {
                    Task {
                        await orchestrator.executeSuggestion(suggestion)
                        addAssistantMessage("I've executed: \(suggestion.title)")
                    }
                }
            }
        }
    }
    
    // MARK: - Context Helpers
    
    private var contextIcon: String {
        switch orchestrator.currentContext {
        case .browser: return "square.grid.2x2"
        case .template: return "doc.text"
        case .component: return "cube.box"
        case .hub: return "square.stack.3d.up"
        case .package: return "shippingbox"
        case .blueprint: return "doc.plaintext"
        case .framework: return "building.columns"
        case .collaboration: return "person.2"
        case .settings: return "gearshape"
        }
    }
    
    private var contextText: String {
        switch orchestrator.currentContext {
        case .browser: return "Browsing"
        case .template: return "Template"
        case .component: return "Component"
        case .hub: return "Hub"
        case .package: return "Package"
        case .blueprint: return "Blueprint"
        case .framework: return "Framework"
        case .collaboration: return "Collaboration"
        case .settings: return "Settings"
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !userQuery.isEmpty else { return }
        
        let message = userQuery
        userQuery = ""
        
        // Add user message
        chatHistory.append(AIChatMessage(text: message, isUser: true))
        
        // Process query
        Task {
            let response = await orchestrator.processNaturalLanguageQuery(message)
            addAssistantMessage(response.message)
        }
    }
    
    private func addAssistantMessage(_ text: String) {
        chatHistory.append(AIChatMessage(text: text, isUser: false))
    }
}

// MARK: - Chat Bubble

struct AIChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        if message.isUser {
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.8)
                        } else {
                            Color(nsColor: .controlBackgroundColor)
                        }
                    }
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(12)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer() }
        }
        .id(message.id)
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: HubAISuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var categoryIcon: String {
        switch suggestion.category {
        case .general: return "lightbulb"
        case .optimization: return "speedometer"
        case .creation: return "plus.circle"
        case .learning: return "book"
        case .troubleshooting: return "wrench.and.screwdriver"
        case .navigation: return "arrow.right.circle"
        case .search: return "magnifyingglass"
        case .action: return "bolt.circle"
        case .information: return "info.circle"
        case .support: return "lifepreserver"
        }
    }
}

// MARK: - Chat Message Model

struct AIChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                AIAssistantPanel(
                    orchestrator: UnifiedAIOrchestrator(
                        modelContext: ModelContext(
                            try! ModelContainer(for: AppHub.self)
                        )
                    )
                )
                .padding()
            }
        }
    }
    .frame(width: 800, height: 600)
}
