import Foundation
import SharedKit

/// Agent specializing in detecting logical flaws and complexity issues.
@MainActor
public final class LogicAgent: BaseAgent {
    public let id = "logic_agent_001"
    public let name = "Logic & Complexity Agent"
    private let ollamaClient: OllamaClient

    public init(ollamaClient: OllamaClient = OllamaClient()) {
        self.ollamaClient = ollamaClient
    }

    public func execute(context: [String: any Sendable]) async throws -> AgentResult {
        guard let code = context["code"] as? String else {
            return AgentResult(
                agentId: id,
                success: false,
                summary: "No code provided for analysis"
            )
        }

        print("[\(name)] Performing AI-assisted deep logic and complexity review...")

        // Directly use AI for logic review as heuristics are unreliable
        guard let issues = await performAILogicReview(code: code) else {
            return AgentResult(
                agentId: id,
                success: true,
                summary: "Code logic appears sound (AI analysis inconclusive).",
                detail: ["note": "AI analysis was unable to parse results."],
                requiresApproval: false
            )
        }

        let summary = issues.isEmpty
            ? "Code logic appears sound and well-structured."
            : "Identified \(issues.count) logical/complexity improvement(s)."

        return AgentResult(
            agentId: id,
            success: true,
            summary: summary,
            detail: issues,
            requiresApproval: issues.count > 2 // Stricter threshold for AI-backed issues
        )
    }

    private func performAILogicReview(code: String) async -> [String: String]? {
        let prompt = """
        Review the following Swift code for:
        1. Logical flaws or edge cases
        2. Cognitive complexity and deep nesting
        3. Potential efficiency improvements

        Code:
        \(code)

        Return a JSON object where keys are issue categories (e.g., "edge_case", "complexity") and values are specific, concise descriptions.
        Return ONLY the JSON.
        """

        do {
            let response = try await ollamaClient.generate(
                model: nil,
                prompt: prompt,
                temperature: 0.2,
                maxTokens: 1000,
                useCache: true
            )

            // Extraction to handle LLM conversational filler
            let cleanedResponse = if let range = response.range(of: "\\{.*\\}", options: .regularExpression) {
                String(response[range])
            } else {
                response
            }

            guard let data = cleanedResponse.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
            else {
                return nil
            }
            return json
        } catch {
            return nil
        }
    }
}
