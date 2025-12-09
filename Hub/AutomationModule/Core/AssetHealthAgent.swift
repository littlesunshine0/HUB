//
//  AssetHealthAgent.swift
//  Hub
//
//  Comprehensive asset health monitoring for all document and resource types
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AssetHealthAgent: ObservableObject {
    static let shared = AssetHealthAgent()
    
    @Published var assetInventory: AssetInventory?
    @Published var isScanning = false
    @Published var healthStatus: AssetHealthStatus = .unknown
    @Published var issues: [AssetIssue] = []
    @Published var lastScanDate: Date?
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Asset Scanning
    
    func performAssetScan() async {
        isScanning = true
        lastScanDate = Date()
        
        print("📦 Starting comprehensive asset scan...")
        
        var inventory = AssetInventory()
        
        // Scan all asset categories
        inventory.documents = await scanDocuments()
        inventory.images = await scanImages()
        inventory.developerDocuments = await scanDeveloperDocuments()
        inventory.appDocuments = await scanAppDocuments()
        inventory.systemDocuments = await scanSystemDocuments()
        inventory.hubDocuments = await scanHubDocuments()
        inventory.templateDocuments = await scanTemplateDocuments()
        inventory.components = await scanComponents()
        inventory.blueprints = await scanBlueprints()
        inventory.modules = await scanModules()
        
        assetInventory = inventory
        
        // Analyze health
        await analyzeAssetHealth()
        
        isScanning = false
        
        print("✅ Asset scan complete")
        printInventorySummary()
    }
    
    // MARK: - Document Scanning
    
    private func scanDocuments() async -> [AssetDocument] {
        var documents: [AssetDocument] = []
        
        // Scan markdown files
        let markdownFiles = findFiles(withExtension: ".md", in: ".")
        for file in markdownFiles {
            documents.append(AssetDocument(
                path: file,
                type: .markdown,
                category: categorizeDocument(file),
                size: getFileSize(file)
            ))
        }
        
        // Scan text files
        let textFiles = findFiles(withExtension: ".txt", in: ".")
        for file in textFiles {
            documents.append(AssetDocument(
                path: file,
                type: .text,
                category: categorizeDocument(file),
                size: getFileSize(file)
            ))
        }
        
        print("📄 Found \(documents.count) documents")
        return documents
    }
    
    private func scanImages() async -> [AssetImage] {
        var images: [AssetImage] = []
        
        // Scan Assets.xcassets
        let assetsPath = "Hub/Assets.xcassets"
        if let enumerator = fileManager.enumerator(atPath: assetsPath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".imageset") || file.hasSuffix(".appiconset") {
                    images.append(AssetImage(
                        path: "\(assetsPath)/\(file)",
                        type: file.hasSuffix(".appiconset") ? .appIcon : .image,
                        size: getDirectorySize("\(assetsPath)/\(file)")
                    ))
                }
            }
        }
        
        // Scan for standalone images
        let imageExtensions = [".png", ".jpg", ".jpeg", ".svg", ".pdf"]
        for ext in imageExtensions {
            let imageFiles = findFiles(withExtension: ext, in: "Hub")
            for file in imageFiles {
                images.append(AssetImage(
                    path: file,
                    type: .image,
                    size: getFileSize(file)
                ))
            }
        }
        
        print("🖼️ Found \(images.count) images")
        return images
    }
    
    private func scanDeveloperDocuments() async -> [DeveloperDocument] {
        var docs: [DeveloperDocument] = []
        
        let devDocPatterns = [
            "README", "CONTRIBUTING", "CHANGELOG", "LICENSE",
            "ARCHITECTURE", "DESIGN", "IMPLEMENTATION", "API"
        ]
        
        let allDocs = findFiles(withExtension: ".md", in: ".")
        for doc in allDocs {
            let fileName = (doc as NSString).lastPathComponent.uppercased()
            for pattern in devDocPatterns {
                if fileName.contains(pattern) {
                    docs.append(DeveloperDocument(
                        path: doc,
                        type: classifyDeveloperDoc(fileName),
                        size: getFileSize(doc)
                    ))
                    break
                }
            }
        }
        
        print("👨‍💻 Found \(docs.count) developer documents")
        return docs
    }
    
    private func scanAppDocuments() async -> [AppDocument] {
        var docs: [AppDocument] = []
        
        // App-specific documentation
        let appDocPaths = [
            "QUICK_START_GUIDE.md",
            "DEFAULT_CONTENT_SYSTEM.md",
            "IMPLEMENTATION_SUMMARY.md",
            "DATABASE_HEALTH_STATUS.md"
        ]
        
        for path in appDocPaths {
            if fileManager.fileExists(atPath: path) {
                docs.append(AppDocument(
                    path: path,
                    type: .userGuide,
                    size: getFileSize(path)
                ))
            }
        }
        
        print("📱 Found \(docs.count) app documents")
        return docs
    }
    
    private func scanSystemDocuments() async -> [SystemDocument] {
        var docs: [SystemDocument] = []
        
        // System configuration files
        let systemPaths = [
            "Hub.xcodeproj",
            ".kiro",
            ".git"
        ]
        
        for path in systemPaths {
            if fileManager.fileExists(atPath: path) {
                docs.append(SystemDocument(
                    path: path,
                    type: classifySystemDoc(path),
                    size: getDirectorySize(path)
                ))
            }
        }
        
        print("⚙️ Found \(docs.count) system documents")
        return docs
    }
    
    private func scanHubDocuments() async -> [HubDocument] {
        var docs: [HubDocument] = []
        
        // Hub-specific files
        let hubFiles = [
            "Hub/AppHub.swift",
            "Hub/HubViewModel.swift",
            "Hub/HubSeeder.swift",
            "Hub/HubDetailView.swift",
            "Hub/HubDiscoveryView.swift",
            "Hub/HubEditorView.swift",
            "Hub/HubCreationView.swift",
            "Hub/HubGalleryView.swift"
        ]
        
        for file in hubFiles {
            if fileManager.fileExists(atPath: file) {
                docs.append(HubDocument(
                    path: file,
                    type: .hubCore,
                    size: getFileSize(file)
                ))
            }
        }
        
        print("🎯 Found \(docs.count) hub documents")
        return docs
    }
    
    private func scanTemplateDocuments() async -> [TemplateDocument] {
        var docs: [TemplateDocument] = []
        
        // Template-related files
        let templatePath = "Hub/TemplateModule"
        if let enumerator = fileManager.enumerator(atPath: templatePath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    let fullPath = "\(templatePath)/\(file)"
                    docs.append(TemplateDocument(
                        path: fullPath,
                        type: .templateDefinition,
                        size: getFileSize(fullPath)
                    ))
                }
            }
        }
        
        // Template seeder
        if fileManager.fileExists(atPath: "Hub/TemplateSeeder.swift") {
            docs.append(TemplateDocument(
                path: "Hub/TemplateSeeder.swift",
                type: .templateSeeder,
                size: getFileSize("Hub/TemplateSeeder.swift")
            ))
        }
        
        print("📋 Found \(docs.count) template documents")
        return docs
    }
    
    private func scanComponents() async -> [ComponentAsset] {
        var components: [ComponentAsset] = []
        
        let componentPath = "Hub/ComponentsModule"
        if let enumerator = fileManager.enumerator(atPath: componentPath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    let fullPath = "\(componentPath)/\(file)"
                    components.append(ComponentAsset(
                        path: fullPath,
                        type: .uiComponent,
                        size: getFileSize(fullPath)
                    ))
                }
            }
        }
        
        // HubComponents
        let hubComponentPath = "Hub/HubComponents"
        if let enumerator = fileManager.enumerator(atPath: hubComponentPath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    let fullPath = "\(hubComponentPath)/\(file)"
                    components.append(ComponentAsset(
                        path: fullPath,
                        type: .hubComponent,
                        size: getFileSize(fullPath)
                    ))
                }
            }
        }
        
        print("🧩 Found \(components.count) components")
        return components
    }
    
    private func scanBlueprints() async -> [BlueprintAsset] {
        var blueprints: [BlueprintAsset] = []
        
        // Scan spec files (blueprints for features)
        let specsPath = ".kiro/specs"
        if let contents = try? fileManager.contentsOfDirectory(atPath: specsPath) {
            for spec in contents {
                let specPath = "\(specsPath)/\(spec)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: specPath, isDirectory: &isDirectory),
                   isDirectory.boolValue {
                    blueprints.append(BlueprintAsset(
                        path: specPath,
                        type: .featureSpec,
                        size: getDirectorySize(specPath)
                    ))
                }
            }
        }
        
        print("📐 Found \(blueprints.count) blueprints")
        return blueprints
    }
    
    private func scanModules() async -> [ModuleAsset] {
        var modules: [ModuleAsset] = []
        
        let hubPath = "Hub"
        if let contents = try? fileManager.contentsOfDirectory(atPath: hubPath) {
            for item in contents {
                if item.hasSuffix("Module") {
                    let modulePath = "\(hubPath)/\(item)"
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: modulePath, isDirectory: &isDirectory),
                       isDirectory.boolValue {
                        
                        let fileCount = countSwiftFiles(in: modulePath)
                        modules.append(ModuleAsset(
                            path: modulePath,
                            name: item,
                            type: classifyModule(item),
                            fileCount: fileCount,
                            size: getDirectorySize(modulePath)
                        ))
                    }
                }
            }
        }
        
        print("📦 Found \(modules.count) modules")
        return modules
    }
    
    // MARK: - Health Analysis
    
    private func analyzeAssetHealth() async {
        guard let inventory = assetInventory else { return }
        
        var detectedIssues: [AssetIssue] = []
        
        // Check for missing critical assets
        if inventory.appDocuments.isEmpty {
            detectedIssues.append(AssetIssue(
                type: .missingAsset,
                severity: .medium,
                description: "No app documentation found",
                affectedAssets: []
            ))
        }
        
        // Check for orphaned files
        let allSwiftFiles = findFiles(withExtension: ".swift", in: "Hub")
        for file in allSwiftFiles {
            if !isFileReferenced(file) {
                detectedIssues.append(AssetIssue(
                    type: .orphanedAsset,
                    severity: .low,
                    description: "Potentially orphaned file",
                    affectedAssets: [file]
                ))
            }
        }
        
        // Check module completeness
        for module in inventory.modules {
            if module.fileCount == 0 {
                detectedIssues.append(AssetIssue(
                    type: .incompleteModule,
                    severity: .medium,
                    description: "Empty module: \(module.name)",
                    affectedAssets: [module.path]
                ))
            }
        }
        
        issues = detectedIssues
        
        // Determine overall health
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
    
    // MARK: - Helper Methods
    
    private func findFiles(withExtension ext: String, in directory: String) -> [String] {
        var files: [String] = []
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(ext) {
                    files.append("\(directory)/\(file)")
                }
            }
        }
        
        return files
    }
    
    private func getFileSize(_ path: String) -> Int64 {
        if let attributes = try? fileManager.attributesOfItem(atPath: path) {
            return attributes[.size] as? Int64 ?? 0
        }
        return 0
    }
    
    private func getDirectorySize(_ path: String) -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(atPath: path) {
            while let file = enumerator.nextObject() as? String {
                let fullPath = "\(path)/\(file)"
                totalSize += getFileSize(fullPath)
            }
        }
        
        return totalSize
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
    
    private func categorizeDocument(_ path: String) -> DocumentCategory {
        let fileName = (path as NSString).lastPathComponent.uppercased()
        
        if fileName.contains("README") { return .readme }
        if fileName.contains("GUIDE") { return .guide }
        if fileName.contains("SPEC") { return .specification }
        if fileName.contains("TASK") { return .task }
        if fileName.contains("DESIGN") { return .design }
        if fileName.contains("REQUIREMENTS") { return .requirements }
        
        return .general
    }
    
    private func classifyDeveloperDoc(_ fileName: String) -> DeveloperDocType {
        if fileName.contains("README") { return .readme }
        if fileName.contains("ARCHITECTURE") { return .architecture }
        if fileName.contains("API") { return .api }
        if fileName.contains("DESIGN") { return .design }
        if fileName.contains("IMPLEMENTATION") { return .implementation }
        
        return .general
    }
    
    private func classifySystemDoc(_ path: String) -> SystemDocType {
        if path.contains(".xcodeproj") { return .projectConfig }
        if path.contains(".kiro") { return .kiroConfig }
        if path.contains(".git") { return .gitConfig }
        
        return .other
    }
    
    private func classifyModule(_ name: String) -> ModuleType {
        if name.contains("AI") { return .ai }
        if name.contains("Auth") { return .authentication }
        if name.contains("Storage") { return .storage }
        if name.contains("Automation") { return .automation }
        if name.contains("Template") { return .template }
        if name.contains("Component") { return .component }
        if name.contains("Design") { return .design }
        if name.contains("Analytics") { return .analytics }
        if name.contains("Notification") { return .notification }
        if name.contains("Enterprise") { return .enterprise }
        
        return .other
    }
    
    private func isFileReferenced(_ file: String) -> Bool {
        // Simple heuristic - could be enhanced
        let fileName = (file as NSString).lastPathComponent
        return !fileName.contains("Demo") && !fileName.contains("Test")
    }
    
    private func printInventorySummary() {
        guard let inventory = assetInventory else { return }
        
        print("""
        
        📊 Asset Inventory Summary:
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📄 Documents: \(inventory.documents.count)
        🖼️ Images: \(inventory.images.count)
        👨‍💻 Developer Docs: \(inventory.developerDocuments.count)
        📱 App Docs: \(inventory.appDocuments.count)
        ⚙️ System Docs: \(inventory.systemDocuments.count)
        🎯 Hub Docs: \(inventory.hubDocuments.count)
        📋 Template Docs: \(inventory.templateDocuments.count)
        🧩 Components: \(inventory.components.count)
        📐 Blueprints: \(inventory.blueprints.count)
        📦 Modules: \(inventory.modules.count)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Health Status: \(healthStatus)
        Issues Found: \(issues.count)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }
}

// MARK: - Asset Types

struct AssetInventory {
    var documents: [AssetDocument] = []
    var images: [AssetImage] = []
    var developerDocuments: [DeveloperDocument] = []
    var appDocuments: [AppDocument] = []
    var systemDocuments: [SystemDocument] = []
    var hubDocuments: [HubDocument] = []
    var templateDocuments: [TemplateDocument] = []
    var components: [ComponentAsset] = []
    var blueprints: [BlueprintAsset] = []
    var modules: [ModuleAsset] = []
}

struct AssetDocument: Identifiable {
    let id = UUID()
    let path: String
    let type: AssetDocumentType
    let category: DocumentCategory
    let size: Int64
}

enum AssetDocumentType {
    case markdown
    case text
    case json
    case yaml
}

enum DocumentCategory {
    case readme
    case guide
    case specification
    case task
    case design
    case requirements
    case general
}

struct AssetImage: Identifiable {
    let id = UUID()
    let path: String
    let type: ImageType
    let size: Int64
}

enum ImageType {
    case image
    case appIcon
    case asset
}

struct DeveloperDocument: Identifiable {
    let id = UUID()
    let path: String
    let type: DeveloperDocType
    let size: Int64
}

enum DeveloperDocType {
    case readme
    case architecture
    case api
    case design
    case implementation
    case general
}

struct AppDocument: Identifiable {
    let id = UUID()
    let path: String
    let type: AppDocType
    let size: Int64
}

enum AppDocType {
    case userGuide
    case quickStart
    case tutorial
    case reference
}

struct SystemDocument: Identifiable {
    let id = UUID()
    let path: String
    let type: SystemDocType
    let size: Int64
}

enum SystemDocType {
    case projectConfig
    case kiroConfig
    case gitConfig
    case other
}

struct HubDocument: Identifiable {
    let id = UUID()
    let path: String
    let type: HubDocType
    let size: Int64
}

enum HubDocType {
    case hubCore
    case hubView
    case hubViewModel
    case hubService
}

struct TemplateDocument: Identifiable {
    let id = UUID()
    let path: String
    let type: TemplateDocType
    let size: Int64
}

enum TemplateDocType {
    case templateDefinition
    case templateSeeder
    case templateView
    case templateService
}

struct ComponentAsset: Identifiable {
    let id = UUID()
    let path: String
    let type: AssetComponentType
    let size: Int64
}

enum AssetComponentType {
    case uiComponent
    case hubComponent
    case designComponent
    case dataComponent
}

struct BlueprintAsset: Identifiable {
    let id = UUID()
    let path: String
    let type: AssetBlueprintType
    let size: Int64
}

enum AssetBlueprintType {
    case featureSpec
    case designSpec
    case architectureSpec
}

struct ModuleAsset: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let type: ModuleType
    let fileCount: Int
    let size: Int64
}

enum ModuleType {
    case ai
    case authentication
    case storage
    case automation
    case template
    case component
    case design
    case analytics
    case notification
    case enterprise
    case other
}

struct AssetIssue: Identifiable {
    let id = UUID()
    let type: AssetIssueType
    let severity: AssetIssueSeverity
    let description: String
    let affectedAssets: [String]
}

enum AssetIssueType {
    case missingAsset
    case orphanedAsset
    case incompleteModule
    case brokenReference
    case duplicateAsset
}

enum AssetIssueSeverity {
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

enum AssetHealthStatus {
    case unknown
    case healthy
    case needsAttention
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .healthy: return .green
        case .needsAttention: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .healthy: return "checkmark.circle.fill"
        case .needsAttention: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}
