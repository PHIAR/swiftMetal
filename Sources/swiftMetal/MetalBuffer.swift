import Foundation
import Metal

open class MetalBuffer: MetalResource {
    fileprivate final let hostPtr: UnsafeMutableRawPointer

    public final let buffer: MTLBuffer

    public convenience init?(metalDevice: MetalDevice,
                             size: Int,
                             hostPtr: UnsafeMutableRawPointer? = nil) {
        guard let buffer = metalDevice.contextHeap.makeBuffer(length: size,
                                                              options: .storageModeShared) else {
            preconditionFailure("Failed to create heap buffer. Heap buffer exhausted with stats: \(metalDevice.contextHeap.maxAvailableSize(alignment: 1))")
            return nil
        }

        self.init(metalDevice: metalDevice,
                  buffer: buffer,
                  hostPtr: hostPtr)
    }

    public required init(metalDevice: MetalDevice,
                         buffer: MTLBuffer,
                         hostPtr: UnsafeMutableRawPointer? = nil) {
        self.hostPtr = hostPtr!// == nil ? buffer.contents() : hostPtr!
        self.buffer = buffer
        super.init(metalDevice: metalDevice)
    }

    public func contents() -> UnsafeMutableRawPointer {
        return self.hostPtr
    }

    public func metalBuffer() -> MTLBuffer {
        return self.buffer
    }
}

open class HeapBuffer: MetalBuffer {
    private final let usesHostPtr: Bool

    public convenience init?(metalDevice: MetalDevice,
                             size: Int,
                             hostPtr: UnsafeMutableRawPointer? = nil) {
        let contextHeap = metalDevice.contextHeap

        guard let buffer = contextHeap.makeBuffer(length: size,
                                                  options: .storageModeShared) else {
            return nil
        }

        self.init(metalDevice: metalDevice,
                  buffer: buffer,
                  hostPtr: hostPtr)

        if self.requiresSynchronization() {
            self.upload()
        }
    }

    public required init(metalDevice: MetalDevice,
                         buffer: MTLBuffer,
                         hostPtr: UnsafeMutableRawPointer?) {
        self.usesHostPtr = hostPtr != nil
        super.init(metalDevice: metalDevice,
                   buffer: buffer,
                   hostPtr: hostPtr)
    }

    public override func requiresSynchronization() -> Bool {
        return self.usesHostPtr
    }

    public override func download() {
        precondition(self.requiresSynchronization())

        let buffer = self.buffer

        memcpy(self.hostPtr, buffer.contents(), buffer.length)
    }

    public override func upload() {
        precondition(self.requiresSynchronization())

        let buffer = self.buffer

        memcpy(buffer.contents(), self.hostPtr, buffer.length)
    }
}

