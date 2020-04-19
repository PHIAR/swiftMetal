import Foundation
import Metal

open class MetalResource {
    internal final let metalDevice: MetalDevice

    private final let retained: Bool
    private final var destructorCallback: (() -> Void)?

    public init(metalDevice: MetalDevice,
                retained: Bool = true) {
        self.metalDevice = metalDevice
        self.retained = retained

        guard retained else {
            return
        }

        let memObj = Int(bitPattern: Unmanaged.passUnretained(self).toOpaque())

        self.metalDevice.resourceQueue.async {
            metalDevice.aliveMemObjects.insert(memObj)
        }
    }

    deinit {
        if let destructorCallback = self.destructorCallback {
            destructorCallback()
        }

        guard self.retained else {
            return
        }

        let metalDevice = self.metalDevice
        let memObj = Int(bitPattern: Unmanaged.passUnretained(self).toOpaque())

        metalDevice.resourceQueue.async {
            precondition(metalDevice.aliveMemObjects.contains(memObj))
            metalDevice.aliveMemObjects.remove(memObj)
        }
    }

    public func requiresSynchronization() -> Bool {
        return false
    }

    public func download() {
    }

    public func upload() {
    }

    public final func setDestructorCallback(_ callback: @escaping () -> Void) {
        self.destructorCallback = callback
    }
}

public extension MetalResource {
    func toOpaquePointer(retained: Bool = false) -> OpaquePointer {
        guard retained else {
            return OpaquePointer(Unmanaged.passUnretained(self).toOpaque())
        }

        return OpaquePointer(Unmanaged.passRetained(self).toOpaque())
    }
}

public extension OpaquePointer {
    func toMetalMemObj(retained: Bool = false) -> MetalResource {
        guard retained else {
            return Unmanaged <MetalResource>.fromOpaque(UnsafeRawPointer(self)!).takeUnretainedValue()
        }

        return Unmanaged <MetalResource>.fromOpaque(UnsafeRawPointer(self)!).takeRetainedValue()
    }
}

public extension OpaquePointer {
    func toMetalBuffer(retained: Bool = false) -> MetalBuffer {
        return self.toMetalMemObj(retained: retained) as! MetalBuffer
    }

    func toMetalTexture(retained: Bool = false) -> MetalTexture {
        return self.toMetalMemObj(retained: retained) as! MetalTexture
    }
}
