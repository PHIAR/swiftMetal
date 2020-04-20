import simdFilament
import Foundation
import Metal

public final class MetalBufferState {
    public var offset: Int
    public var buffer: MTLBuffer?

    public init(offset: Int,
                buffer: MTLBuffer) {
        self.offset = offset
        self.buffer = buffer
    }
}

public final class MetalRenderState {
    private typealias SetBuffer = (MTLBuffer?,
                                   Int,
                                   Int) -> Void
    private typealias SetBufferOffset = (Int,
                                         Int) -> Void
    private typealias SetBytes = (UnsafeRawPointer,
                                  Int,
                                  Int) -> Void
    private typealias SetTexture = (MTLTexture?,
                                    Int) -> Void
    private typealias SetSamplerState = (MTLSamplerState?,
                                         Int) -> Void

    private let renderPipelineState: MTLRenderPipelineState
    private let depthStencilState: MTLDepthStencilState?
    private let viewport: MTLViewport
    private let cullMode: MTLCullMode
    private let winding: MTLWinding
    private let blendEnabled: Bool
    private let blendColor: simd_float4
    private let stencilFuncRef: UInt32
    private let vertexBuffers: ContiguousArray <MetalBufferState?>
    private let vertexTextures: [MTLTexture?]
    private let vertexSamplers: [MTLSamplerState?]
    private let fragmentBuffers: ContiguousArray <MetalBufferState?>
    private let fragmentTextures: [MTLTexture?]
    private let fragmentSamplers: [MTLSamplerState?]
    private let primitiveType: MTLPrimitiveType
    private let offset: Int
    private let count: Int
    private let indexType: MTLIndexType
    private let indexBuffer: MTLBuffer?

    private static func bufferProcessor(setBuffer: SetBuffer,
                                        setBufferOffset: SetBufferOffset,
                                        buffers: ContiguousArray <MetalBufferState?>,
                                        previousBuffers: ContiguousArray <MetalBufferState?>?) -> Void {
        for i in 0..<buffers.count {
            guard let bufferState = buffers[i] else {
                if let _previousBuffers = previousBuffers,
                   i < _previousBuffers.count,
                   let _ = _previousBuffers[i] {
                    setBuffer(nil,
                              0,
                              i)
                }

                continue
            }

            if let buffer = bufferState.buffer {
                guard (i >= previousBuffers?.count ?? 0) ||
                      (buffer !== previousBuffers?[i]?.buffer) else {
                    if bufferState.offset != previousBuffers?[i]?.offset {
                        setBufferOffset(bufferState.offset,
                                        i)
                    }

                    continue
                }

                setBuffer(buffer,
                          bufferState.offset,
                          i)
            } else {
                setBuffer(nil,
                          bufferState.offset,
                          i)
            }
        }
    }

    private static func textureSamplerProcessor(setTexture: SetTexture,
                                                setSamplerState: SetSamplerState,
                                                textures: [MTLTexture?],
                                                samplerStates: [MTLSamplerState?],
                                                previousTextures: [MTLTexture?]?,
                                                previousSamplerStates: [MTLSamplerState?]?) {
        for i in 0..<textures.count {
            let texture = textures[i]

            if (i >= previousTextures?.count ?? 0) ||
               (texture !== previousTextures?[i]) {
                setTexture(texture,
                           i)
            }

            let samplerState = samplerStates[i]

            if (i >= previousSamplerStates?.count ?? 0) ||
               (samplerState !== previousSamplerStates?[i]) {
                setSamplerState(samplerState,
                                i)
            }
        }
    }

