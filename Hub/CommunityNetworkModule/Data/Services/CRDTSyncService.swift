//
//  CRDTSyncService.swift
//  Hub
//
//  CloudKit-free multi-user sync using CRDTs (Conflict-free Replicated Data Types)
//  Enables concurrent editing without central server or CloudKit dependency
//

import Foundation
import SwiftData
import Network
import Combine
/// CRDT-based sync service for conflict-free concurrent editing
/// 
/// Uses Operational Transformation and CRDTs to allow multiple users to edit
/// the same data simultaneously without conflicts. Works over local network,
/// WebSocket, or any transport layer.
@MainActor
class CRDTSyncService: ObservableObject {
    
    // MARK: - CRDT Types
    
    /// Last-Write-Wins Register (LWW-Register)
    /// Simple CRDT where the value with the latest timestamp wins
    struct LWWRegister<T: Codable>: Codable {
        var value: T
        var timestamp: Date
        var replicaID: String
        
        mutating func set(_ newValue: T, replicaID: String) {
            self.value = newValue
            self.timestamp = Date()
            self.replicaID = replicaID
        }
        
        func merge(with other: LWWRegister<T>) -> LWWRegister<T> {
            // Later timestamp wins
            if other.timestamp > self.timestamp {
                return other
            } else if other.timestamp == self.timestamp {
                // Tie-break with replica ID for deterministic ordering
                return other.replicaID > self.replicaID ? other : self
            }
            return self
        }
    }
    
    /// Grow-Only Set (G-Set)
    /// Elements can only be added, never removed
    struct GSet<T: Hashable & Codable>: Codable {
        private var elements: Set<T> = []
        
        mutating func add(_ element: T) {
            elements.insert(element)
        }
        
        func contains(_ element: T) -> Bool {
            elements.contains(element)
        }
        
        func merge(with other: GSet<T>) -> GSet<T> {
            var merged = GSet<T>()
            merged.elements = self.elements.union(other.elements)
            return merged
        }
        
        var allElements: Set<T> {
            elements
        }
    }
    
    /// Two-Phase Set (2P-Set)
    /// Elements can be added and removed, but once removed cannot be re-added
    struct TwoPhaseSet<T: Hashable & Codable>: Codable {
        private var added: GSet<T> = GSet()
        private var removed: GSet<T> = GSet()
        
        mutating func add(_ element: T) {
            added.add(element)
        }
        
        mutating func remove(_ element: T) {
            removed.add(element)
        }
        
        func contains(_ element: T) -> Bool {
            added.contains(element) && !removed.contains(element)
        }
        
        func merge(with other: TwoPhaseSet<T>) -> TwoPhaseSet<T> {
            var merged = TwoPhaseSet<T>()
            merged.added = self.added.merge(with: other.added)
            merged.removed = self.removed.merge(with: other.removed)
            return merged
        }
        
        var allElements: Set<T> {
            added.allElements.subtracting(removed.allElements)
        }
    }
    
    /// Observed-Remove Set (OR-Set)
    /// Most flexible set CRDT - elements can be added and removed multiple times
    struct ORSet<T: Hashable & Codable>: Codable {
        struct Element: Codable, Hashable {
            let value: T
            let uniqueID: UUID
        }
        
        private var elements: Set<Element> = []
        private var tombstones: Set<UUID> = []
        
        mutating func add(_ value: T) -> UUID {
            let id = UUID()
            elements.insert(Element(value: value, uniqueID: id))
            return id
        }
        
        mutating func remove(_ value: T) {
            let toRemove = elements.filter { $0.value == value }
            for element in toRemove {
                tombstones.insert(element.uniqueID)
            }
        }
        
        func contains(_ value: T) -> Bool {
            elements.contains { $0.value == value && !tombstones.contains($0.uniqueID) }
        }
        
        func merge(with other: ORSet<T>) -> ORSet<T> {
            var merged = ORSet<T>()
            merged.elements = self.elements.union(other.elements)
            merged.tombstones = self.tombstones.union(other.tombstones)
            return merged
        }
        
        var allElements: Set<T> {
            Set(elements.filter { !tombstones.contains($0.uniqueID) }.map { $0.value })
        }
    }
    
