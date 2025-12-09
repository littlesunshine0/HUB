//
//  ProjectTaxonomy.swift
//  Hub
//
//  Defines the taxonomy and classification of all project entities
//  Clarifies: What is a Hub? What is an App? What is a Module? etc.
//

import Foundation
import SwiftUI
import Combine

/// Central taxonomy system for the project
@MainActor
class ProjectTaxonomy: ObservableObject {
    static let shared = ProjectTaxonomy()
    
    @Published var taxonomy: TaxonomyDefinition
    
    private init() {
        self.taxonomy = TaxonomyDefinition.standard
    }
    
    func getDefinition(for entity: ProjectEntityType) -> EntityDefinition? {
        return taxonomy.definitions[entity]
    }
    
    func printTaxonomy() {
        print("""
        
        ╔═══════════════════════════════════════════════════════════════╗
        ║                    PROJECT TAXONOMY                           ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        """)
        
        for (entityType, definition) in taxonomy.definitions.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            print("""
            ┌─────────────────────────────────────────────────────────────┐
            │ \(entityType.rawValue.uppercased())
            ├─────────────────────────────────────────────────────────────┤
            │ Definition: \(definition.description)
            │ Purpose: \(definition.purpose)
            │ Examples: \(definition.examples.joined(separator: ", "))
            │ Location: \(definition.location)
            └─────────────────────────────────────────────────────────────┘
            
            """)
        }
    }
    
    func exportTaxonomy() -> String {
        var output = """
        # Project Taxonomy
        
        This document defines the classification and purpose of all entities in the project.
        
        """
        
        for (entityType, definition) in taxonomy.definitions.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            output += """
            
            ## \(entityType.rawValue)
            
            **Definition:** \(definition.description)
            
            **Purpose:** \(definition.purpose)
            
            **Examples:**
            \(definition.examples.map { "- \($0)" }.joined(separator: "\n"))
            
            **Location:** `\(definition.location)`
            
            **Characteristics:**
            \(definition.characteristics.map { "- \($0)" }.joined(separator: "\n"))
            
            ---
            
            """
        }
        
        return output
    }
}

// MARK: - Taxonomy Definition

struct TaxonomyDefinition {
    var definitions: [ProjectEntityType: EntityDefinition]
    
