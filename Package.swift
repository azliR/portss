// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "portss",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PortssCore",
            targets: ["PortssCore"]
        ),
        .executable(
            name: "portss",
            targets: ["portss"]
        )
    ],
    targets: [
        .target(
            name: "PortssCore",
            path: "Sources/PortssCore"
        ),
        .executableTarget(
            name: "portss",
            dependencies: ["PortssCore"],
            path: "Sources/portss"
        ),
        .testTarget(
            name: "portssTests",
            dependencies: ["PortssCore"],
            path: "Tests/portssTests"
        )
    ]
)
