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
    private let aiService: AIEnhancedCodeAnalysisService?

    public init() {
        // Initialize service
        if Self.isAIEnabled {
            // Inject Ollama HTTP generator; service will remap to free models and fallback to CLI if needed
            let generator: (String, String, Double) async throws -> String = { model, prompt, temp in
                try await OllamaClient().generate(model: model, prompt: prompt, temperature: temp)
            }
            self.aiService = AIEnhancedCodeAnalysisService(llmGenerate: generator)
        } else {
            self.aiService = nil
        }
    }

    private static var isAIEnabled: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["CR_USE_OLLAMA"] == "1" || env["CR_USE_AI"] == "1"
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

    public func analyzeCode(_ code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult {
        self.logger.info("Analyzing code - Language: \(language), Type: \(analysisType.rawValue)")

        if let ai = aiService {
            // Use AI-enhanced path; map results into existing model
            let aiResult = try await ai.analyzeCodeWithAI(code, language: language)
            var issues: [CodeIssue] = []
            // Security
            for s in aiResult.securityIssues {
                issues.append(CodeIssue(
                    description: s.description,
                    severity: Self.mapSeverity(s.severity),
                    line: nil,
                    category: .security
                ))
            }
            // Performance
            for p in aiResult.performanceIssues {
                let severity: IssueSeverity = (p.impact == .high ? .high : (p.impact == .medium ? .medium : .low))
                issues.append(CodeIssue(
                    description: p.description,
                    severity: severity,
                    line: nil,
                    category: .performance
                ))
            }
            // Style / Best practices
            for b in aiResult.bestPracticeViolations {
                issues.append(CodeIssue(
                    description: b.violation,
                    severity: .medium,
                    line: nil,
                    category: .style
                ))
            }
            let suggestions = aiResult.recommendations
            let summary = "AI Quality: \(aiResult.qualityScore)/10 • Security: \(aiResult.securityIssues.count) • Performance: \(aiResult.performanceIssues.count) • Style: \(aiResult.bestPracticeViolations.count)"
            return CodeAnalysisResult(
                analysis: summary,
                issues: issues,
                suggestions: suggestions,
                language: language,
                analysisType: analysisType
            )
        }

        // Perform analysis on background thread to avoid blocking UI
        return try await Task.detached(priority: .userInitiated) {
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

    public func generateDocumentation(_ code: String, language: String, includeExamples: Bool) async throws -> DocumentationResult {
        self.logger.info("Generating documentation - Language: \(language)")

        if let ai = aiService {
            let doc = try await ai.generateDocumentationWithAI(code, documentationType: includeExamples ? .comprehensive : .inline)
            return DocumentationResult(documentation: doc.generatedDocumentation, language: language, includesExamples: includeExamples)
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

        if let ai = aiService {
            let aiTests = try await ai.generateTestsWithAI(code, testType: .unit)
            return TestGenerationResult(
                testCode: aiTests.generatedTests,
                language: language,
                testFramework: testFramework,
                estimatedCoverage: Double(aiTests.estimatedCoverage)
            )
        }

        return try await Task.detached(priority: .userInitiated) {
            let testCode = self.analysisEngine.generateBasicTests(code: code, language: language, testFramework: testFramework)
            let estimatedCoverage = self.analysisEngine.estimateTestCoverage(code: code, testCode: testCode)
            return TestGenerationResult(testCode: testCode, language: language, testFramework: testFramework, estimatedCoverage: estimatedCoverage)
        }.value
    }

    private static func mapSeverity(_ s: Severity) -> IssueSeverity {
        switch s {
        case .high: .high
        case .medium: .medium
        case .low: .low
        }
    }

    public func trackReviewProgress(_ reviewId: UUID) async throws {
        self.logger.info("Tracking review progress for ID: \(reviewId)")
        // Basic implementation - could be enhanced with persistence
    }
}
