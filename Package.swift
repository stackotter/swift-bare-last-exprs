// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ImplicitReturn",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "ImplicitReturn",
            targets: ["ImplicitReturn"]
        ),
        .executable(
            name: "FortuneExample",
            targets: ["FortuneExample"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", revision: "d9832e81fae03a6f78c125f925977bba2d0e794e"),
    ],
    targets: [
        .macro(
            name: "ImplicitReturnMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "ImplicitReturn", dependencies: ["ImplicitReturnMacros"]),

        .executableTarget(name: "FortuneExample", dependencies: ["ImplicitReturn"]),

        .testTarget(
            name: "ImplicitReturnTests",
            dependencies: [
                "ImplicitReturnMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
