import SwiftUI
import MultipeerConnectivity

// MARK: - Template Picker Sheet

struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [TemplateModel]
    let connectedPeers: [MCPeerID]
    let onSend: (TemplateModel, MCPeerID?) -> Void
    
    @State private var selectedTemplate: TemplateModel?
    @State private var selectedPeer: MCPeerID?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Template") {
                    if templates.isEmpty {
                        Text("No custom templates available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Template", selection: $selectedTemplate) {
                            Text("Select...").tag(nil as TemplateModel?)
                            ForEach(templates) { template in
                                Text(template.name).tag(template as TemplateModel?)
                            }
                        }
                    }
                }
                
                Section("Send To") {
                    Picker("Device", selection: $selectedPeer) {
                        Text("All Devices").tag(nil as MCPeerID?)
                        ForEach(connectedPeers, id: \.self) { peer in
                            Text(peer.displayName).tag(peer as MCPeerID?)
                        }
                    }
                }
            }
            .navigationTitle("Share Template")
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Send") {
                        if let template = selectedTemplate {
                            onSend(template, selectedPeer)
                            dismiss()
                        }
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}
