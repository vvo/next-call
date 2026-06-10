// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NextCall",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "NextCall",
            path: "Sources",
            resources: [
                .copy("Resources/logos")
            ]
        )
    ]
)
