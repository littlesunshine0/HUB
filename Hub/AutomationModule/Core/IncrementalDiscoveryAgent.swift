//
//  IncrementalDiscoveryAgent.swift
//  Hub
//
//  Gentle, incremental asset discovery with AI-powered insights
//  Discovers project assets gradually without blocking or spamming
//

import Foundation
import SwiftUI
import Combine

@MainActor
class IncrementalDiscoveryAgent: ObservableObject {
    static let shared = IncrementalDiscoveryAgent()
    
    @Published var isDiscovering = false
    @Published var discoveredAssets: [DiscoveredAsset] = []
    @Published var pendingNotifications: [DiscoveryNotification] = []
    @Published var stats: DiscoveryStats = DiscoveryStats()
    
    private var discoveryTask: Task<Void, Never>?
    private var fileQueue: [String] = []
    private var processedFiles: Set<String> = []
    private var interestingFindings: [DiscoveredAsset] = []
    
    // Configuration
    private var filesPerMinute: Int = 2
    private var batchSize: Int = 5
    private var notificationThreshold: InterestLevel = .interesting
    
    private let fileManager = FileManager.default
    private let entityExtractor = EntityExtractor()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Start gentle background discovery
    func startGentleDiscovery(
        filesPerMinute: Int = 2,
        batchSize: Int = 5,
        notificationThreshold: InterestLevel = .interesting
    ) async {
        guard !isDiscovering else { return }
        
        self.filesPerMinute = filesPerMinute
        self.batchSize = batchSize
        self.notificationThreshold = notificationThreshold
        
        isDiscovering = true
        print("🔍 Starting gentle discovery: \(filesPerMinute) files/min")
        
        // Build initial file queue
        await buildFileQueue()
        
        // Start discovery loop
        discoveryTask = Task {
            await discoveryLoop()
        }
    }
    
    /// Stop discovery
    func stopDiscovery() {
        discoveryTask?.cancel()
        isDiscovering = false
        print("⏸️ Discovery paused")
    }
    
    /// Get summary of discoveries
    func getSummary() -> String {
        let total = discoveredAssets.count
        let interesting = discoveredAssets.filter { $0.interestLevel >= .interesting }.count
        return "Discovered \(total) assets (\(interesting) interesting)"
    }
    
    // MARK: - Discovery Loop
    
    private func discoveryLoop() async {
        let delayBetweenFiles = 60.0 / Double(filesPerMinute) // seconds
        
        while !Task.isCancelled && isDiscovering {
            // Process next file
            if let file = fileQueue.first {
                fileQueue.removeFirst()
                await processFile(file)
                stats.filesProcessed += 1
            } else {
                // Queue empty, rebuild
                await buildFileQueue()
                if fileQueue.isEmpty {
                    print("✅ Discovery complete - all files processed")
                    isDiscovering = false
                    break
                }
            }
            
            // Check if we should send notifications
            await checkAndSendNotifications()
            
            // Wait before next file
            try? await Task.sleep(nanoseconds: UInt64(delayBetweenFiles * 1_000_000_000))
        }
    }
    
    // MARK: - File Processing
    
    private func buildFileQueue() async {
        print("📋 Building file queue...")
        
        var files: [String] = []
        
        // Prioritize user's active work
        files += findFiles(withExtension: ".swift", in: "Hub", limit: 50)
        files += findFiles(withExtension: ".json", in: "Hub", limit: 20)
        files += findFiles(withExtension: ".md", in: ".", limit: 10)
        
        // Filter out already processed
        files = files.filter { !processedFiles.contains($0) }
        
        // Shuffle for variety
        fileQueue = files.shuffled()
        
        print("📋 Queue built: \(fileQueue.count) files")
    }
    
    private func processFile(_ path: String) async {
        guard !processedFiles.contains(path) else { return }
        processedFiles.insert(path)
        
        // Analyze file
        if let asset = await analyzeFile(path) {
            discoveredAssets.append(asset)
            
            // If interesting, add to batch
            if asset.interestLevel >= notificationThreshold {
                interestingFindings.append(asset)
                stats.interestingFound += 1
            }
        }
    }
    
    private func analyzeFile(_ path: String) async -> DiscoveredAsset? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        let ext = (path as NSString).pathExtension
        
