//
//  AutomationErrors.swift
//  Hub
//
//  Error types for the Hub Automation System
//

import Foundation

// MARK: - Automation Error

enum AutomationError: Error, LocalizedError {
    case workflowNotFound(UUID)
    case patternNotFound(String)
    case macroNotFound(UUID)
    case invalidConfiguration(String)
    case missingConfiguration(String)
    case approvalDenied
    case approvalTimeout
    case executionTimeout
    case stepFailed(stepName: String, error: Error)
    case macroExecutionFailed(stepId: UUID, error: Error)
    case recoveryFailed(ErrorContext)
    case triggerEvaluationFailed(UUID, Error)
    case conditionEvaluationFailed(String)
    case invalidWorkflow(String)
    case missingParameter(String)
    
    var errorDescription: String? {
        switch self {
        case .workflowNotFound(let id):
            return "Workflow not found: \(id)"
        case .patternNotFound(let pattern):
            return "Command pattern not found: \(pattern)"
        case .macroNotFound(let id):
            return "Macro not found: \(id)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .missingConfiguration(let key):
            return "Missing configuration: \(key)"
        case .approvalDenied:
            return "Approval denied for privileged operation"
        case .approvalTimeout:
            return "Approval request timed out"
        case .executionTimeout:
            return "Workflow execution timed out"
        case .stepFailed(let stepName, let error):
            return "Step '\(stepName)' failed: \(error.localizedDescription)"
        case .macroExecutionFailed(let stepId, let error):
            return "Macro step \(stepId) failed: \(error.localizedDescription)"
        case .recoveryFailed(let context):
            return "Error recovery failed for: \(context.error.localizedDescription)"
        case .triggerEvaluationFailed(let id, let error):
            return "Trigger evaluation failed for \(id): \(error.localizedDescription)"
        case .conditionEvaluationFailed(let expression):
            return "Condition evaluation failed: \(expression)"
        case .invalidWorkflow(let reason):
            return "Invalid workflow: \(reason)"
        case .missingParameter(let name):
            return "Missing required parameter: \(name)"
        }
    }
}

// MARK: - Error Classification

enum ErrorClassification: String, Codable {
    case networkTimeout
    case rateLimited
    case temporaryFailure
    case serviceUnavailable
    case resourceNotFound
    case authenticationFailed
    case permissionDenied
    case invalidInput
    case configurationError
    case unrecoverable
    
    var isRecoverable: Bool {
        switch self {
        case .networkTimeout, .rateLimited, .temporaryFailure, .serviceUnavailable:
            return true
        case .resourceNotFound, .authenticationFailed, .permissionDenied, .invalidInput, .configurationError, .unrecoverable:
            return false
        }
    }
}

// MARK: - Error Context

struct ErrorContext {
    let error: Error
    let workflowId: UUID
    let workflowName: String
    let stepId: UUID
    let stepName: String
    let executionContext: ExecutionContext
    let attemptNumber: Int
    
    init(
        error: Error,
        workflowId: UUID,
        workflowName: String,
        stepId: UUID,
        stepName: String,
        executionContext: ExecutionContext,
        attemptNumber: Int = 0
    ) {
        self.error = error
        self.workflowId = workflowId
        self.workflowName = workflowName
        self.stepId = stepId
        self.stepName = stepName
        self.executionContext = executionContext
        self.attemptNumber = attemptNumber
    }
}

// MARK: - Automation Macro Types (to avoid conflicts with HooksModule)

struct AutomationMacroStep: Codable, Identifiable {
    let id: UUID
    var action: AutomationMacroAction
    var timestamp: TimeInterval
    var context: AutomationMacroContext
    
    init(
        id: UUID = UUID(),
        action: AutomationMacroAction,
        timestamp: TimeInterval,
        context: AutomationMacroContext
    ) {
        self.id = id
        self.action = action
        self.timestamp = timestamp
        self.context = context
    }
}

enum AutomationMacroAction: Codable {
    case click(target: String, position: CGPoint)
    case type(text: String, field: String)
    case select(item: String, list: String)
    case navigate(destination: String)
    case command(pattern: String, parameters: [String: String])
    case wait(duration: TimeInterval)
}

struct AutomationMacroContext: Codable {
    var windowTitle: String?
    var viewIdentifier: String?
    var metadata: [String: String]
}
