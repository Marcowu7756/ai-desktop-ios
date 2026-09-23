// BrainKit — RemoteLLMBrainAdapter
//
// UNVERIFIED: never executed. No network call is made by this scaffold.
//
// The transport is injected so the adapter can be tested without a network and
// so a provider swap never reaches ProductCore.

import Foundation
import ProductCore

public struct LLMRequest: Sendable, Equatable {
    public var modelID: String
    public var systemPrompt: String
    public var userMessage: String

    public init(modelID: String, systemPrompt: String, userMessage: String) {
        self.modelID = modelID
        self.systemPrompt = systemPrompt
        self.userMessage = userMessage
    }
}

public protocol LLMTransport: Sendable {
    /// Returns the assistant's content, which must be the JSON form of
    /// `BrainWireTurn`.
    func complete(_ request: LLMRequest) async throws -> String
}

public struct RemoteLLMBrainAdapter: BrainProtocol {
    private let transport: any LLMTransport
    private let modelID: String

    public init(transport: any LLMTransport, modelID: String) {
        self.transport = transport
        self.modelID = modelID
    }

    public func respond(to input: BrainInput) async throws -> BrainResponse {
        let request = LLMRequest(
            modelID: modelID,
            systemPrompt: Self.systemPrompt(for: input.persona),
            userMessage: input.utterance
        )
        let content = try await transport.complete(request)
        return try BrainWireDecoder.decode(json: content)
    }

    /// Adapters own prompt shape. ProductCore never sees a prompt.
    static func systemPrompt(for persona: Persona) -> String {
        """
        You are \(persona.displayName). Personality: \(persona.personality).
        Reply with JSON only, using exactly these keys:
        mood, gaze, gesture, speech, remember (optional array of
        {category, value}), action (optional {kind, summary, parameters}).
        Decide mood, gaze and gesture before you compose speech.
        Use only these mood values: \(Mood.allCases.map(\.rawValue).joined(separator: ", ")).
        Use only these gaze values: \(Gaze.allCases.map(\.rawValue).joined(separator: ", ")).
        Use only these gesture values: \(Gesture.allCases.map(\.rawValue).joined(separator: ", ")).
        Use only these memory categories: \(MemoryCategory.allCases.map(\.rawValue).joined(separator: ", ")).
        Use only these action kinds: \(ActionKind.allCases.map(\.rawValue).joined(separator: ", ")).
        """
    }
}
