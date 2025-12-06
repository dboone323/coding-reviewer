//
// AnalysisCache.swift
// CodingReviewer
//
// Caching layer for analysis results
//

import Foundation

final class AnalysisCache: @unchecked Sendable {
    static let shared = AnalysisCache()
    private let cache = NSCache<NSString, CacheEntry>()

    class CacheEntry {
        let issues: [CodeIssue]
        let timestamp: Date

        init(issues: [CodeIssue]) {
            self.issues = issues
            self.timestamp = Date()
        }
    }

    func get(for code: String) -> [CodeIssue]? {
        let key = code.hashValue.description as NSString
        return cache.object(forKey: key)?.issues
    }

    func set(issues: [CodeIssue], for code: String) {
        let key = code.hashValue.description as NSString
        cache.setObject(CacheEntry(issues: issues), forKey: key)
    }
}
