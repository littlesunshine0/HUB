//
//  WorkflowModels.swift
//  Hub
//
//  Core data models for the Hub Automation System
//

import Foundation

// MARK: - Workflow Definition

struct Workflow: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var steps: [WorkflowStep]
    var errorHandling: ErrorHandlingPolicy
    var retryPolicy: WorkflowRetryPolicy
    var timeout: TimeInterval?
    var notifications: [WorkflowNotificationConfig]
    var metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        steps: [WorkflowStep] = [],
        errorHandling: ErrorHandlingPolicy = .stopOnError,
        retryPolicy: WorkflowRetryPolicy = WorkflowRetryPolicy(),
        timeout: TimeInterval? = nil,
        notifications: [WorkflowNotificationConfig] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.errorHandling = errorHandling
        self.retryPolicy = retryPolicy
        self.timeout = timeout
        self.notifications = notifications
        self.metadata = metadata
    }
}

// MARK: - Workflow Step

struct WorkflowStep: Codable, Identifiable {
    let id: UUID
    var name: String
    var action: WorkflowAction
    var condition: WorkflowCondition?
    var onSuccessStepIds: [UUID]?
    var onFailureStepIds: [UUID]?
    var timeout: TimeInterval?
    var retryPolicy: WorkflowRetryPolicy?
    var fallbackStepId: UUID?
    
    init(
        id: UUID = UUID(),
        name: String,
        action: WorkflowAction,
        condition: WorkflowCondition? = nil,
        onSuccessStepIds: [UUID]? = nil,
        onFailureStepIds: [UUID]? = nil,
        timeout: TimeInterval? = nil,
        retryPolicy: WorkflowRetryPolicy? = nil,
        fallbackStepId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.action = action
        self.condition = condition
        self.onSuccessStepIds = onSuccessStepIds
        self.onFailureStepIds = onFailureStepIds
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.fallbackStepId = fallbackStepId
    }
}

// MARK: - Workflow Action

enum WorkflowAction: Codable {
    case command(CommandAction)
    case dataPipeline(DataPipelineAction)
    case aiQuery(AIQueryAction)
    case test(TestAction)
    case deploy(DeployAction)
    case macro(MacroAction)
    case custom(CustomAction)
}

// MARK: - Action Types

struct CommandAction: Codable {
    var pattern: String
    var parameters: [String: String]
    var requiresSudo: Bool
    var captureOutput: Bool
    var outputVariable: String?
    var workingDirectory: URL?
}

struct DataPipelineAction: Codable {
    var type: PipelineType
    var config: PipelineConfig
    var validation: ValidationConfig
    var errorRecovery: RecoveryConfig
}

struct AIQueryAction: Codable {
    var query: String
    var context: WorkflowAIContext
    var responseFormat: ResponseFormat
    var outputVariable: String?
}

struct TestAction: Codable {
    var type: TestType
    var config: TestConfig
    var reportFormat: ReportFormat
}

struct DeployAction: Codable {
    var target: String
    var environment: String
    var config: [String: String]
}

struct MacroAction: Codable {
    var macroId: UUID
    var parameters: [String: String]
}

struct CustomAction: Codable {
    var identifier: String
    var parameters: [String: String]
}

// MARK: - Supporting Types

enum PipelineType: String, Codable {
    case crawl
    case `import`
    case validate
    case extract
    case sync
}

struct PipelineConfig: Codable {
    var sourceURL: URL?
    var maxDepth: Int?
    var maxPages: Int?
    var concurrency: Int?
    var autoValidate: Bool
}

struct ValidationConfig: Codable {
    var schemaPath: String?
    var strictMode: Bool
}

struct RecoveryConfig: Codable {
    var autoRepair: Bool
    var maxAttempts: Int
}

struct WorkflowAIContext: Codable {
    var conversationId: UUID?
    var codeContext: WorkflowCodeContext?
    var knowledgeDomain: String?
    var userPreferences: [String: String]
}

struct WorkflowCodeContext: Codable {
    var file: String
    var language: String?
    var symbols: [String]
}

enum ResponseFormat: String, Codable {
    case text
    case json
    case markdown
}

enum TestType: String, Codable {
    case unit
    case integration
    case performance
    case security
    case regression
}

struct TestConfig: Codable {
    var target: String?
    var parallel: Bool
    var coverage: Bool
}

enum ReportFormat: String, Codable {
    case text
    case json
    case html
    case junit
}

// MARK: - Workflow Condition

struct WorkflowCondition: Codable {
    var type: WorkflowConditionType
    var expression: String
    var variables: [String: String]
}

enum WorkflowConditionType: String, Codable {
    case always
    case ifSuccess
    case ifFailure
    case ifVariable
    case custom
}

// MARK: - Error Handling

enum ErrorHandlingPolicy: String, Codable {
    case stopOnError
    case continueOnError
    case rollback
}

// MARK: - Retry Policy

struct WorkflowRetryPolicy: Codable {
    var maxAttempts: Int
    var backoffStrategy: WorkflowBackoffStrategy
    var retryableErrors: [String]
    
    init(
        maxAttempts: Int = 3,
        backoffStrategy: WorkflowBackoffStrategy = .exponential,
        retryableErrors: [String] = []
    ) {
        self.maxAttempts = maxAttempts
        self.backoffStrategy = backoffStrategy
        self.retryableErrors = retryableErrors
    }
}

enum WorkflowBackoffStrategy: String, Codable {
    case fixed
    case exponential
    case linear
}

// MARK: - Notification Configuration

struct WorkflowNotificationConfig: Codable {
    var channel: WorkflowNotificationChannel
    var events: [WorkflowNotificationEvent]
    var template: String?
}

enum WorkflowNotificationChannel: String, Codable {
    case system
    case email
    case slack
    case webhook
}

enum WorkflowNotificationEvent: String, Codable {
    case workflowStarted
    case workflowCompleted
    case workflowFailed
    case stepFailed
    case approvalRequired
}

// MARK: - Workflow Composition

enum WorkflowCompositionMode: String, Codable {
    case sequential
    case parallel
    case conditional
}

// MARK: - Workflow Template

struct WorkflowTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var baseWorkflow: Workflow
    var parameters: [WorkflowParameter]
    var createdAt: Date
    var tags: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        baseWorkflow: Workflow,
        parameters: [WorkflowParameter] = [],
        createdAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.baseWorkflow = baseWorkflow
        self.parameters = parameters
        self.createdAt = createdAt
        self.tags = tags
    }
}

// MARK: - Workflow Parameter

struct WorkflowParameter: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var type: WorkflowParameterType
    var defaultValue: String?
    var required: Bool
    var validationPattern: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: WorkflowParameterType = .string,
        defaultValue: String? = nil,
        required: Bool = true,
        validationPattern: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.defaultValue = defaultValue
        self.required = required
        self.validationPattern = validationPattern
    }
}

// MARK: - Workflow Parameter Type

enum WorkflowParameterType: String, Codable {
    case string
    case number
    case boolean
    case url
    case path
    case email
}