    public init(renderPipelineState: MTLRenderPipelineState,
                depthStencilState: MTLDepthStencilState? = nil,
                viewport: MTLViewport,
                cullMode: MTLCullMode = .none,
                winding: MTLWinding = .counterClockwise,
                blendEnabled: Bool = false,
                blendColor: simd_float4 = simd_float4(),
                stencilFuncRef: UInt32 = 0,
                vertexBuffers: ContiguousArray <MetalBufferState?> = [],
                vertexTextures: [MTLTexture?] = [],
                vertexSamplers: [MTLSamplerState?] = [],
                fragmentBuffers: ContiguousArray <MetalBufferState?> = [],
                fragmentTextures: [MTLTexture?] = [],
                fragmentSamplers: [MTLSamplerState?] = [],
                primitiveType: MTLPrimitiveType,
                offset: Int = 0,
                count: Int = 0,
                indexType: MTLIndexType = .uint16,
                indexBuffer: MTLBuffer? = nil) {
        self.renderPipelineState = renderPipelineState
        self.depthStencilState = depthStencilState
        self.viewport = viewport
        self.cullMode = cullMode
        self.winding = winding
        self.blendEnabled = blendEnabled
        self.blendColor = blendColor
        self.stencilFuncRef = stencilFuncRef
        self.vertexBuffers = vertexBuffers
        self.vertexTextures = vertexTextures
        self.vertexSamplers = vertexSamplers
        self.fragmentBuffers = fragmentBuffers
        self.fragmentTextures = fragmentTextures
        self.fragmentSamplers = fragmentSamplers
        self.count = count
        self.offset = offset
        self.indexType = indexType
        self.indexBuffer = indexBuffer
        self.primitiveType = primitiveType
    }

    internal func execute(renderCommandEncoder: MTLRenderCommandEncoder,
                          previousRenderState: MetalRenderState?) {
        // MARK: Rendering pipeline setup

        if self.renderPipelineState !== previousRenderState?.renderPipelineState {
            renderCommandEncoder.setRenderPipelineState(self.renderPipelineState)
        }

        if let depthStencilState = self.depthStencilState {
            if depthStencilState !== previousRenderState?.depthStencilState {
                renderCommandEncoder.setDepthStencilState(depthStencilState)
            }

            if self.stencilFuncRef != previousRenderState?.stencilFuncRef {
                renderCommandEncoder.setStencilReferenceValue(self.stencilFuncRef)
            }
        }

        if self.viewport != previousRenderState?.viewport {
            renderCommandEncoder.setViewport(self.viewport)
        }

        if self.cullMode != previousRenderState?.cullMode {
            renderCommandEncoder.setCullMode(self.cullMode)
        }

        if self.winding != previousRenderState?.winding {
            renderCommandEncoder.setFrontFacing(self.winding)
        }

        if self.blendEnabled,
           self.blendEnabled != previousRenderState?.blendEnabled,
           self.blendColor != previousRenderState?.blendColor {
            let blendColor = self.blendColor

            renderCommandEncoder.setBlendColor(red: blendColor[0],
                                               green: blendColor[1],
                                               blue: blendColor[2],
                                               alpha: blendColor[3])
        }

        // MARK: Vertex and fragment buffer, constant and data buffer set up.

        MetalRenderState.bufferProcessor(setBuffer: renderCommandEncoder.setVertexBuffer,
                                         setBufferOffset: renderCommandEncoder.setVertexBufferOffset,
                                         buffers: self.vertexBuffers,
                                         previousBuffers: previousRenderState?.vertexBuffers)
        MetalRenderState.bufferProcessor(setBuffer: renderCommandEncoder.setFragmentBuffer,
                                         setBufferOffset: renderCommandEncoder.setFragmentBufferOffset,
                                         buffers: self.fragmentBuffers,
                                         previousBuffers: previousRenderState?.fragmentBuffers)

        // MARK: Texture and sampler set up.

        MetalRenderState.textureSamplerProcessor(setTexture: renderCommandEncoder.setVertexTexture,
                                                 setSamplerState: renderCommandEncoder.setVertexSamplerState,
                                                 textures: self.vertexTextures,
                                                 samplerStates: self.vertexSamplers,
                                                 previousTextures: previousRenderState?.vertexTextures,
                                                 previousSamplerStates: previousRenderState?.vertexSamplers)
        MetalRenderState.textureSamplerProcessor(setTexture: renderCommandEncoder.setFragmentTexture,
                                                 setSamplerState: renderCommandEncoder.setFragmentSamplerState,
                                                 textures: self.fragmentTextures,
                                                 samplerStates: self.fragmentSamplers,
                                                 previousTextures: previousRenderState?.fragmentTextures,
                                                 previousSamplerStates: previousRenderState?.fragmentSamplers)

        // MARK: Draw handling.

        if let indexBuffer = self.indexBuffer {
            renderCommandEncoder.drawIndexedPrimitives(type: self.primitiveType,
                                                       indexCount: self.count,
                                                       indexType: self.indexType,
                                                       indexBuffer: indexBuffer,
                                                       indexBufferOffset: self.offset)
        } else {
            renderCommandEncoder.drawPrimitives(type: self.primitiveType,
                                                vertexStart: self.offset,
                                                vertexCount: self.count)

        }
    }
}

