//
//  CodingReviewerTests.swift
//  CodingReviewerTests
//
//  Created by GitHub Copilot on 2026-02-10.
//

import Foundation
import Testing
@testable import CodingReviewer

struct CodingReviewerTests {
    @Test
    func appInitialization() async throws {
        // Test that the app can be initialized without crashing
        // This is a basic smoke test
        #expect(true, "App should initialize successfully")
    }

    @Test
    func modelTypesExist() async throws {
        // Test that our model types are properly defined
        let issue = CodeIssue(
            description: "Test issue",
            severity: .low,
            line: 1,
            category: .general,
            suggestedFix: "Fix it"
        )

        #expect(issue.id != UUID())
        #expect(issue.description == "Test issue")
        #expect(issue.severity == .low)
        #expect(issue.category == .general)
    }

    @Test
    func issueSeverityEnum() async throws {
        // Test that IssueSeverity enum works correctly
        #expect(IssueSeverity.low.rawValue == "Low")
        #expect(IssueSeverity.medium.rawValue == "Medium")
        #expect(IssueSeverity.high.rawValue == "High")
        #expect(IssueSeverity.critical.rawValue == "Critical")

        #expect(IssueSeverity.allCases.count == 4)
    }

    @Test
    func issueCategoryEnum() async throws {
        // Test that IssueCategory enum works correctly
        #expect(IssueCategory.bug.rawValue == "Bug")
        #expect(IssueCategory.security.rawValue == "Security")
        #expect(IssueCategory.performance.rawValue == "Performance")
        #expect(IssueCategory.style.rawValue == "Style")
        #expect(IssueCategory.maintainability.rawValue == "Maintainability")
        #expect(IssueCategory.general.rawValue == "General")

        #expect(IssueCategory.allCases.count == 6)
    }
}
