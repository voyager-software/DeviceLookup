// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceLookup",
    // The lowest deployment targets current Xcode builds for.
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macCatalyst(.v15),
        .macOS(.v12),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "DeviceLookup",
            targets: ["DeviceLookup"]
        ),
    ],
    targets: [
        .target(
            name: "DeviceLookup",
            resources: [
                .copy("Resources/devices.json"),
                .copy("Resources/all-macs.json"),
            ]
        ),
        .testTarget(
            name: "DeviceLookupTests",
            dependencies: ["DeviceLookup"]
        ),
    ]
)
