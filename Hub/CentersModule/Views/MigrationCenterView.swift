//
//  MigrationCenterView.swift
//  Hub
//
//  Data migration, export, and platform transition tools
//

import SwiftUI

struct MigrationCenterView: View {
    @State private var selectedMigration: MigrationType?
    @State private var showExportWizard = false
    @State private var showImportWizard = false
    
    var body: some View {
        NavigationSplitView {
            List {
                Section("Quick Actions") {
                    Button {
                        showExportWizard = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showImportWizard = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }
                
                Section("Migration Tools") {
                    ForEach(MigrationType.allTypes) { type in
                        NavigationLink(value: type) {
                            MigrationTypeRow(type: type)
                        }
                    }
                }
                
                Section("Resources") {
                    NavigationLink {
                        MigrationGuideView()
                    } label: {
                        Label("Migration Guides", systemImage: "book")
                    }
                    
                    NavigationLink {
                        CompatibilityCheckerView()
                    } label: {
                        Label("Compatibility Checker", systemImage: "checkmark.shield")
                    }
                }
            }
            .navigationTitle("Migration Center")
        } detail: {
            if let type = selectedMigration {
                MigrationDetailView(type: type)
            } else {
                migrationOverview
            }
        }
        .sheet(isPresented: $showExportWizard) {
            ExportWizardView()
        }
        .sheet(isPresented: $showImportWizard) {
            ImportWizardView()
        }
    }
    
    private var migrationOverview: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 70))
                        .foregroundStyle(.purple.gradient)
                    
                    Text("Easy Migration")
                        .font(.largeTitle.bold())
                    
                    Text("Move your data seamlessly between platforms")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Features
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MigrationFeatureCard(
                        icon: "doc.on.doc",
                        title: "Data Export",
                        description: "Export in multiple formats"
                    )
                    MigrationFeatureCard(
                        icon: "arrow.triangle.swap",
                        title: "Platform Switch",
                        description: "Migrate to other platforms"
                    )
                    MigrationFeatureCard(
                        icon: "shield.checkmark",
                        title: "Data Integrity",
                        description: "Verified data transfer"
                    )
                    MigrationFeatureCard(
                        icon: "clock.arrow.circlepath",
                        title: "Version Control",
                        description: "Rollback capability"
                    )
                }
                .padding(.horizontal)
                
                // Recent Migrations
                recentMigrationsSection
                
                // Export Formats
                exportFormatsSection
            }
            .padding(.bottom, 40)
        }
    }
    
    private var recentMigrationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Migrations")
                .font(.title2.bold())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                MigrationHistoryCard(
                    title: "Hub Data Export",
                    date: "Nov 20, 2025",
                    status: .completed,
                    itemCount: 45
                )
                MigrationHistoryCard(
                    title: "Template Import",
                    date: "Nov 18, 2025",
                    status: .completed,
                    itemCount: 12
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var exportFormatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supported Export Formats")
                .font(.title2.bold())
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FormatBadge(format: "JSON", icon: "doc.text")
                FormatBadge(format: "CSV", icon: "tablecells")
                FormatBadge(format: "XML", icon: "doc.richtext")
                FormatBadge(format: "SQL", icon: "cylinder")
                FormatBadge(format: "Swift", icon: "swift")
                FormatBadge(format: "ZIP", icon: "doc.zipper")
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Models

struct MigrationType: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let difficulty: Difficulty
    let estimatedTime: String
    
    enum Difficulty {
        case easy
        case moderate
        case advanced
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .moderate: return .orange
            case .advanced: return .red
            }
        }
        
        var label: String {
            switch self {
            case .easy: return "Easy"
            case .moderate: return "Moderate"
            case .advanced: return "Advanced"
            }
        }
    }
    
    static let allTypes: [MigrationType] = [
        MigrationType(
            id: "export",
            title: "Export All Data",
            description: "Export your entire Hub workspace",
            icon: "square.and.arrow.up",
            difficulty: .easy,
            estimatedTime: "5-10 min"
        ),
        MigrationType(
            id: "import",
            title: "Import from Other Platforms",
            description: "Import data from external sources",
            icon: "square.and.arrow.down",
            difficulty: .moderate,
            estimatedTime: "10-20 min"
        ),
        MigrationType(
            id: "backup",
            title: "Backup & Restore",
            description: "Create and restore backups",
            icon: "externaldrive",
            difficulty: .easy,
            estimatedTime: "5 min"
        ),
        MigrationType(
            id: "version",
            title: "Version Migration",
            description: "Migrate between Hub versions",
            icon: "arrow.up.forward",
            difficulty: .easy,
            estimatedTime: "Auto"
        ),
        MigrationType(
            id: "platform",
            title: "Platform Transfer",
            description: "Move to another no-code platform",
            icon: "arrow.triangle.swap",
            difficulty: .advanced,
            estimatedTime: "30-60 min"
        ),
        MigrationType(
            id: "code",
            title: "Export to Code",
            description: "Generate standalone code project",
            icon: "chevron.left.forwardslash.chevron.right",
            difficulty: .moderate,
            estimatedTime: "15-30 min"
        )
    ]
}

