import Dispatch

public let MTLCopyAllDevices = MetalCopyAllDevices
public let MTLCreateSystemDefaultDevice = MetalCreateSystemDefaultDevice

public func MTLSizeMake(_ width: Int = 0,
                        _ height: Int = 0,
                        _ depth: Int = 0) -> MTLSize {
    return MTLSize(width: width,
                   height: height,
                   depth: depth)
}

public typealias MTLBlitCommandEncoder = BlitCommandEncoder
public typealias MTLBuffer = Buffer
public typealias MTLCaptureManager = CaptureManager
public typealias MTLCaptureScope = CaptureScope
public typealias MTLCommandBuffer = CommandBuffer
public typealias MTLCommandEncoder = CommandEncoder
public typealias MTLCommandQueue = CommandQueue
public typealias MTLCompileOptions = CompileOptions
public typealias MTLComputeCommandEncoder = ComputeCommandEncoder
public typealias MTLComputePipelineState = ComputePipelineState
public typealias MTLCPUCacheMode = CPUCacheMode
public typealias MTLDevice = Device
public typealias MTLDrawable = Drawable
public typealias MTLEvent = Event
public typealias MTLFeatureSet = FeatureSet
public typealias MTLFunction = Function
public typealias MTLFunctionConstantValues = FunctionConstantValues
public typealias MTLHeap = Heap
public typealias MTLHeapDescriptor = HeapDescriptor
public typealias MTLLibrary = Library
public typealias MTLLibraryError = LibraryError
public typealias MTLOrigin = Origin
public typealias MTLPixelFormat = PixelFormat
public typealias MTLPurgeableState = PurgeableState
public typealias MTLRegion = Region
public typealias MTLRenderCommandEncoder = RenderCommandEncoder
public typealias MTLRenderPassDescriptor = RenderPassDescriptor
public typealias MTLRenderPipelineDescriptor = RenderPipelineDescriptor
public typealias MTLResource = Resource
public typealias MTLResourceOptions = ResourceOptions
public typealias MTLSamplerAddressMode = SamplerAddressMode
public typealias MTLSamplerBorderColor = SamplerBorderColor
public typealias MTLSamplerDescriptor = SamplerDescriptor
public typealias MTLSamplerMinMagFilter = SamplerMinMagFilter
public typealias MTLSamplerMipFilter = SamplerMipFilter
public typealias MTLSamplerState = SamplerState
public typealias MTLSize = Size
public typealias MTLSharedEvent = SharedEvent
public typealias MTLSharedEventHandle = SharedEventHandle
public typealias MTLSharedEventListener = SharedEventListener
public typealias MTLStorageMode = StorageMode
public typealias MTLTexture = Texture
public typealias MTLTextureDescriptor = TextureDescriptor
public typealias MTLTextureType = TextureType

#if os(macOS)
public extension CaptureManager {
    func makeCaptureScope(device: Device) -> CaptureScope {
        preconditionFailure()
    }

    func makeCaptureScope(commandQueue: CommandQueue) -> CaptureScope {
        preconditionFailure()
    }

    func startCapture(device: Device) {
        preconditionFailure()
    }

    func startCapture(commandQueue: CommandQueue) {
        preconditionFailure()
    }
}
#endif
