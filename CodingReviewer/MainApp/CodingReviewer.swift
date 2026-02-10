//
//  CodingReviewer.swift
//  CodingReviewer
//
//  Main SwiftUI application for CodingReviewer IDE
//

import os
import SwiftUI

@main
public struct CodingReviewer: App {
    private let logger = Logger(
        subsystem: "com.quantum.codingreviewer", category: "CodingReviewerApp"
    )

    @State private var showNewReviewSheet = false
    @State private var showAboutWindow = false

    public var body: some Scene {
        WindowGroup {
            IDELayoutView()
                .frame(minWidth: 1000, minHeight: 650)
                .sheet(isPresented: $showNewReviewSheet) {
                    NewReviewView()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Review") {
                    showNewReviewSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save File") {
                    saveCurrentReview()
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button("About CodingReviewer") {
                    showAboutWindow = true
                }
            }
        }

        // About window
        WindowGroup(id: "about") {
            AboutView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Settings (Preferences)
        Settings {
            SettingsView()
        }
    }

    public init() {
        logger.info("CodingReviewer IDE initialized")
    }

    private func saveCurrentReview() {
        logger.info("Save action triggered")
        NotificationCenter.default.post(
            name: Notification.Name("SaveReviewNotification"), object: nil
        )
    }
}
