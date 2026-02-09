import Foundation

/// Configuration for service resilience features
public struct ServiceConfig {
    /// Timeout for individual operations (seconds)
    public let operationTimeout: TimeInterval

    /// Maximum retry attempts for failed operations
    public let maxRetryAttempts: Int

    /// Initial backoff delay for retry logic (seconds)
    public let initialBackoff: TimeInterval

    /// Maximum backoff delay (seconds)
    public let maxBackoff: TimeInterval

    /// Whether to enable verbose logging
    public let verboseLogging: Bool

    public init(
        operationTimeout: TimeInterval = 60.0,
        maxRetryAttempts: Int = 3,
        initialBackoff: TimeInterval = 1.0,
        maxBackoff: TimeInterval = 30.0,
        verboseLogging: Bool = false
    ) {
        self.operationTimeout = operationTimeout
        self.maxRetryAttempts = maxRetryAttempts
        self.initialBackoff = initialBackoff
        self.maxBackoff = maxBackoff
        self.verboseLogging = verboseLogging
    }

    public static let `default` = ServiceConfig()
}

/// Errors that can occur during service operations
public enum ServiceError: Error, LocalizedError {
    case timeout(operation: String)
    case retryExhausted(operation: String, underlyingError: Error)
    case cancelled(operation: String)
    case aiUnavailable(reason: String)
    case invalidInput(message: String)
    case analysisFailure(message: String)

    public var errorDescription: String? {
        switch self {
        case .timeout(let op):
            return
                "Operation '\(op)' timed out. Please try with a smaller code sample or check your connection."
        case .retryExhausted(let op, let error):
            return "Operation '\(op)' failed after multiple attempts: \(error.localizedDescription)"
        case .cancelled(let op):
            return "Operation '\(op)' was cancelled."
        case .aiUnavailable(let reason):
            return "AI service unavailable: \(reason). Falling back to offline analysis."
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .analysisFailure(let message):
            return "Analysis failed: \(message)"
        }
    }
}

/// Circuit breaker to prevent overwhelming failed services
public actor CircuitBreaker {
    public enum State {
        case closed  // Service is healthy
        case open  // Service is failing
        case halfOpen  // Testing if service recovered
    }

    private var state: State = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private let failureThreshold: Int
    private let resetTimeout: TimeInterval

    public init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 60.0) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    public func recordSuccess() {
        state = .closed
        failureCount = 0
        lastFailureTime = nil
    }

    public func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()

        if failureCount >= failureThreshold {
            state = .open
        }
    }

    public func canAttempt() -> Bool {
        switch state {
        case .closed:
            return true
        case .open:
            // Check if enough time has passed to try half-open
            if let lastFailure = lastFailureTime,
                Date().timeIntervalSince(lastFailure) >= resetTimeout
            {
                state = .halfOpen
                return true
            }
            return false
        case .halfOpen:
            return true
        }
    }

    public func getCurrentState() -> State {
        state
    }
}
