//
//  UpdatesCenterView.swift
//  Hub
//
//  Platform updates, release notes, and feature announcements
//

import SwiftUI

struct UpdatesCenterView: View {
    @State private var selectedVersion: ReleaseVersion?
    @State private var showNotifications = true
    @State private var autoUpdate = true
    
    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    Toggle("Update Notifications", isOn: $showNotifications)
                    Toggle("Auto-Update", isOn: $autoUpdate)
                }
                
                Section("Recent Releases") {
                    ForEach(ReleaseVersion.allReleases) { version in
                        NavigationLink(value: version) {
                            ReleaseRow(version: version)
                        }
                    }
                }
                
                Section("Update Channels") {
                    NavigationLink {
                        UpdateChannelView(channel: .stable)
                    } label: {
                        Label("Stable", systemImage: "checkmark.shield")
                    }
                    
                    NavigationLink {
                        UpdateChannelView(channel: .beta)
                    } label: {
                        Label("Beta", systemImage: "flask")
                    }
                    
                    NavigationLink {
                        UpdateChannelView(channel: .nightly)
                    } label: {
                        Label("Nightly", systemImage: "moon.stars")
                    }
                }
            }
            .navigationTitle("Updates")
        } detail: {
            if let version = selectedVersion {
                ReleaseDetailView(version: version)
            } else {
                updatesOverview
            }
        }
    }
    
    private var updatesOverview: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.green.gradient)
                    
                    Text("Stay Up to Date")
                        .font(.largeTitle.bold())
                    
                    Text("Regular updates with new features and improvements")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Current Version
                currentVersionCard
                
                // Latest Release
                latestReleaseSection
                
                // Roadmap
                roadmapSection
                
                // Security Updates
                securityUpdatesSection
            }
            .padding(.bottom, 40)
        }
    }
    
    private var currentVersionCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Version")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("2.0.0")
                        .font(.title.bold())
                    Text("Released November 20, 2025")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("Up to date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                // Check for updates
            } label: {
                Label("Check for Updates", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var latestReleaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Latest Release")
                .font(.title2.bold())
                .padding(.horizontal)
            
            if let latest = ReleaseVersion.allReleases.first {
                ReleaseCard(version: latest)
                    .padding(.horizontal)
            }
        }
    }
    
    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Roadmap")
                    .font(.title2.bold())
                Spacer()
                Button("View Full Roadmap") {}
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                RoadmapItem(
                    title: "Visual Workflow Designer",
                    status: .inProgress,
                    eta: "Q1 2026"
                )
                RoadmapItem(
                    title: "Advanced AI Features",
                    status: .planned,
                    eta: "Q2 2026"
                )
                RoadmapItem(
                    title: "Mobile App Export",
                    status: .planned,
                    eta: "Q2 2026"
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var securityUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security Updates")
                .font(.title2.bold())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                SecurityUpdateCard(
                    title: "Security Patch 2.0.1",
                    description: "Critical security fixes",
                    severity: .critical,
                    date: "Nov 22, 2025"
                )
                SecurityUpdateCard(
                    title: "Security Update 1.9.5",
                    description: "Minor security improvements",
                    severity: .moderate,
                    date: "Nov 15, 2025"
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Models

struct ReleaseVersion: Identifiable, Hashable {
    let id: String
    let version: String
    let date: String
    let type: ReleaseType
    let features: [Feature]
    let bugFixes: [String]
    let breaking: [String]
    let securityFixes: [String]
    
    enum ReleaseType: String, Hashable {
        case major = "Major Release"
        case minor = "Minor Release"
        case patch = "Patch"
        case security = "Security Update"
        
        var color: Color {
            switch self {
            case .major: return .purple
            case .minor: return .blue
            case .patch: return .green
            case .security: return .red
            }
        }
    }
    
    struct Feature: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
    }
    
    static let allReleases: [ReleaseVersion] = [
        ReleaseVersion(
            id: "2.0.0",
            version: "2.0.0",
            date: "November 20, 2025",
            type: .major,
            features: [
                Feature(
                    title: "Centers Module",
                    description: "New centralized hub for all platform features",
                    icon: "square.grid.2x2"
                ),
                Feature(
                    title: "Enhanced Collaboration",
                    description: "Real-time collaborative editing with CRDT",
                    icon: "person.2"
                ),
                Feature(
                    title: "Advanced Analytics",
                    description: "Comprehensive analytics dashboard",
                    icon: "chart.bar"
                )
            ],
            bugFixes: [
                "Fixed sync issues with large files",
                "Improved memory management",
                "Resolved UI rendering glitches"
            ],
            breaking: [
                "Updated API endpoints (see migration guide)",
                "Changed storage format (auto-migration included)"
            ],
            securityFixes: [
                "Patched authentication vulnerability",
                "Enhanced encryption protocols"
            ]
        ),
        ReleaseVersion(
            id: "1.9.0",
            version: "1.9.0",
            date: "November 1, 2025",
            type: .minor,
            features: [
                Feature(
                    title: "Template Improvements",
                    description: "50+ new templates added",
                    icon: "doc.on.doc"
                ),
                Feature(
                    title: "Performance Boost",
                    description: "40% faster hub loading",
                    icon: "speedometer"
                )
            ],
            bugFixes: [
                "Fixed template preview issues",
                "Improved search accuracy"
            ],
            breaking: [],
            securityFixes: []
        )
    ]
}

enum RoadmapStatus {
    case completed
    case inProgress
    case planned
    case considering
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .inProgress: return .blue
        case .planned: return .orange
        case .considering: return .gray
        }
    }
    
    var label: String {
        switch self {
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        case .planned: return "Planned"
        case .considering: return "Considering"
        }
    }
}

