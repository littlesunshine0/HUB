//
//  ActionCenterView.swift
//  Hub
//
//  Centralized notifications and quick-access actions
//

import SwiftUI

struct ActionCenterView: View {
    @StateObject private var notificationService = AppNotificationService.shared
    @State private var selectedFilter: ActionFilter = .all
    @State private var showQuickActions = true
    
    enum ActionFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case important = "Important"
        case today = "Today"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Quick Actions
                if showQuickActions {
                    quickActionsSection
                }
                
                // Notifications
                notificationsSection
            }
            .padding()
        }
        .navigationTitle("Action Center")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Clear Unread Count") {
                        notificationService.clearUnreadCount()
                    }
                    Button("Clear All") {
                        notificationService.clearAll()
                    }
                    Divider()
                    Toggle("Show Quick Actions", isOn: $showQuickActions)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange.gradient)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(notificationService.unreadCount)")
                        .font(.system(size: 36, weight: .bold))
                    Text("Unread")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ActionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(icon: "plus.circle.fill", title: "New Hub", color: .blue) {
                    // Action
                }
                QuickActionButton(icon: "square.and.arrow.down.fill", title: "Download", color: .cyan) {
                    // Action
                }
                QuickActionButton(icon: "gear", title: "Settings", color: .gray) {
                    // Action
                }
                QuickActionButton(icon: "lock.shield.fill", title: "Security", color: .red) {
                    // Action
                }
                QuickActionButton(icon: "chart.bar.fill", title: "Analytics", color: .green) {
                    // Action
                }
                QuickActionButton(icon: "questionmark.circle.fill", title: "Help", color: .purple) {
                    // Action
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)
            
            if notificationService.notifications.isEmpty {
                emptyState
            } else {
                ForEach(filteredNotifications) { notification in
                    ActionCenterNotificationRow(notification: notification)
                }
            }
        }
    }
    
    private var filteredNotifications: [AppNotification] {
        switch selectedFilter {
        case .all:
            return notificationService.notifications
        case .unread:
            // All notifications are considered unread until cleared
            return notificationService.notifications
        case .important:
            return notificationService.notifications.filter { $0.level == .error || $0.level == .warning }
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            return notificationService.notifications.filter {
                Calendar.current.isDate($0.timestamp, inSameDayAs: today)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Notifications")
                .font(.headline)
            Text("You're all caught up!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ActionCenterNotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.level.icon)
                .font(.title3)
                .foregroundStyle(notification.level.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.body)
                    .lineLimit(2)
                Text(notification.timestamp, style: .relative)
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

#Preview {
    NavigationStack {
        ActionCenterView()
    }
}
