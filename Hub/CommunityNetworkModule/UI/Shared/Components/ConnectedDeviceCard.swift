import SwiftUI
import MultipeerConnectivity

// MARK: - Connected Device Card

struct ConnectedDeviceCard: View {
    let peer: MCPeerID
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(peer.displayName)
                    .font(.headline)
                Text("Connected")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            Button {
                onSend()
            } label: {
                Label("Send", systemImage: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
