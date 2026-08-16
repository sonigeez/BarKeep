// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BarKeep",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BarKeep", targets: ["BarKeep"])
    ],
    targets: [
        .executableTarget(
            name: "BarKeep",
            path: "Sources/BarKeep"
        )
    ]
)