    static let standard = TaxonomyDefinition(definitions: [
        // MARK: - Core Entities
        
        .app: EntityDefinition(
            description: "The main application container - 'Hub' is the APP",
            purpose: "Hub is the macOS application that hosts everything. It's the executable that users launch.",
            examples: ["Hub.app", "HubApp.swift (entry point)"],
            location: "Hub/ (root directory)",
            characteristics: [
                "Has @main entry point (HubApp.swift)",
                "Contains all modules, components, and features",
                "Manages app lifecycle and window management",
                "Provides the shell for all functionality"
            ]
        ),
        
        .hub: EntityDefinition(
            description: "A user-created application built within the Hub app",
            purpose: "Hubs are mini-applications that users create, customize, and deploy. Think of them as 'apps within the app'.",
            examples: [
                "Task Manager Hub",
                "Note Editor Hub",
                "File Manager Hub",
                "Custom user-created hubs"
            ],
            location: "Hub/AppHub.swift, Hub/Hub*.swift files",
            characteristics: [
                "Created by users or seeded as defaults",
                "Based on templates",
                "Stored in SwiftData",
                "Can be customized and published",
                "Has its own UI, data, and functionality"
            ]
        ),
        
        .template: EntityDefinition(
            description: "A blueprint for creating hubs",
            purpose: "Templates define the structure, UI, and functionality that hubs are built from.",
            examples: [
                "Task Manager Template",
                "Note Editor Template",
                "Dashboard Template"
            ],
            location: "Hub/TemplateModule/, Hub/TemplateSeeder.swift",
            characteristics: [
                "Defines hub structure",
                "Provides default UI and behavior",
                "Can be customized when creating a hub",
                "Stored as models",
                "Seeded on first launch"
            ]
        ),
        
        .module: EntityDefinition(
            description: "A major functional subsystem of the app",
            purpose: "Modules are large, self-contained feature areas that provide specific functionality to the app.",
            examples: [
                "AIModule - AI and agent functionality",
                "AuthenticationModule - User auth and accounts",
                "StorageLayer - Data persistence",
                "AutomationModule - Workflows and automation",
                "TemplateModule - Template management",
                "ComponentsModule - Reusable components"
            ],
            location: "Hub/*Module/ directories",
            characteristics: [
                "Self-contained functionality",
                "Has its own Models, Views, Services",
                "Can be independently developed",
                "Follows module architecture pattern",
                "Named with 'Module' suffix"
            ]
        ),
        
        .component: EntityDefinition(
            description: "A reusable UI or functional building block",
            purpose: "Components are smaller, reusable pieces that can be used across hubs and the app.",
            examples: [
                "ColorSlider",
                "CircularProgressBarView",
                "CapsuleButtonSystem",
                "SearchComponent"
            ],
            location: "Hub/ComponentsModule/, Hub/HubComponents/, Hub/*.swift (standalone)",
            characteristics: [
                "Reusable across the app",
                "Focused on single responsibility",
                "Can be UI or functional",
                "Composable with other components",
                "Smaller than modules"
            ]
        ),
        
        .blueprint: EntityDefinition(
            description: "A specification document for a feature or system",
            purpose: "Blueprints define requirements, design, and implementation plans for features.",
            examples: [
                "hub-browser-navigation spec",
                "local-first-database spec",
                "autonomous-marketplace spec"
            ],
            location: ".kiro/specs/*/",
            characteristics: [
                "Contains requirements.md, design.md, tasks.md",
                "Defines feature specifications",
                "Guides implementation",
                "Living documentation",
                "Version controlled"
            ]
        ),
        
        .framework: EntityDefinition(
            description: "An external or internal code library",
            purpose: "Frameworks provide foundational functionality and APIs.",
            examples: [
                "SwiftUI (Apple framework)",
                "SwiftData (Apple framework)",
                "Custom internal frameworks"
            ],
            location: "External dependencies or Hub/Frameworks/",
            characteristics: [
                "Provides APIs and functionality",
                "Can be internal or external",
                "Imported via Swift Package Manager or built-in",
                "Foundational to app functionality"
            ]
        ),
        
        .package: EntityDefinition(
            description: "A Swift Package that can be converted to a hub",
            purpose: "Packages are external Swift code that can be imported and converted into hubs.",
            examples: [
                "Third-party Swift packages",
                "Custom packages to be converted"
            ],
            location: "Hub/PackageModule/ (conversion logic)",
            characteristics: [
                "External Swift code",
                "Can be converted to hubs",
                "Managed by PackageModule",
                "Follows Swift Package Manager structure"
            ]
        ),
        
        // MARK: - Supporting Entities
        
        .service: EntityDefinition(
            description: "A business logic or data access layer",
            purpose: "Services handle business logic, API calls, and data operations.",
            examples: [
                "AuthenticationService",
                "CloudSyncService",
                "LocalStorageService"
            ],
            location: "Hub/*/Services/ directories",
            characteristics: [
                "Contains business logic",
                "Handles data operations",
                "Stateless or manages state",
                "Used by ViewModels and Views",
                "Named with 'Service' suffix"
            ]
        ),
        
        .viewModel: EntityDefinition(
            description: "A view's data and logic controller",
            purpose: "ViewModels manage view state and handle user interactions.",
            examples: [
                "HubViewModel",
                "HubDiscoveryViewModel",
                "HubEditorViewModel"
            ],
            location: "Hub/*ViewModel.swift files",
            characteristics: [
                "ObservableObject",
                "Manages view state",
                "Handles user actions",
                "Communicates with services",
                "Named with 'ViewModel' suffix"
            ]
        ),
        
        .view: EntityDefinition(
            description: "A SwiftUI view component",
            purpose: "Views define the UI and user interface elements.",
            examples: [
                "ContentView",
                "HubDetailView",
                "SettingsView"
            ],
            location: "Hub/*View.swift files, Hub/*/Views/",
            characteristics: [
                "Conforms to View protocol",
                "Defines UI structure",
                "Uses SwiftUI",
                "Named with 'View' suffix",
                "Declarative UI"
            ]
        ),
        
        .model: EntityDefinition(
            description: "A data structure or entity",
            purpose: "Models define data structures and entities used throughout the app.",
            examples: [
                "AppHub",
                "HubTemplateModel",
                "UserAccount"
            ],
            location: "Hub/*Model.swift files, Hub/*/Models/",
            characteristics: [
                "Defines data structure",
                "May conform to Codable, Identifiable",
                "Used with SwiftData or in-memory",
                "Named with 'Model' suffix or entity name",
                "Represents domain objects"
            ]
        ),
        
        .agent: EntityDefinition(
            description: "An AI-powered autonomous assistant",
            purpose: "Agents provide intelligent automation, assistance, and monitoring.",
            examples: [
                "ProjectHealthAgent",
                "AssetHealthAgent",
                "PageAgentSystem",
                "OwnerAIAssistant"
            ],
            location: "Hub/AIModule/, Hub/AutomationModule/Core/",
            characteristics: [
                "Autonomous or semi-autonomous",
                "Provides intelligent assistance",
                "Can monitor and auto-heal",
                "Named with 'Agent' suffix",
                "Uses AI/ML capabilities"
            ]
        ),
        
        .designSystem: EntityDefinition(
            description: "Visual design tokens and components",
            purpose: "Design system provides consistent styling, colors, and visual components.",
            examples: [
                "UnifiedColorSystem",
                "CapsuleButtonSystem",
                "AppTheme"
            ],
            location: "Hub/DesignSystem/",
            characteristics: [
                "Defines visual standards",
                "Provides reusable styles",
                "Ensures consistency",
                "Includes tokens and components",
                "Centralized design decisions"
            ]
        ),
        
        .automation: EntityDefinition(
            description: "Automated workflows and tasks",
            purpose: "Automation handles repetitive tasks and workflows automatically.",
            examples: [
                "WorkflowExecutionEngine",
                "AutomationCoordinator",
                "DatabaseHealthMonitor"
            ],
            location: "Hub/AutomationModule/",
            characteristics: [
                "Executes tasks automatically",
                "Monitors and responds to events",
                "Configurable workflows",
                "Reduces manual work",
                "Can be scheduled or triggered"
            ]
        ),
        
        .document: EntityDefinition(
            description: "Documentation and reference materials",
            purpose: "Documents provide information, guides, and specifications.",
            examples: [
                "README.md",
                "QUICK_START_GUIDE.md",
                "API documentation",
                "Spec documents"
            ],
            location: "Root directory, .kiro/specs/, Hub/*/README.md",
            characteristics: [
                "Markdown or text format",
                "Provides information",
                "Can be user-facing or developer-facing",
                "Version controlled",
                "Living documentation"
            ]
        )
    ])
}

