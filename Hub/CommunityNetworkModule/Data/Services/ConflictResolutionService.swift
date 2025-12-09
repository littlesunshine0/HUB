//
//  ConflictResolutionService.swift
//  Hub
//
//  Handles concurrent data editing conflicts across multiple users
//

import Foundation
import CloudKit
import SwiftData
import Combine

/// Service for resolving data conflicts when multiple users edit simultaneously
@MainActor
class ConflictResolutionService {
    
    // MARK: - Conflict Resolution Strategies
    
    enum ResolutionStrategy {
        case lastWriteWins          // Most recent change wins
        case firstWriteWins         // First change wins, reject later changes
        case merge                  // Attempt to merge non-conflicting fields
        case userPrompt             // Ask user to resolve manually
        case versionBranching       // Create separate versions
    }
    
    enum ConflictType {
        case sameFieldModified      // Same field changed by multiple users
        case recordDeleted          // One user deleted, another modified
        case structuralConflict     // Incompatible changes (e.g., moved vs deleted)
    }
    
    // MARK: - Conflict Detection
    
    /// Detect conflicts between local and remote versions
    func detectConflicts<T: Codable>(
        local: T,
        remote: T,
        base: T?
    ) -> [ConflictType] {
        var conflicts: [ConflictType] = []
        
        // Use three-way merge if we have a common base
        if let base = base {
            // Compare local vs base and remote vs base
            // If both changed the same field differently, it's a conflict
            let localChanges = detectChanges(from: base, to: local)
            let remoteChanges = detectChanges(from: base, to: remote)
            
            let overlappingChanges = Set(localChanges).intersection(Set(remoteChanges))
            if !overlappingChanges.isEmpty {
                conflicts.append(.sameFieldModified)
            }
        }
        
        return conflicts
    }
    
    private func detectChanges<T: Codable>(from base: T, to current: T) -> [String] {
        // Serialize both to dictionaries and compare keys
        guard let baseData = try? JSONEncoder().encode(base),
              let currentData = try? JSONEncoder().encode(current),
              let baseDict = try? JSONSerialization.jsonObject(with: baseData) as? [String: Any],
              let currentDict = try? JSONSerialization.jsonObject(with: currentData) as? [String: Any] else {
            return []
        }
        
        var changedFields: [String] = []
        for (key, baseValue) in baseDict {
            if let currentValue = currentDict[key],
               !areEqual(baseValue, currentValue) {
                changedFields.append(key)
            }
        }
        
        return changedFields
    }
    
