import SwiftUI
import Combine

// MARK: - Git Integration View
struct GitIntegrationView: View {
    @StateObject private var viewModel = GitIntegrationViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section("Status") {
                    if let status = viewModel.status {
                        StatusRow(title: "Modified", count: status.modified.count, color: .orange)
                        StatusRow(title: "Added", count: status.added.count, color: .green)
                        StatusRow(title: "Deleted", count: status.deleted.count, color: .red)
                        StatusRow(title: "Untracked", count: status.untracked.count, color: .gray)
                    }
                }
                
                Section("Branches") {
                    ForEach(viewModel.branches) { branch in
                        HStack {
                            if branch.isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            Text(branch.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.switchBranch(branch.name)
                        }
                    }
                }
                
                Section("Recent Commits") {
                    ForEach(viewModel.commits.prefix(10)) { commit in
                        VStack(alignment: .leading) {
                            Text(commit.message)
                                .font(.headline)
                            Text("\(commit.author) • \(commit.timestamp, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Version Control")
            .toolbar {
                ToolbarItemGroup {
                    Button("Commit") { viewModel.showCommitSheet = true }
                    Button("Push") { viewModel.push() }
                    Button("Pull") { viewModel.pull() }
                }
            }
            .sheet(isPresented: $viewModel.showCommitSheet) {
                CommitView(onCommit: viewModel.commit)
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

struct StatusRow: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
}

struct CommitView: View {
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    let onCommit: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Commit message", text: $message, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Commit Changes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Commit") {
                        onCommit(message)
                        dismiss()
                    }
                    .disabled(message.isEmpty)
                }
            }
        }
    }
}

@MainActor
class GitIntegrationViewModel: ObservableObject {
    @Published var status: GitStatus?
    @Published var branches: [GitBranch] = []
    @Published var commits: [GitCommit] = []
    @Published var showCommitSheet = false
    
    private let git = GitIntegration.shared
    
    func loadData() async {
        do {
            status = try await git.getStatus()
            branches = try await git.listBranches()
            commits = try await git.getCommitHistory()
        } catch {
            print("Error loading git data: \(error)")
        }
    }
    
    func switchBranch(_ name: String) {
        Task {
            try? await git.switchBranch(name: name)
            await loadData()
        }
    }
    
    func commit(_ message: String) {
        Task {
            try? await git.stageAll()
            try? await git.commit(message: message)
            await loadData()
        }
    }
    
    func push() {
        Task {
            try? await git.push()
        }
    }
    
    func pull() {
        Task {
            try? await git.pull()
            await loadData()
        }
    }
}
