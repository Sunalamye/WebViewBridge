// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebViewBridge",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "WebViewBridge",
            targets: ["WebViewBridge"]
        ),
    ],
    targets: [
        .target(
            name: "WebViewBridge",
            dependencies: [],
            path: "Sources/WebViewBridge",
            resources: [
                .copy("JavaScript")
            ]
        ),
        .testTarget(
            name: "WebViewBridgeTests",
            dependencies: ["WebViewBridge"],
            path: "Tests/WebViewBridgeTests"
        ),
    ]
)
