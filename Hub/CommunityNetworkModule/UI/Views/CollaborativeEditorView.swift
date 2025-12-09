import SwiftUI
import Combine

// MARK: - Collaborative Editor
struct CollaborativeEditorView: View {
    @StateObject private var viewModel: CollaborativeEditorViewModel
    @State private var showParticipants = false
    
    init(documentId: String) {
        _viewModel = StateObject(wrappedValue: CollaborativeEditorViewModel(documentId: documentId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            CollaborationToolbar(
                participants: viewModel.activeParticipants,
                onShowParticipants: { showParticipants.toggle() },
                onShare: { viewModel.shareDocument() }
            )
            
            // Editor with presence indicators
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.content)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: viewModel.content) { newValue in
                        viewModel.handleLocalChange(newValue)
                    }
                
                // Cursor positions of other users
                ForEach(viewModel.remoteCursors) { cursor in
                    CursorIndicator(cursor: cursor)
                }
                
                // Selection highlights
                ForEach(viewModel.remoteSelections) { selection in
                    SelectionHighlight(selection: selection)
                }
            }
            
            // Status bar
            CollaborationStatusBar(
                status: viewModel.connectionStatus,
                lastSync: viewModel.lastSyncTime,
                conflicts: viewModel.conflictCount
            )
        }
        .sheet(isPresented: $showParticipants) {
            ParticipantsView(participants: viewModel.activeParticipants)
        }
        .onAppear {
            viewModel.connect()
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

// MARK: - Toolbar
struct CollaborationToolbar: View {
    let participants: [Participant]
    let onShowParticipants: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            // Participant avatars
            HStack(spacing: -8) {
                ForEach(participants.prefix(5)) { participant in
                    ParticipantAvatar(participant: participant)
                }
                
                if participants.count > 5 {
                    Text("+\(participants.count - 5)")
                        .font(.caption)
                        .padding(4)
                }
            }
            .onTapGesture(perform: onShowParticipants)
            
            Spacer()
            
            Button("Share", action: onShare)
            
            Button("History") {
                // Show version history
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

struct ParticipantAvatar: View {
    let participant: Participant
    
    var body: some View {
        Circle()
            .fill(participant.color)
            .frame(width: 32, height: 32)
            .overlay(
                Text(participant.initials)
                    .font(.caption)
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
}

// MARK: - Cursor & Selection Indicators
struct CursorIndicator: View {
    let cursor: RemoteCursor
    
    var body: some View {
        Rectangle()
            .fill(cursor.color)
            .frame(width: 2, height: 20)
            .position(cursor.position)
            .overlay(
                Text(cursor.userName)
                    .font(.caption2)
                    .padding(4)
                    .background(cursor.color)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .offset(y: -20),
                alignment: .top
            )
    }
}

struct SelectionHighlight: View {
    let selection: RemoteSelection
    
    var body: some View {
        Rectangle()
            .fill(selection.color.opacity(0.3))
            .frame(width: selection.width, height: selection.height)
            .position(selection.position)
    }
}

// MARK: - Status Bar
struct CollaborationStatusBar: View {
    let status: ConnectionStatus
    let lastSync: Date?
    let conflicts: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(status.displayName)
                    .font(.caption)
            }
            
            if let lastSync = lastSync {
                Text("Last sync: \(lastSync, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if conflicts > 0 {
                Text("\(conflicts) conflicts")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Participants View
struct ParticipantsView: View {
    let participants: [Participant]
    
    var body: some View {
        NavigationView {
            List(participants) { participant in
                HStack {
                    ParticipantAvatar(participant: participant)
                    
                    VStack(alignment: .leading) {
                        Text(participant.name)
                            .font(.headline)
                        Text(participant.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(participant.status.displayName)
                        .font(.caption)
                        .padding(4)
                        .background(participant.status.color.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .navigationTitle("Participants")
        }
    }
}

// MARK: - View Model
@MainActor
class CollaborativeEditorViewModel: ObservableObject {
    private let crdtService = CRDTSyncService()
    @Published var content: String = ""
    @Published var activeParticipants: [Participant] = []
    @Published var remoteCursors: [RemoteCursor] = []
    @Published var remoteSelections: [RemoteSelection] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastSyncTime: Date?
    @Published var conflictCount: Int = 0
    
    private let documentId: String
    // TODO: Re-enable when services are properly accessible
    // private let crdtService: CRDTSyncService
    // private let conflictResolver: ConflictResolutionService
    
    init(documentId: String) {
        self.documentId = documentId
        // TODO: Initialize services when available
        // self.crdtService = CRDTSyncService()
        // self.conflictResolver = ConflictResolutionService()
    }
    
    func connect() {
        connectionStatus = .connecting
        
        Task {
            do {
                try await crdtService.connect(documentId: documentId)
                connectionStatus = .connected
                await loadDocument()
                await subscribeToChanges()
            } catch {
                connectionStatus = .error
            }
        }
    }
    
    func disconnect() {
        Task {
            await crdtService.disconnect()
            connectionStatus = .disconnected
        }
    }
    
    func handleLocalChange(_ newContent: String) {
        Task {
            // Convert documentId string to UUID
            guard let docUUID = UUID(uuidString: documentId) else { return }
            
            // Create CRDT change for description update
            let crdtChange = CRDTDocumentChange(
                documentId: docUUID,
                type: .updateDescription,
                newValue: newContent
            )
            
            try? await crdtService.applyLocalChange(crdtChange)
            lastSyncTime = Date()
        }
    }
    
    func shareDocument() {
        // Share document with others
    }
    
    private func loadDocument() async {
        // Load document content
    }
    
    private func subscribeToChanges() async {
        // Subscribe to real-time changes
    }
    
    private func getCurrentUserId() -> String {
        "current-user-id"
    }
}

// MARK: - Models
struct Participant: Identifiable {
    let id: String
    let name: String
    let email: String
    let color: Color
    let status: ParticipantStatus
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        return components.compactMap { $0.first }.map { String($0) }.joined()
    }
}

enum ParticipantStatus {
    case active, idle, away
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .idle: return "Idle"
        case .away: return "Away"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .idle: return .orange
        case .away: return .gray
        }
    }
}

struct RemoteCursor: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let position: CGPoint
    let color: Color
}

struct RemoteSelection: Identifiable {
    let id: String
    let userId: String
    let position: CGPoint
    let width: CGFloat
    let height: CGFloat
    let color: Color
}

enum ConnectionStatus {
    case disconnected, connecting, connected, error
    
    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
}

struct DocumentChange {
    let content: String
    let timestamp: Date
    let userId: String
}
