@testable import CodingReviewer
import XCTest

final class SentimentScoringServiceTests: XCTestCase {
    func testKeywordFallbackPositiveAndNegative() {
        let keyword = KeywordSentimentScoringService()
        let pos = keyword.scoreSync(text: "I love this excellent app, amazing and wonderful!")
        let neg = keyword.scoreSync(text: "This is a terrible, broken and awful crash")
        XCTAssertEqual(pos.label, "positive")
        XCTAssertGreaterThan(pos.score, 0.2)
        XCTAssertEqual(neg.label, "negative")
        XCTAssertLessThan(neg.score, -0.2)
    }

    func testOllamaSentimentParsesJson() async {
        struct FakeLLM: LLMClient {
            func generate(model _: String, prompt _: String, temperature _: Double) async throws -> String {
                "{\"label\":\"neutral\",\"score\":0.0}"
            }
        }
        let svc = OllamaSentimentScoringService(llm: FakeLLM(), model: "llama3.1:8b")
        let result = await svc.score(text: "Neutral statement")
        XCTAssertEqual(result.label, "neutral")
        XCTAssertEqual(result.score, 0.0, accuracy: 0.0001)
    }
}
