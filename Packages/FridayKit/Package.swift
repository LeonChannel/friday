// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FridayKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "FridayFeatures", targets: ["FridayFeatures"]),
        .library(name: "FridayInfrastructure", targets: ["FridayInfrastructure"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.12.0"),
    ],
    targets: [
        .target(name: "FridayDomain"),
        .target(
            name: "FridayInfrastructure",
            dependencies: ["FridayDomain", .product(name: "GRDB", package: "GRDB.swift")]
        ),
        .target(name: "FridayFeatures", dependencies: ["FridayDomain", "FridayInfrastructure"]),
        .testTarget(name: "FridayDomainTests", dependencies: ["FridayDomain"]),
        .testTarget(name: "FridayInfrastructureTests", dependencies: ["FridayInfrastructure"]),
        .testTarget(name: "FridayFeaturesTests", dependencies: ["FridayFeatures"]),
    ]
)
