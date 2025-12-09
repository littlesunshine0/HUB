//
//  ProjectHealthAgent.swift
//  Hub
//
//  Autonomous agent that monitors and auto-heals project issues
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectHealthAgent: ObservableObject {
    static let shared = ProjectHealthAgent()
    
    @Published var isMonitoring = false
    @Published var healthStatus: ProjectHealthStatus = .healthy
    @Published var issues: [ProjectIssue] = []
    @Published var healingHistory: [HealingAction] = []
    @Published var lastScanDate: Date?
    
    private var monitoringTask: Task<Void, Never>?
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🤖 Project Health Agent: Monitoring started")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await performHealthCheck()
                
                // Run every 5 minutes
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        print("🤖 Project Health Agent: Monitoring stopped")
    }
    
    // MARK: - Health Check
    
    func performHealthCheck() async {
        print("🔍 Running project health check...")
        lastScanDate = Date()
        
        var detectedIssues: [ProjectIssue] = []
        
        // 1. Check for compilation errors
        let compileIssues = await checkCompilationErrors()
        detectedIssues.append(contentsOf: compileIssues)
        
        // 2. Check for warnings
        let warningIssues = await checkWarnings()
        detectedIssues.append(contentsOf: warningIssues)
        
        // 3. Check for unused files
        let unusedFiles = await checkUnusedFiles()
        detectedIssues.append(contentsOf: unusedFiles)
        
        // 4. Check for missing imports
        let importIssues = await checkMissingImports()
        detectedIssues.append(contentsOf: importIssues)
        
        // 5. Check for broken references
        let referenceIssues = await checkBrokenReferences()
        detectedIssues.append(contentsOf: referenceIssues)
        
        // 6. Check project structure
        let structureIssues = await checkProjectStructure()
        detectedIssues.append(contentsOf: structureIssues)
        
        issues = detectedIssues
        updateHealthStatus()
        
        // Auto-heal critical issues
        await autoHealCriticalIssues()
        
        print("✅ Health check complete: \(issues.count) issues found")
    }
    
    // MARK: - Issue Detection
    
    private func checkCompilationErrors() async -> [ProjectIssue] {
        var issues: [ProjectIssue] = []
        
        // Check for common compilation errors
        let swiftFiles = findSwiftFiles()
        
        for file in swiftFiles {
            if let content = try? String(contentsOfFile: file, encoding: .utf8) {
                // Check for missing semicolons (not needed in Swift, but check syntax)
                // Check for unbalanced braces
                let openBraces = content.filter { $0 == "{" }.count
                let closeBraces = content.filter { $0 == "}" }.count
                
                if openBraces != closeBraces {
                    issues.append(ProjectIssue(
                        id: UUID(),
                        type: .compilationError,
                        severity: .critical,
                        file: file,
                        line: nil,
                        message: "Unbalanced braces: \(openBraces) open, \(closeBraces) close",
                        autoFixable: true
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func checkWarnings() async -> [ProjectIssue] {
        var issues: [ProjectIssue] = []
        
        let swiftFiles = findSwiftFiles()
        
        for file in swiftFiles {
            if let content = try? String(contentsOfFile: file, encoding: .utf8) {
                // Check for unused variables (simple heuristic)
                let lines = content.components(separatedBy: .newlines)
                for (index, line) in lines.enumerated() {
                    if line.contains("let ") && line.contains(" = ") {
                        let varName = extractVariableName(from: line)
                        if let name = varName, !isVariableUsed(name, in: content, afterLine: index) {
                            issues.append(ProjectIssue(
                                id: UUID(),
                                type: .warning,
                                severity: .medium,
                                file: file,
                                line: index + 1,
                                message: "Unused variable: \(name)",
                                autoFixable: false
                            ))
                        }
                    }
                }
            }
        }
        
        return issues
    }
    
    private func checkUnusedFiles() async -> [ProjectIssue] {
        var issues: [ProjectIssue] = []
        
        let swiftFiles = findSwiftFiles()
        let projectFiles = Set(swiftFiles)
        
        // Check if files are referenced in project
        for file in swiftFiles {
            let fileName = (file as NSString).lastPathComponent
            var isReferenced = false
            
            // Check if file is imported or referenced elsewhere
            for otherFile in swiftFiles where otherFile != file {
                if let content = try? String(contentsOfFile: otherFile, encoding: .utf8) {
                    if content.contains(fileName.replacingOccurrences(of: ".swift", with: "")) {
                        isReferenced = true
                        break
                    }
                }
            }
            
            if !isReferenced && !fileName.contains("Demo") && !fileName.contains("Test") {
                issues.append(ProjectIssue(
                    id: UUID(),
                    type: .unusedFile,
                    severity: .low,
                    file: file,
                    line: nil,
                    message: "File may be unused in project",
                    autoFixable: false
                ))
            }
        }
        
        return issues
    }
    
    private func checkMissingImports() async -> [ProjectIssue] {
        var issues: [ProjectIssue] = []
        
        let swiftFiles = findSwiftFiles()
        
        for file in swiftFiles {
            if let content = try? String(contentsOfFile: file, encoding: .utf8) {
                // Check for SwiftUI usage without import
                if content.contains("View") || content.contains("@State") {
                    if !content.contains("import SwiftUI") {
                        issues.append(ProjectIssue(
                            id: UUID(),
                            type: .missingImport,
                            severity: .high,
                            file: file,
                            line: 1,
                            message: "Missing 'import SwiftUI'",
                            autoFixable: true
                        ))
                    }
                }
                
                // Check for Foundation usage
                if content.contains("Date") || content.contains("UUID") {
                    if !content.contains("import Foundation") && !content.contains("import SwiftUI") {
                        issues.append(ProjectIssue(
                            id: UUID(),
                            type: .missingImport,
                            severity: .high,
                            file: file,
                            line: 1,
                            message: "Missing 'import Foundation'",
                            autoFixable: true
                        ))
                    }
                }
            }
        }
        
        return issues
    }
    
    private func checkBrokenReferences() async -> [ProjectIssue] {
        var issues: [ProjectIssue] = []
        
        // Check for broken file references in project
        // This would integrate with Xcode project file parsing
        
        return issues
    }
    
    private func checkProjectStructure() async -> [ProjectIssue] {
        var issues: [ProjectIssue] = []
        
        // Check for proper module organization
        let hubPath = "Hub"
        
        // Ensure key directories exist
        let requiredDirs = [
            "Hub/AIModule",
            "Hub/AuthenticationModule",
            "Hub/AutomationModule",
            "Hub/StorageLayer",
            "Hub/DesignSystem"
        ]
        
        for dir in requiredDirs {
            if !fileManager.fileExists(atPath: dir) {
                issues.append(ProjectIssue(
                    id: UUID(),
                    type: .structureIssue,
                    severity: .medium,
                    file: dir,
                    line: nil,
                    message: "Missing required directory: \(dir)",
                    autoFixable: true
                ))
            }
        }
        
        return issues
    }
    
    // MARK: - Auto-Healing
    
    private func autoHealCriticalIssues() async {
        let criticalIssues = issues.filter { $0.severity == .critical && $0.autoFixable }
        
        for issue in criticalIssues {
            await healIssue(issue)
        }
    }
    
    func healIssue(_ issue: ProjectIssue) async {
        print("🔧 Auto-healing: \(issue.message)")
        
        switch issue.type {
        case .missingImport:
            await fixMissingImport(issue)
        case .compilationError:
            await fixCompilationError(issue)
        case .structureIssue:
            await fixStructureIssue(issue)
        default:
            print("⚠️ No auto-fix available for: \(issue.type)")
        }
    }
    
    private func fixMissingImport(_ issue: ProjectIssue) async {
        guard let content = try? String(contentsOfFile: issue.file, encoding: .utf8) else { return }
        
        var lines = content.components(separatedBy: .newlines)
        
        // Find the right place to insert import
        var insertIndex = 0
        for (index, line) in lines.enumerated() {
            if line.starts(with: "import ") {
                insertIndex = index + 1
            } else if !line.isEmpty && !line.starts(with: "//") {
                break
            }
        }
        
        // Insert the missing import
        if issue.message.contains("SwiftUI") {
            lines.insert("import SwiftUI", at: insertIndex)
        } else if issue.message.contains("Foundation") {
            lines.insert("import Foundation", at: insertIndex)
        }
        
        let fixedContent = lines.joined(separator: "\n")
        try? fixedContent.write(toFile: issue.file, atomically: true, encoding: .utf8)
        
        recordHealingAction(issue: issue, action: "Added missing import")
    }
    
    private func fixCompilationError(_ issue: ProjectIssue) async {
        // Attempt to fix common compilation errors
        guard let content = try? String(contentsOfFile: issue.file, encoding: .utf8) else { return }
        
        // Fix unbalanced braces (simple heuristic)
        let openBraces = content.filter { $0 == "{" }.count
        let closeBraces = content.filter { $0 == "}" }.count
        
        if openBraces > closeBraces {
            let fixedContent = content + String(repeating: "\n}", count: openBraces - closeBraces)
            try? fixedContent.write(toFile: issue.file, atomically: true, encoding: .utf8)
            recordHealingAction(issue: issue, action: "Added missing closing braces")
        }
    }
    
    private func fixStructureIssue(_ issue: ProjectIssue) async {
        // Create missing directories
        if issue.message.contains("Missing required directory") {
            try? fileManager.createDirectory(atPath: issue.file, withIntermediateDirectories: true)
            recordHealingAction(issue: issue, action: "Created missing directory")
        }
    }
    
    // MARK: - Helper Methods
    
    private func findSwiftFiles() -> [String] {
        var swiftFiles: [String] = []
        
        let hubPath = "Hub"
        
        if let enumerator = fileManager.enumerator(atPath: hubPath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    swiftFiles.append("\(hubPath)/\(file)")
                }
            }
        }
        
        return swiftFiles
    }
    
    private func extractVariableName(from line: String) -> String? {
        let pattern = "let\\s+(\\w+)\\s*="
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsLine = line as NSString
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) {
                return nsLine.substring(with: match.range(at: 1))
            }
        }
        return nil
    }
    
    private func isVariableUsed(_ name: String, in content: String, afterLine: Int) -> Bool {
        let lines = content.components(separatedBy: .newlines)
        let remainingLines = lines.dropFirst(afterLine + 1)
        let remainingContent = remainingLines.joined(separator: "\n")
        
        // Simple check - could be enhanced
        return remainingContent.contains(name)
    }
    
    private func updateHealthStatus() {
        let criticalCount = issues.filter { $0.severity == .critical }.count
        let highCount = issues.filter { $0.severity == .high }.count
        
        if criticalCount > 0 {
            healthStatus = .critical
        } else if highCount > 0 {
            healthStatus = .warning
        } else if issues.count > 0 {
            healthStatus = .needsAttention
        } else {
            healthStatus = .healthy
        }
    }
    
    private func recordHealingAction(issue: ProjectIssue, action: String) {
        let healingAction = HealingAction(
            id: UUID(),
            timestamp: Date(),
            issue: issue,
            action: action,
            success: true
        )
        
        healingHistory.insert(healingAction, at: 0)
        
        // Remove the healed issue
        issues.removeAll { $0.id == issue.id }
        updateHealthStatus()
        
        print("✅ Healed: \(action)")
    }
}

// MARK: - Supporting Types

enum ProjectHealthStatus {
    case healthy
    case needsAttention
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .needsAttention: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .needsAttention: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

struct ProjectIssue: Identifiable {
    let id: UUID
    let type: IssueType
    let severity: IssueSeverity
    let file: String
    let line: Int?
    let message: String
    let autoFixable: Bool
    
    var fileName: String {
        (file as NSString).lastPathComponent
    }
}

enum IssueType {
    case compilationError
    case warning
    case unusedFile
    case missingImport
    case brokenReference
    case structureIssue
    
    var displayName: String {
        switch self {
        case .compilationError: return "Compilation Error"
        case .warning: return "Warning"
        case .unusedFile: return "Unused File"
        case .missingImport: return "Missing Import"
        case .brokenReference: return "Broken Reference"
        case .structureIssue: return "Structure Issue"
        }
    }
}

enum ProjectIssueSeverity {
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

struct HealingAction: Identifiable {
    let id: UUID
    let timestamp: Date
    let issue: ProjectIssue
    let action: String
    let success: Bool
}
