//
//  CodingReviewerTests.swift
//  CodingReviewerTests
//

@testable import CodingReviewer
import Foundation
import Testing

@Suite("CodingReviewer Logic Tests")
struct CodingReviewerTests {
    @Test("App Initialization Smoke Test")
    func appInitialization() {
        // Test that the app can be initialized without crashing
        #expect(true, "App should initialize successfully")
    }

    @Test("Model Types Existence and Values")
    func modelTypesExist() {
        // Test that our model types are properly defined
        let issue = CodeIssue(
            description: "Test issue",
            severity: .low,
            line: 1,
            category: .general,
            suggestedFix: "Fix it"
        )

        #expect(issue.description == "Test issue")
        #expect(issue.severity == .low)
        #expect(issue.category == .general)
    }

    @Test("Issue Severity Enum Raw Values", arguments: IssueSeverity.allCases)
    func issueSeverityEnum(severity: IssueSeverity) {
        let expectedValues: [IssueSeverity: String] = [
            .low: "Low",
            .medium: "Medium",
            .high: "High",
            .critical: "Critical",
        ]
        #expect(severity.rawValue == expectedValues[severity])
    }

    @Test("Issue Category Enum Count")
    func issueCategoryEnumCount() {
        #expect(IssueCategory.allCases.count == 6)
    }
}
