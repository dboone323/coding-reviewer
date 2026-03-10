import Foundation
import SharedKit

/// Agent specializing in detecting logical flaws and complexity issues.
public final class LogicAgent: BaseAgent {
    public let id = "logic_agent_001"
    public let name = "Logic & Complexity Agent"

    public init() {}

    public func execute(context: [String: any Sendable]) async throws -> AgentResult {
        guard let code = context["code"] as? String else {
            return AgentResult(
                agentId: id,
                success: false,
                summary: "No code provided for analysis"
            )
        }

        print("[\(name)] Analyzing logic and cognitive complexity...")

        var issues: [String: String] = [:]

        // Heuristic analysis
        let lines = code.components(separatedBy: .newlines)
        if lines.count > 300 {
            issues["complexity"] = "High cognitive complexity detected (file exceeds 300 lines). Suggest refactoring into smaller components."
        }

        // Check for nested control structures
        let ifCount = code.components(separatedBy: "if").count - 1
        let forCount = code.components(separatedBy: "for").count - 1
        let whileCount = code.components(separatedBy: "while").count - 1

        if ifCount > 5 || forCount > 3 || whileCount > 3 {
            issues["nested_structures"] = "Multiple control structures detected (if: \(ifCount), for: \(forCount), while: \(whileCount)). Consider simplifying logic."
        }

        // Check for long methods
        let methodPattern = try? NSRegularExpression(pattern: "func\\s+\\w+\\s*\\([^)]*\\)\\s*\\{", options: [])
        let range = NSRange(code.startIndex ..< code.endIndex, in: code)
        let methodMatches = methodPattern?.matches(in: code, options: [], range: range) ?? []

        for match in methodMatches {
            if let methodRange = Range(match.range, in: code) {
                let methodStart = code.index(
                    methodRange.lowerBound,
                    offsetBy: code.distance(from: code.startIndex, to: methodRange.lowerBound)
                )
                if let methodEndRange = code.range(of: "}", range: methodStart ..< code.endIndex) {
                    let methodContent = String(code[methodRange.upperBound ..< methodEndRange.lowerBound])
                    let methodLines = methodContent.components(separatedBy: .newlines).count

                    if methodLines > 50 {
                        issues["long_method"] = "Method exceeds 50 lines. Consider breaking it into smaller functions."
                        break
                    }
                }
            }
        }

        let summary = issues.isEmpty
            ? "Code logic appears sound and well-structured."
            : "Identified \(issues.count) logical/complexity improvement(s)."

        return AgentResult(agentId: id, success: true, summary: summary, detail: issues)
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
