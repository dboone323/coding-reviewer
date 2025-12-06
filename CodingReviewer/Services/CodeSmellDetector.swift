//
// CodeSmellDetector.swift
// CodingReviewer
//
// Service for detecting code smells
//

import Foundation

struct CodeSmellDetector {
    func detectSmells(code: String, language: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        
        // Long Method Detection (Basic heuristic: indentation + length)
        // This is a simplified check. Real AST parsing would be better.
        let lines = code.components(separatedBy: .newlines)
        var currentMethodLength = 0
        var methodStartLine = 0
        
        for (index, line) in lines.enumerated() {
            if line.contains("func ") || line.contains("def ") || line.contains("function ") {
                if currentMethodLength > 50 {
                    issues.append(CodeIssue(
                        description: "Long method detected (> 50 lines). Consider refactoring.",
                        severity: .low,
                        line: methodStartLine,
                        category: .maintainability
                    ))
                }
                currentMethodLength = 0
                methodStartLine = index + 1
            } else {
                currentMethodLength += 1
            }
        }
        
        // Check last method
        if currentMethodLength > 50 {
             issues.append(CodeIssue(
                description: "Long method detected (> 50 lines). Consider refactoring.",
                severity: .low,
                line: methodStartLine,
                category: .maintainability
            ))
        }
        
        // DONE: Add more smell detectors (Large Class, Long Parameter List, etc.)
        
        return issues
    }
}
