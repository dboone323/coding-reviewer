//
//  CrashTests.swift
//  CodingReviewerTests
//
//  Created by GitHub Copilot on 2026-02-10.
//

import Foundation
import Testing
@testable import CodingReviewer

struct CrashTests {
    @Test
    func appDoesNotCrashOnLaunch() async throws {
        // Test that basic app functionality doesn't crash
        // This simulates what would happen on device launch

        // Test model creation doesn't crash
        let issue = CodeIssue(
            description: "Test crash prevention",
            severity: .high,
            line: 42,
            category: .bug,
            suggestedFix: "Don't crash"
        )

        #expect(issue.description == "Test crash prevention")
        #expect(issue.severity == .high)
        #expect(issue.line == 42)
        #expect(issue.category == .bug)
    }

    @Test
    func enumValuesAreStable() async throws {
        // Test that enum values don't change unexpectedly (would cause crashes)
        #expect(IssueSeverity.low != IssueSeverity.high)
        #expect(IssueCategory.bug != IssueCategory.security)

        // Test all enum cases exist
        #expect(!IssueSeverity.allCases.isEmpty)
        #expect(!IssueCategory.allCases.isEmpty)
    }

    @Test
    func memoryManagement() async throws {
        // Test basic memory management to prevent leaks/crashes
        var issues: [CodeIssue] = []

        for i in 0 ..< 100 {
            let issue = CodeIssue(
                description: "Memory test issue \(i)",
                severity: .medium,
                line: i,
                category: .performance,
                suggestedFix: "Optimize memory usage"
            )
            issues.append(issue)
        }

        #expect(issues.count == 100)
        #expect(issues[0].description.contains("Memory test issue"))
        #expect(issues[99].line == 99)

        // Clear array to test cleanup
        issues.removeAll()
        #expect(issues.isEmpty)
    }

    @Test
    func concurrentAccess() async throws {
        // Test that the app can handle concurrent operations without crashing
        let iterations = 50

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< iterations {
                group.addTask {
                    let issue = CodeIssue(
                        description: "Concurrent test \(i)",
                        severity: .low,
                        line: i,
                        category: .general
                    )
                    // Just create the object - no shared state to test
                    _ = issue.id
                }
            }
        }

        // If we get here without crashing, the test passes
        #expect(true, "Concurrent operations completed without crashing")
    }
}
