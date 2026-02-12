import Foundation
import os

public class OllamaClient {
    public func generate(model: String, prompt: String, temperature: Double) async throws -> String {
        // Stub implementation
        "Stub response from OllamaClient"
    }
}

//
//  CodeReviewService.swift
//  CodingReviewer
//
//  Implementation of code review service with basic analysis
//

/// Service implementation for code review functionality
@MainActor
public class CodeReviewService: CodeReviewServiceProtocol {
    public let serviceId = "code_review_service"
    public let version = "1.0.1" // Updated for resilience features

    private let logger = Logger(
        subsystem: "com.quantum.codingreviewer", category: "CodeReviewService"
    )
    private let config: ServiceConfig
    private let circuitBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 60.0)

    // Analysis engine that can be used from background threads
    private let analysisEngine = CodeAnalysisEngine()
    private var aiService: AIEnhancedCodeAnalysisService?

    public init(config: ServiceConfig = .default) {
        self.config = config
        self.aiService = nil
    }

    /// Preference-backed AI toggle with env fallback
    private var isAIEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "CR_USE_AI") != nil
            || defaults.object(forKey: "CR_USE_OLLAMA") != nil
        {
            return defaults.bool(forKey: "CR_USE_AI") || defaults.bool(forKey: "CR_USE_OLLAMA")
        }
        let env = ProcessInfo.processInfo.environment
        return env["CR_USE_OLLAMA"] == "1" || env["CR_USE_AI"] == "1"
    }

    private func ensureAIService() {
        if aiService == nil {
            let generator: (String, String, Double) async throws -> String = { model, prompt, temp in
                try await OllamaClient().generate(model: model, prompt: prompt, temperature: temp)
            }
            aiService = AIEnhancedCodeAnalysisService(llmGenerate: generator)
        }
    }

    // MARK: - ServiceProtocol Conformance

    public func initialize() async throws {
        self.logger.info("Initializing CodeReviewService")
    }

    public func cleanup() async {
        self.logger.info("Cleaning up CodeReviewService")
    }

    public func healthCheck() async -> ServiceHealthStatus {
        .healthy
    }

    // MARK: - CodeReviewServiceProtocol Conformance

    public func analyzeCode(_ code: String, language: String, analysisType: AnalysisType)
        async throws -> CodeAnalysisResult
    {
        // Input validation
        guard !code.isEmpty else {
            throw ServiceError.invalidInput(message: "Code cannot be empty")
        }

        guard code.count < 500_000 else { // 500KB limit
            throw ServiceError.invalidInput(message: "Code size exceeds maximum limit (500KB)")
        }

        logger.info(
            "Analyzing code - Language: \(language), Type: \(analysisType.rawValue), Size: \(code.count) chars"
        )

        if isAIEnabled {
            // Try AI analysis with retry and timeout
            do {
                return try await withRetry(operation: "analyzeCode") {
                    try await self.analyzeWithAI(
                        code: code, language: language, analysisType: analysisType
                    )
                }
            } catch let error as ServiceError {
                logger.warning(
                    "AI analysis failed: \(error.localizedDescription). Falling back to offline mode."
                )
                // Fall through to offline analysis
            } catch {
                logger.warning(
                    "Unexpected AI error: \(error.localizedDescription). Falling back to offline mode."
                )
                // Fall through to offline analysis
            }
        }

        return try await fallbackAnalyze(code: code, language: language, analysisType: analysisType)
    }

    // MARK: - AI Analysis with Timeout

    private func analyzeWithAI(code: String, language: String, analysisType: AnalysisType)
        async throws -> CodeAnalysisResult
    {
        // Check circuit breaker
        guard await circuitBreaker.canAttempt() else {
            throw ServiceError.aiUnavailable(
                reason: "Circuit breaker is open (too many recent failures)"
            )
        }

        ensureAIService()
        guard let aiService else {
            await circuitBreaker.recordFailure()
            throw ServiceError.aiUnavailable(reason: "AI service initialization failed")
        }

        // Apply timeout
        let result = try await withTimeout(seconds: config.operationTimeout) {
            try await aiService.analyzeCodeWithAI(code, language: language)
        }

        // Record success in circuit breaker
        await circuitBreaker.recordSuccess()

        // Convert AI result to CodeAnalysisResult
        var issues: [CodeIssue] = []

        for secIssue in result.securityIssues {
            issues.append(
                CodeIssue(
                    description: secIssue.description,
                    severity: Self.mapSeverity(secIssue.severity),
                    line: nil,
                    category: .security
                )
            )
        }

        for perfIssue in result.performanceIssues {
            let sev: IssueSeverity =
                (perfIssue.impact == .high ? .high : (perfIssue.impact == .medium ? .medium : .low))
            issues.append(
                CodeIssue(
                    description: perfIssue.description,
                    severity: sev,
                    line: nil,
                    category: .performance
                )
            )
        }

        for bestPractice in result.bestPracticeViolations {
            issues.append(
                CodeIssue(
                    description: bestPractice.violation,
                    severity: .medium,
                    line: nil,
                    category: .style
                )
            )
        }

        let summary =
            "AI Quality: \(result.qualityScore)/10 • "
                + "Security: \(result.securityIssues.count) • "
                + "Performance: \(result.performanceIssues.count) • "
                + "Style: \(result.bestPracticeViolations.count)"

        return CodeAnalysisResult(
            analysis: summary,
            issues: issues,
            suggestions: result.recommendations,
            language: language,
            analysisType: analysisType
        )
    }

    public func generateDocumentation(_ code: String, language: String, includeExamples: Bool)
        async throws -> DocumentationResult
    {
        self.logger.info("Generating documentation - Language: \(language)")

        if isAIEnabled {
            ensureAIService()
            if let aiService {
                let doc = try await aiService.generateDocumentationWithAI(
                    code, documentationType: includeExamples ? .comprehensive : .inline
                )
                return DocumentationResult(
                    documentation: doc.generatedDocumentation, language: language,
                    includesExamples: includeExamples
                )
            }
        }

        return await Task.detached(priority: .userInitiated) {
            let documentation = self.analysisEngine.generateBasicDocumentation(
                code: code,
                language: language,
                includeExamples: includeExamples
            )
            return DocumentationResult(
                documentation: documentation, language: language, includesExamples: includeExamples
            )
        }.value
    }

    public func generateTests(_ code: String, language: String, testFramework: String) async throws
        -> TestGenerationResult
    {
        self.logger.info("Generating tests - Language: \(language), Framework: \(testFramework)")

        if isAIEnabled {
            ensureAIService()
            if let aiService {
                let aiTests = try await aiService.generateTestsWithAI(code, testType: .unit)
                return TestGenerationResult(
                    testCode: aiTests.generatedTests,
                    language: language,
                    testFramework: testFramework,
                    estimatedCoverage: Double(aiTests.estimatedCoverage)
                )
            }
        }

        return await Task.detached(priority: .userInitiated) {
            let testCode = self.analysisEngine.generateBasicTests(
                code: code, language: language, testFramework: testFramework
            )
            let estimatedCoverage = self.analysisEngine.estimateTestCoverage(
                code: code, testCode: testCode
            )
            return TestGenerationResult(
                testCode: testCode, language: language, testFramework: testFramework,
                estimatedCoverage: estimatedCoverage
            )
        }.value
    }

    private static func mapSeverity(_ severity: Severity) -> IssueSeverity {
        switch severity {
        case .high: .high
        case .medium: .medium
        case .low: .low
        }
    }

    public func trackReviewProgress(_ reviewId: UUID) async throws {
        self.logger.info("Tracking review progress for ID: \(reviewId)")
        // Basic implementation - could be enhanced with persistence
    }

    // MARK: - Fallback helpers

    private func fallbackAnalyze(code: String, language: String, analysisType: AnalysisType)
        async throws -> CodeAnalysisResult
    {
        logger.info("Using offline (non-AI) analysis")

        return try await withTimeout(seconds: config.operationTimeout) {
            await Task.detached(priority: .userInitiated) {
                let issues = self.analysisEngine.performBasicAnalysis(
                    code: code, language: language, analysisType: analysisType
                )
                let suggestions = self.analysisEngine.generateSuggestions(
                    code: code, language: language, analysisType: analysisType
                )
                let analysis = self.analysisEngine.generateAnalysisSummary(
                    issues: issues, suggestions: suggestions, analysisType: analysisType
                )
                return CodeAnalysisResult(
                    analysis: analysis,
                    issues: issues,
                    suggestions: suggestions,
                    language: language,
                    analysisType: analysisType
                )
            }.value
        }
    }

    // MARK: - Retry Logic with Exponential Backoff

    private func withRetry<T>(
        operation: String, maxAttempts: Int? = nil, body: @escaping () async throws -> T
    ) async throws -> T {
        let attempts = maxAttempts ?? config.maxRetryAttempts
        var lastError: Error?

        for attempt in 1...attempts {
            // Check for cancellation
            if Task.isCancelled {
                throw ServiceError.cancelled(operation: operation)
            }

            do {
                if config.verboseLogging {
                    logger.debug("Attempt \(attempt)/\(attempts) for operation: \(operation)")
                }
                return try await body()
            } catch {
                lastError = error
                await circuitBreaker.recordFailure()

                if attempt < attempts {
                    // Calculate exponential backoff with jitter
                    let backoff = min(
                        config.initialBackoff * pow(2.0, Double(attempt - 1)),
                        config.maxBackoff
                    )
                    let jitter = Double.random(in: 0...0.1) * backoff
                    let delay = backoff + jitter

                    // swiftlint:disable line_length
                    logger
                        .warning(
                            "'\(operation)' failed (\(attempt)/\(attempts)): \(error.localizedDescription). Retry \(String(format: "%.1f", delay))s"
                        )
                    // swiftlint:enable line_length

                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    logger.error("Operation '\(operation)' failed after \(attempts) attempts")
                }
            }
        }

        throw ServiceError.retryExhausted(
            operation: operation,
            underlyingError: lastError ?? NSError(domain: "UnknownError", code: -1)
        )
    }

    // MARK: - Timeout Wrapper

    private func withTimeout<T: Sendable>(seconds: TimeInterval, body: @escaping () async throws -> T)
        async throws -> T
    {
        // Simple timeout implementation without complex concurrency
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw ServiceError.timeout(operation: "operation")
        }

        let operationTask = Task {
            try await body()
        }

        do {
            let result = try await operationTask.value
            timeoutTask.cancel()
            return result
        } catch {
            timeoutTask.cancel()
            throw error
        }
    }
}
