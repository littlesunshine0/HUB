//
//  ExecutionModels.swift
//  Hub
//
//  Execution-related data models for the Hub Automation System
//

import Foundation

// MARK: - Workflow Execution

struct WorkflowExecution: Identifiable {
    let id: UUID
    let workflow: Workflow
    var status: ExecutionStatus
    var startTime: Date
    var endTime: Date?
    var currentStep: UUID?
    var context: ExecutionContext
    var results: [UUID: ActionResult]
    var errors: [ExecutionError]
    
    init(
        id: UUID = UUID(),
        workflow: Workflow,
        status: ExecutionStatus = .pending,
        startTime: Date = Date(),
        endTime: Date? = nil,
        currentStep: UUID? = nil,
        context: ExecutionContext,
        results: [UUID: ActionResult] = [:],
        errors: [ExecutionError] = []
    ) {
        self.id = id
        self.workflow = workflow
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.currentStep = currentStep
        self.context = context
        self.results = results
        self.errors = errors
    }
}

// MARK: - Execution Status

enum ExecutionStatus: String, Codable {
    case pending
    case running
    case paused
    case completed
    case failed
    case cancelled
}

// MARK: - Execution Context

struct ExecutionContext {
    var source: ExecutionSource
    var variables: [String: String]
    var event: AutomationSystemEvent?
    var continueOnError: Bool
    
    init(
        source: ExecutionSource = .manual,
        variables: [String: String] = [:],
        event: AutomationSystemEvent? = nil,
        continueOnError: Bool = false
    ) {
        self.source = source
        self.variables = variables
        self.event = event
        self.continueOnError = continueOnError
    }
    
    mutating func setVariable(_ key: String, value: String) {
        variables[key] = value
    }
    
    mutating func updateVariables(from result: ActionResult) {
        if let output = result.output {
            variables["last_output"] = output
        }
        variables["last_status"] = result.status.rawValue
        if let duration = result.duration {
            variables["last_duration"] = "\(duration)"
        }
    }
}

// MARK: - Execution Source

enum ExecutionSource: Codable {
    case manual
    case scheduled(UUID)
    case trigger(UUID)
    case api
}

// MARK: - Action Result

struct ActionResult {
    var status: ActionStatus
    var output: String?
    var error: String?
    var duration: TimeInterval?
    var metadata: [String: String]
    
    init(
        status: ActionStatus,
        output: String? = nil,
        error: String? = nil,
        duration: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        self.status = status
        self.output = output
        self.error = error
        self.duration = duration
        self.metadata = metadata
    }
}

// MARK: - Action Status

enum ActionStatus: String, Codable {
    case success
    case failure
    case skipped
    case timeout
}

// MARK: - Workflow Result

struct WorkflowResult {
    let executionId: UUID
    let status: ExecutionStatus
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let stepResults: [UUID: ActionResult]
    let errors: [ExecutionError]
    
    init(execution: WorkflowExecution) {
        self.executionId = execution.id
        self.status = execution.status
        self.startTime = execution.startTime
        self.endTime = execution.endTime ?? Date()
        self.duration = (execution.endTime ?? Date()).timeIntervalSince(execution.startTime)
        self.stepResults = execution.results
        self.errors = execution.errors
    }
    
    init(
        executionId: UUID,
        status: ExecutionStatus,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        stepResults: [UUID: ActionResult],
        errors: [ExecutionError]
    ) {
        self.executionId = executionId
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.stepResults = stepResults
        self.errors = errors
    }
}

// MARK: - Execution Error

struct ExecutionError: Identifiable {
    let id: UUID
    let stepId: UUID?
    let timestamp: Date
    let error: Error
    let recoveryAttempted: Bool
    let recovered: Bool
    
    init(
        id: UUID = UUID(),
        stepId: UUID? = nil,
        timestamp: Date = Date(),
        error: Error,
        recoveryAttempted: Bool = false,
        recovered: Bool = false
    ) {
        self.id = id
        self.stepId = stepId
        self.timestamp = timestamp
        self.error = error
        self.recoveryAttempted = recoveryAttempted
        self.recovered = recovered
    }
}

// MARK: - Automation System Event

struct AutomationSystemEvent: Codable {
    let id: UUID
    let type: AutomationSystemEventType
    let timestamp: Date
    let source: String
    let data: [String: String]
    
    init(
        id: UUID = UUID(),
        type: AutomationSystemEventType,
        timestamp: Date = Date(),
        source: String,
        data: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.source = source
        self.data = data
    }
}

// MARK: - Automation System Event Type

enum AutomationSystemEventType: String, Codable {
    case fileChanged
    case gitCommit
    case gitPush
    case buildCompleted
    case testFailed
    case deploymentStarted
    case performanceAlert
    case userLogin
    case crawlCompleted
}

// MARK: - Automation Status

enum AutomationStatus: String {
    case idle
    case running
    case paused
    case error
}

// MARK: - Retry Attempt

struct RetryAttempt {
    let attemptNumber: Int
    let timestamp: Date
    let duration: TimeInterval
    let success: Bool
    let error: Error?
    
    init(
        attemptNumber: Int,
        timestamp: Date,
        duration: TimeInterval,
        success: Bool,
        error: Error? = nil
    ) {
        self.attemptNumber = attemptNumber
        self.timestamp = timestamp
        self.duration = duration
        self.success = success
        self.error = error
    }
}
