// UNVERIFIED: not executed. No Swift toolchain in this environment.

import XCTest
import ProductCore

final class PresentationMapperTests: XCTestCase {
    private let mapper = PresentationMapper()

    func testKnownMoodIsAdoptedAndSpeechMarksSpeaking() {
        let response = BrainResponse(
            characterStateCandidate: CharacterStateCandidate(mood: "happy", gaze: "user", gesture: "wave"),
            presentation: "Hello!"
        )

        let turn = mapper.map(response, previous: .idle)

        XCTAssertEqual(turn.characterState.mood, .happy)
        XCTAssertEqual(turn.characterState.gesture, .wave)
        XCTAssertEqual(turn.characterState.presence, .speaking)
    }

    func testUnknownMoodKeepsPreviousValueInsteadOfGuessing() {
        let previous = CharacterState(presence: .idle, mood: .sad, gaze: .away, gesture: .clasp)
        let response = BrainResponse(
            characterStateCandidate: CharacterStateCandidate(mood: "ecstatic", gaze: "somewhere", gesture: "backflip"),
            presentation: "mm"
        )

        let turn = mapper.map(response, previous: previous)

        XCTAssertEqual(turn.characterState.mood, .sad)
        XCTAssertEqual(turn.characterState.gaze, .away)
        XCTAssertEqual(turn.characterState.gesture, .clasp)
    }

    func testEmptyPresentationYieldsIdlePresence() {
        let response = BrainResponse(presentation: "   ")
        let turn = mapper.map(response, previous: CharacterState(presence: .speaking))

        XCTAssertEqual(turn.characterState.presence, .idle)
        XCTAssertEqual(turn.presentation, "")
    }

    func testMappingIsDeterministic() {
        let response = BrainResponse(
            characterStateCandidate: CharacterStateCandidate(mood: "curious", gaze: "up", gesture: "tilt"),
            presentation: "why?"
        )
        let previous = CharacterState(presence: .listening, mood: .neutral, gaze: .user, gesture: .none)

        let first = mapper.map(response, previous: previous)
        let second = mapper.map(response, previous: previous)

        XCTAssertEqual(first, second)
    }
}
