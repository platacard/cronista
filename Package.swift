// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Cronista",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "Cronista",
            targets: ["Cronista"]
        )
    ],
    targets: [
        .target(
            name: "Cronista",
            path: "Sources/Cronista"
        ),
        .testTarget(
            name: "CronistaTests",
            dependencies: ["Cronista"],
            path: "Tests/Cronista"
        )
    ]
)
