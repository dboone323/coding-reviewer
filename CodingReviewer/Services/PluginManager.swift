//
// PluginManager.swift
// CodingReviewer
//
// Architecture for extending functionality
//

import Foundation

protocol ReviewerPlugin {
    var id: String { get }
    func analyze(code: String) -> [CodeIssue]
}

final class PluginManager: @unchecked Sendable {
    static let shared = PluginManager()
    private var plugins: [ReviewerPlugin] = []
    private let lock = NSLock()

    func register(_ plugin: ReviewerPlugin) {
        lock.lock()
        defer { lock.unlock() }
        plugins.append(plugin)
    }

    func runPlugins(code: String) -> [CodeIssue] {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        return currentPlugins.flatMap { $0.analyze(code: code) }
    }
}