    /// Counter CRDT (G-Counter for increment-only, PN-Counter for increment/decrement)
    struct PNCounter: Codable {
        private var increments: [String: Int] = [:]
        private var decrements: [String: Int] = [:]
        
        mutating func increment(by amount: Int = 1, replicaID: String) {
            increments[replicaID, default: 0] += amount
        }
        
        mutating func decrement(by amount: Int = 1, replicaID: String) {
            decrements[replicaID, default: 0] += amount
        }
        
        var value: Int {
            let totalIncrements = increments.values.reduce(0, +)
            let totalDecrements = decrements.values.reduce(0, +)
            return totalIncrements - totalDecrements
        }
        
        func merge(with other: PNCounter) -> PNCounter {
            var merged = PNCounter()
            
            // Merge increments
            let allIncrementKeys = Set(self.increments.keys).union(other.increments.keys)
            for key in allIncrementKeys {
                merged.increments[key] = max(
                    self.increments[key] ?? 0,
                    other.increments[key] ?? 0
                )
            }
            
            // Merge decrements
            let allDecrementKeys = Set(self.decrements.keys).union(other.decrements.keys)
            for key in allDecrementKeys {
                merged.decrements[key] = max(
                    self.decrements[key] ?? 0,
                    other.decrements[key] ?? 0
                )
            }
            
            return merged
        }
    }
    
    // MARK: - CRDT Document Model
    
    /// A document that can be edited concurrently by multiple users
    struct CRDTDocument: Codable, Identifiable {
        let id: UUID
        var name: LWWRegister<String>
        var description: LWWRegister<String>
        var tags: ORSet<String>
        var collaborators: ORSet<String>
        var editCount: PNCounter
        var metadata: [String: LWWRegister<String>]
        let createdAt: Date
        var updatedAt: Date
        
        init(id: UUID = UUID(), name: String, replicaID: String) {
            self.id = id
            self.name = LWWRegister(value: name, timestamp: Date(), replicaID: replicaID)
            self.description = LWWRegister(value: "", timestamp: Date(), replicaID: replicaID)
            self.tags = ORSet()
            self.collaborators = ORSet()
            self.editCount = PNCounter()
            self.metadata = [:]
            self.createdAt = Date()
            self.updatedAt = Date()
        }
        
        func merge(with other: CRDTDocument) -> CRDTDocument {
            var merged = self
            merged.name = self.name.merge(with: other.name)
            merged.description = self.description.merge(with: other.description)
            merged.tags = self.tags.merge(with: other.tags)
            merged.collaborators = self.collaborators.merge(with: other.collaborators)
            merged.editCount = self.editCount.merge(with: other.editCount)
            
            // Merge metadata
            let allKeys = Set(self.metadata.keys).union(other.metadata.keys)
            for key in allKeys {
                if let selfValue = self.metadata[key], let otherValue = other.metadata[key] {
                    merged.metadata[key] = selfValue.merge(with: otherValue)
                } else if let value = self.metadata[key] ?? other.metadata[key] {
                    merged.metadata[key] = value
                }
            }
            
            merged.updatedAt = max(self.updatedAt, other.updatedAt)
            return merged
        }
    }
    
    // MARK: - Sync State
    
    @Published var documents: [UUID: CRDTDocument] = [:]
    @Published var isConnected: Bool = false
    @Published var connectedPeers: Set<String> = []
    
    let replicaID: String  // Made public for adapter access
    private var syncQueue: [SyncMessage] = []
    private let networkService: NetworkSyncService
    
    // MARK: - Initialization
    
    init(replicaID: String = UUID().uuidString) {
        self.replicaID = replicaID
        self.networkService = NetworkSyncService(replicaID: replicaID)
        
        setupNetworkHandlers()
    }
    
    private func setupNetworkHandlers() {
        networkService.onMessageReceived = { [weak self] message in
            await self?.handleIncomingMessage(message)
        }
        
        networkService.onPeerConnected = { [weak self] peerID in
            await self?.handlePeerConnected(peerID)
        }
        
        networkService.onPeerDisconnected = { [weak self] peerID in
            await self?.handlePeerDisconnected(peerID)
        }
    }
    
    // MARK: - Document Operations
    
    func createDocument(name: String) -> CRDTDocument {
        let doc = CRDTDocument(id: UUID(), name: name, replicaID: replicaID)
        documents[doc.id] = doc
        
        // Broadcast creation to peers
        broadcastUpdate(for: doc)
        
        return doc
    }
    
