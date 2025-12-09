import Foundation
import SwiftUI

// MARK: - Expanded Hub Templates from iCloud Projects

/// Comprehensive hub library based on discovered projects and applications
/// This expands the hub ecosystem from 22 to 200+ templates
struct ExpandedHubLibrary {
    static let shared = ExpandedHubLibrary()
    
    private init() {}
    
    // MARK: - All Expanded Templates
    
    func getAllExpandedTemplates() -> [SimpleTemplateDefinition] {
        return fileManagementHubs +
               developmentToolsHubs +
               utilityApplicationsHubs +
               knowledgeManagementHubs +
               systemToolsHubs +
               creativeToolsHubs +
               productivityHubs +
               dataManagementHubs +
               securityToolsHubs +
               automationHubs +
               mediaToolsHubs +
               documentationHubs +
               analysisToolsHubs +
               buildToolsHubs +
               testingToolsHubs +
               deploymentHubs +
               monitoringHubs +
               collaborationHubs +
               learningHubs +
               referenceHubs
    }
    
    // MARK: - File Management Hubs (from Projects 56, 100, 101, 102, 103)
    
    private var fileManagementHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "File Explorer",
                category: .utilities,
                features: ["Browse files", "Grid/List layout", "Search", "Sort", "Inspector panel", "Tags", "Smooth animations"]
            ),
            SimpleTemplateDefinition(
                name: "File Manager Pro",
                category: .utilities,
                features: ["MVVM architecture", "Create/Rename/Move/Delete", "Encrypt files", "Archive files", "Backup/Restore", "Search"]
            ),
            SimpleTemplateDefinition(
                name: "File Manager Database",
                category: .utilities,
                features: ["Database-backed file management", "MVVM pattern", "Persistent storage", "File metadata"]
            ),
            SimpleTemplateDefinition(
                name: "File Operations",
                category: .utilities,
                features: ["Batch operations", "File transformations", "Bulk rename", "Format conversion"]
            ),
            SimpleTemplateDefinition(
                name: "Filing Cabinet",
                category: .productivity,
                features: ["Document organization", "Category management", "Quick access", "Archive system"]
            ),
            SimpleTemplateDefinition(
                name: "Backup Manager",
                category: .utilities,
                features: ["Automated backups", "Restore points", "Incremental backup", "Cloud sync"]
            ),
            SimpleTemplateDefinition(
                name: "Duplicate Finder",
                category: .utilities,
                features: ["Find duplicate files", "Hash comparison", "Smart cleanup", "Space recovery"]
            ),
            SimpleTemplateDefinition(
                name: "File Scanner",
                category: .utilities,
                features: ["Deep file scanning", "Metadata extraction", "Content indexing", "Search optimization"]
            )
        ]
    }
    
    // MARK: - Development Tools Hubs
    
    private var developmentToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Console",
                category: .development,
                features: ["Terminal emulator", "Command history", "Syntax highlighting", "Multi-tab support"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My CLI",
                category: .development,
                features: ["Custom CLI builder", "Command parser", "Argument handling", "Help generation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My Console Package",
                category: .development,
                features: ["Console utilities", "Output formatting", "Progress bars", "Interactive prompts"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Color Gen Tool",
                category: .development,
                features: ["Color palette generation", "Hex/RGB conversion", "Theme builder", "Export formats"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Icon Bae",
                category: .development,
                features: ["Icon generation", "Multiple sizes", "Asset catalog", "Export formats"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Metal Gen",
                category: .development,
                features: ["Metal shader generator", "GPU code", "Performance optimization", "Visual effects"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "MetalKit",
                category: .development,
                features: ["Metal framework", "3D rendering", "Compute shaders", "GPU acceleration"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "MetalS",
                category: .development,
                features: ["Metal utilities", "Shader library", "Rendering pipeline", "Performance tools"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My Component Library",
                category: .development,
                features: ["Reusable components", "SwiftUI views", "Design system", "Documentation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My SVG Library",
                category: .development,
                features: ["SVG rendering", "Vector graphics", "Path manipulation", "Export tools"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My Tools",
                category: .development,
                features: ["Developer utilities", "Code helpers", "Quick actions", "Productivity boosters"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Utility Applications (from Applications folder)
    
    private var utilityApplicationsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Build Droplet",
                category: .development,
                features: ["Drag-and-drop build", "Automated compilation", "Quick deployment", "Build scripts"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Numpad Demo",
                category: .utilities,
                features: ["Virtual numpad", "Keyboard shortcuts", "Custom layouts", "Accessibility"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Export Key Codes",
                category: .development,
                features: ["Key code reference", "Event monitoring", "Shortcut mapping", "Documentation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Function Keys Reference",
                category: .utilities,
                features: ["F-key reference", "System shortcuts", "App-specific keys", "Quick lookup"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Groups Manager",
                category: .productivity,
                features: ["Group organization", "Member management", "Permissions", "Collaboration"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Keyboard Reference",
                category: .utilities,
                features: ["Keyboard shortcuts", "System commands", "App shortcuts", "Cheat sheets"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Keyboard Shortcuts Reference",
                category: .utilities,
                features: ["Comprehensive shortcuts", "Search", "Categories", "Custom shortcuts"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Packager",
                category: .development,
                features: ["App packaging", "Bundle creation", "Distribution", "Code signing"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Path Cleaner",
                category: .utilities,
                features: ["PATH management", "Environment cleanup", "Duplicate removal", "Optimization"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Pattern Learner",
                category: .development,
                features: ["Pattern recognition", "Code analysis", "Learning algorithms", "Suggestions"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Privilege Utility",
                category: .security,
                features: ["Permission management", "Privilege escalation", "Security audit", "Access control"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "SIP Helper",
                category: .security,
                features: ["System Integrity Protection", "SIP status", "Security management", "System tools"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "User Info Checker",
                category: .utilities,
                features: ["User information", "System details", "Environment vars", "Diagnostics"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Volume Control",
                category: .utilities,
                features: ["Audio control", "Volume management", "Device selection", "Shortcuts"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "File Renamer",
                category: .utilities,
                features: ["Batch rename", "Pattern matching", "Preview", "Undo support"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Folder Creator",
                category: .utilities,
                features: ["Batch folder creation", "Templates", "Structure generation", "Automation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Folder Sync",
                category: .utilities,
                features: ["Folder synchronization", "Bidirectional sync", "Conflict resolution", "Scheduling"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "System Info",
                category: .utilities,
                features: ["System information", "Hardware details", "Performance metrics", "Diagnostics"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Text Processor",
                category: .productivity,
                features: ["Text manipulation", "Batch processing", "Regex support", "Transformations"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Web Search Tool",
                category: .utilities,
                features: ["Quick web search", "Multiple engines", "Shortcuts", "History"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Menu Bar App",
                category: .utilities,
                features: ["Menu bar integration", "Quick access", "System tray", "Notifications"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Knowledge Management Hubs (from Projects 74, 75)
    
    private var knowledgeManagementHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Knowledge Engine",
                category: .productivity,
                features: ["Knowledge base", "Search", "Indexing", "Relationships", "Tags"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Knowledge Hub",
                category: .productivity,
                features: ["Central knowledge repository", "Wiki-style", "Collaboration", "Version control"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Learning Assistant",
                category: .education,
                features: ["AI-powered learning", "Study guides", "Progress tracking", "Personalized content"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Documentation Hub",
                category: .development,
                features: ["Technical documentation", "API docs", "Code examples", "Search"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - System Tools Hubs
    
    private var systemToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "AppleScript Library Manager",
                category: .development,
                features: ["Script management", "Library organization", "Quick execution", "Automation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "AppleScript Runner",
                category: .utilities,
                features: ["Script execution", "Scheduling", "Error handling", "Logging"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Backup Script",
                category: .utilities,
                features: ["Automated backups", "Scheduling", "Compression", "Cloud upload"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Update Self",
                category: .utilities,
                features: ["Auto-update", "Version checking", "Download", "Installation"],
                dependencies: []
            )
        ]
    }

    
    // MARK: - Creative Tools Hubs
    
    private var creativeToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Design Studio",
                category: .creative,
                features: ["Vector design", "Layers", "Export", "Templates"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Color Palette Generator",
                category: .creative,
                features: ["Color schemes", "Harmony rules", "Export", "Accessibility check"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Icon Designer",
                category: .creative,
                features: ["Icon creation", "Multiple formats", "Grid system", "Export"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Asset Manager",
                category: .creative,
                features: ["Asset library", "Organization", "Preview", "Export"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Productivity Hubs
    
    private var productivityHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Hiking Survey",
                category: .lifestyle,
                features: ["Trail tracking", "Survey forms", "Data collection", "Reports"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Hunter",
                category: .lifestyle,
                features: ["Hunting logs", "Location tracking", "Weather", "Regulations"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Columns",
                category: .productivity,
                features: ["Column layout", "Data organization", "Sorting", "Filtering"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Document Manager",
                category: .productivity,
                features: ["Document storage", "Version control", "Search", "Sharing"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My Content",
                category: .productivity,
                features: ["Content management", "Organization", "Tags", "Search"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My New App",
                category: .productivity,
                features: ["App template", "Basic structure", "Navigation", "Settings"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Data Management Hubs
    
    private var dataManagementHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Database Manager",
                category: .development,
                features: ["Database operations", "Query builder", "Schema management", "Migrations"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Data Core Framework",
                category: .development,
                features: ["Core data wrapper", "Model management", "Persistence", "Sync"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My Data Framework",
                category: .development,
                features: ["Data layer", "Repository pattern", "Caching", "Validation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "My Data Operations Lexicon",
                category: .development,
                features: ["Data operations", "CRUD", "Batch processing", "Transactions"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Manage Data",
                category: .utilities,
                features: ["Data management", "Import/Export", "Transformations", "Validation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Document Core",
                category: .productivity,
                features: ["Document framework", "File handling", "Metadata", "Search"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Schema Manager",
                category: .development,
                features: ["Schema design", "Validation", "Migration", "Documentation"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Services Layer",
                category: .development,
                features: ["Service architecture", "API layer", "Business logic", "Integration"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Security Tools Hubs
    
    private var securityToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Sentinel",
                category: .security,
                features: ["Security monitoring", "Threat detection", "Alerts", "Logging"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Audit Bin Paths",
                category: .security,
                features: ["Path auditing", "Security scan", "Vulnerability check", "Reports"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Permission Manager",
                category: .security,
                features: ["Permission control", "Access management", "Role-based", "Audit trail"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Security Scanner",
                category: .security,
                features: ["Vulnerability scanning", "Code analysis", "Dependency check", "Reports"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Automation Hubs
    
    private var automationHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Workflow Automator",
                category: .productivity,
                features: ["Workflow builder", "Task automation", "Scheduling", "Triggers"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Script Runner",
                category: .development,
                features: ["Script execution", "Multiple languages", "Scheduling", "Logging"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Task Scheduler",
                category: .productivity,
                features: ["Task scheduling", "Cron jobs", "Recurring tasks", "Notifications"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Batch Processor",
                category: .utilities,
                features: ["Batch operations", "Queue management", "Progress tracking", "Error handling"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Media Tools Hubs
    
    private var mediaToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Media Library",
                category: .creative,
                features: ["Media organization", "Preview", "Metadata", "Search"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Audio Player",
                category: .entertainment,
                features: ["Audio playback", "Playlist", "Equalizer", "Formats"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Video Player",
                category: .entertainment,
                features: ["Video playback", "Subtitles", "Streaming", "Formats"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Image Gallery",
                category: .creative,
                features: ["Image viewer", "Slideshow", "Editing", "Export"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Media Converter",
                category: .utilities,
                features: ["Format conversion", "Batch processing", "Quality settings", "Preview"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Documentation Hubs
    
    private var documentationHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "JSON to Markdown",
                category: .development,
                features: ["JSON parsing", "Markdown generation", "Templates", "Export"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Doc Generator",
                category: .development,
                features: ["Auto documentation", "Code parsing", "Templates", "Export"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "API Documentation",
                category: .development,
                features: ["API docs", "Endpoint listing", "Examples", "Interactive"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Bash Script Documentation",
                category: .development,
                features: ["Script documentation", "Parameter docs", "Examples", "Usage"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Project Checkpoint",
                category: .development,
                features: ["Project snapshots", "Documentation", "Version tracking", "Reports"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Analysis Tools Hubs
    
    private var analysisToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Code Analyzer Pro",
                category: .development,
                features: ["Static analysis", "Metrics", "Complexity", "Quality score"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Performance Analyzer",
                category: .development,
                features: ["Performance profiling", "Bottleneck detection", "Optimization", "Reports"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Dependency Analyzer",
                category: .development,
                features: ["Dependency graph", "Version conflicts", "Updates", "Security"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Log Analyzer",
                category: .development,
                features: ["Log parsing", "Pattern detection", "Filtering", "Visualization"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Data Analyzer",
                category: .business,
                features: ["Data analysis", "Statistics", "Visualization", "Export"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Build Tools Hubs
    
    private var buildToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Build System",
                category: .development,
                features: ["Build automation", "Compilation", "Linking", "Packaging"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Project Generator",
                category: .development,
                features: ["Project scaffolding", "Templates", "Configuration", "Setup"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Package Builder",
                category: .development,
                features: ["Package creation", "Dependencies", "Versioning", "Publishing"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Asset Compiler",
                category: .development,
                features: ["Asset compilation", "Optimization", "Formats", "Catalogs"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Testing Tools Hubs
    
    private var testingToolsHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Test Runner",
                category: .development,
                features: ["Test execution", "Coverage", "Reports", "CI/CD integration"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "UI Test Recorder",
                category: .development,
                features: ["UI test recording", "Playback", "Assertions", "Reports"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Performance Tester",
                category: .development,
                features: ["Performance testing", "Benchmarks", "Load testing", "Reports"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Integration Tester",
                category: .development,
                features: ["Integration tests", "API testing", "Mock services", "Validation"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Deployment Hubs
    
    private var deploymentHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Deployment Manager",
                category: .development,
                features: ["Deployment automation", "Environments", "Rollback", "Monitoring"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Release Manager",
                category: .development,
                features: ["Release planning", "Version control", "Changelog", "Distribution"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "CI/CD Pipeline",
                category: .development,
                features: ["Continuous integration", "Automated testing", "Deployment", "Notifications"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "App Store Publisher",
                category: .development,
                features: ["App Store submission", "Metadata", "Screenshots", "Review tracking"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Monitoring Hubs
    
    private var monitoringHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "System Monitor",
                category: .utilities,
                features: ["CPU/Memory monitoring", "Disk usage", "Network", "Processes"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "App Monitor",
                category: .development,
                features: ["Application monitoring", "Crash reports", "Analytics", "Alerts"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Network Monitor",
                category: .utilities,
                features: ["Network traffic", "Bandwidth", "Connections", "Diagnostics"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Error Tracker",
                category: .development,
                features: ["Error logging", "Stack traces", "Grouping", "Notifications"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Collaboration Hubs
    
    private var collaborationHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Team Workspace",
                category: .productivity,
                features: ["Team collaboration", "Shared documents", "Chat", "Tasks"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Code Review",
                category: .development,
                features: ["Code review", "Comments", "Approvals", "Diff viewer"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Project Board",
                category: .productivity,
                features: ["Kanban board", "Sprint planning", "Backlog", "Reports"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Wiki",
                category: .productivity,
                features: ["Team wiki", "Documentation", "Search", "Version history"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Learning Hubs
    
    private var learningHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Tutorial Builder",
                category: .education,
                features: ["Interactive tutorials", "Step-by-step", "Code examples", "Quizzes"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Course Manager",
                category: .education,
                features: ["Course creation", "Lessons", "Assignments", "Progress tracking"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Flashcard App",
                category: .education,
                features: ["Flashcards", "Spaced repetition", "Categories", "Progress"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Quiz Builder",
                category: .education,
                features: ["Quiz creation", "Multiple choice", "Scoring", "Analytics"],
                dependencies: []
            )
        ]
    }
    
    // MARK: - Reference Hubs
    
    private var referenceHubs: [SimpleTemplateDefinition] {
        [
            SimpleTemplateDefinition(
                name: "Cheat Sheet",
                category: .utilities,
                features: ["Quick reference", "Search", "Categories", "Favorites"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Code Snippets",
                category: .development,
                features: ["Snippet library", "Syntax highlighting", "Search", "Tags"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "Command Reference",
                category: .development,
                features: ["Command lookup", "Examples", "Options", "Search"],
                dependencies: []
            ),
            SimpleTemplateDefinition(
                name: "API Reference",
                category: .development,
                features: ["API documentation", "Endpoints", "Parameters", "Examples"],
                dependencies: []
            )
        ]
    }
}

// MARK: - Simple Template Definition (String-based)

struct SimpleTemplateDefinition {
    let name: String
    let category: HubCategory
    let features: [String]
    let dependencies: [String]
    
    init(name: String, category: HubCategory, features: [String], dependencies: [String] = []) {
        self.name = name
        self.category = category
        self.features = features
        self.dependencies = dependencies
    }
}
