//
//  OwnerAIAssistant.swift
//  Hub
//
//  AI Assistant specialized for owner role creation and development tasks
//  Implements Requirements 9.1, 9.2, 9.3, 9.4, 9.5
//

import Foundation
import Combine
import SwiftUI

/// AI Assistant that provides creation-focused assistance for owners
/// Integrates with existing AIModule and provides Hub structure suggestions,
/// template organization recommendations, refactoring suggestions, and
/// marketplace presentation enhancements
@MainActor
public class OwnerAIAssistant: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var suggestions: [CreationSuggestion] = []
    @Published public var activeContext: CreationContext?
    @Published public var isProcessing: Bool = false
    @Published public var lastUpdate: Date = Date()
    
    // MARK: - Dependencies
    
    private let agentSystem: RoleBasedAgentSystem
    private let integrationHub: AgentIntegrationHub
    
    // MARK: - Initialization
    
    public init(
        agentSystem: RoleBasedAgentSystem,
        integrationHub: AgentIntegrationHub
    ) {
        self.agentSystem = agentSystem
        self.integrationHub = integrationHub
    }
    
    public convenience init() {
        self.init(agentSystem: .shared, integrationHub: AgentIntegrationHub())
    }
    
    // MARK: - Hub Structure Suggestions (Requirement 9.2)
    
    /// Suggest optimal Hub structure based on package analysis
    /// - Parameter analysis: Package analysis result
    /// - Returns: Hub structure suggestion with recommendations
    public func suggestHubStructure(for analysis: PackageAnalyzer.Analysis) async -> HubStructureSuggestion {
        isProcessing = true
        defer { isProcessing = false }
        
        // Analyze package characteristics
        let fileCount = analysis.swiftFiles.count
        let hasMultipleModules = analysis.detectedDependencies.count > 3
        let complexity = determineComplexity(analysis)
        
        // Get AI agent recommendations
        let architectAgent = agentSystem.agents.first { $0.role == .architect }
        let developerAgent = agentSystem.agents.first { $0.role == .developer }
        let designerAgent = agentSystem.agents.first { $0.role == .designer }
        
        var recommendations: [String] = []
        var structureComponents: [StructureComponent] = []
        
        // Architect agent: Analyze and recommend structure
        if fileCount > 20 {
            let recommendation = architectAgent != nil 
                ? "[\(architectAgent!.name)] Consider splitting into multiple Hubs by feature area for better scalability"
                : "Consider splitting into multiple Hubs by feature area"
            recommendations.append(recommendation)
            
            structureComponents.append(StructureComponent(
                name: "Modular Architecture",
                description: "Split large codebase into feature-based Hubs",
                rationale: "With \(fileCount) files, modular organization improves maintainability",
                priority: SuggestionPriority.high
            ))
        }
        
        // Developer agent: Analyze dependencies
        if hasMultipleModules {
            let recommendation = developerAgent != nil
                ? "[\(developerAgent!.name)] Create separate Hubs for each major dependency to reduce coupling"
                : "Create separate Hubs for each major dependency"
            recommendations.append(recommendation)
            
            structureComponents.append(StructureComponent(
                name: "Dependency Isolation",
                description: "Isolate dependencies in dedicated Hubs",
                rationale: "Multiple dependencies benefit from isolated Hub structure",
                priority: SuggestionPriority.medium
            ))
        }
        
        // Architect agent: Add layer-based organization recommendation
        if let architect = architectAgent {
            recommendations.append("[\(architect.name)] Implement clean architecture with clear layer separation")
        }
        structureComponents.append(StructureComponent(
            name: "Layer-Based Organization",
            description: "Organize templates into Data, Domain, and Presentation layers",
            rationale: "Clean architecture improves testability and maintainability",
            priority: SuggestionPriority.high
        ))
        
        // Developer agent: Add shared services recommendation
        if let developer = developerAgent {
            recommendations.append("[\(developer.name)] Extract common functionality into shared services to reduce duplication")
        }
        structureComponents.append(StructureComponent(
            name: "Shared Services Layer",
            description: "Create centralized services for authentication, networking, and storage",
            rationale: "Shared services reduce code duplication and improve consistency",
            priority: SuggestionPriority.high
        ))
        
        // Designer agent: Add UI consistency recommendation
        if let designer = designerAgent {
            recommendations.append("[\(designer.name)] Establish a design system for consistent UI across all Hubs")
            structureComponents.append(StructureComponent(
                name: "Design System",
                description: "Create reusable UI components and design tokens",
                rationale: "Consistent design improves user experience and development speed",
                priority: SuggestionPriority.high
            ))
        }
        
        // Determine optimal Hub count
        let optimalHubCount = calculateOptimalHubCount(analysis)
        
        // Get a fallback agent if architect not found
        let suggestingAgent = architectAgent ?? agentSystem.agents.first ?? AIAgent(
            id: UUID(),
            name: "System Architect",
            role: .architect,
            specialty: "System Architecture & Design",
            personality: .analytical,
            expertise: ["architecture", "design patterns", "scalability"]
        )
        
        return HubStructureSuggestion(
            packageName: analysis.name,
            recommendedHubCount: optimalHubCount,
            structureComponents: structureComponents,
            recommendations: recommendations,
            complexity: complexity,
            estimatedEffort: estimateEffort(for: analysis),
            suggestedBy: suggestingAgent
        )
    }
    
    // MARK: - Template Organization Recommendations (Requirement 9.3)
    
    /// Recommend how to organize extracted templates
    /// - Parameter templates: Array of extracted templates
    /// - Returns: Organization plan with grouping and structure
    public func recommendTemplateOrganization(_ templates: [ExtractedTemplate]) async -> OrganizationPlan {
        isProcessing = true
        defer { isProcessing = false }
        
        // Group templates by category
        let groupedByCategory = Dictionary(grouping: templates) { $0.category }
        
        // Analyze template relationships
        let relationships = analyzeTemplateRelationships(templates)
        
        // Create organization groups
        var groups: [TemplateGroup] = []
        
        for (category, categoryTemplates) in groupedByCategory {
            let group = TemplateGroup(
                name: "\(category.rawValue) Templates",
                category: category,
                templates: categoryTemplates.map { $0.name },
                description: generateGroupDescription(for: category, count: categoryTemplates.count),
                suggestedOrder: determineSuggestedOrder(categoryTemplates)
            )
            groups.append(group)
        }
        
        // Add recommendations
        var recommendations: [String] = []
        
        if templates.count > 10 {
            recommendations.append("Consider creating sub-groups within categories for better organization")
        }
        
        if relationships.count > 5 {
            recommendations.append("Document template relationships to help future developers understand connections")
        }
        
        // Check for naming consistency
        let namingIssues = checkNamingConsistency(templates)
        if !namingIssues.isEmpty {
            recommendations.append("Standardize template naming: \(namingIssues.joined(separator: ", "))")
        }
        
        // Suggest folder structure
        let folderStructure = generateFolderStructure(groups: groups)
        
        return OrganizationPlan(
            groups: groups,
            relationships: relationships,
            recommendations: recommendations,
            folderStructure: folderStructure,
            namingConventions: generateNamingConventions()
        )
    }
    
    // MARK: - Refactoring Suggestions (Requirement 9.4)
    
    /// Provide refactoring suggestions for code
    /// - Parameter code: Source code to analyze
    /// - Returns: Array of refactoring suggestions
    public func provideRefactoringSuggestions(for code: String) async -> [RefactoringSuggestion] {
        isProcessing = true
        defer { isProcessing = false }
        
        var suggestions: [RefactoringSuggestion] = []
        
        // Get AI agent input
        let developerAgent = agentSystem.agents.first { $0.role == .developer }
        let architectAgent = agentSystem.agents.first { $0.role == .architect }
        
        // Developer agent: Check for long functions
        if let longFunctionSuggestion = detectLongFunctions(in: code) {
            var suggestion = longFunctionSuggestion
            if let developer = developerAgent {
                suggestion.description = "[\(developer.name)] " + suggestion.description
            }
            suggestions.append(suggestion)
        }
        
        // Developer agent: Check for code duplication
        if let duplicationSuggestion = detectCodeDuplication(in: code) {
            var suggestion = duplicationSuggestion
            if let developer = developerAgent {
                suggestion.description = "[\(developer.name)] " + suggestion.description
            }
            suggestions.append(suggestion)
        }
        
        // Developer agent: Check for hardcoded values
        if let hardcodedValuesSuggestion = detectHardcodedValues(in: code) {
            var suggestion = hardcodedValuesSuggestion
            if let developer = developerAgent {
                suggestion.description = "[\(developer.name)] " + suggestion.description
            }
            suggestions.append(suggestion)
        }
        
        // Developer agent: Check for missing error handling
        if let errorHandlingSuggestion = detectMissingErrorHandling(in: code) {
            var suggestion = errorHandlingSuggestion
            if let developer = developerAgent {
                suggestion.description = "[\(developer.name)] " + suggestion.description
            }
            suggestions.append(suggestion)
        }
        
        // Architect agent: Check for design pattern opportunities
        if let designPatternSuggestion = suggestDesignPatterns(for: code) {
            var suggestion = designPatternSuggestion
            if let architect = architectAgent {
                suggestion.description = "[\(architect.name)] " + suggestion.description
            }
            suggestions.append(suggestion)
        }
        
        // Check for SwiftUI best practices
        if code.contains("View") {
            if let swiftUISuggestion = suggestSwiftUIImprovements(for: code) {
                suggestions.append(swiftUISuggestion)
            }
        }
        
        // Check for async/await opportunities
        if code.contains("completion:") || code.contains("completionHandler") {
            let suggestingAgent = developerAgent ?? agentSystem.agents.first ?? AIAgent(
                id: UUID(),
                name: "System Developer",
                role: .developer,
                specialty: "Swift Development",
                personality: .analytical,
                expertise: ["swift", "async/await", "modernization"]
            )
            
            suggestions.append(RefactoringSuggestion(
                title: "Modernize to async/await",
                description: "Replace completion handlers with modern async/await syntax",
                codeSnippet: generateAsyncAwaitExample(),
                impact: ImpactLevel.medium,
                effort: EffortLevel.medium,
                category: .modernization,
                suggestedBy: suggestingAgent
            ))
        }
        
        // Sort by priority (high impact, low effort first)
        suggestions.sort { lhs, rhs in
            if lhs.impact == rhs.impact {
                return lhs.effort.rawValue < rhs.effort.rawValue
            }
            return lhs.impact.rawValue > rhs.impact.rawValue
        }
        
        return suggestions
    }
    
    // MARK: - Marketplace Presentation Enhancements (Requirement 9.5)
    
    /// Suggest improvements to marketplace presentation
    /// - Parameter template: Template to enhance
    /// - Returns: Presentation enhancements
    public func enhanceMarketplacePresentation(_ template: TemplateModel) async -> PresentationEnhancements {
        isProcessing = true
        defer { isProcessing = false }
        
        // Get AI agent input
        let designerAgent = agentSystem.agents.first { $0.role == .designer }
        let pmAgent = agentSystem.agents.first { $0.role == .productManager }
        
        var enhancements: [Enhancement] = []
        
        // PM agent: Analyze description quality
        if template.templateDescription.count < 50 {
            let rationale = pmAgent != nil
                ? "[\(pmAgent!.name)] Detailed descriptions improve discoverability and user understanding"
                : "Detailed descriptions improve discoverability and user understanding"
            
            enhancements.append(Enhancement(
                type: Enhancement.EnhancementType.description,
                current: template.templateDescription,
                suggested: generateEnhancedDescription(for: template),
                rationale: rationale,
                impact: ImpactLevel.high
            ))
        }
        
        // Designer agent: Analyze icon selection
        if template.icon == "doc" || template.icon.isEmpty {
            let rationale = designerAgent != nil
                ? "[\(designerAgent!.name)] Distinctive icons improve visual recognition in marketplace"
                : "Distinctive icons improve visual recognition in marketplace"
            
            enhancements.append(Enhancement(
                type: Enhancement.EnhancementType.icon,
                current: template.icon,
                suggested: suggestBetterIcon(for: template),
                rationale: rationale,
                impact: ImpactLevel.medium
            ))
        }
        
        // PM agent: Analyze tags
        if template.tags.count < 3 {
            let rationale = pmAgent != nil
                ? "[\(pmAgent!.name)] More tags improve searchability and categorization"
                : "More tags improve searchability and categorization"
            
            enhancements.append(Enhancement(
                type: Enhancement.EnhancementType.tags,
                current: template.tags.joined(separator: ", "),
                suggested: generateSuggestedTags(for: template).joined(separator: ", "),
                rationale: rationale,
                impact: ImpactLevel.high
            ))
        }
        
        // PM agent: Analyze features list
        if template.features.isEmpty {
            let rationale = pmAgent != nil
                ? "[\(pmAgent!.name)] Feature highlights help users understand template capabilities"
                : "Feature highlights help users understand template capabilities"
            
            enhancements.append(Enhancement(
                type: Enhancement.EnhancementType.features,
                current: "None listed",
                suggested: generateFeaturesList(for: template).joined(separator: ", "),
                rationale: rationale,
                impact: ImpactLevel.high
            ))
        }
        
        // Designer agent: Suggest preview images
        let previewSuggestions = suggestPreviewImages(for: template)
        
        // PM agent: Suggest category optimization
        let categorySuggestion = optimizeCategory(for: template)
        
        // PM + Designer: Generate marketing copy
        let marketingCopy = generateMarketingCopy(for: template)
        
        let suggestingAgent = designerAgent ?? pmAgent ?? agentSystem.agents.first ?? AIAgent(
            id: UUID(),
            name: "System Designer",
            role: .designer,
            specialty: "UI/UX Design",
            personality: .creative,
            expertise: ["design", "marketplace", "presentation"]
        )
        
        return PresentationEnhancements(
            template: template,
            enhancements: enhancements,
            previewSuggestions: previewSuggestions,
            categorySuggestion: categorySuggestion,
            marketingCopy: marketingCopy,
            estimatedImpact: calculatePresentationImpact(enhancements),
            suggestedBy: suggestingAgent
        )
    }
    
    // MARK: - Context Management
    
    /// Set the active creation context
    /// - Parameter context: Creation context to set
    public func setContext(_ context: CreationContext) {
        activeContext = context
        lastUpdate = Date()
        
        // Generate contextual suggestions
        Task {
            await generateContextualSuggestions(for: context)
        }
    }
    
    /// Clear the active context
    public func clearContext() {
        activeContext = nil
        suggestions.removeAll()
        lastUpdate = Date()
    }
    
    // MARK: - Private Helper Methods
    
    private func determineComplexity(_ analysis: PackageAnalyzer.Analysis) -> ComplexityLevel {
        let fileCount = analysis.swiftFiles.count
        let dependencyCount = analysis.detectedDependencies.count
        
        let score = fileCount + (dependencyCount * 5)
        
        if score < 10 {
            return .simple
        } else if score < 30 {
            return .moderate
        } else if score < 60 {
            return .complex
        } else {
            return .veryComplex
        }
    }
    
    private func calculateOptimalHubCount(_ analysis: PackageAnalyzer.Analysis) -> Int {
        let fileCount = analysis.swiftFiles.count
        
        // Rule of thumb: 1 Hub per 15-20 files
        if fileCount <= 15 {
            return 1
        } else if fileCount <= 40 {
            return 2
        } else if fileCount <= 70 {
            return 3
        } else {
            return max(3, fileCount / 20)
        }
    }
    
    private func estimateEffort(for analysis: PackageAnalyzer.Analysis) -> TimeInterval {
        let fileCount = analysis.swiftFiles.count
        let dependencyCount = analysis.detectedDependencies.count
        
        // Estimate: 5 minutes per file + 15 minutes per dependency
        let minutes = (fileCount * 5) + (dependencyCount * 15)
        return TimeInterval(minutes * 60)
    }
    
    private func analyzeTemplateRelationships(_ templates: [ExtractedTemplate]) -> [TemplateRelationship] {
        var relationships: [TemplateRelationship] = []
        
        for template in templates {
            // Check for navigation relationships
            for otherTemplate in templates where otherTemplate.name != template.name {
                if template.sourceCode.contains(otherTemplate.name) {
                    relationships.append(TemplateRelationship(
                        from: template.name,
                        to: otherTemplate.name,
                        type: TemplateRelationship.RelationshipType.navigation,
                        strength: TemplateRelationship.RelationshipStrength.strong
                    ))
                }
            }
            
            // Check for data dependencies
            if template.dependencies.count > 0 {
                for dependency in template.dependencies {
                    if let dependentTemplate = templates.first(where: { $0.name.contains(dependency) }) {
                        relationships.append(TemplateRelationship(
                            from: template.name,
                            to: dependentTemplate.name,
                            type: TemplateRelationship.RelationshipType.dataDependency,
                            strength: TemplateRelationship.RelationshipStrength.medium
                        ))
                    }
                }
            }
        }
        
        return relationships
    }
    
    private func generateGroupDescription(for category: HubCategory, count: Int) -> String {
        return "\(count) template\(count == 1 ? "" : "s") in the \(category.rawValue) category"
    }
    
    private func determineSuggestedOrder(_ templates: [ExtractedTemplate]) -> [String] {
        // Sort by complexity (simpler first) and dependencies
        return templates
            .sorted { lhs, rhs in
                lhs.dependencies.count < rhs.dependencies.count
            }
            .map { $0.name }
    }
    
    private func checkNamingConsistency(_ templates: [ExtractedTemplate]) -> [String] {
        var issues: [String] = []
        
        // Check for inconsistent casing
        let hasMixedCasing = templates.contains { $0.name.contains("_") } && 
                            templates.contains { $0.name.contains(where: { $0.isUppercase }) }
        if hasMixedCasing {
            issues.append("Mixed naming conventions (snake_case and PascalCase)")
        }
        
        // Check for generic names
        let genericNames = ["View", "Screen", "Page", "Component"]
        let hasGenericNames = templates.contains { template in
            genericNames.contains { template.name == $0 }
        }
        if hasGenericNames {
            issues.append("Generic template names should be more descriptive")
        }
        
        return issues
    }
    
    private func generateFolderStructure(groups: [TemplateGroup]) -> [String] {
        var structure: [String] = []
        
        structure.append("Hub/")
        for group in groups {
            structure.append("  \(group.name)/")
            for template in group.templates {
                structure.append("    \(template).swift")
            }
        }
        structure.append("  Shared/")
        structure.append("    Services/")
        structure.append("    Models/")
        structure.append("    Extensions/")
        
        return structure
    }
    
    private func generateNamingConventions() -> [String: String] {
        return [
            "Views": "Use descriptive names ending with 'View' (e.g., UserProfileView)",
            "ViewModels": "Match view name with 'ViewModel' suffix (e.g., UserProfileViewModel)",
            "Services": "Use 'Service' suffix (e.g., AuthenticationService)",
            "Models": "Use singular nouns (e.g., User, not Users)",
            "Extensions": "Use 'Type+Extension' format (e.g., String+Validation)"
        ]
    }
    
    // MARK: - Refactoring Detection Methods
    
    private func detectLongFunctions(in code: String) -> RefactoringSuggestion? {
        // Simple heuristic: count lines between func and closing brace
        let lines = code.components(separatedBy: .newlines)
        var inFunction = false
        var functionLineCount = 0
        var maxFunctionLines = 0
        
        for line in lines {
            if line.contains("func ") {
                inFunction = true
                functionLineCount = 0
            } else if inFunction && line.contains("}") {
                inFunction = false
                maxFunctionLines = max(maxFunctionLines, functionLineCount)
            } else if inFunction {
                functionLineCount += 1
            }
        }
        
        if maxFunctionLines > 50 {
            let suggestingAgent = agentSystem.agents.first { $0.role == .developer } ?? AIAgent(
                id: UUID(),
                name: "System Developer",
                role: .developer,
                specialty: "Code Quality",
                personality: .analytical,
                expertise: ["refactoring", "code quality", "best practices"]
            )
            
            return RefactoringSuggestion(
                title: "Extract Long Functions",
                description: "Functions with \(maxFunctionLines) lines should be broken into smaller, focused functions",
                codeSnippet: "// Extract logical sections into separate functions\n// Aim for functions under 30 lines",
                impact: .high,
                effort: .medium,
                category: .codeQuality,
                suggestedBy: suggestingAgent
            )
        }
        
        return nil
    }
    
    private func detectCodeDuplication(in code: String) -> RefactoringSuggestion? {
        // Simple check for repeated patterns
        let lines = code.components(separatedBy: .newlines)
        let uniqueLines = Set(lines)
        
        let duplicationRatio = 1.0 - (Double(uniqueLines.count) / Double(lines.count))
        
        if duplicationRatio > 0.3 {
            let suggestingAgent = agentSystem.agents.first { $0.role == .developer } ?? AIAgent(
                id: UUID(),
                name: "System Developer",
                role: .developer,
                specialty: "Code Quality",
                personality: .analytical,
                expertise: ["refactoring", "code quality", "DRY principles"]
            )
            
            return RefactoringSuggestion(
                title: "Reduce Code Duplication",
                description: "Approximately \(Int(duplicationRatio * 100))% code duplication detected",
                codeSnippet: "// Extract common code into reusable functions or protocols",
                impact: .high,
                effort: .high,
                category: .codeQuality,
                suggestedBy: suggestingAgent
            )
        }
        
        return nil
    }
    
    private func detectHardcodedValues(in code: String) -> RefactoringSuggestion? {
        // Check for magic numbers and hardcoded strings
        let hasHardcodedNumbers = code.range(of: #"\d{2,}"#, options: .regularExpression) != nil
        let hasHardcodedStrings = code.contains("\"http") || code.contains("\"api")
        
        if hasHardcodedNumbers || hasHardcodedStrings {
            let suggestingAgent = agentSystem.agents.first { $0.role == .developer } ?? AIAgent(
                id: UUID(),
                name: "System Developer",
                role: .developer,
                specialty: "Code Maintainability",
                personality: .analytical,
                expertise: ["maintainability", "configuration", "constants"]
            )
            
            return RefactoringSuggestion(
                title: "Extract Hardcoded Values",
                description: "Move hardcoded values to constants or configuration",
                codeSnippet: """
                // Create a Constants file:
                enum Constants {
                    static let apiBaseURL = "https://api.example.com"
                    static let maxRetries = 3
                }
                """,
                impact: .medium,
                effort: .low,
                category: .maintainability,
                suggestedBy: suggestingAgent
            )
        }
        
        return nil
    }
    
    private func detectMissingErrorHandling(in code: String) -> RefactoringSuggestion? {
        let hasAsyncCode = code.contains("async") || code.contains("await")
        let hasTryKeyword = code.contains("try")
        let hasCatchBlock = code.contains("catch")
        
        if hasAsyncCode && hasTryKeyword && !hasCatchBlock {
            let suggestingAgent = agentSystem.agents.first { $0.role == .developer } ?? AIAgent(
                id: UUID(),
                name: "System Developer",
                role: .developer,
                specialty: "Error Handling",
                personality: .analytical,
                expertise: ["error handling", "reliability", "async/await"]
            )
            
            return RefactoringSuggestion(
                title: "Add Error Handling",
                description: "Async code with 'try' should have proper error handling",
                codeSnippet: """
                do {
                    try await someAsyncFunction()
                } catch {
                    // Handle error appropriately
                    print("Error: \\(error.localizedDescription)")
                }
                """,
                impact: ImpactLevel.high,
                effort: EffortLevel.low,
                category: .reliability,
                suggestedBy: suggestingAgent
            )
        }
        
        return nil
    }
    
    private func suggestDesignPatterns(for code: String) -> RefactoringSuggestion? {
        // Check for opportunities to apply design patterns
        if code.contains("switch") && code.contains("case") {
            let caseCount = code.components(separatedBy: "case").count - 1
            if caseCount > 5 {
                let suggestingAgent = agentSystem.agents.first { $0.role == .architect } ?? AIAgent(
                    id: UUID(),
                    name: "System Architect",
                    role: .architect,
                    specialty: "Design Patterns",
                    personality: .analytical,
                    expertise: ["design patterns", "architecture", "strategy pattern"]
                )
                
                return RefactoringSuggestion(
                    title: "Consider Strategy Pattern",
                    description: "Large switch statements can be refactored using Strategy pattern",
                    codeSnippet: """
                    protocol Strategy {
                        func execute()
                    }
                    
                    class Context {
                        private let strategy: Strategy
                        func performAction() {
                            strategy.execute()
                        }
                    }
                    """,
                    impact: ImpactLevel.medium,
                    effort: EffortLevel.high,
                    category: .architecture,
                    suggestedBy: suggestingAgent
                )
            }
        }
        
        return nil
    }
    
    private func suggestSwiftUIImprovements(for code: String) -> RefactoringSuggestion? {
        // Check for SwiftUI anti-patterns
        if code.contains("@State") && code.contains("class") {
            let suggestingAgent = agentSystem.agents.first { $0.role == .developer } ?? AIAgent(
                id: UUID(),
                name: "System Developer",
                role: .developer,
                specialty: "SwiftUI Best Practices",
                personality: .analytical,
                expertise: ["swiftui", "state management", "correctness"]
            )
            
            return RefactoringSuggestion(
                title: "Use @StateObject for Classes",
                description: "@State should be used for value types. Use @StateObject for reference types",
                codeSnippet: """
                // Instead of:
                @State private var viewModel = ViewModel()
                
                // Use:
                @StateObject private var viewModel = ViewModel()
                """,
                impact: ImpactLevel.high,
                effort: EffortLevel.low,
                category: .correctness,
                suggestedBy: suggestingAgent
            )
        }
        
        return nil
    }
    
    private func generateAsyncAwaitExample() -> String {
        return """
        // Before:
        func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
            // ...
        }
        
        // After:
        func fetchData() async throws -> Data {
            // ...
        }
        """
    }
    
    // MARK: - Marketplace Enhancement Methods
    
    private func generateEnhancedDescription(for template: TemplateModel) -> String {
        var description = "A comprehensive \(template.name) template"
        
        if !template.features.isEmpty {
            description += " featuring \(template.features.prefix(3).joined(separator: ", "))"
        }
        
        description += ". Perfect for \(template.category.rawValue.lowercased()) applications."
        
        if !template.dependencies.isEmpty {
            description += " Includes integration with \(template.dependencies.joined(separator: ", "))."
        }
        
        return description
    }
    
    private func suggestBetterIcon(for template: TemplateModel) -> String {
        let name = template.name.lowercased()
        
        if name.contains("auth") || name.contains("login") {
            return "person.circle.fill"
        } else if name.contains("profile") {
            return "person.crop.circle"
        } else if name.contains("settings") {
            return "gearshape.fill"
        } else if name.contains("data") || name.contains("list") {
            return "list.bullet.rectangle"
        } else if name.contains("create") || name.contains("add") {
            return "plus.circle.fill"
        } else if name.contains("edit") {
            return "pencil.circle.fill"
        } else if name.contains("delete") {
            return "trash.circle.fill"
        } else {
            return "app.fill"
        }
    }
    
    private func generateSuggestedTags(for template: TemplateModel) -> [String] {
        var tags = template.tags
        
        // Add category tag
        tags.append(template.category.rawValue.lowercased())
        
        // Add feature-based tags
        for feature in template.features {
            let featureWords = feature.lowercased().components(separatedBy: " ")
            tags.append(contentsOf: featureWords)
        }
        
        // Add name-based tags
        let nameWords = template.name.components(separatedBy: CharacterSet.alphanumerics.inverted)
        tags.append(contentsOf: nameWords.map { $0.lowercased() })
        
        // Remove duplicates and empty strings
        return Array(Set(tags.filter { !$0.isEmpty }))
    }
    
    private func generateFeaturesList(for template: TemplateModel) -> [String] {
        var features: [String] = []
        
        let name = template.name.lowercased()
        
        // Generate features based on template name and category
        if name.contains("auth") || name.contains("login") {
            features = ["Email/Password Authentication", "Form Validation", "Error Handling", "Remember Me"]
        } else if name.contains("profile") {
            features = ["User Information Display", "Avatar Support", "Edit Capabilities", "Data Persistence"]
        } else if name.contains("list") {
            features = ["Dynamic List Display", "Search Functionality", "Sort Options", "Pull to Refresh"]
        } else if name.contains("create") {
            features = ["Form Input", "Validation", "Save Functionality", "Cancel Option"]
        } else if name.contains("settings") {
            features = ["Grouped Settings", "Toggle Controls", "Navigation", "Persistence"]
        } else {
            features = ["Clean UI", "Responsive Design", "Easy Integration", "Customizable"]
        }
        
        return features
    }
    
    private func suggestPreviewImages(for template: TemplateModel) -> [String] {
        return [
            "Light mode screenshot",
            "Dark mode screenshot",
            "Interaction demo (GIF or video)",
            "Different device sizes (iPhone, iPad)"
        ]
    }
    
    private func optimizeCategory(for template: TemplateModel) -> String? {
        let name = template.name.lowercased()
        
        // Suggest better category if current doesn't match well
        if name.contains("auth") && template.category != .productivity {
            return "Consider moving to Productivity category"
        } else if name.contains("design") && template.category != .creative {
            return "Consider moving to Creative category"
        } else if name.contains("data") && template.category != .utilities {
            return "Consider moving to Utilities category"
        }
        
        return nil
    }
    
    private func generateMarketingCopy(for template: TemplateModel) -> String {
        let name = template.name
        let category = template.category.rawValue
        
        var copy = "🚀 Introducing \(name)\n\n"
        copy += "A powerful \(category.lowercased()) template designed to accelerate your development.\n\n"
        
        if !template.features.isEmpty {
            copy += "✨ Key Features:\n"
            for feature in template.features.prefix(5) {
                copy += "• \(feature)\n"
            }
            copy += "\n"
        }
        
        copy += "Perfect for developers who want to build professional apps faster. "
        copy += "Get started in minutes with this production-ready template.\n\n"
        copy += "⭐️ Download now and see the difference!"
        
        return copy
    }
    
    private func calculatePresentationImpact(_ enhancements: [Enhancement]) -> ImpactLevel {
        let highImpactCount = enhancements.filter { $0.impact == ImpactLevel.high }.count
        let mediumImpactCount = enhancements.filter { $0.impact == ImpactLevel.medium }.count
        
        if highImpactCount >= 3 {
            return ImpactLevel.high
        } else if highImpactCount >= 1 || mediumImpactCount >= 3 {
            return ImpactLevel.medium
        } else {
            return ImpactLevel.low
        }
    }
    
    // MARK: - Contextual Suggestions
    
    private func generateContextualSuggestions(for context: CreationContext) async {
        suggestions.removeAll()
        
        switch context {
        case .packageImport(let packageURL):
            suggestions.append(CreationSuggestion(
                title: "Analyze Package Structure",
                description: "Review package organization at \(packageURL.lastPathComponent) before importing",
                actionType: CreationActionType.structureOptimization,
                codeSnippet: nil,
                priority: SuggestionPriority.high
            ))
            
            // Add suggestion to check dependencies
            suggestions.append(CreationSuggestion(
                title: "Review Package Dependencies",
                description: "Analyze external dependencies and their impact on your Hub",
                actionType: CreationActionType.structureOptimization,
                codeSnippet: nil,
                priority: SuggestionPriority.medium
            ))
            
        case .hubCreation(let hubName):
            suggestions.append(CreationSuggestion(
                title: "Plan Hub Architecture",
                description: "Define clear boundaries and responsibilities for \(hubName)",
                actionType: CreationActionType.structureOptimization,
                codeSnippet: nil,
                priority: SuggestionPriority.high
            ))
            
            // Add suggestion for naming conventions
            suggestions.append(CreationSuggestion(
                title: "Establish Naming Conventions",
                description: "Define consistent naming patterns for \(hubName) components",
                actionType: CreationActionType.structureOptimization,
                codeSnippet: nil,
                priority: SuggestionPriority.medium
            ))
            
        case .templateOrganization(let templates):
            suggestions.append(CreationSuggestion(
                title: "Group Related Templates",
                description: "Organize \(templates.count) templates by feature and layer",
                actionType: CreationActionType.componentExtraction,
                codeSnippet: nil,
                priority: SuggestionPriority.medium
            ))
            
            // Add suggestion for template relationships
            if templates.count > 5 {
                suggestions.append(CreationSuggestion(
                    title: "Document Template Relationships",
                    description: "Map dependencies between \(templates.count) templates",
                    actionType: CreationActionType.structureOptimization,
                    codeSnippet: nil,
                    priority: SuggestionPriority.medium
                ))
            }
            
        case .codeRefactoring(let code):
            suggestions.append(CreationSuggestion(
                title: "Review Code Quality",
                description: "Analyze \(code.components(separatedBy: "\n").count) lines for improvement opportunities",
                actionType: CreationActionType.codeGeneration,
                codeSnippet: nil,
                priority: SuggestionPriority.medium
            ))
            
            // Add specific suggestions based on code content
            if code.contains("class") || code.contains("struct") {
                suggestions.append(CreationSuggestion(
                    title: "Extract Reusable Components",
                    description: "Identify components that can be shared across templates",
                    actionType: CreationActionType.componentExtraction,
                    codeSnippet: nil,
                    priority: SuggestionPriority.high
                ))
            }
            
        case .marketplaceOptimization(let template):
            suggestions.append(CreationSuggestion(
                title: "Enhance Template Presentation",
                description: "Improve marketplace visibility for \(template.name)",
                actionType: CreationActionType.marketplaceEnhancement,
                codeSnippet: nil,
                priority: SuggestionPriority.high
            ))
        }
        
        lastUpdate = Date()
    }
}

