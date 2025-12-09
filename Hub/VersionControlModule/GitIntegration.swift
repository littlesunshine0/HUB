import Foundation

// MARK: - Git Integration
class GitIntegration {
    static let shared = GitIntegration()
    
    private var repositoryPath: String?
    
    func initialize(repositoryPath: String) {
        self.repositoryPath = repositoryPath
    }
    
    // MARK: - Repository Operations
    func initRepository() async throws {
        try await execute("git init")
    }
    
    func cloneRepository(url: String, destination: String) async throws {
        try await execute("git clone \(url) \(destination)")
    }
    
    func getStatus() async throws -> GitStatus {
        let output = try await execute("git status --porcelain")
        return parseStatus(output)
    }
    
    // MARK: - Branch Operations
    func getCurrentBranch() async throws -> String {
        try await execute("git branch --show-current")
    }
    
    func listBranches() async throws -> [GitBranch] {
        let output = try await execute("git branch -a")
        return parseBranches(output)
    }
    
    func createBranch(name: String) async throws {
        try await execute("git branch \(name)")
    }
    
    func switchBranch(name: String) async throws {
        try await execute("git checkout \(name)")
    }
    
    func deleteBranch(name: String, force: Bool = false) async throws {
        let flag = force ? "-D" : "-d"
        try await execute("git branch \(flag) \(name)")
    }
    
    func mergeBranch(name: String) async throws -> MergeResult {
        do {
            let output = try await execute("git merge \(name)")
            return MergeResult(success: true, conflicts: [], message: output)
        } catch {
            let conflicts = try await getConflicts()
            return MergeResult(success: false, conflicts: conflicts, message: error.localizedDescription)
        }
    }
    
    // MARK: - Commit Operations
    func stage(files: [String]) async throws {
        let fileList = files.joined(separator: " ")
        try await execute("git add \(fileList)")
    }
    
    func stageAll() async throws {
        try await execute("git add .")
    }
    
    func unstage(files: [String]) async throws {
        let fileList = files.joined(separator: " ")
        try await execute("git reset HEAD \(fileList)")
    }
    
    func commit(message: String) async throws -> String {
        try await execute("git commit -m \"\(message)\"")
    }
    
    func getCommitHistory(limit: Int = 50) async throws -> [GitCommit] {
        let output = try await execute("git log --pretty=format:'%H|%an|%ae|%at|%s' -n \(limit)")
        return parseCommits(output)
    }
    
    func getCommitDiff(commitHash: String) async throws -> String {
        try await execute("git show \(commitHash)")
    }
    
    // MARK: - Remote Operations
    func addRemote(name: String, url: String) async throws {
        try await execute("git remote add \(name) \(url)")
    }
    
    func listRemotes() async throws -> [GitRemote] {
        let output = try await execute("git remote -v")
        return parseRemotes(output)
    }
    
    func fetch(remote: String = "origin") async throws {
        try await execute("git fetch \(remote)")
    }
    
    func pull(remote: String = "origin", branch: String? = nil) async throws {
        if let branch = branch {
            try await execute("git pull \(remote) \(branch)")
        } else {
            try await execute("git pull \(remote)")
        }
    }
    
    func push(remote: String = "origin", branch: String? = nil, force: Bool = false) async throws {
        let forceFlag = force ? "--force" : ""
        if let branch = branch {
            try await execute("git push \(forceFlag) \(remote) \(branch)")
        } else {
            try await execute("git push \(forceFlag) \(remote)")
        }
    }
    
    // MARK: - Diff Operations
    func getDiff(file: String? = nil) async throws -> String {
        if let file = file {
            return try await execute("git diff \(file)")
        } else {
            return try await execute("git diff")
        }
    }
    
    func getStagedDiff() async throws -> String {
        try await execute("git diff --staged")
    }
    
    // MARK: - Stash Operations
    func stash(message: String? = nil) async throws {
        if let message = message {
            try await execute("git stash push -m \"\(message)\"")
        } else {
            try await execute("git stash")
        }
    }
    
    func stashPop() async throws {
        try await execute("git stash pop")
    }
    
    func listStashes() async throws -> [GitStash] {
        let output = try await execute("git stash list")
        return parseStashes(output)
    }
    
