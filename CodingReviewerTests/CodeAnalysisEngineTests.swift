@testable import CodingReviewer
import XCTest

final class CodeAnalysisEngineTests: XCTestCase {
    
    var analysisEngine: CodeAnalysisEngine!
    
    override func setUp() {
        super.setUp()
        analysisEngine = CodeAnalysisEngine()
    }
    
    override func tearDown() {
        analysisEngine = nil
        super.tearDown()
    }
    
    // MARK: - Full Integration Tests
    
    func testAnalyzeSwiftFile() async throws {
        let swiftCode = """
        import Foundation
        
        class TestClass {
            func testMethod() {
                let value = optional!
                print("Debug")
                // TODO: Fix this
            }
        }
        """
        
        let result = analysisEngine.analyzeCode(code: swiftCode, language: "Swift", analysisTypes: [.comprehensive])
        
        XCTAssertGreaterThan(result.issues.count, 0)
        // Check for specific issue types based on description or category
        XCTAssertTrue(result.issues.contains { $0.description.contains("Force unwrapping") })
        XCTAssertTrue(result.issues.contains { $0.description.contains("Debug print") })
        XCTAssertTrue(result.issues.contains { $0.description.contains("TODO") })
    }
    
    func testAnalyzeMultipleFiles() async throws {
        // analyzeCode only handles one file string, so we test that
        let code = "let x = optional!"
        let result = analysisEngine.analyzeCode(code: code, language: "Swift", analysisTypes: [.bugs])
        
        XCTAssertGreaterThan(result.issues.count, 0)
    }
    
    func testGenerateReport() async throws {
        let swiftCode = """
        let value1 = optional!
        let value2 = another!
        // TODO: Implement
        """
        
        let result = analysisEngine.analyzeCode(code: swiftCode, language: "Swift", analysisTypes: [.comprehensive])
        let report = result.analysis
        
        XCTAssertTrue(report.contains("Analysis Summary"))
        XCTAssertGreaterThan(report.count, 10)
    }
    
    func testSeverityClassification() async throws {
        let code = """
        let safe = optionalValue ?? defaultValue
        let unsafe = optionalValue!
        """
        
        let result = analysisEngine.analyzeCode(code: code, language: "Swift", analysisTypes: [.bugs])
        
        // Force unwrap is medium severity in BugDetectionService
        let mediumSeverity = result.issues.filter { $0.severity == .medium }
        XCTAssertGreaterThan(mediumSeverity.count, 0)
    }
    
    func testEmptyFileHandling() async throws {
        let result = analysisEngine.analyzeCode(code: "", language: "Swift", analysisTypes: [.comprehensive])
        XCTAssertEqual(result.issues.count, 0)
    }
    
    func testPerformanceOnLargeFile() async throws {
        let largeCode = String(repeating: "let x = 1\n", count: 10000)
        
        let start = Date()
        _ = analysisEngine.analyzeCode(code: largeCode, language: "Swift", analysisTypes: [.bugs])
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(duration, 5.0, "Should analyze large file in under 5 seconds")
    }
}
