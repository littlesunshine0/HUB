import Foundation
import CloudKit
import SwiftData
import Combine

// MARK: - Settings CloudKit Sync Service

@MainActor
public class SettingsCloudKitSync: ObservableObject {
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncError: Error?
    @Published public var lastSyncDate: Date?
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "AppSettings"
    
    // MARK: - Initializer
    
    nonisolated public init(containerIdentifier: String = "iCloud.com.hub.settings") {
        // Use default container if custom identifier fails
        if containerIdentifier.hasPrefix("iCloud.") {
            self.container = CKContainer(identifier: containerIdentifier)
        } else {
            self.container = CKContainer.default()
        }
        self.database = container.privateCloudDatabase
    }
    
    // MARK: - Sync Operations
    
    /// Pushes local settings to CloudKit
    func pushSettings(_ settings: AppSettings) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let record = try createRecord(from: settings)
            let savedRecord = try await database.save(record)
            
            // Update local record with CloudKit ID
            settings.cloudKitRecordID = savedRecord.recordID.recordName
            settings.lastSyncedAt = Date()
            lastSyncDate = Date()
            lastSyncError = nil
            
        } catch {
            lastSyncError = error
            throw SettingsSyncError.pushFailed(error)
        }
    }
    
    /// Pulls settings from CloudKit
    func pullSettings(for userID: String) async throws -> AppSettings? {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let predicate = NSPredicate(format: "userID == %@", userID)
            let query = CKQuery(recordType: recordType, predicate: predicate)
            
            let results = try await database.records(matching: query)
            
            guard let (_, result) = results.matchResults.first else {
                return nil
            }
            
            let record = try result.get()
            let settings = try createSettings(from: record)
            
            lastSyncDate = Date()
            lastSyncError = nil
            
            return settings
            
        } catch {
            lastSyncError = error
            throw SettingsSyncError.pullFailed(error)
        }
    }
    
    /// Syncs settings bidirectionally
    func syncSettings(_ localSettings: AppSettings) async throws -> AppSettings {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Try to fetch remote settings
            if let remoteSettings = try await pullSettings(for: localSettings.userID) {
                // Merge based on timestamps
                if remoteSettings.updatedAt > localSettings.updatedAt {
                    // Remote is newer, use it
                    return remoteSettings
                } else {
                    // Local is newer, push it
                    try await pushSettings(localSettings)
                    return localSettings
                }
            } else {
                // No remote settings, push local
                try await pushSettings(localSettings)
                return localSettings
            }
            
        } catch {
            lastSyncError = error
            throw SettingsSyncError.syncFailed(error)
        }
    }
    
    /// Deletes settings from CloudKit
    func deleteSettings(recordID: String) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let ckRecordID = CKRecord.ID(recordName: recordID)
            try await database.deleteRecord(withID: ckRecordID)
            
            lastSyncDate = Date()
            lastSyncError = nil
            
        } catch {
            lastSyncError = error
            throw SettingsSyncError.deleteFailed(error)
        }
    }
    
    // MARK: - Record Conversion
    
    private func createRecord(from settings: AppSettings) throws -> CKRecord {
        let recordID: CKRecord.ID
        if let existingID = settings.cloudKitRecordID {
            recordID = CKRecord.ID(recordName: existingID)
        } else {
            recordID = CKRecord.ID(recordName: UUID().uuidString)
        }
        
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        // Basic fields
        record["userID"] = settings.userID as CKRecordValue
        record["defaultEditorMode"] = settings.defaultEditorMode as CKRecordValue
        record["p2pDisplayName"] = settings.p2pDisplayName as CKRecordValue
        record["p2pAutoAccept"] = (settings.p2pAutoAccept ? 1 : 0) as CKRecordValue
        record["syncEnabled"] = (settings.syncEnabled ? 1 : 0) as CKRecordValue
        record["createdAt"] = settings.createdAt as CKRecordValue
        record["updatedAt"] = settings.updatedAt as CKRecordValue
        
        // Preferences data
        if let editorData = settings.editorPreferencesData {
            record["editorPreferencesData"] = editorData as CKRecordValue
        }
        if let builderData = settings.builderPreferencesData {
            record["builderPreferencesData"] = builderData as CKRecordValue
        }
        if let enterpriseData = settings.enterprisePreferencesData {
            record["enterprisePreferencesData"] = enterpriseData as CKRecordValue
        }
        
        return record
    }
    
    private func createSettings(from record: CKRecord) throws -> AppSettings {
        guard let userID = record["userID"] as? String,
              let defaultEditorMode = record["defaultEditorMode"] as? String,
              let p2pDisplayName = record["p2pDisplayName"] as? String,
              let p2pAutoAcceptInt = record["p2pAutoAccept"] as? Int,
              let syncEnabledInt = record["syncEnabled"] as? Int,
              let updatedAt = record["updatedAt"] as? Date else {
            throw SettingsSyncError.invalidRecord
        }
        
        let settings = AppSettings(
            userID: userID,
            defaultEditorMode: defaultEditorMode,
            p2pDisplayName: p2pDisplayName,
            p2pAutoAccept: p2pAutoAcceptInt != 0,
            syncEnabled: syncEnabledInt != 0
        )
        
        // Restore preferences data
        if let editorData = record["editorPreferencesData"] as? Data {
            settings.editorPreferencesData = editorData
        }
        if let builderData = record["builderPreferencesData"] as? Data {
            settings.builderPreferencesData = builderData
        }
        if let enterpriseData = record["enterprisePreferencesData"] as? Data {
            settings.enterprisePreferencesData = enterpriseData
        }
        
        // Set CloudKit metadata
        settings.cloudKitRecordID = record.recordID.recordName
        settings.lastSyncedAt = Date()
        
        return settings
    }
    
    // MARK: - Subscription Management
    
    /// Sets up a CloudKit subscription to receive updates
    func setupSubscription() async throws {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await database.save(subscription)
        } catch {
            throw SettingsSyncError.subscriptionFailed(error)
        }
    }
    
    /// Removes CloudKit subscription
    func removeSubscription(subscriptionID: String) async throws {
        do {
            try await database.deleteSubscription(withID: subscriptionID)
        } catch {
            throw SettingsSyncError.subscriptionFailed(error)
        }
    }
}

// MARK: - Sync Errors

enum SettingsSyncError: LocalizedError {
    case pushFailed(Error)
    case pullFailed(Error)
    case syncFailed(Error)
    case deleteFailed(Error)
    case invalidRecord
    case subscriptionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .pushFailed(let error):
            return "Failed to push settings to CloudKit: \(error.localizedDescription)"
        case .pullFailed(let error):
            return "Failed to pull settings from CloudKit: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync settings: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete settings from CloudKit: \(error.localizedDescription)"
        case .invalidRecord:
            return "Invalid CloudKit record format"
        case .subscriptionFailed(let error):
            return "Failed to manage CloudKit subscription: \(error.localizedDescription)"
        }
    }
}