// MARK: - Supporting Types

/// Context for AI assistant operations
public enum CreationContext {
    case packageImport(URL)
    case hubCreation(String)
    case templateOrganization([ExtractedTemplate])
    case codeRefactoring(String)
    case marketplaceOptimization(TemplateModel)
}

/// AI-generated suggestion for creation tasks
public struct CreationSuggestion: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let actionType: CreationActionType
    public let codeSnippet: String?
    public let priority: SuggestionPriority
}

/// Type of creation action
public enum CreationActionType {
    case structureOptimization
    case componentExtraction
    case dependencyManagement
    case marketplaceEnhancement
    case codeGeneration
}

/// Priority level for suggestions
public enum SuggestionPriority: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: SuggestionPriority, rhs: SuggestionPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Hub structure suggestion
public struct HubStructureSuggestion {
    public let packageName: String
    public let recommendedHubCount: Int
    public let structureComponents: [StructureComponent]
    public let recommendations: [String]
    public let complexity: ComplexityLevel
    public let estimatedEffort: TimeInterval
    public let suggestedBy: AIAgent
}

/// Component of Hub structure
public struct StructureComponent {
    public let name: String
    public let description: String
    public let rationale: String
    public let priority: SuggestionPriority
}

/// Complexity level
public enum ComplexityLevel: String {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    case veryComplex = "Very Complex"
}

