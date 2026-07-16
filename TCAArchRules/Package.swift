// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TCAArchRules",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "TCAArchRules", targets: ["TCAArchRules"])
    ],
    dependencies: [
        .package(url: "https://github.com/perrystreetsoftware/Harmonize.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "TCAArchRules",
            dependencies: [
                .product(name: "Harmonize", package: "Harmonize")
            ]
        )
    ]
)
