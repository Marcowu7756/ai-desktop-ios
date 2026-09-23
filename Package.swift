// swift-tools-version: 6.0
//
// AIDesktop — V0 architecture scaffold.
//
// Platform floor is deliberately NOT iOS 26. See docs/ADR-0002.
//
// HARD RULE: this `dependencies:` array must stay EMPTY in V0.
// ManifoldKit (floor: iOS 26 / macOS 26) must never be added here, or the
// platform floor of the whole package silently rises to 26 and stays there
// even if ManifoldKit is later removed. ManifoldKit, when it is ever tried,
// lives behind Adapters/ManifoldAdapter (its own local package).

import PackageDescription

let package = Package(
    name: "AIDesktop",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ProductCore", targets: ["ProductCore"]),
        .library(name: "BrainKit", targets: ["BrainKit"])
    ],
    dependencies: [],
    targets: [
        // ProductCore owns the vocabulary. Zero external dependencies, ever.
        .target(
            name: "ProductCore",
            dependencies: [],
            path: "ProductCore/Sources/ProductCore"
        ),
        // BrainKit is the only layer allowed to touch inference libraries.
        .target(
            name: "BrainKit",
            dependencies: ["ProductCore"],
            path: "BrainKit/Sources/BrainKit"
        ),
        .testTarget(
            name: "ProductCoreTests",
            dependencies: ["ProductCore"],
            path: "Tests/ProductCoreTests"
        ),
        .testTarget(
            name: "BrainKitTests",
            dependencies: ["BrainKit", "ProductCore"],
            path: "Tests/BrainKitTests"
        )
    ]
)
