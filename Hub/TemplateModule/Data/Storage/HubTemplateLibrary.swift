import Foundation
import SwiftUI

// MARK: - HubTemplate Enum

public enum HubTemplate: String, Codable, CaseIterable {
    case fileManager = "File Manager"
    case codeAnalyzer = "Code Analyzer"
    case taskManager = "Task Manager"
    case noteEditor = "Note Editor"
    case dataVisualizer = "Data Visualizer"
    case apiTester = "API Tester"
    case markdownEditor = "Markdown Editor"
    case jsonFormatter = "JSON Formatter"
    case builder = "Builder"
    case inspector = "Inspector"
    case packager = "Packager"
    case tester = "Tester"
    case converter = "Converter"
    case optimizer = "Optimizer"
    case gallery = "Gallery"
    case player = "Player"
    case syncer = "Syncer"
    case sharer = "Sharer"
    case reviewer = "Reviewer"
    case analyzer = "Analyzer"
    case reporter = "Reporter"
    case monitor = "Monitor"
    
    public var category: HubCategory {
        switch self {
        case .fileManager, .taskManager, .noteEditor, .reviewer:
            return .productivity
        case .codeAnalyzer, .apiTester, .builder, .inspector, .tester, .analyzer, .monitor:
            return .development
        case .dataVisualizer, .reporter:
            return .business
        case .markdownEditor, .gallery, .player:
            return .creative
        case .jsonFormatter, .packager, .converter, .optimizer, .syncer, .sharer:
            return .utilities
        }
    }
}

// MARK: - HubCategory Enum

public enum HubCategory: String, Codable, CaseIterable {
    // Core Categories
    case productivity = "Productivity"
    case development = "Development"
    case business = "Business"
    case creative = "Creative"
    case utilities = "Utilities"
    case authentication = "Authentication"
    case userProfile = "User Profile"
    
    // Industry Categories
    case finance = "Finance"
    case health = "Health & Fitness"
    case education = "Education"
    case social = "Social"
    case ecommerce = "E-Commerce"
    case travel = "Travel"
    case food = "Food & Dining"
    case realEstate = "Real Estate"
    case entertainment = "Entertainment"
    case news = "News & Media"
    case sports = "Sports"
    case lifestyle = "Lifestyle"
    case gaming = "Gaming"
    case music = "Music"
    case photography = "Photography"
    case weather = "Weather"
    case transportation = "Transportation"
    case communication = "Communication"
    case security = "Security"
    case iot = "IoT & Smart Home"
}

struct HubTemplateLibrary {
    static let shared = HubTemplateLibrary()
    
    private init() {}
    
    // MARK: - Pre-built Templates
    
    func getDefaultTemplates() -> [HubTemplateDefinition] {
        return [
            fileManagerTemplate,
            codeAnalyzerTemplate,
            taskManagerTemplate,
            noteEditorTemplate,
            dataVisualizerTemplate,
            apiTesterTemplate,
            markdownEditorTemplate,
            jsonFormatterTemplate,
            builderTemplate,
            inspectorTemplate,
            packagerTemplate,
            testerTemplate,
            converterTemplate,
            optimizerTemplate,
            galleryTemplate,
            playerTemplate,
            syncerTemplate,
            sharerTemplate,
            reviewerTemplate,
            analyzerTemplate,
            reporterTemplate,
            monitorTemplate
        ]
    }
    
    // MARK: - Template Definitions
    
