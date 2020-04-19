import Foundation
import Metal

internal let METAL_PLATFORM_ENABLE_CONSOLE_LOG = false
internal let METAL_PLATFORM_ENABLE_INSTRUMENTATION = false

open class MetalPlatform {
    private final let metalDevices: [MetalDevice]!

    public final var metalCompiler: MetalCompiler? = nil

    public init(metalDevices: [MetalDevice],
                metalCompiler: MetalCompiler) {
        precondition(!metalDevices.isEmpty)

        self.metalDevices = metalDevices
        self.metalCompiler = metalCompiler
    }

    public final func getDevices() -> [MetalDevice] {
        return self.metalDevices
    }

    public final func unloadCompiler() {
        guard let _ = self.metalCompiler else {
            return
        }

        self.metalCompiler = nil
    }
}
