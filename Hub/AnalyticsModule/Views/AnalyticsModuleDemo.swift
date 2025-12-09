//
//  AnalyticsModuleDemo.swift
//  Hub
//
//  Demo view for the Analytics Module
//

import SwiftUI
import SwiftData

/// Demo view showcasing the Analytics Module
struct AnalyticsModuleDemo: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var collector: AnalyticsCollector
    
    @State private var selectedView: AnalyticsView = .dashboard
    
    init() {
        // Create a temporary model container for demo
        let schema = Schema([
            AnalyticsEvent.self,
            AnalyticsSession.self,
            DailyAnalytics.self,
            MarketplaceTemplateAnalytics.self,
            UserAnalytics.self,
            SearchAnalytics.self,
            AnalyticsPerformanceMetrics.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        
        _collector = StateObject(wrappedValue: AnalyticsCollector.shared(modelContainer: container))
    }
    
    var body: some View {
        NavigationSplitView {
            List(AnalyticsView.allCases, id: \.self, selection: $selectedView) { view in
                Label(view.rawValue, systemImage: view.icon)
            }
            .navigationTitle("Analytics")
        } detail: {
            Group {
                switch selectedView {
                case .dashboard:
                    AnalyticsDashboardView()
                case .events:
                    AnalyticsEventListView()
                case .testEvents:
                    TestEventsView(collector: collector)
                }
            }
        }
        .onAppear {
            // Start a demo session
            collector.startSession()
            
            // Generate some demo events
            generateDemoEvents()
        }
    }
    
    private func generateDemoEvents() {
        // Template events
        for i in 1...5 {
            let templateId = UUID()
            collector.trackTemplateView(templateId: templateId)
            
            if i % 2 == 0 {
                collector.trackTemplateDownload(templateId: templateId)
            }
        }
        
        // Search events
        let searches = ["authentication", "dashboard", "settings", "profile", "charts"]
        for query in searches {
            collector.trackSearch(query: query, resultsCount: Int.random(in: 1...20))
        }
        
        // Performance events
        collector.trackPerformance(metricName: "app_launch_time", value: 1.23)
        collector.trackPerformance(metricName: "template_load_time", value: 0.45)
        collector.trackPerformance(metricName: "search_response_time", value: 0.12)
        
        // Page views
        let screens = ["Home", "Templates", "Settings", "Profile", "Analytics"]
        for screen in screens {
            collector.trackPageView(screenName: screen)
        }
        
        // Feedback
        collector.trackFeedback(rating: 5, comment: "Great app!", itemId: UUID())
        collector.trackFeedback(rating: 4, comment: "Very useful", itemId: UUID())
    }
}

/// Test events view for generating test data
struct TestEventsView: View {
    @ObservedObject var collector: AnalyticsCollector
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Test Event Generator")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Generate test analytics events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                VStack(spacing: 12) {
                    TestEventButton(
                        title: "Track Template View",
                        icon: "doc.text",
                        color: .blue
                    ) {
                        collector.trackTemplateView(templateId: UUID())
                    }
                    
                    TestEventButton(
                        title: "Track Template Download",
                        icon: "arrow.down.circle",
                        color: .green
                    ) {
                        collector.trackTemplateDownload(templateId: UUID())
                    }
                    
                    TestEventButton(
                        title: "Track Search",
                        icon: "magnifyingglass",
                        color: .orange
                    ) {
                        let queries = ["authentication", "dashboard", "settings", "profile"]
                        collector.trackSearch(
                            query: queries.randomElement() ?? "test",
                            resultsCount: Int.random(in: 1...20)
                        )
                    }
                    
                    TestEventButton(
                        title: "Track Purchase",
                        icon: "cart",
                        color: .purple
                    ) {
                        collector.trackPurchase(
                            itemId: UUID(),
                            amount: Decimal(Double.random(in: 9.99...99.99)),
                            currency: "USD"
                        )
                    }
                    
                    TestEventButton(
                        title: "Track Feedback",
                        icon: "bubble.left",
                        color: .pink
                    ) {
                        collector.trackFeedback(
                            rating: Int.random(in: 1...5),
                            comment: "Test feedback",
                            itemId: UUID()
                        )
                    }
                    
                    TestEventButton(
                        title: "Track Performance",
                        icon: "speedometer",
                        color: .cyan
                    ) {
                        collector.trackPerformance(
                            metricName: "test_metric",
                            value: Double.random(in: 0.1...5.0)
                        )
                    }
                    
                    TestEventButton(
                        title: "Track Error",
                        icon: "exclamationmark.triangle",
                        color: .red
                    ) {
                        collector.trackError(
                            message: "Test error occurred",
                            code: "TEST_ERROR"
                        )
                    }
                    
                    TestEventButton(
                        title: "Track Page View",
                        icon: "eye",
                        color: .indigo
                    ) {
                        let screens = ["Home", "Templates", "Settings", "Profile"]
                        collector.trackPageView(
                            screenName: screens.randomElement() ?? "Test"
                        )
                    }
                }
                .padding()
                
                Divider()
                
                VStack(spacing: 8) {
                    Text("Event Count: \(collector.eventCount)")
                        .font(.headline)
                    
                    if let session = collector.getCurrentSession() {
                        Text("Session Duration: \(String(format: "%.1f", session.currentDuration))s")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Events in Session: \(session.eventCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding()
            }
            .padding()
        }
    }
}

/// Button for generating test events
struct TestEventButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(color)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Analytics view options
enum AnalyticsView: String, CaseIterable {
    case dashboard = "Dashboard"
    case events = "Events"
    case testEvents = "Test Events"
    
    var icon: String {
        switch self {
        case .dashboard:
            return "chart.bar"
        case .events:
            return "list.bullet"
        case .testEvents:
            return "flask"
        }
    }
}

#Preview {
    AnalyticsModuleDemo()
}
