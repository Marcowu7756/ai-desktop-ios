// ProductCore — PresentationMapper
//
// The deterministic step. This is the asset worth protecting: given the same
// BrainResponse and the same previous CharacterState, this always yields the
// same CompanionTurn. No randomness, no second model call, no view access.

import Foundation

public struct PresentationMapper: Sendable {
    public init() {}

    /// Rules, in order:
    /// 1. Presence is derived from whether there is anything to present.
    /// 2. mood / gaze / gesture are adopted only if they name a known value;
    ///    otherwise the previous value is kept (see `applying(candidate:)`).
    /// 3. Memory events are passed through as already-validated values.
    /// 4. An action intent is carried forward unchanged; whether it may run is
    ///    not this type's decision.
    public func map(_ response: BrainResponse, previous: CharacterState) -> CompanionTurn {
        let trimmed = response.presentation.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = previous
            .applying(candidate: response.characterStateCandidate)
            .withPresence(trimmed.isEmpty ? .idle : .speaking)

        return CompanionTurn(
            characterState: next,
            presentation: trimmed,
            memoryEvents: response.memoryEvents,
            actionIntent: response.actionIntent
        )
    }
}
