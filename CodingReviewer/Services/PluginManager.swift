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

class PluginManager {
    static let shared = PluginManager()
    private var plugins: [ReviewerPlugin] = []
    
    func register(_ plugin: ReviewerPlugin) {
        plugins.append(plugin)
    }
    
    func runPlugins(code: String) -> [CodeIssue] {
        return plugins.flatMap { $0.analyze(code: code) }
    }
}
