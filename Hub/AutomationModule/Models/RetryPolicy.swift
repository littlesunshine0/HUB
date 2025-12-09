//
//  RetryPolicy.swift
//  Hub
//
//  Retry policy configuration and execution wrapper for the Hub Automation System
//  Implements exponential backoff with configurable strategies
//

import Foundation

// MARK: - Automation Retry Policy Configuration

/// Configuration for retry behavior with exponential backoff for automation workflows
struct AutomationRetryPolicy: Codable, Equatable {
    /// Maximum number of retry attempts (including initial attempt)
    var maxAttempts: Int
    
    /// Backoff strategy to use between retries
    var backoffStrategy: AutomationBackoffStrategy
    
    /// Base delay in seconds for backoff calculation
    var baseDelay: TimeInterval
    
    /// Maximum delay in seconds to cap exponential growth
    var maxDelay: TimeInterval
    
    /// Multiplier for exponential backoff (default 2.0 for doubling)
    var backoffMultiplier: Double
    
    /// Jitter factor (0.0 to 1.0) to add randomness to delays
    var jitterFactor: Double
    
    /// List of error types that should trigger a retry
    var retryableErrors: [String]
    
    /// Whether to retry on timeout errors
    var retryOnTimeout: Bool
    
    /// Whether to retry on network errors
    var retryOnNetworkError: Bool
    
    init(
        maxAttempts: Int = 3,
        backoffStrategy: AutomationBackoffStrategy = .exponential,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        backoffMultiplier: Double = 2.0,
        jitterFactor: Double = 0.1,
        retryableErrors: [String] = [],
        retryOnTimeout: Bool = true,
        retryOnNetworkError: Bool = true
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.backoffStrategy = backoffStrategy
        self.baseDelay = max(0.1, baseDelay)
        self.maxDelay = max(baseDelay, maxDelay)
        self.backoffMultiplier = max(1.0, backoffMultiplier)
        self.jitterFactor = min(1.0, max(0.0, jitterFactor))
        self.retryableErrors = retryableErrors
        self.retryOnTimeout = retryOnTimeout
        self.retryOnNetworkError = retryOnNetworkError
    }
    
    /// Create a policy with no retries
    static var noRetry: AutomationRetryPolicy {
        AutomationRetryPolicy(maxAttempts: 1)
    }
    
    /// Create a policy with aggressive retries (fast, many attempts)
    static var aggressive: AutomationRetryPolicy {
        AutomationRetryPolicy(
            maxAttempts: 5,
            backoffStrategy: .exponential,
            baseDelay: 0.5,
            maxDelay: 30.0,
            backoffMultiplier: 2.0
        )
    }
    
    /// Create a policy with conservative retries (slow, few attempts)
    static var conservative: AutomationRetryPolicy {
        AutomationRetryPolicy(
            maxAttempts: 3,
            backoffStrategy: .exponential,
            baseDelay: 2.0,
            maxDelay: 120.0,
            backoffMultiplier: 3.0
        )
    }
    
    /// Create a policy with linear backoff
    static var linear: AutomationRetryPolicy {
        AutomationRetryPolicy(
            maxAttempts: 3,
            backoffStrategy: .linear,
            baseDelay: 1.0,
            maxDelay: 10.0
        )
    }
    
    /// Create a policy with fixed delay
    static var fixed: AutomationRetryPolicy {
        AutomationRetryPolicy(
            maxAttempts: 3,
            backoffStrategy: .fixed,
            baseDelay: 2.0,
            maxDelay: 2.0
        )
    }
}

// MARK: - Automation Backoff Strategy

/// Strategy for calculating delay between retry attempts in automation workflows
enum AutomationBackoffStrategy: String, Codable, Equatable {
    /// Fixed delay between all retries
    case fixed
    
    /// Exponential growth: delay = baseDelay * (multiplier ^ attempt)
    case exponential
    
    /// Linear growth: delay = baseDelay * (attempt + 1)
    case linear
    
    /// Fibonacci sequence: delay follows Fibonacci pattern
    case fibonacci
    
    /// Decorrelated jitter: AWS recommended approach
    case decorrelatedJitter
}

// MARK: - Retry Execution Wrapper

