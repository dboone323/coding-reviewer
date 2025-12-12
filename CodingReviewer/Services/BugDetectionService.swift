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
        if language == "Swift" || language == "JavaScript" {
            // Check for TODO comments - create separate issues for each
            for (index, line) in lines.enumerated() where line.contains("TODO") {
                issues.append(CodeIssue(
                    description: "TODO comment found - this should be addressed",
                    severity: .medium,
                    line: index + 1,
                    category: .bug
                ))
            }

            // Check for FIXME comments - create separate issues for each
            for (index, line) in lines.enumerated() where line.contains("FIXME") {
                issues.append(CodeIssue(
                    description: "FIXME comment found - this should be addressed",
                    severity: .high, // FIXED is usually higher severity than DONE
                    line: index + 1,
                    category: .bug
                ))
            }
        }

        if language == "Swift" {
            // Check for print statements
            for (index, line) in lines.enumerated() where line.contains("print(") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.hasPrefix("//") {
                    issues.append(CodeIssue(
                        description: "Debug print statements found in production code",
                        severity: .low,
                        line: index + 1,
                        category: .bug
                    ))
                    break // Only report once
                }
            }

            // Check for force unwrap
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                // Ignore comments
                guard !trimmed.hasPrefix("//") else { continue }

                // Simple heuristic to ignore string literals would be complex without a parser,
                // but we can improve the check to be slightly more robust
                if line.contains("!") && !line.contains("!=") && !line.contains("?!") {
                    // Check if it's likely a force unwrap (end of word or before dot)
                    // This is still a heuristic
                    if line.contains("!)") || line.contains("!.") || line.contains("! ") || line.hasSuffix("!") {
                         issues.append(CodeIssue(
                            description: "Force unwrapping detected - consider safe unwrapping",
                            severity: .medium,
                            line: index + 1,
                            category: .bug
                        ))
                        break // Only report once
                    }
                }
            }
        }

        return issues
    }
}
