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

enum IssueSeverity: String, Codable {
    case high
    case medium
    case low
}

enum IssueCategory: String, Codable {
    case security
    case style
    case bug
    case performance
    case maintainability
}
