import Foundation
import SharedKit
import CodingReviewer

@available(macOS 15.0, *)
@main
struct LiveReviewTest {
    static func main() async {
        print(">>> [CodingReviewer Agent] Starting live review task...")

        // Mock Agent for testing
        struct SecurityAgent: BaseAgent {
            let id = "security_agent_001"
            let name = "Security Audit Agent"
            func execute(context: [String: any Sendable]) async throws -> AgentResult {
                let code = context["code"] as? String ?? ""
                var success = true
                var summary = "No security issues detected."

                if code.contains("print(\"password: \\(password)\")") {
                    success = false
                    summary = "Critical: Sensitive data leak in logs detected!"
                }

                return AgentResult(
                    agentId: id,
                    success: success,
                    summary: summary,
                    detail: ["severity": success ? "low" : "high"],
                    requiresApproval: !success
                )
            }
        }

        let orchestrator = ReviewOrchestrator(agents: [SecurityAgent()])
        let sampleCode = "let password = \"12345\"\nprint(\"password: \\(password)\")"

        print(">>> [Task] Analysing sample code for security vulnerabilities...")
        let results = await orchestrator.runReview(code: sampleCode, language: "swift")

        for result in results {
            print("\n--- Agent Result: \(result.agentId) ---")
            print("Status: \(result.success ? "SUCCESS" : "FAILURE")")
            print("Summary: \(result.summary)")
            print("Requires Approval: \(result.requiresApproval)")
            print("Timestamp: \(result.timestamp)")
        }

        print("\n>>> [CodingReviewer Agent] Task completed.")
    }
}
