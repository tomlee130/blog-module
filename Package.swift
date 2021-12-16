// swift-tools-version:5.3
import PackageDescription

let isLocalTestMode = false

var deps: [Package.Dependency] = [
    .package(url: "https://github.com/tomlee130/feather-core", .branch("main")), //from: "1.0.1"),
]

var targets: [Target] = [
    .target(name: "BlogApi"),
    .target(name: "BlogModule", dependencies: [
        .target(name: "BlogApi"),
        .product(name: "FeatherCore", package: "feather-core"),
    ],
    resources: [
        .copy("Bundle"),
    ]),
]

// @NOTE: https://bugs.swift.org/browse/SR-8658
if isLocalTestMode {
    deps.append(contentsOf: [
        /// drivers
        .package(url: "https://github.com/vapor/fluent-sqlite-driver", from: "4.0.0"),
        .package(url: "https://github.com/binarybirds/liquid-local-driver", from: "1.2.0"),
    ])
    targets.append(contentsOf: [
        .target(name: "Feather", dependencies: [
            .product(name: "FeatherCore", package: "feather-core"),
            /// drivers
            .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            .product(name: "LiquidLocalDriver", package: "liquid-local-driver"),

            .target(name: "BlogModule"),
        ]),
        .testTarget(name: "BlogModuleTests", dependencies: [
            .target(name: "BlogModule"),
            .product(name: "FeatherTest", package: "feather-core")
        ]),
    ])
}

let package = Package(
    name: "blog-module",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "BlogModule", targets: ["BlogModule"]),
        .library(name: "BlogApi", targets: ["BlogApi"]),
    ],
    dependencies: deps,
    targets: targets
)
