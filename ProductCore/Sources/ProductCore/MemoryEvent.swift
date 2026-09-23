// ProductCore — MemoryEvent
//
// Durable facts, typed so a model cannot smuggle in an unbounded category.

public enum MemoryCategory: String, Sendable, Equatable, CaseIterable, Codable {
    case name
    case pronouns
    case occupation
    case relationships
    case preferences
    case boundaries
}

public struct MemoryEvent: Sendable, Equatable, Codable {
    public var category: MemoryCategory
    public var value: String

    public init(category: MemoryCategory, value: String) {
        self.category = category
        self.value = value
    }
}
