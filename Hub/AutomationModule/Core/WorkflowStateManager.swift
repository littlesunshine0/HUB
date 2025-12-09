//
//  WorkflowStateManager.swift
//  Hub
//
//  Manages state for active workflow executions
//

import Foundation

/// Manages the state of all active workflow executions
actor WorkflowStateManager {
    
    // MARK: - Properties
    
    private var activeExecutions: [UUID: WorkflowExecution] = [:]
    private var executionHistory: [UUID: WorkflowExecution] = [:]
    private let maxHistorySize: Int = 1000
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Execution Management
    
    /// Register a new workflow execution
    func registerExecution(_ execution: WorkflowExecution) {
        activeExecutions[execution.id] = execution
    }
    
    /// Update an existing workflow execution
    func updateExecution(_ execution: WorkflowExecution) {
        activeExecutions[execution.id] = execution
        
        // Move to history if completed, failed, or cancelled
        if execution.status == .completed || execution.status == .failed || execution.status == .cancelled {
            moveToHistory(execution)
        }
    }
    
    /// Get a workflow execution by ID
    func getExecution(_ id: UUID) -> WorkflowExecution? {
        return activeExecutions[id] ?? executionHistory[id]
    }
    
    /// Get all active executions
    func getActiveExecutions() -> [WorkflowExecution] {
        return Array(activeExecutions.values)
    }
    
    /// Get executions by status
    func getExecutions(withStatus status: ExecutionStatus) -> [WorkflowExecution] {
        return activeExecutions.values.filter { $0.status == status }
    }
    
    /// Get executions for a specific workflow
    func getExecutions(forWorkflow workflowId: UUID) -> [WorkflowExecution] {
        let active = activeExecutions.values.filter { $0.workflow.id == workflowId }
        let historical = executionHistory.values.filter { $0.workflow.id == workflowId }
        return Array(active) + Array(historical)
    }
    
    /// Cancel a workflow execution
    func cancelExecution(_ id: UUID) {
        guard var execution = activeExecutions[id] else { return }
        execution.status = .cancelled
        execution.endTime = Date()
        updateExecution(execution)
    }
    
    /// Pause a workflow execution
    func pauseExecution(_ id: UUID) {
        guard var execution = activeExecutions[id], execution.status == .running else { return }
        execution.status = .paused
        activeExecutions[id] = execution
    }
    
    /// Resume a paused workflow execution
    func resumeExecution(_ id: UUID) {
        guard var execution = activeExecutions[id], execution.status == .paused else { return }
        execution.status = .running
        activeExecutions[id] = execution
    }
    
    /// Update the current step of an execution
    func updateCurrentStep(_ executionId: UUID, stepId: UUID) {
        guard var execution = activeExecutions[executionId] else { return }
        execution.currentStep = stepId
        activeExecutions[executionId] = execution
    }
    
    /// Add a step result to an execution
    func addStepResult(_ executionId: UUID, stepId: UUID, result: ActionResult) {
        guard var execution = activeExecutions[executionId] else { return }
        execution.results[stepId] = result
        execution.context.updateVariables(from: result)
        activeExecutions[executionId] = execution
    }
    
    /// Add an error to an execution
    func addError(_ executionId: UUID, error: ExecutionError) {
        guard var execution = activeExecutions[executionId] else { return }
        execution.errors.append(error)
        activeExecutions[executionId] = execution
    }
    
    /// Update execution context
    func updateContext(_ executionId: UUID, context: ExecutionContext) {
        guard var execution = activeExecutions[executionId] else { return }
        execution.context = context
        activeExecutions[executionId] = execution
    }
    
    // MARK: - History Management
    
    /// Move an execution to history
    private func moveToHistory(_ execution: WorkflowExecution) {
        activeExecutions.removeValue(forKey: execution.id)
        executionHistory[execution.id] = execution
        
        // Trim history if needed
        if executionHistory.count > maxHistorySize {
            trimHistory()
        }
    }
    
    /// Trim history to maintain size limit
    private func trimHistory() {
        let sortedHistory = executionHistory.values.sorted { $0.startTime < $1.startTime }
        let toRemove = sortedHistory.prefix(executionHistory.count - maxHistorySize)
        
        for execution in toRemove {
            executionHistory.removeValue(forKey: execution.id)
        }
    }
    
    /// Get execution history
    func getHistory(limit: Int? = nil) -> [WorkflowExecution] {
        let sorted = executionHistory.values.sorted { $0.startTime > $1.startTime }
        if let limit = limit {
            return Array(sorted.prefix(limit))
        }
        return Array(sorted)
    }
    
    /// Clear completed executions from history
    func clearHistory(olderThan date: Date) {
        executionHistory = executionHistory.filter { $0.value.startTime >= date }
    }
    
    // MARK: - Statistics
    
    /// Get execution statistics
    func getStatistics() -> ExecutionStatistics {
        let all = Array(activeExecutions.values) + Array(executionHistory.values)
        
        let total = all.count
        let completed = all.filter { $0.status == .completed }.count
        let failed = all.filter { $0.status == .failed }.count
        let running = all.filter { $0.status == .running }.count
        let cancelled = all.filter { $0.status == .cancelled }.count
        
        let durations = all.compactMap { execution -> TimeInterval? in
            guard let endTime = execution.endTime else { return nil }
            return endTime.timeIntervalSince(execution.startTime)
        }
        
        let averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        
        return ExecutionStatistics(
            totalExecutions: total,
            completedExecutions: completed,
            failedExecutions: failed,
            runningExecutions: running,
            cancelledExecutions: cancelled,
            averageDuration: averageDuration
        )
    }
}

// MARK: - Execution Statistics

struct ExecutionStatistics {
    let totalExecutions: Int
    let completedExecutions: Int
    let failedExecutions: Int
    let runningExecutions: Int
    let cancelledExecutions: Int
    let averageDuration: TimeInterval
    
    var successRate: Double {
        guard totalExecutions > 0 else { return 0 }
        return Double(completedExecutions) / Double(totalExecutions)
    }
    
    var failureRate: Double {
        guard totalExecutions > 0 else { return 0 }
        return Double(failedExecutions) / Double(totalExecutions)
    }
}
