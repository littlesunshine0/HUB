//
//  HubCRDTAdapter.swift
//  Hub
//
//  Adapter to connect CRDT sync with existing SwiftData models
//

import Foundation
import SwiftData
import Combine

/// Adapter that bridges CRDT documents with SwiftData AppHub models
@MainActor
class HubCRDTAdapter: ObservableObject {
    
     let syncService: CRDTSyncService
    private let modelContext: ModelContext
    private var documentToHubMapping: [UUID: UUID] = [:] // CRDT doc ID -> Hub ID
    
    @Published var isSyncEnabled: Bool = false
    @Published var syncStatus: SyncStatus = .disconnected
    
    enum SyncStatus {
        case disconnected
        case connecting
        case connected(peers: Int)
        case syncing
        case error(String)
    }
    
    init(modelContext: ModelContext, syncService: CRDTSyncService? = nil) {
        self.modelContext = modelContext
        self.syncService = syncService ?? CRDTSyncService()
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe CRDT document changes
        Task {
            for await _ in Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().values {
                await self.syncCRDTToSwiftData()
            }
        }
    }
    
    // MARK: - Enable/Disable Sync
    
    func enableSync() {
        syncService.startListening()
        isSyncEnabled = true
        syncStatus = .connecting
        
        // Convert existing hubs to CRDT documents
        Task {
            await exportHubsToCRDT()
        }
    }
    
    func disableSync() {
        syncService.stopListening()
        isSyncEnabled = false
        syncStatus = .disconnected
    }
    
    func connectToPeer(host: String, port: Int) {
        syncService.connectToPeer(host: host, port: port)
        syncStatus = .connecting
    }
    
    // MARK: - Export Hubs to CRDT
    
    private func exportHubsToCRDT() async {
        let descriptor = FetchDescriptor<AppHub>()
        guard let hubs = try? modelContext.fetch(descriptor) else { return }
        
        for hub in hubs {
            let crdtDoc = convertHubToCRDT(hub)
            syncService.documents[crdtDoc.id] = crdtDoc
            documentToHubMapping[crdtDoc.id] = hub.id
        }
    }
    
    private func convertHubToCRDT(_ hub: AppHub) -> CRDTSyncService.CRDTDocument {
        let replicaID = syncService.replicaID
        
        var doc = CRDTSyncService.CRDTDocument(
            id: UUID(),
            name: hub.name,
            replicaID: replicaID
        )
        
        doc.description.set(hub.details, replicaID: replicaID)
        
        // Add category and template as tags
        _ = doc.tags.add(hub.category.rawValue)
        _ = doc.tags.add(hub.templateName)
        
        return doc
    }
    
    // MARK: - Sync CRDT to SwiftData
    
    private func syncCRDTToSwiftData() async {
        guard isSyncEnabled else { return }
        
        syncStatus = .syncing
        
        for (crdtDocID, crdtDoc) in syncService.documents {
            if let hubID = documentToHubMapping[crdtDocID] {
                // Update existing hub
                await updateExistingHub(hubID: hubID, from: crdtDoc)
            } else {
                // Create new hub from CRDT document
                await createHubFromCRDT(crdtDoc)
                documentToHubMapping[crdtDocID] = crdtDoc.id
            }
        }
        
        let peerCount = syncService.connectedPeers.count
        syncStatus = peerCount > 0 ? .connected(peers: peerCount) : .disconnected
    }
    
    private func updateExistingHub(hubID: UUID, from crdtDoc: CRDTSyncService.CRDTDocument) async {
        let descriptor = FetchDescriptor<AppHub>(
            predicate: #Predicate { $0.id == hubID }
        )
        
        guard let hubs = try? modelContext.fetch(descriptor),
              let hub = hubs.first else { return }
        
        // Update hub properties from CRDT
        hub.name = crdtDoc.name.value
        hub.details = crdtDoc.description.value
        hub.updatedAt = crdtDoc.updatedAt
        
        try? modelContext.save()
    }
    
    private func createHubFromCRDT(_ crdtDoc: CRDTSyncService.CRDTDocument) async {
        // Extract category from tags if available
        let categoryTag = crdtDoc.tags.allElements.first { tag in
            HubCategory.allCases.contains { $0.rawValue == tag }
        }
        let category = categoryTag.flatMap { HubCategory(rawValue: $0) } ?? .productivity
        
        let hub = AppHub(
            name: crdtDoc.name.value,
            description: crdtDoc.description.value,
            icon: "square.stack.3d.up",
            category: category,
            templateID: UUID(),
            templateName: "Custom",
            userID: "crdt-sync"
        )
        
        modelContext.insert(hub)
        try? modelContext.save()
    }
    
    // MARK: - Hub Operations with CRDT Sync
    
    func createHub(name: String, description: String, category: HubCategory = .productivity) -> AppHub {
        // Create in SwiftData
        let hub = AppHub(
            name: name,
            description: description,
            icon: "square.stack.3d.up",
            category: category,
            templateID: UUID(),
            templateName: "Custom",
            userID: "local-user"
        )
        modelContext.insert(hub)
        try? modelContext.save()
        
        // Create in CRDT if sync enabled
        if isSyncEnabled {
            let crdtDoc = convertHubToCRDT(hub)
            syncService.documents[crdtDoc.id] = crdtDoc
            documentToHubMapping[crdtDoc.id] = hub.id
        }
        
        return hub
    }
    
    func updateHub(_ hub: AppHub, name: String? = nil, description: String? = nil) {
        // Update SwiftData
        if let name = name {
            hub.name = name
        }
        if let description = description {
            hub.details = description
        }
        hub.updatedAt = Date()
        try? modelContext.save()
        
        // Update CRDT if sync enabled
        if isSyncEnabled, let crdtDocID = documentToHubMapping.first(where: { $0.value == hub.id })?.key {
            if let name = name {
                syncService.updateDocumentName(crdtDocID, name: name)
            }
        }
    }
    
    func deleteHub(_ hub: AppHub) {
        // Delete from SwiftData
        modelContext.delete(hub)
        try? modelContext.save()
        
        // Remove from CRDT mapping
        if let crdtDocID = documentToHubMapping.first(where: { $0.value == hub.id })?.key {
            documentToHubMapping.removeValue(forKey: crdtDocID)
            syncService.documents.removeValue(forKey: crdtDocID)
        }
    }
}


