// swift-tools-version: 6.0
// CodingReviewer - AI-Powered Code Review Assistant
// Copyright © 2025 Quantum Workspace. All rights reserved.

import PackageDescription

let package = Package(
    name: "CodingReviewer",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "CodingReviewer",
            targets: ["CodingReviewerCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CodingReviewerCore",
            dependencies: [],
            path: "CodingReviewer",
            exclude: ["Info.plist", "Preview Content", "Assets.xcassets", "CodingReviewer.entitlements"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CodingReviewerTests",
            dependencies: ["CodingReviewerCore"],
            path: "CodingReviewerTests"
        )
    ]
)
