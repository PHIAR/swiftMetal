// swift-tools-version:5.2

import PackageDescription

// MARK - Platform configuration

let platforms: [SupportedPlatform] = [
    .iOS("13.2"),
    .macOS("10.15"),
    .tvOS("13.2")
]

var products: [Product] = []
var targets: [Target] = []

// MARK - swiftMetal

let swiftMetal = Target.target(name: "swiftMetal",
                               dependencies: [
    "simdFilament",
    .product(name: "Metal",
             package: "swiftMetalPlatform")
])

let swiftMetalTestTarget = Target.testTarget(name: "swiftMetalTests",
                                             dependencies: [
    "swiftMetal",
    .product(name: "Metal",
             package: "swiftMetalPlatform")
])

targets.append(swiftMetal)
targets.append(swiftMetalTestTarget)

// MARK - Package configuration

products.append(.library(name: "swiftMetal",
                         type: .dynamic,
                         targets: [
    "swiftMetal",
]))

let package = Package(name: "swiftMetal",
                      platforms: platforms,
                      products: products,
                      dependencies: [
    .package(url: "https://github.com/PHIAR/simdFilament.git",
             .branch("master")),
    .package(url: "https://github.com/PHIAR/swiftMetalPlatform.git",
             .branch("master")),
],
                      targets: targets)