    // MARK: - Conflict Resolution
    func getConflicts() async throws -> [GitConflict] {
        let output = try await execute("git diff --name-only --diff-filter=U")
        let files = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        return try await files.asyncMap { file in
            let content = try await execute("cat \(file)")
            return GitConflict(file: file, content: content)
        }
    }
    
    func resolveConflict(file: String, resolution: ConflictResolution) async throws {
        switch resolution {
        case .ours:
            try await execute("git checkout --ours \(file)")
        case .theirs:
            try await execute("git checkout --theirs \(file)")
        case .manual(let content):
            try content.write(toFile: file, atomically: true, encoding: .utf8)
        }
        
        try await execute("git add \(file)")
    }
    
    // MARK: - Helper Methods
    private func execute(_ command: String) async throws -> String {
        guard let repoPath = repositoryPath else {
            throw GitError.noRepository
        }
        
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["sh", "-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        guard process.terminationStatus == 0 else {
            throw GitError.commandFailed(output)
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseStatus(_ output: String) -> GitStatus {
        let lines = output.components(separatedBy: "\n")
        var modified: [String] = []
        var added: [String] = []
        var deleted: [String] = []
        var untracked: [String] = []
        
        for line in lines {
            guard line.count >= 3 else { continue }
            let status = String(line.prefix(2))
            let file = String(line.dropFirst(3))
            
            switch status {
            case " M", "M ", "MM": modified.append(file)
            case "A ", "AM": added.append(file)
            case " D", "D ": deleted.append(file)
            case "??": untracked.append(file)
            default: break
            }
        }
        
        return GitStatus(modified: modified, added: added, deleted: deleted, untracked: untracked)
    }
    
    private func parseBranches(_ output: String) -> [GitBranch] {
        output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { line in
                let isCurrent = line.hasPrefix("*")
                let name = line.replacingOccurrences(of: "* ", with: "").replacingOccurrences(of: "  ", with: "")
                return GitBranch(name: name, isCurrent: isCurrent)
            }
    }
    
    private func parseCommits(_ output: String) -> [GitCommit] {
        output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line in
                let parts = line.components(separatedBy: "|")
                guard parts.count == 5 else { return nil }
                
                return GitCommit(
                    hash: parts[0],
                    author: parts[1],
                    email: parts[2],
                    timestamp: Date(timeIntervalSince1970: Double(parts[3]) ?? 0),
                    message: parts[4]
                )
            }
    }
    
    private func parseRemotes(_ output: String) -> [GitRemote] {
        let lines = output.components(separatedBy: "\n")
        var remotes: [String: GitRemote] = [:]
        
        for line in lines {
            let parts = line.components(separatedBy: "\t")
            guard parts.count == 2 else { continue }
            
            let name = parts[0]
            let urlPart = parts[1].components(separatedBy: " ")
            guard let url = urlPart.first else { continue }
            
            remotes[name] = GitRemote(name: name, url: url)
        }
        
        return Array(remotes.values)
    }
    
    private func parseStashes(_ output: String) -> [GitStash] {
        output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, line in
                GitStash(index: index, description: line)
            }
    }
}

// MARK: - Models
struct GitStatus {
    let modified: [String]
    let added: [String]
    let deleted: [String]
    let untracked: [String]
}

struct GitBranch: Identifiable {
    let id = UUID()
    let name: String
    let isCurrent: Bool
}

struct GitCommit: Identifiable {
    let id = UUID()
    let hash: String
    let author: String
    let email: String
    let timestamp: Date
    let message: String
}

struct GitRemote: Identifiable {
    let id = UUID()
    let name: String
    let url: String
}

struct GitStash: Identifiable {
    let id = UUID()
    let index: Int
    let description: String
}

struct GitConflict: Identifiable {
    let id = UUID()
    let file: String
    let content: String
}

struct MergeResult {
    let success: Bool
    let conflicts: [GitConflict]
    let message: String
}

enum ConflictResolution {
    case ours
    case theirs
    case manual(String)
}

enum GitError: Error {
    case noRepository
    case commandFailed(String)
}

// MARK: - Array Extension
extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }
}
