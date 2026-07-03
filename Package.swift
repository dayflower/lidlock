// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "lidlock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "lidlock",
            path: "Sources/lidlock"
        )
    ]
)
