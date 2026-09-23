// swift-tools-version: 6.1
//
// A deliberately separate local package.
//
// Nothing in the root package references this, which is the whole point: the
// root manifest keeps `dependencies: []`, so ManifoldKit's iOS 26 floor cannot
// propagate into the product. See docs/ADR-0002.
//
// This package is NOT part of any build in V0 and is NOT verified.

import PackageDescription

let package = Package(
    name: "ManifoldAdapter",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "ManifoldAdapter", targets: ["ManifoldAdapter"])
    ],
    dependencies: [
        .package(path: "../../"),
        .package(url: "https://github.com/ManifoldKit/ManifoldKit.git", from: "0.79.0")
    ],
    targets: [
        .target(
            name: "ManifoldAdapter",
            dependencies: [
                .product(name: "ProductCore", package: "AIDesktop"),
                .product(name: "BrainKit", package: "AIDesktop"),
                .product(name: "ManifoldKit", package: "ManifoldKit")
            ],
            path: "Sources/ManifoldAdapter"
        )
    ]
)
