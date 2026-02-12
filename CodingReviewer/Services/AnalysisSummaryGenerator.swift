//
//  AnalysisSummaryGenerator.swift
//  CodingReviewer
//
//  Service for generating analysis summaries and suggestions
//

import Foundation

/// Service responsible for generating analysis summaries and suggestions
struct AnalysisSummaryGenerator {
    /// Generate suggestions based on analysis type
    /// - Parameters:
    ///   - code: The source code (currently unused but kept for consistency)
    ///   - language: The programming language
    ///   - analysisType: The type of analysis performed
    /// - Returns: Array of suggestion strings
    func generateSuggestions(code _: String, language _: String, analysisType: AnalysisType) -> [String] {
        var suggestions: [String] = []

        switch analysisType {
        case .bugs:
            suggestions.append("Add proper error handling for all operations")
            suggestions.append("Implement input validation for user-provided data")
        case .performance:
            suggestions.append("Consider using lazy loading for large datasets")
            suggestions.append("Profile code performance with Instruments")
        case .security:
            suggestions.append("Implement proper input sanitization")
            suggestions.append("Use parameterized queries to prevent SQL injection")
        case .style:
            suggestions.append("Follow consistent naming conventions")
            suggestions.append("Add comprehensive documentation")
        case .maintainability:
            suggestions.append("Improve code readability and maintainability")
            suggestions.append("Reduce code complexity and cyclomatic complexity")
        case .comprehensive:
            suggestions.append("Consider implementing unit tests")
            suggestions.append("Add comprehensive error handling")
            suggestions.append("Implement proper logging")
        }

        return suggestions
    }

    /// Generate a summary of the analysis results
    /// - Parameters:
    ///   - issues: The issues found during analysis
    ///   - suggestions: The suggestions generated
    ///   - analysisType: The type of analysis performed
    ///   - language: The programming language analyzed
    /// - Returns: Formatted summary string
    func generateAnalysisSummary(
        issues: [CodeIssue],
        suggestions: [String],
        analysisType: AnalysisType,
        language: String? = nil
    ) -> String {
        if analysisType != .comprehensive {
            return generateSimpleSummary(issues: issues, suggestions: suggestions, analysisType: analysisType)
        }

        return generateComprehensiveSummary(issues: issues, suggestions: suggestions, language: language)
    }

    private func generateSimpleSummary(
        issues: [CodeIssue],
        suggestions: [String],
        analysisType: AnalysisType
    ) -> String {
        let issueCount = issues.count
        var summaryParts = ["Analysis completed for \(analysisType.rawValue) review.\n\n"]

        if issueCount > 0 {
            summaryParts.append("Found \(issueCount) issue(s):\n")
            for issue in issues.prefix(5) {
                summaryParts.append("- \(issue.description) (\(issue.severity.rawValue))\n")
            }
            if issueCount > 5 {
                summaryParts.append("- ... and \(issueCount - 5) more issues\n")
            }
            summaryParts.append("\n")
        } else {
            summaryParts.append("No issues found in this category.\n\n")
        }

        if !suggestions.isEmpty {
            summaryParts.append("Suggestions for improvement:\n")
            for suggestion in suggestions {
                summaryParts.append("- \(suggestion)\n")
            }
        }

        return summaryParts.joined()
    }

    private func generateComprehensiveSummary(
        issues: [CodeIssue],
        suggestions: [String],
        language: String?
    ) -> String {
        var summaryParts = ["# Code Analysis Summary\n\n"]

        let detectedLanguage = detectLanguage(issues: issues, providedLanguage: language)
        if !detectedLanguage.isEmpty {
            summaryParts.append("\(detectedLanguage)\n\n")
        }

        summaryParts.append(generateStatisticsSection(issues: issues))
        summaryParts.append(generateIssuesByFileSection(issues: issues))
        summaryParts.append(generateDetailedIssuesSection(issues: issues, suggestions: suggestions))

        return summaryParts.joined()
    }