open class MetalCommandQueue {
    enum OperationType {
        case blit
        case compute
        case event
        case native
        case present
        case render
    }

    private final class EncoderState {
        fileprivate var encoderTypes: [OperationType] = []
        fileprivate var blitCommandEncoders: ContiguousArray <(MTLBlitCommandEncoder) -> Void> = []
        fileprivate var computeCommandEncoders: ContiguousArray <(MTLComputeCommandEncoder) -> Void> = []
        fileprivate var eventEncoders: ContiguousArray <() -> Void> = []
        fileprivate var commandEncoders: ContiguousArray <(MTLCommandBuffer) -> Void> = []
        fileprivate var drawables: ContiguousArray <MTLDrawable> = []
        fileprivate var renderPipelineStates: ContiguousArray <(renderPassDescriptor: MTLRenderPassDescriptor,
                                                                renderState: MetalRenderState?)> = []
    }

    private static let maxPendingCommands = 512
    private static let maxPendingCommandBuffers = 8
    private static let numCommandBuffers = 4
    private static let blitHeapSize = 128 * 1024 * 1024

    private final let executionQueue = DispatchQueue(label: "MetalCommandQueue.executionQueue")
    private final let commandJobQueue = DispatchQueue.global(qos: .userInitiated)
    private final var sharedEventCount = UInt64(0)
    private final let sharedEventListener: MTLSharedEventListener
    private final let commandQueue: MTLCommandQueue
    private final var encoderState = EncoderState()

    public final weak var metalContext: MetalContext?
    public final var blitHeap: MTLHeap
    public final let dispatchThreadsAPISupported: Bool

    internal static func makeHeap(device: MTLDevice,
                                  descriptor: MTLHeapDescriptor) -> MTLHeap? {
    #if os(OSX) || targetEnvironment(macCatalyst) || targetEnvironment(simulator)
        return MetalHeapNone(device: device)
    #else
        return device.makeHeap(descriptor: descriptor)
    #endif
    }

