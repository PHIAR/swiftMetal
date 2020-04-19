import Foundation
import Metal

open class MetalContext {
    public static let defaultTextureUsage: MTLTextureUsage = [
        .shaderRead,
    ]

    public final let contextQueue = DispatchQueue(label: "MetalContext.contextQueue")
    public final let metalDevice: MetalDevice
    public final var metalCommandQueue: MetalCommandQueue!

    public init(metalDevice: MetalDevice) {
        self.metalDevice = metalDevice
    }

    public final func commandQueue() -> MetalCommandQueue {
        return self.metalCommandQueue
    }

    public final func makeBuffer(buffer: MTLBuffer) -> MetalBuffer {
        return MetalBuffer(metalDevice: self.metalDevice,
                           buffer: buffer)
    }

    public final func makeTexture2D(width: Int,
                                    height: Int,
                                    arrayLength: Int = 1,
                                    pixelFormat: MTLPixelFormat = .bgra8Unorm,
                                    storageMode: MTLStorageMode = .private,
                                    usage: MTLTextureUsage = MetalContext.defaultTextureUsage) -> MetalTexture {
        let device = self.metalDevice.device
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                  width: width,
                                                                  height: height,
                                                                  mipmapped: false)

        descriptor.storageMode = storageMode
        descriptor.usage = usage

        if arrayLength > 1 {
            descriptor.textureType = .type2DArray
            descriptor.arrayLength = arrayLength
        }

        let texture = device.makeTexture(descriptor: descriptor)!

        return self.makeTexture(texture: texture)
    }

    public final func makeTexture(texture: MTLTexture) -> MetalTexture {
        return MetalTexture(metalDevice: self.metalDevice,
                            texture: texture,
                            retained: false)
    }
}

public extension MetalContext {
    func toOpaquePointer(retained: Bool = false) -> OpaquePointer {
        guard retained else {
            return OpaquePointer(Unmanaged.passUnretained(self).toOpaque())
        }

        return OpaquePointer(Unmanaged.passRetained(self).toOpaque())
    }
}

public extension OpaquePointer {
    func toMetalContext(retained: Bool = false) -> MetalContext {
        guard retained else {
            return Unmanaged <MetalContext>.fromOpaque(UnsafeRawPointer(self)!).takeUnretainedValue()
        }

        return Unmanaged <MetalContext>.fromOpaque(UnsafeRawPointer(self)!).takeRetainedValue()
    }
}
