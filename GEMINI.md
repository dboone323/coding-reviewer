# CodingReviewer: Agentic Grounding (Feb 2026)

## Purpose

CodingReviewer is a multi-agent system designed to perform automated, deep-dive code reviews with a focus on security, performance, and platform standards.

## Core Objectives

1. **Autonomous Security**: Proactively detect and gate common vulnerabilities (OWASP Top 10, memory safety).
2. **HITL Orchestration**: Use `ReviewOrchestrator` to gate high-risk findings behind manual approval (`requiresApproval`).
3. **Swift 6.2 Compliance**: Ensure all reviewed code adheres to strict concurrency standards.

## Agent Instructions

- **Security First**: Agents must prioritize vulnerability detection over stylistic changes.
- **Context Awareness**: Utilize `ProjectContext` to understand cross-file dependencies.
- **Actionable Feedback**: Provide specific file/line suggestions in `AgentResult`.

## Constraints

- Must not leak high-sensitivity credentials in review summaries.
- Adhere to the `BaseAgent` interface from `SharedKit`.

## March 2026 Code Standards

- **No Stubs/Mocks**: Do not use placeholders, mocks, or stubs in implementation or testing.
- **Production Ready**: Every new line of code must be real, working, and production-ready.
- **End-to-End Testing**: Use real working and tested code to verify behavior natively to avoid down-the-line problems.
- **Modern Standards**: Adhere strictly to the latest ecosystem standards (Swift 6.2 concurrency, Python 3.13).
