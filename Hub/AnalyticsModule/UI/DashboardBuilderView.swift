import SwiftUI
import Charts
import Combine

// MARK: - Dashboard Builder
struct DashboardBuilderView: View {
    @StateObject private var viewModel = DashboardBuilderViewModel()
    @State private var showWidgetPicker = false
    
    var body: some View {
        HSplitView {
            // Widget Library
            WidgetLibraryView { widget in
                viewModel.addWidget(widget)
            }
            .frame(minWidth: 200, maxWidth: 250)
            
            // Canvas
            ScrollView {
                LazyVGrid(columns: viewModel.gridColumns, spacing: 16) {
                    ForEach(viewModel.widgets) { widget in
                        DashboardWidgetView(widget: widget)
                            .contextMenu {
                                Button("Remove") {
                                    viewModel.removeWidget(widget.id)
                                }
                                Button("Configure") {
                                    viewModel.configureWidget(widget)
                                }
                            }
                    }
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Save") { viewModel.saveDashboard() }
                Button("Export") { viewModel.exportDashboard() }
            }
        }
    }
}

struct WidgetLibraryView: View {
    let onWidgetSelected: (DashboardWidget) -> Void
    
    var body: some View {
        List {
            Section("Charts") {
                WidgetTypeButton(type: .lineChart, onTap: onWidgetSelected)
                WidgetTypeButton(type: .barChart, onTap: onWidgetSelected)
                WidgetTypeButton(type: .pieChart, onTap: onWidgetSelected)
            }
            Section("Metrics") {
                WidgetTypeButton(type: .kpi, onTap: onWidgetSelected)
                WidgetTypeButton(type: .gauge, onTap: onWidgetSelected)
                WidgetTypeButton(type: .counter, onTap: onWidgetSelected)
            }
            Section("Data") {
                WidgetTypeButton(type: .table, onTap: onWidgetSelected)
                WidgetTypeButton(type: .list, onTap: onWidgetSelected)
            }
        }
    }
}

struct WidgetTypeButton: View {
    let type: WidgetType
    let onTap: (DashboardWidget) -> Void
    
    var body: some View {
        Button(action: { onTap(DashboardWidget(type: type)) }) {
            HStack {
                Image(systemName: type.icon)
                Text(type.displayName)
            }
        }
    }
}

struct DashboardWidgetView: View {
    let widget: DashboardWidget
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(widget.title)
                .font(.headline)
            
            switch widget.type {
            case .lineChart:
                Chart {
                    ForEach(widget.data, id: \.0) { item in
                        LineMark(x: .value("X", item.0), y: .value("Y", item.1))
                    }
                }
                .frame(height: 200)
            case .barChart:
                Chart {
                    ForEach(widget.data, id: \.0) { item in
                        BarMark(x: .value("X", item.0), y: .value("Y", item.1))
                    }
                }
                .frame(height: 200)
            case .kpi:
                Text(widget.value)
                    .font(.system(size: 48, weight: .bold))
            case .counter:
                Text("\(Int(Double(widget.value) ?? 0))")
                    .font(.largeTitle)
            default:
                Text("Widget: \(widget.type.displayName)")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

@MainActor
class DashboardBuilderViewModel: ObservableObject {
    @Published var widgets: [DashboardWidget] = []
    @Published var gridColumns = [GridItem(.adaptive(minimum: 300))]
    
    func addWidget(_ widget: DashboardWidget) {
        widgets.append(widget)
    }
    
    func removeWidget(_ id: UUID) {
        widgets.removeAll { $0.id == id }
    }
    
    func configureWidget(_ widget: DashboardWidget) {
        // Configure widget
    }
    
    func saveDashboard() {
        // Save dashboard
    }
    
    func exportDashboard() {
        // Export dashboard
    }
}

struct DashboardWidget: Identifiable {
    let id = UUID()
    var type: WidgetType
    var title: String
    var data: [(String, Double)]
    var value: String
    
    init(type: WidgetType, title: String = "", data: [(String, Double)] = [], value: String = "0") {
        self.type = type
        self.title = title.isEmpty ? type.displayName : title
        self.data = data
        self.value = value
    }
}

enum WidgetType {
    case lineChart, barChart, pieChart, kpi, gauge, counter, table, list
    
    var displayName: String {
        switch self {
        case .lineChart: return "Line Chart"
        case .barChart: return "Bar Chart"
        case .pieChart: return "Pie Chart"
        case .kpi: return "KPI"
        case .gauge: return "Gauge"
        case .counter: return "Counter"
        case .table: return "Table"
        case .list: return "List"
        }
    }
    
    var icon: String {
        switch self {
        case .lineChart: return "chart.xyaxis.line"
        case .barChart: return "chart.bar"
        case .pieChart: return "chart.pie"
        case .kpi: return "number"
        case .gauge: return "gauge"
        case .counter: return "plusminus"
        case .table: return "tablecells"
        case .list: return "list.bullet"
        }
    }
}
