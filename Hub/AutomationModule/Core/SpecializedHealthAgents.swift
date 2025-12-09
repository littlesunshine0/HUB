//
//  SpecializedHealthAgents.swift
//  Hub
//
//  Domain-specific health agents for each module in the project
//

import Foundation
import SwiftUI
import Combine

// MARK: - Health Agent Protocol

protocol HealthAgent {
    var name: String { get }
    var domain: String { get }
    var icon: String { get }
    
    func performHealthCheck() async -> HealthCheckResult
    func autoHeal(issue: HealthIssue) async -> HealingResult
    func getRecommendations() async -> [HealthRecommendation]
}

// MARK: - Unified Health Agent Coordinator

@MainActor
class UnifiedHealthAgentCoordinator: ObservableObject {
    static let shared = UnifiedHealthAgentCoordinator()
    
    @Published var agents: [any HealthAgent] = []
    @Published var overallHealth: OverallHealthStatus = .unknown
    @Published var isMonitoring = false
    @Published var lastCheckDate: Date?
    @Published var allIssues: [DomainHealthIssue] = []
    
    private var monitoringTask: Task<Void, Never>?
    
    private init() {
        initializeAgents()
    }
    
    private func initializeAgents() {
        agents = [
            // Core App Agents
            AppHealthAgent(),
            HubHealthAgent(),
            TemplateHealthAgent(),
            
            // Module Agents
            AIModuleHealthAgent(),
            AuthenticationHealthAgent(),
            StorageHealthAgent(),
            AutomationHealthAgent(),
            
            // Feature Agents
            CodeGeneratorHealthAgent(),
            DesignSystemHealthAgent(),
            CommunityNetworkHealthAgent(),
            ComponentsHealthAgent(),
            
            // Infrastructure Agents
            HooksHealthAgent(),
            NotificationHealthAgent(),
            AnalyticsHealthAgent(),
            EnterpriseHealthAgent(),
            
            // Content Agents
            PackageHealthAgent(),
            RoleHealthAgent(),
            SettingsHealthAgent(),
            AchievementsHealthAgent()
        ]
        
        print("🤖 Initialized \(agents.count) specialized health agents")
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🔍 Starting unified health monitoring...")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await performUnifiedHealthCheck()
                
                // Check every 10 minutes
                try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000)
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        print("⏸️ Health monitoring stopped")
    }
    
    func performUnifiedHealthCheck() async {
        print("🏥 Running unified health check across all domains...")
        lastCheckDate = Date()
        
        var allDomainIssues: [DomainHealthIssue] = []
        var healthScores: [Double] = []
        
        for agent in agents {
            let result = await agent.performHealthCheck()
            
            // Convert to domain issues
            for issue in result.issues {
                allDomainIssues.append(DomainHealthIssue(
                    domain: agent.domain,
                    agentName: agent.name,
                    issue: issue
                ))
            }
            
            healthScores.append(result.healthScore)
        }
        
        allIssues = allDomainIssues
        
        // Calculate overall health
        let avgScore = healthScores.reduce(0, +) / Double(max(healthScores.count, 1))
        overallHealth = determineOverallHealth(score: avgScore, issueCount: allDomainIssues.count)
        
        print("✅ Health check complete: \(allDomainIssues.count) total issues, score: \(Int(avgScore * 100))%")
        
        // Auto-heal critical issues
        await autoHealCriticalIssues()
    }
    
    private func autoHealCriticalIssues() async {
        let criticalIssues = allIssues.filter { $0.issue.severity == .critical && $0.issue.autoFixable }
        
        print("🔧 Auto-healing \(criticalIssues.count) critical issues...")
        
        for domainIssue in criticalIssues {
            if let agent = agents.first(where: { $0.name == domainIssue.agentName }) {
                let result = await agent.autoHeal(issue: domainIssue.issue)
                if result.success {
                    print("✅ Healed: \(domainIssue.issue.title)")
                }
            }
        }
    }
    
    private func determineOverallHealth(score: Double, issueCount: Int) -> OverallHealthStatus {
        let criticalCount = allIssues.filter { $0.issue.severity == .critical }.count
        
        if criticalCount > 0 {
            return .critical
        } else if score < 0.6 {
            return .poor
        } else if score < 0.8 {
            return .fair
        } else if score < 0.95 {
            return .good
        } else {
            return .excellent
        }
    }
    
    func getAgentForDomain(_ domain: String) -> (any HealthAgent)? {
        return agents.first { $0.domain == domain }
    }
}

