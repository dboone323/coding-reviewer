//
//  StyleAnalysisService.swift
//  CodingReviewer
//
//  Service for detecting code style issues
//

import Foundation

/// Service responsible for detecting code style issues
struct StyleAnalysisService {
    /// Detect style issues in the provided code
    /// - Parameters:
    ///   - code: The source code to analyze
    ///   - language: The programming language of the code
    /// - Returns: Array of detected style issues
    func detectStyleIssues(code: String, language: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        if language == "Swift" {
            // Check for long lines (Swift only)
            let lines = code.components(separatedBy: .newlines)
            var lineIndex = 0

            while lineIndex < lines.count {
                var logicalLine = lines[lineIndex]
                var continuationIndex = lineIndex

                while continuationIndex + 1 < lines.count,
                      logicalLine.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("+")
                {
                    let trimmedCurrent = logicalLine.trimmingCharacters(in: .whitespacesAndNewlines)
                    let currentWithoutPlus = String(trimmedCurrent.dropLast())
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let nextTrimmed = lines[continuationIndex + 1]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    logicalLine = currentWithoutPlus + nextTrimmed
                    continuationIndex += 1
                }

                if logicalLine.count > 120 {
                    issues.append(CodeIssue(
                        description: "Line \(lineIndex + 1) is too long (\(logicalLine.count) characters). " +
                            "Maximum allowed is 120 characters.",
                        severity: .low,
                        line: lineIndex + 1,
                        category: .style
                    ))
                }

                lineIndex = continuationIndex + 1
            }

            // Check for missing documentation (Swift only)
            if code.contains("func "), !code.contains("///") {
                issues.append(CodeIssue(
                    description: "Code contains functions without documentation comments. " +
                        "Consider adding /// comments for public functions.",
                    severity: .low,
                    line: nil,
                    category: .style
                ))
            }
        }

        return issues
    }
}
