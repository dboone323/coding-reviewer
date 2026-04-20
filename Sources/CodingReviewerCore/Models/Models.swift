import Foundation
import SwiftData

//  CodingReviewerCore
//  Centralized Models and Protocols

// MARK: - Persistence Models (SwiftData)

@Model
public final class ReviewReport {
    public var id: UUID
    public var title: String
    public var timestamp: Date
    public var summary: String
    @Relationship(deleteRule: .cascade) public var issues: [ReviewIssue] = []
    
    public init(id: UUID = UUID(), title: String = "Untitled Review", timestamp: Date = Date(), summary: String = "") {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.summary = summary
    }
}

@Model
public final class ReviewIssue {
    public var id: UUID
    public var title: String
    public var message: String
    public var severityValue: String
    public var filePath: String
    public var lineNumber: Int
    public var codeSnippet: String
    public var timestamp: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "",
        message: String = "",
        severity: Severity = .medium,
        filePath: String = "",
        lineNumber: Int = 0,
        codeSnippet: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severityValue = severity.rawValue
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.codeSnippet = codeSnippet
        self.timestamp = timestamp
    }
    
    public var severity: Severity {
        get { Severity(rawValue: severityValue) ?? .medium }
        set { severityValue = newValue.rawValue }
    }
}

// MARK: - Core Protocols & Services

/// Base service protocol that all services should conform to
public protocol ServiceProtocol {
    var serviceId: String { get }
    var version: String { get }
    func initialize() async throws
    func cleanup() async
    func healthCheck() async -> ServiceHealthStatus
}

/// Protocol defining the interface for code review services
public protocol CodeReviewServiceProtocol: ServiceProtocol {
    func analyzeCode(_ code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult
    func generateDocumentation(_ code: String, language: String, includeExamples: Bool) async throws -> DocumentationResult
    func generateTests(_ code: String, language: String, testFramework: String) async throws -> TestGenerationResult
    func trackReviewProgress(_ reviewId: UUID) async throws
}

/// Health status of a service
public enum ServiceHealthStatus: Sendable {
    case healthy
    case degraded(reason: String)
    case unhealthy(errorMessage: String)
}

// MARK: - Service Logic Models

/// Types of analysis that can be performed
public enum AnalysisType: String, Codable, CaseIterable, Sendable {
    case bugs = "Bugs"
    case performance = "Performance"
    case security = "Security"
    case style = "Style"
    case maintainability = "Maintainability"
    case comprehensive = "Comprehensive"
}

/// Result of code analysis
public struct CodeAnalysisResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let analysis: String
    public let issues: [CodeIssue]
    public let suggestions: [String]
    public let language: String
    public let analysisType: AnalysisType

    public init(
        analysis: String, issues: [CodeIssue], suggestions: [String], language: String,
        analysisType: AnalysisType
    ) {
        self.id = UUID()
        self.analysis = analysis
        self.issues = issues
        self.suggestions = suggestions
        self.language = language
        self.analysisType = analysisType
    }
}

/// Result of documentation generation
public struct DocumentationResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let documentation: String
    public let language: String
    public let includesExamples: Bool
    public let timestamp: Date

    public init(documentation: String, language: String = "Swift", includeExamples: Bool = false, timestamp: Date = Date()) {
        self.id = UUID()
        self.documentation = documentation
        self.language = language
        self.includesExamples = includeExamples
        self.timestamp = timestamp
    }
    
    // Legacy initializer for service compatibility
    public init(documentation: String, language: String, includesExamples: Bool) {
        self.id = UUID()
        self.documentation = documentation
        self.language = language
        self.includesExamples = includesExamples
        self.timestamp = Date()
    }
}

/// Result of test generation
public struct TestGenerationResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let testCode: String
    public let language: String
    public let testFramework: String
    public let estimatedCoverage: Double
    public let timestamp: Date

    public init(
        testCode: String, language: String, testFramework: String, estimatedCoverage: Double, timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.testCode = testCode
        self.language = language
        self.testFramework = testFramework
        self.estimatedCoverage = estimatedCoverage
        self.timestamp = timestamp
    }
}

// MARK: - Domain Models

public struct CustomRule: Codable, Identifiable, Sendable {
    public let id: String
    public let description: String
    public let pattern: String
    public let language: String
    public let severity: IssueSeverity
    public let category: IssueCategory
    public let suggestion: String?
    public let isEnabled: Bool

    public init(
        id: String = UUID().uuidString,
        description: String,
        pattern: String,
        language: String,
        severity: IssueSeverity,
        category: IssueCategory,
        suggestion: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.description = description
        self.pattern = pattern
        self.language = language
        self.severity = severity
        self.category = category
        self.suggestion = suggestion
        self.isEnabled = isEnabled
    }
}

public enum IssueSeverity: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public enum IssueCategory: String, Codable, CaseIterable, Sendable {
    case bug = "Bug"
    case security = "Security"
    case performance = "Performance"
    case style = "Style"
    case maintainability = "Maintainability"
    case general = "General"
}

public struct CodeIssue: Codable, Identifiable, Sendable {
    public let id: UUID
    public let description: String
    public let severity: IssueSeverity
    public let line: Int?
    public let category: IssueCategory
    public let suggestedFix: String?

    public init(
        description: String, severity: IssueSeverity, line: Int? = nil, category: IssueCategory,
        suggestedFix: String? = nil
    ) {
        self.id = UUID()
        self.description = description
        self.severity = severity
        self.line = line
        self.category = category
        self.suggestedFix = suggestedFix
    }
}

// MARK: - Git Models

public struct GitCommit: Identifiable, Sendable, Codable {
    public let id: String
    public let author: String
    public let date: Date
    public let message: String

