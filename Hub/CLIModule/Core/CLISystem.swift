//
//  CLISystem.swift
//  Hub
//
//  Command-Line Interface system for professional users
//

import Foundation
import Combine

// MARK: - CLI Manager

@MainActor
public class CLIManager: ObservableObject {
    public static let shared = CLIManager()
    
    @Published public var isEnabled = true
    @Published public var currentDirectory: String = "~"
    @Published public var commandHistory: [CLICommand] = []
    @Published public var output: [CLIOutput] = []
    @Published public var environment: [String: String] = [:]
    
    private var commands: [String: CLICommandHandler] = [:]
    private var aliases: [String: String] = [:]
    private let maxHistoryCount = 1000
    private let maxOutputCount = 500
    
    private init() {
        setupDefaultEnvironment()
        registerBuiltInCommands()
    }
    
    // MARK: - Command Execution
    
    public func execute(_ input: String) async -> CLIResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return CLIResult(success: true, output: "", error: nil)
        }
        
        // Parse command
        let parsed = parseCommand(trimmed)
        
        // Add to history
        let command = CLICommand(
            input: trimmed,
            name: parsed.name,
            arguments: parsed.arguments,
            timestamp: Date()
        )
        addToHistory(command)
        
        // Resolve aliases
        let commandName = aliases[parsed.name] ?? parsed.name
        
        // Execute command
        guard let handler = commands[commandName] else {
            let error = "hub: command not found: \(parsed.name)"
            addOutput(CLIOutput(text: error, type: .error))
            return CLIResult(success: false, output: "", error: error)
        }
        
        do {
            let result = try await handler.execute(
                arguments: parsed.arguments,
                options: parsed.options,
                context: CLIContext(
                    currentDirectory: currentDirectory,
                    environment: environment
                )
            )
            
            if !result.output.isEmpty {
                addOutput(CLIOutput(text: result.output, type: .standard))
            }
            
            return result
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            addOutput(CLIOutput(text: errorMessage, type: .error))
            return CLIResult(success: false, output: "", error: errorMessage)
        }
    }
    
    // MARK: - Command Registration
    
    public func register(command: CLICommandHandler) {
        commands[command.name] = command
    }
    
    public func unregister(commandName: String) {
        commands.removeValue(forKey: commandName)
    }
    
    public func registerAlias(_ alias: String, for command: String) {
        aliases[alias] = command
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ command: CLICommand) {
        commandHistory.insert(command, at: 0)
        if commandHistory.count > maxHistoryCount {
            commandHistory.removeLast()
        }
    }
    
    public func clearHistory() {
        commandHistory.removeAll()
    }
    
    public func searchHistory(_ query: String) -> [CLICommand] {
        commandHistory.filter { $0.input.contains(query) }
    }
    
    // MARK: - Output Management
    
    private func addOutput(_ output: CLIOutput) {
        self.output.append(output)
        if self.output.count > maxOutputCount {
            self.output.removeFirst()
        }
    }
    
    public func clearOutput() {
        output.removeAll()
    }
    
    // MARK: - Environment
    
    private func setupDefaultEnvironment() {
        environment["USER"] = NSUserName()
        environment["HOME"] = NSHomeDirectory()
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin"
        environment["SHELL"] = "/bin/zsh"
    }
    
    public func setEnvironmentVariable(_ key: String, value: String) {
        environment[key] = value
    }
    
    // MARK: - Command Parsing
    
    private func parseCommand(_ input: String) -> ParsedCommand {
        var components = input.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        
        guard !components.isEmpty else {
            return ParsedCommand(name: "", arguments: [], options: [:])
        }
        
        let name = components.removeFirst()
        var arguments: [String] = []
        var options: [String: String] = [:]
        
        var i = 0
        while i < components.count {
            let component = components[i]
            
            if component.hasPrefix("--") {
                // Long option
                let option = String(component.dropFirst(2))
                if i + 1 < components.count && !components[i + 1].hasPrefix("-") {
                    options[option] = components[i + 1]
                    i += 2
                } else {
                    options[option] = "true"
                    i += 1
                }
            } else if component.hasPrefix("-") {
                // Short option
                let option = String(component.dropFirst())
                if i + 1 < components.count && !components[i + 1].hasPrefix("-") {
                    options[option] = components[i + 1]
                    i += 2
                } else {
                    options[option] = "true"
                    i += 1
                }
            } else {
                // Argument
                arguments.append(component)
                i += 1
            }
        }
        
        return ParsedCommand(name: name, arguments: arguments, options: options)
    }
    
    // MARK: - Built-in Commands
    
    private func registerBuiltInCommands() {
        register(command: CLIHelpCommand())
        register(command: CLIListCommand())
        register(command: CLICreateCommand())
        register(command: CLIDeleteCommand())
        register(command: CLISearchCommand())
        register(command: CLIInfoCommand())
        register(command: CLIClearCommand())
        register(command: CLIHistoryCommand())
        register(command: CLIAliasCommand())
        register(command: CLIExportCommand())
        register(command: CLIConfigCommand())
        
        // Register common aliases
        registerAlias("ls", for: "list")
        registerAlias("rm", for: "delete")
        registerAlias("mk", for: "create")
    }
}

