//
//  AnalyticsEventCollectionView.swift
//  Hub
//
//  UI for monitoring and managing analytics event collection
//

import SwiftUI
import SwiftData

/// View for monitoring analytics event collection pipeline
struct AnalyticsEventCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var pipeline: AnalyticsEventPipeline
    @State private var selectedTab: CollectionTab = .status
    @State private var showingSettings = false
    
    init(modelContainer: ModelContainer) {
        _pipeline = StateObject(wrappedValue: AnalyticsEventPipeline.shared(modelContainer: modelContainer))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pipeline status header
                PipelineStatusHeader(pipeline: pipeline)
                
                Divider()
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    ForEach(CollectionTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case .status:
                        StatusTab(pipeline: pipeline)
                    case .events:
                        EventCollectionEventsTab()
                    case .metrics:
                        MetricsTab(pipeline: pipeline)
                    }
                }
            }
            .navigationTitle("Event Collection")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                CollectionSettingsView(pipeline: pipeline)
            }
        }
    }
}

/// Pipeline status header
struct PipelineStatusHeader: View {
    @ObservedObject var pipeline: AnalyticsEventPipeline
    @State private var health: PipelineHealth?
    
    var body: some View {
        HStack(spacing: 20) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(pipeline.isRunning ? "Running" : "Stopped")
                    .font(.headline)
            }
            
            Spacer()
            
            // Metrics
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(pipeline.eventsProcessed) processed")
                    .font(.caption)
                Text("\(pipeline.eventsQueued) queued")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Control button
            Button {
                if pipeline.isRunning {
                    pipeline.pause()
                } else {
                    pipeline.resume()
                }
            } label: {
                Image(systemName: pipeline.isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(pipeline.isRunning ? .orange : .green)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .task {
            health = await pipeline.getHealth()
        }
    }
    
    private var statusColor: Color {
        guard let health = health else { return .gray }
        
        switch health.status {
        case .healthy:
            return .green
        case .degraded:
            return .orange
        case .critical:
            return .red
        case .stopped:
            return .gray
        }
    }
}

/// Status tab showing pipeline health
struct StatusTab: View {
    @ObservedObject var pipeline: AnalyticsEventPipeline
    @State private var health: PipelineHealth?
    @State private var status: PipelineStatus?
    
    var body: some View {
        VStack(spacing: 16) {
            // Health status
            if let health = health {
                HealthStatusCard(health: health)
            }
            
            // Pipeline metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                EventCollectionMetricCard(
                    title: "Events Processed",
                    value: "\(pipeline.eventsProcessed)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                EventCollectionMetricCard(
                    title: "Events Queued",
                    value: "\(pipeline.eventsQueued)",
                    icon: "clock",
                    color: .orange
                )
                
                EventCollectionMetricCard(
                    title: "Processing Rate",
                    value: String(format: "%.1f/s", pipeline.processingRate),
                    icon: "speedometer",
                    color: .blue
                )
                
                EventCollectionMetricCard(
                    title: "Status",
                    value: pipeline.isRunning ? "Active" : "Paused",
                    icon: pipeline.isRunning ? "play.circle" : "pause.circle",
                    color: pipeline.isRunning ? .green : .gray
                )
            }
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    Task {
                        try? await pipeline.triggerAggregation()
                    }
                } label: {
                    Label("Trigger Aggregation", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    Task {
                        await pipeline.stop()
                        pipeline.start()
                    }
                } label: {
                    Label("Restart Pipeline", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top)
        }
        .padding()
        .task {
            await updateStatus()
        }
        .refreshable {
            await updateStatus()
        }
    }
    
    private func updateStatus() async {
        health = await pipeline.getHealth()
        status = pipeline.getStatus()
    }
}

/// Health status card
struct HealthStatusCard: View {
    let health: PipelineHealth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pipeline Health")
                        .font(.headline)
                    Text(health.status.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Queue Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(health.queueSize)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Processing Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f/s", health.processingRate))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            Text("Last updated: \(health.lastUpdate.formatted(date: .omitted, time: .standard))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch health.status {
        case .healthy:
            return .green
        case .degraded:
            return .orange
        case .critical:
            return .red
        case .stopped:
            return .gray
        }
    }
    
    private var statusIcon: String {
        switch health.status {
        case .healthy:
            return "checkmark.circle.fill"
        case .degraded:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.circle.fill"
        case .stopped:
            return "stop.circle.fill"
        }
    }
}

