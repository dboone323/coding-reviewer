//
// LanguageAnalyzer.swift
// CodingReviewer
//
// Protocol for language-specific analysis
//

import Foundation

protocol LanguageAnalyzer {
    var language: String { get }
    func detectSecurityIssues(code: String) -> [CodeIssue]
    func detectStyleIssues(code: String) -> [CodeIssue]
    func detectBugs(code: String) -> [CodeIssue]
}

enum LanguageAnalyzerFactory {
    static func analyzer(for language: String) -> LanguageAnalyzer {
        switch language.lowercased() {
        case "swift":
            SwiftAnalyzer()
        case "javascript", "js":
            JavaScriptAnalyzer()
        case "python", "py":
            PythonAnalyzer()
        default:
            GenericAnalyzer(language: language)
        }
    }
}

struct GenericAnalyzer: LanguageAnalyzer {
    let language: String

    func detectSecurityIssues(code: String) -> [CodeIssue] { [] }
    func detectStyleIssues(code: String) -> [CodeIssue] { [] }
    func detectBugs(code: String) -> [CodeIssue] { [] }
}
