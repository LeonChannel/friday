// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FridayKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "FridayFeatures", targets: ["FridayFeatures"]),
        .library(name: "FridayInfrastructure", targets: ["FridayInfrastructure"]),
        .library(name: "FridayCLI", targets: ["FridayCLI"]),
        .executable(name: "friday", targets: ["friday-cli"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.12.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.99.3"),
    ],
    targets: [
        .target(name: "FridayDomain"),
        .target(
            name: "FridayInfrastructure",
            dependencies: ["FridayDomain", .product(name: "GRDB", package: "GRDB.swift")]
        ),
        .target(
            name: "FridayFeatures",
            dependencies: ["FridayDomain", "FridayInfrastructure", .product(name: "SwiftTerm", package: "SwiftTerm")],
            resources: [.copy("Resources/Fonts")]
        ),
        .target(name: "FridayCLI", dependencies: ["FridayDomain", "FridayInfrastructure"]),
        .executableTarget(name: "friday-cli", dependencies: ["FridayCLI", "FridayInfrastructure"]),
        .testTarget(name: "FridayDomainTests", dependencies: ["FridayDomain"]),
        .testTarget(name: "FridayInfrastructureTests", dependencies: ["FridayInfrastructure"]),
        .testTarget(name: "FridayFeaturesTests", dependencies: ["FridayFeatures"]),
        .testTarget(name: "FridayCLITests", dependencies: ["FridayCLI", "FridayInfrastructure", "friday-cli"]),
    ]
)
