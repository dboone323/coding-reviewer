//
//  WelcomeViewTests.swift
//  CodingReviewerTests
//
//  Comprehensive test suite for WelcomeView
//

@testable import CodingReviewer
import SwiftUI
import XCTest

final class WelcomeViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() {
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        let view = WelcomeView(showFilePicker: binding)
        XCTAssertNotNil(view)
        XCTAssertFalse(flag)
    }

    // MARK: - Property Tests

    func testProperties() {
        // Presenter open action should toggle binding to true
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        let presenter = WelcomeViewPresenter()
        let action = presenter.openFileAction(binding: binding)
        action()
        XCTAssertTrue(flag)
    }

    // MARK: - Method Tests

    func testPublicMethods() {
        // Repeated action should be idempotent (still true)
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        let presenter = WelcomeViewPresenter()
        let action = presenter.openFileAction(binding: binding)
        action()
        action()
        XCTAssertTrue(flag)
    }

    // MARK: - Edge Case Tests

    func testEdgeCases() {
        // Ensure action closure can be stored and invoked later
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        let action = WelcomeViewPresenter().openFileAction(binding: binding)
        let stored = action
        stored()
        XCTAssertTrue(flag)
    }

    // MARK: - Error Handling Tests

    func testErrorHandling() {
        // No explicit errors expected; verify that toggling does not crash
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        WelcomeViewPresenter().openFileAction(binding: binding)()
        XCTAssertTrue(flag)
    }

    // MARK: - Integration Tests

    func testIntegration() {
        // Integrate presenter + view wiring indirectly via binding behavior
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        _ = WelcomeView(showFilePicker: binding)
        // Simulate the primary action
        WelcomeViewPresenter().openFileAction(binding: binding)()
        XCTAssertTrue(flag)
    }
}
