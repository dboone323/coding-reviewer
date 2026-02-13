// swift-tools-version:6.0
// Step 43: SwiftSyntax SPM Dependency
// Package.swift

import PackageDescription

let package = Package(
    name: "CodingReviewer",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CodingReviewerCore",
            targets: ["CodingReviewer"]
        )
    ],
    dependencies: [
        // SwiftSyntax for AST-based code analysis
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "509.0.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.16.0"
        ),
    ],
    targets: [
        .target(
            name: "CodingReviewer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
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
            ],
            sources: [
                "Services",
                "Models",
                "Utilities",
                "IDE",
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
    ]
)
