// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "iOS",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "CounterFeature", targets: ["CounterFeature"]),
    .library(name: "SecondTabFeature", targets: ["SecondTabFeature"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.21.0")
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "CounterFeature",
        "SecondTabFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "CounterFeature",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SecondTabFeature",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "CounterFeatureTests",
      dependencies: [
        "CounterFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
  ]
)
