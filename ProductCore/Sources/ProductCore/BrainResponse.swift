// ProductCore — BrainResponse
//
// What a brain hands back: *candidates*, not decisions.

/// The character-state part of a brain response, as raw strings.
///
/// Deliberately untyped: model output is untrusted input. `PresentationMapper`
/// is the only thing allowed to turn these strings into closed enums.
///
/// Field order is intentional and inherited from a validated prior pattern:
/// mood / gaze / gesture are placed before the spoken line so that an adapter
/// which emits fields progressively can commit the face and pose before the
/// sentence is finished.
public struct CharacterStateCandidate: Sendable, Equatable, Codable {
    public var mood: String
    public var gaze: String
    public var gesture: String

    public init(mood: String = "", gaze: String = "", gesture: String = "") {
        self.mood = mood
        self.gaze = gaze
        self.gesture = gesture
    }
}

/// The envelope every brain adapter must produce.
///
/// Validation of these candidates happens in ProductCore, never in the adapter.
public struct BrainResponse: Sendable, Equatable, Codable {
    public var characterStateCandidate: CharacterStateCandidate
    public var presentation: String
    public var memoryEvents: [MemoryEvent]
    public var actionIntent: ActionIntent?

    public init(
        characterStateCandidate: CharacterStateCandidate = CharacterStateCandidate(),
        presentation: String,
        memoryEvents: [MemoryEvent] = [],
        actionIntent: ActionIntent? = nil
    ) {
        self.characterStateCandidate = characterStateCandidate
        self.presentation = presentation
        self.memoryEvents = memoryEvents
        self.actionIntent = actionIntent
    }
}
