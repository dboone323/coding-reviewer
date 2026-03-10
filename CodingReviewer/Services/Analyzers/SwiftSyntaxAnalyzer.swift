//
// SwiftSyntaxAnalyzer.swift
// CodingReviewer
//
// AST-based Swift code analyzer using SwiftSyntax for accurate detection.
// This provides more accurate analysis than regex-based approaches.
//

import Foundation
#if canImport(SwiftSyntax)
    import SwiftParser
    import SwiftSyntax

    /// SwiftSyntax-based analyzer that uses AST visitors for accurate code analysis.
    struct SwiftSyntaxAnalyzer: LanguageAnalyzer {
        let language = "Swift"

        // MARK: - Security Issues

        func detectSecurityIssues(code: String) -> [CodeIssue] {
            var issues: [CodeIssue] = []

            let sourceFile = Parser.parse(source: code)

            // Detect force unwraps
            let forceUnwrapVisitor = ForceUnwrapVisitor(viewMode: .sourceAccurate)
            forceUnwrapVisitor.walk(sourceFile)
            issues.append(contentsOf: forceUnwrapVisitor.issues)

            // Detect password storage in UserDefaults
            let userDefaultsVisitor = UserDefaultsPasswordVisitor(viewMode: .sourceAccurate)
            userDefaultsVisitor.walk(sourceFile)
            issues.append(contentsOf: userDefaultsVisitor.issues)

            return issues
        }

        // MARK: - Style Issues

        func detectStyleIssues(code: String) -> [CodeIssue] {
            var issues: [CodeIssue] = []

            let sourceFile = Parser.parse(source: code)

            // Detect print statements
            let printVisitor = PrintStatementVisitor(viewMode: .sourceAccurate)
            printVisitor.walk(sourceFile)
            issues.append(contentsOf: printVisitor.issues)

            return issues
        }

        // MARK: - Bug Detection

        func detectBugs(code: String) -> [CodeIssue] {
            var issues: [CodeIssue] = []

            let sourceFile = Parser.parse(source: code)

            // Detect retain cycles
            let retainCycleVisitor = RetainCycleVisitor(viewMode: .sourceAccurate)
            retainCycleVisitor.walk(sourceFile)
            issues.append(contentsOf: retainCycleVisitor.issues)

            // Detect empty catch blocks
            let emptyCatchVisitor = EmptyCatchVisitor(viewMode: .sourceAccurate)
            emptyCatchVisitor.walk(sourceFile)
            issues.append(contentsOf: emptyCatchVisitor.issues)

            return issues
        }
    }

    // MARK: - AST Visitors

    /// Detects force unwrap expressions (!)
    final class ForceUnwrapVisitor: SyntaxVisitor {
        var issues: [CodeIssue] = []

        override func visit(_ node: ForceUnwrapExprSyntax) -> SyntaxVisitorContinueKind {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: "", tree: node.root))
            issues.append(CodeIssue(
                description: "Force unwrapping detected. Use optional binding (if let/guard let).",
                severity: .medium,
                line: location.line,
                category: .security
            ))
            return .visitChildren
        }
    }

    /// Detects UserDefaults usage with password-related keys
    final class UserDefaultsPasswordVisitor: SyntaxVisitor {
        var issues: [CodeIssue] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            let callText = node.description.lowercased()
            if callText.contains("userdefaults") && callText.contains("password") {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: "", tree: node.root))
                issues.append(CodeIssue(
                    description: "Storing passwords in UserDefaults is insecure. Use Keychain.",
                    severity: .high,
                    line: location.line,
                    category: .security
                ))
            }
            return .visitChildren
        }
    }

    /// Detects print() function calls
    final class PrintStatementVisitor: SyntaxVisitor {
        var issues: [CodeIssue] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            // Check if callee is 'print'
            if let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
               callee.baseName.text == "print"
            {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: "", tree: node.root))
                issues.append(CodeIssue(
                    description: "Avoid using print() in production. Use Logger or OSLog.",
                    severity: .low,
                    line: location.line,
                    category: .style,
                    suggestedFix: node.description.replacingOccurrences(of: "print(", with: "Logger.debug(")
                ))
            }
            return .visitChildren
        }
    }

    /// Detects potential retain cycles in closures
    final class RetainCycleVisitor: SyntaxVisitor {
        var issues: [CodeIssue] = []

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            // Check capture list for strong self capture
            if let captureClause = node.signature?.capture {
                let captureText = captureClause.description
                if captureText.contains("self") &&
                    !captureText.contains("weak self") &&
                    !captureText.contains("unowned self")
                {
                    let location = node.startLocation(converter: SourceLocationConverter(fileName: "", tree: node.root))
                    issues.append(CodeIssue(
                        description: "Strong self capture in closure may cause retain cycle. Use [weak self].",
                        severity: .medium,
                        line: location.line,
                        category: .bug
                    ))
                }
            }
            return .visitChildren
        }
    }

    /// Detects empty catch blocks
    final class EmptyCatchVisitor: SyntaxVisitor {
        var issues: [CodeIssue] = []

        override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
            // Check if catch body is empty
            if node.body.statements.isEmpty {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: "", tree: node.root))
                issues.append(CodeIssue(
                    description: "Empty catch block - errors should be handled or logged.",
                    severity: .high,
                    line: location.line,
                    category: .bug
                ))
            }
            return .visitChildren
        }
    }

#else
    /// Fallback when SwiftSyntax is not available
    struct SwiftSyntaxAnalyzer: LanguageAnalyzer {
        let language = "Swift"

        func detectSecurityIssues(code: String) -> [CodeIssue] {
            // Fall back to regex-based analyzer
            SwiftAnalyzer().detectSecurityIssues(code: code)
        }

        func detectStyleIssues(code: String) -> [CodeIssue] {
            SwiftAnalyzer().detectStyleIssues(code: code)
        }

        func detectBugs(code: String) -> [CodeIssue] {
            SwiftAnalyzer().detectBugs(code: code)
        }
    }
#endif
