// UNVERIFIED until the boundary gate runs it.

import XCTest
import ProductCore

private struct LabeledBrain: BrainProtocol {
    let response: BrainResponse

    func respond(to input: BrainInput) async throws -> BrainResponse {
        response
    }
}

private struct FailingBrain: BrainProtocol {
    let error: BrainError

    func respond(to input: BrainInput) async throws -> BrainResponse {
        throw error
    }
}

private struct SwitchingBrain: BrainProtocol {
    func respond(to input: BrainInput) async throws -> BrainResponse {
        if input.utterance == "hello" {
            return BrainResponse(
                characterStateCandidate: CharacterStateCandidate(mood: "happy", gaze: "user", gesture: "wave"),
                presentation: "hello back"
            )
        }
        return BrainResponse(presentation: "mm")
    }
}

final class CompanionSessionTests: XCTestCase {
    private let persona = Persona(id: "companion-01", displayName: "Lumi", personality: "warm")

    func testReplyUpdatesStateAndTranscript() async {
        let brain = LabeledBrain(
            response: BrainResponse(
                characterStateCandidate: CharacterStateCandidate(mood: "happy", gaze: "user", gesture: "wave"),
                presentation: "hello"
            )
        )
        let session = CompanionSession(persona: persona, brain: brain)

        let result = await session.submit("hi")

        XCTAssertEqual(result.outcome, .replied)
        XCTAssertEqual(result.state.characterState.mood, .happy)
        XCTAssertEqual(result.state.characterState.presence, .speaking)

        let turns = await session.turns()
        XCTAssertEqual(turns.count, 1)
        XCTAssertEqual(turns.first?.presentation, "hello")
    }

    func testNoBrainIsReportedNotFaked() async {
        let session = CompanionSession(persona: persona, brain: nil)

        let result = await session.submit("hi")

        XCTAssertEqual(result.outcome, .noBrainConfigured)
        XCTAssertNil(result.turn)
        let turns = await session.turns()
        XCTAssertTrue(turns.isEmpty)
    }

    func testBrainFailureCommitsNothing() async {
        let session = CompanionSession(
            persona: persona,
            brain: FailingBrain(error: .unavailable(reason: "no model"))
        )

        let result = await session.submit("hi")

        XCTAssertEqual(result.outcome, .brainFailed(.unavailable(reason: "no model")))
        XCTAssertNil(result.turn)
        XCTAssertEqual(result.state.characterState.presence, .failed)
        let turns = await session.turns()
        XCTAssertTrue(turns.isEmpty)
    }

    func testMemoryEventsReachTheMemoryStore() async {
        let brain = LabeledBrain(
            response: BrainResponse(
                presentation: "noted",
                memoryEvents: [MemoryEvent(category: .name, value: "Ming")]
            )
        )
        let memory = InMemorySessionMemoryStore()
        let session = CompanionSession(persona: persona, brain: brain, memory: memory)

        _ = await session.submit("I am Ming")

        let facts = await memory.facts()
        XCTAssertEqual(facts.count, 1)
        XCTAssertEqual(facts.first?.category, .name)
        XCTAssertEqual(facts.first?.value, "Ming")
    }

    func testActionIntentFailsClosedWithoutJudgmentBackend() async {
        let brain = LabeledBrain(
            response: BrainResponse(
                presentation: "ok",
                actionIntent: ActionIntent(kind: .reminder, summary: "remind me at 8")
            )
        )
        let session = CompanionSession(persona: persona, brain: brain)

        let result = await session.submit("remind me at 8")

        guard let decision = result.actionDecision else {
            return XCTFail("expected an action decision")
        }
        guard case .denied = decision else {
            return XCTFail("V0 must fail closed, got \(decision)")
        }
        // A refused action must not suppress the turn itself.
        XCTAssertEqual(result.outcome, .replied)
        XCTAssertEqual(result.state.characterState.presence, .speaking)
    }

    func testSameInputProducesSameState() async {
        let brain = LabeledBrain(
            response: BrainResponse(
                characterStateCandidate: CharacterStateCandidate(mood: "curious", gaze: "up", gesture: "tilt"),
                presentation: "why?"
            )
        )
        let firstSession = CompanionSession(persona: persona, brain: brain)
        let secondSession = CompanionSession(persona: persona, brain: brain)

        let first = await firstSession.submit("why?").state
        let second = await secondSession.submit("why?").state

        XCTAssertEqual(first, second)
    }

    func testUnnamedMoodCarriesOverFromThePreviousTurn() async {
        let session = CompanionSession(persona: persona, brain: SwitchingBrain())

        let first = await session.submit("hello")
        XCTAssertEqual(first.state.characterState.mood, .happy)

        // This response names no mood at all. The mapper keeps the previous
        // value instead of guessing or resetting.
        let second = await session.submit("mm")
        XCTAssertEqual(second.state.characterState.mood, .happy)
        XCTAssertEqual(second.state.characterState.presence, .speaking)
    }
}