    func updateDocumentName(_ documentID: UUID, name: String) {
        guard var doc = documents[documentID] else { return }
        
        doc.name.set(name, replicaID: replicaID)
        doc.editCount.increment(replicaID: replicaID)
        doc.updatedAt = Date()
        
        documents[documentID] = doc
        broadcastUpdate(for: doc)
    }
    
    func addTag(_ documentID: UUID, tag: String) {
        guard var doc = documents[documentID] else { return }
        
        _ = doc.tags.add(tag)
        doc.editCount.increment(replicaID: replicaID)
        doc.updatedAt = Date()
        
        documents[documentID] = doc
        broadcastUpdate(for: doc)
    }
    
    func removeTag(_ documentID: UUID, tag: String) {
        guard var doc = documents[documentID] else { return }
        
        doc.tags.remove(tag)
        doc.editCount.increment(replicaID: replicaID)
        doc.updatedAt = Date()
        
        documents[documentID] = doc
        broadcastUpdate(for: doc)
    }
    
    // MARK: - Sync Operations
    
    private func broadcastUpdate(for document: CRDTDocument) {
        let message = SyncMessage(
            type: .documentUpdate,
            documentID: document.id,
            document: document,
            senderID: replicaID,
            timestamp: Date()
        )
        
        networkService.broadcast(message)
    }
    
    private func handleIncomingMessage(_ message: SyncMessage) async {
        switch message.type {
        case .documentUpdate:
            await handleDocumentUpdate(message)
        case .syncRequest:
            await handleSyncRequest(message)
        case .syncResponse:
            await handleSyncResponse(message)
        }
    }
    
    private func handleDocumentUpdate(_ message: SyncMessage) async {
        guard let incomingDoc = message.document else { return }
        
        if let existingDoc = documents[incomingDoc.id] {
            // Merge with existing document
            let merged = existingDoc.merge(with: incomingDoc)
            documents[incomingDoc.id] = merged
        } else {
            // New document
            documents[incomingDoc.id] = incomingDoc
        }
    }
    
    private func handleSyncRequest(_ message: SyncMessage) async {
        // Send all our documents to the requesting peer
        let response = SyncMessage(
            type: .syncResponse,
            documentID: nil,
            document: nil,
            senderID: replicaID,
            timestamp: Date(),
            allDocuments: Array(documents.values)
        )
        
        networkService.send(response, to: message.senderID)
    }
    
    private func handleSyncResponse(_ message: SyncMessage) async {
        guard let incomingDocs = message.allDocuments else { return }
        
        // Merge all incoming documents
        for incomingDoc in incomingDocs {
            if let existingDoc = documents[incomingDoc.id] {
                let merged = existingDoc.merge(with: incomingDoc)
                documents[incomingDoc.id] = merged
            } else {
                documents[incomingDoc.id] = incomingDoc
            }
        }
    }
    
    private func handlePeerConnected(_ peerID: String) async {
        connectedPeers.insert(peerID)
        isConnected = !connectedPeers.isEmpty
        
        // Request sync from new peer
        let syncRequest = SyncMessage(
            type: .syncRequest,
            documentID: nil,
            document: nil,
            senderID: replicaID,
            timestamp: Date()
        )
        
        networkService.send(syncRequest, to: peerID)
    }
    
    private func handlePeerDisconnected(_ peerID: String) async {
        connectedPeers.remove(peerID)
        isConnected = !connectedPeers.isEmpty
    }
    
    // MARK: - Network Control
    
    func startListening() {
        networkService.startListening()
    }
    
    func stopListening() {
        networkService.stopListening()
    }
    
    func connectToPeer(host: String, port: Int) {
        networkService.connectToPeer(host: host, port: port)
    }
    
    // MARK: - Collaborative Editing Methods
    
    /// Connect to a document for collaborative editing
    func connect(documentId: String) async throws {
        // Convert string to UUID if needed
        guard let uuid = UUID(uuidString: documentId) else {
            throw CRDTError.invalidDocumentId
        }
        
        // Start listening for connections if not already
        if !isConnected {
            startListening()
        }
        
        // Request sync for this specific document
        let syncRequest = SyncMessage(
            type: .syncRequest,
            documentID: uuid,
            document: nil,
            senderID: replicaID,
            timestamp: Date()
        )
        
        networkService.broadcast(syncRequest)
    }
    
