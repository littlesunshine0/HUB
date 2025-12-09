//
//  ToolExecutor.swift
//  Hub
//
//  AI Tool execution system for code generation, file operations, and more
//

import Foundation

// MARK: - Tool Executor

actor ToolExecutor {
    private var registeredTools: [String: AITool] = [:]
    private var executionHistory: [ToolExecution] = []
    
    var availableTools: [AITool] {
        Array(registeredTools.values)
    }
    
    init() {
        registerBuiltInTools()
    }
    
    private func registerBuiltInTools() {
        // File operations
        register(ReadFileTool())
        register(WriteFileTool())
        register(ListDirectoryTool())
        register(SearchFilesTool())
        
        // Code operations
        register(GenerateCodeTool())
        register(RefactorCodeTool())
        register(ExplainCodeTool())
        register(FindIssuesTool())
        
        // Shell operations
        register(RunCommandTool())
        
        // Search operations
        register(WebSearchTool())
        register(CodeSearchTool())
        
        // Hub-specific
        register(CreateHubTool())
        register(ListTemplatesTool())
        register(GenerateComponentTool())
    }
    
    func register(_ tool: AITool) {
        registeredTools[tool.name] = tool
    }
    
    func execute(_ call: ToolCall) async -> ToolResult {
        guard let tool = registeredTools[call.name] else {
            return ToolResult(
                toolCallId: call.id,
                success: false,
                output: "Tool not found: \(call.name)",
                error: "Unknown tool"
            )
        }
        
        let startTime = Date()
        
        do {
            let output = try await tool.execute(arguments: call.arguments)
            
            let execution = ToolExecution(
                toolName: call.name,
                arguments: call.arguments,
                output: output,
                success: true,
                duration: Date().timeIntervalSince(startTime)
            )
            executionHistory.append(execution)
            
            return ToolResult(
                toolCallId: call.id,
                success: true,
                output: output,
                error: nil
            )
        } catch {
            let execution = ToolExecution(
                toolName: call.name,
                arguments: call.arguments,
                output: nil,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error.localizedDescription
            )
            executionHistory.append(execution)
            
            return ToolResult(
                toolCallId: call.id,
                success: false,
                output: nil,
                error: error.localizedDescription
            )
        }
    }
    
    func getHistory(limit: Int = 50) -> [ToolExecution] {
        Array(executionHistory.suffix(limit))
    }
}

// MARK: - AI Tool Protocol

protocol AITool {
    var name: String { get }
    var description: String { get }
    var parameters: [ToolParameter] { get }
    
    func execute(arguments: [String: Any]) async throws -> String
}

// ToolParameter is defined in AISharedTypes.swift

// MARK: - Built-in Tools

