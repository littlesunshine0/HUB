import SwiftUI
import SwiftData

// MARK: - Editor Settings View

public struct EditorSettingsView: View {
    @StateObject var viewModel: EditorSettingsViewModel
    
    public init(viewModel: EditorSettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        Form {
            Section {
                // Font Size
                HStack {
                    Text("Font Size")
                    Spacer()
                    Stepper(
                        "\(Int(viewModel.preferences.defaultFontSize))pt",
                        value: $viewModel.preferences.defaultFontSize,
                        in: 10...24,
                        step: 1
                    )
                }
                
                ToggleRowView(
                    title: "Show Line Numbers",
                    subtitle: "Display line numbers in code editor",
                    isOn: $viewModel.preferences.showLineNumbers
                )
                
                ToggleRowView(
                    title: "Syntax Highlighting",
                    subtitle: "Colorize code based on syntax",
                    isOn: $viewModel.preferences.syntaxHighlighting
                )
                
                ToggleRowView(
                    title: "Code Completion",
                    subtitle: "Show suggestions while typing",
                    isOn: $viewModel.preferences.codeCompletion
                )
                
                ToggleRowView(
                    title: "Show Minimap",
                    subtitle: "Display code overview minimap",
                    isOn: $viewModel.preferences.showMinimap
                )
            } header: {
                Text("Editor Appearance")
            }
            
            Section {
                ToggleRowView(
                    title: "Default Panel Visibility",
                    subtitle: "Show component palette by default",
                    isOn: $viewModel.preferences.defaultPanelVisibility
                )
            } header: {
                Text("Layout")
            }
            
            Section {
                ToggleRowView(
                    title: "Auto-Save",
                    subtitle: "Automatically save changes",
                    isOn: $viewModel.preferences.autoSave
                )
                
                if viewModel.preferences.autoSave {
                    HStack {
                        Text("Auto-Save Interval")
                        Spacer()
                        Stepper(
                            "\(Int(viewModel.preferences.autoSaveInterval))s",
                            value: $viewModel.preferences.autoSaveInterval,
                            in: 10...120,
                            step: 10
                        )
                    }
                }
            } header: {
                Text("Saving")
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
    let viewModel = EditorSettingsViewModel(
        preferences: EditorPreferences(),
        settingsManager: settingsManager
    )
    
    return EditorSettingsView(viewModel: viewModel)
        .frame(width: 600, height: 500)
}
