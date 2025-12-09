//
//  ControlCenterView.swift
//  Hub
//
//  Centralized settings and configuration management
//

import SwiftUI

struct ControlCenterView: View {
    @State private var selectedCategory: SettingsCategory = .general
    
    enum SettingsCategory: String, CaseIterable, Identifiable {
        case general = "General"
        case appearance = "Appearance"
        case privacy = "Privacy"
        case storage = "Storage"
        case sync = "Sync"
        case advanced = "Advanced"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .privacy: return "hand.raised"
            case .storage: return "externaldrive"
            case .sync: return "arrow.triangle.2.circlepath"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SettingsCategory.allCases, selection: $selectedCategory) { category in
                Label(category.rawValue, systemImage: category.icon)
                    .tag(category)
            }
            .navigationTitle("Control Center")
        } detail: {
            ScrollView {
                VStack(spacing: 24) {
                    categoryHeader
                    settingsContent
                }
                .padding()
            }
        }
    }
    
    private var categoryHeader: some View {
        HStack {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 40))
                .foregroundStyle(.blue.gradient)
            
            VStack(alignment: .leading) {
                Text(selectedCategory.rawValue)
                    .font(.title.bold())
                Text("Configure \(selectedCategory.rawValue.lowercased()) settings")
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
    private var settingsContent: some View {
        switch selectedCategory {
        case .general:
            generalSettings
        case .appearance:
            appearanceSettings
        case .privacy:
            privacySettings
        case .storage:
            storageSettings
        case .sync:
            syncSettings
        case .advanced:
            advancedSettings
        }
    }
    
    private var generalSettings: some View {
        VStack(spacing: 16) {
            SettingsGroup(title: "Application") {
                SettingsToggle(title: "Launch at Login", icon: "power", isOn: .constant(false))
                SettingsToggle(title: "Show in Menu Bar", icon: "menubar.rectangle", isOn: .constant(true))
                SettingsToggle(title: "Enable Notifications", icon: "bell", isOn: .constant(true))
            }
            
            SettingsGroup(title: "Updates") {
                SettingsToggle(title: "Automatic Updates", icon: "arrow.down.circle", isOn: .constant(true))
                SettingsButton(title: "Check for Updates", icon: "arrow.clockwise") {
                    // Check updates
                }
            }
        }
    }
    
    private var appearanceSettings: some View {
        VStack(spacing: 16) {
            SettingsGroup(title: "Theme") {
                SettingsPicker(title: "Appearance", icon: "paintbrush", selection: .constant("System"), options: ["Light", "Dark", "System"])
                SettingsPicker(title: "Accent Color", icon: "paintpalette", selection: .constant("Blue"), options: ["Blue", "Purple", "Pink", "Orange"])
            }
            
            SettingsGroup(title: "Display") {
                SettingsToggle(title: "Show Sidebar", icon: "sidebar.left", isOn: .constant(true))
                SettingsToggle(title: "Compact Mode", icon: "rectangle.compress.vertical", isOn: .constant(false))
            }
        }
    }
    
    private var privacySettings: some View {
        VStack(spacing: 16) {
            SettingsGroup(title: "Data Collection") {
                SettingsToggle(title: "Analytics", icon: "chart.bar", isOn: .constant(false))
                SettingsToggle(title: "Crash Reports", icon: "exclamationmark.triangle", isOn: .constant(true))
            }
            
            SettingsGroup(title: "Permissions") {
                SettingsButton(title: "Manage Permissions", icon: "hand.raised") {
                    // Manage permissions
                }
            }
        }
    }
    
    private var storageSettings: some View {
        VStack(spacing: 16) {
            SettingsGroup(title: "Storage Usage") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Used: 2.4 GB")
                            .font(.headline)
                        Text("Available: 12.6 GB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ProgressView(value: 0.16)
                        .frame(width: 100)
                }
                .padding()
            }
            
            SettingsGroup(title: "Cache") {
                SettingsButton(title: "Clear Cache", icon: "trash", destructive: true) {
                    // Clear cache
                }
            }
        }
    }
    
    private var syncSettings: some View {
        VStack(spacing: 16) {
            SettingsGroup(title: "Cloud Sync") {
                SettingsToggle(title: "iCloud Sync", icon: "icloud", isOn: .constant(true))
                SettingsToggle(title: "Auto Sync", icon: "arrow.triangle.2.circlepath", isOn: .constant(true))
            }
            
            SettingsGroup(title: "Sync Status") {
                HStack {
                    Label("Last Synced", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("2 minutes ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
    
    private var advancedSettings: some View {
        VStack(spacing: 16) {
            SettingsGroup(title: "Developer") {
                SettingsToggle(title: "Debug Mode", icon: "ant", isOn: .constant(false))
                SettingsToggle(title: "Verbose Logging", icon: "doc.text", isOn: .constant(false))
            }
            
            SettingsGroup(title: "Danger Zone") {
                SettingsButton(title: "Reset All Settings", icon: "arrow.counterclockwise", destructive: true) {
                    // Reset settings
                }
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: icon)
        }
        .padding()
    }
}

struct SettingsPicker: View {
    let title: String
    let icon: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Picker(selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        } label: {
            Label(title, systemImage: icon)
        }
        .padding()
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    var destructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(destructive ? .red : .primary)
        }
        .buttonStyle(.plain)
        .padding()
    }
}

#Preview {
    ControlCenterView()
}
