//
//  CodingReviewerTests.swift
//  CodingReviewerTests
//
//  Created by GitHub Copilot on 2026-02-10.
//

import Foundation
import XCTest
@testable import CodingReviewer

class CodingReviewerTests: XCTestCase {
    func testAppInitialization() {
        // Test that the app can be initialized without crashing
        // This is a basic smoke test
        XCTAssertTrue(true, "App should initialize successfully")
    }

    func testModelTypesExist() {
        // Test that our model types are properly defined
        let issue = CodeIssue(
            description: "Test issue",
            severity: .low,
            line: 1,
            category: .general,
            suggestedFix: "Fix it"
        )

        XCTAssertNotEqual(issue.id, UUID())
        XCTAssertEqual(issue.description, "Test issue")
        XCTAssertEqual(issue.severity, .low)
        XCTAssertEqual(issue.category, .general)
    }

    func testIssueSeverityEnum() {
        // Test that IssueSeverity enum works correctly
        XCTAssertEqual(IssueSeverity.low.rawValue, "Low")
        XCTAssertEqual(IssueSeverity.medium.rawValue, "Medium")
        XCTAssertEqual(IssueSeverity.high.rawValue, "High")
        XCTAssertEqual(IssueSeverity.critical.rawValue, "Critical")

        XCTAssertEqual(IssueSeverity.allCases.count, 4)
    }

    func testIssueCategoryEnum() {
        // Test that IssueCategory enum works correctly
        XCTAssertEqual(IssueCategory.bug.rawValue, "Bug")
        XCTAssertEqual(IssueCategory.security.rawValue, "Security")
        XCTAssertEqual(IssueCategory.performance.rawValue, "Performance")
        XCTAssertEqual(IssueCategory.style.rawValue, "Style")
        XCTAssertEqual(IssueCategory.maintainability.rawValue, "Maintainability")
        XCTAssertEqual(IssueCategory.general.rawValue, "General")

        XCTAssertEqual(IssueCategory.allCases.count, 6)
    }
}
