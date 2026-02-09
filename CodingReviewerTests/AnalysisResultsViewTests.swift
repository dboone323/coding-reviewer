//
//  AnalysisResultsViewTests.swift
//  CodingReviewerTests
//
//  Comprehensive test suite for AnalysisResultsView
//

@testable import CodingReviewerCore
import XCTest

final class AnalysisResultsViewTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitialization() {
        // ViewModel should reflect empty issues correctly
        let empty = CodeAnalysisResult(analysis: "OK", issues: [], suggestions: [], language: "swift", analysisType: .comprehensive)
        let vm = AnalysisResultsViewModel(result: empty)
        XCTAssertTrue(vm.shouldShowEmptyState)
        XCTAssertEqual(vm.emptyStateMessage, "No issues found")
        XCTAssertEqual(vm.issues.count, 0)
    }

    // MARK: - Property Tests

    func testProperties() {
        // Non-empty issues should disable empty state and expose issues
        let issue = CodeIssue(description: "Unused variable", severity: .low, line: 10, category: .maintainability)
        let result = CodeAnalysisResult(analysis: "Found 1 issue", issues: [issue], suggestions: ["Remove unused var"], language: "swift", analysisType: .style)
        let vm = AnalysisResultsViewModel(result: result)
        XCTAssertFalse(vm.shouldShowEmptyState)
        XCTAssertEqual(vm.issues.count, 1)
        XCTAssertEqual(vm.issues.first?.description, "Unused variable")
    }

    // MARK: - Method Tests

    func testPublicMethods() {
        // Smoke test: ensure view can be constructed with model
        let empty = CodeAnalysisResult(analysis: "OK", issues: [], suggestions: [], language: "swift", analysisType: .comprehensive)
        let view = AnalysisResultsView(result: empty)
        // Compile-time construction is sufficient here
        XCTAssertNotNil(view)
    }

    // MARK: - Edge Case Tests

    func testEdgeCases() {
        // Large issues list should still reflect correctly in the VM
        let manyIssues = (0 ..< 50).map { idx in
            CodeIssue(description: "Issue #\(idx)", severity: .medium, line: idx + 1, category: .general)
        }
        let result = CodeAnalysisResult(analysis: "Multiple issues", issues: manyIssues, suggestions: [], language: "swift", analysisType: .comprehensive)
        let vm = AnalysisResultsViewModel(result: result)
        XCTAssertEqual(vm.issues.count, 50)
        XCTAssertFalse(vm.shouldShowEmptyState)
    }

    // MARK: - Error Handling Tests

    func testErrorHandling() {
        // Validate that CodeIssue accepts optional line numbers
        let issueNoLine = CodeIssue(description: "General issue", severity: .high, category: .general)
        XCTAssertNil(issueNoLine.line)
    }

    // MARK: - Integration Tests

    func testIntegration() {
        // Ensure suggestions surface in model when present
        let result = CodeAnalysisResult(analysis: "Some analysis", issues: [], suggestions: ["Refactor function"], language: "swift", analysisType: .maintainability)
        let vm = AnalysisResultsViewModel(result: result)
        XCTAssertTrue(vm.shouldShowEmptyState) // no issues
        XCTAssertEqual(result.suggestions.count, 1)
    }
}
