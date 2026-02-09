//
// SwiftAnalyzer.swift
// CodingReviewer
//

import Foundation

struct SwiftAnalyzer: LanguageAnalyzer {
    let language = "Swift"

    func detectSecurityIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        // UserDefaults + Password (catch standard usage and common aliases)
        let passwordMatches = PatternMatcher.findMatches(
            pattern: "(UserDefaults|defaults|standard).*password", in: code)
        for match in passwordMatches {
            issues.append(
                CodeIssue(
                    description: "Storing passwords in UserDefaults is insecure. Use Keychain.",
                    severity: .high,
                    line: match.line,
                    category: .security
                ))
        }

        // Force Unwrapping
        let forceUnwrapMatches = PatternMatcher.findMatches(pattern: "[a-zA-Z0-9_]+\\s*!", in: code)
        // Filter out != and checks
        for match in forceUnwrapMatches where !match.matchedText.contains("!=") {
            issues.append(
                CodeIssue(
                    description: "Force unwrapping found. Use optional binding (if let/guard let).",
                    severity: .medium,
                    line: match.line,
                    category: .security  // Can cause crashes
                ))
        }

        return issues
    }

    func detectStyleIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, lineContent) in lines.enumerated() {
            // Check for use of print()
            if lineContent.contains("print(")
                && !lineContent.trimmingCharacters(in: .whitespaces).hasPrefix("//")
            {
                let fix = lineContent.replacingOccurrences(of: "print(", with: "Logger.debug(")
                issues.append(
                    CodeIssue(
                        description: "Avoid using print() in production. Use Logger or OSLog.",
                        severity: .low,
                        line: index + 1,
                        category: .style,
                        suggestedFix: fix
                    ))
            }

            // Check for TODOs
            if lineContent.contains("TODO:") {
                issues.append(
                    CodeIssue(
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
        let lines = code.components(separatedBy: .newlines)

        // Detect common Swift bugs
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("//") else { continue }

            // Detect empty catch blocks (swallowed errors)
            if trimmed.contains("catch") && trimmed.contains("{ }") {
                issues.append(
                    CodeIssue(
                        description: "Empty catch block - errors should be handled or logged",
                        severity: .high,
                        line: index + 1,
                        category: .bug
                    ))
            }

            // Detect potential retain cycles in closures
            if trimmed.contains("[self]") && !trimmed.contains("[weak self]")
                && !trimmed.contains("[unowned self]")
            {
                issues.append(
                    CodeIssue(
                        description: "Strong self capture in closure may cause retain cycle",
                        severity: .medium,
                        line: index + 1,
                        category: .bug
                    ))
            }
        }

        return issues
    }
}