    /// Disconnect from collaborative editing
    func disconnect() async {
        stopListening()
        connectedPeers.removeAll()
        isConnected = false
    }
    
    /// Apply a local change and broadcast to peers
    func applyLocalChange(_ change: CRDTDocumentChange) async throws {
        guard let doc = documents[change.documentId] else {
            throw CRDTError.documentNotFound
        }
        
        var updatedDoc = doc
        
        switch change.type {
        case .updateName:
            if let newName = change.newValue {
                updatedDoc.name.set(newName, replicaID: replicaID)
            }
        case .updateDescription:
            if let newDescription = change.newValue {
                updatedDoc.description.set(newDescription, replicaID: replicaID)
            }
        case .addTag:
            if let tag = change.newValue {
                _ = updatedDoc.tags.add(tag)
            }
        case .removeTag:
            if let tag = change.newValue {
                updatedDoc.tags.remove(tag)
            }
        }
        
        updatedDoc.editCount.increment(replicaID: replicaID)
        updatedDoc.updatedAt = Date()
        
        documents[change.documentId] = updatedDoc
        broadcastUpdate(for: updatedDoc)
    }
}

// MARK: - CRDT Document Change

struct CRDTDocumentChange {
    enum ChangeType {
        case updateName
        case updateDescription
        case addTag
        case removeTag
    }
    
    let documentId: UUID
    let type: ChangeType
    let newValue: String?
}

// MARK: - CRDT Errors

enum CRDTError: Error {
    case documentNotFound
    case invalidChange
    case networkError
    case invalidDocumentId
}

// MARK: - Sync Message

struct SyncMessage: Codable, Sendable {
    enum MessageType: String, Codable {
        case documentUpdate
        case syncRequest
        case syncResponse
    }
    
    let type: MessageType
    let documentID: UUID?
    let document: CRDTSyncService.CRDTDocument?
    let senderID: String
    let timestamp: Date
    var allDocuments: [CRDTSyncService.CRDTDocument]?
}

// MARK: - Network Sync Service

/// Handles network communication for CRDT sync
/// Can use Bonjour for local network discovery, WebSocket for internet, or custom transport
class NetworkSyncService {
    let replicaID: String
    private var listener: NWListener?
    private var connections: [String: NWConnection] = [:]
    
    var onMessageReceived: ((SyncMessage) async -> Void)?
    var onPeerConnected: ((String) async -> Void)?
    var onPeerDisconnected: ((String) async -> Void)?
    
    init(replicaID: String) {
        self.replicaID = replicaID
    }
    
    func startListening(port: UInt16 = 8080) {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: .main)
        } catch {
            print("Failed to start listener: \(error)")
        }
    }
    
    func stopListening() {
        listener?.cancel()
        listener = nil
        
        for connection in connections.values {
            connection.cancel()
        }
        connections.removeAll()
    }
    
    func connectToPeer(host: String, port: Int) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port))
        )
        
        let connection = NWConnection(to: endpoint, using: .tcp)
        handleNewConnection(connection)
        connection.start(queue: .main)
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        let peerID = UUID().uuidString
        connections[peerID] = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                Task { await self?.onPeerConnected?(peerID) }
                self?.receiveMessage(from: connection, peerID: peerID)
            case .failed, .cancelled:
                Task { await self?.onPeerDisconnected?(peerID) }
                self?.connections.removeValue(forKey: peerID)
            default:
                break
            }
        }
    }
    
    private func receiveMessage(from connection: NWConnection, peerID: String) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                if let message = try? JSONDecoder().decode(SyncMessage.self, from: data) {
                    Task { await self?.onMessageReceived?(message) }
                }
            }
            
            if !isComplete {
                self?.receiveMessage(from: connection, peerID: peerID)
            }
        }
    }
    
    func broadcast(_ message: SyncMessage) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        
        for connection in connections.values {
            connection.send(content: data, completion: .contentProcessed { _ in })
        }
    }
    
    func send(_ message: SyncMessage, to peerID: String) {
        guard let connection = connections[peerID],
              let data = try? JSONEncoder().encode(message) else { return }
        
        connection.send(content: data, completion: .contentProcessed { _ in })
    }
}
