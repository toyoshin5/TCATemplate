// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "iOS",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "CounterFeature", targets: ["CounterFeature"]),
        .library(name: "SecondTabFeature", targets: ["SecondTabFeature"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.26.0"),
        // Client層が依存してよいのはDependencies/DependenciesMacrosまで(TCA本体は禁止)
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.14.0"),
        // アーキテクチャルール(Harmonizeベース)。ArchitectureTestsターゲットからのみ利用する
        .package(path: "../TCAArchRules")
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "CounterFeature",
                "SecondTabFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "CounterFeature",
            dependencies: [
                "NumberFactClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "NumberFactClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "SecondTabFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "CounterFeatureTests",
            dependencies: [
                "CounterFeature",
                "NumberFactClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "SecondTabFeatureTests",
            dependencies: [
                "SecondTabFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "ArchitectureTests",
            dependencies: [
                .product(name: "TCAArchRules", package: "TCAArchRules")
            ]
        )
    ]
)
