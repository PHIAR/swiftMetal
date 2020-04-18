import Foundation

#if !os(iOS) && !os(macOS) && !os(tvOS)
public typealias __DispatchData = DispatchData

public typealias CFTimeInterval = Double
#endif

public enum CPUCacheMode {
    case defaultCache
    case writeCombined
}

public enum DispatchType {
    case concurrent
    case serial
}

public enum FeatureSet: UInt {
    case iOS_GPUFamily1_v1 = 0
    case iOS_GPUFamily1_v2 = 2
    case iOS_GPUFamily1_v3 = 5
    case iOS_GPUFamily1_v4 = 8
    case iOS_GPUFamily1_v5 = 12
    case iOS_GPUFamily2_v1 = 1
    case iOS_GPUFamily2_v2 = 3
    case iOS_GPUFamily2_v3 = 6
    case iOS_GPUFamily2_v4 = 9
    case iOS_GPUFamily2_v5 = 13
    case iOS_GPUFamily3_v1 = 4
    case iOS_GPUFamily3_v2 = 7
    case iOS_GPUFamily3_v3 = 10
    case iOS_GPUFamily3_v4 = 14
    case iOS_GPUFamily4_v1 = 11
    case iOS_GPUFamily4_v2 = 15
    case iOS_GPUFamily5_v1 = 16
    case tvOS_GPUFamily1_v1 = 30000
    case tvOS_GPUFamily1_v2 = 30001
    case tvOS_GPUFamily1_v3 = 30002
    case tvOS_GPUFamily1_v4 = 30004
    case tvOS_GPUFamily2_v1 = 30003
    case tvOS_GPUFamily2_v2 = 30005
    case macOS_GPUFamily1_v1 = 10000
    case macOS_GPUFamily1_v2 = 10001
    case macOS_GPUFamily1_v3 = 10003
    case macOS_GPUFamily1_v4 = 10004
    case macOS_GPUFamily2_v1 = 10005
    case macOS_ReadWriteTextureTier2 = 10002
}

public enum LanguageVersion {
    case defaultVersion

    case clVersion1_0
    case clVersion1_1
    case clVersion1_2
    case clVersion2_0
    case clVersion2_1

    case glslVersion_450

    case version_1_0
    case version_1_1
    case version_1_2
    case version_2_0
    case version_2_1
}

public enum PixelFormat {
    case unknown
    case bgra8Unorm
    case rgba8Unorm
}

public enum PurgeableState: UInt {
    case keepCurrent = 1
    case nonVolatile = 2
    case volatile = 3
    case empty = 4
}

public enum SamplerAddressMode: UInt {
    case clampToEdge = 0
    case mirrorClampToEdge = 1
    case `repeat` = 2
    case mirrorRepeat = 3
    case clampToZero = 4
    case clampToBorderColor = 5
}

public enum SamplerBorderColor: UInt {
    case transparentBlack = 0
    case opaqueBlack = 1
    case opaqueWhite = 2
}

public enum SamplerMinMagFilter: UInt {
    case nearest = 0
    case linear = 1
}

public enum SamplerMipFilter: UInt {
    case notMipmapped = 0
}

public enum StorageMode: Int {
    case managed = 0
    case memoryless = 1
    case `private` = 2
    case shared = 3
}

public enum TextureType {
    case unknown
    case type1D
    case type1DArray
    case type2D
    case type2DArray
    case type3D
    case typeCube
}

public protocol Drawable {
}

public struct FunctionConstantValues {
    public init() {
    }
}

public struct Origin {
    public var x = 0
    public var y = 0
    public var z = 0

    public init() {
    }
}

public struct Region {
    public var origin = Origin()
    public var size = Size()

    public init() {
    }

    public init(origin: Origin,
                size: Size) {
        self.origin = origin
        self.size = size
    }
}

public struct RenderPassDescriptor {
    public init() {
    }
}

public struct RenderPipelineDescriptor {
    public init() {
    }
}

public struct ResourceOptions: OptionSet {
    public var rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static var storageModeManaged = ResourceOptions(rawValue: UInt(StorageMode.managed.rawValue))

    public static var storageModeMemoryless = ResourceOptions(rawValue: UInt(StorageMode.memoryless.rawValue))

    public static var storageModePrivate = ResourceOptions(rawValue: UInt(StorageMode.`private`.rawValue))

    public static var storageModeShared = ResourceOptions(rawValue: UInt(StorageMode.shared.rawValue))
}

