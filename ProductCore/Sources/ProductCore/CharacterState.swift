// ProductCore — CharacterState
//
// Closed enums on purpose: a model may not invent a mood, a gaze, or a gesture.

/// What the character is doing right now, independent of mood.
public enum Presence: String, Sendable, Equatable, CaseIterable, Codable {
    case idle
    case listening
    case thinking
    case speaking
    case failed
}

public enum Mood: String, Sendable, Equatable, CaseIterable, Codable {
    case neutral
    case happy
    case sad
    case sleepy
    case curious
    case shy
}

public enum Gaze: String, Sendable, Equatable, CaseIterable, Codable {
    case user
    case away
    case up
    case down
    case left
    case right
}

public enum Gesture: String, Sendable, Equatable, CaseIterable, Codable {
    case none
    case wave
    case nod
    case tilt
    case cheek
    case clasp
    case cheer
    case dance
}

/// The single value the renderer consumes.
///
/// No view or animation code reads `BrainResponse`. The renderer only ever sees
/// this type, which is what makes character behaviour reproducible.
public struct CharacterState: Sendable, Equatable, Codable {
    public var presence: Presence
    public var mood: Mood
    public var gaze: Gaze
    public var gesture: Gesture

    public init(
        presence: Presence = .idle,
        mood: Mood = .neutral,
        gaze: Gaze = .user,
        gesture: Gesture = .none
    ) {
        self.presence = presence
        self.mood = mood
        self.gaze = gaze
        self.gesture = gesture
    }

    public static let idle = CharacterState()

    /// Deterministic smoothing rule: adopt only what we can interpret.
    /// Anything unrecognised keeps its previous value rather than guessing.
    public func applying(candidate: CharacterStateCandidate) -> CharacterState {
        CharacterState(
            presence: presence,
            mood: Mood(rawValue: candidate.mood) ?? mood,
            gaze: Gaze(rawValue: candidate.gaze) ?? gaze,
            gesture: Gesture(rawValue: candidate.gesture) ?? gesture
        )
    }
}