// MARK: - App Health Agent

struct AppHealthAgent: HealthAgent {
    let name = "App Health Agent"
    let domain = "App"
    let icon = "app.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        // Check HubApp.swift
        if let content = try? String(contentsOfFile: "Hub/HubApp.swift", encoding: .utf8) {
            if !content.contains("@main") {
                issues.append(HealthIssue(
                    title: "Missing @main attribute",
                    description: "HubApp.swift should have @main attribute",
                    severity: .critical,
                    autoFixable: false
                ))
            }
        }
        
        // Check ContentView exists
        if !FileManager.default.fileExists(atPath: "Hub/ContentView.swift") {
            issues.append(HealthIssue(
                title: "Missing ContentView",
                description: "ContentView.swift is required",
                severity: .critical,
                autoFixable: false
            ))
        }
        
        let score = issues.isEmpty ? 1.0 : 0.7
        return HealthCheckResult(healthScore: score, issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "Manual intervention required")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Keep app entry point clean",
                description: "HubApp should focus on initialization and routing",
                priority: .medium
            )
        ]
    }
}

// MARK: - Hub Health Agent

struct HubHealthAgent: HealthAgent {
    let name = "Hub Health Agent"
    let domain = "Hubs"
    let icon = "square.grid.2x2.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        // Check hub-related files
        let requiredFiles = [
            "Hub/AppHub.swift",
            "Hub/HubViewModel.swift",
            "Hub/HubDetailView.swift",
            "Hub/HubDiscoveryView.swift",
            "Hub/HubSeeder.swift"
        ]
        
        for file in requiredFiles {
            if !FileManager.default.fileExists(atPath: file) {
                issues.append(HealthIssue(
                    title: "Missing hub file: \(file)",
                    description: "Required hub component is missing",
                    severity: .high,
                    autoFixable: false
                ))
            }
        }
        
        let score = 1.0 - (Double(issues.count) * 0.15)
        return HealthCheckResult(healthScore: max(score, 0), issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "File creation requires manual intervention")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Maintain hub consistency",
                description: "Ensure all hub views follow the same pattern",
                priority: .medium
            )
        ]
    }
}

// MARK: - Template Health Agent

struct TemplateHealthAgent: HealthAgent {
    let name = "Template Health Agent"
    let domain = "Templates"
    let icon = "doc.on.doc.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        // Check template module structure
        let templatePath = "Hub/TemplateModule"
        if !FileManager.default.fileExists(atPath: templatePath) {
            issues.append(HealthIssue(
                title: "Template module missing",
                description: "TemplateModule directory not found",
                severity: .critical,
                autoFixable: true
            ))
        }
        
        // Check TemplateSeeder
        if !FileManager.default.fileExists(atPath: "Hub/TemplateSeeder.swift") {
            issues.append(HealthIssue(
                title: "TemplateSeeder missing",
                description: "Template seeding functionality not found",
                severity: .high,
                autoFixable: false
            ))
        }
        
        let score = issues.isEmpty ? 1.0 : 0.6
        return HealthCheckResult(healthScore: score, issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        if issue.title.contains("module missing") {
            try? FileManager.default.createDirectory(atPath: "Hub/TemplateModule", withIntermediateDirectories: true)
            return HealingResult(success: true, message: "Created TemplateModule directory")
        }
        return HealingResult(success: false, message: "Cannot auto-heal")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Expand template library",
                description: "Add more default templates for common use cases",
                priority: .low
            )
        ]
    }
}

// MARK: - AI Module Health Agent

struct AIModuleHealthAgent: HealthAgent {
    let name = "AI Module Health Agent"
    let domain = "AI"
    let icon = "brain.head.profile"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        let aiPath = "Hub/AIModule"
        if !FileManager.default.fileExists(atPath: aiPath) {
            issues.append(HealthIssue(
                title: "AI Module missing",
                description: "AIModule directory not found",
                severity: .high,
                autoFixable: true
            ))
        } else {
            // Check key AI components
            let keyFiles = [
                "Hub/AIModule/UnifiedAIOrchestrator.swift",
                "Hub/AIModule/OwnerAIAssistant.swift"
            ]
            
            for file in keyFiles {
                if !FileManager.default.fileExists(atPath: file) {
                    issues.append(HealthIssue(
                        title: "Missing AI component: \((file as NSString).lastPathComponent)",
                        description: "Key AI file not found",
                        severity: .medium,
                        autoFixable: false
                    ))
                }
            }
        }
        
