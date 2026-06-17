// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PathConverter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PathConverterCore", targets: ["PathConverterCore"]),
        .executable(name: "PathConverter", targets: ["PathConverter"])
    ],
    targets: [
        .target(name: "PathConverterCore"),
        .executableTarget(
            name: "PathConverter",
            dependencies: ["PathConverterCore"]
        ),
        .testTarget(
            name: "PathConverterCoreTests",
            dependencies: ["PathConverterCore"]
        )
    ]
)