    private final func getEncoderOperation(commandQueue: MTLCommandQueue,
                                           encoderTypes: UnsafeBufferPointer <OperationType>,
                                           sharedEvent: MTLSharedEvent?,
                                           lastBlitCommandCount: inout Int,
                                           lastComputeCommandCount: inout Int,
                                           lastEventCount: inout Int,
                                           lastNativeCommandCount: inout Int,
                                           lastPresentCommandCount: inout Int,
                                           lastRenderCommandCount: inout Int) {
        var currentOperationType = OperationType.native
        var operations: [(OperationType, Range <Int>)] = []
        let encoderState = self.encoderState
        let sharedEventListener = self.sharedEventListener
        var firstBlitCommandCount = lastBlitCommandCount
        var firstComputeCommandCount = lastComputeCommandCount
        var firstEventCount = lastEventCount
        var firstNativeCommandCount = lastNativeCommandCount
        var firstPresentCommandCount = lastPresentCommandCount
        var firstRenderCommandCount = lastRenderCommandCount
        var _lastBlitCommandCount = lastBlitCommandCount
        var _lastComputeCommandCount = lastComputeCommandCount
        var _lastEventCount = lastEventCount
        var _lastNativeCommandCount = lastNativeCommandCount
        var _lastPresentCommandCount = lastPresentCommandCount
        var _lastRenderCommandCount = lastRenderCommandCount

        operations.reserveCapacity(encoderTypes.count)

        func flushCommandEncoders(_ operationType: OperationType) {
            switch operationType {
            case .blit:
                if _lastBlitCommandCount > firstBlitCommandCount {
                    let range = firstBlitCommandCount..<_lastBlitCommandCount

                    operations.append((.blit, range))
                    firstBlitCommandCount = _lastBlitCommandCount
                }

            case .compute:
                if _lastComputeCommandCount > firstComputeCommandCount {
                    let range = firstComputeCommandCount..<_lastComputeCommandCount

                    operations.append((.compute, range))
                    firstComputeCommandCount = _lastComputeCommandCount
                }

            case .event:
                if _lastEventCount > firstEventCount {
                    let range = firstEventCount..<_lastEventCount

                    operations.append((.event, range))
                    firstEventCount = _lastEventCount
                }

            case .native:
                if _lastNativeCommandCount > firstNativeCommandCount {
                    let range = firstNativeCommandCount..<_lastNativeCommandCount

                    operations.append((.native, range))
                    firstNativeCommandCount = _lastNativeCommandCount
                }

            case .present:
                if _lastPresentCommandCount > firstPresentCommandCount {
                    let range = firstPresentCommandCount..<_lastPresentCommandCount

                    operations.append((.present, range))
                    firstPresentCommandCount = _lastPresentCommandCount
                }

            case .render:
                if _lastRenderCommandCount > firstRenderCommandCount {
                    let range = firstRenderCommandCount..<_lastRenderCommandCount

                    operations.append((.render, range))
                    firstRenderCommandCount = _lastRenderCommandCount
                }
            }
        }

        for operationType in encoderTypes {
            switch operationType {
            case .blit:
                _lastBlitCommandCount += 1

            case .compute:
                _lastComputeCommandCount += 1

            case .event:
                _lastEventCount += 1

            case .native:
                _lastNativeCommandCount += 1

            case .present:
                _lastPresentCommandCount += 1

            case .render:
                _lastRenderCommandCount += 1
            }

            if currentOperationType != operationType {
                flushCommandEncoders(currentOperationType)
                currentOperationType = operationType
            }
        }

        flushCommandEncoders(currentOperationType)

        lastBlitCommandCount = _lastBlitCommandCount
        lastComputeCommandCount = _lastComputeCommandCount
        lastEventCount = _lastEventCount
        lastNativeCommandCount = _lastNativeCommandCount
        lastPresentCommandCount = _lastPresentCommandCount
        lastRenderCommandCount = _lastRenderCommandCount

        let commandBuffer = commandQueue.makeCommandBuffer()!

        commandBuffer.enqueue()

        operations.forEach { (operationType, range) in
            switch operationType {
            case .blit:
                let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!

                encoderState.blitCommandEncoders[range].forEach { $0(blitCommandEncoder) }
                blitCommandEncoder.endEncoding()

            case .compute:
                let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
                let encoders = encoderState.computeCommandEncoders[range]

                encoders.forEach { $0(computeCommandEncoder) }
                computeCommandEncoder.endEncoding()

            case .event:
                let encoders = Array(encoderState.eventEncoders[range])
                let marker = UInt64(firstEventCount + range.lowerBound)
                let _sharedEvent = sharedEvent!

                _sharedEvent.notify(sharedEventListener,
                                    atValue: marker) { _, _ in
                    encoders.forEach { $0() }
                }

                commandBuffer.encodeSignalEvent(_sharedEvent,
                                                value: marker)

            case .native:
                encoderState.commandEncoders[range].forEach { $0(commandBuffer) }

            case .present:
                encoderState.drawables[range].forEach { commandBuffer.present($0) }

            case .render:
                let renderCommandEncoders = encoderState.renderPipelineStates[range]
                let renderCommandEncoderState = renderCommandEncoders.first!
                var renderPassDescriptor = renderCommandEncoderState.renderPassDescriptor
                var previousRenderState: MetalRenderState? = nil
                var renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

                for renderCommandEncoderState in renderCommandEncoders {
                    let _renderPassDescriptor = renderCommandEncoderState.renderPassDescriptor
                    let currentRenderState = renderCommandEncoderState.renderState

                    if _renderPassDescriptor != renderPassDescriptor {
                        renderCommandEncoder.endEncoding()
                        renderPassDescriptor = _renderPassDescriptor
                        previousRenderState = nil
                        renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                    }

                    currentRenderState?.execute(renderCommandEncoder: renderCommandEncoder,
                                                previousRenderState: previousRenderState)
                    previousRenderState = currentRenderState
                }

                renderCommandEncoder.endEncoding()
            }
        }

        commandBuffer.commit()
    }

