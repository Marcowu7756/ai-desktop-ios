// App — AppModel
//
// Presentation only. The turn loop lives in ProductCore as `CompanionSession`,
// where it is covered by the Windows gate; this type just renders its results.
//
// If you are tempted to put logic here, put it in CompanionSession instead —
// this file is part of the unverified Apple-side surface.

#if canImport(SwiftUI)
import Foundation
import SwiftUI
import ProductCore
import BrainKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var personaState: PersonaState
    @Published private(set) var turns: [CompanionTurn] = []
    @Published private(set) var notice: String?
    @Published var draft: String = ""

    private let session: CompanionSession

    init(session: CompanionSession, persona: Persona, brainIsConfigured: Bool) {
        self.session = session
        self.personaState = PersonaState(persona: persona)
        if !brainIsConfigured {
            self.notice = "No brain adapter is enabled. The character will stay idle."
        }
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        await send(text)
    }

    func send(_ text: String) async {
        let result = await session.submit(text)
        personaState = result.state
        turns = await session.turns()
        notice = Self.notice(for: result)
    }

    /// The shell owns the wording; ProductCore only reports typed outcomes.
    private static func notice(for result: CompanionSessionResult) -> String? {
        switch result.outcome {
        case .replied:
            guard let decision = result.actionDecision,
                  let intent = result.turn?.actionIntent else { return nil }
            switch decision {
            case .authorized:
                return "Authorized but not executed (no executor in V0): \(intent.summary)"
            case .denied(let reason):
                return "Action refused: \(reason)"
            case .awaitingUserConfirmation(let reason):
                return "Action needs confirmation: \(reason)"
            }
        case .noBrainConfigured:
            return "No brain adapter is enabled."
        case .brainFailed(let error):
            switch error {
            case .unavailable(let reason):
                return "Brain unavailable: \(reason)"
            case .notImplemented(let feature):
                return "Not implemented in this build: \(feature)"
            case .malformedResponse(let reason):
                return "Brain returned something unusable: \(reason)"
            }
        }
    }
}
#endif
