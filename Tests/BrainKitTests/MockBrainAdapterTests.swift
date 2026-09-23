// UNVERIFIED: not executed. No Swift toolchain in this environment.

import XCTest
import ProductCore
import BrainKit

final class MockBrainAdapterTests: XCTestCase {
    private let persona = Persona(id: "p", displayName: "Lumi", personality: "warm")

    func testInputBecomesOurStructuredType() async throws {
        let brain = MockBrainAdapter()
        let response = try await brain.respond(
            to: BrainInput(utterance: "hello", persona: persona)
        )

        XCTAssertEqual(response.characterStateCandidate.mood, "happy")
        XCTAssertEqual(response.characterStateCandidate.gesture, "wave")
        XCTAssertFalse(response.presentation.isEmpty)
    }

    func testAdapterOutputSurvivesProductCoreMapping() async throws {
        let brain = MockBrainAdapter()
        let response = try await brain.respond(
            to: BrainInput(utterance: "why is the sky blue?", persona: persona)
        )

        let turn = PresentationMapper().map(response, previous: .idle)

        XCTAssertEqual(turn.characterState.mood, .curious)
        XCTAssertEqual(turn.characterState.presence, .speaking)
    }

    func testNameIsCapturedAsTypedMemory() async throws {
        let brain = MockBrainAdapter()
        let response = try await brain.respond(
            to: BrainInput(utterance: "我叫小明", persona: persona)
        )

        XCTAssertEqual(response.memoryEvents.first?.category, .name)
        XCTAssertEqual(response.memoryEvents.first?.value, "小明")
    }

    func testSameInputProducesSameOutput() async throws {
        let brain = MockBrainAdapter()
        let input = BrainInput(utterance: "hello", persona: persona)

        let first = try await brain.respond(to: input)
        let second = try await brain.respond(to: input)

        XCTAssertEqual(first, second)
    }
}
