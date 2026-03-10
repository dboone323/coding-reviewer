//
//  BugDetectionService.swift
//  CodingReviewer
//
//  Service for detecting basic bugs and code issues
//

import Foundation

/// Service responsible for detecting basic bugs in code
struct BugDetectionService {
    /// Detect basic bugs in the provided code
    /// - Parameters:
    ///   - code: The source code to analyze
    ///   - language: The programming language of the code
    /// - Returns: Array of detected code issues
    func detectBasicBugs(code: String, language: String) -> [CodeIssue] {
        // Validation
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        var issues: [CodeIssue] = []
        let lines = code.components(separatedBy: .newlines)

        // Check for common bug patterns
        issues.append(contentsOf: detectTodoAndFixmeComments(in: lines))
        if language == "Swift" {
            issues.append(contentsOf: detectSwiftSpecificIssues(in: lines))
        }

        return issues
    }

    private func detectTodoAndFixmeComments(in lines: [String]) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        // Check for TODO comments
        for (index, line) in lines.enumerated() where line.contains("TODO") {
            issues.append(CodeIssue(
                description: "TODO comment found - this should be addressed",
                severity: .medium,
                line: index + 1,
                category: .bug
            ))
        }

        // Check for FIXME comments
        for (index, line) in lines.enumerated() where line.contains("FIXME") {
            issues.append(CodeIssue(
                description: "FIXME comment found - this should be addressed",
                severity: .high,
                line: index + 1,
                category: .bug
            ))
        }

        return issues
    }

    private func detectSwiftSpecificIssues(in lines: [String]) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        // Check for print statements
        if let printIssue = detectPrintStatements(in: lines) {
            issues.append(printIssue)
        }

        // Check for force unwrap
        if let forceUnwrapIssue = detectForceUnwrap(in: lines) {
            issues.append(forceUnwrapIssue)
        }

        return issues
    }

    private func detectPrintStatements(in lines: [String]) -> CodeIssue? {
        for (index, line) in lines.enumerated() where line.contains("print(") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.hasPrefix("//") {
                return CodeIssue(
                    description: "Debug print statements found in production code",
                    severity: .low,
                    line: index + 1,
                    category: .bug
                )
            }
        }
        return nil
    }

    private func detectForceUnwrap(in lines: [String]) -> CodeIssue? {
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Ignore comments
            guard !trimmed.hasPrefix("//") else { continue }

            if line.contains("!") && !line.contains("!=") && !line.contains("?!") {
                if line.contains("!)") || line.contains("!.") || line.contains("! ") || line.hasSuffix("!") {
                    return CodeIssue(
                        description: "Force unwrapping detected - consider safe unwrapping",
                        severity: .medium,
                        line: index + 1,
                        category: .bug
                    )
                }
            }
        }
        return nil
    }
}
