//
// ConcurrencyManager.swift
// CodingReviewer
//
// Manages concurrent analysis tasks
//

import Foundation

actor ConcurrencyManager {
    static let shared = ConcurrencyManager()

    func performConcurrentAnalysis(files: [String], analyzer: @escaping @Sendable (String) async -> [CodeIssue]) async -> [String: [CodeIssue]] {
        return await withTaskGroup(of: (String, [CodeIssue]).self) { group in
            for file in files {
                group.addTask {
                    let issues = await analyzer(file)
                    return (file, issues)
                }
            }

            var results: [String: [CodeIssue]] = [:]
            for await (file, issues) in group {
                results[file] = issues
            }
            return results
        }
    }
}
