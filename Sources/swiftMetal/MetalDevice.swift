import swiftMetalShaders
import Foundation
import Metal

public enum MetalGPUVersion: Int {
    case none
    case iOS_GPUFamily1_v1
    case iOS_GPUFamily1_v2
    case iOS_GPUFamily1_v3
    case iOS_GPUFamily1_v4
    case iOS_GPUFamily1_v5
    case iOS_GPUFamily2_v1
    case iOS_GPUFamily2_v2
    case iOS_GPUFamily2_v3
    case iOS_GPUFamily2_v4
    case iOS_GPUFamily2_v5
    case iOS_GPUFamily3_v1
    case iOS_GPUFamily3_v2
    case iOS_GPUFamily3_v3
    case iOS_GPUFamily3_v4
    case iOS_GPUFamily4_v1
    case iOS_GPUFamily4_v2
    case iOS_GPUFamily5_v1
    case macOS_GPUFamily1_v1
    case macOS_GPUFamily1_v2
    case macOS_GPUFamily1_v3
    case macOS_GPUFamily1_v4
    case macOS_GPUFamily2_v1
}

private typealias BOOL = UInt32
private let TRUE = BOOL(1)
private let FALSE = BOOL(0)

open class MetalDevice {
    public static let globalMemorySize = 256 * 1024 * 1024
    public static let contextHeapSize = 128 * 1024 * 1024

    private final var svmBuffers: [Int: MTLBuffer] = [:]

    internal final let blitRenderPipelineDescriptor: MTLRenderPipelineDescriptor
    internal final var blitRenderPipelineStates: [MTLPixelFormat: MTLRenderPipelineState] = [:]

    public final let device: MTLDevice
    public final let testLimitsComputePipelineState: MTLComputePipelineState
    public final let resourceQueue = DispatchQueue(label: "MetalContext.resourceQueue")
    public final let contextHeap: MTLHeap
    public final var aliveMemObjects = Set <Int> ()

