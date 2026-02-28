// swift-tools-version:6.2
// Step 43: SwiftSyntax SPM Dependency
// Package.swift

import PackageDescription
import Foundation

private let localSharedKitPath = "../shared-kit"
private let sharedKitDependency: Package.Dependency = FileManager.default.fileExists(atPath: localSharedKitPath)
    ? .package(path: localSharedKitPath)
    : .package(url: "https://github.com/dboone323/shared-kit.git", branch: "main")

let package = Package(
    name: "CodingReviewer",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "CodingReviewerCore",
            targets: ["CodingReviewer"]
        ),
        .executable(
            name: "LiveReviewTest",
            targets: ["LiveReviewTest"]
        )
    ],
    dependencies: [
        // SwiftSyntax for AST-based code analysis
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "600.0.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.16.0"
        ),
        sharedKitDependency,
    ],
    targets: [
        .target(
            name: "CodingReviewer",
            dependencies: [
                .product(name: "SharedKit", package: "shared-kit"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "CodingReviewer",
            exclude: [
                "Temp",
                "Tools",
                "MainApp",
                "Assets.xcassets",
                "AppLifecycleCoordinator.swift",
                "KeyboardShortcuts.swift",
                "CodingReviewer.entitlements",
                "Info.plist",
            ],
            sources: [
                "Services",
                "Models",
                "Persistence/CoreDataStack.swift",
                "Persistence/ReviewIssue+CoreDataClass.swift",
                "Persistence/ReviewIssue+CoreDataProperties.swift",
                "Persistence/ReviewSession+CoreDataClass.swift",
                "Persistence/ReviewSession+CoreDataProperties.swift",
                "Security",
                "Utilities",
                "IDE",
                "KeychainManager.swift",
                "ContentView.swift",
                "CodeReviewView.swift",
                "SidebarView.swift",
                "DashboardView.swift",
                "SettingsView.swift",
                "WelcomeView.swift",
                "AboutView.swift",
                "AnalysisResultsView.swift",
                "DocumentationResultsView.swift",
                "TestResultsView.swift",
                "DiffView.swift",
                "NewReviewView.swift",
                "ReviewHistoryView.swift",
                "IssueRow.swift",
                "AppDelegate.swift",
            ],
            resources: [
                .process("Persistence/Model.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "CodingReviewerTests",
            dependencies: [
                "CodingReviewer",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "CodingReviewerTests",
            resources: [
                .copy("Fixtures"),
                .copy("__Snapshots__"),
            ]
        ),
        .executableTarget(
            name: "LiveReviewTest",
            dependencies: ["CodingReviewer"],
            path: "Tools",
            exclude: ["ProjectScripts", "Automation"],
            sources: ["live_review_test.swift"]
        ),
    ]
)
