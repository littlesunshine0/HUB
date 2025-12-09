//
//  CloudKitStorables.swift
//  Hub
//
//  Storable wrappers for CloudKit service
//  These types bridge between HubTemplateModel and the Storable protocol
//

import Foundation
import CloudKit

// Assumes Storable protocol is defined elsewhere.
// These types are plain value types and are not actor isolated.
// We opt out of actor isolation by marking them as nonisolated(unsafe).

// MARK: - Template Storable

nonisolated struct TemplateStorable: Storable, Codable, Sendable {
    let id: String
    let timestamp: Date
    let name: String
    let category: String
    let templateDescription: String
    let icon: String
    let author: String
    let authorID: String?
    let version: String
    let features: [String]
    let dependencies: [String]
    let tags: [String]
    var downloadCount: Int
    let rating: Double
    let createdAt: Date
    let updatedAt: Date
    let sourceFilesData: Data?
    
    var storableID: String { id }
    var storableTimestamp: Date { timestamp }
    
    init(from template: TemplateModel, authorID: String?) {
        self.id = template.id.uuidString
        self.timestamp = Date()
        self.name = template.name
        self.category = template.category.rawValue
        self.templateDescription = template.templateDescription
        self.icon = template.icon
        self.author = template.author
        self.authorID = authorID
        self.version = template.version
        self.features = template.features
        self.dependencies = template.dependencies
        self.tags = template.tags
        self.downloadCount = template.downloadCount
        self.rating = template.rating
        self.createdAt = template.createdAt
        self.updatedAt = template.updatedAt
        self.sourceFilesData = template.sourceFilesData
    }
    
    init?(from record: CKRecord) {
        guard let id = record["templateID"] as? String,
              let name = record["name"] as? String,
              let category = record["category"] as? String else {
            return nil
        }
        
        self.id = id
        self.timestamp = record.creationDate ?? Date()
        self.name = name
        self.category = category
        self.templateDescription = record["templateDescription"] as? String ?? ""
        self.icon = record["icon"] as? String ?? ""
        self.author = record["author"] as? String ?? ""
        self.authorID = record["authorID"] as? String
        self.version = record["version"] as? String ?? "1.0"
        self.features = record["features"] as? [String] ?? []
        self.dependencies = record["dependencies"] as? [String] ?? []
        self.tags = record["tags"] as? [String] ?? []
        self.downloadCount = record["downloadCount"] as? Int ?? 0
        self.rating = record["rating"] as? Double ?? 0.0
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.updatedAt = record["updatedAt"] as? Date ?? Date()
        self.sourceFilesData = record["sourceFilesData"] as? Data
    }
    
    func toCKRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "HubTemplate", recordID: CKRecord.ID(recordName: id))
        record["templateID"] = id
        record["name"] = name
        record["category"] = category
        record["templateDescription"] = templateDescription
        record["icon"] = icon
        record["author"] = author
        record["authorID"] = authorID
        record["version"] = version
        record["features"] = features
        record["dependencies"] = dependencies
        record["tags"] = tags
        record["downloadCount"] = downloadCount
        record["rating"] = rating
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        if let sourceFilesData = sourceFilesData {
            record["sourceFilesData"] = sourceFilesData
        }
        return record
    }
    
    static func fromCKRecord(_ record: CKRecord) throws -> TemplateStorable {
        guard let template = TemplateStorable(from: record) else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse template from CloudKit record"])
        }
        return template
    }
}

// MARK: - Rating Storable

nonisolated struct RatingStorable: Storable, Codable, Sendable {
    let id: String
    let timestamp: Date
    let templateID: String
    let userID: String
    let rating: Double
    
    var storableID: String { id }
    var storableTimestamp: Date { timestamp }
    
    func toCKRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "TemplateRating", recordID: CKRecord.ID(recordName: id))
        record["templateID"] = templateID
        record["userID"] = userID
        record["rating"] = rating
        record["createdAt"] = timestamp
        return record
    }
    
    static func fromCKRecord(_ record: CKRecord) throws -> RatingStorable {
        guard let templateID = record["templateID"] as? String,
              let userID = record["userID"] as? String,
              let rating = record["rating"] as? Double else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse rating from CloudKit record"])
        }
        
        return RatingStorable(
            id: record.recordID.recordName,
            timestamp: record["createdAt"] as? Date ?? Date(),
            templateID: templateID,
            userID: userID,
            rating: rating
        )
    }
}

// MARK: - Comment Storable

nonisolated struct CommentStorable: Storable, Codable, Sendable {
    let id: String
    let timestamp: Date
    let templateID: String
    let userID: String
    let comment: String
    
    var storableID: String { id }
    var storableTimestamp: Date { timestamp }
    
    func toCKRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "TemplateComment", recordID: CKRecord.ID(recordName: id))
        record["templateID"] = templateID
        record["userID"] = userID
        record["comment"] = comment
        record["createdAt"] = timestamp
        return record
    }
    
    static func fromCKRecord(_ record: CKRecord) throws -> CommentStorable {
        guard let templateID = record["templateID"] as? String,
              let userID = record["userID"] as? String,
              let comment = record["comment"] as? String else {
            throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse comment from CloudKit record"])
        }
        
        return CommentStorable(
            id: record.recordID.recordName,
            timestamp: record["createdAt"] as? Date ?? Date(),
            templateID: templateID,
            userID: userID,
            comment: comment
        )
    }
}

// MARK: - CloudTemplate Extensions

extension CloudTemplate {
    init?(from storable: TemplateStorable) {
        guard UUID(uuidString: storable.id) != nil,
              HubCategory(rawValue: storable.category) != nil else {
            return nil
        }
        
        // Use the existing CloudTemplate initializer from CKRecord
        // We need to create a temporary CKRecord to use the existing initializer
        let record = CKRecord(recordType: "HubTemplate", recordID: CKRecord.ID(recordName: storable.id))
        record["templateID"] = storable.id
        record["name"] = storable.name
        record["category"] = storable.category
        record["templateDescription"] = storable.templateDescription
        record["icon"] = storable.icon
        record["author"] = storable.author
        record["authorID"] = storable.authorID
        record["version"] = storable.version
        record["features"] = storable.features
        record["dependencies"] = storable.dependencies
        record["tags"] = storable.tags
        record["downloadCount"] = storable.downloadCount
        record["rating"] = storable.rating
        record["createdAt"] = storable.createdAt
        record["updatedAt"] = storable.updatedAt
        if let sourceFilesData = storable.sourceFilesData {
            record["sourceFilesData"] = sourceFilesData
        }
        
        self.init(from: record)
    }
}

extension TemplateRating {
    init?(from storable: RatingStorable) {
        // Use the existing TemplateRating initializer from CKRecord
        let record = CKRecord(recordType: "TemplateRating", recordID: CKRecord.ID(recordName: storable.id))
        record["templateID"] = storable.templateID
        record["userID"] = storable.userID
        record["rating"] = storable.rating
        record["createdAt"] = storable.timestamp
        
        self.init(from: record)
    }
}

extension TemplateComment {
    init?(from storable: CommentStorable) {
        // Use the existing TemplateComment initializer from CKRecord
        let record = CKRecord(recordType: "TemplateComment", recordID: CKRecord.ID(recordName: storable.id))
        record["templateID"] = storable.templateID
        record["userID"] = storable.userID
        record["comment"] = storable.comment
        record["createdAt"] = storable.timestamp
        
        self.init(from: record)
    }
}