    private func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        // Simple equality check for JSON-compatible types
        if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString == rhsString
        }
        if let lhsNumber = lhs as? NSNumber, let rhsNumber = rhs as? NSNumber {
            return lhsNumber == rhsNumber
        }
        if let lhsArray = lhs as? [Any], let rhsArray = rhs as? [Any] {
            return lhsArray.count == rhsArray.count
        }
        return false
    }
    
    // MARK: - CloudKit Conflict Resolution
    
    /// Resolve CloudKit record conflicts
    func resolveCloudKitConflict(
        clientRecord: CKRecord,
        serverRecord: CKRecord,
        strategy: ResolutionStrategy = .lastWriteWins
    ) -> CKRecord {
        switch strategy {
        case .lastWriteWins:
            return resolveLastWriteWins(client: clientRecord, server: serverRecord)
            
        case .firstWriteWins:
            return serverRecord // Server record is older, keep it
            
        case .merge:
            return mergeRecords(client: clientRecord, server: serverRecord)
            
        case .userPrompt:
            // In production, this would trigger UI for user decision
            return clientRecord
            
        case .versionBranching:
            return createBranchedVersion(client: clientRecord, server: serverRecord)
        }
    }
    
    private func resolveLastWriteWins(client: CKRecord, server: CKRecord) -> CKRecord {
        // Compare modification dates
        let clientDate = client.modificationDate ?? Date.distantPast
        let serverDate = server.modificationDate ?? Date.distantPast
        
        return clientDate > serverDate ? client : server
    }
    
    private func mergeRecords(client: CKRecord, server: CKRecord) -> CKRecord {
        // Create a new record with merged fields
        let merged = client.copy() as! CKRecord
        
        // For each field in server record
        for key in server.allKeys() {
            // If client doesn't have this field, add it from server
            if client[key] == nil {
                merged[key] = server[key]
            }
            // If both have the field, prefer newer modification
            else if let clientDate = client.modificationDate,
                    let serverDate = server.modificationDate,
                    serverDate > clientDate {
                merged[key] = server[key]
            }
        }
        
        return merged
    }
    
    private func createBranchedVersion(client: CKRecord, server: CKRecord) -> CKRecord {
        // Create a new record ID for the branch
        let branchID = CKRecord.ID(
            recordName: "\(client.recordID.recordName)_branch_\(UUID().uuidString)",
            zoneID: client.recordID.zoneID
        )
        
        let branch = CKRecord(recordType: client.recordType, recordID: branchID)
        
        // Copy all fields from client
        for key in client.allKeys() {
            branch[key] = client[key]
        }
        
        // Add metadata about the branch
        branch["originalRecordID"] = client.recordID.recordName as CKRecordValue
        branch["branchReason"] = "Conflict with server version" as CKRecordValue
        
        return branch
    }
    
    // MARK: - SwiftData Conflict Resolution
    
    /// Resolve conflicts in SwiftData models
    func resolveSwiftDataConflict<T: PersistentModel>(
        local: T,
        remote: T,
        modelContext: ModelContext,
        strategy: ResolutionStrategy = .lastWriteWins
    ) throws {
        switch strategy {
        case .lastWriteWins:
            // Delete local, insert remote
            modelContext.delete(local)
            modelContext.insert(remote)
            
        case .firstWriteWins:
            // Keep local, ignore remote
            break
            
        case .merge:
            // Merge fields (requires custom logic per model type)
            try mergeSwiftDataModels(local: local, remote: remote, context: modelContext)
            
        case .userPrompt:
            // Store both versions temporarily for user decision
            modelContext.insert(remote)
            
        case .versionBranching:
            // Keep both as separate versions
            modelContext.insert(remote)
        }
        
        try modelContext.save()
    }
    
    private func mergeSwiftDataModels<T: PersistentModel>(
        local: T,
        remote: T,
        context: ModelContext
    ) throws {
        // This would need custom logic per model type
        // For now, use last-write-wins as fallback
        context.delete(local)
        context.insert(remote)
    }
    
    // MARK: - Optimistic Locking
    
    /// Version-based optimistic locking
    struct VersionedData<T: Codable>: Codable {
        let data: T
        let version: Int
        let lastModified: Date
        let modifiedBy: String
    }
    
    /// Attempt to save with version check
    func saveWithVersionCheck<T: Codable>(
        data: T,
        currentVersion: Int,
        identifier: String
    ) async throws -> VersionedData<T> {
        // Fetch latest version from server
        let latestVersion = try await fetchLatestVersion(identifier: identifier)
        
        // Check if version matches
        guard latestVersion == currentVersion else {
            throw ConflictError.versionMismatch(
                expected: currentVersion,
                actual: latestVersion
            )
        }
        
        // Save with incremented version
        let newVersion = VersionedData(
            data: data,
            version: currentVersion + 1,
            lastModified: Date(),
            modifiedBy: getCurrentUserID()
        )
        
        try await saveVersionedData(newVersion, identifier: identifier)
        
        return newVersion
    }
    
    private func fetchLatestVersion(identifier: String) async throws -> Int {
        // In production, fetch from CloudKit or server
        return 1
    }
    
    private func saveVersionedData<T: Codable>(
        _ data: VersionedData<T>,
        identifier: String
    ) async throws {
        // In production, save to CloudKit or server
    }
    
    private func getCurrentUserID() -> String {
        // In production, get from authentication system
        return "user_\(UUID().uuidString)"
    }
    
    // MARK: - Operational Transform (for real-time collaboration)
    
    /// Apply operational transforms for concurrent text editing
    struct Operation: Codable {
        enum OperationType: String, Codable {
            case insert
            case delete
            case retain
        }
        
        let type: OperationType
        var position: Int
        let content: String?
        let length: Int?
        let timestamp: Date
        let userID: String
    }
    
    /// Transform operations to resolve conflicts
    func transformOperations(
        _ op1: Operation,
        _ op2: Operation
    ) -> (Operation, Operation) {
        // Operational Transform algorithm
        // This is simplified - production would use full OT implementation
        
        if op1.position < op2.position {
            return (op1, op2)
        } else if op1.position > op2.position {
            var transformed1 = op1
            if op2.type == .insert {
                transformed1.position += op2.content?.count ?? 0
            } else if op2.type == .delete {
                transformed1.position -= op2.length ?? 0
            }
            return (transformed1, op2)
        } else {
            // Same position - use timestamp to determine order
            if op1.timestamp < op2.timestamp {
                return (op1, op2)
            } else {
                return (op2, op1)
            }
        }
    }
    
    // MARK: - Conflict Notification
    
    /// Notify user of conflicts
    func notifyConflict(
        type: ConflictType,
        localVersion: String,
        remoteVersion: String
    ) {
        NotificationCenter.default.post(
            name: .dataConflictDetected,
            object: nil,
            userInfo: [
                "conflictType": type,
                "localVersion": localVersion,
                "remoteVersion": remoteVersion
            ]
        )
    }
}

// MARK: - Errors

enum ConflictError: LocalizedError {
    case versionMismatch(expected: Int, actual: Int)
    case unresolvableConflict
    case mergeFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .versionMismatch(let expected, let actual):
            return "Version mismatch: expected \(expected), got \(actual)"
        case .unresolvableConflict:
            return "Unable to automatically resolve conflict"
        case .mergeFailure(let reason):
            return "Merge failed: \(reason)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let dataConflictDetected = Notification.Name("dataConflictDetected")
}
