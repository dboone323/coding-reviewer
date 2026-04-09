//
// ReportingService.swift
// CodingReviewerCore
//

import Foundation

/// Unified service for generating reports, summaries, and documentation from review findings.
/// Consolidated from legacy PDFReportExporter, DocumentationGenerator, and AnalysisSummaryGenerator.
public final class ReportingService: Sendable {
    public static let shared = ReportingService()
    
    private init() {}
    
    // MARK: - Summary Generation
    
    /// Generates a comprehensive markdown summary of the review session.
    public func generateSummary(session: ReviewSession) -> String {
        var summary = "# Code Review Summary: \(session.projectName)\n"
        summary += "Generated on: \(session.timestamp.formatted())\n\n"
        
        let issues = session.issues
        if issues.isEmpty {
            summary += "✅ No issues were detected in this session.\n"
            return summary
        }
        
        // Statistics Section
        summary += "## Statistics\n"
        summary += "- Total Issues: \(issues.count)\n"
        
        let severityCounts = Dictionary(grouping: issues, by: \.severity)
        for severity in Severity.allCases {
            let count = severityCounts[severity]?.count ?? 0
            summary += "- \(severity.rawValue) Priority: \(count)\n"
        }
        summary += "\n"
        
        // Detailed Findings
        summary += "## Detailed Findings\n"
        let issuesByFile = Dictionary(grouping: issues, by: \.filePath)
        
        for (file, fileIssues) in issuesByFile.sorted(by: { $0.key < $1.key }) {
            summary += "### \(file.isEmpty ? "General" : file)\n"
            for issue in fileIssues {
                summary += "- **[\(issue.severity.rawValue)]** \(issue.category): \(issue.message)"
                if issue.lineNumber > 0 {
                    summary += " (Line \(issue.lineNumber))"
                }
                if let suggestion = issue.suggestion {
                    summary += "\n  *Suggestion:* \(suggestion)"
                }
                summary += "\n"
            }
            summary += "\n"
        }
        
        return summary
    }
    
    // MARK: - Documentation Generation
    
    /// Generates technical documentation based on the analyzed code and findings.
    public func generateDocumentation(code: String, language: String) async -> DocumentationResult {
        // In a real implementation, this might use an LLM or specialized parser.
        let summary = "## \(language.capitalized) API Documentation\n\nGenerated technical documentation for analyzed source."
        return DocumentationResult(documentation: summary, timestamp: Date())
    }
    
    // MARK: - Exporting (Placeholders for platform-specific logic)
    
    /// Simulates PDF data generation for the given session.
    public func exportToPDF(session: ReviewSession) async throws -> Data {
        let content = generateSummary(session: session)
        return content.data(using: .utf8) ?? Data()
    }
}

extension Severity: CaseIterable {
    public static var allCases: [Severity] {
        [.low, .medium, .high, .critical]
    }
}
