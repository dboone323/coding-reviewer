//
// CustomRule.swift
// CodingReviewer
//
// Defines a custom rule for code analysis
//

import Foundation

struct CustomRule: Codable, Identifiable {
    let id: String
    let description: String
    let pattern: String
    let language: String
    let severity: IssueSeverity
    let category: IssueCategory

    // Optional: Suggestion for fix
    let suggestion: String?
}
