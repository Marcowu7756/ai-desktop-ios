// BrainKit — BrainWireTurn
//
// The one wire shape every adapter must produce, and the strict decoder that
// turns it into a ProductCore `BrainResponse`.
//
// Why here and not in ProductCore: the wire shape is an adapter concern, while
// the resulting types are ProductCore's. Keeping the two apart is what stops a
// provider's vocabulary from leaking upward.

import Foundation
import ProductCore

public struct BrainWireMemory: Sendable, Equatable, Codable {
    public var category: String
    public var value: String

    public init(category: String, value: String) {
        self.category = category
        self.value = value
    }
}

public struct BrainWireAction: Sendable, Equatable, Codable {
    public var kind: String
    public var summary: String
    public var parameters: [String: String]?

    public init(kind: String, summary: String, parameters: [String: String]? = nil) {
        self.kind = kind
        self.summary = summary
        self.parameters = parameters
    }
}

/// Field order mirrors the intent inherited from a validated prior pattern:
/// mood / gaze / gesture first, then the spoken line, then optional durable
/// facts and an optional action.
public struct BrainWireTurn: Sendable, Equatable, Codable {
    public var mood: String?
    public var gaze: String?
    public var gesture: String?
    public var speech: String
    public var remember: [BrainWireMemory]?
    public var action: BrainWireAction?

    public init(
        mood: String? = nil,
        gaze: String? = nil,
        gesture: String? = nil,
        speech: String,
        remember: [BrainWireMemory]? = nil,
        action: BrainWireAction? = nil
    ) {
        self.mood = mood
        self.gaze = gaze
        self.gesture = gesture
        self.speech = speech
        self.remember = remember
        self.action = action
    }
}

public enum BrainWireDecodingError: Error, Sendable, Equatable {
    case emptySpeech
    case unknownActionKind(String)
    case malformedJSON(reason: String)
}

/// Strict on purpose. An unrecognised action kind is a hard failure rather than
/// a silently dropped field — we would rather lose the turn than perform an
/// action we did not understand.
public enum BrainWireDecoder {
    public static func decode(_ wire: BrainWireTurn) throws -> BrainResponse {
        let speech = wire.speech.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !speech.isEmpty else {
            throw BrainWireDecodingError.emptySpeech
        }

        var actionIntent: ActionIntent?
        if let action = wire.action {
            guard let kind = ActionKind(rawValue: action.kind) else {
                throw BrainWireDecodingError.unknownActionKind(action.kind)
            }
            actionIntent = ActionIntent(
                kind: kind,
                parameters: action.parameters ?? [:],
                summary: action.summary
            )
        }

        let memoryEvents: [MemoryEvent] = (wire.remember ?? []).compactMap { entry in
            guard let category = MemoryCategory(rawValue: entry.category) else { return nil }
            return MemoryEvent(category: category, value: entry.value)
        }

        return BrainResponse(
            characterStateCandidate: CharacterStateCandidate(
                mood: wire.mood ?? "",
                gaze: wire.gaze ?? "",
                gesture: wire.gesture ?? ""
            ),
            presentation: speech,
            memoryEvents: memoryEvents,
            actionIntent: actionIntent
        )
    }

    /// Convenience for adapters whose provider returns JSON text.
    public static func decode(json: String) throws -> BrainResponse {
        do {
            let wire = try JSONDecoder().decode(BrainWireTurn.self, from: Data(json.utf8))
            return try decode(wire)
        } catch let error as BrainWireDecodingError {
            throw error
        } catch {
            throw BrainWireDecodingError.malformedJSON(reason: String(describing: error))
        }
    }
}
