//
// SwiftAnalyzer.swift
// CodingReviewer
//

import Foundation

struct SwiftAnalyzer: LanguageAnalyzer {
    let language = "Swift"
    
    func detectSecurityIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        
        // UserDefaults + Password
        let passwordMatches = PatternMatcher.findMatches(pattern: "UserDefaults.*password", in: code)
        for match in passwordMatches {
            issues.append(CodeIssue(
                description: "Storing passwords in UserDefaults is insecure. Use Keychain.",
                severity: .high,
                line: match.line,
                category: .security
            ))
        }
        
        // Force Unwrapping
        let forceUnwrapMatches = PatternMatcher.findMatches(pattern: "[a-zA-Z0-9_]+\\s*!", in: code)
        // Filter out != and checks
        for match in forceUnwrapMatches {
            if !match.content.contains("!=") {
                 issues.append(CodeIssue(
                    description: "Force unwrapping found. Use optional binding (if let/guard let).",
                    severity: .medium,
                    line: match.line,
                    category: .security // Can cause crashes
                ))
            }
        }
        
        return issues
    }
    
    func detectStyleIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        
        // TODO: Add style checks
        return issues
    }
    
    func detectBugs(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        // TODO: Add bug checks
        return issues
    }
}