enum UpdateChannel {
    case stable
    case beta
    case nightly
}

// MARK: - Supporting Views

struct ReleaseRow: View {
    let version: ReleaseVersion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Version \(version.version)")
                    .font(.headline)
                
                Text(version.type.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(version.type.color.opacity(0.2))
                    .foregroundStyle(version.type.color)
                    .cornerRadius(4)
            }
            
            Text(version.date)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if !version.securityFixes.isEmpty {
                Label("Security fixes included", systemImage: "shield.checkmark")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }
}

struct ReleaseCard: View {
    let version: ReleaseVersion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Version \(version.version)")
                        .font(.title2.bold())
                    Text(version.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(version.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(version.type.color.opacity(0.2))
                    .foregroundStyle(version.type.color)
                    .cornerRadius(6)
            }
            
            if !version.features.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Features")
                        .font(.headline)
                    
                    ForEach(version.features.prefix(3)) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: feature.icon)
                                .foregroundStyle(.blue)
                            Text(feature.title)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            Button {
                // View full release notes
            } label: {
                Text("View Full Release Notes")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ReleaseDetailView: View {
    let version: ReleaseVersion
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Version \(version.version)")
                                .font(.largeTitle.bold())
                            Text(version.date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(version.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(version.type.color.opacity(0.2))
                            .foregroundStyle(version.type.color)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Security Fixes
                if !version.securityFixes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Security Fixes", systemImage: "shield.checkmark.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        ForEach(version.securityFixes, id: \.self) { fix in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(fix)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Features
                if !version.features.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Features")
                            .font(.title2.bold())
                        
                        ForEach(version.features) { feature in
                            FeatureCard(feature: feature)
                        }
                    }
                }
                
                // Bug Fixes
                if !version.bugFixes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bug Fixes")
                            .font(.title2.bold())
                        
                        ForEach(version.bugFixes, id: \.self) { fix in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(fix)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Breaking Changes
                if !version.breaking.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Breaking Changes", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        ForEach(version.breaking, id: \.self) { change in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(change)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

struct FeatureCard: View {
    let feature: ReleaseVersion.Feature
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct RoadmapItem: View {
    let title: String
    let status: RoadmapStatus
    let eta: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                HStack {
                    Text(status.label)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.2))
                        .foregroundStyle(status.color)
                        .cornerRadius(4)
                    
                    Text("ETA: \(eta)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct SecurityUpdateCard: View {
    let title: String
    let description: String
    let severity: Severity
    let date: String
    
    enum Severity {
        case critical
        case high
        case moderate
        case low
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .moderate: return .yellow
            case .low: return .blue
            }
        }
        
        var label: String {
            switch self {
            case .critical: return "Critical"
            case .high: return "High"
            case .moderate: return "Moderate"
            case .low: return "Low"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.fill")
                .font(.title2)
                .foregroundStyle(severity.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(severity.label)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(severity.color.opacity(0.2))
                        .foregroundStyle(severity.color)
                        .cornerRadius(4)
                    
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct UpdateChannelView: View {
    let channel: UpdateChannel
    
    var body: some View {
        Text("Update Channel: \(String(describing: channel))")
            .font(.largeTitle)
    }
}

#Preview {
    UpdatesCenterView()
}
