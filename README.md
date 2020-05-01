# swiftMetal

A convenience API for Metal and GCD written in Swift. For the reference Metal implementation
please refer to the `swiftMetalPlatform` project.

Note this is a proof of concept implementation and is not complete.

## Building and Verification

swiftMetal depends on the following projects:
1. simdFilament
2. swiftVulkan
3. swiftMetalPlatform

Vulkan is the only supported backend right now, in the future this may be expanded
for other OSs or API implementations.

swiftMetal uses the Swift Package Manager (swiftpm) for building.

To build:
```
swift build
```

To test:
```
swift test
```

