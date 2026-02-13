//
//  WelcomeViewTests.swift
//  CodingReviewerTests
//
//  Comprehensive test suite for WelcomeView
//

import SwiftUI
import XCTest
@testable import CodingReviewer

@MainActor
final class WelcomeViewTests: XCTestCase {
    private final class FlagStore {
        var value = false
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        let flagStore = FlagStore()
        let binding = Binding<Bool>(get: { flagStore.value }, set: { flagStore.value = $0 })
        let view = WelcomeView(showFilePicker: binding)
        XCTAssertNotNil(view)
        XCTAssertFalse(flagStore.value)
    }

    // MARK: - Property Tests

    func testProperties() {
        // Presenter open action should toggle binding to true
        let flagStore = FlagStore()
        let binding = Binding<Bool>(get: { flagStore.value }, set: { flagStore.value = $0 })
        let presenter = WelcomeViewPresenter()
        let action = presenter.openFileAction(binding: binding)
        action()
        XCTAssertTrue(flagStore.value)
    }

    // MARK: - Method Tests

    func testPublicMethods() {
        // Repeated action should be idempotent (still true)
        let flagStore = FlagStore()
        let binding = Binding<Bool>(get: { flagStore.value }, set: { flagStore.value = $0 })
        let presenter = WelcomeViewPresenter()
        let action = presenter.openFileAction(binding: binding)
        action()
        action()
        XCTAssertTrue(flagStore.value)
    }

    // MARK: - Edge Case Tests

    func testEdgeCases() {
        // Ensure action closure can be stored and invoked later
        let flagStore = FlagStore()
        let binding = Binding<Bool>(get: { flagStore.value }, set: { flagStore.value = $0 })
        let action = WelcomeViewPresenter().openFileAction(binding: binding)
        let stored = action
        stored()
        XCTAssertTrue(flagStore.value)
    }

    // MARK: - Error Handling Tests

    func testErrorHandling() {
        // No explicit errors expected; verify that toggling does not crash
        let flagStore = FlagStore()
        let binding = Binding<Bool>(get: { flagStore.value }, set: { flagStore.value = $0 })
        WelcomeViewPresenter().openFileAction(binding: binding)()
        XCTAssertTrue(flagStore.value)
    }

    // MARK: - Integration Tests

    func testIntegration() {
        // Integrate presenter + view wiring indirectly via binding behavior
        let flagStore = FlagStore()
        let binding = Binding<Bool>(get: { flagStore.value }, set: { flagStore.value = $0 })
        _ = WelcomeView(showFilePicker: binding)
        // Simulate the primary action
        WelcomeViewPresenter().openFileAction(binding: binding)()
        XCTAssertTrue(flagStore.value)
    }
}
