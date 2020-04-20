import Foundation

open class MetalEvent {
    public final let metalCommandQueue: MetalCommandQueue

    public init(metalCommandQueue: MetalCommandQueue) {
        self.metalCommandQueue = metalCommandQueue
    }
}

public extension MetalEvent {
    func toOpaquePointer(retained: Bool = false) -> OpaquePointer {
        guard retained else {
            return OpaquePointer(Unmanaged.passUnretained(self).toOpaque())
        }

        return OpaquePointer(Unmanaged.passRetained(self).toOpaque())
    }
}

public extension OpaquePointer {
    func toMetalEvent(retained: Bool = false) -> MetalEvent {
        guard retained else {
            return Unmanaged <MetalEvent>.fromOpaque(UnsafeRawPointer(self)!).takeUnretainedValue()
        }

        return Unmanaged <MetalEvent>.fromOpaque(UnsafeRawPointer(self)!).takeRetainedValue()
    }
}
