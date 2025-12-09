import SwiftUI

// MARK: - Account Settings View (Standalone)

public struct AccountSettingsViewStandalone: View {
    @ObservedObject var viewModel: AccountSettingsViewModel
    
    public init(viewModel: AccountSettingsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Form {
            Section {
                if let name = viewModel.name {
                    LabeledContent("Name", value: name)
                }
                
                if let email = viewModel.email {
                    LabeledContent("Email", value: email)
                }
                
                if viewModel.userID != nil {
                    LabeledContent("User ID", value: viewModel.displayUserID)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    if viewModel.isAuthenticated {
                        Label("Authenticated", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Label("Not Authenticated", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            } header: {
                Text("Account Information")
            }
            
            Section {
                ButtonRowView(
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    role: .destructive,
                    icon: "rectangle.portrait.and.arrow.right"
                ) {
                    viewModel.signOut()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Account")
    }
}

#Preview {
    let viewModel = AccountSettingsViewModel()
    
    return NavigationStack {
        AccountSettingsViewStandalone(viewModel: viewModel)
    }
    .frame(width: 600, height: 400)
}