/// Wrapper for executing operations with retry logic and exponential backoff
actor RetryExecutor {
    
    // MARK: - Properties
    
    private let policy: AutomationRetryPolicy
    private var attemptHistory: [RetryAttemptRecord] = []
    
    // MARK: - Initialization
    
    init(policy: AutomationRetryPolicy = AutomationRetryPolicy()) {
        self.policy = policy
    }
    
    // MARK: - Execution
    
    /// Execute an operation with retry logic
    /// - Parameters:
    ///   - operation: The async operation to execute
    ///   - shouldRetry: Optional custom predicate to determine if error is retryable
    /// - Returns: The result of the successful operation
    /// - Throws: The last error if all retries are exhausted
    func execute<T>(
        operation: @escaping () async throws -> T,
        shouldRetry: ((Error) -> Bool)? = nil
    ) async throws -> T {
        attemptHistory.removeAll()
        var lastError: Error?
        var previousDelay: TimeInterval = 0
        
        for attempt in 0..<policy.maxAttempts {
            let attemptStartTime = Date()
            
            do {
                // Execute the operation
                let result = try await operation()
                
                // Record successful attempt
                let attemptDuration = Date().timeIntervalSince(attemptStartTime)
                let record = RetryAttemptRecord(
                    attemptNumber: attempt,
                    timestamp: attemptStartTime,
                    duration: attemptDuration,
                    success: true,
                    error: nil,
                    delayBeforeAttempt: attempt > 0 ? previousDelay : nil
                )
                attemptHistory.append(record)
                
                return result
                
            } catch {
                lastError = error
                let attemptDuration = Date().timeIntervalSince(attemptStartTime)
                
                // Check if we should retry this error
                let isRetryable = shouldRetry?(error) ?? isErrorRetryable(error)
                
                // Record failed attempt
                let record = RetryAttemptRecord(
                    attemptNumber: attempt,
                    timestamp: attemptStartTime,
                    duration: attemptDuration,
                    success: false,
                    error: error,
                    delayBeforeAttempt: attempt > 0 ? previousDelay : nil
                )
                attemptHistory.append(record)
                
                // Don't retry if error is not retryable
                if !isRetryable {
                    throw RetryError.nonRetryableError(
                        underlyingError: error,
                        attempts: attemptHistory
                    )
                }
                
                // Don't retry on last attempt
                if attempt < policy.maxAttempts - 1 {
                    // Calculate backoff delay
                    let delay = calculateBackoffDelay(
                        attempt: attempt,
                        previousDelay: previousDelay
                    )
                    previousDelay = delay
                    
                    // Wait before retry
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All retries exhausted
        throw RetryError.retriesExhausted(
            underlyingError: lastError ?? RetryError.unknownError,
            attempts: attemptHistory
        )
    }
    
    /// Execute an operation with retry logic and return a Result type
    func executeWithResult<T>(
        operation: @escaping () async throws -> T,
        shouldRetry: ((Error) -> Bool)? = nil
    ) async -> Result<T, Error> {
        do {
            let result = try await execute(operation: operation, shouldRetry: shouldRetry)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Backoff Calculation
    
    /// Calculate the delay before the next retry attempt
    private func calculateBackoffDelay(attempt: Int, previousDelay: TimeInterval) -> TimeInterval {
        let baseDelay = policy.baseDelay
        let maxDelay = policy.maxDelay
        
        var delay: TimeInterval
        
        switch policy.backoffStrategy {
        case .fixed:
            delay = baseDelay
            
        case .exponential:
            // delay = baseDelay * (multiplier ^ attempt)
            delay = baseDelay * pow(policy.backoffMultiplier, Double(attempt))
            
        case .linear:
            // delay = baseDelay * (attempt + 1)
            delay = baseDelay * Double(attempt + 1)
            
        case .fibonacci:
            // Use Fibonacci sequence for delays
            delay = baseDelay * Double(fibonacci(n: attempt + 1))
            
        case .decorrelatedJitter:
            // AWS recommended: delay = random(baseDelay, previousDelay * 3)
            if attempt == 0 {
                delay = baseDelay
            } else {
                let upperBound = min(maxDelay, previousDelay * 3.0)
                delay = TimeInterval.random(in: baseDelay...upperBound)
            }
        }
        
        // Cap at maximum delay
        delay = min(delay, maxDelay)
        
        // Add jitter if configured (except for decorrelatedJitter which has its own randomness)
        if policy.backoffStrategy != .decorrelatedJitter && policy.jitterFactor > 0 {
            delay = addJitter(to: delay, factor: policy.jitterFactor)
        }
        
        return delay
    }
    
    /// Add random jitter to a delay value
    private func addJitter(to delay: TimeInterval, factor: Double) -> TimeInterval {
        let jitterAmount = delay * factor
        let randomJitter = TimeInterval.random(in: -jitterAmount...jitterAmount)
        return max(0.1, delay + randomJitter)
    }
    
    /// Calculate Fibonacci number for backoff
    private func fibonacci(n: Int) -> Int {
        guard n > 0 else { return 0 }
        guard n > 1 else { return 1 }
        
        var a = 0
        var b = 1
        
        for _ in 2...n {
            let temp = a + b
            a = b
            b = temp
        }
        
        return b
    }
    
    // MARK: - Error Classification
    
    /// Determine if an error should trigger a retry
    private func isErrorRetryable(_ error: Error) -> Bool {
        // Check timeout errors
        if policy.retryOnTimeout && isTimeoutError(error) {
            return true
        }
        
        // Check network errors
        if policy.retryOnNetworkError && isNetworkError(error) {
            return true
        }
        
        // Check against configured retryable error types
        if !policy.retryableErrors.isEmpty {
            let errorType = String(describing: type(of: error))
            return policy.retryableErrors.contains(errorType)
        }
        
        // Default: retry on common transient errors
        return isTransientError(error)
    }
    
    /// Check if error is a timeout error
    private func isTimeoutError(_ error: Error) -> Bool {
        if let automationError = error as? AutomationError {
            if case .executionTimeout = automationError {
                return true
            }
        }
        
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut
    }
    
    /// Check if error is a network error
    private func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        // Check for common network error codes
        if nsError.domain == NSURLErrorDomain {
            let networkErrorCodes = [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorCannotFindHost,
                NSURLErrorDNSLookupFailed
            ]
            return networkErrorCodes.contains(nsError.code)
        }
        
        return false
    }
    
    /// Check if error is a transient error that should be retried
    private func isTransientError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        // HTTP 5xx errors are typically transient
        if nsError.domain == NSURLErrorDomain {
            let httpCode = nsError.userInfo["HTTPStatusCode"] as? Int ?? 0
            return httpCode >= 500 && httpCode < 600
        }
        
        // Check for common transient error patterns
        let errorDescription = error.localizedDescription.lowercased()
        let transientPatterns = [
            "timeout",
            "connection",
            "network",
            "unavailable",
            "busy",
            "overloaded",
            "rate limit"
        ]
        
        return transientPatterns.contains { errorDescription.contains($0) }
    }
    
    // MARK: - Attempt History
    
    /// Get the history of retry attempts
    func getAttemptHistory() -> [RetryAttemptRecord] {
        return attemptHistory
    }
    
    /// Get statistics about retry attempts
    func getRetryStatistics() -> RetryStatistics {
        let totalAttempts = attemptHistory.count
        let successfulAttempts = attemptHistory.filter { $0.success }.count
        let failedAttempts = attemptHistory.filter { !$0.success }.count
        let totalDuration = attemptHistory.reduce(0.0) { $0 + $1.duration }
        let totalDelayTime = attemptHistory.compactMap { $0.delayBeforeAttempt }.reduce(0.0, +)
        
        return RetryStatistics(
            totalAttempts: totalAttempts,
            successfulAttempts: successfulAttempts,
            failedAttempts: failedAttempts,
            totalExecutionTime: totalDuration,
            totalDelayTime: totalDelayTime,
            finalSuccess: attemptHistory.last?.success ?? false
        )
    }
}

// MARK: - Retry Attempt Record

/// Record of a single retry attempt with detailed information
struct RetryAttemptRecord: Identifiable {
    let id: UUID
    let attemptNumber: Int
    let timestamp: Date
    let duration: TimeInterval
    let success: Bool
    let error: Error?
    let delayBeforeAttempt: TimeInterval?
    
    init(
        id: UUID = UUID(),
        attemptNumber: Int,
        timestamp: Date,
        duration: TimeInterval,
        success: Bool,
        error: Error?,
        delayBeforeAttempt: TimeInterval?
    ) {
        self.id = id
        self.attemptNumber = attemptNumber
        self.timestamp = timestamp
        self.duration = duration
        self.success = success
        self.error = error
        self.delayBeforeAttempt = delayBeforeAttempt
    }
}

// MARK: - Retry Statistics

/// Statistics about retry execution
struct RetryStatistics {
    let totalAttempts: Int
    let successfulAttempts: Int
    let failedAttempts: Int
    let totalExecutionTime: TimeInterval
    let totalDelayTime: TimeInterval
    let finalSuccess: Bool
    
    var averageExecutionTime: TimeInterval {
        guard totalAttempts > 0 else { return 0 }
        return totalExecutionTime / Double(totalAttempts)
    }
    
    var successRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(successfulAttempts) / Double(totalAttempts)
    }
}

// MARK: - Retry Error

/// Errors specific to retry execution
enum RetryError: Error, LocalizedError {
    case retriesExhausted(underlyingError: Error, attempts: [RetryAttemptRecord])
    case nonRetryableError(underlyingError: Error, attempts: [RetryAttemptRecord])
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .retriesExhausted(let error, let attempts):
            return "All \(attempts.count) retry attempts exhausted. Last error: \(error.localizedDescription)"
        case .nonRetryableError(let error, let attempts):
            return "Non-retryable error after \(attempts.count) attempts: \(error.localizedDescription)"
        case .unknownError:
            return "Unknown error occurred during retry execution"
        }
    }
}

