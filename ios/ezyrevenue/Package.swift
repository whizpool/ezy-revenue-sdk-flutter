// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ezyrevenue",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "ezyrevenue", targets: ["ezyrevenue"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ezyrevenue",
            dependencies: [],
            path: "../Classes",
            resources: [
                .process("../Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
