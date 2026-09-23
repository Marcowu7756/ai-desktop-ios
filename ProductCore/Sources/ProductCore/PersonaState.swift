// ProductCore — PersonaState
//
// Owned by the product. Never derived from a provider's notion of identity.

/// The live state of one companion: identity + current character state.
public struct PersonaState: Sendable, Equatable, Codable {
    public var persona: Persona
    public var characterState: CharacterState
    /// Placeholder relationship counter. Not persisted in V0.
    public var affinity: Int

    public init(persona: Persona, characterState: CharacterState = .idle, affinity: Int = 0) {
        self.persona = persona
        self.characterState = characterState
        self.affinity = affinity
    }
}