public struct Size {
    public var width = 0
    public var height = 0
    public var depth = 0

    public init() {
    }

    public init(width: Int,
                height: Int,
                depth: Int) {
        self.width = width
        self.height = height
        self.depth = depth
    }
}

public struct TextureUsage: OptionSet {
    public let rawValue: Int

    public static let renderTarget = TextureUsage(rawValue: 1 << 0)
    public static let shaderRead = TextureUsage(rawValue: 1 << 1)
    public static let shaderWrite = TextureUsage(rawValue: 1 << 2)
    public static let pixelFormatView = TextureUsage(rawValue: 1 << 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public final class CaptureManager {
    private static let sharedInstance = CaptureManager()

    public static func shared() -> CaptureManager {
        return CaptureManager.sharedInstance
    }

    private init() {
    }

    public func makeCaptureScope(device: Device) -> CaptureScope {
        return CaptureScope(device: device)
    }

    public func makeCaptureScope(commandQueue: CommandQueue) -> CaptureScope {
        return CaptureScope(device: commandQueue.device)
    }

    public func startCapture(device: Device) {
    }

    public func startCapture(commandQueue: CommandQueue) {
    }

    public func startCapture(scope: CaptureScope) {
    }

    public func stopCapture() {
    }
}

public final class CaptureScope {
    private let device: Device

    internal init(device: Device) {
        self.device = device
    }

    public func begin() {
    }

    public func end() {
    }
}

public final class CompileOptions {
    public var fastMathEnabled = false
    public var languageVersion = LanguageVersion.defaultVersion
    public var preprocessorMacros: [String: Any]?

    public init() {
    }
}

public final class HeapDescriptor {
    private var _storageMode: StorageMode = .shared
    private var _cpuCacheMode: CPUCacheMode = .defaultCache
    private var _size = 0

    public var storageMode: StorageMode {
        get {
            return self._storageMode
        }

        set {
            self._storageMode = newValue
        }
    }

    public var cpuCacheMode: CPUCacheMode {
        get {
            return self._cpuCacheMode
        }

        set {
            self._cpuCacheMode = newValue
        }
    }

    public var size: Int {
        get {
            return self._size
        }

        set {
            self._size = newValue
        }
    }

    public init() {
    }
}

public final class SamplerDescriptor {
    public var normalizedCoordinates = true
    public var rAddressMode: SamplerAddressMode = .clampToEdge
    public var sAddressMode: SamplerAddressMode = .clampToEdge
    public var tAddressMode: SamplerAddressMode = .clampToEdge
    public var borderColor: SamplerBorderColor = .transparentBlack
    public var minFilter: SamplerMinMagFilter = .nearest
    public var magFilter: SamplerMinMagFilter = .nearest
    public var mipFilter: SamplerMipFilter = .notMipmapped
    public var lodMinClamp: Float = 0.0
    public var lodMaxClamp: Float = .greatestFiniteMagnitude
    public var lodAverage = false
    public var maxAnisotropy = 1

    public init() {
    }
}

public final class SharedEventHandle {
    public init() {
    }
}

public final class SharedEventListener {
    private let _dispatchQueue: DispatchQueue

    public var dispatchQueue: DispatchQueue {
        return self._dispatchQueue
    }

    public init() {
        self._dispatchQueue = .global()
    }

    public init(dispatchQueue: DispatchQueue) {
        self._dispatchQueue = dispatchQueue
    }
}

public final class TextureDescriptor {
    public class func texture2DDescriptor(pixelFormat: PixelFormat,
                                          width: Int,
                                          height: Int,
                                          mipmapped: Bool) -> TextureDescriptor {
        let descriptor = TextureDescriptor()

        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.mipmapLevelCount = Int(ffs(min(Int32(width), Int32(height))))
        return descriptor
    }

    public var textureType: TextureType = .unknown
    public var pixelFormat: PixelFormat = .unknown
    public var width = 0
    public var height = 0
    public var depth = 0
    public var mipmapLevelCount = 0
    public var sampleCount = 0
    public var arrayLength = 0
    public var resourceOptions = ResourceOptions()
    public var cpuCacheMode: CPUCacheMode = .defaultCache
    public var storageMode: StorageMode = .shared
    public var allowGPUOptimizedContents = true
    public var usage: TextureUsage = [ .shaderRead ]

    public init() {
    }
}
