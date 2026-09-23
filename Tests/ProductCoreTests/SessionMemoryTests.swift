// UNVERIFIED: not executed. No Swift toolchain in this environment.

import XCTest
import ProductCore

final class SessionMemoryTests: XCTestCase {
    func testRecentReturnsTailInOrder() async {
        let store = InMemorySessionMemoryStore()
        for index in 1...3 {
            await store.append(
                CompanionTurn(characterState: .idle, presentation: "turn-\(index)")
            )
        }

        let recent = await store.recent(limit: 2)

        XCTAssertEqual(recent.map(\.presentation), ["turn-2", "turn-3"])
    }

    func testZeroOrNegativeLimitReturnsEmpty() async {
        let store = InMemorySessionMemoryStore()
        await store.append(CompanionTurn(characterState: .idle, presentation: "x"))

        let recent = await store.recent(limit: 0)

        XCTAssertTrue(recent.isEmpty)
    }

    func testRememberKeepsLastWritePerCategory() async {
        let store = InMemorySessionMemoryStore()
        await store.remember(MemoryEvent(category: .name, value: "A"))
        await store.remember(MemoryEvent(category: .name, value: "B"))
        await store.remember(MemoryEvent(category: .occupation, value: "C"))

        let facts = await store.facts()

        XCTAssertEqual(facts.count, 2)
        XCTAssertEqual(facts.first { $0.category == .name }?.value, "B")
    }
}
