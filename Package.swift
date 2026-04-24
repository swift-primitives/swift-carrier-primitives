// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-carrier-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Carrier Primitives",
            targets: ["Carrier Primitives"]
        ),
        .library(
            name: "Carrier Primitives Standard Library Integration",
            targets: ["Carrier Primitives Standard Library Integration"]
        ),
        .library(
            name: "Carrier Primitives Test Support",
            targets: ["Carrier Primitives Test Support"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Carrier Primitives",
            dependencies: []
        ),
        .target(
            name: "Carrier Primitives Standard Library Integration",
            dependencies: [
                "Carrier Primitives",
            ]
        ),
        .target(
            name: "Carrier Primitives Test Support",
            dependencies: [
                "Carrier Primitives",
                "Carrier Primitives Standard Library Integration",
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Carrier Primitives Tests",
            dependencies: [
                "Carrier Primitives",
                "Carrier Primitives Standard Library Integration",
                "Carrier Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
