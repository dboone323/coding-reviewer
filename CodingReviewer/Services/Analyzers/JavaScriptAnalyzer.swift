//
// JavaScriptAnalyzer.swift
// CodingReviewer
//

import Foundation

struct JavaScriptAnalyzer: LanguageAnalyzer {
    let language = "JavaScript"

    func detectSecurityIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        // Eval
        let evalMatches = PatternMatcher.findMatches(pattern: "(?i)eval\\s*\\(", in: code)
        for match in evalMatches {
            issues.append(
                CodeIssue(
                    description: "Use of eval() detected. This is a major security risk.",
                    severity: .high,
                    line: match.line,
                    category: .security
                ))
        }

        // innerHTML
        let innerHTMLMatches = PatternMatcher.findMatches(
            pattern: "(?i)(?:\\.|\\b)innerHTML\\s*=", in: code
        )
        for match in innerHTMLMatches {
            issues.append(
                CodeIssue(
                    description: "Direct assignment to innerHTML can lead to XSS attacks.",
                    severity: .medium,
                    line: match.line,
                    category: .security
                ))
        }

        return issues
    }

    func detectStyleIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        // Console.log
        let consoleMatches = PatternMatcher.findMatches(pattern: "console\\.log\\(", in: code)
        for match in consoleMatches {
            issues.append(
                CodeIssue(
                    description: "Remove console.log statements before production.",
                    severity: .low,
                    line: match.line,
                    category: .style
                ))
        }

        return issues
    }

    func detectBugs(code: String) -> [CodeIssue] {
        []
    }
}
