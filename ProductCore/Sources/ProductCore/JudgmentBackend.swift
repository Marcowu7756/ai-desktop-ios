// ProductCore — JudgmentBackend
//
// V0 STATUS: protocol seam only. ZERO implementations, ZERO wiring.
//
// This exists so the slot is where it belongs. It is deliberately not filled.
// A judgment backend is only worth building once a real decision has been shown
// to need it — not the other way round.

public struct JudgmentContext: Sendable, Equatable {
    public var personaID: String

    public init(personaID: String) {
        self.personaID = personaID
    }
}

public enum JudgmentVerdict: Sendable, Equatable {
    case allow
    case deny(reason: String)
    case requireUserConfirmation(reason: String)
}

public protocol JudgmentBackend: Sendable {
    func judge(_ intent: ActionIntent, in context: JudgmentContext) async -> JudgmentVerdict
}
