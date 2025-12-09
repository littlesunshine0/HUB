//
//  ProjectAnalyzer.swift
//  Hub
//
//  Analyzes project structure, connections, and file usage
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectAnalyzer: ObservableObject {
    static let shared = ProjectAnalyzer()
    
    @Published var analysisResults: ProjectAnalysisResults?
    @Published var isAnalyzing = false
    @Published var progress: Double = 0
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Analysis
    
    func analyzeProject() async {
        isAnalyzing = true
        progress = 0
        
        print("🔍 Starting comprehensive project analysis...")
        
        var results = ProjectAnalysisResults()
        
        // 1. Discover all files
        progress = 0.1
        results.allFiles = await discoverAllFiles()
        print("📁 Found \(results.allFiles.count) files")
        
        // 2. Analyze file connections
        progress = 0.3
        results.fileConnections = await analyzeFileConnections(results.allFiles)
        print("🔗 Analyzed \(results.fileConnections.count) connections")
        
        // 3. Find unused files
        progress = 0.5
        results.unusedFiles = await findUnusedFiles(results.allFiles, connections: results.fileConnections)
        print("⚠️ Found \(results.unusedFiles.count) potentially unused files")
        
        // 4. Analyze module structure
        progress = 0.7
        results.modules = await analyzeModules()
        print("📦 Found \(results.modules.count) modules")
        
        // 5. Check file organization
        progress = 0.9
        results.organizationIssues = await checkOrganization(results.allFiles)
        print("📋 Found \(results.organizationIssues.count) organization issues")
        
        // 6. Generate recommendations
        results.recommendations = generateRecommendations(results)
        print("💡 Generated \(results.recommendations.count) recommendations")
        
        progress = 1.0
        analysisResults = results
        isAnalyzing = false
        
        print("✅ Project analysis complete")
    }
    
    // MARK: - File Discovery
    
    private func discoverAllFiles() async -> [ProjectFile] {
        var files: [ProjectFile] = []
        let hubPath = "Hub"
        
        if let enumerator = fileManager.enumerator(atPath: hubPath) {
            while let file = enumerator.nextObject() as? String {
                let fullPath = "\(hubPath)/\(file)"
                
                if file.hasSuffix(".swift") {
                    let fileType = determineFileType(file)
                    let module = extractModule(from: file)
                    
                    files.append(ProjectFile(
                        path: fullPath,
                        name: (file as NSString).lastPathComponent,
                        type: fileType,
                        module: module,
                        size: getFileSize(fullPath)
                    ))
                }
            }
        }
        
        return files
    }
    
    private func determineFileType(_ path: String) -> FileType {
        let name = (path as NSString).lastPathComponent
        
        if name.contains("View") { return .view }
        if name.contains("ViewModel") { return .viewModel }
        if name.contains("Model") { return .model }
        if name.contains("Service") { return .service }
        if name.contains("Manager") { return .manager }
        if name.contains("Protocol") { return .protocol }
        if name.contains("Extension") { return .extension }
        if name.contains("Test") { return .test }
        if name.contains("Demo") { return .demo }
        
        return .other
    }
    
    private func extractModule(from path: String) -> String {
        let components = path.components(separatedBy: "/")
        if components.count > 1 {
            return components[0]
        }
        return "Root"
    }
    
    private func getFileSize(_ path: String) -> Int64 {
        if let attributes = try? fileManager.attributesOfItem(atPath: path) {
            return attributes[.size] as? Int64 ?? 0
        }
        return 0
    }
    
    // MARK: - Connection Analysis
    
    private func analyzeFileConnections(_ files: [ProjectFile]) async -> [FileConnection] {
        var connections: [FileConnection] = []
        
        for file in files {
            guard let content = try? String(contentsOfFile: file.path, encoding: .utf8) else {
                continue
            }
            
            // Find imports
            let imports = extractImports(from: content)
            
            // Find type references
            let references = findTypeReferences(in: content, allFiles: files)
            
            for reference in references {
                connections.append(FileConnection(
                    from: file.path,
                    to: reference,
                    type: .typeReference
                ))
            }
        }
        
        return connections
    }
    
    private func extractImports(from content: String) -> [String] {
        var imports: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if line.starts(with: "import ") {
                let importName = line.replacingOccurrences(of: "import ", with: "").trimmingCharacters(in: .whitespaces)
                imports.append(importName)
            }
        }
        
        return imports
    }
    
    private func findTypeReferences(in content: String, allFiles: [ProjectFile]) -> [String] {
        var references: [String] = []
        
        for file in allFiles {
            let typeName = file.name.replacingOccurrences(of: ".swift", with: "")
            if content.contains(typeName) {
                references.append(file.path)
            }
        }
        
        return references
    }
    
    // MARK: - Unused Files Detection
    
    private func findUnusedFiles(_ files: [ProjectFile], connections: [FileConnection]) async -> [ProjectFile] {
        var unusedFiles: [ProjectFile] = []
        
        for file in files {
            // Skip test and demo files
            if file.type == .test || file.type == .demo {
                continue
            }
            
            // Check if file is referenced
            let isReferenced = connections.contains { $0.to == file.path }
            
            // Check if it's an entry point (App, main, etc.)
            let isEntryPoint = file.name.contains("App.swift") || file.name.contains("main.swift")
            
            if !isReferenced && !isEntryPoint {
                unusedFiles.append(file)
            }
        }
        
        return unusedFiles
    }
    
    // MARK: - Module Analysis
    
    private func analyzeModules() async -> [ProjectModule] {
        var modules: [ProjectModule] = []
        let hubPath = "Hub"
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: hubPath) {
            for item in contents {
                let fullPath = "\(hubPath)/\(item)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory),
                   isDirectory.boolValue,
                   item.hasSuffix("Module") {
                    
                    let fileCount = countSwiftFiles(in: fullPath)
                    let size = calculateDirectorySize(fullPath)
                    
                    modules.append(ProjectModule(
                        name: item,
                        path: fullPath,
                        fileCount: fileCount,
                        size: size,
                        isComplete: fileCount > 0
                    ))
                }
            }
        }
        
        return modules
    }
    
    private func countSwiftFiles(in directory: String) -> Int {
        var count = 0
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    private func calculateDirectorySize(_ directory: String) -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            while let file = enumerator.nextObject() as? String {
                let fullPath = "\(directory)/\(file)"
                totalSize += getFileSize(fullPath)
            }
        }
        
        return totalSize
    }
    
    // MARK: - Organization Check
    
    private func checkOrganization(_ files: [ProjectFile]) async -> [OrganizationIssue] {
        var issues: [OrganizationIssue] = []
        
        // Check for files in wrong locations
        for file in files {
            if file.type == .view && !file.path.contains("/Views/") && !file.path.contains("/UI/") {
                issues.append(OrganizationIssue(
                    file: file.path,
                    issue: "View file not in Views or UI directory",
                    suggestion: "Move to appropriate Views directory"
                ))
            }
            
            if file.type == .model && !file.path.contains("/Models/") && !file.path.contains("/Data/") {
                issues.append(OrganizationIssue(
                    file: file.path,
                    issue: "Model file not in Models or Data directory",
                    suggestion: "Move to appropriate Models directory"
                ))
            }
            
            if file.type == .service && !file.path.contains("/Services/") {
                issues.append(OrganizationIssue(
                    file: file.path,
                    issue: "Service file not in Services directory",
                    suggestion: "Move to appropriate Services directory"
                ))
            }
        }
        
        return issues
    }
    
    // MARK: - Recommendations
    
    private func generateRecommendations(_ results: ProjectAnalysisResults) -> [ProjectRecommendation] {
        var recommendations: [ProjectRecommendation] = []
        
        // Unused files recommendation
        if results.unusedFiles.count > 0 {
            recommendations.append(ProjectRecommendation(
                priority: .medium,
                category: .cleanup,
                title: "Remove Unused Files",
                description: "Found \(results.unusedFiles.count) potentially unused files that could be removed to reduce project size.",
                action: .reviewUnusedFiles
            ))
        }
        
        // Organization recommendations
        if results.organizationIssues.count > 0 {
            recommendations.append(ProjectRecommendation(
                priority: .low,
                category: .organization,
                title: "Improve File Organization",
                description: "Found \(results.organizationIssues.count) files that could be better organized.",
                action: .reorganizeFiles
            ))
        }
        
        // Module completeness
        let incompleteModules = results.modules.filter { !$0.isComplete }
        if incompleteModules.count > 0 {
            recommendations.append(ProjectRecommendation(
                priority: .high,
                category: .structure,
                title: "Complete Module Implementation",
                description: "\(incompleteModules.count) modules appear incomplete or empty.",
                action: .reviewModules
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Export
    
    func exportAnalysis() -> String {
        guard let results = analysisResults else {
            return "No analysis results available"
        }
        
        var report = """
        # Project Analysis Report
        Generated: \(Date())
        
        ## Summary
        - Total Files: \(results.allFiles.count)
        - Connections: \(results.fileConnections.count)
        - Unused Files: \(results.unusedFiles.count)
        - Modules: \(results.modules.count)
        - Organization Issues: \(results.organizationIssues.count)
        
        ## Modules
        """
        
        for module in results.modules {
            report += "\n- \(module.name): \(module.fileCount) files"
        }
        
        report += "\n\n## Recommendations\n"
        for rec in results.recommendations {
            report += "\n[\(rec.priority)] \(rec.title)\n  \(rec.description)\n"
        }
        
        return report
    }
}

// MARK: - Supporting Types

struct ProjectAnalysisResults {
    var allFiles: [ProjectFile] = []
    var fileConnections: [FileConnection] = []
    var unusedFiles: [ProjectFile] = []
    var modules: [ProjectModule] = []
    var organizationIssues: [OrganizationIssue] = []
    var recommendations: [ProjectRecommendation] = []
}

struct ProjectFile: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let type: FileType
    let module: String
    let size: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum FileType {
    case view
    case viewModel
    case model
    case service
    case manager
    case `protocol`
    case `extension`
    case test
    case demo
    case other
    
    var icon: String {
        switch self {
        case .view: return "rectangle.fill"
        case .viewModel: return "brain"
        case .model: return "cube.fill"
        case .service: return "gearshape.fill"
        case .manager: return "folder.fill"
        case .protocol: return "doc.text.fill"
        case .extension: return "puzzlepiece.extension.fill"
        case .test: return "checkmark.circle.fill"
        case .demo: return "play.circle.fill"
        case .other: return "doc.fill"
        }
    }
}

struct FileConnection: Identifiable {
    let id = UUID()
    let from: String
    let to: String
    let type: ConnectionType
}

enum ConnectionType {
    case importStatement
    case typeReference
    case inheritance
    case protocolConformance
}

struct ProjectModule: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let fileCount: Int
    let size: Int64
    let isComplete: Bool
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct OrganizationIssue: Identifiable {
    let id = UUID()
    let file: String
    let issue: String
    let suggestion: String
}

// MARK: - Enums (must be defined before structs that use them)

enum RecommendationPriority: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum RecommendationCategory {
    case cleanup
    case organization
    case structure
    case performance
    case security
}

enum RecommendationAction {
    case reviewUnusedFiles
    case reorganizeFiles
    case reviewModules
    case optimizePerformance
    case fixSecurity
}

// MARK: - Recommendation Struct

struct ProjectRecommendation: Identifiable {
    let id = UUID()
    let priority: RecommendationPriority
    let category: RecommendationCategory
    let title: String
    let description: String
    let action: RecommendationAction
}
