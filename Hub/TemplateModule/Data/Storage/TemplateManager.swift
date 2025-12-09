//
//  TemplateManager.swift
//  Hub
//
//  Manages Hub templates with role-aware access control
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
public class TemplateManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published public var templates: [TemplateModel] = []
    @Published public var filteredTemplates: [TemplateModel] = []
    @Published public var searchText: String = ""
    @Published public var selectedCategory: HubCategory?
    @Published public var showBuiltInOnly: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Dependencies
    
    public let modelContext: ModelContext
    private let roleManager: RoleManager
    private var currentUserID: String?
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext, roleManager: RoleManager = .shared, currentUserID: String? = nil) {
        self.modelContext = modelContext
        self.roleManager = roleManager
        self.currentUserID = currentUserID
        
        loadTemplates()
    }
    
    // MARK: - Template Loading (Owner-Aware)
    
    /// Load templates with role-aware filtering
    /// - Owner role: sees ALL templates (built-in + all users' templates)
    /// - Regular users: see built-in + their own templates
    /// - Not logged in: see only built-in templates
    public func loadTemplates() {
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor: FetchDescriptor<TemplateModel>
            
            if roleManager.isOwner {
                // Owner sees ALL templates
                descriptor = FetchDescriptor<TemplateModel>(
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
            } else if let userID = currentUserID {
                // Regular users see built-in + their own
                descriptor = FetchDescriptor<TemplateModel>(
                    predicate: #Predicate { template in
                        template.isBuiltIn == true || template.userID == userID
                    },
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
            } else {
                // Not logged in: only built-in
                descriptor = FetchDescriptor<TemplateModel>(
                    predicate: #Predicate { $0.isBuiltIn == true },
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
            }
            
            templates = try modelContext.fetch(descriptor)
            applyFilters()
            isLoading = false
        } catch {
            errorMessage = "Failed to load templates: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Filtering
    
    public func applyFilters() {
        var result = templates
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.templateDescription.localizedCaseInsensitiveContains(searchText) ||
                template.features.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Apply built-in filter
        if showBuiltInOnly {
            result = result.filter { $0.isBuiltIn }
        }
        
        filteredTemplates = result
    }
    
    // MARK: - Owner-Aware Permissions
    
    /// Check if the current user can modify a template
    /// - Owner role: can modify ANY template
    /// - Regular users: can only modify their own templates
    public func canModifyTemplate(_ template: TemplateModel) -> Bool {
        return roleManager.isOwner || template.userID == currentUserID
    }
    
    /// Check if the current user can delete a template
    /// - Owner role: can delete ANY template (except built-in)
    /// - Regular users: can only delete their own non-built-in templates
    public func canDeleteTemplate(_ template: TemplateModel) -> Bool {
        if template.isBuiltIn && !roleManager.isOwner {
            return false
        }
        return roleManager.isOwner || (template.userID == currentUserID && !template.isBuiltIn)
    }
    
    // MARK: - Template Operations
    
    public func createTemplate(_ template: TemplateModel, userID: String? = nil) {
        if let userID = userID, !template.isBuiltIn {
            template.userID = userID
        }
        modelContext.insert(template)
        saveContext()
        loadTemplates()
    }
    
    public func updateTemplate(_ template: TemplateModel) {
        guard canModifyTemplate(template) else {
            errorMessage = "You don't have permission to modify this template"
            return
        }
        
        saveContext()
        loadTemplates()
    }
    
    public func deleteTemplate(_ template: TemplateModel) {
        guard canDeleteTemplate(template) else {
            errorMessage = "You don't have permission to delete this template"
            return
        }
        
        modelContext.delete(template)
        saveContext()
        loadTemplates()
    }
    
    public func duplicateTemplate(_ template: TemplateModel) {
        let duplicate = TemplateModel(
            name: "\(template.name) (Copy)",
            category: template.category,
            description: template.templateDescription,
            icon: template.icon,
            author: currentUserID ?? "Unknown",
            version: "1.0.0",
            sourceFiles: template.sourceFiles,
            features: template.features,
            dependencies: template.dependencies,
            isBuiltIn: false,
            tags: template.tags,
            sharedModules: template.sharedModules,
            featureToggles: template.featureToggles,
            userID: currentUserID,
            visualLayout: template.visualLayout.isEmpty ? nil : template.visualLayout,
            visualScreens: template.visualScreens.isEmpty ? nil : template.visualScreens,
            branding: template.brandingData != nil ? template.branding : nil,
            isVisualTemplate: template.isVisualTemplate,
            isFeatured: false
        )
        
        createTemplate(duplicate, userID: currentUserID ?? "Unknown")
    }
    
    // MARK: - Template Discovery
    
    public func getFeaturedTemplates() -> [TemplateModel] {
        return templates.filter { $0.isFeatured }
    }
    
    public func getPopularTemplates() -> [TemplateModel] {
        return templates.sorted { $0.downloadCount > $1.downloadCount }.prefix(20).map { $0 }
    }
    
    public func getTopRatedTemplates() -> [TemplateModel] {
        return templates.sorted { $0.averageRating > $1.averageRating }.prefix(20).map { $0 }
    }
    
    public func getRecentlyViewedTemplates() -> [TemplateModel] {
        return templates.sorted { $0.lastViewedAt ?? Date.distantPast > $1.lastViewedAt ?? Date.distantPast }.prefix(20).map { $0 }
    }
    
    // MARK: - Template Tracking
    
    public func trackTemplateView(_ template: TemplateModel) {
        template.viewCount += 1
        template.lastViewedAt = Date()
        saveContext()
    }
    
    public func trackTemplateDownload(_ template: TemplateModel) {
        template.downloadCount += 1
        saveContext()
    }
    
    // MARK: - Reviews
    
    public func addReview(to template: TemplateModel, rating: Double, comment: String, userName: String, userID: String) {
        let review = TemplateReview(
            id: UUID(),
            userID: userID,
            userName: userName,
            rating: rating,
            comment: comment,
            createdAt: Date()
        )
        
        // Append review to the template's reviews array
        // The averageRating and reviewCount are computed properties that will update automatically
        template.reviews.append(review)
        
        saveContext()
    }
    
    // MARK: - Import/Export
    
    public func exportTemplate(_ template: TemplateModel) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(template)
    }
    
    public func importTemplate(from data: Data) throws {
        let decoder = JSONDecoder()
        var template = try decoder.decode(TemplateModel.self, from: data)
        
        // Assign to current user
        template.userID = currentUserID
        template.isBuiltIn = false
        
        createTemplate(template)
    }
    
    // MARK: - User Management
    
    public func setCurrentUser(_ userID: String?) {
        currentUserID = userID
        loadTemplates()
    }
    
    // MARK: - Context Management
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
