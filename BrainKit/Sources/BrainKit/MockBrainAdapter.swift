// BrainKit — MockBrainAdapter
//
// The only adapter V0 must be able to run. Fully deterministic: no network, no
// model, no randomness. Same input always yields the same BrainResponse.

import Foundation
import ProductCore

public struct MockBrainAdapter: BrainProtocol {
    public init() {}

    public func respond(to input: BrainInput) async throws -> BrainResponse {
        let utterance = input.utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !utterance.isEmpty else {
            throw BrainError.malformedResponse(reason: "empty utterance")
        }

        let wire = BrainWireTurn(
            mood: Self.mood(for: utterance),
            gaze: "user",
            gesture: Self.gesture(for: utterance),
            speech: Self.speech(for: utterance, persona: input.persona),
            remember: Self.remember(for: utterance),
            action: nil
        )

        return try BrainWireDecoder.decode(wire)
    }

    // MARK: - Deterministic rules (documented, testable, no randomness)

    static func mood(for utterance: String) -> String {
        if utterance.contains("?") { return Mood.curious.rawValue }
        if utterance.contains("你好") || utterance.lowercased().contains("hello") {
            return Mood.happy.rawValue
        }
        return Mood.neutral.rawValue
    }

    static func gesture(for utterance: String) -> String {
        if utterance.contains("你好") || utterance.lowercased().contains("hello") {
            return Gesture.wave.rawValue
        }
        return Gesture.nod.rawValue
    }

    static func speech(for utterance: String, persona: Persona) -> String {
        "\(persona.displayName) heard: \(utterance)"
    }

    static func remember(for utterance: String) -> [BrainWireMemory]? {
        let marker = "我叫"
        guard let range = utterance.range(of: marker) else { return nil }
        let name = String(utterance[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        return [BrainWireMemory(category: MemoryCategory.name.rawValue, value: name)]
    }
}