    private final func flushStateOnExecutionQueue() {
        if METAL_PLATFORM_ENABLE_CONSOLE_LOG {
            print("New command buffer:")
        }

        let commandQueue = self.commandQueue

        defer {
            if !self.encoderState.drawables.isEmpty {
                self.encoderState.drawables.removeAll()
            }

            var encoderState: EncoderState? = self.encoderState

            self.encoderState = EncoderState()
            self.commandJobQueue.async { encoderState = nil }
        }

        let encoderState = self.encoderState
        let encoderTypes = encoderState.encoderTypes
        let eventEncoders = encoderState.eventEncoders

        guard encoderTypes.count != eventEncoders.count else {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let commandJobQueue = self.commandJobQueue
            let eventEncoders = self.encoderState.eventEncoders

            commandBuffer.addCompletedHandler { _ in
                commandJobQueue.async {
                    eventEncoders.forEach { $0() }
                }
            }

            commandBuffer.commit()
            return
        }

        let maxCommandBufferCommands = MetalCommandQueue.maxPendingCommands / MetalCommandQueue.numCommandBuffers
        let numEncoderRanges = encoderTypes.count / maxCommandBufferCommands
        let encoderRemaining = encoderTypes.count % maxCommandBufferCommands
        let buffer = encoderTypes.withUnsafeBufferPointer { $0 }
        var baseAddress = buffer.baseAddress!
        var lastBlitCommandCount = 0
        var lastComputeCommandCount = 0
        var lastEventCount = 0
        var lastNativeCommandCount = 0
        var lastPresentCommandCount = 0
        var lastRenderCommandCount = 0
        let sharedEvent: MTLSharedEvent? = eventEncoders.isEmpty ? nil :
                                                                   commandQueue.device.makeSharedEvent()

        for _ in 0..<numEncoderRanges {
            let encoderTypes = UnsafeBufferPointer(start: baseAddress,
                                                   count: maxCommandBufferCommands)

            self.getEncoderOperation(commandQueue: commandQueue,
                                     encoderTypes: encoderTypes,
                                     sharedEvent: sharedEvent,
                                     lastBlitCommandCount: &lastBlitCommandCount,
                                     lastComputeCommandCount: &lastComputeCommandCount,
                                     lastEventCount: &lastEventCount,
                                     lastNativeCommandCount: &lastNativeCommandCount,
                                     lastPresentCommandCount: &lastPresentCommandCount,
                                     lastRenderCommandCount: &lastRenderCommandCount)
            baseAddress = baseAddress.advanced(by: maxCommandBufferCommands)
        }

        if encoderRemaining > 0 {
            let _encoderTypes = UnsafeBufferPointer(start: baseAddress,
                                                    count: encoderRemaining)

            self.getEncoderOperation(commandQueue: commandQueue,
                                     encoderTypes: _encoderTypes,
                                     sharedEvent: sharedEvent,
                                     lastBlitCommandCount: &lastBlitCommandCount,
                                     lastComputeCommandCount: &lastComputeCommandCount,
                                     lastEventCount: &lastEventCount,
                                     lastNativeCommandCount: &lastNativeCommandCount,
                                     lastPresentCommandCount: &lastPresentCommandCount,
                                     lastRenderCommandCount: &lastRenderCommandCount)
        }
    }

    private final func opportunisticFlush() {
        guard self.executionQueue.sync(execute: { self.encoderState.encoderTypes.count }) >= MetalCommandQueue.maxPendingCommands else {
            return
        }

        self.flushAsync()
    }

    public init?(metalContext: MetalContext) {
        let metalDevice = metalContext.metalDevice
        let device = metalDevice.device
        let blitHeapDescriptor = MTLHeapDescriptor()

        blitHeapDescriptor.hazardTrackingMode = .tracked
        blitHeapDescriptor.storageMode = .shared
        blitHeapDescriptor.size = MetalCommandQueue.blitHeapSize

        guard let commandQueue = device.makeCommandQueue(maxCommandBufferCount: MetalCommandQueue.maxPendingCommandBuffers),
              let blitHeap = MetalCommandQueue.makeHeap(device: device,
                                                        descriptor: blitHeapDescriptor) else {
            return nil
        }

        self.metalContext = metalContext
        self.sharedEventListener = MTLSharedEventListener(dispatchQueue: self.commandJobQueue)
        self.commandQueue = commandQueue
        self.blitHeap = blitHeap

    #if os(iOS)
        self.dispatchThreadsAPISupported = metalDevice.getFeatureSet().rawValue >= MetalGPUVersion.iOS_GPUFamily4_v1.rawValue
    #elseif os(Android) || os(Linux) || os(macOS)
        self.dispatchThreadsAPISupported = true
    #elseif os(tvOS)
        self.dispatchThreadsAPISupported = false
    #endif
    }

