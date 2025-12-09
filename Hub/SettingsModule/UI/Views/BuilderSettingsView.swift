import SwiftUI
import SwiftData
// MARK: - Builder Settings View

public struct BuilderSettingsView: View {
    @StateObject var viewModel: BuilderSettingsViewModel
    
    public init(viewModel: BuilderSettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        Form {
            Section {
                // Optimization Level
                Picker("Optimization Level", selection: $viewModel.preferences.optimizationLevel) {
                    ForEach(BuilderPreferences.OptimizationLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading) {
                            Text(level.rawValue)
                            Text(level.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(level)
                    }
                }
                
                // Build Verbosity
                Picker("Build Output", selection: $viewModel.preferences.buildOutputVerbosity) {
                    ForEach(BuilderPreferences.BuildVerbosity.allCases, id: \.self) { verbosity in
                        Text(verbosity.rawValue).tag(verbosity)
                    }
                }
                
                // Custom Compiler Flags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Compiler Flags")
                        .font(.body)
                    TextField("e.g., -Xswiftc -warnings-as-errors", text: $viewModel.preferences.customCompilerFlags)
                        .textFieldStyle(.roundedBorder)
                    Text("Additional flags passed to the Swift compiler")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Compiler Settings")
            }
            
            Section {
                ToggleRowView(
                    title: "Enable Debug Symbols",
                    subtitle: "Include debugging information in builds",
                    isOn: $viewModel.preferences.enableDebugSymbols
                )
                
                ToggleRowView(
                    title: "Parallel Build",
                    subtitle: "Use multiple cores for faster compilation",
                    isOn: $viewModel.preferences.parallelBuild
                )
                
                ToggleRowView(
                    title: "Auto-Launch After Build",
                    subtitle: "Automatically launch app when build succeeds",
                    isOn: $viewModel.preferences.autoLaunchAfterBuild
                )
            } header: {
                Text("Build Options")
            }
            
            Section {
                ToggleRowView(
                    title: "Clear Cache on Build",
                    subtitle: "Remove old builds before starting new ones",
                    isOn: $viewModel.preferences.clearCacheOnBuild
                )
                
                // Cache Size Display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build Cache Size")
                            .font(.body)
                        Text(viewModel.cacheSizeFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.refreshCacheSize()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
                
                // Clear Cache Button
                Button(role: .destructive) {
                    Task {
                        await viewModel.clearCacheButtonTapped()
                    }
                } label: {
                    HStack {
                        if viewModel.isClearing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash")
                        }
                        Text(viewModel.isClearing ? "Clearing..." : "Clear Build Cache")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.isClearing)
            } header: {
                Text("Cache Management")
            } footer: {
                Text("Clearing the build cache will remove all previously built apps. This can free up disk space but will require rebuilding apps.")
            }
        }
        .formStyle(.grouped)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    let settingsManager = SettingsManager(modelContext: ModelContext(try! ModelContainer(for: AppSettings.self)))
    let viewModel = BuilderSettingsViewModel(
        preferences: BuilderPreferences(),
        settingsManager: settingsManager
    )
    
    return BuilderSettingsView(viewModel: viewModel)
        .frame(width: 600, height: 500)
}