/// Template organization plan
public struct OrganizationPlan {
    public let groups: [TemplateGroup]
    public let relationships: [TemplateRelationship]
    public let recommendations: [String]
    public let folderStructure: [String]
    public let namingConventions: [String: String]
}

/// Group of related templates
public struct TemplateGroup {
    public let name: String
    public let category: HubCategory
    public let templates: [String]
    public let description: String
    public let suggestedOrder: [String]
}

/// Relationship between templates
public struct TemplateRelationship {
    public let from: String
    public let to: String
    public let type: RelationshipType
    public let strength: RelationshipStrength
    
    public enum RelationshipType {
        case navigation
        case dataDependency
        case serviceUsage
        case inheritance
    }
    
    public enum RelationshipStrength {
        case weak
        case medium
        case strong
    }
}

/// Refactoring suggestion
public struct RefactoringSuggestion: Identifiable {
    public let id = UUID()
    public let title: String
    public var description: String
    public let codeSnippet: String
    public let impact: ImpactLevel
    public let effort: EffortLevel
    public let category: RefactoringCategory
    public let suggestedBy: AIAgent
    
    public enum RefactoringCategory {
        case codeQuality
        case maintainability
        case reliability
        case architecture
        case modernization
        case correctness
    }
}

/// Impact level
public enum ImpactLevel: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    
    public static func < (lhs: ImpactLevel, rhs: ImpactLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Effort level
public enum EffortLevel: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    
    public static func < (lhs: EffortLevel, rhs: EffortLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Marketplace presentation enhancements
public struct PresentationEnhancements {
    public let template: TemplateModel
    public let enhancements: [Enhancement]
    public let previewSuggestions: [String]
    public let categorySuggestion: String?
    public let marketingCopy: String
    public let estimatedImpact: ImpactLevel
    public let suggestedBy: AIAgent
}

/// Enhancement suggestion
public struct Enhancement {
    public let type: EnhancementType
    public let current: String
    public let suggested: String
    public let rationale: String
    public let impact: ImpactLevel
    
    public enum EnhancementType {
        case description
        case icon
        case tags
        case features
        case screenshots
        case category
    }
}
