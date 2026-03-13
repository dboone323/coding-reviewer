import Foundation
import SharedKit

/// Agent specializing in detecting logical flaws and complexity issues.
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

        print("[\(name)] Analyzing logic and cognitive complexity...")

        // 1. Heuristic Analysis
        var issues = performHeuristicAnalysis(code: code)

        // 2. AI-Assisted Deep Logic Review
        if let aiIssues = await performAILogicReview(code: code) {
            for (key, value) in aiIssues {
                issues["ai_\(key)"] = value
            }
        }

        let summary = issues.isEmpty
            ? "Code logic appears sound and well-structured."
            : "Identified \(issues.count) logical/complexity improvement(s)."

        return AgentResult(
            agentId: id,
            success: true,
            summary: summary,
            detail: issues,
            requiresApproval: issues.count > 3
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

        Return a JSON object where keys are issue categories and values are specific, concise descriptions.
        """

        return await MainActor.run {
            Task {
                do {
                    let response = try await ollamaClient.generate(
                        model: nil,
                        prompt: prompt,
                        temperature: 0.2,
                        maxTokens: 1000,
                        useCache: true
                    )

                    guard let data = response.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
                    else {
                        return nil
                    }
                    return json
                } catch {
                    return nil
                }
            }
        }.value
    }

    private func performHeuristicAnalysis(code: String) -> [String: String] {
        var issues: [String: String] = [:]
        let lines = code.components(separatedBy: .newlines)

        if lines.count > 300 {
            issues["complexity"] = "File exceeds 300 lines. Suggest refactoring into smaller components."
        }

        let ifCount = code.components(separatedBy: "if").count - 1
        let forCount = code.components(separatedBy: "for").count - 1
        if ifCount > 5 || forCount > 3 {
            issues["nested_structures"] = "Multiple control structures detected. Consider simplifying logic."
        }

        return issues
    }
}

/// Extension for additional utility methods
extension LogicAgent {
    /// Calculates a simple complexity score based on various code metrics
    private func calculateComplexityScore(code: String) -> Int {
        var score = 0

        // Count control structures
        score += (code.components(separatedBy: "if").count - 1) * 2
        score += (code.components(separatedBy: "for").count - 1) * 3
        score += (code.components(separatedBy: "while").count - 1) * 3
        score += (code.components(separatedBy: "switch").count - 1) * 2

        // Count method calls (simple heuristic)
        let dotCount = code.components(separatedBy: ".").count - 1
        score += max(0, dotCount - 10) // Only count beyond basic usage

        return score
    }
}
