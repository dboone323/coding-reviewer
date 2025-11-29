//
// PythonAnalyzer.swift
// CodingReviewer
//

import Foundation

struct PythonAnalyzer: LanguageAnalyzer {
    let language = "Python"
    
    func detectSecurityIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        
        // Exec
        let execMatches = PatternMatcher.findMatches(pattern: "exec\\(", in: code)
        for match in execMatches {
            issues.append(CodeIssue(
                description: "Use of exec() detected. This is a security risk.",
                severity: .high,
                line: match.line,
                category: .security
            ))
        }
        
        // Subprocess with shell=True
        let shellMatches = PatternMatcher.findMatches(pattern: "subprocess\\..*shell\\s*=\\s*True", in: code)
        for match in shellMatches {
            issues.append(CodeIssue(
                description: "subprocess call with shell=True can lead to shell injection.",
                severity: .high,
                line: match.line,
                category: .security
            ))
        }
        
        return issues
    }
    
    func detectStyleIssues(code: String) -> [CodeIssue] {
        return []
    }
    
    func detectBugs(code: String) -> [CodeIssue] {
        return []
    }
}
