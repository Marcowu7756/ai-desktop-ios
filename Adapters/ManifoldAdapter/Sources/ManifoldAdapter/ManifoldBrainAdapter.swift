// ManifoldAdapter — the only file in the repository permitted to name ManifoldKit.
//
// STATUS: NOT BUILT, NOT VERIFIED, NOT ENABLED.
//
// This file exists to prove the seam is real: enabling ManifoldKit is adding a
// reference to this package, and disabling it is removing that reference.
// Neither operation touches ProductCore.

import Foundation
import ProductCore
import BrainKit
import ManifoldKit

/// Exposed so the App's composition root can obtain a brain without ever naming
/// a ManifoldKit type itself.
public enum ManifoldAdapterFactory {
    public static func makeBrain() -> any BrainProtocol {
        ManifoldBrainAdapter()
    }
}

public struct ManifoldBrainAdapter: BrainProtocol {
    public init() {}

    public func respond(to input: BrainInput) async throws -> BrainResponse {
        // Deliberately unimplemented.
        //
        // Wiring this requires reading ManifoldKit's actual API (its
        // `InferenceBackend` surface and turn loop) on a Mac, then mapping its
        // output onto `BrainWireTurn` and decoding through
        // `BrainWireDecoder` — so that no ManifoldKit type escapes this file.
        //
        // It throws rather than returning a plausible-looking stub, because a
        // fake reply is worse than a visible failure.
        throw BrainError.notImplemented(feature: "ManifoldBrainAdapter.respond")
    }
}