struct ReadFileTool: AITool {
    let name = "read_file"
    let description = "Read the contents of a file at the specified path"
    let parameters = [
        ToolParameter(name: "path", type: "string", description: "Path to the file", required: true, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["path"] as? String else {
            throw ToolError.missingParameter("path")
        }
        
        let url = URL(fileURLWithPath: path)
        return try String(contentsOf: url, encoding: .utf8)
    }
}

struct WriteFileTool: AITool {
    let name = "write_file"
    let description = "Write content to a file at the specified path"
    let parameters = [
        ToolParameter(name: "path", type: "string", description: "Path to the file", required: true, enumValues: nil),
        ToolParameter(name: "content", type: "string", description: "Content to write", required: true, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["path"] as? String,
              let content = arguments["content"] as? String else {
            throw ToolError.missingParameter("path or content")
        }
        
        let url = URL(fileURLWithPath: path)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return "Successfully wrote \(content.count) characters to \(path)"
    }
}

struct ListDirectoryTool: AITool {
    let name = "list_directory"
    let description = "List files and directories at the specified path"
    let parameters = [
        ToolParameter(name: "path", type: "string", description: "Directory path", required: true, enumValues: nil),
        ToolParameter(name: "recursive", type: "boolean", description: "List recursively", required: false, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["path"] as? String else {
            throw ToolError.missingParameter("path")
        }
        
        let recursive = arguments["recursive"] as? Bool ?? false
        let fm = FileManager.default
        
        var items: [String] = []
        
        if recursive {
            if let enumerator = fm.enumerator(atPath: path) {
                while let item = enumerator.nextObject() as? String {
                    items.append(item)
                }
            }
        } else {
            items = try fm.contentsOfDirectory(atPath: path)
        }
        
        return items.joined(separator: "\n")
    }
}

struct SearchFilesTool: AITool {
    let name = "search_files"
    let description = "Search for files matching a pattern"
    let parameters = [
        ToolParameter(name: "path", type: "string", description: "Base directory", required: true, enumValues: nil),
        ToolParameter(name: "pattern", type: "string", description: "Search pattern (glob or regex)", required: true, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["path"] as? String,
              let pattern = arguments["pattern"] as? String else {
            throw ToolError.missingParameter("path or pattern")
        }
        
        let fm = FileManager.default
        var matches: [String] = []
        
        if let enumerator = fm.enumerator(atPath: path) {
            while let item = enumerator.nextObject() as? String {
                if item.contains(pattern) || item.hasSuffix(pattern) {
                    matches.append(item)
                }
            }
        }
        
        return matches.isEmpty ? "No files found" : matches.joined(separator: "\n")
    }
}

struct GenerateCodeTool: AITool {
    let name = "generate_code"
    let description = "Generate code based on a description"
    let parameters = [
        ToolParameter(name: "description", type: "string", description: "What to generate", required: true, enumValues: nil),
        ToolParameter(name: "language", type: "string", description: "Programming language", required: true, enumValues: ["swift", "typescript", "python", "javascript"]),
        ToolParameter(name: "framework", type: "string", description: "Framework to use", required: false, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let description = arguments["description"] as? String,
              let language = arguments["language"] as? String else {
            throw ToolError.missingParameter("description or language")
        }
        
        // This would integrate with the LLM for actual generation
        // For now, return a template
        
        switch language {
        case "swift":
            return """
            // Generated code for: \(description)
            import SwiftUI
            
            struct GeneratedView: View {
                var body: some View {
                    VStack {
                        Text("Generated Content")
                    }
                }
            }
            """
        case "typescript", "javascript":
            return """
            // Generated code for: \(description)
            export function generatedFunction() {
                return {
                    message: "Generated Content"
                };
            }
            """
        case "python":
            return """
            # Generated code for: \(description)
            def generated_function():
                return {"message": "Generated Content"}
            """
        default:
            return "// Generated code for: \(description)"
        }
    }
}

struct RefactorCodeTool: AITool {
    let name = "refactor_code"
    let description = "Refactor code to improve quality"
    let parameters = [
        ToolParameter(name: "code", type: "string", description: "Code to refactor", required: true, enumValues: nil),
        ToolParameter(name: "style", type: "string", description: "Refactoring style", required: false, enumValues: ["clean", "performant", "readable", "testable"])
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let code = arguments["code"] as? String else {
            throw ToolError.missingParameter("code")
        }
        
        let style = arguments["style"] as? String ?? "clean"
        
        // Would integrate with LLM for actual refactoring
        return "// Refactored (\(style)):\n\(code)"
    }
}

struct ExplainCodeTool: AITool {
    let name = "explain_code"
    let description = "Explain what code does"
    let parameters = [
        ToolParameter(name: "code", type: "string", description: "Code to explain", required: true, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let code = arguments["code"] as? String else {
            throw ToolError.missingParameter("code")
        }
        
        // Would integrate with LLM for actual explanation
        return "This code contains \(code.components(separatedBy: "\n").count) lines and appears to be a function or class definition."
    }
}

struct FindIssuesTool: AITool {
    let name = "find_issues"
    let description = "Find potential issues in code"
    let parameters = [
        ToolParameter(name: "code", type: "string", description: "Code to analyze", required: true, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let code = arguments["code"] as? String else {
            throw ToolError.missingParameter("code")
        }
        
        var issues: [String] = []
        
        if code.contains("!") { issues.append("Force unwrapping detected") }
        if code.contains("try!") { issues.append("Force try detected") }
        if code.contains("var ") && !code.contains("let ") { issues.append("Consider using let for immutable values") }
        if code.count > 1000 { issues.append("File may be too long, consider splitting") }
        
        return issues.isEmpty ? "No issues found" : issues.joined(separator: "\n")
    }
}

struct RunCommandTool: AITool {
    let name = "run_command"
    let description = "Run a shell command"
    let parameters = [
        ToolParameter(name: "command", type: "string", description: "Command to run", required: true, enumValues: nil),
        ToolParameter(name: "workingDirectory", type: "string", description: "Working directory", required: false, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let command = arguments["command"] as? String else {
            throw ToolError.missingParameter("command")
        }
        
        // Security: Only allow safe commands
        let allowedCommands = ["ls", "cat", "echo", "pwd", "swift", "xcodebuild", "git"]
        let firstWord = command.split(separator: " ").first.map(String.init) ?? ""
        
        guard allowedCommands.contains(firstWord) else {
            throw ToolError.commandNotAllowed(command)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        if let workingDir = arguments["workingDirectory"] as? String {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

struct WebSearchTool: AITool {
    let name = "web_search"
    let description = "Search the web for information"
    let parameters = [
        ToolParameter(name: "query", type: "string", description: "Search query", required: true, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let query = arguments["query"] as? String else {
            throw ToolError.missingParameter("query")
        }
        
        // Would integrate with search API
        return "Search results for: \(query)\n(Web search integration pending)"
    }
}

struct CodeSearchTool: AITool {
    let name = "code_search"
    let description = "Search codebase for patterns"
    let parameters = [
        ToolParameter(name: "pattern", type: "string", description: "Search pattern", required: true, enumValues: nil),
        ToolParameter(name: "path", type: "string", description: "Base path", required: false, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let pattern = arguments["pattern"] as? String else {
            throw ToolError.missingParameter("pattern")
        }
        
        let basePath = arguments["path"] as? String ?? "."
        
        // Use grep-like search
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/grep")
        process.arguments = ["-r", "-n", pattern, basePath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.isEmpty ? "No matches found" : output
    }
}

struct CreateHubTool: AITool {
    let name = "create_hub"
    let description = "Create a new Hub from a template"
    let parameters = [
        ToolParameter(name: "name", type: "string", description: "Hub name", required: true, enumValues: nil),
        ToolParameter(name: "template", type: "string", description: "Template to use", required: false, enumValues: nil),
        ToolParameter(name: "description", type: "string", description: "Hub description", required: false, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let name = arguments["name"] as? String else {
            throw ToolError.missingParameter("name")
        }
        
        let template = arguments["template"] as? String ?? "blank"
        let description = arguments["description"] as? String ?? ""
        
        return "Created Hub '\(name)' from template '\(template)'\nDescription: \(description)"
    }
}

struct ListTemplatesTool: AITool {
    let name = "list_templates"
    let description = "List available Hub templates"
    let parameters: [ToolParameter] = []
    
    func execute(arguments: [String: Any]) async throws -> String {
        return """
        Available Templates:
        - blank: Empty Hub
        - dashboard: Analytics dashboard
        - portfolio: Portfolio showcase
        - blog: Blog/content site
        - ecommerce: E-commerce store
        - saas: SaaS application
        - mobile: Mobile app template
        """
    }
}

struct GenerateComponentTool: AITool {
    let name = "generate_component"
    let description = "Generate a UI component"
    let parameters = [
        ToolParameter(name: "type", type: "string", description: "Component type", required: true, enumValues: ["button", "card", "form", "list", "modal", "navigation"]),
        ToolParameter(name: "name", type: "string", description: "Component name", required: true, enumValues: nil),
        ToolParameter(name: "props", type: "object", description: "Component properties", required: false, enumValues: nil)
    ]
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let type = arguments["type"] as? String,
              let name = arguments["name"] as? String else {
            throw ToolError.missingParameter("type or name")
        }
        
        return """
        // Generated \(type) component: \(name)
        struct \(name): View {
            var body: some View {
                // \(type) implementation
                Text("\(name)")
            }
        }
        """
    }
}

// MARK: - Tool Errors

enum ToolError: LocalizedError {
    case missingParameter(String)
    case invalidParameter(String)
    case executionFailed(String)
    case commandNotAllowed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingParameter(let param): return "Missing required parameter: \(param)"
        case .invalidParameter(let param): return "Invalid parameter: \(param)"
        case .executionFailed(let reason): return "Execution failed: \(reason)"
        case .commandNotAllowed(let cmd): return "Command not allowed: \(cmd)"
        }
    }
}

// MARK: - Tool Execution Record

struct ToolExecution {
    let toolName: String
    let arguments: [String: Any]
    let output: String?
    let success: Bool
    let duration: TimeInterval
    var error: String?
}
