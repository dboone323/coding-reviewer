//
//  GitHubPanelViewModel.swift
//  CodingReviewer
//
//  View model for GitHub panel
//

import Foundation

/// View model for GitHub panel
@MainActor
@Observable
public final class GitHubPanelViewModel {
    // State
    public var repo: GitHubRepo?
    public var pullRequests: [PullRequest] = []
    public var issues: [Issue] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    // Services
    private let githubService = GitHubService()
    private let gitService = GitService()
    private var projectDirectory: URL?

    public init(projectDirectory: URL? = nil) {
        self.projectDirectory = projectDirectory
        if projectDirectory != nil {
            Task { await detectCurrentRepo() }
        }
    }

    // MARK: - Public Methods

    /// Set project directory and refresh
    public func setProjectDirectory(_ directory: URL) {
        projectDirectory = directory
        Task { await detectCurrentRepo() }
    }

    /// Detect current repository from git remote
    public func detectCurrentRepo() async {
        guard let directory = projectDirectory else {
            errorMessage = "No project directory set"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Get git remote URL
            guard let remoteURL = try await gitService.remoteURL(in: directory) else {
                errorMessage = "No GitHub remote found"
                isLoading = false
                return
            }

            // Parse GitHub owner/repo from URL
            guard let (owner, repoName) = parseGitHubURL(remoteURL) else {
                errorMessage = "Invalid GitHub repository URL"
                isLoading = false
                return
            }

            // Fetch repository details
            repo = try await githubService.getRepository(owner: owner, repo: repoName)

            // Load PRs and issues
            await loadPullRequests()
            await loadIssues()

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Load pull requests for the current repo
    public func loadPullRequests() async {
        guard let repo = repo else { return }

        let parts = repo.fullName.components(separatedBy: "/")
        guard parts.count == 2 else { return }

        do {
            pullRequests = try await githubService.listPullRequests(owner: parts[0], repo: parts[1])
        } catch {
            handleError(error)
        }
    }

    /// Load issues for the current repo
    public func loadIssues() async {
        guard let repo = repo else { return }

        let parts = repo.fullName.components(separatedBy: "/")
        guard parts.count == 2 else { return }

        do {
            issues = try await githubService.listIssues(owner: parts[0], repo: parts[1])
        } catch {
            handleError(error)
        }
    }

    /// Create a new issue
    public func createIssue(title: String, body: String) async {
        guard let repo = repo else { return }

        let parts = repo.fullName.components(separatedBy: "/")
        guard parts.count == 2 else { return }

        do {
            let newIssue = try await githubService.createIssue(
                owner: parts[0],
                repo: parts[1],
                title: title,
                body: body
            )
            issues.insert(newIssue, at: 0)  // Add to top of list
        } catch {
            handleError(error)
        }
    }

    // MARK: - Private Methods

    private func parseGitHubURL(_ urlString: String) -> (owner: String, repo: String)? {
        // Handle HTTPS: https://github.com/owner/repo.git
        // Handle SSH: git@github.com:owner/repo.git

        var cleanURL =
            urlString
            .replacingOccurrences(of: ".git", with: "")
            .replacingOccurrences(of: "git@github.com:", with: "https://github.com/")

        guard let url = URL(string: cleanURL),
            let host = url.host,
            host.contains("github.com")
        else {
            return nil
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else { return nil }

        return (owner: pathComponents[0], repo: pathComponents[1])
    }

    private func handleError(_ error: Error) {
        if let githubError = error as? GitHubError {
            errorMessage = githubError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
