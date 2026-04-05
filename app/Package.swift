// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ClaudeHub",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeHub",
            path: "Sources"
        ),
        .testTarget(
            name: "ClaudeHubTests",
            dependencies: ["ClaudeHub"],
            path: "Tests"
        )
    ]
)
