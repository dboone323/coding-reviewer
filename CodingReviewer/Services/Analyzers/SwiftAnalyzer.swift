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
        let lines = code.components(separatedBy: .newlines)
        
        for (index, lineContent) in lines.enumerated() {
            // Check for use of print()
            if lineContent.contains("print(") && !lineContent.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                let fix = lineContent.replacingOccurrences(of: "print(", with: "Logger.debug(")
                issues.append(CodeIssue(
                    description: "Avoid using print() in production. Use Logger or OSLog.",
                    severity: .low,
                    line: index + 1,
                    category: .style,
                    suggestedFix: fix
                ))
            }
            
            // Check for TODOs
            if lineContent.contains("TODO:") {
                issues.append(CodeIssue(
                    description: "Resolve TODO item.",
                    severity: .low,
                    line: index + 1,
                    category: .maintainability
                ))
            }
        }
        
        return issues
    }
    
    func detectBugs(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        // DONE: Add bug checks
        return issues
    }
}
