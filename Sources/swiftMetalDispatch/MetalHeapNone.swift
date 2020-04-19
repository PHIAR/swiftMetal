import Foundation
import Metal

internal class MetalHeapNone: NSObject, MTLHeap {
    public let device: MTLDevice
    public var label: String?
    public var storageMode: MTLStorageMode = .shared
    public var cpuCacheMode: MTLCPUCacheMode = .defaultCache
    public var size: Int = 0
    public var usedSize: Int = 0
    public var currentAllocatedSize: Int = 0
    public var hazardTrackingMode: MTLHazardTrackingMode = .untracked
    public var resourceOptions: MTLResourceOptions = MTLResourceOptions()
    public var type: MTLHeapType = .automatic

    internal init(device: MTLDevice) {
        self.device = device
    }

    public func maxAvailableSize(alignment: Int) -> Int {
        return 0
    }

    public func makeBuffer(length: Int,
                           options: MTLResourceOptions) -> MTLBuffer? {
        return self.device.makeBuffer(length: length,
                                      options: options)
    }

    public func makeBuffer(length: Int,
                           options: MTLResourceOptions = [],
                           offset: Int) -> MTLBuffer? {
        return self.device.makeBuffer(length: length,
                                      options: options)
    }

    public func makeTexture(descriptor desc: MTLTextureDescriptor) -> MTLTexture? {
        return self.device.makeTexture(descriptor: desc)
    }

    public func makeTexture(descriptor: MTLTextureDescriptor,
                            offset: Int) -> MTLTexture? {
        return self.device.makeTexture(descriptor: descriptor)
    }

    public func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState {
        return .keepCurrent
    }
}