    private var fileManagerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.fileManager,
            category: HubCategory.productivity,
            sampleCode: """
            import SwiftUI
            
            struct FileManagerView: View {
                @State private var files: [FileItem] = []
                @State private var searchText = ""
                
                var body: some View {
                    NavigationStack {
                        List {
                            ForEach(filteredFiles) { file in
                                FileRow(file: file)
                            }
                        }
                        .searchable(text: $searchText)
                        .navigationTitle("Files")
                        .toolbar {
                            Button("Add", systemImage: "plus") {
                                // Add file logic
                            }
                        }
                    }
                }
                
                var filteredFiles: [FileItem] {
                    if searchText.isEmpty {
                        return files
                    }
                    return files.filter { $0.name.contains(searchText) }
                }
            }
            
            struct FileItem: Identifiable {
                let id = UUID()
                let name: String
                let size: Int64
                let type: String
            }
            
            struct FileRow: View {
                let file: FileItem
                
                var body: some View {
                    HStack {
                        Image(systemName: "doc.fill")
                        VStack(alignment: .leading) {
                            Text(file.name)
                            Text("\\(file.size) bytes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            """,
            features: ["File Browser", "Search", "Categorization", "Quick Actions"],
            dependencies: []
        )
    }
    
    private var codeAnalyzerTemplate: HubTemplateDefinition {
        // Read UnifiedSystem.swift content from the project
        let unifiedSystemCode = HubBuilderService.loadSwiftFile(named: "UnifiedSystem.swift") ?? """
        // UnifiedSystem.swift placeholder
        // The actual UnifiedSystem.swift file should be included in the project
        import Foundation
        
        public enum UnifiedSystem {
            public enum Utils {
                public class Logger {
                    public static func log(_ message: String) {
                        print(message)
                    }
                }
            }
        }
        """
        
        let mainCode = """
        import SwiftUI
        
        @main
        struct CodeAnalyzerApp: App {
            var body: some Scene {
                WindowGroup {
                    CodeAnalyzerView()
                }
            }
        }
        
        struct CodeAnalyzerView: View {
            @State private var code = ""
            @State private var analysisResults: [UnifiedSystem.Core.Structures.AnalysisResult] = []
            @State private var isAnalyzing = false
            @State private var selectedLanguage: UnifiedSystem.Core.Types.Language = .swift
            
            var body: some View {
                HSplitView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Code Editor")
                            .font(.headline)
                        
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(UnifiedSystem.Core.Types.Language.allCases, id: \'\'.self) { lang in
                                Text(lang.rawValue.capitalized).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        TextEditor(text: $code)
                            .font(.system(.body, design: .monospaced))
                            .border(Color.gray.opacity(0.3))
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Results")
                            .font(.headline)
                        
                        if analysisResults.isEmpty {
                            Text("No analysis results yet")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(analysisResults) { result in
                                    Section(header: Text(result.filePath).font(.caption)) {
                                        ForEach(result.issues) { issue in
                                            IssueRow(issue: issue)
                                        }
                                        
                                        ForEach(result.metrics, id: \'\'.name) { metric in
                                            MetricRow(metric: metric)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .toolbar {
                    Button(action: analyzeCode) {
                        Label("Analyze", systemImage: "magnifyingglass")
                    }
                    .disabled(isAnalyzing || code.isEmpty)
                    
                    Button(action: clearResults) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(analysisResults.isEmpty)
                }
            }
            
            func analyzeCode() {
                isAnalyzing = true
                
                Task {
                    // FEATURE:Parser:START
                    // Parse the code
                    let ast = UnifiedSystem.Analysis.UniversalCodeParser.parse(code: code, language: selectedLanguage)
                    // FEATURE:Parser:END
                    
                    // FEATURE:Linter:START
                    // Lint the code
                    let issues = UnifiedSystem.Analysis.UnifiedLinter.lintCode(code: code, language: selectedLanguage)
                    // FEATURE:Linter:END
                    
                    // FEATURE:Metrics:START
                    // Analyze complexity
                    let metric = UnifiedSystem.Analysis.ComplexityAnalyzer.analyzeComplexity(
                        ast: ast,
                        language: selectedLanguage,
                        filePath: "inline-code"
                    )
                    // FEATURE:Metrics:END
                    
                    // Create result
                    let _ = UnifiedSystem.Core.Structures.AnalysisResult(
                        id: UUID(),
                        language: selectedLanguage,
                        filePath: "inline-code",
                        ast: ast,
                        issues: issues,
                        metrics: [metric]
                    )
                    
                    await MainActor.run {
                        analysisResults = [result]
                        isAnalyzing = false
                    }
                }
            }
            
            func clearResults() {
                analysisResults = []
            }
        }
        
        struct IssueRow: View {
            let issue: UnifiedSystem.Core.Structures.CodeIssue
            
            var body: some View {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: severityIcon)
                        .foregroundStyle(severityColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issue.message)
                            .font(.body)
                        
                        HStack {
                            Text(issue.type.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                            
                            if let line = issue.lineNumber {
                                Text("Line \\(line)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if issue.isAutoFixable {
                                Text("Auto-fixable")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        if let fix = issue.suggestedFix {
                            Text("Fix: \\(fix)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            var severityIcon: String {
                switch issue.severity {
                case .critical: return "exclamationmark.octagon.fill"
                case .error: return "xmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .info: return "info.circle.fill"
                }
            }
            
            var severityColor: Color {
                switch issue.severity {
                case .critical: return .purple
                case .error: return .red
                case .warning: return .orange
                case .info: return .blue
                }
            }
        }
        
        struct MetricRow: View {
            let metric: UnifiedSystem.Core.Structures.CodeMetric
            
            var body: some View {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(complexityColor)
                    
                    VStack(alignment: .leading) {
                        Text(metric.name)
                            .font(.body)
                        Text(String(format: "%.2f", metric.value) + (metric.unit ?? ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let level = metric.complexityLevel {
                        Text(level.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(complexityColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
            }
            
            var complexityColor: Color {
                switch metric.complexityLevel {
                case .critical: return .red
                case .high: return .orange
                case .medium: return .yellow
                case .low: return .green
                case .none: return .gray
                }
            }
        }
        """
        
        return HubTemplateDefinition(
            template: HubTemplate.codeAnalyzer,
            category: HubCategory.development,
            sourceFiles: [
                "main.swift": mainCode,
                "UnifiedSystem.swift": unifiedSystemCode
            ],
            features: ["Parser", "Linter", "Metrics", "Auto-fix Suggestions"],
            dependencies: []
        )
    }
    
    private var taskManagerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.taskManager,
            category: HubCategory.productivity,
            sampleCode: """
            import SwiftUI
            
            struct TaskManagerView: View {
                @State private var tasks: [Task] = []
                @State private var showingAddTask = false
                
                var body: some View {
                    NavigationStack {
                        List {
                            ForEach(tasks) { task in
                                TaskRow(task: task)
                            }
                            .onDelete(perform: deleteTasks)
                        }
                        .navigationTitle("Tasks")
                        .toolbar {
                            Button("Add", systemImage: "plus") {
                                showingAddTask = true
                            }
                        }
                        .sheet(isPresented: $showingAddTask) {
                            AddTaskView { newTask in
                                tasks.append(newTask)
                            }
                        }
                    }
                }
                
                func deleteTasks(at offsets: IndexSet) {
                    tasks.remove(atOffsets: offsets)
                }
            }
            
            struct Task: Identifiable {
                let id = UUID()
                var title: String
                var isCompleted: Bool
                var dueDate: Date?
                var priority: Priority
                
                enum Priority: String, CaseIterable {
                    case low, medium, high
                }
            }
            
            struct TaskRow: View {
                let task: Task
                
                var body: some View {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? .green : .gray)
                        VStack(alignment: .leading) {
                            Text(task.title)
                            if let dueDate = task.dueDate {
                                Text(dueDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            struct AddTaskView: View {
                @Environment('\'.dismiss) private var dismiss
                @State private var title = ""
                let onAdd: (Task) -> Void
                
                var body: some View {
                    NavigationStack {
                        Form {
                            TextField("Task Title", text: $title)
                        }
                        .navigationTitle("New Task")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    let task = Task(title: title, isCompleted: false, priority: .medium)
                                    onAdd(task)
                                    dismiss()
                                }
                                .disabled(title.isEmpty)
                            }
                        }
                    }
                }
            }
            """,
            features: ["Task List", "Calendar", "Reminders", "Priority Levels"],
            dependencies: []
        )
    }
    
    private var noteEditorTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.noteEditor,
            category: HubCategory.productivity,
            sampleCode: """
            import SwiftUI
            
            struct NoteEditorView: View {
                @State private var notes: [Note] = []
                @State private var selectedNote: Note?
                
                var body: some View {
                    NavigationSplitView {
                        List(notes, selection: $selectedNote) { note in
                            NoteListItem(note: note)
                        }
                        .navigationTitle("Notes")
                    } detail: {
                        if let note = selectedNote {
                            NoteDetailView(note: note)
                        } else {
                            Text("Select a note")
                        }
                    }
                }
            }
            
            struct Note: Identifiable, Hashable {
                let id = UUID()
                var title: String
                var content: String
                var tags: [String]
                var createdAt: Date
            }
            
            struct NoteListItem: View {
                let note: Note
                
                var body: some View {
                    VStack(alignment: .leading) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.content)
                            .lineLimit(2)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            struct NoteDetailView: View {
                let note: Note
                
                var body: some View {
                    TextEditor(text: .constant(note.content))
                        .navigationTitle(note.title)
                }
            }
            """,
            features: ["Text Editor", "Formatting", "Tags", "Search"],
            dependencies: []
        )
    }
    
    private var dataVisualizerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.dataVisualizer,
            category: HubCategory.business,
            sampleCode: """
            import SwiftUI
            import Charts
            
            struct DataVisualizerView: View {
                @State private var data: [DataPoint] = []
                
                var body: some View {
                    VStack {
                        Chart(data) { point in
                            BarMark(
                                x: .value("Category", point.category),
                                y: .value("Value", point.value)
                            )
                        }
                        .frame(height: 300)
                        .padding()
                        
                        List(data) { point in
                            HStack {
                                Text(point.category)
                                Spacer()
                                Text("\\(point.value)")
                            }
                        }
                    }
                    .navigationTitle("Data Visualizer")
                }
            }
            
            struct DataPoint: Identifiable {
                let id = UUID()
                let category: String
                let value: Double
            }
            """,
            features: ["Charts", "Import", "Export", "Multiple Chart Types"],
            dependencies: ["Charts"]
        )
    }
    
    private var apiTesterTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.apiTester,
            category: HubCategory.development,
            sampleCode: """
            import SwiftUI
            
            struct APITesterView: View {
                @State private var url = ""
                @State private var method = "GET"
                @State private var response = ""
                @State private var isLoading = false
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Picker("Method", selection: $method) {
                                Text("GET").tag("GET")
                                Text("POST").tag("POST")
                                Text("PUT").tag("PUT")
                                Text("DELETE").tag("DELETE")
                            }
                            .frame(width: 120)
                            
                            TextField("URL", text: $url)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Send") {
                                sendRequest()
                            }
                            .disabled(isLoading)
                        }
                        
                        Text("Response:")
                            .font(.headline)
                        
                        ScrollView {
                            Text(response)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: .infinity)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                    }
                    .padding()
                }
                
                func sendRequest() {
                    isLoading = true
                    // API request logic
                    isLoading = false
                }
            }
            """,
            features: ["HTTP Client", "Request Builder", "Response Viewer", "History"],
            dependencies: []
        )
    }
    
    private var markdownEditorTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.markdownEditor,
            category: HubCategory.creative,
            sampleCode: """
            import SwiftUI
            
            struct MarkdownEditorView: View {
                @State private var markdown = "# Hello World"
                
                var body: some View {
                    HSplitView {
                        VStack {
                            Text("Editor")
                                .font(.headline)
                            TextEditor(text: $markdown)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        VStack {
                            Text("Preview")
                                .font(.headline)
                            ScrollView {
                                Text(markdown)
                                    .padding()
                            }
                        }
                    }
                    .navigationTitle("Markdown Editor")
                }
            }
            """,
            features: ["Editor", "Preview", "Export", "Syntax Highlighting"],
            dependencies: []
        )
    }
    
    private var jsonFormatterTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.jsonFormatter,
            category: HubCategory.development,
            sampleCode: """
            import SwiftUI
            
            struct JSONFormatterView: View {
                @State private var input = ""
                @State private var output = ""
                @State private var errorMessage: String?
                
                var body: some View {
                    VStack {
                        Text("Input JSON")
                            .font(.headline)
                        TextEditor(text: $input)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 200)
                        
                        HStack {
                            Button("Format") {
                                formatJSON()
                            }
                            Button("Validate") {
                                validateJSON()
                            }
                            Button("Minify") {
                                minifyJSON()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        
                        Text("Output")
                            .font(.headline)
                        TextEditor(text: $output)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 200)
                    }
                    .padding()
                }
                
                func formatJSON() {
                    guard let data = input.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data),
                          let formatted = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                          let string = String(data: formatted, encoding: .utf8) else {
                        errorMessage = "Invalid JSON"
                        return
                    }
                    output = string
                    errorMessage = nil
                }
                
                func validateJSON() {
                    guard let data = input.data(using: .utf8),
                          let _ = try? JSONSerialization.jsonObject(with: data) else {
                        errorMessage = "Invalid JSON"
                        return
                    }
                    errorMessage = "Valid JSON ✓"
                }
                
                func minifyJSON() {
                    guard let data = input.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data),
                          let minified = try? JSONSerialization.data(withJSONObject: json),
                          let string = String(data: minified, encoding: .utf8) else {
                        errorMessage = "Invalid JSON"
                        return
                    }
                    output = string
                    errorMessage = nil
                }
            }
            """,
            features: ["Parser", "Formatter", "Validator", "Minifier"],
            dependencies: []
        )
    }
    
    // MARK: - Development & Utility Hubs
    
    private var builderTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.builder,
            category: HubCategory.development,
            sampleCode: #"""
            import SwiftUI
            
            struct BuilderView: View {
                @State private var projectName = ""
                @State private var projectType: ProjectType = .swiftUI
                @State private var selectedFeatures: Set<String> = []
                @State private var generatedCode = ""
                @State private var showingPreview = false
                
                let availableFeatures = [
                    "SwiftData Persistence",
                    "CloudKit Sync",
                    "Authentication",
                    "Notifications",
                    "In-App Purchases"
                ]
                
                var body: some View {
                    NavigationStack {
                        Form {
                            Section("Project Configuration") {
                                TextField("Project Name", text: $projectName)
                                
                                Picker("Project Type", selection: $projectType) {
                                    ForEach(ProjectType.allCases, id: '\'.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                            }
                            
                            Section("Features") {
                                ForEach(availableFeatures, id: '\'.self) { feature in
                                    Toggle(feature, isOn: Binding(
                                        get: { selectedFeatures.contains(feature) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedFeatures.insert(feature)
                                            } else {
                                                selectedFeatures.remove(feature)
                                            }
                                        }
                                    ))
                                }
                            }
                            
                            Section {
                                Button("Generate Project") {
                                    generateProject()
                                }
                                .disabled(projectName.isEmpty)
                                
                                if !generatedCode.isEmpty {
                                    Button("Preview Code") {
                                        showingPreview = true
                                    }
                                }
                            }
                        }
                        .navigationTitle("Project Builder")
                        .sheet(isPresented: $showingPreview) {
                            CodePreviewView(code: generatedCode)
                        }
                    }
                }
                
                func generateProject() {
                    var code = """
                    // \(projectName)
                    // Generated by Builder
                    
                    import SwiftUI
                    
                    @main
                    struct \(projectName.replacingOccurrences(of: " ", with: ""))App: App {
                        var body: some Scene {
                            WindowGroup {
                                ContentView()
                            }
                        }
                    }
                    
                    struct ContentView: View {
                        var body: some View {
                            NavigationStack {
                                Text("Welcome to \(projectName)")
                                    .navigationTitle("\(projectName)")
                            }
                        }
                    }
                    """
                    
                    // Add feature-specific code
                    if selectedFeatures.contains("SwiftData Persistence") {
                        code += """
                        
                        
                        // SwiftData Models
                        import SwiftData
                        
                        @Model
                        class Item {
                            var name: String
                            var timestamp: Date
                            
                            init(name: String) {
                                self.name = name
                                self.timestamp = Date()
                            }
                        }
                        """
                    }
                    
                    generatedCode = code
                }
            }
            
            enum ProjectType: String, CaseIterable {
                case swiftUI = "SwiftUI App"
                case multiplatform = "Multiplatform App"
                case commandLine = "Command Line Tool"
                case framework = "Framework"
            }
            
            struct CodePreviewView: View {
                let code: String
                @Environment('\'.dismiss) private var dismiss
                
                var body: some View {
                    NavigationStack {
                        ScrollView {
                            Text(code)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                        }
                        .navigationTitle("Generated Code")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            """#,
            features: ["Code Generation", "Project Scaffolding", "Template Selection", "Feature Toggles"],
            dependencies: []
        )
    }
    
    private var inspectorTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.inspector,
            category: HubCategory.development,
            sampleCode: """
            import SwiftUI
            
            struct InspectorView: View {
                @State private var isMonitoring = false
                @State private var cpuUsage: Double = 0.0
                @State private var memoryUsage: Double = 0.0
                @State private var networkActivity: [NetworkEvent] = []
                @State private var logs: [LogEntry] = []
                
                var body: some View {
                    NavigationStack {
                        List {
                            Section("Performance Metrics") {
                                HStack {
                                    Label("CPU Usage", systemImage: "cpu")
                                    Spacer()
                                    Text(String(format: "%.1f%%", cpuUsage))
                                        .foregroundStyle(cpuUsage > 80 ? .red : .primary)
                                }
                                
                                HStack {
                                    Label("Memory", systemImage: "memorychip")
                                    Spacer()
                                    Text(String(format: "%.1f MB", memoryUsage))
                                        .foregroundStyle(memoryUsage > 500 ? .orange : .primary)
                                }
                            }
                            
                            Section("Network Activity") {
                                if networkActivity.isEmpty {
                                    Text("No network activity")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(networkActivity) { event in
                                        NetworkEventRow(event: event)
                                    }
                                }
                            }
                            
                            Section("Console Logs") {
                                if logs.isEmpty {
                                    Text("No logs")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(logs) { log in
                                        LogRow(log: log)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Inspector")
                        .toolbar {
                            Button(isMonitoring ? "Stop" : "Start") {
                                isMonitoring.toggle()
                                if isMonitoring {
                                    startMonitoring()
                                }
                            }
                        }
                    }
                }
                
                func startMonitoring() {
                    // Simulate monitoring
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        if isMonitoring {
                            cpuUsage = Double.random(in: 10...90)
                            memoryUsage = Double.random(in: 100...600)
                        }
                    }
                }
            }
            
            struct NetworkEvent: Identifiable {
                let id = UUID()
                let method: String
                let url: String
                let statusCode: Int
                let timestamp: Date
            }
            
            struct NetworkEventRow: View {
                let event: NetworkEvent
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(event.method)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(methodColor)
                                .foregroundStyle(.white)
                                .cornerRadius(4)
                            
                            Text(String(event.statusCode))
                                .font(.caption)
                                .foregroundStyle(statusColor)
                        }
                        
                        Text(event.url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                var methodColor: Color {
                    switch event.method {
                    case "GET": return .blue
                    case "POST": return .green
                    case "PUT": return .orange
                    case "DELETE": return .red
                    default: return .gray
                    }
                }
                
                var statusColor: Color {
                    if event.statusCode < 300 { return .green }
                    if event.statusCode < 400 { return .blue }
                    if event.statusCode < 500 { return .orange }
                    return .red
                }
            }
            
            struct LogEntry: Identifiable {
                let id = UUID()
                let level: LogLevel
                let message: String
                let timestamp: Date
                
                enum LogLevel: String {
                    case debug = "DEBUG"
                    case info = "INFO"
                    case warning = "WARNING"
                    case error = "ERROR"
                }
            }
            
            struct LogRow: View {
                let log: LogEntry
                
                var body: some View {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: levelIcon)
                            .foregroundStyle(levelColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.message)
                                .font(.caption)
                            Text(log.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                var levelIcon: String {
                    switch log.level {
                    case .debug: return "ant.fill"
                    case .info: return "info.circle.fill"
                    case .warning: return "exclamationmark.triangle.fill"
                    case .error: return "xmark.circle.fill"
                    }
                }
                
                var levelColor: Color {
                    switch log.level {
                    case .debug: return .gray
                    case .info: return .blue
                    case .warning: return .orange
                    case .error: return .red
                    }
                }
            }
            """,
            features: ["Performance Monitoring", "Network Inspector", "Console Logs", "Memory Profiling"],
            dependencies: []
        )
    }
    
    private var packagerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.packager,
            category: HubCategory.utilities,
            sampleCode: """
            import SwiftUI
            
            struct PackagerView: View {
                @State private var appName = ""
                @State private var bundleID = ""
                @State private var version = "1.0.0"
                @State private var buildNumber = "1"
                @State private var selectedPlatforms: Set<Platform> = [.macOS]
                @State private var exportFormat: ExportFormat = .app
                @State private var isPackaging = false
                @State private var packageProgress: Double = 0.0
                
                var body: some View {
                    NavigationStack {
                        Form {
                            Section("App Information") {
                                TextField("App Name", text: $appName)
                                TextField("Bundle Identifier", text: $bundleID)
                                    .textContentType(.URL)
                                
                                HStack {
                                    TextField("Version", text: $version)
                                    TextField("Build", text: $buildNumber)
                                }
                            }
                            
                            Section("Target Platforms") {
                                ForEach(Platform.allCases, id: '\'.self) { platform in
                                    Toggle(platform.rawValue, isOn: Binding(
                                        get: { selectedPlatforms.contains(platform) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedPlatforms.insert(platform)
                                            } else {
                                                selectedPlatforms.remove(platform)
                                            }
                                        }
                                    ))
                                }
                            }
                            
                            Section("Export Options") {
                                Picker("Format", selection: $exportFormat) {
                                    ForEach(ExportFormat.allCases, id: '\'.self) { format in
                                        Text(format.rawValue).tag(format)
                                    }
                                }
                            }
                            
                            Section {
                                if isPackaging {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Packaging...")
                                        ProgressView(value: packageProgress)
                                    }
                                } else {
                                    Button("Package App") {
                                        packageApp()
                                    }
                                    .disabled(appName.isEmpty || bundleID.isEmpty || selectedPlatforms.isEmpty)
                                }
                            }
                        }
                        .navigationTitle("Packager")
                    }
                }
                
                func packageApp() {
                    isPackaging = true
                    packageProgress = 0.0
                    
                    Task {
                        // Simulate packaging process
                        for i in 1...10 {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            await MainActor.run {
                                packageProgress = Double(i) / 10.0
                            }
                        }
                        
                        await MainActor.run {
                            isPackaging = false
                            // Show success message
                        }
                    }
                }
            }
            
            enum Platform: String, CaseIterable {
                case macOS = "macOS"
                case iOS = "iOS"
                case iPadOS = "iPadOS"
                case watchOS = "watchOS"
                case tvOS = "tvOS"
            }
            
            enum ExportFormat: String, CaseIterable {
                case app = ".app Bundle"
                case dmg = "DMG Image"
                case pkg = "PKG Installer"
                case zip = "ZIP Archive"
            }
            """,
            features: ["App Bundling", "Multi-Platform Export", "Code Signing", "Distribution"],
            dependencies: []
        )
    }
    
    private var testerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.tester,
            category: HubCategory.development,
            sampleCode: """
            import SwiftUI
            
            struct TesterView: View {
                @State private var testSuites: [TestSuite] = []
                @State private var isRunning = false
                @State private var selectedSuite: TestSuite?
                @State private var testResults: [TestResult] = []
                
                var body: some View {
                    NavigationSplitView {
                        List(testSuites, selection: $selectedSuite) { suite in
                            TestSuiteRow(suite: suite)
                        }
                        .navigationTitle("Test Suites")
                        .toolbar {
                            Button("Run All") {
                                runAllTests()
                            }
                            .disabled(isRunning)
                        }
                    } detail: {
                        if let suite = selectedSuite {
                            TestSuiteDetailView(
                                suite: suite,
                                results: testResults.filter { $0.suiteID == suite.id },
                                isRunning: isRunning,
                                onRun: { runTests(for: suite) }
                            )
                        } else {
                            Text("Select a test suite")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onAppear {
                        loadTestSuites()
                    }
                }
                
                func loadTestSuites() {
                    testSuites = [
                        TestSuite(name: "Unit Tests", testCount: 45),
                        TestSuite(name: "Integration Tests", testCount: 23),
                        TestSuite(name: "UI Tests", testCount: 12)
                    ]
                }
                
                func runAllTests() {
                    isRunning = true
                    testResults = []
                    
                    Task {
                        for suite in testSuites {
                            await runTests(for: suite)
                        }
                        await MainActor.run {
                            isRunning = false
                        }
                    }
                }
                
                func runTests(for suite: TestSuite) async {
                    // Simulate test execution
                    for i in 1...suite.testCount {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        
                        let _ = TestResult(
                            suiteID: suite.id,
                            testName: "Test \\(i)",
                            status: Bool.random() ? .passed : .failed,
                            duration: Double.random(in: 0.01...0.5)
                        )
                        
                        await MainActor.run {
                            testResults.append(result)
                        }
                    }
                }
            }
            
            struct TestSuite: Identifiable {
                let id = UUID()
                let name: String
                let testCount: Int
            }
            
            struct TestSuiteRow: View {
                let suite: TestSuite
                
                var body: some View {
                    VStack(alignment: .leading) {
                        Text(suite.name)
                            .font(.headline)
                        Text("\\(suite.testCount) tests")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            struct TestResult: Identifiable {
                let id = UUID()
                let suiteID: UUID
                let testName: String
                let status: TestStatus
                let duration: Double
                
                enum TestStatus {
                    case passed
                    case failed
                    case skipped
                }
            }
            
            struct TestSuiteDetailView: View {
                let suite: TestSuite
                let results: [TestResult]
                let isRunning: Bool
                let onRun: () -> Void
                
                var passedCount: Int {
                    results.filter { $0.status == .passed }.count
                }
                
                var failedCount: Int {
                    results.filter { $0.status == .failed }.count
                }
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(suite.name)
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            Button("Run Tests") {
                                onRun()
                            }
                            .disabled(isRunning)
                        }
                        .padding()
                        
                        if !results.isEmpty {
                            HStack(spacing: 20) {
                                StatView(title: "Passed", value: passedCount, color: .green)
                                StatView(title: "Failed", value: failedCount, color: .red)
                                StatView(title: "Total", value: results.count, color: .blue)
                            }
                            .padding(.horizontal)
                        }
                        
                        List(results) { result in
                            TestResultRow(result: result)
                        }
                    }
                }
            }
            
            struct TestResultRow: View {
                let result: TestResult
                
                var body: some View {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)
                        
                        VStack(alignment: .leading) {
                            Text(result.testName)
                            Text(String(format: "%.3fs", result.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                var statusIcon: String {
                    switch result.status {
                    case .passed: return "checkmark.circle.fill"
                    case .failed: return "xmark.circle.fill"
                    case .skipped: return "minus.circle.fill"
                    }
                }
                
                var statusColor: Color {
                    switch result.status {
                    case .passed: return .green
                    case .failed: return .red
                    case .skipped: return .gray
                    }
                }
            }
            
            struct StatView: View {
                let title: String
                let value: Int
                let color: Color
                
                var body: some View {
                    VStack {
                        Text("\\(value)")
                            .font(.title)
                            .bold()
                            .foregroundStyle(color)
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            """,
            features: ["Test Runner", "Test Reports", "Code Coverage", "Automated Validation"],
            dependencies: []
        )
    }
    
    // MARK: - Content & Media Hubs
    
    private var converterTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.converter,
            category: HubCategory.utilities,
            sampleCode: """
            import SwiftUI
            import UniformTypeIdentifiers
            
            struct ConverterView: View {
                @State private var inputFormat: FileFormat = .json
                @State private var outputFormat: FileFormat = .xml
                @State private var inputText = ""
                @State private var outputText = ""
                @State private var isConverting = false
                @State private var errorMessage: String?
                
                var body: some View {
                    NavigationStack {
                        VStack(spacing: 16) {
                            // Format Selection
                            HStack(spacing: 20) {
                                VStack(alignment: .leading) {
                                    Text("From")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Picker("Input Format", selection: $inputFormat) {
                                        ForEach(FileFormat.allCases, id: '\'.self) { format in
                                            Text(format.rawValue).tag(format)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading) {
                                    Text("To")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Picker("Output Format", selection: $outputFormat) {
                                        ForEach(FileFormat.allCases, id: '\'.self) { format in
                                            Text(format.rawValue).tag(format)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .padding()
                            
                            // Input/Output Areas
                            HSplitView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Input")
                                        .font(.headline)
                                    TextEditor(text: $inputText)
                                        .font(.system(.body, design: .monospaced))
                                        .border(Color.gray.opacity(0.3))
                                }
                                .padding()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Output")
                                        .font(.headline)
                                    TextEditor(text: $outputText)
                                        .font(.system(.body, design: .monospaced))
                                        .border(Color.gray.opacity(0.3))
                                }
                                .padding()
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                        }
                        .navigationTitle("Converter")
                        .toolbar {
                            Button("Convert") {
                                convertFile()
                            }
                            .disabled(isConverting || inputText.isEmpty)
                            
                            Button("Clear") {
                                inputText = ""
                                outputText = ""
                                errorMessage = nil
                            }
                        }
                    }
                }
                
                func convertFile() {
                    isConverting = true
                    errorMessage = nil
                    
                    Task {
                        do {
                            // Simulate conversion
                            try await Task.sleep(nanoseconds: 500_000_000)
                            
                            let converted = try performConversion(
                                input: inputText,
                                from: inputFormat,
                                to: outputFormat
                            )
                            
                            await MainActor.run {
                                outputText = converted
                                isConverting = false
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Conversion failed: \\(error.localizedDescription)"
                                isConverting = false
                            }
                        }
                    }
                }
                
                func performConversion(input: String, from: FileFormat, to: FileFormat) throws -> String {
                    // Basic conversion logic
                    if from == to {
                        return input
                    }
                    
                    // Simulate format conversion
                    return "// Converted from \\(from.rawValue) to \\(to.rawValue)\\n\\(input)"
                }
            }
            
            enum FileFormat: String, CaseIterable {
                case json = "JSON"
                case xml = "XML"
                case yaml = "YAML"
                case csv = "CSV"
                case markdown = "Markdown"
                case html = "HTML"
                case pdf = "PDF"
                case text = "Plain Text"
            }
            """,
            features: ["Format Conversion", "Batch Processing", "Preview", "Multiple Formats"],
            dependencies: []
        )
    }
    
    private var optimizerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.optimizer,
            category: HubCategory.utilities,
            sampleCode: """
            import SwiftUI
            
            struct OptimizerView: View {
                @State private var selectedFiles: [OptimizableFile] = []
                @State private var compressionLevel: CompressionLevel = .balanced
                @State private var isOptimizing = false
                @State private var optimizationProgress: Double = 0.0
                @State private var results: [OptimizationResult] = []
                
                var totalSavings: Int64 {
                    results.reduce(0) { $0 + ($1.originalSize - $1.optimizedSize) }
                }
                
                var body: some View {
                    NavigationStack {
                        VStack(spacing: 0) {
                            // Settings Panel
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Optimization Settings")
                                    .font(.headline)
                                
                                Picker("Compression Level", selection: $compressionLevel) {
                                    ForEach(CompressionLevel.allCases, id: '\'.self) { level in
                                        Text(level.rawValue).tag(level)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                HStack {
                                    Text("Quality: \\(compressionLevel.quality)%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("Speed: \\(compressionLevel.speed)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            
                            Divider()
                            
                            // File List
                            if selectedFiles.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                    Text("Drop files here to optimize")
                                        .foregroundStyle(.secondary)
                                    Button("Select Files") {
                                        selectFiles()
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                List {
                                    Section {
                                        ForEach(selectedFiles) { file in
                                            FileRow(file: file)
                                        }
                                        .onDelete(perform: removeFiles)
                                    } header: {
                                        HStack {
                                            Text("\\(selectedFiles.count) files")
                                            Spacer()
                                            if !results.isEmpty {
                                                Text("Saved: \\(formatBytes(totalSavings))")
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Progress
                            if isOptimizing {
                                VStack(spacing: 8) {
                                    ProgressView(value: optimizationProgress)
                                    Text("Optimizing... \\(Int(optimizationProgress * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                        .navigationTitle("Optimizer")
                        .toolbar {
                            Button("Add Files") {
                                selectFiles()
                            }
                            
                            Button("Optimize") {
                                optimizeFiles()
                            }
                            .disabled(selectedFiles.isEmpty || isOptimizing)
                        }
                    }
                }
                
                func selectFiles() {
                    // Simulate file selection
                    let newFiles = [
                        OptimizableFile(name: "image1.png", size: 2_500_000, type: .image),
                        OptimizableFile(name: "video.mp4", size: 15_000_000, type: .video),
                        OptimizableFile(name: "document.pdf", size: 1_200_000, type: .document)
                    ]
                    selectedFiles.append(contentsOf: newFiles)
                }
                
                func removeFiles(at offsets: IndexSet) {
                    selectedFiles.remove(atOffsets: offsets)
                }
                
                func optimizeFiles() {
                    isOptimizing = true
                    optimizationProgress = 0.0
                    results = []
                    
                    Task {
                        for (index, file) in selectedFiles.enumerated() {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            
                            let optimizedSize = Int64(Double(file.size) * compressionLevel.compressionRatio)
                            let _ = OptimizationResult(
                                fileName: file.name,
                                originalSize: file.size,
                                optimizedSize: optimizedSize
                            )
                            
                            await MainActor.run {
                                results.append(result)
                                optimizationProgress = Double(index + 1) / Double(selectedFiles.count)
                            }
                        }
                        
                        await MainActor.run {
                            isOptimizing = false
                        }
                    }
                }
                
                func formatBytes(_ bytes: Int64) -> String {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: bytes)
                }
            }
            
            struct OptimizableFile: Identifiable {
                let id = UUID()
                let name: String
                let size: Int64
                let type: FileType
                
                enum FileType {
                    case image
                    case video
                    case audio
                    case document
                }
            }
            
            struct FileRow: View {
                let file: OptimizableFile
                
                var body: some View {
                    HStack {
                        Image(systemName: fileIcon)
                            .foregroundStyle(fileColor)
                        
                        VStack(alignment: .leading) {
                            Text(file.name)
                            Text(formatBytes(file.size))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                var fileIcon: String {
                    switch file.type {
                    case .image: return "photo"
                    case .video: return "video"
                    case .audio: return "music.note"
                    case .document: return "doc"
                    }
                }
                
                var fileColor: Color {
                    switch file.type {
                    case .image: return .blue
                    case .video: return .purple
                    case .audio: return .pink
                    case .document: return .orange
                    }
                }
                
                func formatBytes(_ bytes: Int64) -> String {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: bytes)
                }
            }
            
            enum CompressionLevel: String, CaseIterable {
                case maximum = "Maximum"
                case balanced = "Balanced"
                case fast = "Fast"
                
                var quality: Int {
                    switch self {
                    case .maximum: return 95
                    case .balanced: return 85
                    case .fast: return 75
                    }
                }
                
                var speed: String {
                    switch self {
                    case .maximum: return "Slow"
                    case .balanced: return "Medium"
                    case .fast: return "Fast"
                    }
                }
                
                var compressionRatio: Double {
                    switch self {
                    case .maximum: return 0.4
                    case .balanced: return 0.6
                    case .fast: return 0.75
                    }
                }
            }
            
            struct OptimizationResult {
                let fileName: String
                let originalSize: Int64
                let optimizedSize: Int64
            }
            """,
            features: ["Image Compression", "Video Optimization", "Batch Processing", "Quality Control"],
            dependencies: []
        )
    }
    
    private var galleryTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.gallery,
            category: HubCategory.creative,
            sampleCode: """
            import SwiftUI
            
            struct GalleryView: View {
                @State private var assets: [Asset] = []
                @State private var selectedAsset: Asset?
                @State private var viewMode: ViewMode = .grid
                @State private var searchText = ""
                @State private var selectedCategory: AssetCategory?
                
                var filteredAssets: [Asset] {
                    assets.filter { asset in
                        let matchesSearch = searchText.isEmpty || asset.name.localizedCaseInsensitiveContains(searchText)
                        let matchesCategory = selectedCategory == nil || asset.category == selectedCategory
                        return matchesSearch && matchesCategory
                    }
                }
                
                var body: some View {
                    NavigationSplitView {
                        List(AssetCategory.allCases, id: '\'.self, selection: $selectedCategory) { category in
                            Label(category.rawValue, systemImage: category.icon)
                        }
                        .navigationTitle("Categories")
                    } content: {
                        VStack(spacing: 0) {
                            // Toolbar
                            HStack {
                                Picker("View", selection: $viewMode) {
                                    Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                                    Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                                
                                Spacer()
                                
                                Text("\\(filteredAssets.count) items")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            
                            Divider()
                            
                            // Content
                            if viewMode == .grid {
                                ScrollView {
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 150), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(filteredAssets) { asset in
                                            AssetGridItem(asset: asset, isSelected: selectedAsset?.id == asset.id)
                                                .onTapGesture {
                                                    selectedAsset = asset
                                                }
                                        }
                                    }
                                    .padding()
                                }
                            } else {
                                List(filteredAssets, selection: $selectedAsset) { asset in
                                    AssetListItem(asset: asset)
                                }
                            }
                        }
                        .searchable(text: $searchText)
                        .navigationTitle(selectedCategory?.rawValue ?? "All Assets")
                        .toolbar {
                            Button("Import") {
                                importAssets()
                            }
                        }
                    } detail: {
                        if let asset = selectedAsset {
                            AssetDetailView(asset: asset)
                        } else {
                            Text("Select an asset")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onAppear {
                        loadAssets()
                    }
                }
                
                func loadAssets() {
                    assets = [
                        Asset(name: "Logo.png", category: .images, size: 125_000, dateAdded: Date()),
                        Asset(name: "Background.jpg", category: .images, size: 450_000, dateAdded: Date()),
                        Asset(name: "Icon.svg", category: .vectors, size: 8_500, dateAdded: Date()),
                        Asset(name: "Intro.mp4", category: .videos, size: 5_200_000, dateAdded: Date()),
                        Asset(name: "Theme.mp3", category: .audio, size: 3_100_000, dateAdded: Date())
                    ]
                }
                
                func importAssets() {
                    // Import logic
                }
            }
            
            struct Asset: Identifiable, Hashable {
                let id = UUID()
                let name: String
                let category: AssetCategory
                let size: Int64
                let dateAdded: Date
            }
            
            enum AssetCategory: String, CaseIterable {
                case images = "Images"
                case videos = "Videos"
                case audio = "Audio"
                case vectors = "Vectors"
                case documents = "Documents"
                
                var icon: String {
                    switch self {
                    case .images: return "photo"
                    case .videos: return "video"
                    case .audio: return "music.note"
                    case .vectors: return "square.and.pencil"
                    case .documents: return "doc"
                    }
                }
            }
            
            enum ViewMode {
                case grid
                case list
            }
            
            struct AssetGridItem: View {
                let asset: Asset
                let isSelected: Bool
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: asset.category.icon)
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                            )
                        
                        Text(asset.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Text(formatBytes(asset.size))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                func formatBytes(_ bytes: Int64) -> String {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: bytes)
                }
            }
            
            struct AssetListItem: View {
                let asset: Asset
                
                var body: some View {
                    HStack {
                        Image(systemName: asset.category.icon)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text(asset.name)
                            Text(formatBytes(asset.size))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(asset.dateAdded, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                func formatBytes(_ bytes: Int64) -> String {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: bytes)
                }
            }
            
            struct AssetDetailView: View {
                let asset: Asset
                
                var body: some View {
                    VStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 300, height: 300)
                            .overlay(
                                Image(systemName: asset.category.icon)
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                            )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(label: "Name", value: asset.name)
                            DetailRow(label: "Category", value: asset.category.rawValue)
                            DetailRow(label: "Size", value: formatBytes(asset.size))
                            DetailRow(label: "Added", value: asset.dateAdded.formatted(date: .long, time: .shortened))
                        }
                        .frame(maxWidth: 400)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationTitle(asset.name)
                }
                
                func formatBytes(_ bytes: Int64) -> String {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: bytes)
                }
            }
            
            struct DetailRow: View {
                let label: String
                let value: String
                
                var body: some View {
                    HStack {
                        Text(label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(value)
                    }
                }
            }
            """,
            features: ["Asset Library", "Grid/List View", "Search & Filter", "Import/Export"],
            dependencies: []
        )
    }
    
    private var playerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.player,
            category: HubCategory.creative,
            sampleCode: """
            import SwiftUI
            import AVKit
            
            struct PlayerView: View {
                @State private var mediaItems: [MediaItem] = []
                @State private var selectedItem: MediaItem?
                @State private var isPlaying = false
                @State private var currentTime: Double = 0
                @State private var duration: Double = 100
                
                var body: some View {
                    NavigationSplitView {
                        List(mediaItems, selection: $selectedItem) { item in
                            MediaItemRow(item: item)
                        }
                        .navigationTitle("Media")
                        .toolbar {
                            Button("Add") {
                                addMedia()
                            }
                        }
                    } detail: {
                        if let item = selectedItem {
                            VStack(spacing: 0) {
                                // Preview Area
                                ZStack {
                                    Color.black
                                    
                                    VStack(spacing: 20) {
                                        Image(systemName: item.type.icon)
                                            .font(.system(size: 80))
                                            .foregroundStyle(.white.opacity(0.8))
                                        
                                        Text(item.name)
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 400)
                                
                                // Controls
                                VStack(spacing: 16) {
                                    // Progress Bar
                                    VStack(spacing: 4) {
                                        Slider(value: $currentTime, in: 0...duration)
                                        
                                        HStack {
                                            Text(formatTime(currentTime))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(formatTime(duration))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    // Playback Controls
                                    HStack(spacing: 30) {
                                        Button(action: previousTrack) {
                                            Image(systemName: "backward.fill")
                                                .font(.title2)
                                        }
                                        
                                        Button(action: togglePlayback) {
                                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.system(size: 50))
                                        }
                                        
                                        Button(action: nextTrack) {
                                            Image(systemName: "forward.fill")
                                                .font(.title2)
                                        }
                                    }
                                    
                                    // Volume Control
                                    HStack {
                                        Image(systemName: "speaker.fill")
                                            .foregroundStyle(.secondary)
                                        Slider(value: .constant(0.7), in: 0...1)
                                            .frame(width: 150)
                                        Image(systemName: "speaker.wave.3.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(nsColor: .controlBackgroundColor))
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                Text("Select media to play")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onAppear {
                        loadMediaItems()
                    }
                }
                
                func loadMediaItems() {
                    mediaItems = [
                        MediaItem(name: "Sample Video.mp4", type: .video, duration: 180),
                        MediaItem(name: "Background Music.mp3", type: .audio, duration: 240),
                        MediaItem(name: "Animation.gif", type: .animation, duration: 5)
                    ]
                }
                
                func addMedia() {
                    // Add media logic
                }
                
                func togglePlayback() {
                    isPlaying.toggle()
                    
                    if isPlaying {
                        // Simulate playback
                        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                            if isPlaying && currentTime < duration {
                                currentTime += 0.1
                            } else {
                                timer.invalidate()
                                isPlaying = false
                            }
                        }
                    }
                }
                
                func previousTrack() {
                    guard let current = selectedItem,
                          let index = mediaItems.firstIndex(where: { $0.id == current.id }),
                          index > 0 else { return }
                    selectedItem = mediaItems[index - 1]
                    currentTime = 0
                }
                
                func nextTrack() {
                    guard let current = selectedItem,
                          let index = mediaItems.firstIndex(where: { $0.id == current.id }),
                          index < mediaItems.count - 1 else { return }
                    selectedItem = mediaItems[index + 1]
                    currentTime = 0
                }
                
                func formatTime(_ seconds: Double) -> String {
                    let minutes = Int(seconds) / 60
                    let secs = Int(seconds) % 60
                    return String(format: "%d:%02d", minutes, secs)
                }
            }
            
            struct MediaItem: Identifiable, Hashable {
                let id = UUID()
                let name: String
                let type: MediaType
                let duration: Double
                
                enum MediaType {
                    case video
                    case audio
                    case animation
                    
                    var icon: String {
                        switch self {
                        case .video: return "video.fill"
                        case .audio: return "music.note"
                        case .animation: return "sparkles"
                        }
                    }
                }
            }
            
            struct MediaItemRow: View {
                let item: MediaItem
                
                var body: some View {
                    HStack {
                        Image(systemName: item.type.icon)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text(item.name)
                            Text(formatDuration(item.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                func formatDuration(_ seconds: Double) -> String {
                    let minutes = Int(seconds) / 60
                    let secs = Int(seconds) % 60
                    return String(format: "%d:%02d", minutes, secs)
                }
            }
            """,
            features: ["Media Playback", "Audio/Video Support", "Playlist Management", "Preview"],
            dependencies: ["AVKit"]
        )
    }
    
    // MARK: - Collaboration & Sync Hubs
    
    private var syncerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.syncer,
            category: HubCategory.utilities,
            sampleCode: """
            import SwiftUI
            
            struct SyncerView: View {
                @State private var projects: [SyncProject] = []
                @State private var isSyncing = false
                
                var body: some View {
                    NavigationStack {
                        List(projects) { project in
                            HStack {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(project.name)
                                    Text("Last sync: \\(project.lastSync, style: .relative)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .navigationTitle("Syncer")
                        .toolbar {
                            Button("Sync All") {
                                syncAll()
                            }
                            .disabled(isSyncing)
                        }
                    }
                }
                
                func syncAll() {
                    isSyncing = true
                    // Sync logic
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isSyncing = false
                    }
                }
            }
            
            struct SyncProject: Identifiable {
                let id = UUID()
                let name: String
                let lastSync: Date
            }
            """,
            features: ["Cloud Sync", "Version Control", "Conflict Resolution", "CloudKit Integration"],
            dependencies: ["CloudKit"]
        )
    }
    
    private var sharerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.sharer,
            category: HubCategory.utilities,
            sampleCode: """
            import SwiftUI
            
            struct SharerView: View {
                @State private var items: [ShareableItem] = []
                @State private var isPublishing = false
                
                var body: some View {
                    NavigationStack {
                        List(items) { item in
                            HStack {
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    if item.isPublished {
                                        Text("Published")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Sharer")
                        .toolbar {
                            Button("Publish") {
                                publishItems()
                            }
                            .disabled(isPublishing)
                        }
                    }
                }
                
                func publishItems() {
                    isPublishing = true
                    // Publish logic
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPublishing = false
                    }
                }
            }
            
            struct ShareableItem: Identifiable {
                let id = UUID()
                let name: String
                var isPublished: Bool
            }
            """,
            features: ["Export", "Publish", "Collaboration Tools", "Share Links"],
            dependencies: []
        )
    }
    
    private var reviewerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.reviewer,
            category: HubCategory.productivity,
            sampleCode: """
            import SwiftUI
            
            struct ReviewerView: View {
                @State private var reviews: [Review] = []
                @State private var filterStatus: ReviewStatus? = nil
                
                var filteredReviews: [Review] {
                    if let status = filterStatus {
                        return reviews.filter { $0.status == status }
                    }
                    return reviews
                }
                
                var body: some View {
                    NavigationStack {
                        VStack {
                            Picker("Filter", selection: $filterStatus) {
                                Text("All").tag(nil as ReviewStatus?)
                                Text("Pending").tag(ReviewStatus.pending as ReviewStatus?)
                                Text("Approved").tag(ReviewStatus.approved as ReviewStatus?)
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            
                            List(filteredReviews) { review in
                                HStack {
                                    Image(systemName: review.status.icon)
                                        .foregroundStyle(review.status.color)
                                    VStack(alignment: .leading) {
                                        Text(review.title)
                                        Text(review.author)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Reviewer")
                    }
                }
            }
            
            struct Review: Identifiable {
                let id = UUID()
                let title: String
                let author: String
                var status: ReviewStatus
            }
            
            enum ReviewStatus {
                case pending
                case approved
                case rejected
                
                var icon: String {
                    switch self {
                    case .pending: return "clock.fill"
                    case .approved: return "checkmark.circle.fill"
                    case .rejected: return "xmark.circle.fill"
                    }
                }
                
                var color: Color {
                    switch self {
                    case .pending: return .orange
                    case .approved: return .green
                    case .rejected: return .red
                    }
                }
            }
            """,
            features: ["Feedback", "Approval Workflows", "Comments", "Status Tracking"],
            dependencies: []
        )
    }
    
    // MARK: - Analytics & Insights Hubs
    
    private var analyzerTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.analyzer,
            category: HubCategory.development,
            sampleCode: """
            import SwiftUI
            import Charts
            
            struct AnalyzerView: View {
                @State private var analysisResults: [AnalysisMetric] = []
                @State private var selectedProject: String = "Current Project"
                @State private var isAnalyzing = false
                @State private var selectedMetric: MetricType = .codeQuality
                
                var body: some View {
                    NavigationStack {
                        VStack(spacing: 0) {
                            // Header with Project Selector
                            HStack {
                                Picker("Project", selection: $selectedProject) {
                                    Text("Current Project").tag("Current Project")
                                    Text("Project A").tag("Project A")
                                    Text("Project B").tag("Project B")
                                }
                                .frame(width: 200)
                                
                                Spacer()
                                
                                Button(action: runAnalysis) {
                                    Label("Analyze", systemImage: "chart.bar.xaxis")
                                }
                                .disabled(isAnalyzing)
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            
                            Divider()
                            
                            // Metric Type Selector
                            Picker("Metric Type", selection: $selectedMetric) {
                                ForEach(MetricType.allCases, id: '\'.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            
                            // Charts and Metrics
                            if analysisResults.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                    Text("No analysis data yet")
                                        .foregroundStyle(.secondary)
                                    Text("Click 'Analyze' to generate metrics")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                ScrollView {
                                    VStack(spacing: 24) {
                                        // Summary Cards
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 16) {
                                            MetricCard(
                                                title: "Code Quality",
                                                value: "87%",
                                                trend: "+5%",
                                                color: .green
                                            )
                                            MetricCard(
                                                title: "Test Coverage",
                                                value: "72%",
                                                trend: "+3%",
                                                color: .blue
                                            )
                                            MetricCard(
                                                title: "Complexity",
                                                value: "Medium",
                                                trend: "-2%",
                                                color: .orange
                                            )
                                        }
                                        .padding(.horizontal)
                                        
                                        // Chart
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Metrics Over Time")
                                                .font(.headline)
                                                .padding(.horizontal)
                                            
                                            Chart(analysisResults) { metric in
                                                LineMark(
                                                    x: .value("Date", metric.date),
                                                    y: .value("Score", metric.score)
                                                )
                                                .foregroundStyle(by: .value("Type", metric.type.rawValue))
                                            }
                                            .frame(height: 250)
                                            .padding()
                                            .background(Color(nsColor: .controlBackgroundColor))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                                        
                                        // Detailed Metrics List
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Detailed Metrics")
                                                .font(.headline)
                                                .padding(.horizontal)
                                            
                                            ForEach(analysisResults.filter { $0.type == selectedMetric }) { metric in
                                                MetricRow(metric: metric)
                                            }
                                        }
                                    }
                                    .padding(.vertical)
                                }
                            }
                        }
                        .navigationTitle("Analyzer")
                    }
                }
                
                func runAnalysis() {
                    isAnalyzing = true
                    
                    Task {
                        // Simulate analysis
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        let newResults = MetricType.allCases.flatMap { type in
                            (0..<7).map { day in
                                AnalysisMetric(
                                    type: type,
                                    score: Double.random(in: 60...95),
                                    date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!
                                )
                            }
                        }
                        
                        await MainActor.run {
                            analysisResults = newResults.sorted { $0.date < $1.date }
                            isAnalyzing = false
                        }
                    }
                }
            }
            
            struct AnalysisMetric: Identifiable {
                let id = UUID()
                let type: MetricType
                let score: Double
                let date: Date
            }
            
            enum MetricType: String, CaseIterable {
                case codeQuality = "Code Quality"
                case testCoverage = "Test Coverage"
                case complexity = "Complexity"
                case maintainability = "Maintainability"
            }
            
            struct MetricCard: View {
                let title: String
                let value: String
                let trend: String
                let color: Color
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(value)
                            .font(.title)
                            .bold()
                            .foregroundStyle(color)
                        
                        HStack(spacing: 4) {
                            Image(systemName: trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(trend)
                                .font(.caption)
                        }
                        .foregroundStyle(trend.hasPrefix("+") ? .green : .red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            
            struct MetricRow: View {
                let metric: AnalysisMetric
                
                var body: some View {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.type.rawValue)
                                .font(.body)
                            Text(metric.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", metric.score))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(scoreColor(metric.score))
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                func scoreColor(_ score: Double) -> Color {
                    if score >= 80 { return .green }
                    if score >= 60 { return .orange }
                    return .red
                }
            }
            """,
            features: ["Code Analysis", "Metrics Dashboard", "Trend Charts", "Quality Reports"],
            dependencies: ["Charts"]
        )
    }
    
    private var reporterTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.reporter,
            category: HubCategory.business,
            sampleCode: """
            import SwiftUI
            
            struct ReporterView: View {
                @State private var reports: [Report] = []
                @State private var selectedReport: Report?
                @State private var isGenerating = false
                @State private var reportType: ReportType = .summary
                @State private var dateRange: DateRange = .lastWeek
                
                var body: some View {
                    NavigationSplitView {
                        VStack(spacing: 0) {
                            // Report Configuration
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Generate Report")
                                    .font(.headline)
                                
                                Picker("Report Type", selection: $reportType) {
                                    ForEach(ReportType.allCases, id: '\'.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                
                                Picker("Date Range", selection: $dateRange) {
                                    ForEach(DateRange.allCases, id: '\'.self) { range in
                                        Text(range.rawValue).tag(range)
                                    }
                                }
                                
                                Button(action: generateReport) {
                                    Label("Generate Report", systemImage: "doc.text.magnifyingglass")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isGenerating)
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            
                            Divider()
                            
                            // Reports List
                            List(reports, selection: $selectedReport) { report in
                                ReportListItem(report: report)
                            }
                            .navigationTitle("Reports")
                        }
                    } detail: {
                        if let report = selectedReport {
                            ReportDetailView(report: report)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                Text("Select a report to view")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                
                func generateReport() {
                    isGenerating = true
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        
                        let newReport = Report(
                            title: "\\(reportType.rawValue) Report",
                            type: reportType,
                            dateRange: dateRange,
                            generatedAt: Date(),
                            summary: generateSummary(),
                            data: generateData()
                        )
                        
                        await MainActor.run {
                            reports.insert(newReport, at: 0)
                            selectedReport = newReport
                            isGenerating = false
                        }
                    }
                }
                
                func generateSummary() -> String {
                    switch reportType {
                    case .summary:
                        return "Overall project health is good. 87% code quality, 72% test coverage."
                    case .detailed:
                        return "Comprehensive analysis of all project metrics including code quality, test coverage, complexity, and maintainability scores."
                    case .performance:
                        return "Performance metrics show average response time of 120ms with 99.5% uptime."
                    case .usage:
                        return "User engagement increased by 15% with 1,234 active users this period."
                    }
                }
                
                func generateData() -> [ReportDataPoint] {
                    (0..<10).map { i in
                        ReportDataPoint(
                            label: "Metric \\(i + 1)",
                            value: Double.random(in: 50...100)
                        )
                    }
                }
            }
            
            struct Report: Identifiable, Hashable {
                let id = UUID()
                let title: String
                let type: ReportType
                let dateRange: DateRange
                let generatedAt: Date
                let summary: String
                let data: [ReportDataPoint]
            }
            
            struct ReportDataPoint: Hashable {
                let label: String
                let value: Double
            }
            
            enum ReportType: String, CaseIterable {
                case summary = "Summary"
                case detailed = "Detailed"
                case performance = "Performance"
                case usage = "Usage"
            }
            
            enum DateRange: String, CaseIterable {
                case lastWeek = "Last Week"
                case lastMonth = "Last Month"
                case lastQuarter = "Last Quarter"
                case lastYear = "Last Year"
            }
            
            struct ReportListItem: View {
                let report: Report
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.title)
                            .font(.headline)
                        HStack {
                            Text(report.type.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                            
                            Text(report.generatedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            struct ReportDetailView: View {
                let report: Report
                
                var body: some View {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(report.title)
                                    .font(.title)
                                    .bold()
                                
                                HStack {
                                    Label(report.type.rawValue, systemImage: "doc.text")
                                    Text("•")
                                    Label(report.dateRange.rawValue, systemImage: "calendar")
                                    Text("•")
                                    Text(report.generatedAt, style: .date)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                            
                            // Summary
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(.headline)
                                Text(report.summary)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                            
                            // Data
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Metrics")
                                    .font(.headline)
                                
                                ForEach(report.data, id: '\'.label) { dataPoint in
                                    HStack {
                                        Text(dataPoint.label)
                                        Spacer()
                                        Text(String(format: "%.1f%%", dataPoint.value))
                                            .bold()
                                            .foregroundStyle(dataPoint.value >= 70 ? .green : .orange)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Divider()
                            
                            // Export Options
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Export")
                                    .font(.headline)
                                
                                HStack(spacing: 12) {
                                    Button(action: {}) {
                                        Label("PDF", systemImage: "doc.fill")
                                    }
                                    Button(action: {}) {
                                        Label("CSV", systemImage: "tablecells")
                                    }
                                    Button(action: {}) {
                                        Label("JSON", systemImage: "curlybraces")
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle(report.title)
                }
            }
            """,
            features: ["Report Generation", "Multiple Formats", "Data Export", "Custom Date Ranges"],
            dependencies: []
        )
    }
    
    private var monitorTemplate: HubTemplateDefinition {
        HubTemplateDefinition(
            template: HubTemplate.monitor,
            category: HubCategory.development,
            sampleCode: """
            import SwiftUI
            import Charts
            
            struct MonitorView: View {
                @State private var isMonitoring = false
                @State private var metrics: [SystemMetric] = []
                @State private var alerts: [Alert] = []
                @State private var selectedTimeRange: TimeRange = .last15Minutes
                @State private var refreshTimer: Timer?
                
                var filteredMetrics: [SystemMetric] {
                    let cutoffDate = selectedTimeRange.cutoffDate
                    return metrics.filter { $0.timestamp >= cutoffDate }
                }
                
                var body: some View {
                    NavigationStack {
                        VStack(spacing: 0) {
                            // Control Bar
                            HStack {
                                Button(action: toggleMonitoring) {
                                    Label(
                                        isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                                        systemImage: isMonitoring ? "stop.circle.fill" : "play.circle.fill"
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(isMonitoring ? .red : .green)
                                
                                Spacer()
                                
                                Picker("Time Range", selection: $selectedTimeRange) {
                                    ForEach(TimeRange.allCases, id: '\'.self) { range in
                                        Text(range.rawValue).tag(range)
                                    }
                                }
                                .frame(width: 200)
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            
                            Divider()
                            
                            ScrollView {
                                VStack(spacing: 24) {
                                    // Status Cards
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 16) {
                                        StatusCard(
                                            title: "CPU",
                                            value: currentCPU,
                                            unit: "%",
                                            status: cpuStatus
                                        )
                                        StatusCard(
                                            title: "Memory",
                                            value: currentMemory,
                                            unit: "MB",
                                            status: memoryStatus
                                        )
                                        StatusCard(
                                            title: "Network",
                                            value: currentNetwork,
                                            unit: "KB/s",
                                            status: .normal
                                        )
                                        StatusCard(
                                            title: "Requests",
                                            value: currentRequests,
                                            unit: "/min",
                                            status: .normal
                                        )
                                    }
                                    .padding(.horizontal)
                                    
                                    // Real-time Charts
                                    if !filteredMetrics.isEmpty {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("System Metrics")
                                                .font(.headline)
                                                .padding(.horizontal)
                                            
                                            Chart(filteredMetrics) { metric in
                                                LineMark(
                                                    x: .value("Time", metric.timestamp),
                                                    y: .value("CPU", metric.cpu)
                                                )
                                                .foregroundStyle(.blue)
                                                .interpolationMethod(.catmullRom)
                                            }
                                            .frame(height: 200)
                                            .chartYAxis {
                                                AxisMarks(position: .leading)
                                            }
                                            .padding()
                                            .background(Color(nsColor: .controlBackgroundColor))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                            
                                            Chart(filteredMetrics) { metric in
                                                LineMark(
                                                    x: .value("Time", metric.timestamp),
                                                    y: .value("Memory", metric.memory)
                                                )
                                                .foregroundStyle(.purple)
                                                .interpolationMethod(.catmullRom)
                                            }
                                            .frame(height: 200)
                                            .chartYAxis {
                                                AxisMarks(position: .leading)
                                            }
                                            .padding()
                                            .background(Color(nsColor: .controlBackgroundColor))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                                    }
                                    
                                    // Alerts Section
                                    if !alerts.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Active Alerts")
                                                .font(.headline)
                                                .padding(.horizontal)
                                            
                                            ForEach(alerts) { alert in
                                                AlertRow(alert: alert)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                        .navigationTitle("Monitor")
                    }
                    .onDisappear {
                        stopMonitoring()
                    }
                }
                
                var currentCPU: Double {
                    filteredMetrics.last?.cpu ?? 0
                }
                
                var currentMemory: Double {
                    filteredMetrics.last?.memory ?? 0
                }
                
                var currentNetwork: Double {
                    filteredMetrics.last?.network ?? 0
                }
                
                var currentRequests: Double {
                    filteredMetrics.last?.requests ?? 0
                }
                
                var cpuStatus: MetricStatus {
                    if currentCPU > 80 { return .critical }
                    if currentCPU > 60 { return .warning }
                    return .normal
                }
                
                var memoryStatus: MetricStatus {
                    if currentMemory > 800 { return .critical }
                    if currentMemory > 600 { return .warning }
                    return .normal
                }
                
                func toggleMonitoring() {
                    if isMonitoring {
                        stopMonitoring()
                    } else {
                        startMonitoring()
                    }
                }
                
                func startMonitoring() {
                    isMonitoring = true
                    metrics = []
                    alerts = []
                    
                    refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                        collectMetrics()
                    }
                }
                
                func stopMonitoring() {
                    isMonitoring = false
                    refreshTimer?.invalidate()
                    refreshTimer = nil
                }
                
                func collectMetrics() {
                    let cpu = Double.random(in: 10...95)
                    let memory = Double.random(in: 200...900)
                    let network = Double.random(in: 10...500)
                    let requests = Double.random(in: 50...200)
                    
                    let metric = SystemMetric(
                        timestamp: Date(),
                        cpu: cpu,
                        memory: memory,
                        network: network,
                        requests: requests
                    )
                    
                    metrics.append(metric)
                    
                    // Keep only recent metrics
                    let cutoff = Date().addingTimeInterval(-3600) // Last hour
                    metrics = metrics.filter { $0.timestamp >= cutoff }
                    
                    // Check for alerts
                    if cpu > 80 {
                        addAlert(severity: .critical, message: "CPU usage critical: \\(Int(cpu))%")
                    } else if cpu > 60 {
                        addAlert(severity: .warning, message: "CPU usage high: \\(Int(cpu))%")
                    }
                    
                    if memory > 800 {
                        addAlert(severity: .critical, message: "Memory usage critical: \\(Int(memory))MB")
                    }
                }
                
                func addAlert(severity: AlertSeverity, message: String) {
                    let alert = Alert(severity: severity, message: message, timestamp: Date())
                    alerts.insert(alert, at: 0)
                    
                    // Keep only last 10 alerts
                    if alerts.count > 10 {
                        alerts = Array(alerts.prefix(10))
                    }
                }
            }
            
            struct SystemMetric: Identifiable {
                let id = UUID()
                let timestamp: Date
                let cpu: Double
                let memory: Double
                let network: Double
                let requests: Double
            }
            
            struct Alert: Identifiable {
                let id = UUID()
                let severity: AlertSeverity
                let message: String
                let timestamp: Date
            }
            
            enum AlertSeverity {
                case info
                case warning
                case critical
                
                var color: Color {
                    switch self {
                    case .info: return .blue
                    case .warning: return .orange
                    case .critical: return .red
                    }
                }
                
                var icon: String {
                    switch self {
                    case .info: return "info.circle.fill"
                    case .warning: return "exclamationmark.triangle.fill"
                    case .critical: return "exclamationmark.octagon.fill"
                    }
                }
            }
            
            enum MetricStatus {
                case normal
                case warning
                case critical
                
                var color: Color {
                    switch self {
                    case .normal: return .green
                    case .warning: return .orange
                    case .critical: return .red
                    }
                }
            }
            
            enum TimeRange: String, CaseIterable {
                case last15Minutes = "Last 15 Minutes"
                case lastHour = "Last Hour"
                case last6Hours = "Last 6 Hours"
                case last24Hours = "Last 24 Hours"
                
                var cutoffDate: Date {
                    let now = Date()
                    switch self {
                    case .last15Minutes: return now.addingTimeInterval(-15 * 60)
                    case .lastHour: return now.addingTimeInterval(-60 * 60)
                    case .last6Hours: return now.addingTimeInterval(-6 * 60 * 60)
                    case .last24Hours: return now.addingTimeInterval(-24 * 60 * 60)
                    }
                }
            }
            
            struct StatusCard: View {
                let title: String
                let value: Double
                let unit: String
                let status: MetricStatus
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Circle()
                                .fill(status.color)
                                .frame(width: 8, height: 8)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.0f", value))
                                .font(.title2)
                                .bold()
                            Text(unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            
            struct AlertRow: View {
                let alert: Alert
                
                var body: some View {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: alert.severity.icon)
                            .foregroundStyle(alert.severity.color)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.message)
                                .font(.body)
                            Text(alert.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(alert.severity.color.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            """,
            features: ["Real-time Monitoring", "System Metrics", "Alert System", "Performance Charts"],
            dependencies: ["Charts"]
        )
    }
}

struct HubTemplateDefinition {
    let template: HubTemplate
    let category: HubCategory
    let sourceFiles: [String: String]  // [FileName: CodeString]
    let features: [String]
    let dependencies: [String]
    
    // Convenience initializer for single-file templates
    init(template: HubTemplate, category: HubCategory, sampleCode: String, features: [String], dependencies: [String]) {
        self.template = template
        self.category = category
        self.sourceFiles = ["main.swift": sampleCode]
        self.features = features
        self.dependencies = dependencies
    }
    
    // Full initializer for multi-file templates
    init(template: HubTemplate, category: HubCategory, sourceFiles: [String: String], features: [String], dependencies: [String]) {
        self.template = template
        self.category = category
        self.sourceFiles = sourceFiles
        self.features = features
        self.dependencies = dependencies
    }
}
