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

let swiftMetalTarget = Target.target(name: "Metal",
                                     dependencies: [
    "swiftVulkan",
],
                                     path: "Sources/swiftMetal")
let swiftMetalTestTarget = Target.testTarget(name: "swiftMetalTests",
                                             dependencies: [
    "Metal",
])

targets.append(swiftMetalTarget)
targets.append(swiftMetalTestTarget)

// MARK - swiftMetalDispatch

let swiftMetalDispatch = Target.target(name: "swiftMetalDispatch",
                                       dependencies: [
    "simdFilament",
    "Metal",
])

targets.append(swiftMetalDispatch)

// MARK - Package configuration

products.append(.library(name: "Metal",
                         type: .dynamic,
                         targets: [
    "Metal",
]))

products.append(.library(name: "swiftMetalDispatch",
                         type: .dynamic,
                         targets: [
    "swiftMetalDispatch",
]))

let package = Package(name: "swiftMetal",
                      platforms: platforms,
                      products: products,
                      dependencies: [
    .package(url: "https://github.com/PHIAR/simdFilament.git",
             .branch("master")),
    .package(url: "https://github.com/PHIAR/swiftVulkan.git",
             .branch("master")),
],
                      targets: targets)

