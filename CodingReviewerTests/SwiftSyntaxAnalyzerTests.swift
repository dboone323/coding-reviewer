//
// SwiftSyntaxAnalyzerTests.swift
// CodingReviewerTests
//
// Unit tests for the SwiftSyntax-based code analyzer.
//

import XCTest
@testable import CodingReviewer

final class SwiftSyntaxAnalyzerTests: XCTestCase {
    var analyzer: SwiftSyntaxAnalyzer!

    override func setUpWithError() throws {
        analyzer = SwiftSyntaxAnalyzer()
    }

    // MARK: - Basic Tests

    func testAnalyzerLanguage() {
        XCTAssertEqual(analyzer.language, "Swift")
    }

    // MARK: - Force Unwrap Detection

    func testDetectsForceUnwrap() {
        let code = """
        let value: String? = "test"
        let unwrapped = value!
        """

        let issues = analyzer.detectSecurityIssues(code: code)

        // Should detect force unwrap
        XCTAssertTrue(issues
            .contains { $0.description.contains("Force unwrap") || $0.description.contains("optional") })
    }

    func testNoFalsePositiveForNotEqual() {
        let code = """
        if value != nil {
            print("not nil")
        }
        """

        let issues = analyzer.detectSecurityIssues(code: code)

        // Should NOT flag != as force unwrap
        let forceUnwrapIssues = issues.filter { $0.description.contains("Force unwrap") }
        XCTAssertEqual(forceUnwrapIssues.count, 0)
    }

    // MARK: - Print Statement Detection

    func testDetectsPrintStatements() {
        let code = """
        func doSomething() {
            print("Debug message")
        }
        """

        let issues = analyzer.detectStyleIssues(code: code)

        XCTAssertTrue(issues.contains { $0.description.contains("print") })
    }

    func testPrintInCommentNotFlagged() {
        let code = """
        // print("This is a comment")
        func doSomething() {
            // No actual print here
        }
        """

        let issues = analyzer.detectStyleIssues(code: code)

        // Comments should not be flagged
        let printIssues = issues.filter { $0.description.contains("print") }
        XCTAssertEqual(printIssues.count, 0)
    }

    // MARK: - Empty Catch Detection

    func testDetectsEmptyCatch() {
        let code = """
        do {
            try riskyOperation()
        } catch {
        }
        """

        let issues = analyzer.detectBugs(code: code)

        XCTAssertTrue(issues
            .contains { $0.description.contains("Empty catch") || $0.description.contains("catch block") })
    }

    func testCatchWithHandlerNotFlagged() {
        let code = """
        do {
            try riskyOperation()
        } catch {
            print("Error: \\(error)")
        }
        """

        let issues = analyzer.detectBugs(code: code)

        let emptyCatchIssues = issues.filter { $0.description.contains("Empty catch") }
        XCTAssertEqual(emptyCatchIssues.count, 0)
    }

    // MARK: - UserDefaults Password Detection

    func testDetectsPasswordInUserDefaults() {
        let code = """
        UserDefaults.standard.set("secret", forKey: "password")
        """

        let issues = analyzer.detectSecurityIssues(code: code)

        XCTAssertTrue(issues
            .contains { $0.description.contains("UserDefaults") || $0.description.contains("password") })
    }

    // MARK: - Retain Cycle Detection

    func testDetectsStrongSelfInClosure() {
        let code = """
        someAsyncOperation { [self] in
            self.updateUI()
        }
        """

        let issues = analyzer.detectBugs(code: code)

        XCTAssertTrue(issues.contains { $0.description.contains("retain cycle") || $0.description.contains("self") })
    }

    func testWeakSelfNotFlagged() {
        let code = """
        someAsyncOperation { [weak self] in
            self?.updateUI()
        }
        """

        let issues = analyzer.detectBugs(code: code)

        let retainCycleIssues = issues.filter { $0.description.contains("retain cycle") }
        XCTAssertEqual(retainCycleIssues.count, 0)
    }

    // MARK: - Suggested Fix Tests

    func testPrintSuggestedFix() {
        let code = """
        print("Debug")
        """

        let issues = analyzer.detectStyleIssues(code: code)
        let printIssue = issues.first { $0.description.contains("print") }

        XCTAssertNotNil(printIssue?.suggestedFix)
        XCTAssertTrue(printIssue?.suggestedFix?.contains("Logger") ?? false)
    }
}
