import Foundation
import Metal

open class MetalCompilerSession {
    public final let source: String
    public final let metalSource: String?

    public init?(source: String,
                 metalSource: String? = nil) {
        self.source = source
        self.metalSource = metalSource
    }

    public func getMetalSource() -> String? {
        return self.metalSource
    }

    public func getMetalLibrary(device: MTLDevice,
                                preprocessorMacros: [String : NSObject]? = nil) -> MTLLibrary? {
        guard let metalSource = self.metalSource else {
            return nil
        }

        var library: MTLLibrary
        let options = MTLCompileOptions()

        options.fastMathEnabled = true
        options.preprocessorMacros = preprocessorMacros
        options.languageVersion = .version2_2

        library = try! device.makeLibrary(source: metalSource,
                                          options: options)

        return library
    }
}

open class MetalCompiler {
    public init() {
    }
}
