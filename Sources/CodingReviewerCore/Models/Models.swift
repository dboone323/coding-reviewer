import Foundation
import SwiftData

/// Represents a collection of findings for a codebase snapshot
@Model
public final class ReviewSession {
    public var id: UUID
    public var timestamp: Date
    public var projectPath: String
    public var projectName: String
    public var status: String
    
    @Relationship(deleteRule: .cascade, inverse: \ReviewIssue.session)
    public var issues: [ReviewIssue] = []
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        projectPath: String = "",
        projectName: String = "",
        status: String = "In Progress"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.projectPath = projectPath
        self.projectName = projectName
        self.status = status
    }
}

/// Represents a single detected finding in the codebase
@Model
public final class ReviewIssue {
    public var id: UUID
    public var message: String
    public var severity: Severity
    public var filePath: String
    public var lineNumber: Int
    public var category: String
    public var suggestion: String?
    
    public var session: ReviewSession?
    
    public init(
        id: UUID = UUID(),
        message: String,
        severity: Severity = .medium,
        filePath: String = "",
        lineNumber: Int = 0,
        category: String = "General",
        suggestion: String? = nil
    ) {
        self.id = id
        self.message = message
        self.severity = severity
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.category = category
        self.suggestion = suggestion
    }
}

public enum Severity: String, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public enum AnalysisType: String, Codable, Sendable {
    case basic = "Basic"
    case comprehensive = "Comprehensive"
    case security = "Security"
    case performance = "Performance"
}

/// Consolidated analysis result for a review session
public struct CodeAnalysisResult: Codable, Sendable {
    public var issues: [ReviewIssueData]
    public var summary: String
    public var timestamp: Date
    
    public init(issues: [ReviewIssueData] = [], summary: String = "", timestamp: Date = Date()) {
        self.issues = issues
        self.summary = summary
        self.timestamp = timestamp
    }
}

public struct ReviewIssueData: Codable, Sendable {
    public var message: String
    public var severity: Severity
    public var filePath: String
    public var lineNumber: Int
    public var category: String
    public var suggestion: String?
    
    public init(message: String, severity: Severity, filePath: String = "", lineNumber: Int = 0, category: String = "General", suggestion: String? = nil) {
        self.message = message
        self.severity = severity
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.category = category
        self.suggestion = suggestion
    }
}

public struct DocumentationResult: Codable, Sendable {
    public var documentation: String
    public var timestamp: Date
    
    public init(documentation: String = "", timestamp: Date = Date()) {
        self.documentation = documentation
        self.timestamp = timestamp
    }
}

public struct TestGenerationResult: Codable, Sendable {
    public var testCode: String
    public var timestamp: Date
    
    public init(testCode: String = "", timestamp: Date = Date()) {
        self.testCode = testCode
        self.timestamp = timestamp
    }
}

/// User-defined or built-in analysis rule
@Model
public final class ReviewRule {
    public var id: String
    public var name: String
    public var ruleDescription: String
    public var pattern: String
    public var severity: Severity
    public var language: String
    public var isEnabled: Bool
    
    public init(
        id: String,
        name: String,
        ruleDescription: String,
        pattern: String,
        severity: Severity = .medium,
        language: String = "Swift",
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.ruleDescription = ruleDescription
        self.pattern = pattern
        self.severity = severity
        self.language = language
        self.isEnabled = isEnabled
    }
}
