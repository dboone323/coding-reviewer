//
// ReviewEngine.swift
// CodingReviewerCore
//

import Foundation
import SwiftSyntax
import SwiftParser
import OSLog

private let logger = Logger(subsystem: "com.codingreviewer.core", category: "ReviewEngine")

/// Unified engine for executing high-integrity code reviews.
/// Consolidated from legacy analyzers (Swift, JavaScript, Python) and security agents.
public final class ReviewEngine: Sendable {
    public static let shared = ReviewEngine()
    
    private init() {}
    
    /// Execute a comprehensive review for a given code string.
    public func analyze(code: String, language: String, rules: [ReviewRule]) async -> [ReviewIssueData] {
        var findings: [ReviewIssueData] = []
        
        let normalizedLang = language.lowercased()
        
        // 1. Language-Specific Static Analysis
        switch normalizedLang {
        case "swift":
            findings.append(contentsOf: runSwiftAnalysis(code: code))
        case "javascript", "js":
            findings.append(contentsOf: runJavaScriptAnalysis(code: code))
        case "python", "py":
            findings.append(contentsOf: runPythonAnalysis(code: code))
        default:
            logger.info("No specialized analyzer for language: \(language)")
        }
        
        // 2. Custom Pattern Matching (Regex Rules)
        findings.append(contentsOf: runPatternMatching(code: code, language: language, rules: rules))
        
        return findings
    }
    
    // MARK: - Swift Analysis (SwiftSyntax)

    private func runSwiftAnalysis(code: String) -> [ReviewIssueData] {
        var issues: [ReviewIssueData] = []
        let sourceFile = Parser.parse(source: code)
        let converter = SourceLocationConverter(fileName: "", tree: sourceFile)
        
        // 1. Insecure Storage (UserDefaults for passwords)
        let insecureStorageVisitor = InsecureStorageVisitor(viewMode: .fixedUp)
        insecureStorageVisitor.walk(sourceFile)
        issues.append(contentsOf: insecureStorageVisitor.findings.map { 
            ReviewIssueData(message: $0.msg, severity: .high, lineNumber: $0.line(converter), category: "Security") 
        })
        
        // 2. Print Statements
        let printVisitor = PrintVisitor(viewMode: .fixedUp)
        printVisitor.walk(sourceFile)
        issues.append(contentsOf: printVisitor.findings.map { 
            ReviewIssueData(message: $0.msg, severity: .low, lineNumber: $0.line(converter), category: "Style", suggestion: "Use Logger.debug(...)") 
        })
        
        // 3. Retain Cycles
        let retainCycleVisitor = RetainCycleVisitor(viewMode: .fixedUp)
        retainCycleVisitor.walk(sourceFile)
        issues.append(contentsOf: retainCycleVisitor.findings.map { 
            ReviewIssueData(message: $0.msg, severity: .medium, lineNumber: $0.line(converter), category: "Bug", suggestion: "Use [weak self]") 
        })
        
        return issues
    }

    // MARK: - JavaScript Analysis (Regex-based)

    private func runJavaScriptAnalysis(code: String) -> [ReviewIssueData] {
        var issues: [ReviewIssueData] = []
        
        // Eval detection
        issues.append(contentsOf: match(pattern: "(?i)eval\\s*\\(", in: code, message: "Use of eval() detected. Major security risk.", severity: .high, category: "Security"))
        
        // innerHTML detection
        issues.append(contentsOf: match(pattern: "(?i)(?:\\.|\\b)innerHTML\\s*=", in: code, message: "Direct assignment to innerHTML can lead to XSS.", severity: .medium, category: "Security"))
        
        return issues
    }

    // MARK: - Python Analysis (Regex-based)

    private func runPythonAnalysis(code: String) -> [ReviewIssueData] {
        var issues: [ReviewIssueData] = []
        
        // Exec detection
        issues.append(contentsOf: match(pattern: "exec\\(", in: code, message: "Use of exec() detected. Security risk.", severity: .high, category: "Security"))
        
        // Subprocess shell=True
        issues.append(contentsOf: match(pattern: "subprocess\\..*shell\\s*=\\s*True", in: code, message: "Subprocess with shell=True can lead to shell injection.", severity: .high, category: "Security"))
        
        return issues
    }

    // MARK: - Custom Rules

    private func runPatternMatching(code: String, language: String, rules: [ReviewRule]) -> [ReviewIssueData] {
        var findings: [ReviewIssueData] = []
        let applicableRules = rules.filter { 
            $0.isEnabled && ($0.language.lowercased() == language.lowercased() || $0.language == "*") 
        }
        
        for rule in applicableRules {
            findings.append(contentsOf: match(pattern: rule.pattern, in: code, message: rule.ruleDescription, severity: rule.severity, category: "Custom User Rule"))
        }
        
        return findings
    }

    // MARK: - Helpers

    private func match(pattern: String, in code: String, message: String, severity: Severity, category: String) -> [ReviewIssueData] {
        var results: [ReviewIssueData] = []
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(code.startIndex..<code.endIndex, in: code)
        let matches = regex.matches(in: code, options: [], range: range)
        
        for match in matches {
            let line = lineCount(to: match.range.location, in: code)
            results.append(ReviewIssueData(message: message, severity: severity, lineNumber: line, category: category))
        }
        return results
    }

    private func lineCount(to location: Int, in code: String) -> Int {
        let prefix = code.prefix(location)
        return prefix.filter { $0 == "\n" }.count + 1
    }
}

// MARK: - SwiftSyntax Visitors

private struct Finding {
    let msg: String
    let node: Syntax
    func line(_ converter: SourceLocationConverter) -> Int {
        converter.location(for: node.position).line
    }
}

private final class InsecureStorageVisitor: SyntaxVisitor {
    var findings: [Finding] = []
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callText = node.description.lowercased()
        if callText.contains("userdefaults") && callText.contains("password") {
            findings.append(Finding(msg: "Storing passwords in UserDefaults is insecure.", node: Syntax(node)))
        }
        return .visitChildren
    }
}

private final class PrintVisitor: SyntaxVisitor {
    var findings: [Finding] = []
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
           callee.baseName.text == "print" {
            findings.append(Finding(msg: "Avoid using print() in production.", node: Syntax(node)))
        }
        return .visitChildren
    }
}

private final class RetainCycleVisitor: SyntaxVisitor {
    var findings: [Finding] = []
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        if let capture = node.signature?.capture {
            let text = capture.description
            if text.contains("self") && !text.contains("weak") && !text.contains("unowned") {
                findings.append(Finding(msg: "Strong self capture in closure.", node: Syntax(node)))
            }
        }
        return .visitChildren
    }
}
