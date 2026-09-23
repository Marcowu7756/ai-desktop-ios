// ProductCore — CharacterState presence transition
//
// Kept separate so the transition rule stays trivially auditable.

extension CharacterState {
    public func withPresence(_ presence: Presence) -> CharacterState {
        CharacterState(
            presence: presence,
            mood: mood,
            gaze: gaze,
            gesture: gesture
        )
    }
}
