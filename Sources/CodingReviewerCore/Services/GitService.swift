//
// GitService.swift
// CodingReviewerCore
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.codingreviewer.core", category: "GitService")

/// Comprehensive service for local and remote Git integration.
/// Consolidated from legacy GitHubService, GitIntegrationService, and WebhookHandler.
public actor GitService {
    public static let shared = GitService()

    private let session: URLSession
    private var baseURL: String = "https://api.github.com" // Default, can be overridden for local MCP

    private init() {
        self.session = URLSession.shared
    }

    /// Sets the base URL for remote API calls (e.g., to point to a local MCP bridge).
    public func setBaseURL(_ url: String) {
        self.baseURL = url
    }

    // MARK: - Local Git Operations

    /// List modified files in the working directory at the given path.
    public func getChangedFiles(at path: String) async throws -> [String] {
        // Implementation would use Process call to `git status --porcelain`
        return []
    }

    // MARK: - Remote GitHub Operations

    /// Lists pull requests for a specific repository.
    public func listPullRequests(owner: String, repo: String, state: String = "open") async throws -> [PullRequest] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls?state=\(state)")!
        return try await fetch(url: url)
    }

    /// Fetches details for a single pull request.
    public func getPullRequest(owner: String, repo: String, number: Int) async throws -> PullRequest {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls/\(number)")!
        return try await fetch(url: url)
    }

    /// Posts a comment to a pull request.
    public func postComment(owner: String, repo: String, prNumber: Int, body: String) async throws {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/issues/\(prNumber)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["body": body]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw GitError.networkError
        }
    }

    // MARK: - Webhook Integration

    /// Processes an incoming webhook payload.
    public func handleWebhook(data: Data) throws -> WebhookAction {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let payload = try decoder.decode(WebhookPayload.self, from: data)
        return WebhookAction(action: payload.action, prNumber: payload.pullRequest?.number)
    }

    // MARK: - Private Helpers

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GitError.networkError
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Supporting Types

public enum GitError: Error {
    case notConfigured
    case networkError
    case unauthorized
}

public struct WebhookAction: Sendable {
    public let action: String
    public let prNumber: Int?
}

private struct WebhookPayload: Codable {
    let action: String
    let pullRequest: PullRequest?
}

public struct PullRequest: Codable, Identifiable, Sendable {
    public let id: Int
    public let number: Int
    public let title: String
    public let body: String?
    public let state: String
    public let htmlUrl: String
    public let createdAt: Date
}