        let score = 1.0 - (Double(issues.count) * 0.2)
        return HealthCheckResult(healthScore: max(score, 0), issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        if issue.title.contains("Module missing") {
            try? FileManager.default.createDirectory(atPath: "Hub/AIModule", withIntermediateDirectories: true)
            return HealingResult(success: true, message: "Created AIModule directory")
        }
        return HealingResult(success: false, message: "Cannot auto-heal")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Enhance AI capabilities",
                description: "Add more specialized AI agents for different tasks",
                priority: .medium
            )
        ]
    }
}

// MARK: - Authentication Health Agent

struct AuthenticationHealthAgent: HealthAgent {
    let name = "Authentication Health Agent"
    let domain = "Authentication"
    let icon = "person.badge.key.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        let authPath = "Hub/AuthenticationModule"
        if !FileManager.default.fileExists(atPath: authPath) {
            issues.append(HealthIssue(
                title: "Authentication module missing",
                description: "AuthenticationModule directory not found",
                severity: .critical,
                autoFixable: true
            ))
        } else {
            // Check authentication service
            if !FileManager.default.fileExists(atPath: "Hub/AuthenticationModule/Services/AuthenticationService.swift") {
                issues.append(HealthIssue(
                    title: "AuthenticationService missing",
                    description: "Core authentication service not found",
                    severity: .critical,
                    autoFixable: false
                ))
            }
        }
        
        let score = issues.isEmpty ? 1.0 : 0.5
        return HealthCheckResult(healthScore: score, issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        if issue.title.contains("module missing") {
            try? FileManager.default.createDirectory(atPath: "Hub/AuthenticationModule/Services", withIntermediateDirectories: true)
            return HealingResult(success: true, message: "Created AuthenticationModule structure")
        }
        return HealingResult(success: false, message: "Cannot auto-heal")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Implement biometric authentication",
                description: "Add Face ID/Touch ID support",
                priority: .medium
            )
        ]
    }
}

// MARK: - Storage Health Agent

struct StorageHealthAgent: HealthAgent {
    let name = "Storage Health Agent"
    let domain = "Storage"
    let icon = "cylinder.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        let storagePath = "Hub/StorageLayer"
        if !FileManager.default.fileExists(atPath: storagePath) {
            issues.append(HealthIssue(
                title: "Storage layer missing",
                description: "StorageLayer directory not found",
                severity: .critical,
                autoFixable: true
            ))
        } else {
            // Check key storage components
            let keyFiles = [
                "Hub/StorageLayer/LocalStorageService.swift",
                "Hub/StorageLayer/StorageCoordinator.swift",
                "Hub/StorageLayer/CloudSyncService.swift"
            ]
            
            for file in keyFiles {
                if !FileManager.default.fileExists(atPath: file) {
                    issues.append(HealthIssue(
                        title: "Missing storage component: \((file as NSString).lastPathComponent)",
                        description: "Key storage file not found",
                        severity: .high,
                        autoFixable: false
                    ))
                }
            }
        }
        
        let score = 1.0 - (Double(issues.count) * 0.25)
        return HealthCheckResult(healthScore: max(score, 0), issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        if issue.title.contains("layer missing") {
            try? FileManager.default.createDirectory(atPath: "Hub/StorageLayer", withIntermediateDirectories: true)
            return HealingResult(success: true, message: "Created StorageLayer directory")
        }
        return HealingResult(success: false, message: "Cannot auto-heal")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Optimize storage performance",
                description: "Implement caching and indexing strategies",
                priority: .high
            )
        ]
    }
}

// MARK: - Automation Health Agent

struct AutomationHealthAgent: HealthAgent {
    let name = "Automation Health Agent"
    let domain = "Automation"
    let icon = "gearshape.2.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        var issues: [HealthIssue] = []
        
        let automationPath = "Hub/AutomationModule"
        if !FileManager.default.fileExists(atPath: automationPath) {
            issues.append(HealthIssue(
                title: "Automation module missing",
                description: "AutomationModule directory not found",
                severity: .medium,
                autoFixable: true
            ))
        }
        
