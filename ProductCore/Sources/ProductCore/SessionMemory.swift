// ProductCore — SessionMemory
//
// V0: in-memory only. Nothing is persisted, nothing leaves the device.
// Persistence is a V1 decision, not a V0 dependency.

public protocol SessionMemoryStore: Sendable {
    func append(_ turn: CompanionTurn) async
    func recent(limit: Int) async -> [CompanionTurn]
    func remember(_ event: MemoryEvent) async
    func facts() async -> [MemoryEvent]
}

public actor InMemorySessionMemoryStore: SessionMemoryStore {
    private var turns: [CompanionTurn] = []
    private var remembered: [MemoryEvent] = []

    public init() {}

    public func append(_ turn: CompanionTurn) async {
        turns.append(turn)
    }

    public func recent(limit: Int) async -> [CompanionTurn] {
        guard limit > 0 else { return [] }
        return Array(turns.suffix(limit))
    }

    public func remember(_ event: MemoryEvent) async {
        // Last write wins per category: a session memory, not a knowledge base.
        remembered.removeAll { $0.category == event.category }
        remembered.append(event)
    }

    public func facts() async -> [MemoryEvent] {
        remembered
    }
}
