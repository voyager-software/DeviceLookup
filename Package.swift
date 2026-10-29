// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceLookup",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
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