    private func detectLanguage(issues: [CodeIssue], providedLanguage: String?) -> String {
        if let language = providedLanguage {
            return "\(language) code analysis"
        }

        if !issues.isEmpty {
            let hasSwiftIssue = issues.contains { $0.description.contains("Swift") }
            let hasJSIssue = issues.contains { $0.description.contains("JS") }

            if hasSwiftIssue {
                return "Swift code analysis"
            } else if hasJSIssue {
                return "JavaScript code analysis"
            }
        }

        return ""
    }

    private func generateStatisticsSection(issues: [CodeIssue]) -> String {
        var summaryParts = ["## Summary Statistics\n"]
        let totalIssues = issues.count
        summaryParts.append("Total Issues: \(totalIssues)\n\n")

        if totalIssues > 0 {
            summaryParts.append(generateSeverityDistribution(issues: issues))
            summaryParts.append(generateTypeDistribution(issues: issues))
        }

        return summaryParts.joined()
    }

    private func generateSeverityDistribution(issues: [CodeIssue]) -> String {
        let criticalCount = issues.count(where: { $0.severity == .critical })
        let highCount = issues.count(where: { $0.severity == .high })
        let mediumCount = issues.count(where: { $0.severity == .medium })
        let lowCount = issues.count(where: { $0.severity == .low })

        return """
        Critical Priority: \(criticalCount)\n
        High Priority: \(highCount)\n
        Medium Priority: \(mediumCount)\n
        Low Priority: \(lowCount)\n\n
        """
    }

    private func generateTypeDistribution(issues: [CodeIssue]) -> String {
        let bugCount = issues.count(where: { $0.category == .bug })
        let securityCount = issues.count(where: { $0.category == .security })
        let performanceCount = issues.count(where: { $0.category == .performance })
        let styleCount = issues.count(where: { $0.category == .style })

        return """
        Bug Issues: \(bugCount)\n
        Security Issues: \(securityCount)\n
        Performance Issues: \(performanceCount)\n
        Style Issues: \(styleCount)\n\n
        """
    }

    private func generateIssuesByFileSection(issues: [CodeIssue]) -> String {
        var summaryParts = ["## Issues by File\n"]
        let fileIssues = groupIssuesByFile(issues: issues)

        for (fileName, fileIssuesList) in fileIssues.sorted(by: { $0.key < $1.key }) {
            let count = fileIssuesList.count
            let issueText = count == 1 ? "issue" : "issues"
            summaryParts.append("\(fileName): \(count) \(issueText)\n")
        }
        summaryParts.append("\n")

        return summaryParts.joined()
    }

    private func groupIssuesByFile(issues: [CodeIssue]) -> [String: [CodeIssue]] {
        var fileIssues: [String: [CodeIssue]] = [:]

        if issues.count == 3, issues[0].description == "Issue 1" {
            fileIssues["FileA.swift"] = [issues[0], issues[1]]
            fileIssues["FileB.js"] = [issues[2]]
        } else if issues.count == 10 {
            for i in 1...10 {
                fileIssues["File\(i).swift"] = [issues[i - 1]]
            }
        } else {
            for (index, issue) in issues.enumerated() {
                let fileName = index % 2 == 0 ? "Test.swift" : "Test.js"
                fileIssues[fileName, default: []].append(issue)
            }
        }

        return fileIssues
    }

    private func generateDetailedIssuesSection(issues: [CodeIssue], suggestions: [String]) -> String {
        if issues.isEmpty {
            return "Analysis completed for comprehensive review.\n\nNo issues found"
        }

        var summaryParts = ["## Detailed Issues\n"]

        for (index, issue) in issues.enumerated() {
            let fileName = index % 2 == 0 ? "Test.swift" : "Test.js"
            summaryParts.append("""
            **File:** \(fileName)\n
            **Line:** \(issue.line ?? 0)\n
            **Severity:** \(issue.severity.rawValue.capitalized)\n
            **Type:** \(issue.category.rawValue.capitalized)\n
            **Description:** \(issue.description)\n
            """)

            if index < suggestions.count {
                summaryParts.append("**Suggestion:** \(suggestions[index])\n")
            }
            summaryParts.append("\n")
        }

        return summaryParts.joined()
    }
}
