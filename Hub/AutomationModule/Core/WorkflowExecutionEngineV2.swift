//
//  WorkflowExecutionEngine.swift
//  Hub
//
//  Core engine for executing workflows with step-by-step execution logic
//

import Foundation

/// Engine responsible for executing workflows with conditional logic and error handling
actor WorkflowExecutionEngine {
    
    // MARK: - Properties
    
    private let stateManager: WorkflowStateManager
    private let terminalService: TerminalService
    private var pauseFlags: [UUID: Bool] = [:]
    
    // MARK: - Initialization
    
    init(stateManager: WorkflowStateManager, terminalService: TerminalService) {
        self.stateManager = stateManager
        self.terminalService = terminalService
    }
    
    // MARK: - Workflow Execution
    
    /// Execute a workflow with the given context
    func execute(_ workflow: Workflow, context: ExecutionContext) async throws -> WorkflowResult {
        // Validate workflow
        try validateWorkflow(workflow)
        
        // Create execution
        let execution = WorkflowExecution(
            workflow: workflow,
            status: .running,
            context: context
        )
        
        // Register execution
        await stateManager.registerExecution(execution)
        
        // Execute with timeout if specified
        if let timeout = workflow.timeout {
            return try await withTimeout(timeout) {
                try await self.executeWorkflow(execution)
            }
        } else {
            return try await executeWorkflow(execution)
        }
    }
    
    /// Execute multiple workflows in sequence (chaining)
    func executeChain(_ workflows: [Workflow], context: ExecutionContext) async throws -> [WorkflowResult] {
        var results: [WorkflowResult] = []
        var chainContext = context
        
        for workflow in workflows {
            let result = try await execute(workflow, context: chainContext)
            results.append(result)
            
            // Pass context forward to next workflow
            // Merge variables from previous workflow result
            for (stepId, stepResult) in result.stepResults {
                chainContext.updateVariables(from: stepResult)
            }
            
            // Stop chain if workflow failed and continueOnError is false
            if result.status == .failed && !chainContext.continueOnError {
                break
            }
        }
        
        return results
    }
    
    /// Execute multiple workflows in parallel
    func executeParallel(_ workflows: [Workflow], context: ExecutionContext) async throws -> [WorkflowResult] {
        try await withThrowingTaskGroup(of: (Int, WorkflowResult).self) { group in
            // Add tasks for each workflow
            for (index, workflow) in workflows.enumerated() {
                group.addTask {
                    let result = try await self.execute(workflow, context: context)
                    return (index, result)
                }
            }
            
            // Collect results in order
            var results: [(Int, WorkflowResult)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by original index to maintain order
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    /// Execute steps in parallel within a workflow
    func executeStepsParallel(_ steps: [WorkflowStep], context: ExecutionContext, executionId: UUID) async throws -> [UUID: ActionResult] {
        try await withThrowingTaskGroup(of: (UUID, ActionResult).self) { group in
            // Add tasks for each step
            for step in steps {
                group.addTask {
                    // Check if paused
                    await self.checkPauseState(executionId)
                    
                    // Evaluate condition
                    guard try await self.evaluateCondition(step.condition, context: context) else {
                        return (step.id, ActionResult(status: .skipped))
                    }
                    
                    // Execute step with retry logic
                    let result = try await self.executeStepWithRetry(
                        step,
                        context: context,
                        executionId: executionId
                    )
                    
                    return (step.id, result)
                }
            }
            
            // Collect results
            var results: [UUID: ActionResult] = [:]
            for try await (stepId, result) in group {
                results[stepId] = result
                await self.stateManager.addStepResult(executionId, stepId: stepId, result: result)
            }
            
            return results
        }
    }
    
    /// Compose a workflow from sub-workflows (reusable workflow composition)
    func composeWorkflow(
        name: String,
        description: String,
        subWorkflows: [Workflow],
        executionMode: WorkflowCompositionMode = .sequential
    ) -> Workflow {
        // Create a composite workflow that references sub-workflows
        var compositeSteps: [WorkflowStep] = []
        
        for (index, subWorkflow) in subWorkflows.enumerated() {
            // Create a step that represents executing the sub-workflow
            let step = WorkflowStep(
                name: "Execute \(subWorkflow.name)",
                action: .custom(CustomAction(
                    identifier: "execute_workflow",
                    parameters: [
                        "workflow_id": subWorkflow.id.uuidString,
                        "workflow_name": subWorkflow.name
                    ]
                ))
            )
            compositeSteps.append(step)
        }
        
        return Workflow(
            name: name,
            description: description,
            steps: compositeSteps,
            metadata: [
                "composition_mode": executionMode.rawValue,
                "sub_workflow_count": "\(subWorkflows.count)",
                "is_composite": "true"
            ]
        )
    }
    
    /// Execute a composite workflow with sub-workflows
    func executeCompositeWorkflow(
        _ workflow: Workflow,
        subWorkflows: [UUID: Workflow],
        context: ExecutionContext
    ) async throws -> WorkflowResult {
        guard workflow.metadata["is_composite"] == "true" else {
            throw AutomationError.invalidWorkflow("Not a composite workflow")
        }
        
        let mode = WorkflowCompositionMode(rawValue: workflow.metadata["composition_mode"] ?? "sequential") ?? .sequential
        
        // Extract sub-workflow IDs from steps
        var subWorkflowsToExecute: [Workflow] = []
        for step in workflow.steps {
            if case .custom(let customAction) = step.action,
               customAction.identifier == "execute_workflow",
               let workflowIdString = customAction.parameters["workflow_id"],
               let workflowId = UUID(uuidString: workflowIdString),
               let subWorkflow = subWorkflows[workflowId] {
                subWorkflowsToExecute.append(subWorkflow)
            }
        }
        
        // Execute based on composition mode
        let results: [WorkflowResult]
        switch mode {
        case .sequential:
            results = try await executeChain(subWorkflowsToExecute, context: context)
        case .parallel:
            results = try await executeParallel(subWorkflowsToExecute, context: context)
        case .conditional:
            // For conditional mode, execute based on conditions in the workflow steps
            results = try await executeConditionalComposition(workflow, subWorkflows: subWorkflows, context: context)
        }
        
        // Aggregate results into a single workflow result
        return aggregateCompositeResults(workflow: workflow, results: results)
    }
    
    /// Execute sub-workflows conditionally based on step conditions
    private func executeConditionalComposition(
        _ workflow: Workflow,
        subWorkflows: [UUID: Workflow],
        context: ExecutionContext
    ) async throws -> [WorkflowResult] {
        var results: [WorkflowResult] = []
        var currentContext = context
        
        for step in workflow.steps {
            // Evaluate condition
            guard try await evaluateCondition(step.condition, context: currentContext) else {
                continue
            }
            
            // Extract and execute sub-workflow
            if case .custom(let customAction) = step.action,
               customAction.identifier == "execute_workflow",
               let workflowIdString = customAction.parameters["workflow_id"],
               let workflowId = UUID(uuidString: workflowIdString),
               let subWorkflow = subWorkflows[workflowId] {
                
                let result = try await execute(subWorkflow, context: currentContext)
                results.append(result)
                
                // Update context for next workflow
                for (_, stepResult) in result.stepResults {
                    currentContext.updateVariables(from: stepResult)
                }
            }
        }
        
        return results
    }
    
    /// Aggregate results from multiple sub-workflows into a single result
    private func aggregateCompositeResults(workflow: Workflow, results: [WorkflowResult]) -> WorkflowResult {
        let startTime = results.first?.startTime ?? Date()
        let endTime = results.last?.endTime ?? Date()
        
        // Aggregate all step results
        var allStepResults: [UUID: ActionResult] = [:]
        var allErrors: [ExecutionError] = []
        
        for result in results {
            allStepResults.merge(result.stepResults) { _, new in new }
            allErrors.append(contentsOf: result.errors)
        }
        
        // Determine overall status
        let overallStatus: ExecutionStatus
        if results.allSatisfy({ $0.status == .completed }) {
            overallStatus = .completed
        } else if results.contains(where: { $0.status == .failed }) {
            overallStatus = .failed
        } else if results.contains(where: { $0.status == .cancelled }) {
            overallStatus = .cancelled
        } else {
            overallStatus = .completed
        }
        
        return WorkflowResult(
            executionId: UUID(),
            status: overallStatus,
            startTime: startTime,
            endTime: endTime,
            duration: endTime.timeIntervalSince(startTime),
            stepResults: allStepResults,
            errors: allErrors
        )
    }
    
    /// Create a reusable workflow template from an existing workflow
    func createWorkflowTemplate(
        from workflow: Workflow,
        templateName: String,
        parameters: [WorkflowParameter]
    ) -> WorkflowTemplate {
        return WorkflowTemplate(
            id: UUID(),
            name: templateName,
            description: workflow.description,
            baseWorkflow: workflow,
            parameters: parameters,
            createdAt: Date()
        )
    }
    
    /// Instantiate a workflow from a template with parameter values
    func instantiateFromTemplate(
        _ template: WorkflowTemplate,
        parameterValues: [String: String]
    ) throws -> Workflow {
        // Validate all required parameters are provided
        for parameter in template.parameters where parameter.required {
            guard parameterValues[parameter.name] != nil else {
                throw AutomationError.missingParameter(parameter.name)
            }
        }
        
        // Apply parameter substitution to workflow steps
        let substitutedSteps = template.baseWorkflow.steps.map { step in
            var modifiedStep = step
            modifiedStep.action = substituteTemplateParameters(
                in: step.action,
                parameters: parameterValues
            )
            return modifiedStep
        }
        
        // Create new workflow with substituted steps and updated metadata
        var metadata = template.baseWorkflow.metadata
        metadata["template_id"] = template.id.uuidString
        metadata["template_name"] = template.name
        metadata["instantiated_at"] = ISO8601DateFormatter().string(from: Date())
        
        return Workflow(
            id: UUID(), // New ID for the instance
            name: template.baseWorkflow.name,
            description: template.baseWorkflow.description,
            steps: substitutedSteps,
            errorHandling: template.baseWorkflow.errorHandling,
            retryPolicy: template.baseWorkflow.retryPolicy,
            timeout: template.baseWorkflow.timeout,
            notifications: template.baseWorkflow.notifications,
            metadata: metadata
        )
    }
    
    /// Substitute template parameters in workflow actions
    private func substituteTemplateParameters(
        in action: WorkflowAction,
        parameters: [String: String]
    ) -> WorkflowAction {
        switch action {
        case .command(var commandAction):
            commandAction.parameters = substituteTemplateParametersInDictionary(
                commandAction.parameters,
                parameters: parameters
            )
            commandAction.pattern = substituteTemplateParametersInString(
                commandAction.pattern,
                parameters: parameters
            )
            return .command(commandAction)
            
        case .dataPipeline(let pipelineAction):
            return .dataPipeline(pipelineAction)
            
        case .aiQuery(var aiAction):
            aiAction.query = substituteTemplateParametersInString(
                aiAction.query,
                parameters: parameters
            )
            return .aiQuery(aiAction)
            
        case .test(let testAction):
            return .test(testAction)
            
        case .deploy(var deployAction):
            deployAction.target = substituteTemplateParametersInString(
                deployAction.target,
                parameters: parameters
            )
            deployAction.environment = substituteTemplateParametersInString(
                deployAction.environment,
                parameters: parameters
            )
            deployAction.config = substituteTemplateParametersInDictionary(
                deployAction.config,
                parameters: parameters
            )
            return .deploy(deployAction)
            
        case .macro(var macroAction):
            macroAction.parameters = substituteTemplateParametersInDictionary(
                macroAction.parameters,
                parameters: parameters
            )
            return .macro(macroAction)
            
        case .custom(var customAction):
            customAction.parameters = substituteTemplateParametersInDictionary(
                customAction.parameters,
                parameters: parameters
            )
            return .custom(customAction)
        }
    }
    
    /// Substitute template parameters in a dictionary
    private func substituteTemplateParametersInDictionary(
        _ dict: [String: String],
        parameters: [String: String]
    ) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = substituteTemplateParametersInString(value, parameters: parameters)
        }
        return result
    }
    
    /// Substitute template parameters in a string using {{parameter_name}} syntax
    private func substituteTemplateParametersInString(
        _ string: String,
        parameters: [String: String]
    ) -> String {
        var result = string
        
        // Find all {{parameter_name}} patterns
        let pattern = "\\{\\{([^}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return string
        }
        
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        
        // Replace in reverse order to maintain string indices
        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: string) else { continue }
            let parameterName = String(string[range])
            
            if let value = parameters[parameterName] {
                guard let fullRange = Range(match.range, in: string) else { continue }
                result.replaceSubrange(fullRange, with: value)
            }
        }
        
        return result
    }
    
    // MARK: - Private Execution Methods
    
    private func executeWorkflow(_ execution: WorkflowExecution) async throws -> WorkflowResult {
        var currentExecution = execution
        
        do {
            // Execute all steps
            for step in currentExecution.workflow.steps {
                // Check if paused
                await checkPauseState(currentExecution.id)
                
                // Update current step
                await stateManager.updateCurrentStep(currentExecution.id, stepId: step.id)
                
                // Evaluate condition
                guard try await evaluateCondition(step.condition, context: currentExecution.context) else {
                    // Skip step if condition not met
                    let skippedResult = ActionResult(status: .skipped)
                    await stateManager.addStepResult(currentExecution.id, stepId: step.id, result: skippedResult)
                    continue
                }
                
                // Execute step with retry logic
                let stepResult = try await executeStepWithRetry(
                    step,
                    context: currentExecution.context,
                    executionId: currentExecution.id
                )
                
                // Store result
                await stateManager.addStepResult(currentExecution.id, stepId: step.id, result: stepResult)
                
                // Update context with results
                var updatedContext = currentExecution.context
                updatedContext.updateVariables(from: stepResult)
                await stateManager.updateContext(currentExecution.id, context: updatedContext)
                currentExecution.context = updatedContext
                
                // Handle step result
                try await handleStepResult(
                    step: step,
                    result: stepResult,
                    execution: currentExecution
                )
            }
            
            // Mark as completed
            currentExecution.status = .completed
            currentExecution.endTime = Date()
            await stateManager.updateExecution(currentExecution)
            
            return WorkflowResult(execution: currentExecution)
            
        } catch {
            // Handle workflow error
            currentExecution.status = .failed
            currentExecution.endTime = Date()
            
            let executionError = ExecutionError(
                error: error,
                recoveryAttempted: false,
                recovered: false
            )
            await stateManager.addError(currentExecution.id, error: executionError)
            await stateManager.updateExecution(currentExecution)
            
            throw error
        }
    }
    
    /// Execute a step with retry logic and exponential backoff
    private func executeStepWithRetry(
        _ step: WorkflowStep,
        context: ExecutionContext,
        executionId: UUID
    ) async throws -> ActionResult {
        // Convert WorkflowRetryPolicy to RetryPolicy
        let workflowPolicy = step.retryPolicy ?? WorkflowRetryPolicy()
        let retryPolicy = convertToRetryPolicy(workflowPolicy)
        
        // Create retry executor
        let executor = RetryExecutor(policy: retryPolicy)
        
        // Execute with retry logic
        do {
            let result = try await executor.execute {
                // Log retry attempt if not first attempt
                let history = await executor.getAttemptHistory()
                if !history.isEmpty {
                    let attempt = history.count
                    RetryLogger.logAttempt(
                        attemptNumber: attempt,
                        maxAttempts: retryPolicy.maxAttempts,
                        operation: step.name
                    )
                }
                
                // Execute with timeout if specified
                if let timeout = step.timeout {
                    return try await self.withTimeout(timeout) {
                        try await self.executeStep(step, context: context)
                    }
                } else {
                    return try await self.executeStep(step, context: context)
                }
            }
            
            // Get retry statistics
            let stats = await executor.getRetryStatistics()
            
            // Add retry metadata to result if there were retries
            if stats.totalAttempts > 1 {
                var resultWithRetryInfo = result
                resultWithRetryInfo.metadata["retry_attempts"] = "\(stats.totalAttempts - 1)"
                resultWithRetryInfo.metadata["retry_success"] = "true"
                resultWithRetryInfo.metadata["total_execution_time"] = String(format: "%.3f", stats.totalExecutionTime)
                resultWithRetryInfo.metadata["total_delay_time"] = String(format: "%.3f", stats.totalDelayTime)
                
                // Log success with retry info
                RetryLogger.logSuccess(
                    attemptNumber: stats.totalAttempts - 1,
                    duration: stats.totalExecutionTime
                )
                
                return resultWithRetryInfo
            }
            
            return result
            
        } catch let error as RetryError {
            // Handle retry-specific errors
            let stats = await executor.getRetryStatistics()
            
            // Log retry statistics
            RetryLogger.logStatistics(stats)
            
            // Return failure result with comprehensive retry information
            let history = await executor.getAttemptHistory()
            return ActionResult(
                status: .failure,
                error: error.localizedDescription,
                metadata: [
                    "retry_attempts": "\(stats.totalAttempts)",
                    "retry_exhausted": "true",
                    "backoff_strategy": retryPolicy.backoffStrategy.rawValue,
                    "total_execution_time": String(format: "%.3f", stats.totalExecutionTime),
                    "total_delay_time": String(format: "%.3f", stats.totalDelayTime),
                    "success_rate": String(format: "%.2f", stats.successRate),
                    "final_error": history.last?.error?.localizedDescription ?? "Unknown"
                ]
            )
            
        } catch {
            // Handle unexpected errors
            return ActionResult(
                status: .failure,
                error: error.localizedDescription,
                metadata: ["unexpected_error": "true"]
            )
        }
    }
    
    /// Convert WorkflowRetryPolicy to AutomationRetryPolicy
    private func convertToRetryPolicy(_ workflowPolicy: WorkflowRetryPolicy) -> AutomationRetryPolicy {
        let backoffStrategy: AutomationBackoffStrategy
        switch workflowPolicy.backoffStrategy {
        case .fixed:
            backoffStrategy = .fixed
        case .exponential:
            backoffStrategy = .exponential
        case .linear:
            backoffStrategy = .linear
        }
        
        return AutomationRetryPolicy(
            maxAttempts: workflowPolicy.maxAttempts,
            backoffStrategy: backoffStrategy,
            retryableErrors: workflowPolicy.retryableErrors
        )
    }
    
    /// Execute a single step with variable substitution
    private func executeStep(_ step: WorkflowStep, context: ExecutionContext) async throws -> ActionResult {
        let startTime = Date()
        
        // Perform variable substitution on the action
        let substitutedAction = substituteVariables(in: step.action, context: context)
        
        // Execute based on action type
        let result: ActionResult
        
        switch substitutedAction {
        case .command(let commandAction):
            result = try await executeCommandAction(commandAction, context: context)
        case .dataPipeline(let pipelineAction):
            result = try await executeDataPipelineAction(pipelineAction, context: context)
        case .aiQuery(let aiAction):
            result = try await executeAIQueryAction(aiAction, context: context)
        case .test(let testAction):
            result = try await executeTestAction(testAction, context: context)
        case .deploy(let deployAction):
            result = try await executeDeployAction(deployAction, context: context)
        case .macro(let macroAction):
            result = try await executeMacroAction(macroAction, context: context)
        case .custom(let customAction):
            result = try await executeCustomAction(customAction, context: context)
        }
        
        // Add duration
        var finalResult = result
        finalResult.duration = Date().timeIntervalSince(startTime)
        
        return finalResult
    }
    
    /// Substitute variables in action parameters
    private func substituteVariables(in action: WorkflowAction, context: ExecutionContext) -> WorkflowAction {
        switch action {
        case .command(var commandAction):
            commandAction.parameters = substituteVariablesInDictionary(commandAction.parameters, context: context)
            if let pattern = substituteVariablesInString(commandAction.pattern, context: context) {
                commandAction.pattern = pattern
            }
            return .command(commandAction)
            
        case .dataPipeline(var pipelineAction):
            // Substitute in pipeline config
            return .dataPipeline(pipelineAction)
            
        case .aiQuery(var aiAction):
            if let query = substituteVariablesInString(aiAction.query, context: context) {
                aiAction.query = query
            }
            aiAction.context.userPreferences = substituteVariablesInDictionary(aiAction.context.userPreferences, context: context)
            return .aiQuery(aiAction)
            
        case .test(let testAction):
            return .test(testAction)
            
        case .deploy(var deployAction):
            deployAction.config = substituteVariablesInDictionary(deployAction.config, context: context)
            if let target = substituteVariablesInString(deployAction.target, context: context) {
                deployAction.target = target
            }
            if let environment = substituteVariablesInString(deployAction.environment, context: context) {
                deployAction.environment = environment
            }
            return .deploy(deployAction)
            
        case .macro(var macroAction):
            macroAction.parameters = substituteVariablesInDictionary(macroAction.parameters, context: context)
            return .macro(macroAction)
            
        case .custom(var customAction):
            customAction.parameters = substituteVariablesInDictionary(customAction.parameters, context: context)
            return .custom(customAction)
        }
    }
    
    /// Substitute variables in a dictionary
    private func substituteVariablesInDictionary(_ dict: [String: String], context: ExecutionContext) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = substituteVariablesInString(value, context: context) ?? value
        }
        return result
    }
    
    /// Substitute variables in a string using ${variable_name} syntax
    private func substituteVariablesInString(_ string: String, context: ExecutionContext) -> String? {
        var result = string
        var hasSubstitution = false
        
        // Find all ${variable_name} patterns
        let pattern = "\\$\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        
        // Replace in reverse order to maintain string indices
        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: string) else { continue }
            let variableName = String(string[range])
            
            if let value = context.variables[variableName] {
                guard let fullRange = Range(match.range, in: string) else { continue }
                result.replaceSubrange(fullRange, with: value)
                hasSubstitution = true
            }
        }
        
        return hasSubstitution ? result : nil
    }
    
    /// Handle the result of a step execution and execute branching logic
    private func handleStepResult(
        step: WorkflowStep,
        result: ActionResult,
        execution: WorkflowExecution
    ) async throws {
        switch result.status {
        case .success:
            // Execute onSuccess branch if defined
            if let successStepIds = step.onSuccessStepIds, !successStepIds.isEmpty {
                try await executeBranch(successStepIds, execution: execution)
            }
            
        case .failure:
            // Execute onFailure branch if defined
            if let failureStepIds = step.onFailureStepIds, !failureStepIds.isEmpty {
                try await executeBranch(failureStepIds, execution: execution)
            } else if execution.workflow.errorHandling == .stopOnError {
                // Stop execution on error if no failure branch
                throw AutomationError.stepFailed(stepName: step.name, error: NSError(domain: "StepFailed", code: -1))
            }
            
        case .timeout:
            // Handle timeout - treat as failure
            if let failureStepIds = step.onFailureStepIds, !failureStepIds.isEmpty {
                try await executeBranch(failureStepIds, execution: execution)
            } else if execution.workflow.errorHandling == .stopOnError {
                throw AutomationError.executionTimeout
            }
            
        case .skipped:
            // Continue to next step
            break
        }
    }
    
    /// Execute a branch of steps (onSuccess or onFailure)
    private func executeBranch(_ stepIds: [UUID], execution: WorkflowExecution) async throws {
        var currentExecution = execution
        
        for stepId in stepIds {
            // Find the step by ID
            guard let step = currentExecution.workflow.steps.first(where: { $0.id == stepId }) else {
                continue
            }
            
            // Check if paused
            await checkPauseState(currentExecution.id)
            
            // Update current step
            await stateManager.updateCurrentStep(currentExecution.id, stepId: step.id)
            
            // Evaluate condition
            guard try await evaluateCondition(step.condition, context: currentExecution.context) else {
                let skippedResult = ActionResult(status: .skipped)
                await stateManager.addStepResult(currentExecution.id, stepId: step.id, result: skippedResult)
                continue
            }
            
            // Execute step with retry logic
            let stepResult = try await executeStepWithRetry(
                step,
                context: currentExecution.context,
                executionId: currentExecution.id
            )
            
            // Store result
            await stateManager.addStepResult(currentExecution.id, stepId: step.id, result: stepResult)
            
            // Update context with results
            var updatedContext = currentExecution.context
            updatedContext.updateVariables(from: stepResult)
            await stateManager.updateContext(currentExecution.id, context: updatedContext)
            currentExecution.context = updatedContext
            
            // Recursively handle nested branches
            try await handleStepResult(
                step: step,
                result: stepResult,
                execution: currentExecution
            )
        }
    }
    
    // MARK: - Condition Evaluation
    
    /// Evaluate a workflow condition
    private func evaluateCondition(_ condition: WorkflowCondition?, context: ExecutionContext) async throws -> Bool {
        guard let condition = condition else {
            return true // No condition means always execute
        }
        
        switch condition.type {
        case .always:
            return true
            
        case .ifSuccess:
            return context.variables["last_status"] == "success"
            
        case .ifFailure:
            return context.variables["last_status"] == "failure"
            
        case .ifVariable:
            // Evaluate variable expression
            return evaluateVariableExpression(condition.expression, variables: context.variables)
            
        case .custom:
            // Custom condition evaluation
            return try await evaluateCustomCondition(condition.expression, context: context)
        }
    }
    
    private func evaluateVariableExpression(_ expression: String, variables: [String: String]) -> Bool {
        // Variable expression evaluation
        // Supported formats:
        // - "variable_name == value"
        // - "variable_name != value"
        // - "variable_name contains value"
        // - "variable_name > value" (numeric comparison)
        // - "variable_name < value" (numeric comparison)
        // - "variable_name exists"
        // - "variable_name empty"
        
        let components = expression.split(separator: " ").map(String.init)
        
        guard !components.isEmpty else { return false }
        
        let variableName = components[0]
        
        // Handle single-word conditions
        if components.count == 2 {
            let condition = components[1]
            switch condition {
            case "exists":
                return variables[variableName] != nil
            case "empty":
                return variables[variableName]?.isEmpty ?? true
            default:
                return false
            }
        }
        
        guard components.count >= 3 else { return false }
        
        let operator_ = components[1]
        let expectedValue = components[2...].joined(separator: " ")
        
        guard let actualValue = variables[variableName] else { return false }
        
        switch operator_ {
        case "==":
            return actualValue == expectedValue
        case "!=":
            return actualValue != expectedValue
        case "contains":
            return actualValue.contains(expectedValue)
        case ">":
            // Numeric comparison
            if let actual = Double(actualValue), let expected = Double(expectedValue) {
                return actual > expected
            }
            return false
        case "<":
            // Numeric comparison
            if let actual = Double(actualValue), let expected = Double(expectedValue) {
                return actual < expected
            }
            return false
        case ">=":
            // Numeric comparison
            if let actual = Double(actualValue), let expected = Double(expectedValue) {
                return actual >= expected
            }
            return false
        case "<=":
            // Numeric comparison
            if let actual = Double(actualValue), let expected = Double(expectedValue) {
                return actual <= expected
            }
            return false
        default:
            return false
        }
    }
    
    private func evaluateCustomCondition(_ expression: String, context: ExecutionContext) async throws -> Bool {
        // Placeholder for custom condition evaluation
        // This would integrate with a scripting engine or custom evaluator
        return true
    }
    
    // MARK: - Action Execution Implementations
    
    private func executeCommandAction(_ action: CommandAction, context: ExecutionContext) async throws -> ActionResult {
        // Execute command using TerminalService
        do {
            let result = try await terminalService.execute(
                pattern: action.pattern,
                parameters: action.parameters,
                projectDirectory: action.workingDirectory
            )
            
            // Capture output into variables if specified
            var outputVariables: [String: String] = [:]
            if let outputVar = action.outputVariable {
                outputVariables[outputVar] = result.stdout
            }
            outputVariables["exit_code"] = "\(result.exitCode)"
            outputVariables["stderr"] = result.stderr
            
            // Return success or failure based on exit code
            if result.isSuccess {
                return ActionResult(
                    status: .success,
                    output: result.stdout,
                    metadata: [
                        "exit_code": "\(result.exitCode)",
                        "duration": result.formattedDuration
                    ]
                )
            } else {
                return ActionResult(
                    status: .failure,
                    error: "Command failed with exit code \(result.exitCode): \(result.stderr)",
                    metadata: [
                        "exit_code": "\(result.exitCode)",
                        "duration": result.formattedDuration
                    ]
                )
            }
        } catch {
            return ActionResult(
                status: .failure,
                error: "Command execution failed: \(error.localizedDescription)"
            )
        }
    }
    
    private func executeDataPipelineAction(_ action: DataPipelineAction, context: ExecutionContext) async throws -> ActionResult {
        // Placeholder - will be implemented by DataPipelineEngine
        return ActionResult(status: .success, output: "Pipeline executed")
    }
    
    private func executeAIQueryAction(_ action: AIQueryAction, context: ExecutionContext) async throws -> ActionResult {
        // Placeholder - will be implemented by AIAutomationEngine
        return ActionResult(status: .success, output: "AI query executed")
    }
    
    private func executeTestAction(_ action: TestAction, context: ExecutionContext) async throws -> ActionResult {
        // Placeholder - will be implemented by TestingAutomationEngine
        return ActionResult(status: .success, output: "Tests executed")
    }
    
    private func executeDeployAction(_ action: DeployAction, context: ExecutionContext) async throws -> ActionResult {
        // Placeholder - will be implemented by DeploymentAutomationEngine
        return ActionResult(status: .success, output: "Deployment executed")
    }
    
    private func executeMacroAction(_ action: MacroAction, context: ExecutionContext) async throws -> ActionResult {
        // Placeholder - will be implemented by MacroAutomationEngine
        return ActionResult(status: .success, output: "Macro executed")
    }
    
    private func executeCustomAction(_ action: CustomAction, context: ExecutionContext) async throws -> ActionResult {
        // Placeholder for custom action execution
        return ActionResult(status: .success, output: "Custom action executed")
    }
    
    // MARK: - Pause/Resume Support
    
    /// Check if execution is paused and wait if necessary
    private func checkPauseState(_ executionId: UUID) async {
        while pauseFlags[executionId] == true {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    /// Pause an execution
    func pause(_ executionId: UUID) async {
        pauseFlags[executionId] = true
        await stateManager.pauseExecution(executionId)
    }
    
    /// Resume an execution
    func resume(_ executionId: UUID) async {
        pauseFlags[executionId] = false
        await stateManager.resumeExecution(executionId)
    }
    
    // MARK: - Helper Methods
    
    private func validateWorkflow(_ workflow: Workflow) throws {
        guard !workflow.steps.isEmpty else {
            throw AutomationError.invalidWorkflow("Workflow must have at least one step")
        }
        
        guard !workflow.name.isEmpty else {
            throw AutomationError.invalidWorkflow("Workflow must have a name")
        }
    }
    

    
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the operation task
            group.addTask { [self] in
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AutomationError.executionTimeout
            }
            
            // Return first result (either completion or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