// MARK: - CLI Models

public struct CLICommand {
    public let id = UUID()
    public let input: String
    public let name: String
    public let arguments: [String]
    public let timestamp: Date
    
    public init(input: String, name: String, arguments: [String], timestamp: Date) {
        self.input = input
        self.name = name
        self.arguments = arguments
        self.timestamp = timestamp
    }
}

public struct CLIOutput {
    public let id = UUID()
    public let text: String
    public let type: OutputType
    public let timestamp = Date()
    
    public enum OutputType {
        case standard
        case error
        case warning
        case success
        case info
    }
    
    public init(text: String, type: OutputType) {
        self.text = text
        self.type = type
    }
}

public struct CLIResult {
    public let success: Bool
    public let output: String
    public let error: String?
    
    public init(success: Bool, output: String, error: String? = nil) {
        self.success = success
        self.output = output
        self.error = error
    }
}

public struct CLIContext {
    public let currentDirectory: String
    public let environment: [String: String]
    
    public init(currentDirectory: String, environment: [String: String]) {
        self.currentDirectory = currentDirectory
        self.environment = environment
    }
}

struct ParsedCommand {
    let name: String
    let arguments: [String]
    let options: [String: String]
}

// MARK: - CLI Command Protocol

public protocol CLICommandHandler {
    var name: String { get }
    var description: String { get }
    var usage: String { get }
    var options: [CLIOption] { get }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult
}

public struct CLIOption {
    public let short: String?
    public let long: String
    public let description: String
    public let requiresValue: Bool
    
    public init(short: String? = nil, long: String, description: String, requiresValue: Bool = false) {
        self.short = short
        self.long = long
        self.description = description
        self.requiresValue = requiresValue
    }
}

// MARK: - CLI Error

public enum CLIError: Error {
    case invalidArguments(String)
    case commandFailed(String)
    case notFound(String)
    case permissionDenied(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidArguments(let message):
            return "Invalid arguments: \(message)"
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}


// MARK: - Auto-generated CLI Commands
struct CLIHelpCommand: CLICommandHandler {
    var name: String { "help" }
    var description: String { "Display help information" }
    var usage: String { "help [command]" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Help command executed")
    }
}

struct CLIListCommand: CLICommandHandler {
    var name: String { "list" }
    var description: String { "List items" }
    var usage: String { "list [options]" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "List command executed")
    }
}

struct CLICreateCommand: CLICommandHandler {
    var name: String { "create" }
    var description: String { "Create new item" }
    var usage: String { "create <name>" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Create command executed")
    }
}

struct CLIDeleteCommand: CLICommandHandler {
    var name: String { "delete" }
    var description: String { "Delete item" }
    var usage: String { "delete <name>" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Delete command executed")
    }
}

struct CLISearchCommand: CLICommandHandler {
    var name: String { "search" }
    var description: String { "Search for items" }
    var usage: String { "search <query>" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Search command executed")
    }
}

struct CLIInfoCommand: CLICommandHandler {
    var name: String { "info" }
    var description: String { "Display information" }
    var usage: String { "info [item]" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Info command executed")
    }
}

struct CLIClearCommand: CLICommandHandler {
    var name: String { "clear" }
    var description: String { "Clear the screen" }
    var usage: String { "clear" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Clear command executed")
    }
}

struct CLIHistoryCommand: CLICommandHandler {
    var name: String { "history" }
    var description: String { "Show command history" }
    var usage: String { "history" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "History command executed")
    }
}

struct CLIAliasCommand: CLICommandHandler {
    var name: String { "alias" }
    var description: String { "Create command alias" }
    var usage: String { "alias <name> <command>" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Alias command executed")
    }
}

struct CLIExportCommand: CLICommandHandler {
    var name: String { "export" }
    var description: String { "Export data" }
    var usage: String { "export <format>" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Export command executed")
    }
}

struct CLIConfigCommand: CLICommandHandler {
    var name: String { "config" }
    var description: String { "Configure settings" }
    var usage: String { "config <key> [value]" }
    var options: [CLIOption] { [] }
    
    func execute(arguments: [String], options: [String: String], context: CLIContext) async throws -> CLIResult {
        return CLIResult(success: true, output: "Config command executed")
    }
}