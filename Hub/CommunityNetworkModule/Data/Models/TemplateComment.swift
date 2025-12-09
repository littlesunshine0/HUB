import Foundation
import CloudKit
import Combine

// MARK: - Template Comment Model

struct TemplateComment: Identifiable {
    let id: String
    let templateID: String
    let userID: String
    let comment: String
    let createdAt: Date
    
    init?(from record: CKRecord) {
        guard let templateID = record["templateID"] as? String,
              let userID = record["userID"] as? String,
              let comment = record["comment"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.templateID = templateID
        self.userID = userID
        self.comment = comment
        self.createdAt = createdAt
    }
}
