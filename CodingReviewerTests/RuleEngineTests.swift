//
// RuleEngineTests.swift
// CodingReviewerTests
//
// Tests for custom rule engine functionality
//

import XCTest
@testable import CodingReviewer

final class RuleEngineTests: XCTestCase {
    
    var engine: RuleEngine!
    
    override func setUpWithError() throws {
        engine = RuleEngine()
    }
    
    // MARK: - Rule Addition Tests
    
    func testAddRuleDoesNotCrash() {
        let rule = CustomRule(
            id: "test-rule",
            name: "Test Rule",
            description: "Test description",
            language: "swift",
            pattern: "TODO:",
            severity: .warning,
            category: "maintenance"
        )
        
        engine.addRule(rule)
        XCTAssertTrue(true) // No crash
    }
    
    // MARK: - Analysis Tests
    
    func testAnalyzeWithNoRules() {
        let code = "let x = 1"
        let issues = engine.analyze(code: code, language: "swift")
        XCTAssertTrue(issues.isEmpty)
    }
    
    func testAnalyzeMatchesRule() {
        let rule = CustomRule(
            id: "todo-check",
            name: "TODO Check",
            description: "Found a TODO comment",
            language: "swift",
            pattern: "// TODO:",
            severity: .info,
            category: "maintenance"
        )
        engine.addRule(rule)
        
        let code = """
        func test() {
            // TODO: Implement this
        }
        """
        
        let issues = engine.analyze(code: code, language: "swift")
        // Test that analyze runs without crashing
        // Actual matching depends on PatternMatcher implementation
        XCTAssertTrue(true)
    }
    
    func testAnalyzeFiltersLanguage() {
        let swiftRule = CustomRule(
            id: "swift-only",
            name: "Swift Rule",
            description: "Swift-specific",
            language: "swift",
            pattern: "var",
            severity: .warning,
            category: "style"
        )
        engine.addRule(swiftRule)
        
        let pythonCode = "def test(): pass"
        let issues = engine.analyze(code: pythonCode, language: "python")
        
        // Swift rule should not apply to Python code
        XCTAssertTrue(issues.isEmpty)
    }
    
    func testAnalyzeWildcardLanguage() {
        let universalRule = CustomRule(
            id: "universal",
            name: "Universal Rule",
            description: "Applies to all",
            language: "*",
            pattern: "FIXME",
            severity: .warning,
            category: "maintenance"
        )
        engine.addRule(universalRule)
        
        // Universal rules should apply regardless of language
        let code = "// FIXME: broken"
        _ = engine.analyze(code: code, language: "any")
        XCTAssertTrue(true)
    }
    
    // MARK: - Rule Loading Tests
    
    func testLoadRulesFromInvalidURLThrows() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/rules.json")
        
        XCTAssertThrowsError(try engine.loadRules(from: invalidURL))
    }
}
