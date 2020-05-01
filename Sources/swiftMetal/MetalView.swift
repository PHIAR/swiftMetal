import Foundation
import Metal

#if os(iOS) || os(tvOS)
import QuartzCore
import UIKit

public typealias Layer = Layer
public typealias MetalLayer = CAMetalLayer
public typealias View = UIView

private let PHIAR_METAL_USE_CA_DISPLAY_LINK = true
#elseif os(macOS)
import AppKit

public typealias Layer = Layer
public typealias MetalLayer = CAMetalLayer
public typealias View = NSView

private let PHIAR_METAL_USE_CA_DISPLAY_LINK = false
#elseif os(Android) || os(Linux)
public typealias CGContext = OpaquePointer
public typealias Layer = VisualLayer

open class MetalLayer: Layer {
    public var device: Device? = nil
    public var delegate: MetalLayerDelegate? = nil
    public var pixelFormat: PixelFormat = .bgra8Unorm
    public var maximumDrawableCount = 2
    public var framebufferOnly = false
    public var drawableSize = Size()

    open func nextDrawable() -> Drawable? {
        return nil
    }
}

public protocol MetalLayerDelegate {
}

open class View {
    public var layer: Layer? = nil
    public var frame = CGRect()

    public init(frame: CGRect) {
        self.frame = frame
    }

}

private let PHIAR_METAL_USE_CA_DISPLAY_LINK = false

#endif

@objc open class MetalView: View {
#if os(iOS) || os(tvOS)
    private class Presenter {
        private weak var metalView: MetalView?

        fileprivate init(metalView: MetalView) {
            self.metalView = metalView
        }

        @objc public func displayLinkPresent() {
            guard let _metalView = self.metalView else {
                return
            }

            _metalView.presentView()
        }
    }
#endif

    // MARK: Configuration for swapchain

    private static let maximumDrawableCount = 3

    // MARK: Private statically managed objects.

    private static let defaultMetalContext = MetalContext(metalDevice: MetalDevice(device: MTLCreateSystemDefaultDevice()!))

    // MARK: Private variables for tracking and managing view related state.

    private final weak var _presentationDelegate: MetalPresentationDelegate? = nil
    private final var _frameRate = TimeInterval(0.0)

#if os(iOS) || os(tvOS)
    private final var displayLink: CADisplayLink!
#endif

    private final var frameTimer: DispatchSourceTimer!

#if os(macOS)
    // NB: This layer is used by MacOS only.
    private final let backingMetalLayer = MetalLayer()
    private final var contentScaleFactor: CGFloat = 1.0
#endif

    // MARK: Publically available state variables

    public final let executionQueue = DispatchQueue(label: "MetalView.executionQueue")
    public final let metalContext: MetalContext
    public final let metalCommandQueue: MetalCommandQueue

    // MARK: Overrides for `View` public properties

#if os(iOS) || os(tvOS)
    @objc open override class var layerClass: AnyClass {
        return MetalLayer.self
    }
#elseif os(macOS)
    // NB: layer property cannot be overriden on MetalViews.
    @objc public override var layer: Layer? {
        get {
            return self.backingMetalLayer
        }

        set {
            super.layer = self.backingMetalLayer
        }
    }
#elseif os(Android) || os(Linux)
    open class var layerClass: AnyClass {
        return MetalLayer.self
    }
#endif

    // MARK: Public API properties
    public final var caMetalLayer: MetalLayer { self.layer as! MetalLayer }

    public final var isPresentationEnabled: Bool {
    #if os(iOS) || os(tvOS)
        return UIApplication.shared.applicationState == .active
    #else
        return true
    #endif
    }

    public final var frameRate: TimeInterval {
        get {
            return self.executionQueue.sync {
                return self._frameRate
            }
        }
        set {
            self.executionQueue.async {
                guard newValue != self._frameRate else {
                    return
                }

                if !PHIAR_METAL_USE_CA_DISPLAY_LINK {
                    self.frameTimer.cancel()
                }

                self._frameRate = newValue
                self.reconfigureTimer()
            }
        }
    }

    open var presentationDelegate: MetalPresentationDelegate? {
        get {
            return self.executionQueue.sync {
                return self._presentationDelegate
            }
        }
        set {
            // NB: Quiesce events to the presentation delegate when reconfiguring.
            self.executionQueue.sync {
                self._presentationDelegate = newValue
            }
        }
    }

#if os(macOS)
    @objc public override var wantsLayer: Bool {
        // NB: macOSism to always return a layer instead of using legacy draw path.
        get {
            return true
        }
        set {
            super.wantsLayer = true
        }
    }
#endif

    // MARK: CAMetalLayer manipulation and presentation dispatch helper routines.

    public final func presentView() {
        dispatchPrecondition(condition: .onQueue(.main))

        let presentCall = {
            guard self.isPresentationEnabled,
                  let presentationDelegate = self.presentationDelegate,
                  let currentDrawable = self.caMetalLayer.nextDrawable() else {
                return
            }

            let texture = currentDrawable.texture

            guard texture.width > 0,
                  texture.height > 0 else {
                return
            }

            let currentMetalTexture = self.metalContext.makeTexture(texture: texture)

            guard presentationDelegate.present(metalTexture: currentMetalTexture) else {
                return
            }

            self.metalCommandQueue.enqueueMetalNativePresent(drawable: currentDrawable)
            self.metalCommandQueue.flush()
        }

    #if os(iOS) || os(macOS) || os(tvOS)
        autoreleasepool {
            presentCall()
        }
    #elseif os(Android) || os(Linux)
        presentCall()
    #endif
    }