    public final func enqueueCopyTexture(destinationTexture: MTLTexture,
                                         sourceTexture: MTLTexture) {
        let renderPassDescriptor = MTLRenderPassDescriptor()

        if let renderPassDescriptor = renderPassDescriptor.colorAttachments[0] {
            renderPassDescriptor.texture = destinationTexture
            renderPassDescriptor.loadAction = .clear
            renderPassDescriptor.storeAction = .store
        }

        let renderState: MetalRenderState = self.executionQueue.sync {
            let blitRenderPipelineState: MTLRenderPipelineState
            let metalDevice = self.metalContext!.metalDevice
            let pixelFormat = destinationTexture.pixelFormat

            if let _blitRenderPipelineState = metalDevice.blitRenderPipelineStates[pixelFormat] {
                blitRenderPipelineState = _blitRenderPipelineState
            } else {
                let blitRenderPipelineDescriptor = metalDevice.blitRenderPipelineDescriptor

                if let colorAttachment = blitRenderPipelineDescriptor.colorAttachments[0] {
                    colorAttachment.pixelFormat = pixelFormat
                }

                blitRenderPipelineState = try! metalDevice.device.makeRenderPipelineState(descriptor: blitRenderPipelineDescriptor)
                metalDevice.blitRenderPipelineStates[pixelFormat] = blitRenderPipelineState
                blitRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            }

            let viewport = MTLViewport(originX: 0.0,
                                       originY: 0.0,
                                       width: Double(destinationTexture.width),
                                       height: Double(destinationTexture.height),
                                       znear: 0.0,
                                       zfar: 1.0)

            return MetalRenderState(renderPipelineState: blitRenderPipelineState,
                                    viewport: viewport,
                                    fragmentTextures: [ sourceTexture ],
                                    fragmentSamplers: [ nil ],
                                    primitiveType: .triangleStrip,
                                    count: 4)
        }

        renderPassDescriptor.colorAttachments[0].texture = destinationTexture
        self.enqueueRenderPass(renderPassDescriptor: renderPassDescriptor,
                               renderState: renderState)
    }

    public final func enqueueMetalBlitCommand(eventWaitList: [MetalEvent]? = nil,
                                              event: UnsafeMutablePointer <OpaquePointer?>? = nil,
                                              operation: @escaping (MTLBlitCommandEncoder) -> Void) {
        if let _event = event {
            let metalEvent = MetalEvent(metalCommandQueue: self)

            _event.pointee = metalEvent.toOpaquePointer(retained: true)
        }

        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(.blit)
            self.encoderState.blitCommandEncoders.append(operation)
        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalComputeCommand(eventWaitList: [MetalEvent]? = nil,
                                                 event: UnsafeMutablePointer <OpaquePointer?>? = nil,
                                                 operation: @escaping (MTLComputeCommandEncoder) -> Void) {
        if let _event = event {
            let metalEvent = MetalEvent(metalCommandQueue: self)

            _event.pointee = metalEvent.toOpaquePointer(retained: true)
        }

        self.executionQueue.async {
            self.encoderState.encoderTypes.append(.compute)
            self.encoderState.computeCommandEncoders.append(operation)
        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalNativeCommand(operation: @escaping (MTLCommandBuffer) -> Void) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(.native)
            self.encoderState.commandEncoders.append(operation)
        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalNativeCommands(operations: [(MTLCommandBuffer) -> Void]) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes += Array(repeating: OperationType.native,
                                                    count: operations.count)
            self.encoderState.commandEncoders += operations
        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalNativeCommandBuffer(operation: (MTLCommandBuffer) -> Void) {
        self.executionQueue.sync {
            self.flushStateOnExecutionQueue()

            let commandBuffer = self.commandQueue.makeCommandBuffer()!

            commandBuffer.enqueue()
            operation(commandBuffer)
            commandBuffer.commit()
        }
    }

    public final func enqueueMetalNativeEvent(callback: @escaping () -> Void) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(.event)
            self.encoderState.eventEncoders.append(callback)
        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalNativeKernel(kernel: @escaping () -> Void) {
        self.enqueueMetalNativeEvent(callback: kernel)
    }

    public final func enqueueMetalNativePresent(drawable: MTLDrawable) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(.present)
            self.encoderState.drawables.append(drawable)
        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalNativeRenderCommand(renderPassDescriptor: MTLRenderPassDescriptor,
                                                      callback: @escaping (MTLRenderCommandEncoder) -> Void) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(.native)
            self.encoderState.commandEncoders.append { commandBuffer in
                let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

                callback(renderCommandEncoder)
                renderCommandEncoder.endEncoding()
            }

        }

        self.opportunisticFlush()
    }

    public final func enqueueMetalNativeMarker() -> UInt64 {
        return self.executionQueue.sync {
            let marker = self.sharedEventCount + 1

            self.sharedEventCount = marker
            return marker
        }
    }

    public final func enqueueRenderPass(renderPassDescriptor: MTLRenderPassDescriptor,
                                        renderState: MetalRenderState? = nil) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(.render)
            self.encoderState.renderPipelineStates.append((renderPassDescriptor: renderPassDescriptor,
                                                           renderState: renderState))
        }

