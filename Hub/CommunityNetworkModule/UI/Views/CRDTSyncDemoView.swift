//
//  CRDTSyncDemoView.swift
//  Hub
//
//  Demo of CloudKit-free multi-user sync using CRDTs
//

import SwiftUI

struct CRDTSyncDemoView: View {
    @StateObject private var syncService = CRDTSyncService()
    @State private var newDocumentName = ""
    @State private var selectedDocumentID: UUID?
    @State private var newTag = ""
    @State private var peerHost = "localhost"
    
    @State private var peerPort = "8080"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Document List
            VStack(spacing: 0) {
                // Connection Status
                HStack {
                    Circle()
                        .fill(syncService.isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(syncService.isConnected ? "Connected" : "Offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(syncService.connectedPeers.count) peers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // Document List
                List(Array(syncService.documents.values), id: \.id, selection: $selectedDocumentID) { doc in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(doc.name.value)
                            .font(.headline)
                        
                        Text("\(doc.editCount.value) edits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !doc.tags.allElements.isEmpty {
                            HStack {
                                ForEach(Array(doc.tags.allElements), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                
                // Create New Document
                HStack {
                    TextField("New document name", text: $newDocumentName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Create") {
                        let doc = syncService.createDocument(name: newDocumentName)
                        selectedDocumentID = doc.id
                        newDocumentName = ""
                    }
                    .disabled(newDocumentName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Start Listening") {
                            syncService.startListening()
                        }
                        
                        Button("Stop Listening") {
                            syncService.stopListening()
                        }
                        
                        Divider()
                        
                        Button("Connect to Peer...") {
                            // Show connection dialog
                        }
                    } label: {
                        Image(systemName: "network")
                    }
                }
            }
        } detail: {
            // Detail - Document Editor
            if let documentID = selectedDocumentID,
               let document = syncService.documents[documentID] {
                documentDetailView(for: document)
            } else {
                ContentUnavailableView(
                    "No Document Selected",
                    systemImage: "doc.text",
                    description: Text("Select a document from the sidebar or create a new one")
                )
            }
        }
    }
    
    @ViewBuilder
    private func documentDetailView(for document: CRDTSyncService.CRDTDocument) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Document Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Document Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Name", text: Binding(
                    get: { document.name.value },
                    set: { syncService.updateDocumentName(document.id, name: $0) }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.title2)
            }
            
            Divider()
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                CRDTFlowLayout(spacing: 8) {
                    ForEach(Array(document.tags.allElements), id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.body)
                            
                            Button {
                                syncService.removeTag(document.id, tag: tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                
                HStack {
                    TextField("Add tag", text: $newTag)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        syncService.addTag(document.id, tag: newTag)
                        newTag = ""
                    }
                    .disabled(newTag.isEmpty)
                }
            }
            
            Divider()
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                Text("Metadata")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Created:")
                            .foregroundColor(.secondary)
                        Text(document.createdAt, style: .date)
                    }
                    
                    GridRow {
                        Text("Updated:")
                            .foregroundColor(.secondary)
                        Text(document.updatedAt, style: .relative)
                    }
                    
                    GridRow {
                        Text("Edit Count:")
                            .foregroundColor(.secondary)
                        Text("\(document.editCount.value)")
                    }
                    
                    GridRow {
                        Text("Last Editor:")
                            .foregroundColor(.secondary)
                        Text(document.name.replicaID.prefix(8))
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .font(.body)
            }
            
            Spacer()
            
            // Info Box
            VStack(alignment: .leading, spacing: 8) {
                Label("CRDT Sync Active", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                
                Text("This document uses Conflict-free Replicated Data Types (CRDTs) for automatic conflict resolution. Multiple users can edit simultaneously without conflicts.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle(document.name.value)
    }
}

// MARK: - Flow Layout

private struct CRDTFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    CRDTSyncDemoView()
        .frame(width: 900, height: 600)
}
