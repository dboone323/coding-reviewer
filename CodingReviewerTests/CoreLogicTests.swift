@testable import CodingReviewerCore
import XCTest

final class CoreLogicTests: XCTestCase {
    var bugDetectionService: BugDetectionService!

    override func setUp() {
        super.setUp()
        bugDetectionService = BugDetectionService()
    }

    override func tearDown() {
        bugDetectionService = nil
        super.tearDown()
    }

    // MARK: - Issue Detection Tests

    func testDetectForceUnwrap() {
        let code = "let value = optional!"
        let issues = bugDetectionService.detectBasicBugs(code: code, language: "Swift")

        let forceUnwrapIssues = issues.filter { $0.description.contains("Force unwrapping") }
        XCTAssertGreaterThan(forceUnwrapIssues.count, 0)
    }

    func testDetectTODOComments() {
        let code = "// TODO: Fix this later"
        let issues = bugDetectionService.detectBasicBugs(code: code, language: "Swift")

        let todoIssues = issues.filter { $0.description.contains("TODO") }
        XCTAssertGreaterThan(todoIssues.count, 0)
    }

    func testDetectFIXMEComments() {
        let code = "// FIXME: This needs attention"
        let issues = bugDetectionService.detectBasicBugs(code: code, language: "Swift")

        let fixmeIssues = issues.filter { $0.description.contains("FIXME") }
        XCTAssertGreaterThan(fixmeIssues.count, 0)
    }

    func testDetectMultipleIssues() {
        let code = """
        let value = optional!
        // TODO: Implement error handling
        // FIXME: Refactor this
        """

        let issues = bugDetectionService.detectBasicBugs(code: code, language: "Swift")
        XCTAssertGreaterThanOrEqual(issues.count, 3)
    }

    // MARK: - Severity Calculation Tests

    func testForceUnwrapHasMediumSeverity() {
        let code = "let value = optional!"
        let issues = bugDetectionService.detectBasicBugs(code: code, language: "Swift")

        XCTAssertFalse(issues.isEmpty)
        XCTAssertEqual(issues.first?.severity, .medium)
    }

    func testTODOHasMediumSeverity() {
        let code = "// TODO: Fix this"
        let issues = bugDetectionService.detectBasicBugs(code: code, language: "Swift")

        let todo = issues.first { $0.description.contains("TODO") }
        XCTAssertEqual(todo?.severity, .medium)
    }

    // MARK: - Edge Cases

    func testHandlesMalformedCode() {
        let malformed = "let x = { ["

        // Should not crash
        let issues = bugDetectionService.detectBasicBugs(code: malformed, language: "Swift")
        XCTAssertNotNil(issues)
    }

    func testHandlesVeryLongCode() {
        let longCode = String(repeating: "let x = 1\n", count: 10000)

        // Should complete in reasonable time
        let startTime = Date()
        let issues = bugDetectionService.detectBasicBugs(code: longCode, language: "Swift")
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 5.0) // Should take less than 5 seconds
        XCTAssertNotNil(issues)
    }
}
