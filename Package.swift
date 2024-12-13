// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RingProgressView",
    platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v8)],
    products: [
        .library(name: "RingProgressView", targets: ["RingProgressView"]),
    ],
    targets: [
        .target(name: "RingProgressView"),
    ]
)
