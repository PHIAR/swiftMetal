import Foundation
import Metal

open class MetalTexture: MetalResource {
    public static func optimalDrawablePixelFormat() -> MTLPixelFormat {
    #if os(Android) || os(Linux) || os(macOS) || os(tvOS) || targetEnvironment(macCatalyst) || targetEnvironment(simulator)
        return .bgra8Unorm
    #else
        return .bgr10_xr
    #endif
    }

    public static func optimalStorageMode() -> MTLStorageMode {
    #if os(macOS)
        return .managed
    #else
        return .shared
    #endif
    }

    public final let texture: MTLTexture

    public init(metalDevice: MetalDevice,
                texture: MTLTexture,
                retained: Bool = true) {
        self.texture = texture
        super.init(metalDevice: metalDevice,
                   retained: retained)
    }
}