enum MigrationCenterStatus {
    case pending
    case inProgress
    case completed
    case failed
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct MigrationTypeRow: View {
    let type: MigrationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundStyle(.purple)
                Text(type.title)
                    .font(.headline)
            }
            
            Text(type.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(type.difficulty.label)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(type.difficulty.color.opacity(0.2))
                    .foregroundStyle(type.difficulty.color)
                    .cornerRadius(4)
                
                Label(type.estimatedTime, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MigrationFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.purple.gradient)
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MigrationHistoryCard: View {
    let title: String
    let date: String
    let status: MigrationCenterStatus
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.title2)
                .foregroundStyle(status.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("\(itemCount) items • \(date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if status == .completed {
                Button {
                    // Download
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct FormatBadge: View {
    let format: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
            Text(format)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct MigrationDetailView: View {
    let type: MigrationType
    @State private var isProcessing = false
    @State private var progress: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: type.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(.purple.gradient)
                        
                        VStack(alignment: .leading) {
                            Text(type.title)
                                .font(.largeTitle.bold())
                            Text(type.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(type.difficulty.label)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(type.difficulty.color.opacity(0.2))
                            .foregroundStyle(type.difficulty.color)
                            .cornerRadius(6)
                        
                        Label(type.estimatedTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Migration Steps")
                        .font(.title2.bold())
                    
                    MigrationStep(number: 1, title: "Prepare Data", description: "Review and select data to migrate")
                    MigrationStep(number: 2, title: "Choose Format", description: "Select export format and options")
                    MigrationStep(number: 3, title: "Verify", description: "Check data integrity")
                    MigrationStep(number: 4, title: "Export", description: "Complete the migration")
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Progress
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView(value: progress)
                        Text("Processing... \(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Action Button
                Button {
                    startMigration()
                } label: {
                    Label("Start Migration", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            .padding()
        }
    }
    
    private func startMigration() {
        isProcessing = true
        // Simulate migration
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.05
            if progress >= 1.0 {
                timer.invalidate()
                isProcessing = false
                progress = 0
            }
        }
    }
}

struct MigrationStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.2))
                .foregroundStyle(.purple)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ExportWizardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedFormat = "JSON"
    @State private var includeTemplates = true
    @State private var includeSettings = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        Text("JSON").tag("JSON")
                        Text("CSV").tag("CSV")
                        Text("XML").tag("XML")
                        Text("SQL").tag("SQL")
                    }
                }
                
                Section("Include") {
                    Toggle("Templates", isOn: $includeTemplates)
                    Toggle("Settings", isOn: $includeSettings)
                }
                
                Section {
                    Button("Export") {
                        // Perform export
                        dismiss()
                    }
                }
            }
            .navigationTitle("Export Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImportWizardView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple.gradient)
                
                Text("Import Data")
                    .font(.title.bold())
                
                Text("Select a file to import")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    // File picker
                } label: {
                    Label("Choose File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MigrationGuideView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                Text("How to export your data")
                Text("Importing from other platforms")
                Text("Backup best practices")
            }
            
            Section("Platform-Specific Guides") {
                Text("Migrating from Bubble")
                Text("Migrating from Webflow")
                Text("Migrating from Airtable")
            }
        }
        .navigationTitle("Migration Guides")
    }
}

struct CompatibilityCheckerView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundStyle(.green.gradient)
            
            Text("Compatibility Checker")
                .font(.title.bold())
            
            Text("Verify your data is compatible with the target platform")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Run Check") {
                // Run compatibility check
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    MigrationCenterView()
}
