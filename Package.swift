// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "HawkenDotIs",
    products: [
        .executable(
            name: "HawkenDotIs",
            targets: ["HawkenDotIs"]
        )
    ],
    dependencies: [
        .package(name: "Publish", url: "https://github.com/johnsundell/publish.git", from: "0.7.0")
    ],
    targets: [
        .target(
            name: "HawkenDotIs",
            dependencies: ["Publish"]
        )
    ]
)
