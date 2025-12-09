import SwiftUI
import MultipeerConnectivity

// MARK: - Local Sharing View

struct LocalSharingView: View {
    @StateObject private var viewModel = LocalSharingViewModel()
    @ObservedObject var templateManager: TemplateManager
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Controls
            List {
                Section("Your Device") {
                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundStyle(.blue)
                        Text(viewModel.peerID.displayName)
                            .font(.headline)
                    }
                }
                
                Section("Visibility") {
                    Toggle(isOn: Binding(
                        get: { viewModel.isAdvertising },
                        set: { viewModel.isAdvertising = $0 }
                    )) {
                        Label("Make Discoverable", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    
                    if viewModel.isAdvertising {
                        Text("Other devices can see you")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Discovery") {
                    Toggle(isOn: Binding(
                        get: { viewModel.isBrowsing },
                        set: { viewModel.isBrowsing = $0 }
                    )) {
                        Label("Search for Devices", systemImage: "magnifyingglass")
                    }
                    
                    if viewModel.isBrowsing {
                        Text("Searching nearby...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Connected Devices") {
                    if viewModel.connectedPeers.isEmpty {
                        Text("No devices connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.connectedPeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(peer.displayName)
                            }
                            .font(.caption)
                        }
                    }
                }
                
                if viewModel.hasReceivedTemplates {
                    Section("Received Templates") {
                        Button {
                            viewModel.showReceivedTemplates()
                        } label: {
                            HStack {
                                Image(systemName: "tray.and.arrow.down.fill")
                                    .foregroundStyle(.blue)
                                Text("\(viewModel.receivedTemplates.count) template(s)")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Controls")
        } detail: {
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Local Sharing")
                            .font(.largeTitle)
                            .bold()
                        Text("Share templates with nearby devices via Bluetooth & Wi-Fi")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.showTemplatePicker()
                    } label: {
                        Label("Share Template", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasConnectedPeers)
                }
                .padding()
                
                Divider()
                
                // Status message
                if let status = viewModel.statusMessage {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text(status)
                            .font(.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                }
                
                // Content
                if !viewModel.isBrowsing && !viewModel.isAdvertising {
                    ContentUnavailableView(
                        "Start Sharing",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Enable 'Make Discoverable' or 'Search for Devices' to start sharing templates locally")
                    )
                } else if viewModel.nearbyPeers.isEmpty && viewModel.connectedPeers.isEmpty {
                    ContentUnavailableView(
                        "No Devices Found",
                        systemImage: "magnifyingglass",
                        description: Text("Make sure both devices have Local Sharing enabled and are nearby")
                    )
                } else {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Nearby devices
                            if !viewModel.nearbyPeers.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Nearby Devices")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(viewModel.nearbyPeers, id: \.self) { peer in
                                        NearbyDeviceCard(
                                            peer: peer,
                                            isConnected: viewModel.connectedPeers.contains(peer),
                                            onConnect: {
                                                viewModel.invitePeer(peer)
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Connected devices
                            if !viewModel.connectedPeers.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Connected Devices")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(viewModel.connectedPeers, id: \.self) { peer in
                                        ConnectedDeviceCard(
                                            peer: peer,
                                            onSend: {
                                                viewModel.showTemplatePicker()
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingTemplatePicker) {
            TemplatePickerSheet(
                templates: templateManager.templates.filter { !$0.isBuiltIn },
                connectedPeers: viewModel.connectedPeers,
                onSend: { template, peer in
                    Task {
                        await viewModel.sendTemplate(template, to: peer)
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showingReceivedTemplates) {
            ReceivedTemplatesSheet(
                templates: viewModel.receivedTemplates,
                onImport: { template in
                    viewModel.importReceivedTemplate(template, templateManager: templateManager)
                },
                onDismiss: {
                    viewModel.clearReceivedTemplates()
                }
            )
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
