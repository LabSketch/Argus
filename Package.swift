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
        .executable(
            name: "ArgusMacOSHelper",
            targets: ["ArgusMacOSHelper"]
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
        .executableTarget(
            name: "ArgusMacOSHelper",
            dependencies: ["ArgusCore"],
            path: "Sources/ArgusMacOSHelper",
            linkerSettings: [
                .linkedFramework("WebKit"),
                .linkedFramework("AppKit")
            ]
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
        .testTarget(
            name: "ArgusMacOSHelperTests",
            dependencies: ["ArgusMacOSHelper", "ArgusCore"],
            path: "Tests/ArgusMacOSHelperTests"
        ),
    ]
)