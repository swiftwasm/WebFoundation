// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "WebFoundation",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "WebFoundation",
            targets: ["WebFoundation"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftwasm/JavaScriptKit.git",
            .upToNextMajor(from: "0.16.0")
        ),
    ],
    targets: [
        .target(
            name: "FoundationShim",
            dependencies: [
                .target(name: "WebFoundation", condition: .when(platforms: [.wasi])),
            ]
        ),
        .target(
            name: "WebFoundation",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ]
        ),
        .testTarget(
            name: "WebFoundationTests",
            dependencies: ["FoundationShim"]
        ),
    ]
)
