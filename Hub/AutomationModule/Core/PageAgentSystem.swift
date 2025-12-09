//
//  PageAgentSystem.swift
//  Hub
//
//  Assigns AI agents to every page for contextual support
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PageAgentSystem: ObservableObject {
    static let shared = PageAgentSystem()
    
    @Published var activeAgents: [String: PageAgent] = [:]
    @Published var agentHistory: [AgentInteraction] = []
    @Published var showAgentPanel = false
    @Published var currentPageAgent: PageAgent?
    
    private init() {
        initializeDefaultAgents()
    }
    
    // MARK: - Agent Management
    
    func getAgent(for page: String) -> PageAgent {
        if let agent = activeAgents[page] {
            return agent
        }
        
        // Create new agent for this page
        let agent = createAgent(for: page)
        activeAgents[page] = agent
        return agent
    }
    
    func activateAgent(for page: String) {
        let agent = getAgent(for: page)
        currentPageAgent = agent
        showAgentPanel = true
        
        print("🤖 Agent activated for: \(page)")
    }
    
    func deactivateAgent() {
        currentPageAgent = nil
        showAgentPanel = false
    }
    
    // MARK: - Agent Creation
    
    private func createAgent(for page: String) -> PageAgent {
        let capabilities = determineCapabilities(for: page)
        let context = generateContext(for: page)
        
        return PageAgent(
            id: UUID(),
            page: page,
            name: "\(page) Assistant",
            capabilities: capabilities,
            context: context,
            personality: nil
        )
    }
    
    private func determineCapabilities(for page: String) -> [AgentCapability] {
        switch page.lowercased() {
        case let p where p.contains("hub"):
            return [.codeGeneration, .debugging, .documentation, .search, .suggestions]
        case let p where p.contains("template"):
            return [.codeGeneration, .design, .documentation, .suggestions]
        case let p where p.contains("settings"):
            return [.configuration, .troubleshooting, .documentation]
        case let p where p.contains("auth"):
            return [.security, .troubleshooting, .documentation]
        case let p where p.contains("storage"):
            return [.dataManagement, .troubleshooting, .optimization]
        default:
            return [.general, .documentation, .search]
        }
    }
    
    private func generateContext(for page: String) -> String {
        """
        I'm your AI assistant for the \(page) page. I can help you with:
        - Understanding features and functionality
        - Troubleshooting issues
        - Finding relevant documentation
        - Suggesting improvements
        - Answering questions
        
        How can I assist you today?
        """
    }
    
    // MARK: - Interaction
    
    func sendMessage(_ message: String, to agent: PageAgent) async -> String {
        let interaction = AgentInteraction(
            id: UUID(),
            type: .collaboration,
            participants: [],
            timestamp: Date(),
            outcome: .success
        )
        
        // Process message based on agent capabilities
        let response = await processMessage(message, with: agent)
        
        agentHistory.insert(interaction, at: 0)
        
        return response
    }
    
    private func processMessage(_ message: String, with agent: PageAgent) async -> String {
        // Simulate AI processing
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let lowercased = message.lowercased()
        
        // Context-aware responses
        if lowercased.contains("error") || lowercased.contains("issue") {
            return generateTroubleshootingResponse(for: agent.page)
        } else if lowercased.contains("how") || lowercased.contains("what") {
            return generateExplanationResponse(for: agent.page)
        } else if lowercased.contains("help") {
            return agent.context
        } else {
            return generateGeneralResponse(for: agent.page, message: message)
        }
    }
    
    private func generateTroubleshootingResponse(for page: String) -> String {
        """
        I can help troubleshoot issues on the \(page) page. Here are some common solutions:
        
        1. Check the console for error messages
        2. Verify your authentication status
        3. Ensure all required data is loaded
        4. Try refreshing the page
        5. Check your network connection
        
        Would you like me to run a diagnostic check?
        """
    }
    
    private func generateExplanationResponse(for page: String) -> String {
        """
        The \(page) page provides functionality for managing and interacting with your content.
        
        Key features:
        - View and manage items
        - Search and filter
        - Create and edit content
        - Access settings and preferences
        
        What specific aspect would you like to know more about?
        """
    }
    
    private func generateGeneralResponse(for page: String, message: String) -> String {
        """
        I understand you're asking about: "\(message)"
        
        On the \(page) page, I can help you with various tasks. Could you provide more details about what you'd like to accomplish?
        
        Some things I can help with:
        - Navigation and features
        - Best practices
        - Troubleshooting
        - Documentation
        """
    }
    
    // MARK: - Default Agents
    
    private func initializeDefaultAgents() {
        let defaultPages = [
            "HubDiscovery",
            "HubDetail",
            "HubEditor",
            "TemplateGallery",
            "Settings",
            "Authentication",
            "Storage",
            "Automation"
        ]
        
        for page in defaultPages {
            _ = getAgent(for: page)
        }
    }
    
    // MARK: - Agent Suggestions
    
    func getSuggestions(for page: String) -> [AgentSuggestion] {
        let agent = getAgent(for: page)
        
        switch page.lowercased() {
        case let p where p.contains("hub"):
            return [
                AgentSuggestion(text: "Create a new hub", action: .navigate("HubCreation")),
                AgentSuggestion(text: "Browse templates", action: .navigate("TemplateGallery")),
                AgentSuggestion(text: "View documentation", action: .openDocs("hubs"))
            ]
        case let p where p.contains("template"):
            return [
                AgentSuggestion(text: "Customize this template", action: .edit),
                AgentSuggestion(text: "Preview template", action: .preview),
                AgentSuggestion(text: "Export code", action: .export)
            ]
        default:
            return [
                AgentSuggestion(text: "Show help", action: .help),
                AgentSuggestion(text: "Search documentation", action: .search)
            ]
        }
    }
}

// MARK: - Supporting Types

struct PageAgent: Identifiable {
    let id: UUID
    let page: String
    let name: String
    let capabilities: [AgentCapability]
    let context: String
    let personality: AgentPersonality?
    
    var icon: String {
        "brain.head.profile"
    }
}

enum AgentCapability {
    case codeGeneration
    case debugging
    case documentation
    case search
    case suggestions
    case design
    case configuration
    case troubleshooting
    case security
    case dataManagement
    case optimization
    case general
    
    var displayName: String {
        switch self {
        case .codeGeneration: return "Code Generation"
        case .debugging: return "Debugging"
        case .documentation: return "Documentation"
        case .search: return "Search"
        case .suggestions: return "Suggestions"
        case .design: return "Design"
        case .configuration: return "Configuration"
        case .troubleshooting: return "Troubleshooting"
        case .security: return "Security"
        case .dataManagement: return "Data Management"
        case .optimization: return "Optimization"
        case .general: return "General Assistance"
        }
    }
    
    var icon: String {
        switch self {
        case .codeGeneration: return "chevron.left.forwardslash.chevron.right"
        case .debugging: return "ant.fill"
        case .documentation: return "book.fill"
        case .search: return "magnifyingglass"
        case .suggestions: return "lightbulb.fill"
        case .design: return "paintbrush.fill"
        case .configuration: return "gearshape.fill"
        case .troubleshooting: return "wrench.and.screwdriver.fill"
        case .security: return "lock.shield.fill"
        case .dataManagement: return "cylinder.fill"
        case .optimization: return "speedometer"
        case .general: return "questionmark.circle.fill"
        }
    }
}

struct AgentSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let action: SuggestionAction
}

enum SuggestionAction {
    case navigate(String)
    case edit
    case preview
    case export
    case help
    case search
    case openDocs(String)
}
