//
// AnalysisCacheTests.swift
// CodingReviewerTests
//
// Tests for analysis result caching
//

import XCTest
@testable import CodingReviewer

final class AnalysisCacheTests: XCTestCase {
    var cache: AnalysisCache!

    override func setUpWithError() throws {
        cache = AnalysisCache.shared
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = AnalysisCache.shared
        let instance2 = AnalysisCache.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Cache Miss Tests

    func testGetReturnsNilForUncachedCode() {
        let uncachedCode = "unique_code_\(UUID().uuidString)"
        let result = cache.get(for: uncachedCode)
        XCTAssertNil(result)
    }

    // MARK: - Cache Set/Get Tests

    func testSetAndGetRoundTrip() {
        let code = "let x = 1"
        let issues = [
            CodeIssue(
                description: "Test issue",
                severity: .medium,
                line: 1,
                category: .general
            ),
        ]

        cache.set(issues: issues, for: code)

        let cached = cache.get(for: code)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
        XCTAssertEqual(cached?.first?.description, "Test issue")
    }

    func testSetEmptyIssues() {
        let code = "empty_test"
        cache.set(issues: [], for: code)

        let cached = cache.get(for: code)
        XCTAssertNotNil(cached)
        XCTAssertTrue(cached?.isEmpty ?? false)
    }

    func testOverwritesCachedValue() {
        let code = "overwrite_test"

        let firstIssues = [
            CodeIssue(description: "First", severity: .low, line: 1, category: .general),
        ]
        cache.set(issues: firstIssues, for: code)

        let secondIssues = [
            CodeIssue(description: "Second", severity: .high, line: 2, category: .general),
        ]
        cache.set(issues: secondIssues, for: code)

        let cached = cache.get(for: code)
        XCTAssertEqual(cached?.first?.description, "Second")
    }

    // MARK: - Multiple Code Entries

    func testMultipleEntriesCachedSeparately() {
        let code1 = "code_one"
        let code2 = "code_two"

        let issues1 = [
            CodeIssue(description: "Issue 1", severity: .low, line: 1, category: .general),
        ]
        let issues2 = [
            CodeIssue(description: "Issue 2", severity: .high, line: 2, category: .general),
        ]

        cache.set(issues: issues1, for: code1)
        cache.set(issues: issues2, for: code2)

        XCTAssertEqual(cache.get(for: code1)?.first?.description, "Issue 1")
        XCTAssertEqual(cache.get(for: code2)?.first?.description, "Issue 2")
    }
}
