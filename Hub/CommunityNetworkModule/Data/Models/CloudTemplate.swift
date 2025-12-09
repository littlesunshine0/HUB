import Foundation
import CloudKit
import Combine

// MARK: - Cloud Template Model

struct CloudTemplate: Identifiable {
    let id: String
    let templateID: UUID
    let name: String
    let category: HubCategory
    let templateDescription: String
    let icon: String
    let author: String
    let authorID: String?
    let version: String
    let features: [String]
    let dependencies: [String]
    let tags: [String]
    let downloadCount: Int
    let rating: Double
    let createdAt: Date
    let updatedAt: Date
    let sourceFilesData: Data?
    
    init?(from record: CKRecord) {
        guard let templateIDString = record["templateID"] as? String,
              let templateID = UUID(uuidString: templateIDString),
              let name = record["name"] as? String,
              let categoryString = record["category"] as? String,
              let category = HubCategory(rawValue: categoryString),
              let description = record["templateDescription"] as? String,
              let icon = record["icon"] as? String,
              let author = record["author"] as? String,
              let version = record["version"] as? String,
              let features = record["features"] as? [String],
              let dependencies = record["dependencies"] as? [String],
              let tags = record["tags"] as? [String],
              let downloadCount = record["downloadCount"] as? Int,
              let rating = record["rating"] as? Double,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.templateID = templateID
        self.name = name
        self.category = category
        self.templateDescription = description
        self.icon = icon
        self.author = author
        self.authorID = record["authorID"] as? String
        self.version = version
        self.features = features
        self.dependencies = dependencies
        self.tags = tags
        self.downloadCount = downloadCount
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceFilesData = record["sourceFilesData"] as? Data
    }
    
    func toHubTemplateModel() -> TemplateModel {
        let template = TemplateModel(
            id: templateID,
            name: name,
            category: category,
            description: templateDescription,
            icon: icon,
            author: author,
            version: version,
            sourceFiles: [:],
            features: features,
            dependencies: dependencies,
            isBuiltIn: false,
            tags: tags
        )
        
        if let data = sourceFilesData {
            template.sourceFilesData = data
        }
        
        template.downloadCount = downloadCount
        template.rating = rating
        
        return template
    }
}
