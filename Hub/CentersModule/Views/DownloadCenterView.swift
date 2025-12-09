//
//  DownloadCenterView.swift
//  Hub
//
//  Manage hub and template downloads
//

import SwiftUI

struct DownloadCenterView: View {
    @State private var downloads: [DownloadItem] = []
    @State private var selectedFilter: DownloadFilter = .all
    
    enum DownloadFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case failed = "Failed"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding()
            
            Divider()
            
            // Filter
            Picker("Filter", selection: $selectedFilter) {
                ForEach(DownloadFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Downloads List
            if filteredDownloads.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDownloads) { download in
                            DownloadRow(download: download)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Download Center")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Clear Completed") {
                        clearCompleted()
                    }
                    Button("Retry Failed") {
                        retryFailed()
                    }
                    Divider()
                    Button("Pause All") {
                        pauseAll()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadSampleDownloads()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.cyan.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Download Center")
                    .font(.title.bold())
                Text("\(activeDownloads.count) active, \(completedDownloads.count) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Total progress
            if !activeDownloads.isEmpty {
                VStack(alignment: .trailing) {
                    Text("\(Int(totalProgress * 100))%")
                        .font(.title2.bold())
                    Text("Overall")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var filteredDownloads: [DownloadItem] {
        switch selectedFilter {
        case .all:
            return downloads
        case .active:
            return activeDownloads
        case .completed:
            return completedDownloads
        case .failed:
            return downloads.filter { $0.status == .failed }
        }
    }
    
    private var activeDownloads: [DownloadItem] {
        downloads.filter { $0.status == .downloading || $0.status == .pending }
    }
    
    private var completedDownloads: [DownloadItem] {
        downloads.filter { $0.status == .completed }
    }
    
    private var totalProgress: Double {
        guard !activeDownloads.isEmpty else { return 0 }
        return activeDownloads.reduce(0) { $0 + $1.progress } / Double(activeDownloads.count)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Downloads")
                .font(.headline)
            Text("Your downloads will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func clearCompleted() {
        downloads.removeAll { $0.status == .completed }
    }
    
    private func retryFailed() {
        for index in downloads.indices where downloads[index].status == .failed {
            downloads[index].status = .pending
        }
    }
    
    private func pauseAll() {
        for index in downloads.indices where downloads[index].status == .downloading {
            downloads[index].status = .paused
        }
    }
    
    private func loadSampleDownloads() {
        downloads = [
            DownloadItem(name: "E-Commerce Template", type: .template, size: "24.5 MB", progress: 0.65, status: .downloading),
            DownloadItem(name: "Analytics Dashboard", type: .hub, size: "18.2 MB", progress: 1.0, status: .completed),
            DownloadItem(name: "Social Media Hub", type: .hub, size: "32.1 MB", progress: 0.0, status: .pending),
            DownloadItem(name: "Design System", type: .template, size: "15.8 MB", progress: 0.45, status: .paused),
            DownloadItem(name: "Chat Application", type: .hub, size: "28.3 MB", progress: 0.0, status: .failed)
        ]
    }
}

struct DownloadItem: Identifiable {
    let id = UUID()
    let name: String
    let type: DownloadType
    let size: String
    var progress: Double
    var status: DownloadStatus
    
    enum DownloadType {
        case hub
        case template
        
        var icon: String {
            switch self {
            case .hub: return "square.stack.3d.up"
            case .template: return "doc.on.doc"
            }
        }
    }
    
    enum DownloadStatus {
        case pending
        case downloading
        case paused
        case completed
        case failed
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .downloading: return "Downloading"
            case .paused: return "Paused"
            case .completed: return "Completed"
            case .failed: return "Failed"
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .downloading: return "arrow.down.circle.fill"
            case .paused: return "pause.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .downloading: return .blue
            case .paused: return .yellow
            case .completed: return .green
            case .failed: return .red
            }
        }
    }
}

struct DownloadRow: View {
    let download: DownloadItem
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: download.type.icon)
                    .font(.title2)
                    .foregroundStyle(.cyan)
                    .frame(width: 40)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.name)
                        .font(.headline)
                    HStack {
                        Text(download.size)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Label(download.status.displayName, systemImage: download.status.icon)
                            .font(.caption)
                            .foregroundStyle(download.status.color)
                    }
                }
                
                Spacer()
                
                // Actions
                downloadActions
            }
            
            // Progress bar
            if download.status == .downloading || download.status == .paused {
                VStack(spacing: 4) {
                    ProgressView(value: download.progress)
                        .tint(.cyan)
                    HStack {
                        Text("\(Int(download.progress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(estimatedTime)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var downloadActions: some View {
        HStack(spacing: 8) {
            switch download.status {
            case .pending, .downloading:
                Button {
                    // Pause
                } label: {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                
            case .paused:
                Button {
                    // Resume
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                
            case .failed:
                Button {
                    // Retry
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                
            case .completed:
                Button {
                    // Open
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                // Delete
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var estimatedTime: String {
        let remaining = 1.0 - download.progress
        let seconds = Int(remaining * 60)
        return "\(seconds)s remaining"
    }
}

#Preview {
    NavigationStack {
        DownloadCenterView()
    }
}
