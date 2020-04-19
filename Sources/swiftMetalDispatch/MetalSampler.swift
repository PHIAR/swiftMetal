import Foundation
import Metal

open class MetalSampler {
    public final let samplerState: MTLSamplerState

    public init(samplerState: MTLSamplerState) {
        self.samplerState = samplerState
    }
}