    private final func reconfigureTimer() {
        dispatchPrecondition(condition: .onQueue(self.executionQueue))

    #if os(iOS) || os(tvOS)
        guard !PHIAR_METAL_USE_CA_DISPLAY_LINK else {
            if let displayLink = self.displayLink {
                displayLink.isPaused = true
                displayLink.preferredFramesPerSecond = Int(self._frameRate)
                displayLink.isPaused = self._frameRate == 0
            }

            return
        }
    #endif

        let frameTimer = DispatchSource.makeTimerSource(flags: .strict,
                                                        queue: .main)

        frameTimer.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.presentView()
        }

        frameTimer.schedule(deadline: .now(),
                            repeating: 1.0 / self._frameRate)
        frameTimer.activate()

        self.frameTimer = frameTimer
    }

    private final func setupView() {
        let layer = self.layer as! MetalLayer

        layer.delegate = self
        layer.device = self.metalContext.metalDevice.device
        layer.framebufferOnly = true
        layer.maximumDrawableCount = MetalView.maximumDrawableCount
        layer.pixelFormat = MetalTexture.optimalDrawablePixelFormat()

    #if os(iOS) || os(tvOS)
        if PHIAR_METAL_USE_CA_DISPLAY_LINK {
            let presenter = Presenter(metalView: self)
            let displayLink = CADisplayLink(target: presenter,
                                            selector: #selector(displayLinkPresent))

            displayLink.preferredFramesPerSecond = Int(self._frameRate)
            displayLink.add(to: .current,
                            forMode: .default)

            self.displayLink = displayLink
        }
    #endif

        self.executionQueue.async {
            self.reconfigureTimer()
        }

    #if os(macOS)
        self.wantsLayer = true
    #endif
    }

    // MARK: View constructors

    public init(frame: CGRect,
                metalContext: MetalContext) {
        self.metalContext = metalContext
        self.metalCommandQueue = metalContext.commandQueue()
        super.init(frame: frame)
        self.setupView()
    }

#if os(iOS) || os(tvOS)
    @objc public override init(frame frameRect: CGRect) {
        self.metalContext = MetalView.defaultMetalContext
        self.metalCommandQueue = metalContext.commandQueue()
        super.init(frame: frameRect)
        self.setupView()
    }
#elseif os(macOS)
    @objc public override init(frame frameRect: NSRect) {
        self.metalContext = MetalView.defaultMetalContext
        self.metalCommandQueue = metalContext.commandQueue()
        super.init(frame: frameRect)
        self.setupView()
    }
#endif

#if os(iOS) || os(tvOS) || os(macOS)
    public init?(coder: NSCoder,
                 metalContext: MetalContext) {
        self.metalContext = metalContext
        self.metalCommandQueue = metalContext.commandQueue()
        super.init(coder: coder)
        self.setupView()
    }

    @objc public required init?(coder: NSCoder) {
        self.metalContext = MetalView.defaultMetalContext
        self.metalCommandQueue = MetalCommandQueue(metalContext: metalContext)!
        super.init(coder: coder)
        self.setupView()
    }
#endif

    deinit {
    #if os(iOS) || os(tvOS)
        guard !PHIAR_METAL_USE_CA_DISPLAY_LINK else {
            self.displayLink.remove(from: .current,
                                    forMode: .default)
            self.displayLink.invalidate()
            self.displayLink = nil
            return
        }
    #endif

        self.frameTimer.cancel()
    }

#if os(iOS) || os(tvOS)
    @objc public func displayLinkPresent() {
        self.caMetalLayer.setNeedsDisplay()
    }
#endif

#if os(iOS) || os(tvOS)
    @objc public override func didMoveToWindow() {
        super.didMoveToWindow()
        self.contentScaleFactor = self.window?.screen.nativeScale ?? 1.0
    }

    @objc public override func layoutSubviews() {
        super.layoutSubviews()
        self.caMetalLayer.frame = self.frame
        self.caMetalLayer.drawableSize = CGSize(width: self.frame.size.width * self.contentScaleFactor,
                                                height: self.frame.size.height * self.contentScaleFactor)
    }
#elseif os(macOS)
    @objc open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.contentScaleFactor = self.window?.screen?.backingScaleFactor ?? 1.0
    }

    @objc open override func layout() {
        super.layout()
        self.caMetalLayer.frame = self.frame
        self.caMetalLayer.drawableSize = CGSize(width: self.frame.size.width * self.contentScaleFactor,
                                                height: self.frame.size.height * self.contentScaleFactor)
    }
#endif
}

#if os(iOS)
extension MetalView {
    @objc public override func display(_ layer: Layer) {
        self.presentView()
    }

    @objc public override func draw(_ layer: Layer,
                                    in ctx: CGContext) {
    }
}
#elseif os(macOS)
extension MetalView: CALayerDelegate {
    @objc public func display(_ layer: Layer) {
        self.presentView()
    }

    @objc public func draw(_ layer: Layer,
                           in ctx: CGContext) {
    }
}
#elseif os(Android) || os(Linux)
extension MetalView: MetalLayerDelegate {
    public func display(_ layer: Layer) {
        self.presentView()
    }

    public func draw(_ layer: Layer,
                     in ctx: CGContext) {
    }
}
#endif
