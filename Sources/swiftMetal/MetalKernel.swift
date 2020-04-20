import Foundation
import Metal

open class MetalKernel {
    private static let numReservedArguments = 32
    private static let reservedArguments = Array(repeating: KernelArg(),
                                                 count: MetalKernel.numReservedArguments)

    public enum KernelArgType {
        case none
        case buffer
        case constant
        case data
    }

    public struct KernelArg {
        public typealias Constant = (UInt64, UInt64, UInt64, UInt64,
                                     UInt64, UInt64, UInt64, UInt64)

        public let type: KernelArgType
        public let buffer: (MTLBuffer, Int)?
        public let data: Data?
        public var constant: Constant
        public let size: Int

        public init() {
            self.type = .none
            self.buffer = nil
            self.data = nil
            self.constant = Constant(0, 0, 0, 0, 0, 0, 0, 0)
            self.size = 0
        }

        public init(buffer: (MTLBuffer, Int)) {
            self.type = .buffer
            self.buffer = buffer
            self.data = nil
            self.constant = Constant(0, 0, 0, 0, 0, 0, 0, 0)
            self.size = 0
        }

        public init(data: Data) {
            self.type = .data
            self.buffer = nil
            self.data = data
            self.constant = Constant(0, 0, 0, 0, 0, 0, 0, 0)
            self.size = 0
        }

        public init(constant: UInt64,
                    size: Int) {
            self.type = .constant
            self.buffer = nil
            self.data = nil
            self.constant = Constant(constant, 0, 0, 0, 0, 0, 0, 0)
            self.size = size
        }

        public init(pointer: UnsafeRawPointer,
                    size: Int) {
            self.type = .constant
            self.buffer = nil
            self.data = nil

            precondition(size <= MemoryLayout <Constant>.size)

            var constant = Constant(0, 0, 0, 0, 0, 0, 0, 0)

            memcpy(&constant.0, pointer, size)
            self.constant = constant
            self.size = size
        }
    }

    public final let metalContext: MetalContext
    public final let computePipelineState: MTLComputePipelineState
    public final var arguments = MetalKernel.reservedArguments
    public final var maxSetArgument = 0

    public convenience init?(metalProgram: MetalProgram,
                             name: UnsafePointer <CChar>) {
        guard let function = metalProgram.makeFunction(name: name) else {
            return nil
        }

        let metalContext = metalProgram.metalContext
        let library = metalContext.metalDevice
        let device = library.device
        var computePipelineState: MTLComputePipelineState

        do {
            computePipelineState = try device.makeComputePipelineState(function: function)
        } catch {
            return nil
        }

        self.init(metalContext: metalContext,
                  computePipelineState: computePipelineState)
    }

    public required init(metalContext: MetalContext,
                         computePipelineState: MTLComputePipelineState) {
        self.metalContext = metalContext
        self.computePipelineState = computePipelineState
    }
}
