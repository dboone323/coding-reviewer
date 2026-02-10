//
//  GitService.swift
//  CodingReviewer
//
//  Git command wrapper for source control integration
//

import Foundation

/// Git file change status
public enum GitChangeStatus: String, Sendable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case untracked = "??"
}

/// Represents a file change in git
public struct GitFileChange: Identifiable, Sendable {
    public let id = UUID()
    public let path: String
    public let status: GitChangeStatus
    public let isStaged: Bool
}

/// Git repository status
public struct GitStatus: Sendable {
    public var modified: [String] = []
    public var added: [String] = []
    public var deleted: [String] = []
    public var renamed: [String] = []
    public var untracked: [String] = []
    public var staged: [String] = []

    public var allChanges: [GitFileChange] {
        var changes: [GitFileChange] = []

        // Staged files
        for path in staged {
            let status: GitChangeStatus = if added.contains(path) {
                .added
            } else if deleted.contains(path) {
                .deleted
            } else if renamed.contains(path) {
                .renamed
            } else {
                .modified
            }

            changes.append(GitFileChange(path: path, status: status, isStaged: true))
        }

        // Unstaged files (not in staged list)
        for path in modified where !staged.contains(path) {
            changes.append(GitFileChange(path: path, status: .modified, isStaged: false))
        }
        for path in untracked {
            changes.append(GitFileChange(path: path, status: .untracked, isStaged: false))
        }
        for path in deleted where !staged.contains(path) {
            changes.append(GitFileChange(path: path, status: .deleted, isStaged: false))
        }

        return changes.sorted { $0.path < $1.path }
    }
}

/// Git service errors
public enum GitCommandError: Error, LocalizedError {
    case notARepository
    case commandFailed(String)
    case invalidDirectory
    case gitNotFound

    public var errorDescription: String? {
        switch self {
        case .notARepository:
            "Not a git repository"
        case let .commandFailed(message):
            "Git command failed: \(message)"
        case .invalidDirectory:
            "Invalid directory"
        case .gitNotFound:
            "Git executable not found"
        }
    }
}

/// Service for executing git commands
public actor GitService {
    private let gitPath = "/usr/bin/git"

    public init() {}

    // MARK: - Status Operations

    /// Get repository status
    public func status(in directory: URL) async throws -> GitStatus {
        let output = try await execute(["status", "--porcelain"], in: directory)
        return parseStatus(output)
    }

    /// Get diff for a file
    public func diff(file: String, in directory: URL, staged: Bool = false) async throws -> String {
        var args = ["diff"]
        if staged {
            args.append("--cached")
        }
        args.append(file)
        return try await execute(args, in: directory)
    }

    // MARK: - Staging Operations

    /// Stage files
    public func add(paths: [String], in directory: URL) async throws {
        _ = try await execute(["add"] + paths, in: directory)
    }

    /// Unstage files
    public func reset(paths: [String], in directory: URL) async throws {
        _ = try await execute(["reset", "HEAD", "--"] + paths, in: directory)
    }

    // MARK: - Commit Operations

    /// Commit staged changes
    public func commit(message: String, in directory: URL) async throws {
        _ = try await execute(["commit", "-m", message], in: directory)
    }

    // MARK: - Remote Operations

    /// Push to remote
    public func push(in directory: URL) async throws -> String {
        try await execute(["push"], in: directory)
    }

    /// Pull from remote
    public func pull(in directory: URL) async throws -> String {
        try await execute(["pull"], in: directory)
    }

    // MARK: - Branch Operations

    /// Get current branch name
    public func currentBranch(in directory: URL) async throws -> String {
        let output = try await execute(["branch", "--show-current"], in: directory)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// List all branches
    public func branches(in directory: URL) async throws -> [String] {
        let output = try await execute(["branch", "--list"], in: directory)
        return
            output
                .components(separatedBy: .newlines)
                .map {
                    $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "* ", with: "")
                }
                .filter { !$0.isEmpty }
    }

    /// Checkout a branch
    public func checkout(branch: String, in directory: URL) async throws {
        _ = try await execute(["checkout", branch], in: directory)
    }

    /// Get remote URL (for detecting GitHub repo)
    public func remoteURL(in directory: URL) async throws -> String? {
        do {
            let output = try await execute(["remote", "get-url", "origin"], in: directory)
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    // MARK: - Private Helpers

    private func execute(_ arguments: [String], in directory: URL) async throws -> String {
        // Verify directory exists
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw GitCommandError.invalidDirectory
        }

        // Verify git executable exists
        guard FileManager.default.fileExists(atPath: gitPath) else {
            throw GitCommandError.gitNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        // Check for "not a git repository" error
        if errorOutput.contains("not a git repository") {
            throw GitCommandError.notARepository
        }

        // Check exit code
        if process.terminationStatus != 0 {
            throw GitCommandError.commandFailed(errorOutput.isEmpty ? output : errorOutput)
        }

        return output
    }

    private func parseStatus(_ output: String) -> GitStatus {
        var status = GitStatus()

        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for line in lines {
            guard line.count >= 3 else { continue }

            let stagingStatus = String(line.prefix(1))
            let workingStatus = String(line.dropFirst().prefix(1))
            let filePath = String(line.dropFirst(3))

            // Parse staging area status (first column)
            switch stagingStatus {
            case "M":
                status.modified.append(filePath)
                status.staged.append(filePath)
            case "A":
                status.added.append(filePath)
                status.staged.append(filePath)
            case "D":
                status.deleted.append(filePath)
                status.staged.append(filePath)
            case "R":
                status.renamed.append(filePath)
                status.staged.append(filePath)
            default:
                break
            }

            // Parse working tree status (second column)
            switch workingStatus {
            case "M":
                if !status.modified.contains(filePath) {
                    status.modified.append(filePath)
                }
            case "D":
                if !status.deleted.contains(filePath) {
                    status.deleted.append(filePath)
                }
            default:
                break
            }

            // Untracked files
            if line.hasPrefix("??") {
                status.untracked.append(filePath)
            }
        }

        return status
    }
}
