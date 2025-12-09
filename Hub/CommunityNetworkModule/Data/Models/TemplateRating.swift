import Foundation
import CloudKit
import Combine

// MARK: - Template Rating Model

struct TemplateRating: Identifiable {
    let id: String
    let templateID: String
    let userID: String
    let rating: Double
    let createdAt: Date
    
    init?(from record: CKRecord) {
        guard let templateID = record["templateID"] as? String,
              let userID = record["userID"] as? String,
              let rating = record["rating"] as? Double,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.templateID = templateID
        self.userID = userID
        self.rating = rating
        self.createdAt = createdAt
    }
}
