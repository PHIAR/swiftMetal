import Foundation
import Metal

open class MetalProgram {
    private final var usesSpecializationConstants = false
    private final let specializationConstants = MTLFunctionConstantValues()
    private final var releaseCallback: (() -> Void)? = nil

    public final let metalContext: MetalContext
    public final var library: MTLLibrary? = nil
    public final var kernelCache: [String: MetalKernel] = [:]

    public init?(metalContext: MetalContext,
                 library: MTLLibrary? = nil) {
        self.metalContext = metalContext
    }

    deinit {
        if let callback = self.releaseCallback {
            callback()
        }
    }

    internal final func makeFunction(name: UnsafePointer <CChar>) -> MTLFunction? {
        guard let library = self.library else {
            return nil
        }

        let specializationConstants = self.specializationConstants
        let makeFunction: (UnsafePointer <CChar>) -> MTLFunction? = self.usesSpecializationConstants ? { name in
            library.makeFunction(name: String(cString: name))
        } : { name in
            do {
                return try library.makeFunction(name: String(cString: name),
                                                constantValues: specializationConstants)
            } catch {
                return nil
            }
        }

        guard let function = makeFunction(name) else {
            return nil
        }

        return function
    }

    open func buildProgram(options: String? = nil) -> Bool {
        return false
    }

    public func getData() -> Data? {
        return self.library?.getData()
    }

    public final func setReleaseCallback(_ callback: @escaping () -> Void) {
        self.releaseCallback = callback
    }

    public final func setSpecializationConstant(specId: Int,
                                                specSize: size_t,
                                                specPtr: UnsafeRawPointer?) {
        self.usesSpecializationConstants = true
    }
}
