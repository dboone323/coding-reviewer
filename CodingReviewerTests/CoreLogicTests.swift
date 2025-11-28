@testable import CodingReviewer
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
    
    // MARK: - Code Parsing Tests
    
    func testParseSwiftCode() {
        let code = """
        import Foundation
        
        class TestClass {
            func testMethod() {
                print("Hello")
            }
        }
        """
        
        let result = bugDetectionService.parseCode(code)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testParseEmptyCode() {
        let result = bugDetectionService.parseCode("")
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Issue Detection Tests
    
    func testDetectForceUnwrap() {
        let code = "let value = optional!"
        let issues = bugDetectionService.detectIssues(in: code)
        
        let forceUnwrapIssues = issues.filter { $0.type == .forceUnwrap }
        XCTAssertGreaterThan(forceUnwrapIssues.count, 0)
    }
    
    func testDetectTODOComments() {
        let code = "// TODO: Fix this later"
        let issues = bugDetectionService.detectIssues(in: code)
        
        let todoIssues = issues.filter { $0.description.contains("TODO") }
        XCTAssertGreaterThan(todoIssues.count, 0)
    }
    
    func testDetectFIXMEComments() {
        let code = "// FIXME: This needs attention"
        let issues = bugDetectionService.detectIssues(in: code)
        
        let fixmeIssues = issues.filter { $0.description.contains("FIXME") }
        XCTAssertGreaterThan(fixmeIssues.count, 0)
    }
    
    func testDetectMultipleIssues() {
        let code = """
        let value = optional!
        // TODO: Implement error handling
        // FIXME: Refactor this
        """
        
        let issues = bugDetectionService.detectIssues(in: code)
        XCTAssertGreaterThanOrEqual(issues.count, 3)
    }
    
    // MARK: - Severity Calculation Tests
    
    func testForceUnwrap HasHighSeverity() {
        let code = "let value = optional!"
        let issues = bugDetectionService.detectIssues(in: code)
        
        let forceUnwrap = issues.first { $0.type == .forceUnwrap }
        XCTAssertEqual(forceUnwrap?.severity, .high)
    }
    
    func testTODOHasMediumSeverity() {
        let code = "// TODO: Fix this"
        let issues = bugDetectionService.detectIssues(in: code)
        
        let todo = issues.first { $0.description.contains("TODO") }
        XCTAssertEqual(todo?.severity, .medium)
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateReport() {
        let code = """
        let value = optional!
        // TODO: Add validation
        """
        
        let issues = bugDetectionService.detectIssues(in: code)
        let report = bugDetectionService.generateReport(for: issues)
        
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("Issues Found"))
    }
    
    func testReportContainsIssueCounts() {
        let code = """
        let val1 = optional!
        let val2 = another!
        // TODO: Fix
        """
        
        let issues = bugDetectionService.detectIssues(in: code)
        let report = bugDetectionService.generateReport(for: issues)
        
        XCTAssertTrue(report.contains("Total Issues"))
        XCTAssertGreaterThan(issues.count, 0)
    }
    
    // MARK: - File Filtering Tests
    
    func testFilterSwiftFiles() {
        let files = ["test.swift", "readme.md", "code.swift", "image.png"]
        let swiftFiles = bugDetectionService.filterSwiftFiles(files)
        
        XCTAssertEqual(swiftFiles.count, 2)
        XCTAssertTrue(swiftFiles.allSatisfy { $0.hasSuffix(".swift") })
    }
    
    func testFilterExcludesNonSwift() {
        let files = ["readme.md", "image.png", "data.json"]
        let swiftFiles = bugDetectionService.filterSwiftFiles(files)
        
        XCTAssertEqual(swiftFiles.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testHandlesMalformedCode() {
        let malformed = "let x = { ["
        
        // Should not crash
        let issues = bugDetectionService.detectIssues(in: malformed)
        XCTAssertNotNil(issues)
    }
    
    func testHandlesVeryLongCode() {
        let longCode = String(repeating: "let x = 1\n", count: 10000)
        
        // Should complete in reasonable time
        let startTime = Date()
        let issues = bugDetectionService.detectIssues(in: longCode)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 5.0) // Should take less than 5 seconds
        XCTAssertNotNil(issues)
    }
}
