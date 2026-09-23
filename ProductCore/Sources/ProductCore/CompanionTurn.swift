// ProductCore — CompanionTurn
//
// The resolved turn: what the product system has accepted and committed.

/// One committed interaction.
///
/// `BrainResponse` carries candidates; `CompanionTurn` carries what ProductCore
/// decided. Only `PresentationMapper` produces this type.
public struct CompanionTurn: Sendable, Equatable, Codable {
    public var characterState: CharacterState
    public var presentation: String
    public var memoryEvents: [MemoryEvent]
    /// An intent is still a request, not a performed action. Authorization is
    /// decided by `ActionBoundary`.
    public var actionIntent: ActionIntent?

    public init(
        characterState: CharacterState,
        presentation: String,
        memoryEvents: [MemoryEvent] = [],
        actionIntent: ActionIntent? = nil
    ) {
        self.characterState = characterState
        self.presentation = presentation
        self.memoryEvents = memoryEvents
        self.actionIntent = actionIntent
    }
}
