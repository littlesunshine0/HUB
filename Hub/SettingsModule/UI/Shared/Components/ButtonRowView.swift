import SwiftUI

// MARK: - Button Row View

public struct ButtonRowView: View {
    let title: String
    let subtitle: String?
    let role: ButtonRole?
    let icon: String?
    let action: () -> Void
    
    public init(
        title: String,
        subtitle: String? = nil,
        role: ButtonRole? = nil,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.role = role
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var iconColor: Color {
        switch role {
        case .destructive:
            return .red
        case .cancel:
            return .secondary
        default:
            return .accentColor
        }
    }
}

#Preview {
    Form {
        Section {
            ButtonRowView(
                title: "Clear Cache",
                subtitle: "Free up disk space",
                role: .destructive,
                icon: "trash"
            ) {
                print("Clear cache tapped")
            }
            
            ButtonRowView(
                title: "Export Settings",
                icon: "square.and.arrow.up"
            ) {
                print("Export tapped")
            }
        }
    }
    .frame(width: 400)
}
