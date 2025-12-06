//
// WebhookHandler.swift
// CodingReviewer
//
// Handler for incoming webhooks
//

import Foundation

struct WebhookHandler {
    struct WebhookPayload: Codable {
        let action: String
        let repository: Repository
        let pullRequest: PullRequest?

        enum CodingKeys: String, CodingKey {
            case action
            case repository
            case pullRequest = "pull_request"
        }
    }

    struct Repository: Codable {
        let fullName: String
    }

    struct PullRequest: Codable {
        let number: Int
        let title: String
    }

    func handle(payload: Data) throws {
        let decoder = JSONDecoder()
        let event = try decoder.decode(WebhookPayload.self, from: payload)

        if event.action == "opened" || event.action == "synchronize" {
            // Trigger analysis
            print("Triggering analysis for PR #\(event.pullRequest?.number ?? 0)")
        }
    }
}
