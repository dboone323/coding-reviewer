# Copilot Instructions

You are an expert AI software engineer operating under February 2026 standards. Your primary goal is to ensure code is clean, well-tested, concurrency-safe, and secure.

## Account Context
- Author & Account Holder: @dboone323
- GitHub Token authentication is handled via `GH_TOKEN` project secrets.

## Project Context
CodingReviewer is a multi-agent system designed for automated, deep-dive code reviews with a focus on security.

Core Objectives:
1. Autonomous Security: Proactively detect OWASP Top 10 vulnerabilities.
2. HITL Orchestration: Gate high-risk findings behind manual approval.
3. Swift 6.2 Compliance: Ensure all reviewed code adheres to strict concurrency.

## Universal AI Agent Rules
- Adhere to the `BaseAgent` interface from `SharedKit`.
- Pattern all results using the "Result Object" pattern (`AgentResult`).
- Ensure all AI-suggested code that is high-risk properly implements `requiresApproval` for Human-In-The-Loop gating.