    static public func featureSet(device: MTLDevice) -> MetalGPUVersion {
    #if os(Android) || (os(iOS) && !targetEnvironment(macCatalyst))
        if device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
            return .iOS_GPUFamily5_v1
        } else if device.supportsFeatureSet(.iOS_GPUFamily4_v2) {
            return .iOS_GPUFamily4_v2
        } else if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            return .iOS_GPUFamily4_v1
        } else if device.supportsFeatureSet(.iOS_GPUFamily3_v4) {
            return .iOS_GPUFamily3_v4
        } else if device.supportsFeatureSet(.iOS_GPUFamily3_v3) {
            return .iOS_GPUFamily3_v3
        } else if device.supportsFeatureSet(.iOS_GPUFamily3_v2) {
            return .iOS_GPUFamily3_v2
        } else if device.supportsFeatureSet(.iOS_GPUFamily3_v1) {
            return .iOS_GPUFamily3_v1
        } else if device.supportsFeatureSet(.iOS_GPUFamily2_v5) {
            return .iOS_GPUFamily2_v5
        } else if device.supportsFeatureSet(.iOS_GPUFamily2_v4) {
            return .iOS_GPUFamily2_v4
        } else if device.supportsFeatureSet(.iOS_GPUFamily2_v3) {
            return .iOS_GPUFamily2_v3
        } else if device.supportsFeatureSet(.iOS_GPUFamily2_v2) {
            return .iOS_GPUFamily2_v2
        } else if device.supportsFeatureSet(.iOS_GPUFamily2_v1) {
            return .iOS_GPUFamily2_v1
        } else if device.supportsFeatureSet(.iOS_GPUFamily1_v5) {
            return .iOS_GPUFamily1_v5
        } else if device.supportsFeatureSet(.iOS_GPUFamily1_v4) {
            return .iOS_GPUFamily1_v4
        } else if device.supportsFeatureSet(.iOS_GPUFamily1_v3) {
            return .iOS_GPUFamily1_v3
        } else if device.supportsFeatureSet(.iOS_GPUFamily1_v2) {
            return .iOS_GPUFamily1_v2
        } else if device.supportsFeatureSet(.iOS_GPUFamily1_v1) {
            return .iOS_GPUFamily1_v1
        }
    #elseif os(tvOS)
        if device.supportsFeatureSet(.tvOS_GPUFamily2_v2) {
           return .iOS_GPUFamily1_v1
       }
       if device.supportsFeatureSet(.tvOS_GPUFamily2_v2) {
           return .iOS_GPUFamily2_v2
       } else if device.supportsFeatureSet(.tvOS_GPUFamily2_v1) {
           return .iOS_GPUFamily2_v1
       } else if device.supportsFeatureSet(.tvOS_GPUFamily1_v4) {
           return .iOS_GPUFamily1_v4
       } else if device.supportsFeatureSet(.tvOS_GPUFamily1_v3) {
           return .iOS_GPUFamily1_v3
       } else if device.supportsFeatureSet(.tvOS_GPUFamily1_v2) {
           return .iOS_GPUFamily1_v2
       } else if device.supportsFeatureSet(.tvOS_GPUFamily1_v1) {
           return .iOS_GPUFamily1_v1
       }
    #elseif os(Linux) || os(macOS)
        if device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
            return .macOS_GPUFamily2_v1
        } else if device.supportsFeatureSet(.macOS_GPUFamily1_v4) {
            return .macOS_GPUFamily1_v4
        } else if device.supportsFeatureSet(.macOS_GPUFamily1_v3) {
            return .macOS_GPUFamily1_v3
        } else if device.supportsFeatureSet(.macOS_GPUFamily1_v2) {
            return .macOS_GPUFamily1_v2
        } else if device.supportsFeatureSet(.macOS_GPUFamily1_v1) {
            return .macOS_GPUFamily1_v1
        }
    #elseif targetEnvironment(macCatalyst)
        if device.supportsFamily(.macCatalyst2) {
            return .macOS_GPUFamily2_v1
        } else if device.supportsFamily(.macCatalyst1) {
            return .macOS_GPUFamily1_v4
        }
    #endif

        preconditionFailure("Unknown platform.")
    }

    public init(device: MTLDevice) {
        let contextHeapDescriptor = MTLHeapDescriptor()

        contextHeapDescriptor.hazardTrackingMode = .tracked
        contextHeapDescriptor.size = MetalDevice.contextHeapSize
        contextHeapDescriptor.storageMode = .shared

        let library = try! device.makeDefaultLibrary(bundle: Bundle.swiftMetalShadersBundle)
        let testLimitsFunction = library.makeFunction(name: "testLimits")!
        let testLimitsComputePipelineState = try! device.makeComputePipelineState(function: testLimitsFunction)
        let blitKernelVertexFunction = library.makeFunction(name: "blitKernelVertexFunction")
        let blitKernelFragmentFunction = library.makeFunction(name: "blitKernelFragmentFunction")
        let blitRenderPipelineDescriptor = MTLRenderPipelineDescriptor()

        blitRenderPipelineDescriptor.vertexFunction = blitKernelVertexFunction
        blitRenderPipelineDescriptor.fragmentFunction = blitKernelFragmentFunction

        if let colorAttachment = blitRenderPipelineDescriptor.colorAttachments[0] {
            colorAttachment.pixelFormat = .bgra8Unorm
        }

        let blitRenderPipelineStates: [MTLPixelFormat: MTLRenderPipelineState] = [
            .bgra8Unorm: try! device.makeRenderPipelineState(descriptor: blitRenderPipelineDescriptor),
        ]

        let contextHeap = MetalCommandQueue.makeHeap(device: device,
                                                     descriptor: contextHeapDescriptor)!

        self.device = device
        self.testLimitsComputePipelineState = testLimitsComputePipelineState
        self.blitRenderPipelineDescriptor = blitRenderPipelineDescriptor
        self.blitRenderPipelineStates = blitRenderPipelineStates
        self.contextHeap = contextHeap
    }

    public final func getBuffer(pointer: Int) -> (buffer: MTLBuffer,
                                                  offset: Int)? {
        return self.resourceQueue.sync {
            guard let buffer = self.svmBuffers[pointer] else {
                for entry in self.svmBuffers {
                    let key = entry.key
                    let buffer = entry.value

                    guard (pointer < key) ||
                          (pointer >= (key + buffer.length)) else {
                        return (buffer: buffer,
                                offset: pointer - key)
                    }
                }

                return nil
            }

            return (buffer: buffer,
                    offset: 0)
        }
    }

    public final func getFeatureSet() -> MetalGPUVersion {
        return MetalDevice.featureSet(device: self.device)
    }

    public final func makeBuffer(size: Int) -> MetalBuffer? {
        return self.resourceQueue.sync {
            return HeapBuffer(metalDevice: self,
                              size: size)
        }
    }

    public final func makeBuffer(size: Int,
                                 hostPtr: UnsafeMutableRawPointer? = nil) -> MetalBuffer? {
        return self.resourceQueue.sync {
            return HeapBuffer(metalDevice: self,
                              size: size,
                              hostPtr: hostPtr)
        }
    }

    public final func sharedVirtualMemoryAlloc(size: size_t,
                                               alignment: Int) -> UnsafeMutableRawPointer? {
        if METAL_PLATFORM_ENABLE_CONSOLE_LOG {
            print(String(format: "\(#function)(size: \(size)), alignment: \(alignment))"))
        }

        guard let buffer = self.device.makeBuffer(length: size,
                                                  options: .storageModeShared) else {
            return nil
        }

        let baseAddress = buffer.contents()

        self.resourceQueue.async {
            self.svmBuffers[Int(bitPattern: baseAddress)] = buffer
        }

        return baseAddress
    }

    public final func sharedVirtualMemoryFree(pointer: UnsafeMutableRawPointer) {
        if METAL_PLATFORM_ENABLE_CONSOLE_LOG {
            print(String(format: "\(#function)(pointer: \(pointer))"))
        }

        self.resourceQueue.async {
            self.svmBuffers[Int(bitPattern: pointer)] = nil
        }
    }
}
