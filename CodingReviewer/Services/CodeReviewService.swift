class OllamaClient {
    func generate(model: String, prompt: String, temperature: Double) async throws -> String {
        // Stub implementation
        return "Stub response from OllamaClient" 
    }
}


//
//  CodeReviewService.swift
//  CodingReviewer
//
//  Implementation of code review service with basic analysis
//

import Foundation
import os

/// Service implementation for code review functionality
@MainActor
public class CodeReviewService: CodeReviewServiceProtocol {
    public let serviceId = "code_review_service"
    public let version = "1.0.0"

    private let logger = Logger(subsystem: "com.quantum.codingreviewer", category: "CodeReviewService")

    // Analysis engine that can be used from background threads
    private let analysisEngine = CodeAnalysisEngine()
    private var aiService: AIEnhancedCodeAnalysisService?

    public init() {
        // Initialize service; AI is created lazily when enabled via settings
        self.aiService = nil
    }

    // Preference-backed AI toggle with env fallback
    private var isAIEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "CR_USE_AI") != nil || defaults.object(forKey: "CR_USE_OLLAMA") != nil {
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

    public func healthCheck() async -> ServiceHealthStatus { .healthy }

    // MARK: - CodeReviewServiceProtocol Conformance

    public func analyzeCode(_ code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult {
        self.logger.info("Analyzing code - Language: \(language), Type: \(analysisType.rawValue)")

        if isAIEnabled {
            ensureAIService()
            if let aiService {
                let aiResult = try await aiService.analyzeCodeWithAI(code, language: language)
                var issues: [CodeIssue] = []
                for secIssue in aiResult.securityIssues {
                    issues.append(CodeIssue(
                        description: secIssue.description,
                        severity: Self.mapSeverity(secIssue.severity),
                        line: nil,
                        category: .security
                    ))
                }
                for perfIssue in aiResult.performanceIssues {
                    let sev: IssueSeverity = (perfIssue.impact == .high ? .high : (perfIssue.impact == .medium ? .medium : .low))
                    issues.append(CodeIssue(
                        description: perfIssue.description,
                        severity: sev,
                        line: nil,
                        category: .performance
                    ))
                }
                for bestPractice in aiResult.bestPracticeViolations {
                    issues.append(CodeIssue(
                        description: bestPractice.violation,
                        severity: .medium,
                        line: nil,
                        category: .style
                    ))
                }
                let suggestions = aiResult.recommendations
                let summary = "AI Quality: \(aiResult.qualityScore)/10 • " +
                    "Security: \(aiResult.securityIssues.count) • " +
                    "Performance: \(aiResult.performanceIssues.count) • " +
                    "Style: \(aiResult.bestPracticeViolations.count)"
                return CodeAnalysisResult(
                    analysis: summary,
                    issues: issues,
                    suggestions: suggestions,
                    language: language,
                    analysisType: analysisType
                )
            }
        }

        return try await fallbackAnalyze(code: code, language: language, analysisType: analysisType)
    }

    public func generateDocumentation(_ code: String, language: String, includeExamples: Bool) async throws -> DocumentationResult {
        self.logger.info("Generating documentation - Language: \(language)")

        if isAIEnabled {
            ensureAIService()
            if let aiService {
                let doc = try await aiService.generateDocumentationWithAI(code, documentationType: includeExamples ? .comprehensive : .inline)
                return DocumentationResult(documentation: doc.generatedDocumentation, language: language, includesExamples: includeExamples)
            }
        }

        return try await Task.detached(priority: .userInitiated) {
            let documentation = self.analysisEngine.generateBasicDocumentation(
                code: code,
                language: language,
                includeExamples: includeExamples
            )
            return DocumentationResult(documentation: documentation, language: language, includesExamples: includeExamples)
        }.value
    }

    public func generateTests(_ code: String, language: String, testFramework: String) async throws -> TestGenerationResult {
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

        return try await Task.detached(priority: .userInitiated) {
            let testCode = self.analysisEngine.generateBasicTests(code: code, language: language, testFramework: testFramework)
            let estimatedCoverage = self.analysisEngine.estimateTestCoverage(code: code, testCode: testCode)
            return TestGenerationResult(testCode: testCode, language: language, testFramework: testFramework, estimatedCoverage: estimatedCoverage)
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

    private func fallbackAnalyze(code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult {
        try await Task.detached(priority: .userInitiated) {
            let issues = self.analysisEngine.performBasicAnalysis(code: code, language: language, analysisType: analysisType)
            let suggestions = self.analysisEngine.generateSuggestions(code: code, language: language, analysisType: analysisType)
            let analysis = self.analysisEngine.generateAnalysisSummary(issues: issues, suggestions: suggestions, analysisType: analysisType)
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
