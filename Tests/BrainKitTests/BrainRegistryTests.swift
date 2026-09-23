// UNVERIFIED until the boundary gate runs it.
//
// These tests cover the mechanism that makes "swap the brain" safe: an adapter
// named in the policy but absent from the registry must never be substituted by
// something the policy did not enable.

import XCTest
import ProductCore
import BrainKit

private struct LabeledBrain: BrainProtocol {
    let label: String

    func respond(to input: BrainInput) async throws -> BrainResponse {
        BrainResponse(presentation: label)
    }
}

final class BrainRegistryTests: XCTestCase {
    private let persona = Persona(id: "companion-01", displayName: "Lumi", personality: "warm")

    private func input() -> BrainInput {
        BrainInput(utterance: "hi", persona: persona)
    }

    func testPreferredAdapterIsUsedWhenEnabledAndRegistered() async throws {
        let registry = BrainRegistry()
            .register(.mock) { LabeledBrain(label: "mock") }
            .register(.remoteLLM) { LabeledBrain(label: "remote") }
        let policy = BrainPolicy(enabled: [.mock, .remoteLLM], preferred: .remoteLLM)

        guard let brain = registry.brain(for: policy) else {
            return XCTFail("expected a brain")
        }
        let response = try await brain.respond(to: input())

        XCTAssertEqual(response.presentation, "remote")
    }

    func testFallsBackToAnEnabledRegisteredAdapter() async throws {
        let registry = BrainRegistry().register(.mock) { LabeledBrain(label: "mock") }
        // The preferred adapter is named but not registered.
        let policy = BrainPolicy(enabled: [.mock], preferred: .remoteLLM)

        guard let brain = registry.brain(for: policy) else {
            return XCTFail("expected a fallback brain")
        }
        let response = try await brain.respond(to: input())

        XCTAssertEqual(response.presentation, "mock")
    }

    func testNothingEnabledReturnsNil() {
        let registry = BrainRegistry().register(.mock) { LabeledBrain(label: "mock") }
        let policy = BrainPolicy(enabled: [], preferred: .mock)

        XCTAssertNil(registry.brain(for: policy))
    }

    func testEnabledButUnregisteredReturnsNilRatherThanSubstituting() {
        // .manifoldKit is named by the policy but no adapter exists for it. An
        // empty registry must yield nothing - not the mock, which is not enabled.
        let registry = BrainRegistry()
        let policy = BrainPolicy(enabled: [.manifoldKit], preferred: .manifoldKit)

        XCTAssertNil(registry.brain(for: policy))
    }

    func testDisablingManifoldKitFallsBackWithoutChangingAnythingElse() async throws {
        // This is the "adapter disabled is a configuration change" property:
        // the policy still names ManifoldKit as preferred, but because no
        // adapter is registered for it, the enabled+registered mock is used.
        let registry = BrainRegistry().register(.mock) { LabeledBrain(label: "mock") }
        let policy = BrainPolicy(enabled: [.mock, .manifoldKit], preferred: .manifoldKit)

        guard let brain = registry.brain(for: policy) else {
            return XCTFail("expected the mock fallback")
        }
        let response = try await brain.respond(to: input())

        XCTAssertEqual(response.presentation, "mock")
    }

    func testV0DefaultResolvesToTheMockBrain() async throws {
        let registry = BrainRegistry().register(.mock) { LabeledBrain(label: "mock") }

        guard let brain = registry.brain(for: .v0Default) else {
            return XCTFail("expected the V0 default brain")
        }
        let response = try await brain.respond(to: input())

        XCTAssertEqual(response.presentation, "mock")
    }
}
