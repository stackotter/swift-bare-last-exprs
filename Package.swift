// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "BareLastExprs",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "BareLastExprs",
            targets: ["BareLastExprs"]
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
            name: "BareLastExprsMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "BareLastExprs", dependencies: ["BareLastExprsMacros"], swiftSettings: [.enableExperimentalFeature("BodyMacros")]),

        .executableTarget(name: "FortuneExample", dependencies: ["BareLastExprs"]),

        .testTarget(
            name: "BareLastExprsTests",
            dependencies: [
                "BareLastExprsMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
