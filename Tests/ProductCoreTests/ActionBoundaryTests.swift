// UNVERIFIED: not executed. No Swift toolchain in this environment.

import XCTest
import ProductCore

private struct DenyAllJudgment: JudgmentBackend {
    func judge(_ intent: ActionIntent, in context: JudgmentContext) async -> JudgmentVerdict {
        .deny(reason: "test")
    }
}

private struct ConfirmAllJudgment: JudgmentBackend {
    func judge(_ intent: ActionIntent, in context: JudgmentContext) async -> JudgmentVerdict {
        .requireUserConfirmation(reason: "test")
    }
}

final class ActionBoundaryTests: XCTestCase {
    private let intent = ActionIntent(kind: .reminder, summary: "remind me at 8")
    private let context = JudgmentContext(personaID: "companion-01")

    func testFailsClosedWithoutJudgmentBackend() async {
        let boundary = ActionBoundary()
        let decision = await boundary.submit(intent, context: context)

        if case .denied = decision {
            // expected
        } else {
            XCTFail("V0 action boundary must fail closed, got \(decision)")
        }
    }

    func testDenialIsSurfaced() async {
        let boundary = ActionBoundary(judgment: DenyAllJudgment())
        let decision = await boundary.submit(intent, context: context)

        XCTAssertEqual(decision, .denied(reason: "test"))
    }

    func testConfirmationIsNotSilentlyTreatedAsDenial() async {
        let boundary = ActionBoundary(judgment: ConfirmAllJudgment())
        let decision = await boundary.submit(intent, context: context)

        XCTAssertEqual(decision, .awaitingUserConfirmation(reason: "test"))
    }
}
