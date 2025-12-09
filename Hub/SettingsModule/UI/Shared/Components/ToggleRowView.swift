import SwiftUI

// MARK: - Toggle Row View

public struct ToggleRowView: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    public init(
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
    }
}

#Preview {
    Form {
        ToggleRowView(
            title: "Enable Feature",
            subtitle: "This is a helpful description",
            isOn: .constant(true)
        )
    }
    .frame(width: 400)
}