        switch ext {
        case "swift":
            return await analyzeSwiftFile(path, content: content)
        case "json":
            return await analyzeJSONFile(path, content: content)
        case "md":
            return await analyzeMarkdownFile(path, content: content)
        default:
            return nil
        }
    }
    
    // MARK: - File Analysis
    
    private func analyzeSwiftFile(_ path: String, content: String) async -> DiscoveredAsset? {
        var suggestions: [String] = []
        var interestLevel: InterestLevel = .mundane
        
        // Check for reusable components
        if content.contains("struct") && content.contains(": View") {
            suggestions.append("Could be extracted as a reusable component")
            interestLevel = .interesting
        }
        
        // Check for color definitions
        if content.contains("Color(") || content.contains("UIColor(") {
            suggestions.append("Contains color definitions - add to design system?")
            interestLevel = .interesting
        }
        
        // Check for API patterns
        if content.contains("URLSession") || content.contains("async") {
            suggestions.append("Contains networking code - could be a service module")
            interestLevel = .useful
        }
        
        guard !suggestions.isEmpty else { return nil }
        
        return DiscoveredAsset(
            path: path,
            type: DiscoveredAssetType.component,
            interestLevel: interestLevel,
            suggestions: suggestions,
            metadata: ["language": "Swift"]
        )
    }
    
    private func analyzeJSONFile(_ path: String, content: String) async -> DiscoveredAsset? {
        // Check if it's a package manifest
        if path.contains("Package.swift") || content.contains("\"dependencies\"") {
            return DiscoveredAsset(
                path: path,
                type: DiscoveredAssetType.package,
                interestLevel: InterestLevel.veryInteresting,
                suggestions: ["Swift Package detected - convert to Hub?"],
                metadata: ["format": "SPM"]
            )
        }
        
        // Check for configuration
        if content.contains("\"version\"") || content.contains("\"config\"") {
            return DiscoveredAsset(
                path: path,
                type: DiscoveredAssetType.configuration,
                interestLevel: InterestLevel.useful,
                suggestions: ["Configuration file - could be managed in settings"],
                metadata: ["format": "JSON"]
            )
        }
        
        return nil
    }
    
    private func analyzeMarkdownFile(_ path: String, content: String) async -> DiscoveredAsset? {
        let filename = (path as NSString).lastPathComponent.lowercased()
        
        // Check for documentation
        if filename.contains("readme") || filename.contains("doc") {
            return DiscoveredAsset(
                path: path,
                type: DiscoveredAssetType.documentation,
                interestLevel: InterestLevel.useful,
                suggestions: ["Documentation found - add to knowledge base?"],
                metadata: ["type": "README"]
            )
        }
        
        return nil
    }
    
    // MARK: - Notifications
    
    private func checkAndSendNotifications() async {
        guard interestingFindings.count >= batchSize else { return }
        
        // Create batched notification
        let notification = DiscoveryNotification(
            title: "🎨 Discovered \(interestingFindings.count) interesting assets",
            message: createNotificationMessage(),
            assets: interestingFindings,
            timestamp: Date()
        )
        
        pendingNotifications.append(notification)
        stats.notificationsSent += 1
        
        // Send to notification system
        await sendNotification(notification)
        
        // Clear batch
        interestingFindings.removeAll()
    }
    
    private func createNotificationMessage() -> String {
        let types = Dictionary(grouping: interestingFindings, by: { $0.type })
        var parts: [String] = []
        
        for (type, assets) in types {
            parts.append("\(assets.count) \(type.rawValue)s")
        }
        
        return parts.joined(separator: ", ")
    }
    
    private func sendNotification(_ notification: DiscoveryNotification) async {
        // TODO: Integrate with NotificationModule
        print("📬 \(notification.title): \(notification.message)")
    }
    
    // MARK: - Helpers
    
    private func findFiles(withExtension ext: String, in directory: String, limit: Int = 100) -> [String] {
        var files: [String] = []
        
        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            return files
        }
        
        for case let file as String in enumerator {
            if file.hasSuffix(ext) && !file.contains(".build") && !file.contains("DerivedData") {
                files.append("\(directory)/\(file)")
                if files.count >= limit { break }
            }
        }
        
        return files
    }
}

// MARK: - Supporting Types

struct DiscoveredAsset: Identifiable {
    let id = UUID()
    let path: String
    let type: DiscoveredAssetType
    let interestLevel: InterestLevel
    let suggestions: [String]
    let metadata: [String: String]
    let discoveredAt = Date()
}

enum DiscoveredAssetType: String {
    case component = "component"
    case package = "package"
    case configuration = "config"
    case documentation = "doc"
    case image = "image"
    case color = "color"
    case module = "module"
}

enum InterestLevel: Int, Comparable {
    case mundane = 0
    case useful = 1
    case interesting = 2
    case veryInteresting = 3
    case exceptional = 4
    
    static func < (lhs: InterestLevel, rhs: InterestLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct DiscoveryNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let assets: [DiscoveredAsset]
    let timestamp: Date
}

struct DiscoveryStats {
    var filesProcessed: Int = 0
    var interestingFound: Int = 0
    var notificationsSent: Int = 0
}
