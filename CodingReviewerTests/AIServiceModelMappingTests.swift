@testable import CodingReviewerCore
import XCTest

@MainActor
final class AIServiceModelMappingTests: XCTestCase {
    func testMapsCloudModelTagsToFreeOllamaModels() async throws {
        var models: [String] = []
        let service = AIEnhancedCodeAnalysisService(llmGenerate: { model, _, _ in
            models.append(model)
            return "OK"
        })

        _ = try await service.generateDocumentationWithAI("struct A {}", documentationType: .inline)
        _ = try await service.generateCodeWithAI(prompt: "Create a type A", language: "swift")
        _ = try await service.analyzeCodeWithAI("print(1)")

        XCTAssertTrue(models.contains("mistral:7b"), "gpt-oss should map to mistral:7b")
        XCTAssertTrue(models.contains("qwen2.5-coder:7b"), "qwen3-coder should map to qwen2.5-coder:7b")
        XCTAssertTrue(models.contains("llama3.1:8b"), "deepseek should map to llama3.1:8b")
    }
}
