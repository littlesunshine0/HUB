import SwiftUI
import Combine

// MARK: - Enterprise Settings View

struct EnterpriseSettingsView: View {
    @ObservedObject var viewModel: EnterpriseSettingsViewModel
    
    var body: some View {
        Form {
            // Team Management Section
            Section("Team Management") {
                TextField("Organization ID", text: Binding(
                    get: { viewModel.preferences.organizationID ?? "" },
                    set: { viewModel.updateOrganizationID($0) }
                ))
                
                TextField("Team Name", text: $viewModel.preferences.teamName)
                
                Stepper("Max Team Members: \(viewModel.preferences.maxTeamMembers)",
                       value: $viewModel.preferences.maxTeamMembers,
                       in: 1...1000)
                
                Toggle("Enable Team Sync", isOn: $viewModel.preferences.enableTeamSync)
            }
            
            // Automation Settings Section
            Section("Automation") {
                Picker("Automation Level", selection: $viewModel.preferences.automationLevel) {
                    ForEach(EnterprisePreferences.AutomationLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                
                Text(viewModel.preferences.automationLevel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Automated Quality Control", isOn: $viewModel.preferences.enableAutomatedQualityControl)
                Toggle("Automated Deployment", isOn: $viewModel.preferences.enableAutomatedDeployment)
                Toggle("Automated Testing", isOn: $viewModel.preferences.enableAutomatedTesting)
            }
            
            // Analytics & Monitoring Section
            Section("Analytics & Monitoring") {
                Toggle("Enable Analytics", isOn: $viewModel.preferences.enableAnalytics)
                
                if viewModel.preferences.enableAnalytics {
                    Stepper("Retention: \(viewModel.preferences.analyticsRetentionDays) days",
                           value: $viewModel.preferences.analyticsRetentionDays,
                           in: 7...365)
                }
                
                Toggle("Performance Monitoring", isOn: $viewModel.preferences.enablePerformanceMonitoring)
                Toggle("Error Tracking", isOn: $viewModel.preferences.enableErrorTracking)
            }
            
            // Security & Compliance Section
            Section("Security & Compliance") {
                Toggle("Require Two-Factor Auth", isOn: $viewModel.preferences.requireTwoFactorAuth)
                
                Stepper("Session Timeout: \(viewModel.preferences.sessionTimeoutMinutes) min",
                       value: $viewModel.preferences.sessionTimeoutMinutes,
                       in: 5...480)
                
                Toggle("Enable Audit Logging", isOn: $viewModel.preferences.enableAuditLogging)
                
                Picker("Data Residency", selection: $viewModel.preferences.dataResidencyRegion) {
                    ForEach(EnterprisePreferences.DataRegion.allCases, id: \.self) { region in
                        Text(region.description).tag(region)
                    }
                }
            }
            
            // SLA & Support Section
            Section("SLA & Support") {
                Picker("SLA Level", selection: $viewModel.preferences.slaLevel) {
                    ForEach(EnterprisePreferences.SLALevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                
                HStack {
                    Text("Uptime Guarantee:")
                    Spacer()
                    Text("\(viewModel.preferences.slaLevel.uptimeGuarantee, specifier: "%.2f")%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Response Time:")
                    Spacer()
                    Text(viewModel.preferences.slaLevel.responseTime)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Priority Support", isOn: $viewModel.preferences.prioritySupport)
                Toggle("Dedicated Account Manager", isOn: $viewModel.preferences.dedicatedAccountManager)
            }
            
            // Licensing Section
            Section("Licensing") {
                Picker("License Type", selection: $viewModel.preferences.licenseType) {
                    ForEach(EnterprisePreferences.LicenseType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Features:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.preferences.licenseType.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Stepper("Seat Count: \(viewModel.preferences.seatCount)",
                       value: $viewModel.preferences.seatCount,
                       in: 1...10000)
                
                Picker("Volume Discount", selection: $viewModel.preferences.volumeDiscountTier) {
                    ForEach(EnterprisePreferences.VolumeTier.allCases, id: \.self) { tier in
                        Text(tier.rawValue).tag(tier)
                    }
                }
                
                if viewModel.preferences.volumeDiscountTier != .none {
                    HStack {
                        Text("Discount:")
                        Spacer()
                        Text("\(viewModel.preferences.volumeDiscountTier.discountPercentage, specifier: "%.0f")%")
                            .foregroundColor(.green)
                            .bold()
                    }
                }
            }
            
            // Custom Settings Section
            Section("Custom Settings") {
                NavigationLink("Compliance Rules (\(viewModel.preferences.customComplianceRules.count))") {
                    ComplianceRulesView(rules: $viewModel.preferences.customComplianceRules)
                }
                
                NavigationLink("Custom Integrations (\(viewModel.preferences.customIntegrations.count))") {
                    CustomIntegrationsView(integrations: $viewModel.preferences.customIntegrations)
                }
            }
            
            // Actions Section
            Section {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Save Enterprise Settings") {
                    Task {
                        await viewModel.saveSettings()
                    }
                }
                .disabled(viewModel.isSaving)
                
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Enterprise Settings")
    }
}

// MARK: - Compliance Rules View

struct ComplianceRulesView: View {
    @Binding var rules: [String]
    @State private var newRule: String = ""
    
    var body: some View {
        List {
            Section("Add New Rule") {
                HStack {
                    TextField("Enter compliance rule", text: $newRule)
                    Button("Add") {
                        if !newRule.isEmpty {
                            rules.append(newRule)
                            newRule = ""
                        }
                    }
                    .disabled(newRule.isEmpty)
                }
            }
            
            Section("Current Rules") {
                ForEach(rules, id: \.self) { rule in
                    Text(rule)
                }
                .onDelete { indexSet in
                    rules.remove(atOffsets: indexSet)
                }
            }
        }
        .navigationTitle("Compliance Rules")
    }
}

// MARK: - Custom Integrations View

struct CustomIntegrationsView: View {
    @Binding var integrations: [String: String]
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    
    var body: some View {
        List {
            Section("Add New Integration") {
                TextField("Integration Name", text: $newKey)
                TextField("Configuration", text: $newValue)
                Button("Add") {
                    if !newKey.isEmpty && !newValue.isEmpty {
                        integrations[newKey] = newValue
                        newKey = ""
                        newValue = ""
                    }
                }
                .disabled(newKey.isEmpty || newValue.isEmpty)
            }
            
            Section("Current Integrations") {
                ForEach(Array(integrations.keys.sorted()), id: \.self) { key in
                    VStack(alignment: .leading) {
                        Text(key)
                            .font(.headline)
                        Text(integrations[key] ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let keys = Array(integrations.keys.sorted())
                    for index in indexSet {
                        integrations.removeValue(forKey: keys[index])
                    }
                }
            }
        }
        .navigationTitle("Custom Integrations")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var preferences = EnterprisePreferences()
    
    NavigationStack {
        Form {
            Text("Enterprise Settings Preview")
        }
    }
}