    public init(id: String, author: String, date: Date, message: String) {
        self.id = id
        self.author = author
        self.date = date
        self.message = message
    }
}

public struct GitStash: Identifiable, Sendable, Codable {
    public let id: String
    public let name: String
    public let date: Date

    public init(id: String, name: String, date: Date) {
        self.id = id
        self.name = name
        self.date = date
    }
}

// MARK: - AI Models

public struct RefactoringGoal: Sendable {
    public let description: String
    public let objectives: [String]
    public init(description: String, objectives: [String]) {
        self.description = description
        self.objectives = objectives
    }
}

public enum DocumentationType: Sendable {
    case comprehensive, api, inline
    public var description: String {
        switch self {
        case .comprehensive: "comprehensive"
        case .api: "API-focused"
        case .inline: "inline"
        }
    }
}

public enum TestType: Sendable {
    case unit, integration, performance
    public var description: String {
        switch self {
        case .unit: "unit"
        case .integration: "integration"
        case .performance: "performance"
        }
    }
}

public enum ReviewType: Sendable {
    case comprehensive, security, performance, style
    public var description: String {
        switch self {
        case .comprehensive: "comprehensive"
        case .security: "security-focused"
        case .performance: "performance-focused"
        case .style: "style and convention"
        }
    }
}

public struct SecurityIssue: Sendable {
    public let type: String
    public let severity: Severity
    public let description: String
    public let recommendation: String
    public init(type: String, severity: Severity, description: String, recommendation: String) {
        self.type = type
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
    }
}

public enum Severity: String, Codable, Sendable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public struct ReviewSession: Identifiable, Sendable, Codable {
    public let id: UUID
    public let projectName: String
    public let timestamp: Date
    public let issues: [ReviewIssueData]
    
    public init(id: UUID = UUID(), projectName: String, timestamp: Date = Date(), issues: [ReviewIssueData] = []) {
        self.id = id
        self.projectName = projectName
        self.timestamp = timestamp
        self.issues = issues
    }
}

public enum Impact: String, Codable, Sendable {
    case low = "Low", medium = "Medium", high = "High"
}

public struct PerformanceIssue: Sendable {
    public let type: String
    public let impact: Impact
    public let description: String
    public let suggestion: String
    public init(type: String, impact: Impact, description: String, suggestion: String) {
        self.type = type
        self.impact = impact
        self.description = description
        self.suggestion = suggestion
    }
}

public struct BestPracticeViolation: Sendable {
    public let rule: String
    public let violation: String
    public let suggestion: String
    public init(rule: String, violation: String, suggestion: String) {
        self.rule = rule
        self.violation = violation
        self.suggestion = suggestion
    }
}

public enum Priority: String, Codable, Sendable {
    case low = "Low", medium = "Medium", high = "High"
}

public struct CodeImprovement: Sendable {
    public let title: String
    public let description: String
    public let currentCode: String
    public let improvedCode: String
    public let benefits: [String]
    public let priority: Priority
    public init(title: String, description: String, currentCode: String, improvedCode: String, benefits: [String], priority: Priority) {
        self.title = title
        self.description = description
        self.currentCode = currentCode
        self.improvedCode = improvedCode
        self.benefits = benefits
        self.priority = priority
    }
}

public enum PerformanceImpact: String, Codable, Sendable {
    case positive = "Positive", neutral = "Neutral", negative = "Negative"
}

public struct CodeComparison: Sendable {
    public let originalLinesOfCode: Int
    public let refactoredLinesOfCode: Int
    public let complexityReduction: Double
    public let performanceImpact: PerformanceImpact
    public let maintainabilityScore: Double
    public let readabilityImprovement: Bool
    public init(originalLinesOfCode: Int, refactoredLinesOfCode: Int, complexityReduction: Double, performanceImpact: PerformanceImpact, maintainabilityScore: Double, readabilityImprovement: Bool) {
        self.originalLinesOfCode = originalLinesOfCode
        self.refactoredLinesOfCode = refactoredLinesOfCode
        self.complexityReduction = complexityReduction
        self.performanceImpact = performanceImpact
        self.maintainabilityScore = maintainabilityScore
        self.readabilityImprovement = readabilityImprovement
    }
}

public enum TechnicalDebtLevel: String, Codable, Sendable {
    case low = "Low", medium = "Medium", high = "High"
}

public struct AISuggestion: Sendable {
    public let title: String
    public let description: String
    public let priority: Priority
    public let estimatedEffort: String
    public let category: String
    public init(title: String, description: String, priority: Priority, estimatedEffort: String, category: String) {
        self.title = title
        self.description = description
        self.priority = priority
        self.estimatedEffort = estimatedEffort
        self.category = category
    }
}

/// Helper for data mapping between service and persistence layers
public typealias ReviewRule = CustomRule

public struct ReviewIssueData: Codable, Sendable {
    public let title: String
    public let message: String
    public let severity: Severity
    public let category: IssueCategory
    public let filePath: String
    public let lineNumber: Int
    public let suggestion: String?
    
    public init(
        title: String = "Code Issue", 
        message: String, 
        severity: Severity, 
        category: IssueCategory = .general, 
        filePath: String = "", 
        lineNumber: Int = 0,
        suggestion: String? = nil
    ) {
        self.title = title
        self.message = message
        self.severity = severity
        self.category = category
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.suggestion = suggestion
    }
    
    // Convenience initializer for string-based categories (legacy support)
    public init(
        message: String,
        severity: Severity,
        lineNumber: Int,
        category: String,
        suggestion: String? = nil
    ) {
        self.title = "Code Issue"
        self.message = message
        self.severity = severity
        self.category = IssueCategory(rawValue: category) ?? .general
        self.filePath = ""
        self.lineNumber = lineNumber
        self.suggestion = suggestion
    }
}