// MARK: - Entity Types

enum ProjectEntityType: String, CaseIterable {
    case app = "App"
    case hub = "Hub"
    case template = "Template"
    case module = "Module"
    case component = "Component"
    case blueprint = "Blueprint"
    case framework = "Framework"
    case package = "Package"
    case service = "Service"
    case viewModel = "ViewModel"
    case view = "View"
    case model = "Model"
    case agent = "Agent"
    case designSystem = "Design System"
    case automation = "Automation"
    case document = "Document"
}

struct EntityDefinition {
    let description: String
    let purpose: String
    let examples: [String]
    let location: String
    let characteristics: [String]
}

// MARK: - Entity Classifier

struct EntityClassifier {
    static func classify(filePath: String) -> ProjectEntityType {
        let fileName = (filePath as NSString).lastPathComponent
        let directory = (filePath as NSString).deletingLastPathComponent
        
        // Check by file name patterns
        if fileName == "HubApp.swift" { return .app }
        if fileName.contains("AppHub") { return .hub }
        if fileName.contains("Template") { return .template }
        if fileName.contains("ViewModel") { return .viewModel }
        if fileName.contains("View") { return .view }
        if fileName.contains("Model") { return .model }
        if fileName.contains("Service") { return .service }
        if fileName.contains("Agent") { return .agent }
        
        // Check by directory
        if directory.contains("Module") { return .module }
        if directory.contains("Components") { return .component }
        if directory.contains("DesignSystem") { return .designSystem }
        if directory.contains("Automation") { return .automation }
        if directory.contains("specs") { return .blueprint }
        
        // Check by extension
        if fileName.hasSuffix(".md") { return .document }
        
        return .component // Default
    }
}
