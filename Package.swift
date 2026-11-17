// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Argus",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "ArgusCore",
            targets: ["ArgusCore"]
        ),
        .executable(
            name: "ArgusMCPServer",
            targets: ["ArgusMCPServer"]
        ),
    ],
    dependencies: [
        // No external dependencies for now
    ],
    targets: [
        .target(
            name: "ArgusCore",
            dependencies: [],
            path: "Sources/ArgusCore"
        ),
        .target(
            name: "ArgusMCPServer",
            dependencies: ["ArgusCore"],
            path: "Sources/ArgusMCPServer"
        ),
        .testTarget(
            name: "ArgusCoreTests",
            dependencies: ["ArgusCore"],
            path: "Tests/ArgusCoreTests"
        ),
        .testTarget(
            name: "ArgusMCPServerTests",
            dependencies: ["ArgusMCPServer", "ArgusCore"],
            path: "Tests/ArgusMCPServerTests"
        ),
    ]
)