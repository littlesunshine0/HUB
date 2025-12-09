//
//  CentersHubView.swift
//  Hub
//
//  Main Centers Hub - Access all centers from one place
//

import SwiftUI

struct CentersHubView: View {
    @State private var selectedCenter: CentersModule.CenterType?
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with all centers
            List(selection: $selectedCenter) {
                Section("Quick Access") {
                    ForEach(CentersModule.CenterType.allCases.prefix(4)) { center in
                        centerRow(center)
                    }
                }
                
                Section("System") {
                    ForEach(CentersModule.CenterType.allCases.dropFirst(4)) { center in
                        centerRow(center)
                    }
                }
            }
            .navigationTitle("Centers")
            .searchable(text: $searchQuery, prompt: "Search centers...")
        } detail: {
            if let selected = selectedCenter {
                centerDetailView(for: selected)
            } else {
                centerOverview
            }
        }
    }
    
    private func centerRow(_ center: CentersModule.CenterType) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(center.rawValue)
                    .font(.headline)
                Text(center.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: center.icon)
                .foregroundStyle(center.color)
        }
        .tag(center)
    }
    
    @ViewBuilder
    private func centerDetailView(for center: CentersModule.CenterType) -> some View {
        switch center {
        case .action:
            ActionCenterView()
        case .control:
            ControlCenterView()
        case .help:
            HelpCenterView()
        case .knowledge:
            KnowledgeCenterView()
        case .download:
            DownloadCenterView()
        case .security:
            SecurityCenterView()
        case .admin:
            AdminCenterView()
        case .media:
            MediaCenterView()
        }
    }
    
    private var centerOverview: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Centers Hub")
                        .font(.largeTitle.bold())
                    
                    Text("Access all your control centers from one place")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Grid of centers
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200), spacing: 16)
                ], spacing: 16) {
                    ForEach(CentersModule.CenterType.allCases) { center in
                        CenterCard(center: center) {
                            selectedCenter = center
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }
}

struct CenterCard: View {
    let center: CentersModule.CenterType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: center.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(center.color.gradient)
                
                Text(center.rawValue)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(center.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(center.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CentersHubView()
}
