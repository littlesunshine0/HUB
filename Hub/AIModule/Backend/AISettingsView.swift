//
//  AISettingsView.swift
//  Hub
//
//  Settings UI for AI backend configuration
//

import SwiftUI
import Combine

struct AISettingsView: View {
    @StateObject private var viewModel = AISettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Provider Selection
            Section("AI Provider") {
                Picker("Provider", selection: $viewModel.selectedProvider) {
                    ForEach(AIBackendConfig.AIProviderType.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                
                providerDescription
            }
            
            // API Configuration
            Section("API Configuration") {
                if viewModel.requiresAPIKey {
                    SecureField("API Key", text: $viewModel.apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    if !viewModel.apiKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API key configured")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if viewModel.selectedProvider == .ollama {
                    TextField("Base URL", text: $viewModel.baseURL)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Test Connection") {
                        Task { await viewModel.testOllamaConnection() }
                    }
                    .disabled(viewModel.isTesting)
                    
                    if let status = viewModel.connectionStatus {
                        HStack {
                            Image(systemName: status.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(status.success ? .green : .red)
                            Text(status.message)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Model Selection
            Section("Model") {
                if viewModel.selectedProvider == .ollama {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    
                    Button("Refresh Models") {
                        Task { await viewModel.fetchOllamaModels() }
                    }
                } else {
                    TextField("Model", text: $viewModel.selectedModel)
                        .textFieldStyle(.roundedBorder)
                    
                    Text(viewModel.modelSuggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Generation Settings
            Section("Generation Settings") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.temperature))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $viewModel.temperature, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Max Tokens")
                        Spacer()
                        Text("\(viewModel.maxTokens)")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.maxTokens) },
                        set: { viewModel.maxTokens = Int($0) }
                    ), in: 256...8192, step: 256)
                }
            }
            
            // Features
            Section("Features") {
                Toggle("Enable RAG (Retrieval)", isOn: $viewModel.enableRAG)
                Toggle("Enable Tool Use", isOn: $viewModel.enableTools)
                Toggle("Enable Streaming", isOn: $viewModel.enableStreaming)
            }
            
            // RAG Settings
            if viewModel.enableRAG {
                Section("RAG Configuration") {
                    VStack(alignment: .leading) {
                        Text("Indexed Documents: \(viewModel.indexedDocCount)")
                            .font(.caption)
                        Text("Vector Store Size: \(viewModel.vectorStoreSize)")
                            .font(.caption)
                    }
                    
                    Button("Index Current Project") {
                        Task { await viewModel.indexProject() }
                    }
                    .disabled(viewModel.isIndexing)
                    
                    if viewModel.isIndexing {
                        ProgressView("Indexing...")
                    }
                    
                    Button("Clear Index", role: .destructive) {
                        Task { await viewModel.clearIndex() }
                    }
                }
            }
            
            // Usage Stats
            Section("Usage Statistics") {
                LabeledContent("Tokens Used Today", value: "\(viewModel.tokensUsedToday)")
                LabeledContent("Requests Today", value: "\(viewModel.requestsToday)")
                LabeledContent("Average Response Time", value: viewModel.avgResponseTime)
            }
            
            // Actions
            Section {
                Button("Save Configuration") {
                    viewModel.saveConfiguration()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset to Defaults", role: .destructive) {
                    viewModel.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("AI Settings")
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            viewModel.loadConfiguration()
        }
    }
    
    @ViewBuilder
    private var providerDescription: some View {
        switch viewModel.selectedProvider {
        case .openAI:
            Text("Use OpenAI's GPT models. Requires API key.")
                .font(.caption)
                .foregroundColor(.secondary)
        case .anthropic:
            Text("Use Anthropic's Claude models. Requires API key.")
                .font(.caption)
                .foregroundColor(.secondary)
        case .ollama:
            Text("Use local models via Ollama. Free and private.")
                .font(.caption)
                .foregroundColor(.secondary)
        case .local:
            Text("On-device inference. No internet required.")
                .font(.caption)
                .foregroundColor(.secondary)
        case .bedrock:
            Text("AWS Bedrock. Requires AWS credentials.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - View Model

@MainActor
final class AISettingsViewModel: ObservableObject {
    @Published var selectedProvider: AIBackendConfig.AIProviderType = .local
    @Published var apiKey: String = ""
    @Published var baseURL: String = "http://localhost:11434"
    @Published var selectedModel: String = "gpt-4"
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 4096
    @Published var enableRAG: Bool = true
    @Published var enableTools: Bool = true
    @Published var enableStreaming: Bool = true
    
    @Published var availableModels: [String] = []
    @Published var connectionStatus: ConnectionStatus?
    @Published var isTesting: Bool = false
    @Published var isIndexing: Bool = false
    
    @Published var indexedDocCount: Int = 0
    @Published var vectorStoreSize: String = "0 KB"
    @Published var tokensUsedToday: Int = 0
    @Published var requestsToday: Int = 0
    @Published var avgResponseTime: String = "0ms"
    
    private let backend = AIBackendService.shared
    
    var requiresAPIKey: Bool {
        selectedProvider == .openAI || selectedProvider == .anthropic || selectedProvider == .bedrock
    }
    
    var modelSuggestion: String {
        switch selectedProvider {
        case .openAI: return "Suggested: gpt-4, gpt-4-turbo, gpt-3.5-turbo"
        case .anthropic: return "Suggested: claude-3-5-sonnet-20241022, claude-3-opus-20240229"
        case .ollama: return "Select from available models"
        case .local: return "Using on-device model"
        case .bedrock: return "Suggested: anthropic.claude-3-sonnet, amazon.titan-text"
        }
    }
    
    struct ConnectionStatus {
        let success: Bool
        let message: String
    }
    
    func loadConfiguration() {
        let config = backend.config
        selectedProvider = config.provider
        apiKey = config.apiKey ?? ""
        baseURL = config.baseURL ?? "http://localhost:11434"
        selectedModel = config.model
        temperature = config.temperature
        maxTokens = config.maxTokens
        enableRAG = config.enableRAG
        enableTools = config.enableTools
        enableStreaming = config.enableStreaming
        
        tokensUsedToday = backend.tokensUsed
        
        if selectedProvider == .ollama {
            Task { await fetchOllamaModels() }
        }
    }
    
    func saveConfiguration() {
        var config = AIBackendConfig()
        config.provider = selectedProvider
        config.apiKey = apiKey.isEmpty ? nil : apiKey
        config.baseURL = baseURL
        config.model = selectedModel
        config.temperature = temperature
        config.maxTokens = maxTokens
        config.enableRAG = enableRAG
        config.enableTools = enableTools
        config.enableStreaming = enableStreaming
        
        backend.config = config
        
        // Persist to UserDefaults
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "ai_provider")
        UserDefaults.standard.set(selectedModel, forKey: "ai_model")
        UserDefaults.standard.set(temperature, forKey: "ai_temperature")
        UserDefaults.standard.set(maxTokens, forKey: "ai_max_tokens")
        
        if !apiKey.isEmpty {
            // In production, use Keychain
            UserDefaults.standard.set(apiKey, forKey: "ai_api_key")
        }
    }
    
    func resetToDefaults() {
        selectedProvider = .local
        apiKey = ""
        baseURL = "http://localhost:11434"
        selectedModel = "gpt-4"
        temperature = 0.7
        maxTokens = 4096
        enableRAG = true
        enableTools = true
        enableStreaming = true
    }
    
    func testOllamaConnection() async {
        isTesting = true
        defer { isTesting = false }
        
        do {
            let url = URL(string: "\(baseURL)/api/tags")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                connectionStatus = ConnectionStatus(success: true, message: "Connected to Ollama")
                await fetchOllamaModels()
            } else {
                connectionStatus = ConnectionStatus(success: false, message: "Ollama not responding")
            }
        } catch {
            connectionStatus = ConnectionStatus(success: false, message: "Connection failed: \(error.localizedDescription)")
        }
    }
    
    func fetchOllamaModels() async {
        do {
            let provider = OllamaProvider()
            availableModels = try await provider.listModels()
            if !availableModels.isEmpty && !availableModels.contains(selectedModel) {
                selectedModel = availableModels[0]
            }
        } catch {
            availableModels = ["llama3.2", "codellama", "mistral", "phi3"]
        }
    }
    
    func indexProject() async {
        isIndexing = true
        defer { isIndexing = false }
        
        // Would get project path from workspace
        let projectPath = FileManager.default.currentDirectoryPath
        
        do {
            let ragEngine = RAGEngine()
            try await ragEngine.indexCodebase(at: projectPath)
            let stats = await ragEngine.stats()
            indexedDocCount = stats.documentCount
            vectorStoreSize = formatBytes(stats.indexSize)
        } catch {
            print("Indexing failed: \(error)")
        }
    }
    
    func clearIndex() async {
        let ragEngine = RAGEngine()
        await ragEngine.clear()
        indexedDocCount = 0
        vectorStoreSize = "0 KB"
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview

#Preview {
    AISettingsView()
}
