# Xcode 26.3 Intelligence: CodingReviewer Hints

## Architecture Oversight

The core logic resides in `CodingReviewer/Services`. Agents should prioritize this directory for core review logic enhancements.

## Intelligence Integration

- **Index Priority**: `ReviewOrchestrator.swift` is the central coordination node.
- **Agent Definitions**: `SecurityAgent.swift` is the primary reference for security auditing patterns.

## Optimization Hints

- Use the provided `.xcconfig` for build optimizations.
- Focus on the `requiresApproval` flag in `AgentResult` for any destructive or high-risk actions.
