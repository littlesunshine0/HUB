import SwiftUI
import SwiftData
import Combine

// MARK: - CloudKit Service Enhanced Demo

/// Demonstrates the enhanced CloudKitService with local fallback capabilities
/// This shows how the service automatically falls back to local content when CloudKit is unavailable

struct CloudKitServiceEnhancedDemo: View {
    @StateObject private var cloudKitService = CloudKitService.shared
    @StateObject private var localMarketplaceService = LocalMarketplaceService.shared
    @Environment(\.modelContext) private var modelContext
    
    @State private var demoStatus: String = "Ready"
    @State private var templates: [MarketplaceItem] = []
    @State private var searchQuery: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Section
                    statusSection
                    
                    Divider()
                    
                    // Configuration Section
                    configurationSection
                    
                    Divider()
                    
                    // Demo Actions
                    demoActionsSection
                    
                    Divider()
                    
                    // Search Section
                    searchSection
                    
                    Divider()
                    
                    // Results Section
                    resultsSection
                }
                .padding()
            }
            .navigationTitle("CloudKit Enhanced Demo")
            .task {
                await setupDemo()
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Status")
                .font(.headline)
            
            HStack {
                Image(systemName: cloudKitService.isCloudKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(cloudKitService.isCloudKitAvailable ? .green : .red)
                Text("CloudKit: \(cloudKitService.isCloudKitAvailable ? "Available" : "Unavailable")")
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Local-First: Always Enabled")
            }
            
            HStack {
                Image(systemName: localMarketplaceService.contentSource.icon)
                    .foregroundColor(.blue)
                Text("Content Source: \(localMarketplaceService.contentSource.displayName)")
            }
            
            Text("Status: \(demoStatus)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
            
            Text("Local-first architecture is always enabled")
                .font(.body)
            
            Text("All operations use local storage first, with automatic CloudKit sync in the background")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Demo Actions
    
    private var demoActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demo Actions")
                .font(.headline)
            
            Button("Check CloudKit Status") {
                Task {
                    demoStatus = "Checking CloudKit status..."
                    await cloudKitService.checkAccountStatus()
                    demoStatus = cloudKitService.isCloudKitAvailable ? "CloudKit is available" : "CloudKit is unavailable - using local fallback"
                }
            }
            .buttonStyle(.bordered)
            
            Button("Load Local Content") {
                Task {
                    demoStatus = "Loading local content..."
                    await localMarketplaceService.loadLocalContent()
                    templates = localMarketplaceService.getAllContent()
                    demoStatus = "Loaded \(templates.count) local templates"
                }
            }
            .buttonStyle(.bordered)
            
            Button("Check Sync Status") {
                Task {
                    demoStatus = "Checking sync status..."
                    let stats = await cloudKitService.getSyncStatistics()
                    templates = localMarketplaceService.getAllContent()
                    demoStatus = "Sync queue: \(stats["queueDepth"] ?? 0) pending, \(stats["totalProcessed"] ?? 0) processed"
                }
            }
            .buttonStyle(.bordered)
            
            Button("Simulate CloudKit Unavailable") {
                demoStatus = "Simulating CloudKit unavailable..."
                // In real scenario, CloudKit would be unavailable
                // The service automatically falls back to local content
                Task {
                    await localMarketplaceService.loadLocalContent()
                    templates = localMarketplaceService.getAllContent()
                    demoStatus = "Using local fallback - \(templates.count) templates available"
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search")
                .font(.headline)
            
            HStack {
                TextField("Search templates...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                
                Button("Search") {
                    performSearch()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("Search works in both cloud and local modes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results (\(templates.count))")
                .font(.headline)
            
            if templates.isEmpty {
                Text("No templates found. Try loading local content or syncing with cloud.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(templates) { item in
                    templateRow(item)
                }
            }
        }
    }
    
    private func templateRow(_ item: MarketplaceItem) -> some View {
        HStack {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(item.downloadCount)", systemImage: "arrow.down.circle")
                    Label(String(format: "%.1f", item.rating), systemImage: "star.fill")
                    
                    Spacer()
                    
                    // Source indicator
                    HStack(spacing: 4) {
                        Image(systemName: item.source.icon)
                        Text(item.source.displayName)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func setupDemo() async {
        // Configure services
        localMarketplaceService.configure(with: modelContext)
        
        // Check initial status
        await cloudKitService.checkAccountStatus()
        await localMarketplaceService.loadLocalContent()
        
        templates = localMarketplaceService.getAllContent()
        demoStatus = "Demo ready - \(templates.count) local templates available (local-first mode)"
    }
    
    private func performSearch() {
        if searchQuery.isEmpty {
            templates = localMarketplaceService.getAllContent()
            demoStatus = "Showing all templates"
        } else {
            templates = localMarketplaceService.searchLocal(query: searchQuery)
            demoStatus = "Found \(templates.count) templates matching '\(searchQuery)'"
        }
    }
}

// MARK: - Usage Examples

/*
 
 EXAMPLE 1: Basic Setup with Local Fallback
 ==========================================
 
 ```swift
 @StateObject private var cloudKitService = CloudKitService.shared
 @StateObject private var localMarketplaceService = LocalMarketplaceService.shared
 @Environment(\.modelContext) private var modelContext
 
 // In your view's task or onAppear:
 localMarketplaceService.configure(with: modelContext)
 cloudKitService.configureLocalFallback(localMarketplaceService)
 
 // Check CloudKit availability
 await cloudKitService.checkAccountStatus()
 
 // Load content (automatically uses local if CloudKit unavailable)
 await localMarketplaceService.loadLocalContent()
 ```
 
 EXAMPLE 2: Uploading Templates with Automatic Fallback
 ======================================================
 
 ```swift
 // Upload template - automatically stores locally if CloudKit unavailable
 do {
     try await cloudKitService.uploadTemplate(myTemplate)
     print("Template uploaded (cloud or local)")
 } catch {
     print("Upload failed: \(error)")
 }
 ```
 
 EXAMPLE 3: Searching with Automatic Fallback
 ============================================
 
 ```swift
 // Search - automatically uses local search if CloudKit unavailable
 let cloudResults = try? await cloudKitService.searchTemplates(query: "auth")
 let localResults = localMarketplaceService.searchLocal(query: "auth")
 
 // Combine results in hybrid mode
 let allResults = (cloudResults ?? []) + localResults
 ```
 
 EXAMPLE 4: Syncing When CloudKit Becomes Available
 ==================================================
 
 ```swift
 // Monitor CloudKit availability
 if cloudKitService.isCloudKitAvailable {
     // Sync local content with cloud
     await cloudKitService.syncWhenAvailable()
     print("Content synced with CloudKit")
 } else {
     print("Using local content only")
 }
 ```
 
 EXAMPLE 5: Handling Offline to Online Transition
 ================================================
 
 ```swift
 // When app comes to foreground or network changes
 await cloudKitService.checkAccountStatus()
 
 if cloudKitService.isCloudKitAvailable {
     // CloudKit became available - sync
     try? await localMarketplaceService.syncWithCloud()
     
     // Content source automatically switches to hybrid
     print("Content source: \(localMarketplaceService.contentSource)")
 }
 ```
 
 EXAMPLE 6: Disabling Local Fallback (Cloud-Only Mode)
 =====================================================
 
 ```swift
 // Disable local fallback to require CloudKit
 cloudKitService.setLocalFallback(enabled: false)
 
 // Now operations will throw errors if CloudKit is unavailable
 do {
     try await cloudKitService.uploadTemplate(template)
 } catch {
     // Handle CloudKit unavailable error
     print("CloudKit required but unavailable")
 }
 ```
 
 KEY FEATURES:
 =============
 
 1. Automatic Fallback
    - Service automatically detects CloudKit availability
    - Falls back to local content without user intervention
    - Seamless experience for users
 
 2. Hybrid Mode
    - When CloudKit becomes available, merges cloud and local content
    - Avoids duplicates
    - Provides best of both worlds
 
 3. Sync Mechanism
    - Automatic sync when CloudKit becomes available
    - Manual sync option for user control
    - Conflict resolution (cloud takes precedence)
 
 4. Graceful Degradation
    - All operations work in local-only mode
    - Ratings, comments, downloads tracked locally
    - Can sync to cloud later when available
 
 5. Configuration Options
    - Enable/disable local fallback
    - Configure sync behavior
    - Monitor availability status
 
 */

#Preview {
    CloudKitServiceEnhancedDemo()
        .modelContainer(for: [TemplateModel.self])
}
