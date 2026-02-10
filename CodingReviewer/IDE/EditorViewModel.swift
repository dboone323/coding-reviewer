//
//  EditorViewModel.swift
//  CodingReviewer
//
//  Observable model managing open files, tabs, and editor state
//

import Foundation
import SwiftUI

/// Represents a single open file in the editor
public struct OpenFile: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public var content: String
    public var language: String
    public var isModified: Bool

    public var filename: String { url.lastPathComponent }

    public init(url: URL, content: String, language: String) {
        self.id = UUID()
        self.url = url
        self.content = content
        self.language = language
        self.isModified = false
    }

    public static func == (lhs: OpenFile, rhs: OpenFile) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manages the editor state including open files and active tab
@MainActor
@Observable
public final class EditorViewModel {
    public var openFiles: [OpenFile] = []
    public var activeFileID: UUID?
    public var projectRootURL: URL?

    public var activeFile: OpenFile? {
        guard let id = activeFileID else { return nil }
        return openFiles.first(where: { $0.id == id })
    }

    public var activeFileIndex: Int? {
        guard let id = activeFileID else { return nil }
        return openFiles.firstIndex(where: { $0.id == id })
    }

    // MARK: - File Operations

    public func openFile(url: URL) {
        // Check if already open
        if let existing = openFiles.first(where: { $0.url == url }) {
            activeFileID = existing.id
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let language = detectLanguage(for: url)
            let file = OpenFile(url: url, content: content, language: language)
            openFiles.append(file)
            activeFileID = file.id
        } catch {
            print("Failed to open file: \(error.localizedDescription)")
        }
    }

    public func closeFile(id: UUID) {
        guard let index = openFiles.firstIndex(where: { $0.id == id }) else { return }
        openFiles.remove(at: index)

        if activeFileID == id {
            if openFiles.isEmpty {
                activeFileID = nil
            } else {
                let newIndex = min(index, openFiles.count - 1)
                activeFileID = openFiles[newIndex].id
            }
        }
    }

    public func closeAllFiles() {
        openFiles.removeAll()
        activeFileID = nil
    }

    public func saveFile(id: UUID) {
        guard let index = openFiles.firstIndex(where: { $0.id == id }) else { return }
        let file = openFiles[index]

        do {
            try file.content.write(to: file.url, atomically: true, encoding: .utf8)
            openFiles[index].isModified = false
        } catch {
            print("Failed to save file: \(error.localizedDescription)")
        }
    }

    public func saveActiveFile() {
        guard let id = activeFileID else { return }
        saveFile(id: id)
    }

    public func updateContent(_ newContent: String, for id: UUID) {
        guard let index = openFiles.firstIndex(where: { $0.id == id }) else { return }
        if openFiles[index].content != newContent {
            openFiles[index].content = newContent
            openFiles[index].isModified = true
        }
    }

    // MARK: - Tab Navigation

    public func selectTab(id: UUID) {
        activeFileID = id
    }

    public func selectNextTab() {
        guard let current = activeFileIndex, !openFiles.isEmpty else { return }
        let next = (current + 1) % openFiles.count
        activeFileID = openFiles[next].id
    }

    public func selectPreviousTab() {
        guard let current = activeFileIndex, !openFiles.isEmpty else { return }
        let prev = current == 0 ? openFiles.count - 1 : current - 1
        activeFileID = openFiles[prev].id
    }

    // MARK: - Project

    public func openFolder(url: URL) {
        projectRootURL = url
    }

    // MARK: - Language Detection

    private func detectLanguage(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "python"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "jsx": return "javascript"
        case "tsx": return "typescript"
        case "html", "htm": return "html"
        case "css": return "css"
        case "json": return "json"
        case "yaml", "yml": return "yaml"
        case "md", "markdown": return "markdown"
        case "sh", "bash", "zsh": return "bash"
        case "rb": return "ruby"
        case "go": return "go"
        case "rs": return "rust"
        case "c", "h": return "c"
        case "cpp", "hpp", "cc": return "cpp"
        case "m": return "objective-c"
        case "java": return "java"
        case "kt": return "kotlin"
        case "xml", "plist": return "xml"
        case "sql": return "sql"
        case "toml": return "toml"
        case "dockerfile": return "dockerfile"
        default: return "plainText"
        }
    }
}
