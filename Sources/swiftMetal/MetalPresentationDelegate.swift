import Foundation
import Metal

/**
    The presentation delegate for a Metal View.

    Conformance to this delegate indicates thats the client can provide the contents for the backbuffer prior to a
    presentation front to back buffer swap. The client does not need to perform the present, as that is scheduled
    by the Metal View itself based on a configurable frame rate timer.
*/
public protocol MetalPresentationDelegate: class {
    /**
        Schedule a client present.

        MetalViews callback via the presentation delegate to acquire presentation contents for the
        next scheduled backbuffer from the client's perspective.

        - Parameters:
            - metalTexture: the texture wrapping the drawable for the actively rendered to backbuffer.

        - Returns:
            - true if a present is to be scheduled, false if the current presentation output is to be maintained.
    */
    func present(metalTexture: MetalTexture) -> Bool
}
