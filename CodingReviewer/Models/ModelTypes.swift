//
//  ModelTypes.swift
//  CodingReviewer
//
//  Shared model types used across the application
//

import Foundation

/// Severity levels for code issues
public enum IssueSeverity: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

/// Categories of code issues
public enum IssueCategory: String, Codable, CaseIterable, Sendable {
    case bug = "Bug"
    case security = "Security"
    case performance = "Performance"
    case style = "Style"
    case maintainability = "Maintainability"
    case general = "General"
}

/// Represents a single code issue found during analysis
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
