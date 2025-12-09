import Combine
import SwiftUI

import Foundation

@MainActor
public class AccountSettingsViewModel: ObservableObject {
    @Published var email: String?
    @Published var name: String?
    @Published var userID: String?
    
    // TEMPORARY: Auth disabled
    // private let authManager: AppAuthManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    public init() {
        // TEMPORARY: Auth disabled - using placeholder data
        self.email = "user@hub.app"
        self.name = "User"
        self.userID = "temp-id"
    }
    
    // MARK: - Actions
    
    func signOut() {
        // TEMPORARY: Auth disabled
        // authManager.signOut()
    }
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        // TEMPORARY: Auth disabled
        true
    }
    
    var displayUserID: String {
        guard let userID = userID else { return "N/A" }
        return String(userID.prefix(8)) + "..."
    }
}
