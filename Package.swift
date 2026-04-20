// swift-tools-version: 6.2
import PackageDescription
import Foundation

private let localSharedKitPath = "../shared-kit"
private let sharedKitDependency: Package.Dependency = true
    ? .package(path: localSharedKitPath)
    : .package(url: "https://github.com/dboone323/shared-kit.git", branch: "main")

let package = Package(
    name: "CodingReviewer",
    defaultLocalization: "en",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
    ],
    products: [
        .executable(
            name: "CodingReviewer",
            targets: ["CodingReviewer"]
        ),
        .library(
            name: "CodingReviewerCore",
            targets: ["CodingReviewerCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.16.0"),
        sharedKitDependency,
    ],
    targets: [
        .executableTarget(
            name: "CodingReviewer",
            dependencies: [
                "CodingReviewerCore"
            ],
            path: "Sources/CodingReviewer"
        ),
        .target(
            name: "CodingReviewerCore",
            dependencies: [
                .product(name: "SharedKit", package: "shared-kit"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            path: "Sources/CodingReviewerCore"
        ),
        .testTarget(
            name: "CodingReviewerCoreTests",
            dependencies: [
                "CodingReviewerCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/CodingReviewerCoreTests"
        ),
    ]
)
