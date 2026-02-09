//
// GitIntegrationServiceTests.swift
// CodingReviewerTests
//

import XCTest
@testable import CodingReviewerCore

final class MockGitProvider: GitProvider {
    var prContentToReturn: String = ""
    var postCommentCalled = false
    var lastComment: String?

    func fetchPullRequest(id: String) async throws -> String {
        prContentToReturn
    }

    func postComment(prId: String, file: String, line: Int, comment: String) async throws {
        postCommentCalled = true
        lastComment = comment
    }
}

final class GitIntegrationServiceTests: XCTestCase {
    var service: GitIntegrationService!
    var mockProvider: MockGitProvider!

    override func setUp() {
        super.setUp()
        service = GitIntegrationService()
        mockProvider = MockGitProvider()
    }

    func testFetchPR_NotConfigured_ThrowsError() async {
        do {
            _ = try await service.fetchPR(id: "123")
            XCTFail("Should throw error if not configured")
        } catch {
            XCTAssertEqual(error as? GitError, GitError.notConfigured)
        }
    }

    func testFetchPR_Configured_ReturnsContent() async throws {
        service.configure(provider: mockProvider)
        mockProvider.prContentToReturn = "PR Code"

        let content = try await service.fetchPR(id: "123")
        XCTAssertEqual(content, "PR Code")
    }

    // Note: Service doesn't expose postComment wrapper in the viewed file `GitIntegrationService.swift`
    // It only has `fetchPR`?
    // Checking file content from Step 1464:
    // func fetchPR(id: String) ...
    // func configure(provider: GitProvider) ...
    // No `postComment` in service class, only in Protocol.
    // So we can only test fetchPR.
    // That's fine.
}
