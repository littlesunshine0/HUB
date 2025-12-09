import SwiftUI

/// Template cleanup and maintenance view
struct TemplateCleanupView: View {
    let templateManager: TemplateManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIssues: Set<CleanupIssue.ID> = []
    @State private var isScanning = false
    @State private var issues: [CleanupIssue] = []
    @State private var showingConfirmation = false
    
    struct CleanupIssue: Identifiable {
        let id = UUID()
        let type: IssueType
        let template: TemplateModel
        let description: String
        let severity: Severity
        
        enum IssueType {
            case duplicate
            case orphaned
            case corrupted
            case outdated
            case unused
            case missingDependencies
            case invalidMetadata
        }
        
        enum Severity {
            case low
            case medium
            case high
            
            var color: Color {
                switch self {
                case .low: return .yellow
                case .medium: return .orange
                case .high: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .low: return "exclamationmark.triangle"
                case .medium: return "exclamationmark.triangle.fill"
                case .high: return "exclamationmark.octagon.fill"
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Issues list
                if isScanning {
                    scanningView
                } else if issues.isEmpty {
                    emptyView
                } else {
                    issuesListView
                }
                
                Divider()
                
                // Actions
                actionsView
            }
            .navigationTitle("Template Cleanup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Cleanup", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clean Up", role: .destructive) {
                    performCleanup()
                }
            } message: {
                Text("This will fix \(selectedIssues.count) issues. This action cannot be undone.")
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            scanForIssues()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("Template Cleanup")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Scan and fix issues with your templates")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Statistics
            if !issues.isEmpty {
                HStack(spacing: 20) {
                    CleanupStatBadge(
                        icon: "exclamationmark.octagon.fill",
                        value: "\(issues.filter { $0.severity == .high }.count)",
                        label: "High",
                        color: .red
                    )
                    CleanupStatBadge(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(issues.filter { $0.severity == .medium }.count)",
                        label: "Medium",
                        color: .orange
                    )
                    CleanupStatBadge(
                        icon: "exclamationmark.triangle",
                        value: "\(issues.filter { $0.severity == .low }.count)",
                        label: "Low",
                        color: .yellow
                    )
                }
            }
        }
        .padding()
    }
    
