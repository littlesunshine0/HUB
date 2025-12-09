import SwiftUI
import Combine
import SwiftData

// MARK: - Main Settings View

public struct MainSettingsView: View {
    @StateObject var viewModel: SettingsMainViewModel
    @StateObject private var roleManager = RoleManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var showOwnerOnboarding = false
    
    public init(settingsManager: SettingsManager) {
        self._viewModel = StateObject(wrappedValue: SettingsMainViewModel(
            settingsManager: settingsManager,
            loadSettingsUseCase: LoadSettingsUseCase(settingsManager: settingsManager),
            saveSettingsUseCase: SaveSettingsUseCase(settingsManager: settingsManager)
        ))
    }
    
    // Legacy initializer for backward compatibility
    public init(viewModel: SettingsMainViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case editor = "Editor"
        case builder = "Builder"
        case p2p = "Peer-to-Peer"
        case role = "Role"
        case owner = "Owner"
        case enterprise = "Enterprise"
        case account = "Account"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .editor: return "pencil.and.outline"
            case .builder: return "hammer"
            case .p2p: return "antenna.radiowaves.left.and.right"
            case .role: return "person.badge.key.fill"
            case .owner: return "crown.fill"
            case .enterprise: return "building.2.fill"
            case .account: return "person.circle"
            }
        }
        
        var isOwnerOnly: Bool {
            return self == .owner || self == .enterprise
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsTab.allCases.filter { !$0.isOwnerOnly || roleManager.isOwner }, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            // Detail view
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading settings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let settings = viewModel.currentSettings {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(
                            settings: settings,
                            viewModel: viewModel
                        )
                    case .editor:
                        EditorSettingsView(viewModel: viewModel.editorVM)
                    case .builder:
                        BuilderSettingsView(viewModel: viewModel.builderVM)
                    case .p2p:
                        P2PSettingsView(
                            settings: settings,
                            viewModel: viewModel
                        )
                    case .role:
                        RoleSettingsView(roleManager: roleManager)
                    case .owner:
                        OwnerSettingsView(
                            roleManager: roleManager,
                            showOwnerOnboarding: $showOwnerOnboarding
                        )
                    case .enterprise:
                        EnterpriseSettingsView(
                            viewModel: viewModel.enterpriseVM
                        )
                    case .account:
                        SettingsAccountView(
                            viewModel: viewModel.accountVM,
                            roleManager: roleManager,
                            showOwnerOnboarding: $showOwnerOnboarding
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "No Settings Loaded",
                        systemImage: "gearshape.slash",
                        description: Text("Please sign in to access settings")
                    )
                }
            }
            .frame(minWidth: 500)
        }
        .task {
            await viewModel.loadAllSettings()
        }
        .sheet(isPresented: $showOwnerOnboarding) {
            OwnerOnboardingView()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    let settings: AppSettings
    @ObservedObject var viewModel: SettingsMainViewModel
    
    var body: some View {
        Form {
            Section {
                Picker("Default Editor Mode", selection: Binding(
                    get: { settings.editorModeEnum },
                    set: { newMode in
                        settings.updateEditorMode(newMode)
                        viewModel.saveAllSettings()
                    }
                )) {
                    ForEach(AppSettings.EditorMode.allCases) { mode in
                        VStack(alignment: .leading) {
                            Label(mode.rawValue, systemImage: mode.icon)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(mode)
                    }
                }
            } header: {
                Text("Editor")
            }
            
            Section {
                HStack {
                    Text("User ID")
                    Spacer()
                    Text(settings.userID.prefix(8) + "...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                HStack {
                    Text("Created")
                    Spacer()
                    Text(settings.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(settings.updatedAt, style: .relative)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Information")
            }
            
            Section {
                Button(role: .destructive) {
                    Task {
                        await viewModel.resetToDefaults()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                    .frame(maxWidth: .infinity)
                }
            } footer: {
                Text("This will reset all settings to their default values.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

// MARK: - P2P Settings View

struct P2PSettingsView: View {
    let settings: AppSettings
    @ObservedObject var viewModel: SettingsMainViewModel
    
    @State private var displayName: String
    @State private var autoAccept: Bool
    
    init(settings: AppSettings, viewModel: SettingsMainViewModel) {
        self.settings = settings
        self.viewModel = viewModel
        self._displayName = State(initialValue: settings.p2pDisplayName)
        self._autoAccept = State(initialValue: settings.p2pAutoAccept)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: displayName) { _, newValue in
                        saveP2PSettings()
                    }
                
                Text("This name will be visible to other users when sharing templates")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Identity")
            }
            
            Section {
                ToggleRowView(
                    title: "Auto-Accept Connections",
                    subtitle: "Automatically accept incoming template shares",
                    isOn: $autoAccept
                )
                .onChange(of: autoAccept) { _, _ in
                    saveP2PSettings()
                }
            } header: {
                Text("Connection Settings")
            } footer: {
                Text("When enabled, templates from other users will be automatically accepted without confirmation.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Peer-to-Peer")
    }
    
    private func saveP2PSettings() {
        settings.updateP2PSettings(displayName: displayName, autoAccept: autoAccept)
        viewModel.saveAllSettings()
    }
}

// MARK: - Owner Settings View

struct OwnerSettingsView: View {
    @ObservedObject var roleManager: RoleManager
    @Binding var showOwnerOnboarding: Bool
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Owner Account")
                            .font(.headline)
                        Text("Full system privileges")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                NavigationLink {
                    RoleManagementView(roleManager: roleManager)
                } label: {
                    Label("Manage User Roles", systemImage: "person.3.fill")
                }
                
                NavigationLink {
                    AutomationSettingsView(roleManager: roleManager)
                } label: {
                    Label("Automation Tasks", systemImage: "gearshape.2.fill")
                }
                
                Button {
                    showOwnerOnboarding = true
                } label: {
                    Label("Review Owner Setup", systemImage: "checkmark.shield.fill")
                }
            } header: {
                Text("Owner Tools")
            }
            
            Section {
                LabeledContent("Current Role", value: roleManager.currentRole.rawValue)
                LabeledContent("Capabilities", value: "\(roleManager.availableCapabilities().count)")
                LabeledContent("Available Tasks", value: "\(roleManager.availableTasks().count)")
                LabeledContent("Enabled Tasks", value: "\(roleManager.enabledTasks.count)")
            } header: {
                Text("Status")
            }
            
            Section {
                Button(role: .destructive) {
                    roleManager.resetFirstLaunch()
                } label: {
                    Label("Reset First Launch (Debug)", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Debug")
            } footer: {
                Text("This will reset the first launch flag. The app will show owner onboarding on next launch.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Owner Settings")
    }
}

// MARK: - Role Management View

struct RoleManagementView: View {
    @ObservedObject var roleManager: RoleManager
    
    var body: some View {
        Form {
            Section {
                Text("Role management features coming soon")
                    .foregroundStyle(.secondary)
                Text("Assign roles to team members and manage permissions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Manage Roles")
    }
}

// MARK: - Automation Settings View

struct AutomationSettingsView: View {
    @ObservedObject var roleManager: RoleManager
    
    var body: some View {
        Form {
            Section {
                ForEach(roleManager.availableTasks(), id: \.id) { task in
                    Toggle(isOn: Binding(
                        get: { roleManager.enabledTasks.contains(task.id) },
                        set: { _ in roleManager.toggleTask(task.id) }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.name)
                                .font(.headline)
                            Text(task.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Automated Tasks")
            } footer: {
                Text("Enable tasks to run automatically based on triggers")
            }
        }
        .navigationTitle("Automation")
    }
}

// MARK: - Account Settings View

struct SettingsAccountView: View {
    @ObservedObject var viewModel: AccountSettingsViewModel
    @ObservedObject var roleManager: RoleManager
    @Binding var showOwnerOnboarding: Bool
    
    var body: some View {
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
                HStack {
                    Label("Role", systemImage: roleManager.currentRole == .owner ? "crown.fill" : "person.fill")
                    Spacer()
                    Text(roleManager.currentRole.rawValue)
                        .foregroundStyle(roleManager.currentRole == .owner ? .yellow : .secondary)
                }
                
                if !roleManager.isOwner {
                    Button {
                        showOwnerOnboarding = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Become Owner")
                        }
                    }
                }
            } header: {
                Text("Role & Permissions")
            } footer: {
                if roleManager.isOwner {
                    Text("You have full owner privileges with access to all features.")
                } else {
                    Text("Complete owner onboarding to gain full system access.")
                }
            }
            
            Section {
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Account")
        .sheet(isPresented: $showOwnerOnboarding) {
            OwnerOnboardingView()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: AppSettings.self)
    let context = ModelContext(container)
    let settingsManager = SettingsManager(modelContext: context)
    // TEMPORARY: Auth disabled
    let viewModel = SettingsMainViewModel(
        settingsManager: settingsManager,
        loadSettingsUseCase: LoadSettingsUseCase(settingsManager: settingsManager),
        saveSettingsUseCase: SaveSettingsUseCase(settingsManager: settingsManager)
    )
    
    MainSettingsView(viewModel: viewModel)
        .frame(width: 800, height: 600)
}
