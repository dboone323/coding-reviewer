import Testing
@testable import CodingReviewerCore

struct CodingReviewerCoreTests {
    @Test func testReviewEngineInitialization() async throws {
        let engine = ReviewEngine.shared
        let code = "let x = 10"
        let issues = await engine.analyze(code: code, language: "Swift", rules: [])
        #expect(issues.isEmpty) // Basic case should be clean
    }
}
