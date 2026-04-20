//
// SwiftAnalyzer.swift
// CodingReviewer
//

import Foundation

struct SwiftAnalyzer: LanguageAnalyzer {
    let language = "Swift"

    func detectSecurityIssues(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        issues.append(contentsOf: detectUserDefaultsSecurity(in: code))
        issues.append(contentsOf: detectForceUnwraps(in: code))
        return issues
    }

    private func detectUserDefaultsSecurity(in code: String) -> [CodeIssue] {
        PatternMatcher.findMatches(pattern: "(UserDefaults|defaults|standard).*password", in: code).map { match in
            CodeIssue(description: "Storing passwords in UserDefaults is insecure. Use Keychain.", severity: .high, line: match.line, category: .security)
        }
    }

    private func detectForceUnwraps(in code: String) -> [CodeIssue] {
        PatternMatcher.findMatches(pattern: "[a-zA-Z0-9_]+\\s*!(?!=)", in: code).map { match in
            CodeIssue(description: "Force unwrapping found. Use optional binding (if let/guard let).", severity: .medium, line: match.line, category: .security)
        }
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
                    )
                )
            }

            // Check for TODOs
            if lineContent.contains("TODO:") {
                issues.append(
                    CodeIssue(
                        description: "Resolve TODO item.",
                        severity: .low,
                        line: index + 1,
                        category: .maintainability
                    )
                )
            }
        }

        return issues
    }

    func detectBugs(code: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        issues.append(contentsOf: detectEmptyCatchBlocks(in: code))
        issues.append(contentsOf: detectRetainCycles(in: code))
        return issues
    }

    private func detectEmptyCatchBlocks(in code: String) -> [CodeIssue] {
        PatternMatcher.findMatches(pattern: "catch\\s*\\{\\s*\\}", in: code).map { match in
            CodeIssue(description: "Empty catch block - errors should be handled or logged", severity: .high, line: match.line, category: .bug)
        }
    }

    private func detectRetainCycles(in code: String) -> [CodeIssue] {
        let lines = code.components(separatedBy: .newlines)
        return lines.enumerated().compactMap { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("//"), trimmed.contains("[self]"), !trimmed.contains("[weak self]"), !trimmed.contains("[unowned self]") else { return nil }
            return CodeIssue(description: "Strong self capture in closure may cause retain cycle", severity: .medium, line: index + 1, category: .bug)
        }
    }
}
