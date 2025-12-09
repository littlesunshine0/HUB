import SwiftUI
import MultipeerConnectivity

// MARK: - Nearby Device Card

struct NearbyDeviceCard: View {
    let peer: MCPeerID
    let isConnected: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "iphone")
                .font(.title2)
                .foregroundStyle(isConnected ? .green : .blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(peer.displayName)
                    .font(.headline)
                Text(isConnected ? "Connected" : "Available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !isConnected {
                Button("Connect") {
                    onConnect()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
