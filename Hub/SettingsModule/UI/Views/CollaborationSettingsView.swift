//
//  CollaborationSettingsView.swift
//  Hub
//
//  Settings for CRDT-based collaboration and sync
//

import SwiftUI
import SwiftData

struct CollaborationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var adapter: HubCRDTAdapter
    
    @State private var showConnectionSheet = false
    @State private var peerHost = "192.168.1.100"
    @State private var peerPort = "8080"
    @State private var showCRDTDemo = false
    
    init(modelContext: ModelContext) {
        _adapter = StateObject(wrappedValue: HubCRDTAdapter(modelContext: modelContext))
    }
    
    var body: some View {
        Form {
            // Sync Status Section
            Section {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sync Status")
                            .font(.headline)
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { adapter.isSyncEnabled },
                        set: { enabled in
                            if enabled {
                                adapter.enableSync()
                            } else {
                                adapter.disableSync()
                            }
                        }
                    ))
                }
            } header: {
                Text("Real-Time Collaboration")
            } footer: {
                Text("Enable CRDT-based sync to collaborate with other users in real-time without conflicts. Works over local network without CloudKit.")
            }
            
            // Connection Section
            if adapter.isSyncEnabled {
                Section {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.accentColor)
                        
                        Text("Connected Peers")
                        
                        Spacer()
                        
                        Text("\(adapter.syncService.connectedPeers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showConnectionSheet = true
                    } label: {
                        Label("Connect to Peer", systemImage: "plus.circle")
                    }
                    
                    if !adapter.syncService.connectedPeers.isEmpty {
                        ForEach(Array(adapter.syncService.connectedPeers), id: \.self) { peerID in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                Text(peerID.prefix(8))
                                    .font(.system(.body, design: .monospaced))
                                
                                Spacer()
                                
                                Button {
                                    // Disconnect peer
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("Network")
                }
            }
            
            // Features Section
            Section {
                LandingFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Conflict-Free Merging",
                    description: "Automatic conflict resolution using CRDTs"
                )
                
                LandingFeatureRow(
                    icon: "wifi.slash",
                    title: "Offline-First",
                    description: "Edit offline, sync when connected"
                )
                
                LandingFeatureRow(
                    icon: "network",
                    title: "Peer-to-Peer",
                    description: "No central server required"
                )
                
                LandingFeatureRow(
                    icon: "lock.shield",
                    title: "No CloudKit",
                    description: "Works without iCloud or Apple account"
                )
            } header: {
                Text("Features")
            }
            
            // Demo Section
            Section {
                Button {
                    showCRDTDemo = true
                } label: {
                    Label("Open CRDT Demo", systemImage: "play.circle")
                }
            } header: {
                Text("Testing")
            } footer: {
                Text("Try the CRDT demo to see real-time collaboration in action with multiple simulated users.")
            }
            
            // Info Section
            Section {
                Link(destination: URL(string: "https://crdt.tech")!) {
                    Label("Learn About CRDTs", systemImage: "book")
                }
                
                Button {
                    // Show guide
                } label: {
                    Label("Integration Guide", systemImage: "doc.text")
                }
            } header: {
                Text("Resources")
            }
        }
#if os(iOS)
        .formStyle(.grouped)
#endif
        .navigationTitle("Collaboration")
        .sheet(isPresented: $showConnectionSheet) {
            connectionSheet
        }
        .sheet(isPresented: $showCRDTDemo) {
            CRDTSyncDemoView()
                .frame(minWidth: 900, minHeight: 600)
        }
    }
    
    // MARK: - Connection Sheet
    
    private var connectionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Host", text: $peerHost)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Port", text: $peerPort)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Peer Connection")
                } footer: {
                    Text("Enter the IP address and port of the peer you want to connect to.")
                }
                
                Section {
                    Text("Your Device")
                        .font(.headline)
                    
                    Text("Other users can connect to you using:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Host:")
                        Spacer()
                        Text(getLocalIPAddress() ?? "Unknown")
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Port:")
                        Spacer()
                        Text("8080")
                            .font(.system(.body, design: .monospaced))
                    }
                } header: {
                    Text("Connection Info")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Connect to Peer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showConnectionSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        if let port = Int(peerPort) {
                            adapter.connectToPeer(host: peerHost, port: port)
                        }
                        showConnectionSheet = false
                    }
                    .disabled(peerHost.isEmpty || peerPort.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    // MARK: - Status Helpers
    
    private var statusIcon: String {
        switch adapter.syncStatus {
        case .disconnected:
            return "circle"
        case .connecting:
            return "circle.dotted"
        case .connected:
            return "circle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch adapter.syncStatus {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .syncing:
            return .blue
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch adapter.syncStatus {
        case .disconnected:
            return "Not connected"
        case .connecting:
            return "Connecting..."
        case .connected(let peers):
            return "Connected to \(peers) peer\(peers == 1 ? "" : "s")"
        case .syncing:
            return "Syncing..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private func getLocalIPAddress() -> String? {
        // Get local IP address
        // This is a simplified version - production would use proper network APIs
        return "192.168.1.100"
    }
}

// MARK: - Feature Row

struct LandingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollaborationSettingsView(modelContext: ModelContext(
            try! ModelContainer(for: AppHub.self)
        ))
    }
}

