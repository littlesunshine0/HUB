//
//  AutomationCoordinator.swift
//  Hub
//
//  Central orchestrator for the Hub Automation System
//

import Foundation
import Combine

/// Central coordinator managing workflow execution, scheduling, and event distribution
@MainActor
class AutomationCoordinator: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AutomationCoordinator()
    
    // MARK: - Published Properties
    
    @Published var activeWorkflows: [UUID: WorkflowExecution] = [:]
    @Published var systemStatus: AutomationStatus = .idle
    
    // MARK: - Private Properties
    
    private let workflowStateManager: WorkflowStateManager
    private let workflowExecutionEngine: WorkflowExecutionEngine
    private let terminalService: TerminalService
    
    private var eventSubscriptions: Set<AnyCancellable> = []
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private init() {
        self.workflowStateManager = WorkflowStateManager()
        
        // Determine storage location for automation-related persistence
        let automationStorageURL: URL = {
            let fm = FileManager.default
            let baseURL: URL
            if let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                baseURL = appSupport
            } else {
                baseURL = fm.temporaryDirectory
            }
            let dir = baseURL.appendingPathComponent("HubAutomation", isDirectory: true)
            // Ensure directory exists
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }()
        
        // Initialize TerminalService dependencies
        let patternRegistry = CommandPatternRegistry()
        let contextManager = ShellContextManager(storageURL: automationStorageURL.appendingPathComponent("ShellContext.json"))
        let historyManager = CommandHistoryManager(storageURL: automationStorageURL.appendingPathComponent("CommandHistory.json"))
        let sudoManager = SudoManager.shared
        let whitelistURL = automationStorageURL.appendingPathComponent("CommandWhitelist.json")
          let initialCommands: Set<String> = {
              if let data = try? Data(contentsOf: whitelistURL),
                 let array = try? JSONDecoder().decode([String].self, from: data) {
                  return Set(array)
              }
              return []
          }()
          let whitelist = CommandWhitelist(initialCommands: initialCommands)
        
        // Create TerminalService
        self.terminalService = TerminalService(
            patternRegistry: patternRegistry,
            contextManager: contextManager,
            historyManager: historyManager,
            sudoManager: sudoManager,
            whitelist: whitelist,
            executionTimeout: 30.0
        )
        
        // Create WorkflowExecutionEngine with TerminalService
        self.workflowExecutionEngine = WorkflowExecutionEngine(
            stateManager: workflowStateManager,
            terminalService: terminalService
        )
    }
    
    // MARK: - Public Access
    
    /// Access to the terminal service for direct command execution
    var terminal: TerminalService {
        return terminalService
    }
    
    // MARK: - Lifecycle Management
    
    /// Initialize the automation coordinator
    func initialize() async throws {
        guard !isInitialized else { return }
        
        print("🚀 Initializing Hub Automation System...")
        
        // Update status
        systemStatus = .running
        
        // Set up event subscriptions
        setupEventSubscriptions()
        
        isInitialized = true
        print("✅ Hub Automation System initialized successfully")
    }
    
    /// Shutdown the automation coordinator
    func shutdown() async {
        print("🛑 Shutting down Hub Automation System...")
        
        // Cancel all active workflows
        let active = await workflowStateManager.getActiveExecutions()
        for execution in active {
            await workflowStateManager.cancelExecution(execution.id)
        }
        
        // Clear subscriptions
        eventSubscriptions.removeAll()
        
        // Update status
        systemStatus = .idle
        isInitialized = false
        
        print("✅ Hub Automation System shut down successfully")
    }
    
    // MARK: - Workflow Execution
    
    /// Execute a workflow with the given context
    func executeWorkflow(_ workflow: Workflow, context: ExecutionContext = ExecutionContext()) async throws -> WorkflowResult {
        guard isInitialized else {
            throw AutomationError.invalidConfiguration("Automation system not initialized")
        }
        
        print("▶️ Executing workflow: \(workflow.name)")
        
        // Update status
        if systemStatus == .idle {
            systemStatus = .running
        }
        
        do {
            // Execute workflow
            let result = try await workflowExecutionEngine.execute(workflow, context: context)
            
            // Update active workflows
            await updateActiveWorkflows()
            
            // Check if we should return to idle
            let activeCount = await workflowStateManager.getExecutions(withStatus: .running).count
            if activeCount == 0 {
                systemStatus = .idle
            }
            
            print("✅ Workflow completed: \(workflow.name)")
            return result
            
        } catch {
            print("❌ Workflow failed: \(workflow.name) - \(error.localizedDescription)")
            systemStatus = .error
            
            // Update active workflows
            await updateActiveWorkflows()
            
            throw error
        }
    }
    
    /// Execute a workflow by ID
    func executeWorkflow(id: UUID, context: ExecutionContext = ExecutionContext()) async throws -> WorkflowResult {
        // This would load the workflow from storage
        // For now, throw an error
        throw AutomationError.workflowNotFound(id)
    }
    
    // MARK: - Workflow Control
    
    /// Pause a running workflow
    func pauseWorkflow(_ workflowId: UUID) async {
        await workflowExecutionEngine.pause(workflowId)
        await updateActiveWorkflows()
        print("⏸️ Workflow paused: \(workflowId)")
    }
    
    /// Resume a paused workflow
    func resumeWorkflow(_ workflowId: UUID) async {
        await workflowExecutionEngine.resume(workflowId)
        await updateActiveWorkflows()
        print("▶️ Workflow resumed: \(workflowId)")
    }
    
    /// Cancel a workflow
    func cancelWorkflow(_ workflowId: UUID) async {
        await workflowStateManager.cancelExecution(workflowId)
        await updateActiveWorkflows()
        print("🛑 Workflow cancelled: \(workflowId)")
    }
    
    /// Get the status of a workflow execution
    func getWorkflowStatus(_ workflowId: UUID) async -> WorkflowExecution? {
        return await workflowStateManager.getExecution(workflowId)
    }
    
    // MARK: - Workflow Queries
    
    /// Get all active workflow executions
    func getActiveWorkflows() async -> [WorkflowExecution] {
        return await workflowStateManager.getActiveExecutions()
    }
    
    /// Get workflow execution history
    func getWorkflowHistory(limit: Int? = nil) async -> [WorkflowExecution] {
        return await workflowStateManager.getHistory(limit: limit)
    }
    
    /// Get execution statistics
    func getStatistics() async -> ExecutionStatistics {
        return await workflowStateManager.getStatistics()
    }
    
    // MARK: - Private Methods
    
    private func setupEventSubscriptions() {
        // Set up timer to periodically update active workflows
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateActiveWorkflows()
                }
            }
            .store(in: &eventSubscriptions)
    }
    
    private func updateActiveWorkflows() async {
        let executions = await workflowStateManager.getActiveExecutions()
        
        // Convert to dictionary
        var executionsDict: [UUID: WorkflowExecution] = [:]
        for execution in executions {
            executionsDict[execution.id] = execution
        }
        
        activeWorkflows = executionsDict
    }
}

