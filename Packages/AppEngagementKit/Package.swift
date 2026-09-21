// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppEngagementKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AppEngagementKit",
            targets: ["AppEngagementKit"]
        )
    ],
    targets: [
        .target(
            name: "AppEngagementKit"
        )
    ]
)
