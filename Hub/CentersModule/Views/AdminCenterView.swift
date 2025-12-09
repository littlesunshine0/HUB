//
//  AdminCenterView.swift
//  Hub
//
//  System administration console
//

import SwiftUI

struct AdminCenterView: View {
    @State private var selectedSection: AdminSection = .users
    
    enum AdminSection: String, CaseIterable, Identifiable {
        case users = "Users"
        case roles = "Roles & Permissions"
        case system = "System"
        case logs = "Logs"
        case database = "Database"
        case integrations = "Integrations"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .users: return "person.3"
            case .roles: return "person.badge.key"
            case .system: return "gearshape.2"
            case .logs: return "doc.text"
            case .database: return "cylinder"
            case .integrations: return "puzzlepiece.extension"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(AdminSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Admin Center")
        } detail: {
            ScrollView {
                VStack(spacing: 24) {
                    sectionHeader
                    sectionContent
                }
                .padding()
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: selectedSection.icon)
                .font(.system(size: 40))
                .foregroundStyle(.indigo.gradient)
            
            VStack(alignment: .leading) {
                Text(selectedSection.rawValue)
                    .font(.title.bold())
                Text("Manage \(selectedSection.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .users:
            usersContent
        case .roles:
            rolesContent
        case .system:
            systemContent
        case .logs:
            logsContent
        case .database:
            databaseContent
        case .integrations:
            integrationsContent
        }
    }
    
    private var usersContent: some View {
        VStack(spacing: 16) {
            // Stats
            HStack(spacing: 12) {
                AdminStatCard(title: "Total Users", value: "1,234", icon: "person.3", color: .blue)
                AdminStatCard(title: "Active", value: "892", icon: "checkmark.circle", color: .green)
                AdminStatCard(title: "Admins", value: "12", icon: "star", color: .yellow)
            }
            
            // User Management
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("User Management")
                        .font(.headline)
                    Spacer()
                    Button {
                        // Add user
                    } label: {
                        Label("Add User", systemImage: "plus")
                    }
                }
                
                VStack(spacing: 8) {
                    UserRow(name: "John Doe", email: "john@example.com", role: "Admin", status: .active)
                    UserRow(name: "Jane Smith", email: "jane@example.com", role: "User", status: .active)
                    UserRow(name: "Bob Johnson", email: "bob@example.com", role: "User", status: .inactive)
                }
            }
        }
    }
    
