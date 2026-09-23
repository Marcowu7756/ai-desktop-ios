// ProductCore — BrainProtocol
//
// The seam between our product and any inference provider.
// Whatever produces a BrainResponse, ProductCore only ever sees this protocol.

/// A persona the companion is role-playing. Owned by us, not by a provider.
public struct Persona: Sendable, Equatable, Codable {
    public var id: String
    public var displayName: String
    public var personality: String

    public init(id: String, displayName: String, personality: String) {
        self.id = id
        self.displayName = displayName
        self.personality = personality
    }
}

/// What the brain is allowed to see about the current session.
public struct ConversationContext: Sendable, Equatable {
    public var recentTurns: [CompanionTurn]
    public var rememberedFacts: [MemoryEvent]

    public init(recentTurns: [CompanionTurn] = [], rememberedFacts: [MemoryEvent] = []) {
        self.recentTurns = recentTurns
        self.rememberedFacts = rememberedFacts
    }
}

/// One request to a brain.
public struct BrainInput: Sendable, Equatable {
    public var utterance: String
    public var context: ConversationContext
    public var persona: Persona
    public var currentState: CharacterState

    public init(
        utterance: String,
        context: ConversationContext = ConversationContext(),
        persona: Persona,
        currentState: CharacterState = .idle
    ) {
        self.utterance = utterance
        self.context = context
        self.persona = persona
        self.currentState = currentState
    }
}

public enum BrainError: Error, Sendable, Equatable {
    /// The adapter exists but cannot run right now (no model, no network, device
    /// ineligible). Must be surfaced, never faked into a successful turn.
    case unavailable(reason: String)
    /// Deliberately unimplemented in V0.
    case notImplemented(feature: String)
    /// The provider returned something we refuse to interpret.
    case malformedResponse(reason: String)
}

/// The only inference-shaped thing ProductCore knows about.
///
/// A brain returns *candidates*. It never mutates state and it never drives the
/// character directly — see `PresentationMapper` for the deterministic step.
public protocol BrainProtocol: Sendable {
    func respond(to input: BrainInput) async throws -> BrainResponse
}
