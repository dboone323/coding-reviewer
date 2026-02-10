//
//  SourceControlViewModel.swift
//  CodingReviewer
//
//  View model for source control operations
//

import Foundation
import SwiftUI

/// View model managing git source control state
@MainActor
@Observable
public final class SourceControlViewModel {
    // State
    public var status: GitStatus?
    public var selectedFile: String?
    public var selectedFileDiff: String = ""
    public var commitMessage: String = ""
    public var currentBranch: String = "main"
    public var isLoading: Bool = false
    public var isLoadingDiff: Bool = false
    public var errorMessage: String?

    // Services
    private let gitService = GitService()
    private var projectDirectory: URL?

    public init(projectDirectory: URL? = nil) {
        self.projectDirectory = projectDirectory
        if let directory = projectDirectory {
            Task { await loadInitialState(for: directory) }
        }
    }

    // MARK: - Public Methods

    /// Set the project directory and load git state
    public func setProjectDirectory(_ directory: URL) {
        projectDirectory = directory
        Task { await loadInitialState(for: directory) }
    }

    /// Refresh git status
    public func refreshStatus() async {
        guard let directory = projectDirectory else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Get status
            status = try await gitService.status(in: directory)

            // Get current branch
            currentBranch = try await gitService.currentBranch(in: directory)
        } catch {
            handleError(error)
            status = nil
        }

        isLoading = false
    }

    /// Stage a file
    public func stageFile(_ path: String) async {
        guard let directory = projectDirectory else { return }

        do {
            try await gitService.add(paths: [path], in: directory)
            await refreshStatus()

            // Reload diff if this was the selected file
            if selectedFile == path {
                await loadDiff(for: path, staged: true)
            }
        } catch {
            handleError(error)
        }
    }

    /// Unstage a file
    public func unstageFile(_ path: String) async {
        guard let directory = projectDirectory else { return }

        do {
            try await gitService.reset(paths: [path], in: directory)
            await refreshStatus()

            // Reload diff if this was the selected file
            if selectedFile == path {
                await loadDiff(for: path, staged: false)
            }
        } catch {
            handleError(error)
        }
    }

    /// Commit staged changes
    public func commit() async {
        guard let directory = projectDirectory else { return }
        guard !commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Commit message cannot be empty"
            return
        }

        do {
            try await gitService.commit(message: commitMessage, in: directory)
            commitMessage = "" // Clear the message
            selectedFile = nil
            selectedFileDiff = ""
            await refreshStatus()
        } catch {
            handleError(error)
        }
    }

    /// Push to remote
    public func push() async {
        guard let directory = projectDirectory else { return }
        isLoading = true

        do {
            let output = try await gitService.push(in: directory)
            print("Push output: \(output)")
            await refreshStatus()
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Pull from remote
    public func pull() async {
        guard let directory = projectDirectory else { return }
        isLoading = true

        do {
            let output = try await gitService.pull(in: directory)
            print("Pull output: \(output)")
            await refreshStatus()
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Select a file and load its diff
    public func selectFile(_ path: String, staged: Bool) async {
        selectedFile = path
        await loadDiff(for: path, staged: staged)
    }

    // MARK: - Private Methods

    private func loadInitialState(for directory: URL) async {
        await refreshStatus()
    }

    private func loadDiff(for file: String, staged: Bool) async {
        guard let directory = projectDirectory else { return }
        isLoadingDiff = true
        selectedFileDiff = ""

        do {
            selectedFileDiff = try await gitService.diff(file: file, in: directory, staged: staged)
        } catch {
            handleError(error)
        }

        isLoadingDiff = false
    }

    private func handleError(_ error: Error) {
        if let gitError = error as? GitCommandError {
            errorMessage = gitError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
