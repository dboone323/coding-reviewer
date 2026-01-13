# Step 43: SwiftSyntax SPM Dependency
# Package.swift

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CodingReviewer",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CodingReviewerCore",
            targets: ["CodingReviewerCore"]
        )
    ],
    dependencies: [
        // SwiftSyntax for AST-based code analysis
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "509.0.0"
        )
    ],
    targets: [
        .target(
            name: "CodingReviewerCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ],
            path: "CodingReviewer/Services"
        ),
        .testTarget(
            name: "CodingReviewerTests",
            dependencies: ["CodingReviewerCore"],
            path: "CodingReviewerTests"
        )
    ]
)
