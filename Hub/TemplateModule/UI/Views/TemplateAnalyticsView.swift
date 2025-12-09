import SwiftUI
import Charts

/// Template analytics and insights view
struct TemplateAnalyticsView: View {
    let templateManager: TemplateManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: Metric = .downloads
    
    enum Metric: String, CaseIterable {
        case downloads = "Downloads"
        case views = "Views"
        case ratings = "Ratings"
        case usage = "Usage"
        
        var icon: String {
            switch self {
            case .downloads: return "arrow.down.circle.fill"
            case .views: return "eye.fill"
            case .ratings: return "star.fill"
            case .usage: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview cards
                    overviewSection
                    
                    // Metric selector
                    metricSelector
                    
                    // Charts
                    chartsSection
                    
                    // Top templates
                    topTemplatesSection
                    
                    // Category breakdown
                    categoryBreakdownSection
                }
                .padding()
            }
            .navigationTitle("Template Analytics")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            OverviewCard(
                title: "Total Templates",
                value: "\(templateManager.templates.count)",
                icon: "doc.fill",
                color: .blue
            )
            
            OverviewCard(
                title: "Total Downloads",
                value: "\(totalDownloads)",
                icon: "arrow.down.circle.fill",
                color: .green
            )
            
            OverviewCard(
                title: "Total Views",
                value: "\(totalViews)",
                icon: "eye.fill",
                color: .orange
            )
            
            OverviewCard(
                title: "Avg Rating",
                value: String(format: "%.1f", averageRating),
                icon: "star.fill",
                color: .yellow
            )
        }
    }
    
    // MARK: - Metric Selector
    
    private var metricSelector: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(Metric.allCases, id: \.self) { metric in
                Label(metric.rawValue, systemImage: metric.icon)
                    .tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Trend Over Time")
                    .font(.headline)
                
                Chart {
                    ForEach(trendData, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Value", data.value)
                        )
                        .foregroundStyle(.blue)
                        
                        AreaMark(
                            x: .value("Date", data.date),
                            y: .value("Value", data.value)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                }
                .frame(height: 200)
            }
            .padding()
        }
    }
    
    // MARK: - Top Templates
    
    private var topTemplatesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Top 10 Templates")
                    .font(.headline)
                
                ForEach(topTemplates.prefix(10)) { template in
                    HStack {
                        Image(systemName: template.icon)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.body)
                            Text(template.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(metricValue(for: template))")
                                .font(.headline)
                            Text(selectedMetric.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if template.id != topTemplates.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Category Breakdown")
                    .font(.headline)
                
                Chart {
                    ForEach(categoryData, id: \.category) { data in
                        BarMark(
                            x: .value("Count", data.count),
                            y: .value("Category", data.category.rawValue)
                        )
                        .foregroundStyle(by: .value("Category", data.category.rawValue))
                    }
                }
                .frame(height: 300)
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalDownloads: Int {
        templateManager.templates.reduce(0) { $0 + $1.downloadCount }
    }
    
    private var totalViews: Int {
        templateManager.templates.reduce(0) { $0 + $1.viewCount }
    }
    
    private var averageRating: Double {
        let templates = templateManager.templates.filter { $0.reviewCount > 0 }
        guard !templates.isEmpty else { return 0 }
        let sum = templates.reduce(0.0) { $0 + $1.averageRating }
        return sum / Double(templates.count)
    }
    
    private var topTemplates: [TemplateModel] {
        switch selectedMetric {
        case .downloads:
            return templateManager.templates.sorted { $0.downloadCount > $1.downloadCount }
        case .views:
            return templateManager.templates.sorted { $0.viewCount > $1.viewCount }
        case .ratings:
            return templateManager.templates.sorted { $0.averageRating > $1.averageRating }
        case .usage:
            return templateManager.templates.sorted { ($0.downloadCount + $0.viewCount) > ($1.downloadCount + $1.viewCount) }
        }
    }
    
    private func metricValue(for template: TemplateModel) -> Int {
        switch selectedMetric {
        case .downloads:
            return template.downloadCount
        case .views:
            return template.viewCount
        case .ratings:
            return Int(template.averageRating * 10)
        case .usage:
            return template.downloadCount + template.viewCount
        }
    }
    
    private var trendData: [TrendDataPoint] {
        // Generate sample trend data
        let calendar = Calendar.current
        let now = Date()
        return (0..<30).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            let value = Int.random(in: 10...100)
            return TrendDataPoint(date: date, value: value)
        }.reversed()
    }
    
    private var categoryData: [CategoryDataPoint] {
        var counts: [HubCategory: Int] = [:]
        for template in templateManager.templates {
            counts[template.category, default: 0] += 1
        }
        return counts.map { CategoryDataPoint(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Supporting Types

struct TrendDataPoint {
    let date: Date
    let value: Int
}

struct CategoryDataPoint {
    let category: HubCategory
    let count: Int
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// Preview removed - requires model context