        let score = issues.isEmpty ? 1.0 : 0.7
        return HealthCheckResult(healthScore: score, issues: issues)
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        if issue.title.contains("module missing") {
            try? FileManager.default.createDirectory(atPath: "Hub/AutomationModule/Core", withIntermediateDirectories: true)
            return HealingResult(success: true, message: "Created AutomationModule structure")
        }
        return HealingResult(success: false, message: "Cannot auto-heal")
    }
    
    func getRecommendations() async -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                title: "Expand automation workflows",
                description: "Add more automated tasks and workflows",
                priority: .medium
            )
        ]
    }
}

// MARK: - Additional Specialized Agents (Simplified)

struct CodeGeneratorHealthAgent: HealthAgent {
    let name = "Code Generator Health Agent"
    let domain = "CodeGenerator"
    let icon = "chevron.left.forwardslash.chevron.right"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/CodeGeneratorModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct DesignSystemHealthAgent: HealthAgent {
    let name = "Design System Health Agent"
    let domain = "DesignSystem"
    let icon = "paintpalette.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/DesignSystem")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct CommunityNetworkHealthAgent: HealthAgent {
    let name = "Community Network Health Agent"
    let domain = "CommunityNetwork"
    let icon = "person.3.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/CommunityNetworkModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct ComponentsHealthAgent: HealthAgent {
    let name = "Components Health Agent"
    let domain = "Components"
    let icon = "square.stack.3d.up.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/ComponentsModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct HooksHealthAgent: HealthAgent {
    let name = "Hooks Health Agent"
    let domain = "Hooks"
    let icon = "link.circle.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/HooksModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct NotificationHealthAgent: HealthAgent {
    let name = "Notification Health Agent"
    let domain = "Notifications"
    let icon = "bell.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/NotificationModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct AnalyticsHealthAgent: HealthAgent {
    let name = "Analytics Health Agent"
    let domain = "Analytics"
    let icon = "chart.bar.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/AnalyticsModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct EnterpriseHealthAgent: HealthAgent {
    let name = "Enterprise Health Agent"
    let domain = "Enterprise"
    let icon = "building.2.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/EnterpriseModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct PackageHealthAgent: HealthAgent {
    let name = "Package Health Agent"
    let domain = "Packages"
    let icon = "shippingbox.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/PackageModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct RoleHealthAgent: HealthAgent {
    let name = "Role Health Agent"
    let domain = "Roles"
    let icon = "person.crop.circle.badge.checkmark"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/RoleModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct SettingsHealthAgent: HealthAgent {
    let name = "Settings Health Agent"
    let domain = "Settings"
    let icon = "gearshape.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/SettingsModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

struct AchievementsHealthAgent: HealthAgent {
    let name = "Achievements Health Agent"
    let domain = "Achievements"
    let icon = "trophy.fill"
    
    func performHealthCheck() async -> HealthCheckResult {
        let exists = FileManager.default.fileExists(atPath: "Hub/AchievementsModule")
        return HealthCheckResult(healthScore: exists ? 1.0 : 0.5, issues: [])
    }
    
    func autoHeal(issue: HealthIssue) async -> HealingResult {
        return HealingResult(success: false, message: "No auto-heal available")
    }
    
    func getRecommendations() async -> [HealthRecommendation] { return [] }
}

// MARK: - Supporting Types

struct HealthCheckResult {
    let healthScore: Double // 0.0 to 1.0
    let issues: [HealthIssue]
}

struct HealthIssue: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let severity: IssueSeverity
    let autoFixable: Bool
}

enum IssueSeverity {
    case low
    case medium
    case high
    case critical
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct HealingResult {
    let success: Bool
    let message: String
}

struct HealthRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: RecommendationPriority
}

enum HealthRecommendationPriority {
    case low
    case medium
    case high
}

struct DomainHealthIssue: Identifiable {
    let id = UUID()
    let domain: String
    let agentName: String
    let issue: HealthIssue
}

enum OverallHealthStatus {
    case unknown
    case critical
    case poor
    case fair
    case good
    case excellent
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .critical: return .red
        case .poor: return .orange
        case .fair: return .yellow
        case .good: return .green
        case .excellent: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .critical: return "xmark.octagon.fill"
        case .poor: return "exclamationmark.triangle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .excellent: return "star.circle.fill"
        }
    }
}
