// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TuneDomain",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "TuneDomain",
            targets: ["TuneDomain"]
        ),
    ],
    targets: [
        .target(
            name: "TuneDomain"
        ),
    ]
)