        self.opportunisticFlush()
    }

    public final func enqueue(renderPasses: UnsafeBufferPointer <(renderPassDescriptor: MTLRenderPassDescriptor,
                                                                  renderState: MetalRenderState?)>) {
        self.executionQueue.sync {
            self.encoderState.encoderTypes.append(contentsOf: Array(repeating: OperationType.render,
                                                                    count: renderPasses.count))
            self.encoderState.renderPipelineStates.append(contentsOf: renderPasses)
        }

        self.opportunisticFlush()
    }

    public final func enqueueWriteMetalBuffer(metalBuffer: MTLBuffer,
                                              blockingWrite: Bool,
                                              offset: Int,
                                              size: Int,
                                              ptr: UnsafeRawPointer,
                                              eventWaitList: [MetalEvent]?,
                                              event: UnsafeMutablePointer <OpaquePointer?>?) {
        if METAL_PLATFORM_ENABLE_CONSOLE_LOG {
            print("\(#function): \(metalBuffer), blockingWrite: \(blockingWrite), offset: \(offset), size: \(size), ptr: \(ptr)")
        }

        guard size > 0 else {
            return
        }

        guard let ptrBuffer = self.blitHeap.makeBuffer(length: size,
                                                       options: .storageModeShared) else {
            preconditionFailure("Failed to create heap buffer. Blit heap exhausted with stats: \(self.blitHeap.maxAvailableSize(alignment: 1))")
        }

        memcpy(ptrBuffer.contents(), ptr, size)

        self.enqueueMetalBlitCommand(eventWaitList: eventWaitList,
                                     event: event) { blitCommandEncoder in
            if METAL_PLATFORM_ENABLE_INSTRUMENTATION {
                blitCommandEncoder.label = "clEnqueueWriteBuffer"
            }

            if METAL_PLATFORM_ENABLE_CONSOLE_LOG {
                print("    arguments: \(ptrBuffer) -> \(metalBuffer)")
            }

            blitCommandEncoder.copy(from: ptrBuffer,
                                    sourceOffset: 0,
                                    to: metalBuffer,
                                    destinationOffset: offset,
                                    size: size)
        }

        if blockingWrite {
            self.finish()
        }
    }

    public final func finish() {
        let finishGroup = DispatchGroup()

        finishGroup.enter()

        self.enqueueMetalNativeEvent {
            finishGroup.leave()
        }

        self.flushAsync()
        finishGroup.wait()
    }

    public final func finishWithCapture() {
        let captureManager = MTLCaptureManager.shared()
        let captureScope = captureManager.makeCaptureScope(commandQueue: self.commandQueue)
        let descriptor = MTLCaptureDescriptor()

        descriptor.captureObject = captureScope
        try! captureManager.startCapture(with: descriptor)
        captureScope.begin()

        let _ = self.finish()

        captureScope.end()
        captureManager.stopCapture()
    }

    public final func flush() {
        self.executionQueue.sync {
            let _ = self.flushStateOnExecutionQueue()
        }
    }

    public final func flushAsync() {
        self.executionQueue.async {
            let _ = self.flushStateOnExecutionQueue()
        }
    }
}

extension MTLViewport: Equatable {
    public static func == (lhs: MTLViewport, rhs: MTLViewport) -> Bool {
        return (lhs.originX == rhs.originX) &&
               (lhs.originY == rhs.originY) &&
               (lhs.width == rhs.width) &&
               (lhs.height == rhs.height) &&
               (lhs.znear == rhs.znear) &&
               (lhs.zfar == rhs.zfar)
    }
}
