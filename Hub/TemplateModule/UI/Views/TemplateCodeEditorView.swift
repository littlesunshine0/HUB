import SwiftUI

/// Code editor with live preview for templates
struct TemplateCodeEditorView: View {
    let template: TemplateModel
    let templateManager: TemplateManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFile: String?
    @State private var editedCode: String = ""
    @State private var showingPreview = true
    @State private var previewMode: PreviewMode = .live
    @State private var hasChanges = false
    
    enum PreviewMode: String, CaseIterable {
        case live = "Live"
        case split = "Split"
        case code = "Code Only"
    }
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // Left: File list
                fileListView
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                
                // Center: Code editor
                codeEditorView
                    .frame(minWidth: 400)
                
                // Right: Live preview (optional)
                if showingPreview && previewMode != .code {
                    livePreviewView
                        .frame(minWidth: 300, idealWidth: 400)
                }
            }
            .navigationTitle("Edit Code: \(template.name)")
            .toolbar {
                toolbarContent
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            if let firstFile = template.sourceFiles.keys.sorted().first {
                selectedFile = firstFile
                editedCode = template.sourceFiles[firstFile] ?? ""
            }
        }
    }
    
    // MARK: - File List
    
    private var fileListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Files")
                    .font(.headline)
                Spacer()
                Button {
                    addNewFile()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // File list
            List(selection: $selectedFile) {
                ForEach(Array(template.sourceFiles.keys.sorted()), id: \.self) { filename in
                    HStack {
                        Image(systemName: fileIcon(for: filename))
                            .foregroundStyle(fileColor(for: filename))
                        Text(filename)
                            .font(.body)
                        Spacer()
                        if hasUnsavedChanges(for: filename) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectFile(filename)
                    }
                    .contextMenu {
                        Button("Rename") {
                            renameFile(filename)
                        }
                        Button("Duplicate") {
                            duplicateFile(filename)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteFile(filename)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
    
    // MARK: - Code Editor
    
    private var codeEditorView: some View {
        VStack(spacing: 0) {
            // Editor header
            HStack {
                if let filename = selectedFile {
                    HStack(spacing: 8) {
                        Image(systemName: fileIcon(for: filename))
                            .foregroundStyle(fileColor(for: filename))
                        Text(filename)
                            .font(.headline)
                        if hasChanges {
                            Text("• Edited")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    Text("No file selected")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Preview mode picker
                Picker("Preview", selection: $previewMode) {
                    ForEach(PreviewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Code editor
            if selectedFile != nil {
                TextEditor(text: $editedCode)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .onChange(of: editedCode) { _, _ in
                        hasChanges = true
                    }
            } else {
                ContentUnavailableView(
                    "No File Selected",
                    systemImage: "doc.text",
                    description: Text("Select a file from the list to edit")
                )
            }
        }
    }
    
    // MARK: - Live Preview
    
    private var livePreviewView: some View {
        VStack(spacing: 0) {
            // Preview header
            HStack {
                Text("Live Preview")
                    .font(.headline)
                Spacer()
                Button {
                    refreshPreview()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Preview content
            ScrollView {
                if template.isVisualTemplate && !template.visualScreens.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(template.visualScreens) { screen in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(screen.name)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Text("Visual preview: \(screen.components.count) components")
                                    .frame(height: 400)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "eye.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Live preview not available")
                            .foregroundStyle(.secondary)
                        Text("Code-based templates require compilation to preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                showingPreview.toggle()
            } label: {
                Label("Preview", systemImage: showingPreview ? "sidebar.right" : "sidebar.left")
            }
            
            Divider()
            
            Button {
                revertChanges()
            } label: {
                Label("Revert", systemImage: "arrow.uturn.backward")
            }
            .disabled(!hasChanges)
            
            Button {
                saveChanges()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!hasChanges)
            .keyboardShortcut("s", modifiers: .command)
            
            Divider()
            
            Button("Done") {
                if hasChanges {
                    saveChanges()
                }
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectFile(_ filename: String) {
        // Save current file if needed
        if hasChanges, let currentFile = selectedFile {
            saveFileChanges(currentFile)
        }
        
        selectedFile = filename
        editedCode = template.sourceFiles[filename] ?? ""
        hasChanges = false
    }
    
    private func saveFileChanges(_ filename: String) {
        var files = template.sourceFiles
        files[filename] = editedCode
        template.sourceFiles = files
    }
    
    private func saveChanges() {
        if let filename = selectedFile {
            saveFileChanges(filename)
        }
        templateManager.updateTemplate(template)
        hasChanges = false
    }
    
    private func revertChanges() {
        if let filename = selectedFile {
            editedCode = template.sourceFiles[filename] ?? ""
        }
        hasChanges = false
    }
    
    private func refreshPreview() {
        // Trigger preview refresh
        if hasChanges {
            saveChanges()
        }
    }
    
    private func addNewFile() {
        let filename = "NewFile.swift"
        var files = template.sourceFiles
        files[filename] = "// New file\n"
        template.sourceFiles = files
        selectedFile = filename
        editedCode = files[filename] ?? ""
    }
    
    private func renameFile(_ filename: String) {
        // TODO: Implement rename dialog
    }
    
    private func duplicateFile(_ filename: String) {
        if let content = template.sourceFiles[filename] {
            let newName = "Copy of \(filename)"
            var files = template.sourceFiles
            files[newName] = content
            template.sourceFiles = files
        }
    }
    
    private func deleteFile(_ filename: String) {
        var files = template.sourceFiles
        files.removeValue(forKey: filename)
        template.sourceFiles = files
        if selectedFile == filename {
            selectedFile = files.keys.sorted().first
            editedCode = selectedFile.map { files[$0] ?? "" } ?? ""
        }
    }
    
    private func hasUnsavedChanges(for filename: String) -> Bool {
        return selectedFile == filename && hasChanges
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "json": return "curlybraces"
        case "md": return "doc.text"
        case "txt": return "doc.plaintext"
        default: return "doc"
        }
    }
    
    private func fileColor(for filename: String) -> Color {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return .orange
        case "json": return .green
        case "md": return .blue
        default: return .gray
        }
    }
}

// Preview removed - requires model context
