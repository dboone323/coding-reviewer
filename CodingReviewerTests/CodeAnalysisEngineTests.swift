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
        
        let result = try await analysisEngine.analyze(code: swiftCode, language: "Swift")
        
        XCTAssertGreaterThan(result.issues.count, 0)
        XCTAssertTrue(result.issues.contains { $0.category == .forceUnwrap })
        XCTAssertTrue(result.issues.contains { $0.category == .debugCode })
        XCTAssertTrue(result.issues.contains { $0.category == .todo })
    }
    
    func testAnalyzeMultipleFiles() async throws {
        let files = [
            ("File1.swift", "let x = optional!"),
            ("File2.swift", "// FIXME: Broken"),
            ("File3.swift", "print('debug')")
        ]
        
        let results = try await analysisEngine.analyzeMultipleFiles(files)
        
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.issues.count > 0 })
    }
    
    func testGenerateReport() async throws {
        let swiftCode = """
        let value1 = optional!
        let value2 = another!
        // TODO: Implement
        """
        
        let result = try await analysisEngine.analyze(code: swiftCode, language: "Swift")
        let report = analysisEngine.generateReport(from: result)
        
        XCTAssertTrue(report.contains("Analysis Report"))
        XCTAssertTrue(report.contains("Total Issues"))
        XCTAssertGreaterThan(report.count, 100)
    }
    
    func testSeverityClassification() async throws {
        let code = """
        let safe = optionalValue ?? defaultValue
        let unsafe = optionalValue!
        """
        
        let result = try await analysisEngine.analyze(code: code, language: "Swift")
        
        let highSeverity = result.issues.filter { $0.severity == .high }
        XCTAssertGreaterThan(highSeverity.count, 0)
    }
    
    func testCodeMetrics() async throws {
        let code = """
        class LargeClass {
            func method1() { }
            func method2() { }
            func method3() { }
            func method4() { }
            func method5() { }
            func method6() { }
            func method7() { }
            func method8() { }
            func method9() { }
            func method10() { }
        }
        """
        
        let metrics = analysisEngine.calculateMetrics(for: code)
        
        XCTAssertGreaterThan(metrics.methodCount, 5)
        XCTAssertGreaterThan(metrics.lineCount, 10)
    }
    
    func testComplexityAnalysis() async throws {
        let complexCode = """
        func complex(x: Int) -> Int {
            if x > 10 {
                if x < 20 {
                    if x % 2 == 0 {
                        return x * 2
                    } else {
                        return x + 1
                    }
                }
            }
            return 0
        }
        """
        
        let complexity = analysisEngine.calculateCyclomaticComplexity(for: complexCode)
        XCTAssertGreaterThan(complexity, 3)
    }
    
    func testEmptyFileHandling() async throws {
        let result = try await analysisEngine.analyze(code: "", language: "Swift")
        XCTAssertEqual(result.issues.count, 0)
    }
    
    func testUnsupportedLanguage() async throws {
        do {
            _ = try await analysisEngine.analyze(code: "code", language: "Unknown")
            XCTFail("Should throw unsupported language error")
        } catch {
            XCTAssertTrue(error is AnalysisError)
        }
    }
    
    func testPerformanceOnLargeFile() async throws {
        let largeCode = String(repeating: "let x = 1\n", count: 10000)
        
        let start = Date()
        _ = try await analysisEngine.analyze(code: largeCode, language: "Swift")
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(duration, 5.0, "Should analyze large file in under 5 seconds")
    }
}

enum AnalysisError: Error {
    case unsupportedLanguage
}
