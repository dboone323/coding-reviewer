import Foundation
import SharedKit

/// Orchestrator that coordinates multiple specialized agents for code review.
@MainActor
public final class ReviewOrchestrator {
    private let agents: [BaseAgent]

    public init(agents: [BaseAgent]) {
        self.agents = agents
    }

    /// Run all agents on the provided code and aggregate results
    public func runReview(code: String, language: String) async -> [AgentResult] {
        var results: [AgentResult] = []
        let context: [String: Sendable] = ["code": code, "language": language]

        await withTaskGroup(of: AgentResult?.self) { group in
            for agent in agents {
                group.addTask { @Sendable in
                    try? await agent.execute(context: context)
                }
            }

            for await result in group {
                if let res = result {
                    results.append(res)
                }
            }
        }

        // 2026 HITL Governance: Flag high-risk results for manual approval
        return results.map { result in
            if result.agentId.contains("security") && !result.success {
                return AgentResult(
                    agentId: result.agentId,
                    success: result.success,
                    summary: result.summary,
                    detail: result.detail,
                    requiresApproval: true,
                )
            }
            return result
        }
    }
}
