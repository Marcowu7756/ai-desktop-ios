// ProductCore — ActionIntent
//
// A request to do something in the world. Never an action that was performed.

public enum ActionKind: String, Sendable, Equatable, CaseIterable, Codable {
    case notification
    case calendar
    case reminder
    case shortcut
    case share
}

public struct ActionIntent: Sendable, Equatable, Codable {
    public var kind: ActionKind
    /// Flat, stringly-typed payload. V0 has no executor, so this is only ever
    /// inspected for authorization, never performed.
    public var parameters: [String: String]
    /// Human-readable description, shown to the user before any authorization.
    public var summary: String

    public init(kind: ActionKind, parameters: [String: String] = [:], summary: String) {
        self.kind = kind
        self.parameters = parameters
        self.summary = summary
    }
}
