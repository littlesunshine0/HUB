//
//  AnalyticsEventListView.swift
//  Hub
//
//  View for displaying analytics events
//

import SwiftUI
import SwiftData

/// View for displaying a list of analytics events
struct AnalyticsEventListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AnalyticsEvent.timestamp, order: .reverse) private var events: [AnalyticsEvent]
    
    @State private var selectedEventType: EventType?
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var filteredEvents: [AnalyticsEvent] {
        var filtered = events
        
        if let selectedType = selectedEventType {
            filtered = filtered.filter { $0.type == selectedType.rawValue }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.type.localizedCaseInsensitiveContains(searchText) ||
                event.id.uuidString.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Analytics Events")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(filteredEvents.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .imageScale(.large)
                }
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search events...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Filters
            if showingFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        AnalyticsFilterChip(
                            title: "All",
                            isSelected: selectedEventType == nil,
                            action: { selectedEventType = nil }
                        )
                        
                        ForEach(EventType.allCases, id: \.self) { type in
                            AnalyticsFilterChip(
                                title: type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                                isSelected: selectedEventType == type,
                                action: { selectedEventType = type }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Event list
            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "No Events",
                    systemImage: "chart.bar.xaxis",
                    description: Text("No analytics events to display")
                )
            } else {
                List {
                    ForEach(filteredEvents) { event in
                        AnalyticsEventRow(event: event)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

/// Row view for a single analytics event
struct AnalyticsEventRow: View {
    let event: AnalyticsEvent
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Event type icon
                Image(systemName: iconForEventType(event.type))
                    .foregroundStyle(colorForEventType(event.type))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.type.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.headline)
                    
                    Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if event.processed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .imageScale(.small)
                }
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .imageScale(.small)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    if let userId = event.userId {
                        EventDetailRow(label: "User ID", value: userId.uuidString)
                    }
                    
                    if let itemId = event.itemId {
                        EventDetailRow(label: "Item ID", value: itemId.uuidString)
                    }
                    
                    EventDetailRow(label: "Session ID", value: event.sessionId.uuidString)
                    
                    if let duration = event.duration {
                        EventDetailRow(label: "Duration", value: String(format: "%.2f seconds", duration))
                    }
                    
                    let metadata = event.getMetadata()
                    if !metadata.isEmpty {
                        Text("Metadata:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                            if let value = metadata[key] {
                                EventDetailRow(label: key, value: "\(value)")
                            }
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForEventType(_ type: String) -> String {
        switch type {
        case let t where t.contains("template"):
            return "doc.text"
        case let t where t.contains("search"):
            return "magnifyingglass"
        case let t where t.contains("purchase"):
            return "cart"
        case let t where t.contains("subscription"):
            return "star"
        case let t where t.contains("feedback"):
            return "bubble.left"
        case let t where t.contains("error"):
            return "exclamationmark.triangle"
        case let t where t.contains("performance"):
            return "speedometer"
        default:
            return "chart.bar"
        }
    }
    
    private func colorForEventType(_ type: String) -> Color {
        switch type {
        case let t where t.contains("error") || t.contains("crash"):
            return .red
        case let t where t.contains("purchase") || t.contains("subscription"):
            return .green
        case let t where t.contains("feedback"):
            return .blue
        case let t where t.contains("performance"):
            return .orange
        default:
            return .primary
        }
    }
}

/// Detail row for event metadata
struct EventDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }
}

/// Filter chip for event type filtering
struct AnalyticsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AnalyticsEventListView()
        .modelContainer(for: [AnalyticsEvent.self], inMemory: true)
}
