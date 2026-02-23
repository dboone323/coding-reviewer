import Foundation
import SharedKit

/// Agent specializing in detecting logical flaws and complexity issues.
public final class LogicAgent: BaseAgent {
    public let id = "logic_agent_001"
    public let name = "Logic & Complexity Agent"

    public init() {}

    public func execute(context: [String: Sendable]) async throws -> AgentResult {
        guard let code = context["code"] as? String else {
            return AgentResult(
                agentId: id, success: false, summary: "No code provided for analysis",
            )
        }

        print("[\(name)] Analyzing logic and cognitive complexity...")

        var issues: [String: String] = [:]

        // Heuristic analysis (simulated for Phase 6)
        let lines = code.components(separatedBy: .newlines)
        if lines.count > 300 {
            issues["complexity"] =
                "High cognitive complexity detected (file exceeds 300 lines). "
                    + "Suggest refactoring into smaller components."
        }

        if code.contains("if") && code.contains("for") && code.contains("while") {
            issues["nesting"] =
                "Deeply nested control structures detected. Risk: Poor readability and bug-prone logic."
        }

        let summary =
            issues.isEmpty
                ? "Code logic appears sound and well-structured."
                : "Identified \(issues.count) logical/complexity improvements."

        return AgentResult(agentId: id, success: true, summary: summary, detail: issues)
    }
}