// MARK: - Convenience Extensions

extension AutomationCoordinator {
    
    /// Create and execute a simple command workflow
    func executeCommand(
        pattern: String,
        parameters: [String: String] = [:],
        requiresSudo: Bool = false
    ) async throws -> WorkflowResult {
        let commandAction = CommandAction(
            pattern: pattern,
            parameters: parameters,
            requiresSudo: requiresSudo,
            captureOutput: true,
            outputVariable: "output",
            workingDirectory: nil
        )
        
        let step = WorkflowStep(
            name: "Execute \(pattern)",
            action: .command(commandAction)
        )
        
        let workflow = Workflow(
            name: "Command: \(pattern)",
            description: "Execute command pattern \(pattern)",
            steps: [step]
        )
        
        return try await executeWorkflow(workflow)
    }
    
    /// Create and execute a simple test workflow
    func executeTests(
        type: TestType = .unit,
        target: String? = nil
    ) async throws -> WorkflowResult {
        let testAction = TestAction(
            type: type,
            config: TestConfig(target: target, parallel: true, coverage: false),
            reportFormat: .text
        )
        
        let step = WorkflowStep(
            name: "Run \(type.rawValue) tests",
            action: .test(testAction)
        )
        
        let workflow = Workflow(
            name: "Tests: \(type.rawValue)",
            description: "Execute \(type.rawValue) tests",
            steps: [step]
        )
        
        return try await executeWorkflow(workflow)
    }
}

