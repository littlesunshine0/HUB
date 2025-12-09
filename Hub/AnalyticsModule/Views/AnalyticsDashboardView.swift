//
//  AnalyticsDashboardView.swift
//  Hub
//
//  Dashboard view for analytics overview
//

import SwiftUI
import SwiftData

/// Main analytics dashboard view
struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [AnalyticsEvent]
    @Query private var sessions: [AnalyticsSession]
    @Query private var dailyAnalytics: [DailyAnalytics]
    
    @State private var selectedTimeRange: AnalyticsTimeRange = .last7Days
    @State private var selectedTab: DashboardTab = .overview
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Time range selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    ForEach(DashboardTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Divider()
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case .overview:
                        OverviewTab(
                            events: filteredEvents,
                            sessions: filteredSessions,
                            timeRange: selectedTimeRange
                        )
                    case .events:
                        EventsTab(events: filteredEvents)
                    case .users:
                        UsersTab(sessions: filteredSessions)
                    case .performance:
                        PerformanceTab(events: filteredEvents)
                    }
                }
            }
            .navigationTitle("Analytics Dashboard")
        }
    }
    
    private var filteredEvents: [AnalyticsEvent] {
        let startDate = selectedTimeRange.startDate
        return events.filter { $0.timestamp >= startDate }
    }
    
    private var filteredSessions: [AnalyticsSession] {
        let startDate = selectedTimeRange.startDate
        return sessions.filter { $0.startTime >= startDate }
    }
}

/// Overview tab showing key metrics
struct OverviewTab: View {
    let events: [AnalyticsEvent]
    let sessions: [AnalyticsSession]
    let timeRange: AnalyticsTimeRange
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsMetricCard(
                title: "Total Events",
                value: "\(events.count)",
                icon: "chart.bar",
                color: .blue
            )
            
            AnalyticsMetricCard(
                title: "Sessions",
                value: "\(sessions.count)",
                icon: "person.2",
                color: .green
            )
            
            AnalyticsMetricCard(
                title: "Avg Session Duration",
                value: averageSessionDuration,
                icon: "clock",
                color: .orange
            )
            
            AnalyticsMetricCard(
                title: "Events per Session",
                value: eventsPerSession,
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
        .padding()
        
        // Event type breakdown
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Types")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(eventTypeBreakdown, id: \.type) { item in
                EventTypeRow(
                    type: item.type,
                    count: item.count,
                    percentage: item.percentage
                )
            }
        }
        .padding(.vertical)
    }
    
    private var averageSessionDuration: String {
        guard !sessions.isEmpty else { return "0s" }
        let total = sessions.compactMap { $0.duration }.reduce(0, +)
        let average = total / Double(sessions.count)
        return String(format: "%.1fs", average)
    }
    
    private var eventsPerSession: String {
        guard !sessions.isEmpty else { return "0" }
        return String(format: "%.1f", Double(events.count) / Double(sessions.count))
    }
    
    private var eventTypeBreakdown: [(type: String, count: Int, percentage: Double)] {
        let grouped = Dictionary(grouping: events) { $0.type }
        let total = Double(events.count)
        
        return grouped.map { type, events in
            (
                type: type.replacingOccurrences(of: "_", with: " ").capitalized,
                count: events.count,
                percentage: total > 0 ? (Double(events.count) / total) * 100 : 0
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(10)
        .map { $0 }
    }
}

/// Events tab showing event details
private struct EventsTab: View {
    let events: [AnalyticsEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Events")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(events.prefix(50)) { event in
                AnalyticsEventRow(event: event)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

/// Users tab showing user analytics
struct UsersTab: View {
    let sessions: [AnalyticsSession]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsMetricCard(
                title: "Total Sessions",
                value: "\(sessions.count)",
                icon: "person.2",
                color: .blue
            )
            
            AnalyticsMetricCard(
                title: "Active Users",
                value: "\(uniqueUsers)",
                icon: "person.circle",
                color: .green
            )
            
            AnalyticsMetricCard(
                title: "Avg Events/User",
                value: String(format: "%.1f", averageEventsPerUser),
                icon: "chart.bar",
                color: .orange
            )
            
            AnalyticsMetricCard(
                title: "Active Sessions",
                value: "\(activeSessions)",
                icon: "circle.fill",
                color: .purple
            )
        }
        .padding()
    }
    
    private var uniqueUsers: Int {
        Set(sessions.compactMap { $0.userId }).count
    }
    
    private var averageEventsPerUser: Double {
        guard uniqueUsers > 0 else { return 0 }
        let totalEvents = sessions.reduce(0) { $0 + $1.eventCount }
        return Double(totalEvents) / Double(uniqueUsers)
    }
    
    private var activeSessions: Int {
        sessions.filter { $0.isActive }.count
    }
}

/// Performance tab showing performance metrics
struct PerformanceTab: View {
    let events: [AnalyticsEvent]
    
    var performanceEvents: [AnalyticsEvent] {
        events.filter { $0.type == EventType.performanceMetric.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            if performanceEvents.isEmpty {
                ContentUnavailableView(
                    "No Performance Data",
                    systemImage: "speedometer",
                    description: Text("No performance metrics have been recorded yet")
                )
                .padding()
            } else {
                ForEach(performanceEvents.prefix(20)) { event in
                    PerformanceEventRow(event: event)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}

/// Metric card for displaying key analytics metrics
struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Event type row showing breakdown
struct EventTypeRow: View {
    let type: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(type)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 4)
            .cornerRadius(2)
        }
        .padding(.horizontal)
    }
}

/// Performance event row
struct PerformanceEventRow: View {
    let event: AnalyticsEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let metricName = event.getMetadata()[EventMetadata.performanceMetricName] as? String {
                    Text(metricName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(event.timestamp.formatted(date: .omitted, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let value = event.getMetadata()[EventMetadata.performanceMetricValue] as? Double {
                Text(String(format: "%.2f", value))
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Time range options for analytics
enum AnalyticsTimeRange: String, CaseIterable {
    case last24Hours = "24 Hours"
    case last7Days = "7 Days"
    case last30Days = "30 Days"
    case last90Days = "90 Days"
    
    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .last24Hours:
            return calendar.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        case .last7Days:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        case .last90Days:
            return calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        }
    }
}

/// Dashboard tabs
enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case events = "Events"
    case users = "Users"
    case performance = "Performance"
}

#Preview {
    AnalyticsDashboardView()
        .modelContainer(for: [AnalyticsEvent.self, AnalyticsSession.self, DailyAnalytics.self], inMemory: true)
}
