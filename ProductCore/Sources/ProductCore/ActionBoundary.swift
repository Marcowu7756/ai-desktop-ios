// ProductCore — ActionBoundary
//
// Fails closed by default.
//
// V0 ships no judgment backend and no executor, so every action intent is
// refused with an explicit reason. That is the intended behaviour: the boundary
// is proven to be closed before anything is allowed through it.

public enum ActionDecision: Sendable, Equatable {
    /// Authorized to be *attempted*. V0 has no executor, so nothing happens yet.
    case authorized(ActionIntent)
    case denied(reason: String)
    case awaitingUserConfirmation(reason: String)
}

public struct ActionBoundary: Sendable {
    private let judgment: (any JudgmentBackend)?

    public init(judgment: (any JudgmentBackend)? = nil) {
        self.judgment = judgment
    }

    public func submit(_ intent: ActionIntent, context: JudgmentContext) async -> ActionDecision {
        guard let judgment else {
            return .denied(reason: "no judgment backend wired in V0; action boundary fails closed")
        }

        switch await judgment.judge(intent, in: context) {
        case .allow:
            return .authorized(intent)
        case .deny(let reason):
            return .denied(reason: reason)
        case .requireUserConfirmation(let reason):
            return .awaitingUserConfirmation(reason: reason)
        }
    }
}
