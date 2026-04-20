//
// WebhookHandler.swift
// CodingReviewer
//
// Handler for incoming webhooks
//

import Foundation

// MARK: - Webhook Types

struct WebhookPayload: Codable {
    let action: String
    let repository: WebhookRepository
    let pullRequest: WebhookPullRequest?

    enum CodingKeys: String, CodingKey {
        case action
        case repository
        case pullRequest = "pull_request"
    }
}

struct WebhookRepository: Codable {
    let fullName: String
}

struct WebhookPullRequest: Codable {
    let number: Int
    let title: String
}

// MARK: - WebhookHandler

struct WebhookHandler {
    func handle(payload: Data) throws {
        let decoder = JSONDecoder()
        let event = try decoder.decode(WebhookPayload.self, from: payload)

        if event.action == "opened" || event.action == "synchronize" {
            // Trigger analysis
            print("Triggering analysis for PR #\(event.pullRequest?.number ?? 0)")
        }
    }
}
