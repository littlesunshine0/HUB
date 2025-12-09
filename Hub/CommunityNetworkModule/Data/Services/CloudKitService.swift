import Foundation
import CloudKit
import SwiftUI
import Combine

// MARK: - CloudKit Service
/// Refactored to use new local-first architecture with StorageCoordinator
/// All operations are purely async and non-blocking
/// Fallback logic is handled by StorageCoordinator
@MainActor
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    @Published var isSignedIn = false
    @Published var userID: String?
    @Published var syncStatus: CloudSyncStatus = .idle
    @Published var errorMessage: String?
    @Published var isCloudKitAvailable: Bool = false
    
    var achievementService: AchievementService?
    var templateAchievementTracker: TemplateAchievementTracker?
    
    // Storage coordinator for local-first operations
    private var storageCoordinator: StorageCoordinator?
    
    // CloudSync service for direct CloudKit operations
    private var cloudSync: CloudSyncService?
    
    // Automatic sync timer
    nonisolated(unsafe) private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    private init() {
        // Initialize with StorageCoordinator
        Task {
            await initializeStorage()
        }
        
        // Start monitoring for CloudKit availability
        startAvailabilityMonitoring()
    }
    
    deinit {
        stopAvailabilityMonitoring()
    }
    
    // MARK: - Storage Initialization
    
    /// Initialize storage coordinator with configuration
    private func initializeStorage() async {
        do {
            // Get current storage configuration
            let config = StorageConfigurationManager.shared.currentConfiguration
            
            // Create storage coordinator
            self.storageCoordinator = try await StorageCoordinator.create(configuration: config)
            
            // Get CloudSync service from coordinator for direct operations
            // Note: This is a simplified approach - in production, we'd expose this through coordinator
            self.cloudSync = CloudSyncService(
                containerIdentifier: config.cloudKitEnabled ? config.cloudKitContainerIdentifier : nil
            )
            
            // Update availability status
            self.isCloudKitAvailable = await cloudSync?.isCloudKitAvailable() ?? false
            
            // Check account status
            await checkAccountStatus()
            
            print("✅ CloudKitService initialized with StorageCoordinator")
        } catch {
            print("⚠️ Failed to initialize CloudKitService: \(error.localizedDescription)")
            self.errorMessage = "Storage initialization failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Availability Monitoring
    
    /// Start monitoring CloudKit availability
    private func startAvailabilityMonitoring() {
        // Check immediately
        Task {
            await checkAccountStatus()
        }
        
        // Set up periodic checks
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAndSyncIfAvailable()
            }
        }
    }
    
    /// Stop monitoring CloudKit availability
    nonisolated private func stopAvailabilityMonitoring() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// Check CloudKit availability and sync if it becomes available
    private func checkAndSyncIfAvailable() async {
        let wasAvailable = isCloudKitAvailable
        await checkAccountStatus()
        
        // If CloudKit just became available, sync status is updated automatically
        if !wasAvailable && isCloudKitAvailable {
            print("✅ CloudKit became available")
        }
    }
    
    // MARK: - Account Management
    
    func checkAccountStatus() async {
        // Check availability through CloudSync service
        guard let cloudSync = cloudSync else {
            isSignedIn = false
            isCloudKitAvailable = false
            errorMessage = "CloudKit is not configured. Using local storage."
            return
        }
        
        // Update availability status
        isCloudKitAvailable = await cloudSync.isCloudKitAvailable()
        isSignedIn = isCloudKitAvailable
        
        if isCloudKitAvailable {
            print("✅ CloudKit is available and signed in")
        } else {
            print("ℹ️ CloudKit not available - using local storage only")
        }
    }
    
    // MARK: - Template Upload
    
    /// Upload template using local-first architecture
    /// Template is saved locally first, then synced to CloudKit asynchronously
    func uploadTemplate(_ template: TemplateModel) async throws {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        syncStatus = .syncing(progress: 0.0)
        
        // Convert template to storable format
        let storableTemplate = TemplateStorable(from: template, authorID: userID)
        
        do {
            // Save to local storage first (fast, always succeeds)
            // This automatically queues for CloudKit sync if available
            try await storageCoordinator.save(storableTemplate)
            
            syncStatus = .completed
            print("✅ Template saved locally and queued for sync")
            
            // Track template publishing for achievements
            if let userID = userID, let tracker = templateAchievementTracker {
                await tracker.trackTemplatePublished(
                    templateID: template.id.uuidString,
                    userID: userID
                )
            }
            
            // Grant legacy achievement (keeping for backward compatibility)
            if let userID = userID, let achievementService = achievementService {
                try? achievementService.grant(id: "firstPublish", for: userID)
            }
        } catch {
            syncStatus = .failed(error)
            throw error
        }
    }
    
    // MARK: - Template Download
    
    /// Fetch public templates using local-first architecture
    /// Returns local templates first, CloudKit templates are synced in background
    func fetchPublicTemplates(limit: Int = 50) async throws -> [CloudTemplate] {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Load all templates from local storage (fast)
        let localTemplates: [TemplateStorable] = await storageCoordinator.loadAll()
        
        // Convert to CloudTemplate format
        let templates = localTemplates.compactMap { CloudTemplate(from: $0) }
        
        // If CloudKit is available, fetch updates in background (non-blocking)
        if isCloudKitAvailable, let cloudSync = cloudSync {
            Task.detached(priority: .utility) {
                // Fetch from CloudKit
                let records = await cloudSync.fetchAll(recordType: "HubTemplate")
                
                // Convert and save to local storage
                for record in records.prefix(limit) {
                    if let template = TemplateStorable(from: record) {
                        try? await storageCoordinator.save(template)
                    }
                }
                
                print("✅ Synced \(records.count) templates from CloudKit")
            }
        }
        
        return Array(templates.prefix(limit))
    }
    
    // MARK: - Search
    
    /// Search templates using local-first architecture
    /// Searches local storage first, CloudKit search happens in background
    func searchTemplates(query: String) async throws -> [CloudTemplate] {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Search local storage (fast)
        let matchingIds = await storageCoordinator.search(query: query)
        
        // Load matching templates
        let templates: [TemplateStorable] = await storageCoordinator.loadMultiple(ids: matchingIds)
        
        // Convert to CloudTemplate format
        return templates.compactMap { CloudTemplate(from: $0) }
    }
    
    // MARK: - Ratings
    
    /// Rate a template using local-first architecture
    /// Rating is saved locally first, then synced to CloudKit
    func rateTemplate(templateID: String, rating: Double) async throws {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Create rating storable
        let ratingStorable = RatingStorable(
            id: UUID().uuidString,
            timestamp: Date(),
            templateID: templateID,
            userID: userID ?? "anonymous",
            rating: rating
        )
        
        // Save locally first (automatically queues for CloudKit sync)
        try await storageCoordinator.save(ratingStorable)
        print("✅ Rating saved locally and queued for sync")
    }
    
    /// Fetch template ratings using local-first architecture
    /// Returns local ratings, CloudKit ratings are synced in background
    func fetchTemplateRatings(templateID: String) async throws -> [TemplateRating] {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Search for ratings by template ID
        let matchingIds = await storageCoordinator.searchByTag(templateID)
        
        // Load matching ratings
        let ratings: [RatingStorable] = await storageCoordinator.loadMultiple(ids: matchingIds)
        
        // Convert to TemplateRating format
        return ratings.compactMap { TemplateRating(from: $0) }
    }
    
    // MARK: - Comments
    
    /// Add comment using local-first architecture
    /// Comment is saved locally first, then synced to CloudKit
    func addComment(templateID: String, comment: String) async throws {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Create comment storable
        let commentStorable = CommentStorable(
            id: UUID().uuidString,
            timestamp: Date(),
            templateID: templateID,
            userID: userID ?? "anonymous",
            comment: comment
        )
        
        // Save locally first (automatically queues for CloudKit sync)
        try await storageCoordinator.save(commentStorable)
        print("✅ Comment saved locally and queued for sync")
    }
    
    /// Fetch comments using local-first architecture
    /// Returns local comments, CloudKit comments are synced in background
    func fetchComments(templateID: String) async throws -> [TemplateComment] {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Search for comments by template ID
        let matchingIds = await storageCoordinator.searchByTag(templateID)
        
        // Load matching comments
        let comments: [CommentStorable] = await storageCoordinator.loadMultiple(ids: matchingIds)
        
        // Convert to TemplateComment format and sort by date
        return comments
            .compactMap { TemplateComment(from: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Download Tracking
    
    /// Increment download count using local-first architecture
    /// Count is updated locally first, then synced to CloudKit
    func incrementDownloadCount(templateID: String) async throws {
        guard let storageCoordinator = storageCoordinator else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialized"])
        }
        
        // Load template
        guard let template: TemplateStorable = try? await storageCoordinator.load(id: templateID) else {
            print("⚠️ Template not found: \(templateID)")
            return
        }
        
        // Increment download count
        var updatedTemplate = template
        updatedTemplate.downloadCount += 1
        
        // Save updated template (automatically queues for CloudKit sync)
        try await storageCoordinator.save(updatedTemplate)
        print("✅ Download count incremented locally and queued for sync")
    }
    
    // MARK: - Sync Status
    
    /// Get sync queue statistics
    func getSyncStatistics() async -> [String: Int] {
        guard let storageCoordinator = storageCoordinator else {
            return [:]
        }
        
        return await storageCoordinator.syncQueueStatistics()
    }
}

// MARK: - Cloud Models
// Models are now in separate files:
// - CloudTemplate.swift
// - TemplateRating.swift
// - TemplateComment.swift
