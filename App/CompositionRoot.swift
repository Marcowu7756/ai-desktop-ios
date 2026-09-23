// App — CompositionRoot
//
// The ONLY place adapters are chosen. It knows about BrainKit and ProductCore.
// It must never name a provider type: swapping brains later means registering
// one more factory here, not touching Persona or State.

#if canImport(SwiftUI)
import Foundation
import ProductCore
import BrainKit

enum CompositionRoot {
    static let defaultPersona = Persona(
        id: "companion-01",
        displayName: "Lumi",
        personality: "warm, concise, curious"
    )

    /// V0 policy: mock brain only. Every other adapter is off.
    ///
    /// Enabling a real brain later is a config change:
    ///   .register(.remoteLLM) { RemoteLLMBrainAdapter(transport: ..., modelID: ...) }
    /// and a `BrainPolicy` whose `enabled` set includes it.
    static func makeBrain() -> (any BrainProtocol)? {
        let registry = BrainRegistry()
            .register(.mock) { MockBrainAdapter() }

        return registry.brain(for: .v0Default)
    }

    @MainActor
    static func makeAppModel() -> AppModel {
        let brain = makeBrain()
        let session = CompanionSession(persona: defaultPersona, brain: brain)
        return AppModel(
            session: session,
            persona: defaultPersona,
            brainIsConfigured: brain != nil
        )
    }
}
#endif