    // MARK: - Scanning View
    
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning templates...")
                .font(.headline)
            Text("Checking for issues and optimization opportunities")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No Issues Found",
            systemImage: "checkmark.circle.fill",
            description: Text("Your templates are in good shape!")
        )
        .symbolRenderingMode(.multicolor)
    }
    
    // MARK: - Issues List
    
    private var issuesListView: some View {
        List(selection: $selectedIssues) {
            ForEach(issues) { issue in
                IssueRow(issue: issue, isSelected: selectedIssues.contains(issue.id))
                    .tag(issue.id)
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Actions
    
    private var actionsView: some View {
        HStack {
            Button {
                scanForIssues()
            } label: {
                Label("Rescan", systemImage: "arrow.clockwise")
            }
            
            Spacer()
            
            Button {
                selectedIssues = Set(issues.map { $0.id })
            } label: {
                Text("Select All")
            }
            .disabled(issues.isEmpty)
            
            Button {
                selectedIssues.removeAll()
            } label: {
                Text("Deselect All")
            }
            .disabled(selectedIssues.isEmpty)
            
            Button {
                showingConfirmation = true
            } label: {
                Label("Fix Selected (\(selectedIssues.count))", systemImage: "wrench.and.screwdriver")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIssues.isEmpty)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Helper Methods
    
    private func scanForIssues() {
        isScanning = true
        issues.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Scan for duplicates
            findDuplicates()
            
            // Scan for orphaned templates
            findOrphaned()
            
            // Scan for corrupted data
            findCorrupted()
            
            // Scan for outdated templates
            findOutdated()
            
            // Scan for unused templates
            findUnused()
            
            // Scan for missing dependencies
            findMissingDependencies()
            
            // Scan for invalid metadata
            findInvalidMetadata()
            
            isScanning = false
        }
    }
    
    private func findDuplicates() {
        var seen: [String: TemplateModel] = [:]
        for template in templateManager.templates {
            if let existing = seen[template.name] {
                issues.append(CleanupIssue(
                    type: .duplicate,
                    template: template,
                    description: "Duplicate of '\(existing.name)'",
                    severity: .medium
                ))
            } else {
                seen[template.name] = template
            }
        }
    }
    
    private func findOrphaned() {
        for template in templateManager.templates {
            if !template.isBuiltIn && template.userID == nil {
                issues.append(CleanupIssue(
                    type: .orphaned,
                    template: template,
                    description: "Template has no owner",
                    severity: .low
                ))
            }
        }
    }
    
    private func findCorrupted() {
        for template in templateManager.templates {
            if template.name.isEmpty {
                issues.append(CleanupIssue(
                    type: .corrupted,
                    template: template,
                    description: "Template has no name",
                    severity: .high
                ))
            }
            if template.icon.isEmpty {
                issues.append(CleanupIssue(
                    type: .corrupted,
                    template: template,
                    description: "Template has no icon",
                    severity: .low
                ))
            }
        }
    }
    
    private func findOutdated() {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        for template in templateManager.templates {
            if template.updatedAt < sixMonthsAgo && !template.isBuiltIn {
                issues.append(CleanupIssue(
                    type: .outdated,
                    template: template,
                    description: "Not updated in 6+ months",
                    severity: .low
                ))
            }
        }
    }
    
    private func findUnused() {
        for template in templateManager.templates {
            if template.downloadCount == 0 && template.viewCount == 0 && !template.isBuiltIn {
                issues.append(CleanupIssue(
                    type: .unused,
                    template: template,
                    description: "Never used or viewed",
                    severity: .low
                ))
            }
        }
    }
    
    private func findMissingDependencies() {
        for template in templateManager.templates {
            if !template.dependencies.isEmpty {
                // Check if dependencies exist
                for dep in template.dependencies {
                    // Simplified check - in real implementation, verify actual dependencies
                    if dep.isEmpty {
                        issues.append(CleanupIssue(
                            type: .missingDependencies,
                            template: template,
                            description: "Has empty dependency",
                            severity: .medium
                        ))
                    }
                }
            }
        }
    }
    
    private func findInvalidMetadata() {
        for template in templateManager.templates {
            if template.templateDescription.isEmpty {
                issues.append(CleanupIssue(
                    type: .invalidMetadata,
                    template: template,
                    description: "Missing description",
                    severity: .low
                ))
            }
            if template.author.isEmpty {
                issues.append(CleanupIssue(
                    type: .invalidMetadata,
                    template: template,
                    description: "Missing author",
                    severity: .low
                ))
            }
        }
    }
    
    private func performCleanup() {
        for issueID in selectedIssues {
            guard let issue = issues.first(where: { $0.id == issueID }) else { continue }
            
            switch issue.type {
            case .duplicate:
                // Delete duplicate
                templateManager.deleteTemplate(issue.template)
            case .orphaned:
                // Assign to system user
                issue.template.userID = "system"
                templateManager.updateTemplate(issue.template)
            case .corrupted:
                // Fix corrupted data
                if issue.template.name.isEmpty {
                    issue.template.name = "Untitled Template"
                }
                if issue.template.icon.isEmpty {
                    issue.template.icon = "doc"
                }
                templateManager.updateTemplate(issue.template)
            case .outdated:
                // Update timestamp
                issue.template.updatedAt = Date()
                templateManager.updateTemplate(issue.template)
            case .unused:
                // Delete unused template
                templateManager.deleteTemplate(issue.template)
            case .missingDependencies:
                // Remove empty dependencies
                issue.template.dependencies = issue.template.dependencies.filter { !$0.isEmpty }
                templateManager.updateTemplate(issue.template)
            case .invalidMetadata:
                // Fix metadata
                if issue.template.templateDescription.isEmpty {
                    issue.template.templateDescription = "No description available"
                }
                if issue.template.author.isEmpty {
                    issue.template.author = "Unknown"
                }
                templateManager.updateTemplate(issue.template)
            }
        }
        
        // Rescan after cleanup
        selectedIssues.removeAll()
        scanForIssues()
    }
}

// MARK: - Issue Row

struct IssueRow: View {
    let issue: TemplateCleanupView.CleanupIssue
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
            
            // Severity icon
            Image(systemName: issue.severity.icon)
                .foregroundStyle(issue.severity.color)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.template.name)
                    .font(.headline)
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Label(issue.type.description, systemImage: "tag")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label(issue.severity.description, systemImage: issue.severity.icon)
                        .font(.caption2)
                        .foregroundStyle(issue.severity.color)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Badge

struct CleanupStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Extensions

extension TemplateCleanupView.CleanupIssue.IssueType: CustomStringConvertible {
    var description: String {
        switch self {
        case .duplicate: return "Duplicate"
        case .orphaned: return "Orphaned"
        case .corrupted: return "Corrupted"
        case .outdated: return "Outdated"
        case .unused: return "Unused"
        case .missingDependencies: return "Missing Dependencies"
        case .invalidMetadata: return "Invalid Metadata"
        }
    }
}

extension TemplateCleanupView.CleanupIssue.Severity: CustomStringConvertible {
    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// Preview removed - requires model context
