//
// CodeSmellDetectorTests.swift
// CodingReviewerTests
//

@testable import CodingReviewerCore
import XCTest

final class CodeSmellDetectorTests: XCTestCase {
    let detector = CodeSmellDetector()

    func testDetectShortMethod() {
        let code = """
        func short() {
            print("Hello")
        }
        """
        let issues = detector.detectSmells(code: code, language: "Swift")
        XCTAssertTrue(issues.isEmpty)
    }

    func testDetectLongMethod() {
        // Create a fake long method
        var code = "func longMethod() {\n"
        for i in 0 ..< 60 {
            code += "    print(\(i))\n"
        }
        code += "}\n"

        // CodeSmellDetector counts lines between "func|def|function" lines.
        // It resets count when it sees new func definition.
        // Logic:
        // for (index, line) in lines.enumerated() {
        //    if line contains "func " ... {
        //       if currentMethodLength > 50 -> report previous method?
        //       ...
        //    } else { currentMethodLength += 1 }
        // }
        // check last method at end loop.

        // So for one method, it accumulates length and checks at the end of loop if no subsequent func.

        let issues = detector.detectSmells(code: code, language: "Swift")
        XCTAssertFalse(issues.isEmpty, "Should detect long method")
        XCTAssertTrue(issues.contains { $0.description.contains("Long method") })
    }

    func testMultipleMethods_CheckReset() {
        var code = "func method1() {\n"
        // 10 lines
        for _ in 0 ..< 10 {
            code += "\n"
        }
        code += "}\n"

        code += "func method2() {\n"
        // 10 lines
        for _ in 0 ..< 10 {
            code += "\n"
        }
        code += "}\n"

        let issues = detector.detectSmells(code: code, language: "Swift")
        XCTAssertTrue(issues.isEmpty, "Short methods should not trigger warning")
    }
}
