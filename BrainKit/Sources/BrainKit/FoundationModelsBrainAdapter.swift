// BrainKit — FoundationModelsBrainAdapter
//
// UNVERIFIED AND DELIBERATELY EMPTY.
//
// Apple's on-device Foundation Models framework is the natural default brain,
// but it requires an Apple toolchain to compile and an eligible device to run.
// Neither exists in this environment, so this file contains the seam and
// nothing more. It refuses to fake a reply.

import ProductCore

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public struct FoundationModelsBrainAdapter: BrainProtocol {
    public init() {}

    public func respond(to input: BrainInput) async throws -> BrainResponse {
        // Intentionally not implemented. Wiring this requires guided generation
        // mapped onto BrainWireTurn, verified on an Apple toolchain.
        throw BrainError.notImplemented(feature: "FoundationModelsBrainAdapter.respond")
    }
}
#endif