/// Events tab showing recent events
private struct EventCollectionEventsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AnalyticsEvent.timestamp, order: .reverse) private var events: [AnalyticsEvent]
    @State private var selectedEvent: AnalyticsEvent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Events")
                .font(.headline)
                .padding(.horizontal)
            
            if events.isEmpty {
                ContentUnavailableView(
                    "No Events",
                    systemImage: "chart.bar",
                    description: Text("No analytics events have been collected yet")
                )
                .padding()
            } else {
                ForEach(events.prefix(50)) { event in
                    AnalyticsEventRow(event: event)
                        .padding(.horizontal)
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            }
        }
        .padding(.vertical)
        .sheet(item: $selectedEvent) { event in
            AnalyticsEventDetailView(event: event)
        }
    }
}

/// Metrics tab showing collection metrics
struct MetricsTab: View {
    @ObservedObject var pipeline: AnalyticsEventPipeline
    @Query private var events: [AnalyticsEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collection Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            // Event type distribution
            VStack(alignment: .leading, spacing: 12) {
                Text("Event Types")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                ForEach(eventTypeDistribution, id: \.type) { item in
                    EventTypeDistributionRow(
                        type: item.type,
                        count: item.count,
                        percentage: item.percentage
                    )
                }
            }
            
            // Processing metrics
            VStack(alignment: .leading, spacing: 12) {
                Text("Processing Metrics")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    EventCollectionMetricCard(
                        title: "Total Events",
                        value: "\(events.count)",
                        icon: "chart.bar",
                        color: .blue
                    )
                    
                    EventCollectionMetricCard(
                        title: "Processed",
                        value: "\(processedCount)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    EventCollectionMetricCard(
                        title: "Pending",
                        value: "\(pendingCount)",
                        icon: "clock",
                        color: .orange
                    )
                    
                    EventCollectionMetricCard(
                        title: "Success Rate",
                        value: String(format: "%.1f%%", successRate),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var eventTypeDistribution: [(type: String, count: Int, percentage: Double)] {
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
    
    private var processedCount: Int {
        events.filter { $0.processed }.count
    }
    
    private var pendingCount: Int {
        events.filter { !$0.processed }.count
    }
    
    private var successRate: Double {
        guard !events.isEmpty else { return 0 }
        return (Double(processedCount) / Double(events.count)) * 100
    }
}

/// Event type distribution row
struct EventTypeDistributionRow: View {
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

/// Metric card
private struct EventCollectionMetricCard: View {
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
                .font(.title2)
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

/// Analytics event detail view
struct AnalyticsEventDetailView: View {
    let event: AnalyticsEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Information") {
                    LabeledContent("ID", value: event.id.uuidString)
                    LabeledContent("Type", value: event.type)
                    LabeledContent("Timestamp", value: event.timestamp.formatted())
                    if let duration = event.duration {
                        LabeledContent("Duration", value: String(format: "%.2fs", duration))
                    }
                    LabeledContent("Processed", value: event.processed ? "Yes" : "No")
                }
                
                Section("Identifiers") {
                    if let userId = event.userId {
                        LabeledContent("User ID", value: userId.uuidString)
                    }
                    if let itemId = event.itemId {
                        LabeledContent("Item ID", value: itemId.uuidString)
                    }
                    LabeledContent("Session ID", value: event.sessionId.uuidString)
                }
                
                Section("Metadata") {
                    let metadata = event.getMetadata()
                    if metadata.isEmpty {
                        Text("No metadata")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                            LabeledContent(key, value: "\(metadata[key] ?? "")")
                        }
                    }
                }
            }
            .navigationTitle("Event Details")
            #if os(iOS)
            #endif
        }
    }
}

/// Collection settings view
struct CollectionSettingsView: View {
    @ObservedObject var pipeline: AnalyticsEventPipeline
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Pipeline Control") {
                    Toggle("Enable Collection", isOn: .constant(pipeline.isRunning))
                        .onChange(of: pipeline.isRunning) { _, newValue in
                            if newValue {
                                pipeline.start()
                            } else {
                                Task {
                                    await pipeline.stop()
                                }
                            }
                        }
                }
                
                Section("Status") {
                    LabeledContent("Events Processed", value: "\(pipeline.eventsProcessed)")
                    LabeledContent("Events Queued", value: "\(pipeline.eventsQueued)")
                    LabeledContent("Processing Rate", value: String(format: "%.1f/s", pipeline.processingRate))
                }
                
                Section("Actions") {
                    Button("Trigger Aggregation") {
                        Task {
                            try? await pipeline.triggerAggregation()
                        }
                    }
                    
                    Button("Restart Pipeline") {
                        Task {
                            await pipeline.stop()
                            pipeline.start()
                        }
                    }
                }
            }
            .navigationTitle("Collection Settings")
            #if os(iOS)
            #endif
        }
    }
}

/// Collection tabs
enum CollectionTab: String, CaseIterable {
    case status = "Status"
    case events = "Events"
    case metrics = "Metrics"
}

#Preview {
    AnalyticsEventCollectionView(
        modelContainer: try! ModelContainer(
            for: AnalyticsEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    )
}

