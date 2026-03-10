//
// CustomRule.swift
// CodingReviewer
//
// Defines a custom rule for code analysis and pattern matching utilities
//

import Foundation

/// A custom code analysis rule
public struct CustomRule: Codable, Identifiable {
    public let id: String
    public let description: String
    public let pattern: String
    public let language: String
    public let severity: IssueSeverity
    public let category: IssueCategory
    public let suggestion: String?

    public init(
        id: String = UUID().uuidString,
        description: String,
        pattern: String,
        language: String,
        severity: IssueSeverity,
        category: IssueCategory,
        suggestion: String? = nil
    ) {
        self.id = id
        self.description = description
        self.pattern = pattern
        self.language = language
        self.severity = severity
        self.category = category
        self.suggestion = suggestion
    }
}
