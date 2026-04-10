// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TuneAPI",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "TuneAPI",
            targets: ["TuneAPI"]
        ),
    ],
    dependencies: [
        .package(path: "../TuneDomain"),
    ],
    targets: [
        .target(
            name: "TuneAPI",
            dependencies: [
                .product(name: "TuneDomain", package: "TuneDomain"),
            ]
        ),
        .testTarget(
            name: "TuneAPITests",
            dependencies: [
                "TuneAPI",
                .product(name: "TuneDomain", package: "TuneDomain"),
            ]
        ),
        // Integration Test target: making a real HTTTP call separate target so that unit tests can run faster.
        .testTarget(
            name: "TuneAPIIntegrationTests",
            dependencies: [
                "TuneAPI",
                .product(name: "TuneDomain", package: "TuneDomain"),
            ]
        ),
    ]
)