// MARK: - Retry Logger

/// Logger for retry attempts and backoff behavior
struct RetryLogger {
    
    static func logAttempt(
        attemptNumber: Int,
        maxAttempts: Int,
        operation: String
    ) {
        print("🔄 Retry attempt \(attemptNumber + 1)/\(maxAttempts) for operation: \(operation)")
    }
    
    static func logBackoff(
        delay: TimeInterval,
        strategy: AutomationBackoffStrategy,
        attemptNumber: Int
    ) {
        let formattedDelay = String(format: "%.2f", delay)
        print("⏱️  Backing off for \(formattedDelay)s using \(strategy.rawValue) strategy (attempt \(attemptNumber + 1))")
    }
    
    static func logSuccess(
        attemptNumber: Int,
        duration: TimeInterval
    ) {
        let formattedDuration = String(format: "%.3f", duration)
        if attemptNumber > 0 {
            print("✅ Operation succeeded on attempt \(attemptNumber + 1) after \(formattedDuration)s")
        } else {
            print("✅ Operation succeeded on first attempt after \(formattedDuration)s")
        }
    }
    
    static func logFailure(
        attemptNumber: Int,
        error: Error,
        willRetry: Bool
    ) {
        if willRetry {
            print("❌ Attempt \(attemptNumber + 1) failed: \(error.localizedDescription) - will retry")
        } else {
            print("🚫 Attempt \(attemptNumber + 1) failed: \(error.localizedDescription) - no more retries")
        }
    }
    
    static func logNonRetryable(error: Error) {
        print("⛔️ Non-retryable error: \(error.localizedDescription)")
    }
    
    static func logStatistics(_ stats: RetryStatistics) {
        print("📊 Retry Statistics:")
        print("   Total attempts: \(stats.totalAttempts)")
        print("   Successful: \(stats.successfulAttempts)")
        print("   Failed: \(stats.failedAttempts)")
        print("   Total execution time: \(String(format: "%.3f", stats.totalExecutionTime))s")
        print("   Total delay time: \(String(format: "%.3f", stats.totalDelayTime))s")
        print("   Average execution time: \(String(format: "%.3f", stats.averageExecutionTime))s")
        print("   Success rate: \(String(format: "%.1f", stats.successRate * 100))%")
        print("   Final result: \(stats.finalSuccess ? "✅ Success" : "❌ Failed")")
    }
}