    private var rolesContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Roles")
                        .font(.headline)
                    Spacer()
                    Button {
                        // Add role
                    } label: {
                        Label("Add Role", systemImage: "plus")
                    }
                }
                
                VStack(spacing: 8) {
                    RoleCard(name: "Owner", description: "Full system access", userCount: 1, color: .yellow)
                    RoleCard(name: "Admin", description: "Administrative privileges", userCount: 12, color: .red)
                    RoleCard(name: "Developer", description: "Development access", userCount: 45, color: .blue)
                    RoleCard(name: "User", description: "Standard user access", userCount: 1176, color: .green)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Permissions")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    PermissionRow(name: "Create Hubs", roles: ["Owner", "Admin", "Developer"])
                    PermissionRow(name: "Delete Hubs", roles: ["Owner", "Admin"])
                    PermissionRow(name: "Manage Users", roles: ["Owner", "Admin"])
                    PermissionRow(name: "View Analytics", roles: ["Owner", "Admin", "Developer"])
                }
            }
        }
    }
    
    private var systemContent: some View {
        VStack(spacing: 16) {
            // System Stats
            HStack(spacing: 12) {
                AdminStatCard(title: "Uptime", value: "99.9%", icon: "checkmark.shield", color: .green)
                AdminStatCard(title: "CPU", value: "23%", icon: "cpu", color: .blue)
                AdminStatCard(title: "Memory", value: "4.2 GB", icon: "memorychip", color: .orange)
            }
            
            // System Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("System Settings")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    SystemSettingRow(title: "Maintenance Mode", description: "Disable user access", isEnabled: false)
                    SystemSettingRow(title: "Debug Logging", description: "Verbose system logs", isEnabled: true)
                    SystemSettingRow(title: "Auto Backup", description: "Automatic daily backups", isEnabled: true)
                    SystemSettingRow(title: "Rate Limiting", description: "API rate limits", isEnabled: true)
                }
            }
            
            // System Actions
            VStack(alignment: .leading, spacing: 12) {
                Text("System Actions")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ActionButton(title: "Restart Services", icon: "arrow.clockwise", color: .blue)
                    ActionButton(title: "Clear Cache", icon: "trash", color: .orange)
                    ActionButton(title: "Run Diagnostics", icon: "stethoscope", color: .green)
                    ActionButton(title: "Export Logs", icon: "square.and.arrow.up", color: .purple)
                }
            }
        }
    }
    
    private var logsContent: some View {
        VStack(spacing: 16) {
            // Log Filters
            HStack {
                Menu {
                    Button("All Levels") {}
                    Button("Error") {}
                    Button("Warning") {}
                    Button("Info") {}
                } label: {
                    Label("Level: All", systemImage: "line.3.horizontal.decrease.circle")
                }
                
                Spacer()
                
                Button {
                    // Refresh
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            
            // Logs
            VStack(alignment: .leading, spacing: 8) {
                AdminLogEntry(level: .error, message: "Failed to sync data", timestamp: "10:23:45")
                AdminLogEntry(level: .warning, message: "High memory usage detected", timestamp: "10:22:12")
                AdminLogEntry(level: .info, message: "User logged in successfully", timestamp: "10:20:33")
                AdminLogEntry(level: .info, message: "Hub created: Analytics Dashboard", timestamp: "10:18:45")
                AdminLogEntry(level: .warning, message: "Slow query detected", timestamp: "10:15:22")
            }
        }
    }
    
    private var databaseContent: some View {
        VStack(spacing: 16) {
            // Database Stats
            HStack(spacing: 12) {
                AdminStatCard(title: "Size", value: "2.4 GB", icon: "cylinder", color: .blue)
                AdminStatCard(title: "Records", value: "45.2K", icon: "doc.on.doc", color: .green)
                AdminStatCard(title: "Queries/s", value: "127", icon: "bolt", color: .yellow)
            }
            
            // Database Actions
            VStack(alignment: .leading, spacing: 12) {
                Text("Database Management")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ActionButton(title: "Backup Database", icon: "externaldrive", color: .blue)
                    ActionButton(title: "Optimize Tables", icon: "speedometer", color: .green)
                    ActionButton(title: "Run Migrations", icon: "arrow.up.doc", color: .purple)
                    ActionButton(title: "Export Data", icon: "square.and.arrow.up", color: .orange)
                }
            }
            
            // Recent Backups
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Backups")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    BackupRow(name: "Auto Backup", date: "2 hours ago", size: "2.4 GB", status: .success)
                    BackupRow(name: "Manual Backup", date: "1 day ago", size: "2.3 GB", status: .success)
                    BackupRow(name: "Auto Backup", date: "2 days ago", size: "2.2 GB", status: .success)
                }
            }
        }
    }
    
    private var integrationsContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Integrations")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    IntegrationCard(name: "CloudKit", description: "Cloud sync service", status: .connected)
                    IntegrationCard(name: "Analytics", description: "Usage analytics", status: .connected)
                    IntegrationCard(name: "Notifications", description: "Push notifications", status: .connected)
                    IntegrationCard(name: "Webhooks", description: "Event webhooks", status: .disconnected)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Integrations")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    AvailableIntegrationCard(name: "Slack", description: "Team communication")
                    AvailableIntegrationCard(name: "GitHub", description: "Code repository")
                    AvailableIntegrationCard(name: "Stripe", description: "Payment processing")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct UserRow: View {
    let name: String
    let email: String
    let role: String
    let status: UserStatus
    
    enum UserStatus {
        case active, inactive
        
        var color: Color {
            self == .active ? .green : .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(role)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.indigo.opacity(0.1))
                .foregroundStyle(.indigo)
                .cornerRadius(4)
            
            Button {
                // Edit
            } label: {
                Image(systemName: "ellipsis")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct RoleCard: View {
    let name: String
    let description: String
    let userCount: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.key")
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(userCount) users")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PermissionRow: View {
    let name: String
    let roles: [String]
    
    var body: some View {
        HStack {
            Text(name)
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(roles, id: \.self) { role in
                    Text(role)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.indigo.opacity(0.1))
                        .foregroundStyle(.indigo)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct SystemSettingRow: View {
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .labelsHidden()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
            // Action
        } label: {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AdminLogEntry: View {
    let level: LogLevel
    let message: String
    let timestamp: String
    
    enum LogLevel {
        case error, warning, info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: level.icon)
                .foregroundStyle(level.color)
                .frame(width: 20)
            
            Text(message)
                .font(.caption)
            
            Spacer()
            
            Text(timestamp)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct BackupRow: View {
    let name: String
    let date: String
    let size: String
    let status: BackupStatus
    
    enum BackupStatus {
        case success, failed
        
        var color: Color {
            self == .success ? .green : .red
        }
        
        var icon: String {
            self == .success ? "checkmark.circle.fill" : "xmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                HStack {
                    Text(date)
                    Text("•")
                    Text(size)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct IntegrationCard: View {
    let name: String
    let description: String
    let status: IntegrationStatus
    
    enum IntegrationStatus {
        case connected, disconnected
        
        var color: Color {
            self == .connected ? .green : .gray
        }
        
        var label: String {
            self == .connected ? "Connected" : "Disconnected"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(status.label)
                .font(.caption)
                .foregroundStyle(status.color)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AvailableIntegrationCard: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                // Connect
            } label: {
                Text("Connect")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    AdminCenterView()
}
