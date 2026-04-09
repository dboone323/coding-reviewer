//
//  SecurityAnalysisService.swift
//  CodingReviewer
//
//  Service for detecting security vulnerabilities in code
//

import Foundation

/// Service responsible for detecting security issues in code
struct SecurityAnalysisService {
    /// Detect security issues in the provided code
    /// - Parameters:
    ///   - code: The source code to analyze
    ///   - language: The programming language of the code
    /// - Returns: Array of detected security issues
    func detectSecurityIssues(code: String, language: String) -> [CodeIssue] {
        let analyzer = LanguageAnalyzerFactory.analyzer(for: language)
        return analyzer.detectSecurityIssues(code: code)
    }
}
