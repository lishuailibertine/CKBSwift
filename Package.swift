// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CKBSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CKBSwift",
            targets: ["CKBSwift"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Secp256k1Swift", url: "https://github.com/mathwallet/Secp256k1Swift.git", from: "2.0.0"),
        .package(name: "Blake2", url: "https://github.com/lishuailibertine/Blake2.swift", from: "0.1.3"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.4.2"),
        .package(url: "https://github.com/attaswift/BigInt", from: "5.3.0"),
        .package(url: "https://github.com/mathwallet/RIPEMDSwift.git", from: "0.0.1"),
        .package(url: "https://github.com/mxcl/PromiseKit.git", .upToNextMajor(from: "8.1.1")),
        .package(url: "https://github.com/mathwallet/BIP39swift", from: "1.0.1"),
        .package(name: "scrypt", url: "https://github.com/v57/scrypt.c.git", from: "0.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CKBSwift",
            dependencies: ["Secp256k1Swift",.product(name: "BIP32Swift", package: "Secp256k1Swift"), "Blake2", "RIPEMDSwift", "CryptoSwift", "BigInt", "PromiseKit", "BIP39swift", "scrypt"]),
        .testTarget(
            name: "CKBSwiftTests",
            dependencies: ["CKBSwift","CryptoSwift", "BigInt"]),
    ]
)
