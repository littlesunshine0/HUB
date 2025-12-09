//
//  SecurityCenterView.swift
//  Hub
//
//  Centralized security status and controls
//

import SwiftUI

struct SecurityCenterView: View {
    @State private var securityScore: Double = 0.85
    @State private var showSecurityScan = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Security Score
                securityScoreSection
                
                // Quick Status
                quickStatusSection
                
                // Security Features
                securityFeaturesSection
                
                // Recent Activity
                recentActivitySection
                
                // Recommendations
                recommendationsSection
            }
            .padding()
        }
        .navigationTitle("Security Center")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSecurityScan = true
                } label: {
                    Label("Scan", systemImage: "shield.checkered")
                }
            }
        }
        .sheet(isPresented: $showSecurityScan) {
            SecurityScanView()
        }
    }
    
    private var securityScoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.separatorColor), lineWidth: 20)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: securityScore)
                    .stroke(scoreColor.gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(securityScore * 100))")
                        .font(.system(size: 48, weight: .bold))
                    Text("Security Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(scoreDescription)
                .font(.headline)
                .foregroundStyle(scoreColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var quickStatusSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SecurityStatusCard(
                title: "Encryption",
                value: "Active",
                icon: "lock.fill",
                color: .green,
                status: .good
            )
            SecurityStatusCard(
                title: "2FA",
                value: "Enabled",
                icon: "lock.shield.fill",
                color: .green,
                status: .good
            )
            SecurityStatusCard(
                title: "Backups",
                value: "2 hours ago",
                icon: "externaldrive.fill",
                color: .blue,
                status: .good
            )
            SecurityStatusCard(
                title: "Threats",
                value: "None",
                icon: "checkmark.shield.fill",
                color: .green,
                status: .good
            )
        }
    }
    
    private var securityFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Features")
                .font(.headline)
            
            VStack(spacing: 12) {
                SecurityFeatureRow(
                    title: "Data Encryption",
                    description: "End-to-end encryption for all data",
                    icon: "lock.fill",
                    isEnabled: true
                )
                SecurityFeatureRow(
                    title: "Two-Factor Authentication",
                    description: "Extra layer of account security",
                    icon: "lock.shield.fill",
                    isEnabled: true
                )
                SecurityFeatureRow(
                    title: "Biometric Lock",
                    description: "Face ID / Touch ID protection",
                    icon: "faceid",
                    isEnabled: true
                )
                SecurityFeatureRow(
                    title: "Auto-Lock",
                    description: "Lock app after inactivity",
                    icon: "lock.rotation",
                    isEnabled: false
                )
                SecurityFeatureRow(
                    title: "Secure Backup",
                    description: "Encrypted cloud backups",
                    icon: "icloud.and.arrow.up",
                    isEnabled: true
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            VStack(spacing: 12) {
                SecurityActivityRow(
                    title: "Successful Login",
                    description: "MacBook Pro • San Francisco, CA",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    time: "2 minutes ago"
                )
                SecurityActivityRow(
                    title: "Password Changed",
                    description: "Account security updated",
                    icon: "key.fill",
                    color: .blue,
                    time: "3 days ago"
                )
                SecurityActivityRow(
                    title: "2FA Enabled",
                    description: "Two-factor authentication activated",
                    icon: "lock.shield.fill",
                    color: .green,
                    time: "1 week ago"
                )
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            VStack(spacing: 12) {
                RecommendationCard(
                    title: "Enable Auto-Lock",
                    description: "Protect your data when away from device",
                    icon: "lock.rotation",
                    priority: .medium
                )
                RecommendationCard(
                    title: "Review Permissions",
                    description: "Check which apps have access to your data",
                    icon: "hand.raised",
                    priority: .low
                )
            }
        }
    }
    
    private var scoreColor: Color {
        switch securityScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
    
    private var scoreDescription: String {
        switch securityScore {
        case 0.8...1.0: return "Excellent Security"
        case 0.6..<0.8: return "Good Security"
        default: return "Needs Attention"
        }
    }
}

struct SecurityStatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let status: SecurityStatus
    
    enum SecurityStatus {
        case good, warning, critical
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct SecurityFeatureRow: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isEnabled ? .green : .secondary)
                .frame(width: 32)
            
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

struct SecurityActivityRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        
        var label: String {
            switch self {
            case .high: return "High Priority"
            case .medium: return "Medium Priority"
            case .low: return "Low Priority"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(priority.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(priority.label)
                    .font(.caption2)
                    .foregroundStyle(priority.color)
            }
            
            Spacer()
            
            Button {
                // Take action
            } label: {
                Text("Fix")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(priority.color)
                    .foregroundStyle(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(priority.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SecurityScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = false
    @State private var scanProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80))
                    .foregroundStyle(.red.gradient)
                    .rotationEffect(.degrees(isScanning ? 360 : 0))
                    .animation(isScanning ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isScanning)
                
                VStack(spacing: 8) {
                    Text(isScanning ? "Scanning..." : "Security Scan")
                        .font(.title.bold())
                    Text(isScanning ? "Checking for vulnerabilities" : "Run a comprehensive security check")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if isScanning {
                    ProgressView(value: scanProgress)
                        .frame(width: 200)
                }
                
                Spacer()
                
                Button {
                    if isScanning {
                        isScanning = false
                    } else {
                        startScan()
                    }
                } label: {
                    Text(isScanning ? "Cancel" : "Start Scan")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isScanning ? Color.red : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding()
            }
            .padding()
            .navigationTitle("Security Scan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startScan() {
        isScanning = true
        // Simulate scan
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            scanProgress += 0.05
            if scanProgress >= 1.0 {
                timer.invalidate()
                isScanning = false
                scanProgress = 0
            }
        }
    }
}

#Preview {
    NavigationStack {
        SecurityCenterView()
    }
}
