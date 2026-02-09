//
// JavaScriptAnalyzerTests.swift
// CodingReviewerTests
//

import XCTest
@testable import CodingReviewerCore

final class JavaScriptAnalyzerTests: XCTestCase {
    let analyzer = JavaScriptAnalyzer()

    func testDetectEval() {
        let code = """
        function risky() {
            eval("console.log('pwned')");
        }
        """

        let issues = analyzer.detectSecurityIssues(code: code)
        XCTAssertTrue(issues.contains { $0.description.contains("eval()") }, "Should detect eval usage")
        XCTAssertEqual(issues.first?.category, .security)
        XCTAssertEqual(issues.first?.severity, .high)
    }

    func testDetectInnerHTML() {
        let code = """
        document.getElementById('foo').innerHTML = userContent;
        """

        let issues = analyzer.detectSecurityIssues(code: code)
        XCTAssertTrue(issues.contains { $0.description.contains("innerHTML") }, "Should detect innerHTML assignment")
        XCTAssertEqual(issues.first?.category, .security)
    }

    func testDetectConsoleLog() {
        let code = "console.log('debug info');"

        let issues = analyzer.detectStyleIssues(code: code)
        XCTAssertTrue(issues.contains { $0.description.contains("console.log") }, "Should detect console.log")
        XCTAssertEqual(issues.first?.category, .style)
    }

    func testNoFalsePositives() {
        let code = """
        function safe() {
            const evaluation = 5;
            const innerHTMLs = [];
        }
        """
        // The regex used in source might be simple.
        // eval\\( -> detects "eval("
        // \\.innerHTML\\s*= -> detects ".innerHTML ="

        let secIssues = analyzer.detectSecurityIssues(code: code)
        XCTAssertTrue(secIssues.isEmpty, "Should not flag variable names")
    }
}
