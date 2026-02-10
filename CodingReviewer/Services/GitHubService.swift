//
//  GitHubService.swift
//  CodingReviewer
//
//  GitHub API client using MCP server endpoints
//

import Foundation

// MARK: - Model Types

public struct GitHubRepo: Identifiable, Codable, Sendable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let description: String?
    public let `private`: Bool
    public let htmlUrl: String
    public let defaultBranch: String

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case fullName = "full_name"
        case `private` = "private"
        case htmlUrl = "html_url"
        case defaultBranch = "default_branch"
    }
}

public struct GitHubUser: Codable, Sendable {
    public let login: String
    public let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

public struct PullRequest: Identifiable, Codable, Sendable {
    public let id: Int
    public let number: Int
    public let title: String
    public let body: String?
    public let state: String
    public let htmlUrl: String
    public let user: GitHubUser
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, user
        case htmlUrl = "html_url"
        case createdAt = "created_at"
    }
}

public struct Issue: Identifiable, Codable, Sendable {
    public let id: Int
    public let number: Int
    public let title: String
    public let body: String?
    public let state: String
    public let htmlUrl: String
    public let user: GitHubUser

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, user
        case htmlUrl = "html_url"
    }
}

// MARK: - Service

/// GitHub API service via MCP server
public actor GitHubService {
    public var baseURL: String
    private let session: URLSession

    public init(baseURL: String = "http://localhost:5005") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    // MARK: - Repository Operations

    /// List user repositories
    public func listRepositories(user: String) async throws -> [GitHubRepo] {
        let url = URL(string: "\(baseURL)/api/github/users/\(user)/repos")!
        return try await fetch(url: url)
    }

    /// Get repository details
    public func getRepository(owner: String, repo: String) async throws -> GitHubRepo {
        let url = URL(string: "\(baseURL)/api/github/repos/\(owner)/\(repo)")!
        return try await fetch(url: url)
    }

    // MARK: - Pull Request Operations

    /// List pull requests
    public func listPullRequests(owner: String, repo: String, state: String = "open") async throws
        -> [PullRequest]
    {
        let url = URL(string: "\(baseURL)/api/github/repos/\(owner)/\(repo)/pulls?state=\(state)")!
        return try await fetch(url: url)
    }

    /// Get pull request details
    public func getPullRequest(owner: String, repo: String, number: Int) async throws -> PullRequest
    {
        let url = URL(string: "\(baseURL)/api/github/repos/\(owner)/\(repo)/pulls/\(number)")!
        return try await fetch(url: url)
    }

    // MARK: - Issue Operations

    /// List issues
    public func listIssues(owner: String, repo: String, state: String = "open") async throws
        -> [Issue]
    {
        let url = URL(string: "\(baseURL)/api/github/repos/\(owner)/\(repo)/issues?state=\(state)")!
        return try await fetch(url: url)
    }

    /// Create a new issue
    public func createIssue(owner: String, repo: String, title: String, body: String) async throws
        -> Issue
    {
        let url = URL(string: "\(baseURL)/api/github/repos/\(owner)/\(repo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "title": title,
            "body": body,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Issue.self, from: data)
    }

    // MARK: - Private Helpers

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Errors

public enum GitHubError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError
    case networkError

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        }
    }
}
