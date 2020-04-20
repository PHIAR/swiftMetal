// swift-tools-version:5.2

import PackageDescription

var products: [Product] = []
var targets: [Target] = []

// MARK - Metal

let metalProtocolsTarget = Target.target(name: "MetalProtocols",
                                         dependencies: [])
let metalTarget = Target.target(name: "Metal",
                                dependencies: [
    "MetalProtocols",
    "swiftVulkan",
],
                                path: "Sources/MetalVulkanBackend")

targets.append(metalProtocolsTarget)
targets.append(metalTarget)

// MARK - Package configuration

products.append(.library(name: "Metal",
                         type: .dynamic,
                         targets: [
    "Metal",
]))

let package = Package(name: "Platform-Metal",
                      products: products,
                      dependencies: [
    .package(url: "https://github.com/PHIAR/swiftVulkan.git",
             .branch("master")),
],
                      targets: targets)

